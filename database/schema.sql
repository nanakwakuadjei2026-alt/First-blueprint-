-- ============================================================================
-- ENTERPRISE ERP/POS SYSTEM - COMPLETE DATABASE SCHEMA
-- ============================================================================
-- Database: erp_pos_db
-- Purpose: Multi-branch inventory, sales, services, and financial management
-- ============================================================================

-- ============================================================================
-- 1. CORE ORGANIZATIONAL TABLES
-- ============================================================================

-- Branches Table
CREATE TABLE branches (
    id SERIAL PRIMARY KEY,
    branch_code VARCHAR(10) UNIQUE NOT NULL,
    branch_name VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) DEFAULT 'Ghana',
    phone_number VARCHAR(20),
    email VARCHAR(255),
    manager_id INTEGER,
    opening_time TIME,
    closing_time TIME,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_branch_manager FOREIGN KEY (manager_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Users Table (Roles: Admin, Branch Manager, Cashier, Store Officer, Accountant)
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(100) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone_number VARCHAR(20),
    role VARCHAR(50) NOT NULL, -- 'ADMIN', 'BRANCH_MANAGER', 'CASHIER', 'STORE_OFFICER', 'ACCOUNTANT'
    branch_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_user_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT chk_role CHECK (role IN ('ADMIN', 'BRANCH_MANAGER', 'CASHIER', 'STORE_OFFICER', 'ACCOUNTANT'))
);

-- ============================================================================
-- 2. INVENTORY MANAGEMENT TABLES
-- ============================================================================

