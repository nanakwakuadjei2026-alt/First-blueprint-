-- ============================================================================
-- MIGRATION 001: Initial Schema Creation
-- ============================================================================
-- Run this after creating the main schema above

-- Enable UUID Extension (for future use)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enable JSON Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create Admin User (Default)
INSERT INTO users (username, email, password_hash, first_name, last_name, role, is_active)
VALUES ('admin', 'admin@erpsystem.local', '$2b$10$hashedpassword', 'System', 'Administrator', 'ADMIN', TRUE)
ON CONFLICT (username) DO NOTHING;

-- Create Default Categories
INSERT INTO categories (category_name, description)
VALUES 
    ('Electronics', 'Electronic devices and accessories'),
    ('Groceries', 'Food and grocery items'),
    ('Clothing', 'Apparel and fashion items'),
    ('Services', 'Service offerings'),
    ('Maintenance', 'Maintenance and repairs')
ON CONFLICT (category_name) DO NOTHING;

-- Create Default Supplier
INSERT INTO suppliers (supplier_name, supplier_code, contact_person, email, phone_number, is_active)
VALUES ('Default Supplier', 'SUP-001', 'Contact', 'supplier@example.com', '+233XXXXXXXXX', TRUE)
ON CONFLICT (supplier_code) DO NOTHING;

-- Create Default Branches
INSERT INTO branches (branch_code, branch_name, address, city, state, postal_code, phone_number, email, is_active)
VALUES 
    ('BR-001', 'Head Office - Accra', 'Accra Business District', 'Accra', 'Greater Accra', 'GA-001', '+233XXXXXXXXX', 'accra@company.com', TRUE),
    ('BR-002', 'Kumasi Branch', 'Kumasi CBD', 'Kumasi', 'Ashanti', 'AK-001', '+233XXXXXXXXX', 'kumasi@company.com', TRUE),
    ('BR-003', 'Takoradi Branch', 'Takoradi Port Area', 'Takoradi', 'Western', 'WR-001', '+233XXXXXXXXX', 'takoradi@company.com', TRUE),
    ('BR-004', 'Tema Branch', 'Tema Industrial Area', 'Tema', 'Greater Accra', 'GA-002', '+233XXXXXXXXX', 'tema@company.com', TRUE)
ON CONFLICT (branch_code) DO NOTHING;

-- Create Cash Registers for Each Branch
INSERT INTO cash_registers (register_code, branch_id, register_name, is_active)
SELECT 'REG-' || br.branch_code || '-001', br.id, br.branch_name || ' - Register 1', TRUE
FROM branches br WHERE br.branch_code LIKE 'BR-%'
ON CONFLICT (register_code) DO NOTHING;

-- ============================================================================
-- MIGRATION 002: Create Views for Admin Dashboard
-- ============================================================================

-- Daily Sales Summary View
CREATE OR REPLACE VIEW v_daily_sales_summary AS
SELECT 
    DATE(st.transaction_date) as sales_date,
    st.branch_id,
    b.branch_name,
    COUNT(DISTINCT st.id) as transaction_count,
    SUM(st.total_items_qty) as total_items_qty,
    SUM(st.subtotal) as subtotal,
    SUM(st.discount_amount) as total_discounts,
    SUM(st.tax_amount) as total_tax,
    SUM(st.total_amount) as gross_sales,
    SUM(CASE WHEN st.payment_method = 'CASH' THEN st.total_amount ELSE 0 END) as cash_sales,
    SUM(CASE WHEN st.payment_method = 'CARD' THEN st.total_amount ELSE 0 END) as card_sales,
    SUM(CASE WHEN st.payment_method = 'MOBILE_MONEY' THEN st.total_amount ELSE 0 END) as mobile_money_sales
FROM sales_transactions st
LEFT JOIN branches b ON st.branch_id = b.id
WHERE st.is_voided = FALSE AND st.payment_status = 'COMPLETED'
GROUP BY DATE(st.transaction_date), st.branch_id, b.branch_name
ORDER BY sales_date DESC, gross_sales DESC;

-- Daily Profit Calculation View
CREATE OR REPLACE VIEW v_daily_profit_summary AS
SELECT 
    DATE(st.transaction_date) as sales_date,
    st.branch_id,
    b.branch_name,
    SUM(st.total_amount) as gross_sales,
    SUM(si.cost_price * si.quantity) as total_cogs,
    (SUM(st.total_amount) - SUM(si.cost_price * si.quantity)) as gross_profit,
    ROUND(
        ((SUM(st.total_amount) - SUM(si.cost_price * si.quantity)) / SUM(st.total_amount) * 100)::numeric, 
        2
    ) as profit_margin_percentage