-- Categories Table
CREATE TABLE categories (
    id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Products Table (Goods)
CREATE TABLE products (
    id SERIAL PRIMARY KEY,
    product_code VARCHAR(50) UNIQUE NOT NULL,
    product_name VARCHAR(255) NOT NULL,
    category_id INTEGER NOT NULL,
    description TEXT,
    cost_price DECIMAL(12, 2) NOT NULL,
    selling_price DECIMAL(12, 2) NOT NULL,
    reorder_level INTEGER DEFAULT 10,
    supplier_id INTEGER,
    sku VARCHAR(100) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_product_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE CASCADE,
    CONSTRAINT fk_product_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- Suppliers Table
CREATE TABLE suppliers (
    id SERIAL PRIMARY KEY,
    supplier_name VARCHAR(255) NOT NULL,
    supplier_code VARCHAR(50) UNIQUE NOT NULL,
    contact_person VARCHAR(100),
    email VARCHAR(255),
    phone_number VARCHAR(20),
    address TEXT,
    city VARCHAR(100),
    payment_terms VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Centralized Warehouse Inventory
CREATE TABLE warehouse_inventory (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    quantity_on_hand INTEGER DEFAULT 0,
    quantity_reserved INTEGER DEFAULT 0,
    last_stock_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_warehouse_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT uk_warehouse_product UNIQUE (product_id)
);

-- Branch Inventory (Local stock at each branch)
CREATE TABLE branch_inventory (
    id SERIAL PRIMARY KEY,
    branch_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_on_hand INTEGER DEFAULT 0,
    quantity_reserved INTEGER DEFAULT 0,
    last_stock_check TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_branch_inv_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE,
    CONSTRAINT fk_branch_inv_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT uk_branch_product UNIQUE (branch_id, product_id)
);

-- Stock Transfer Log (Warehouse to Branch)
CREATE TABLE stock_transfers (
    id SERIAL PRIMARY KEY,
    transfer_number VARCHAR(50) UNIQUE NOT NULL,
    from_location VARCHAR(50) NOT NULL, -- 'WAREHOUSE' or branch_id
    to_branch_id INTEGER NOT NULL,
    created_by INTEGER NOT NULL,
    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    received_by INTEGER,
    received_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'IN_TRANSIT', 'RECEIVED', 'REJECTED'
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transfer_to_branch FOREIGN KEY (to_branch_id) REFERENCES branches(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfer_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_transfer_received_by FOREIGN KEY (received_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Stock Transfer Line Items
CREATE TABLE stock_transfer_items (
    id SERIAL PRIMARY KEY,
    transfer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_requested INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    cost_price DECIMAL(12, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_transfer_item_transfer FOREIGN KEY (transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE,
    CONSTRAINT fk_transfer_item_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

-- Product Expiry Tracking
CREATE TABLE product_batches (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    batch_number VARCHAR(100) NOT NULL,
    expiry_date DATE NOT NULL,
    manufacture_date DATE,
    quantity_received INTEGER NOT NULL,
    quantity_available INTEGER NOT NULL,
    warehouse_id INTEGER, -- NULL for warehouse, branch_id for branch inventory
    branch_id INTEGER,
    supplier_id INTEGER,
    purchase_order_id INTEGER,
    status VARCHAR(50) DEFAULT 'ACTIVE', -- 'ACTIVE', 'EXPIRED', 'DAMAGED', 'RETURNED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_batch_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE,
    CONSTRAINT fk_batch_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE,
    CONSTRAINT fk_batch_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
);

-- ============================================================================
-- 3. SERVICES TABLE
-- ============================================================================

CREATE TABLE services (
    id SERIAL PRIMARY KEY,
    service_code VARCHAR(50) UNIQUE NOT NULL,
    service_name VARCHAR(255) NOT NULL,
    description TEXT,
    cost_price DECIMAL(12, 2) NOT NULL,
    selling_price DECIMAL(12, 2) NOT NULL,
    duration_minutes INTEGER,
    category_id INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_service_category FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- ============================================================================
-- 4. SALES & TRANSACTIONS TABLES
-- ============================================================================

-- Sales Transactions
CREATE TABLE sales_transactions (
    id SERIAL PRIMARY KEY,
    transaction_number VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL,
    cashier_id INTEGER NOT NULL,
    customer_name VARCHAR(255),
    customer_phone VARCHAR(20),
    customer_email VARCHAR(255),
    transaction_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    total_items_qty INTEGER,
    subtotal DECIMAL(14, 2) DEFAULT 0,
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    discount_percentage DECIMAL(5, 2) DEFAULT 0,
    tax_amount DECIMAL(12, 2) DEFAULT 0,
    total_amount DECIMAL(14, 2) DEFAULT 0,
    payment_method VARCHAR(50), -- 'CASH', 'CARD', 'MOBILE_MONEY', 'CHECK', 'MIXED'
    payment_status VARCHAR(50) DEFAULT 'COMPLETED', -- 'PENDING', 'COMPLETED', 'FAILED', 'REFUNDED'
    reference_number VARCHAR(100),
    notes TEXT,
    is_voided BOOLEAN DEFAULT FALSE,
    void_reason TEXT,
    void_date TIMESTAMP,
    voided_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sale_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sale_cashier FOREIGN KEY (cashier_id) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_sale_voided_by FOREIGN KEY (voided_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Sales Transaction Line Items
CREATE TABLE sales_items (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER NOT NULL,
    product_id INTEGER,
    service_id INTEGER,
    batch_id INTEGER,
    item_type VARCHAR(20), -- 'PRODUCT' or 'SERVICE'
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(12, 2) NOT NULL,
    cost_price DECIMAL(12, 2),
    discount_amount DECIMAL(12, 2) DEFAULT 0,
    tax_amount DECIMAL(12, 2) DEFAULT 0,
    line_total DECIMAL(14, 2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_item_transaction FOREIGN KEY (transaction_id) REFERENCES sales_transactions(id) ON DELETE CASCADE,
    CONSTRAINT fk_item_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE SET NULL,
    CONSTRAINT fk_item_service FOREIGN KEY (service_id) REFERENCES services(id) ON DELETE SET NULL,
    CONSTRAINT fk_item_batch FOREIGN KEY (batch_id) REFERENCES product_batches(id) ON DELETE SET NULL
);

-- ============================================================================
-- 5. PAYMENT & CASH MANAGEMENT TABLES
-- ============================================================================

-- Payment Transactions (Integration with Stripe/Adyen)
CREATE TABLE payment_transactions (
    id SERIAL PRIMARY KEY,
    sales_transaction_id INTEGER NOT NULL,
    payment_gateway VARCHAR(50), -- 'STRIPE', 'ADYEN', 'MANUAL'
    gateway_transaction_id VARCHAR(255),
    payment_method_type VARCHAR(50), -- 'CREDIT_CARD', 'DEBIT_CARD', 'MOBILE_MONEY', 'CASH'
    amount DECIMAL(14, 2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'GHS',
    status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'SUCCESS', 'FAILED', 'CANCELLED'
    response_code VARCHAR(10),
    response_message TEXT,
    processed_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_payment_transaction FOREIGN KEY (sales_transaction_id) REFERENCES sales_transactions(id) ON DELETE CASCADE
);

-- Cash Register Management
CREATE TABLE cash_registers (
    id SERIAL PRIMARY KEY,
    register_code VARCHAR(50) UNIQUE NOT NULL,
    branch_id INTEGER NOT NULL,
    register_name VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_register_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

-- Cash Register Sessions (Daily Opening/Closing)
CREATE TABLE register_sessions (
    id SERIAL PRIMARY KEY,
    register_id INTEGER NOT NULL,
    opened_by INTEGER NOT NULL,
    opened_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    opening_cash DECIMAL(14, 2),
    closed_by INTEGER,
    closed_at TIMESTAMP,
    closing_cash_counted DECIMAL(14, 2),
    system_total DECIMAL(14, 2),
    discrepancy_amount DECIMAL(14, 2),
    discrepancy_type VARCHAR(50), -- 'SHORT', 'OVER', 'BALANCED'
    notes TEXT,
    status VARCHAR(50) DEFAULT 'OPEN', -- 'OPEN', 'CLOSED', 'RECONCILED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_session_register FOREIGN KEY (register_id) REFERENCES cash_registers(id) ON DELETE CASCADE,
    CONSTRAINT fk_session_opened_by FOREIGN KEY (opened_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_session_closed_by FOREIGN KEY (closed_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Cash Discrepancies Log
CREATE TABLE cash_discrepancies (
    id SERIAL PRIMARY KEY,
    register_session_id INTEGER NOT NULL,
    branch_id INTEGER NOT NULL,
    discrepancy_amount DECIMAL(14, 2) NOT NULL,
    discrepancy_type VARCHAR(50), -- 'SHORT', 'OVER'
    reason VARCHAR(255),
    reported_by INTEGER NOT NULL,
    reported_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    investigated BOOLEAN DEFAULT FALSE,
    investigation_notes TEXT,
    investigated_by INTEGER,
    investigated_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'OPEN', -- 'OPEN', 'RESOLVED', 'PENDING_REVIEW'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_discrepancy_session FOREIGN KEY (register_session_id) REFERENCES register_sessions(id) ON DELETE CASCADE,
    CONSTRAINT fk_discrepancy_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE,
    CONSTRAINT fk_discrepancy_reported_by FOREIGN KEY (reported_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_discrepancy_investigated_by FOREIGN KEY (investigated_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================================
-- 6. ACCOUNTING & FINANCIAL TABLES
-- ============================================================================

-- General Ledger
CREATE TABLE general_ledger (
    id SERIAL PRIMARY KEY,
    transaction_date DATE NOT NULL,
    branch_id INTEGER,
    account_code VARCHAR(20) NOT NULL,
    account_name VARCHAR(255) NOT NULL,
    debit_amount DECIMAL(14, 2) DEFAULT 0,
    credit_amount DECIMAL(14, 2) DEFAULT 0,
    reference_type VARCHAR(50), -- 'SALES', 'PURCHASE', 'EXPENSE', 'ADJUSTMENT'
    reference_id INTEGER,
    description TEXT,
    created_by INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_ledger_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT fk_ledger_created_by FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE RESTRICT
);

-- Daily Financial Summary
CREATE TABLE daily_financial_summary (
    id SERIAL PRIMARY KEY,
    summary_date DATE NOT NULL,
    branch_id INTEGER,
    gross_sales DECIMAL(14, 2) DEFAULT 0,
    total_discount DECIMAL(12, 2) DEFAULT 0,
    total_tax DECIMAL(12, 2) DEFAULT 0,
    net_sales DECIMAL(14, 2) DEFAULT 0,
    total_cost_of_goods_sold DECIMAL(14, 2) DEFAULT 0,
    gross_profit DECIMAL(14, 2) DEFAULT 0,
    operating_expenses DECIMAL(12, 2) DEFAULT 0,
    net_profit DECIMAL(14, 2) DEFAULT 0,
    cash_sales DECIMAL(14, 2) DEFAULT 0,
    card_sales DECIMAL(14, 2) DEFAULT 0,
    mobile_money_sales DECIMAL(14, 2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_daily_summary_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT uk_daily_summary UNIQUE (summary_date, branch_id)
);

-- Monthly Financial Summary
CREATE TABLE monthly_financial_summary (
    id SERIAL PRIMARY KEY,
    year_month DATE NOT NULL,
    branch_id INTEGER,
    gross_sales DECIMAL(14, 2) DEFAULT 0,
    total_discount DECIMAL(12, 2) DEFAULT 0,
    total_tax DECIMAL(12, 2) DEFAULT 0,
    net_sales DECIMAL(14, 2) DEFAULT 0,
    total_cost_of_goods_sold DECIMAL(14, 2) DEFAULT 0,
    gross_profit DECIMAL(14, 2) DEFAULT 0,
    operating_expenses DECIMAL(12, 2) DEFAULT 0,
    net_profit DECIMAL(14, 2) DEFAULT 0,
    sales_target DECIMAL(14, 2) DEFAULT 0,
    target_achievement_percentage DECIMAL(5, 2) DEFAULT 0,
    previous_month_profit DECIMAL(14, 2),
    mom_growth_percentage DECIMAL(5, 2), -- Month-over-Month
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_monthly_summary_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT uk_monthly_summary UNIQUE (year_month, branch_id)
);

-- Purchase Orders
CREATE TABLE purchase_orders (
    id SERIAL PRIMARY KEY,
    po_number VARCHAR(50) UNIQUE NOT NULL,
    supplier_id INTEGER NOT NULL,
    branch_id INTEGER,
    ordered_by INTEGER NOT NULL,
    order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expected_delivery_date DATE,
    delivery_date DATE,
    subtotal DECIMAL(14, 2) DEFAULT 0,
    tax_amount DECIMAL(12, 2) DEFAULT 0,
    total_amount DECIMAL(14, 2) DEFAULT 0,
    status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'
    received_by INTEGER,
    received_date TIMESTAMP,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_po_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_po_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT fk_po_ordered_by FOREIGN KEY (ordered_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_po_received_by FOREIGN KEY (received_by) REFERENCES users(id) ON DELETE SET NULL
);

-- Purchase Order Line Items
CREATE TABLE purchase_order_items (
    id SERIAL PRIMARY KEY,
    purchase_order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity_ordered INTEGER NOT NULL,
    quantity_received INTEGER DEFAULT 0,
    unit_cost DECIMAL(12, 2) NOT NULL,
    line_total DECIMAL(14, 2),
    batch_number VARCHAR(100),
    expiry_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_poi_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE,
    CONSTRAINT fk_poi_product FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE RESTRICT
);

-- Goods Received Notes (GRN)
CREATE TABLE goods_received_notes (
    id SERIAL PRIMARY KEY,
    grn_number VARCHAR(50) UNIQUE NOT NULL,
    purchase_order_id INTEGER,
    branch_id INTEGER,
    supplier_id INTEGER NOT NULL,
    received_by INTEGER NOT NULL,
    received_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_note_number VARCHAR(100),
    total_items_received INTEGER,
    total_amount DECIMAL(14, 2),
    inspection_status VARCHAR(50) DEFAULT 'PENDING', -- 'PENDING', 'APPROVED', 'REJECTED', 'PARTIAL'
    inspection_notes TEXT,
    inspected_by INTEGER,
    inspected_date TIMESTAMP,
    status VARCHAR(50) DEFAULT 'RECEIVED', -- 'RECEIVED', 'INSPECTED', 'STORED', 'RETURNED'
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_grn_purchase_order FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL,
    CONSTRAINT fk_grn_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE SET NULL,
    CONSTRAINT fk_grn_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT,
    CONSTRAINT fk_grn_received_by FOREIGN KEY (received_by) REFERENCES users(id) ON DELETE RESTRICT,
    CONSTRAINT fk_grn_inspected_by FOREIGN KEY (inspected_by) REFERENCES users(id) ON DELETE SET NULL
);

-- ============================================================================
-- 7. AUDIT & NOTIFICATIONS TABLES
-- ============================================================================

-- Audit Log
CREATE TABLE audit_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id INTEGER,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(50),
    user_agent TEXT,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Notifications
CREATE TABLE notifications (
    id SERIAL PRIMARY KEY,
    user_id INTEGER,
    branch_id INTEGER,
    notification_type VARCHAR(50), -- 'EXPIRY_ALERT', 'LOW_STOCK', 'HIGH_DISCREPANCY', 'PAYMENT_ERROR', 'SYSTEM'
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    reference_type VARCHAR(50),
    reference_id INTEGER,
    severity VARCHAR(20) DEFAULT 'INFO', -- 'INFO', 'WARNING', 'CRITICAL'
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT fk_notification_branch FOREIGN KEY (branch_id) REFERENCES branches(id) ON DELETE CASCADE
);

-- Notification Settings
CREATE TABLE notification_settings (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    notification_type VARCHAR(50) NOT NULL,
    email_enabled BOOLEAN DEFAULT TRUE,
    sms_enabled BOOLEAN DEFAULT FALSE,
    push_enabled BOOLEAN DEFAULT TRUE,
    threshold_value NUMERIC,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notif_settings_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    CONSTRAINT uk_notif_settings UNIQUE (user_id, notification_type)
);

-- ============================================================================
-- 8. INDEXES FOR PERFORMANCE OPTIMIZATION
-- ============================================================================

-- Sales & Transactions Indexes
CREATE INDEX idx_sales_branch_date ON sales_transactions(branch_id, transaction_date);
CREATE INDEX idx_sales_cashier ON sales_transactions(cashier_id);
CREATE INDEX idx_sales_status ON sales_transactions(payment_status);
CREATE INDEX idx_sales_items_transaction ON sales_items(transaction_id);

-- Inventory Indexes
CREATE INDEX idx_branch_inventory_branch ON branch_inventory(branch_id);
CREATE INDEX idx_branch_inventory_product ON branch_inventory(product_id);
CREATE INDEX idx_product_batches_expiry ON product_batches(expiry_date);
CREATE INDEX idx_product_batches_branch ON product_batches(branch_id);
CREATE INDEX idx_warehouse_inventory_product ON warehouse_inventory(product_id);

-- Financial Indexes
CREATE INDEX idx_daily_summary_date ON daily_financial_summary(summary_date);
CREATE INDEX idx_daily_summary_branch ON daily_financial_summary(branch_id);
CREATE INDEX idx_monthly_summary_date ON monthly_financial_summary(year_month);
CREATE INDEX idx_monthly_summary_branch ON monthly_financial_summary(branch_id);

-- Cash Register Indexes
CREATE INDEX idx_register_sessions_register ON register_sessions(register_id);
CREATE INDEX idx_register_sessions_date ON register_sessions(opened_at);
CREATE INDEX idx_cash_discrepancies_branch ON cash_discrepancies(branch_id);
CREATE INDEX idx_cash_discrepancies_status ON cash_discrepancies(status);

-- General Indexes
CREATE INDEX idx_users_branch ON users(branch_id);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_timestamp ON audit_logs(timestamp);
CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_read ON notifications(is_read);

-- ============================================================================
-- END OF SCHEMA
-- ============================================================================