FROM sales_transactions st
LEFT JOIN sales_items si ON st.id = si.transaction_id
LEFT JOIN branches b ON st.branch_id = b.id
WHERE st.is_voided = FALSE AND st.payment_status = 'COMPLETED' AND si.cost_price IS NOT NULL
GROUP BY DATE(st.transaction_date), st.branch_id, b.branch_name
ORDER BY sales_date DESC;

-- Expiry Watch View (Items expiring within 90 days)
CREATE OR REPLACE VIEW v_expiry_watch_alert AS
SELECT 
    pb.id as batch_id,
    p.id as product_id,
    p.product_name,
    cat.category_name,
    pb.batch_number,
    pb.expiry_date,
    pb.quantity_available,
    CAST((pb.expiry_date - CURRENT_DATE) as integer) as days_until_expiry,
    CASE 
        WHEN (pb.expiry_date - CURRENT_DATE) <= 7 THEN 'CRITICAL'
        WHEN (pb.expiry_date - CURRENT_DATE) <= 30 THEN 'HIGH'
        WHEN (pb.expiry_date - CURRENT_DATE) <= 60 THEN 'MEDIUM'
        ELSE 'LOW'
    END as urgency_level,
    b.branch_id,
    b.branch_name
FROM product_batches pb
JOIN products p ON pb.product_id = p.id
JOIN categories cat ON p.category_id = cat.id
LEFT JOIN branches b ON pb.branch_id = b.id
WHERE pb.status = 'ACTIVE' 
    AND pb.expiry_date > CURRENT_DATE 
    AND (pb.expiry_date - CURRENT_DATE) <= 90
    AND pb.quantity_available > 0
ORDER BY pb.expiry_date ASC, urgency_level DESC;

-- Low Stock Alert View
CREATE OR REPLACE VIEW v_low_stock_alert AS
SELECT 
    bi.id,
    bi.branch_id,
    b.branch_name,
    p.id as product_id,
    p.product_name,
    p.product_code,
    cat.category_name,
    bi.quantity_on_hand,
    p.reorder_level,
    (p.reorder_level - bi.quantity_on_hand) as shortage_qty,
    CASE 
        WHEN bi.quantity_on_hand <= 0 THEN 'CRITICAL - OUT OF STOCK'
        WHEN bi.quantity_on_hand <= (p.reorder_level * 0.5) THEN 'CRITICAL - VERY LOW'
        WHEN bi.quantity_on_hand <= p.reorder_level THEN 'WARNING - LOW STOCK'
        ELSE 'ADEQUATE'
    END as stock_status
FROM branch_inventory bi
JOIN branches b ON bi.branch_id = b.id
JOIN products p ON bi.product_id = p.id
JOIN categories cat ON p.category_id = cat.id
WHERE bi.quantity_on_hand <= p.reorder_level AND p.is_active = TRUE
ORDER BY b.branch_name, stock_status DESC;

-- Cash Discrepancies View
CREATE OR REPLACE VIEW v_cash_discrepancies_summary AS
SELECT 
    cd.id,
    cd.branch_id,
    b.branch_name,
    rs.opened_at::date as register_date,
    rs.register_id,
    cr.register_name,
    cd.discrepancy_amount,
    cd.discrepancy_type,
    cd.reason,
    cd.status,
    u.first_name || ' ' || u.last_name as reported_by_name,
    cd.reported_date,
    CASE 
        WHEN ABS(cd.discrepancy_amount) > 100 THEN 'HIGH'
        WHEN ABS(cd.discrepancy_amount) > 20 THEN 'MEDIUM'
        ELSE 'LOW'
    END as severity
FROM cash_discrepancies cd
JOIN register_sessions rs ON cd.register_session_id = rs.id
JOIN cash_registers cr ON rs.register_id = cr.id
JOIN branches b ON cd.branch_id = b.id
JOIN users u ON cd.reported_by = u.id
WHERE cd.status IN ('OPEN', 'PENDING_REVIEW')
ORDER BY cd.reported_date DESC;

-- Monthly Sales Performance View
CREATE OR REPLACE VIEW v_monthly_performance AS
SELECT 
    mfs.year_month,
    mfs.branch_id,
    b.branch_name,
    mfs.gross_sales,
    mfs.net_sales,
    mfs.total_cost_of_goods_sold,
    mfs.gross_profit,
    mfs.net_profit,
    mfs.sales_target,
    mfs.target_achievement_percentage,
    mfs.mom_growth_percentage,
    CASE 
        WHEN mfs.target_achievement_percentage >= 100 THEN 'ON TARGET'
        WHEN mfs.target_achievement_percentage >= 80 THEN 'GOOD'
        WHEN mfs.target_achievement_percentage >= 50 THEN 'NEEDS IMPROVEMENT'
        ELSE 'CRITICAL'
    END as performance_status
FROM monthly_financial_summary mfs
LEFT JOIN branches b ON mfs.branch_id = b.id
ORDER BY mfs.year_month DESC, mfs.gross_profit DESC;