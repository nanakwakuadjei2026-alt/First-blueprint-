# ERP/POS System - Database Relationships & Data Models

## Entity Relationship Overview

### 1. Organizational Hierarchy
```
BRANCHES (id, branch_code, manager_id)
    ↓
USERS (id, branch_id, role)
    ├─ ADMIN (system-wide access)
    ├─ BRANCH_MANAGER (branch operations)
    ├─ CASHIER (POS transactions)
    ├─ STORE_OFFICER (inventory management)
    └─ ACCOUNTANT (financial records)
```

### 2. Product Catalog
```
CATEGORIES (id, category_name)
    ↓
PRODUCTS (id, category_id, supplier_id)
    ├─ cost_price
    ├─ selling_price
    ├─ reorder_level
    └─ sku

SUPPLIERS (id, supplier_name)
    ↓
PURCHASE_ORDERS (id, supplier_id)
    ↓
PURCHASE_ORDER_ITEMS (id, po_id, product_id)
```

### 3. Inventory Management
```
WAREHOUSE_INVENTORY (id, product_id)
    ↓ (Transfer)
STOCK_TRANSFERS (id, from_location, to_branch_id)
    ↓
STOCK_TRANSFER_ITEMS (id, transfer_id, product_id)
    ↓
BRANCH_INVENTORY (id, branch_id, product_id)

PRODUCT_BATCHES (id, product_id, branch_id, expiry_date)
    └─ Tracks: quantity_available, batch_number, manufacture_date
```

### 4. Sales & Transactions
```
BRANCHES (id)
    ↓
CASH_REGISTERS (id, branch_id)
    ↓
REGISTER_SESSIONS (id, register_id, opened_by, closed_by)
    ↓
SALES_TRANSACTIONS (id, branch_id, cashier_id, register_session_id)
    ↓
SALES_ITEMS (id, transaction_id, product_id/service_id, batch_id)
    ├─ quantity, unit_price, discount_amount, tax_amount
    └─ Tracks COGS at time of sale
```

### 5. Payment Processing
```
SALES_TRANSACTIONS (id)
    ↓
PAYMENT_TRANSACTIONS (id, sales_transaction_id)
    ├─ payment_gateway: 'STRIPE' | 'ADYEN' | 'MANUAL'
    ├─ payment_method_type: 'CREDIT_CARD' | 'DEBIT_CARD' | 'MOBILE_MONEY' | 'CASH'
    ├─ status: 'PENDING' | 'SUCCESS' | 'FAILED'
    └─ gateway_transaction_id: External reference
```

### 6. Cash Management
```
REGISTER_SESSIONS (id)
    ├─ opened_at, opening_cash
    ├─ closed_at, closing_cash_counted
    ├─ system_total (calculated from transactions)
    ├─ discrepancy_amount = closing_cash_counted - system_total
    ├─ discrepancy_type: 'SHORT' | 'OVER' | 'BALANCED'
    │
    └─ CASH_DISCREPANCIES (id, register_session_id)
        ├─ branch_id, discrepancy_amount
        ├─ reason, reported_by, reported_date
        ├─ investigated, investigated_by
        └─ status: 'OPEN' | 'RESOLVED' | 'PENDING_REVIEW'
```

### 7. Financial & Accounting
```
DAILY_FINANCIAL_SUMMARY (id, summary_date, branch_id)
    ├─ Calculated from: SALES_TRANSACTIONS + SALES_ITEMS
    ├─ gross_sales = SUM(total_amount) from sales_transactions
    ├─ total_cogs = SUM(cost_price * quantity) from sales_items
    ├─ gross_profit = gross_sales - total_cogs
    ├─ Populated by: Background job (Bull queue)
    │
    └─ GENERAL_LEDGER (id, transaction_date, branch_id)
        ├─ account_code, account_name
        ├─ debit_amount, credit_amount
        ├─ reference_type: 'SALES' | 'PURCHASE' | 'EXPENSE' | 'ADJUSTMENT'
        └─ reference_id: Links to source transaction

MONTHLY_FINANCIAL_SUMMARY (id, year_month, branch_id)
    ├─ Aggregated from: DAILY_FINANCIAL_SUMMARY
    ├─ sales_target, target_achievement_percentage
    ├─ previous_month_profit
    ├─ mom_growth_percentage = (current_profit - previous_profit) / previous_profit
    └─ Populated by: Monthly aggregation job
```

### 8. Goods Receipt & Inventory Intake
```
PURCHASE_ORDERS (id, po_number, supplier_id)
    ↓
GOODS_RECEIVED_NOTES (id, grn_number, po_id, supplier_id)
    ├─ received_by, received_date
    ├─ inspection_status: 'PENDING' | 'APPROVED' | 'REJECTED' | 'PARTIAL'
    ├─ inspected_by, inspected_date
    └─ status: 'RECEIVED' | 'INSPECTED' | 'STORED' | 'RETURNED'
    ↓
PRODUCT_BATCHES (id, product_id, batch_number, expiry_date)
    ├─ warehouse_id = NULL (central warehouse)
    ├─ quantity_received, quantity_available
    ├─ manufacture_date
    └─ Links to GRN via purchase_order_id
```

### 9. Notifications & Alerts
```
PRODUCT_BATCHES (expiry_date <= CURRENT_DATE + 90 days)
    ↓
Notification System
    ├─ Type: 'EXPIRY_ALERT'
    ├─ Severity: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'
    └─ → NOTIFICATIONS (user_id, notification_type, reference_id)

BRANCH_INVENTORY (quantity_on_hand <= reorder_level)
    ↓
    ├─ Type: 'LOW_STOCK_ALERT'
    └─ → NOTIFICATIONS

CASH_DISCREPANCIES (ABS(discrepancy_amount) > threshold)
    ↓
    ├─ Type: 'HIGH_DISCREPANCY'
    └─ → NOTIFICATIONS

NOTIFICATION_SETTINGS (user_id, notification_type)
    ├─ email_enabled, sms_enabled, push_enabled
    ├─ threshold_value
    └─ Controls delivery method & frequency
```

### 10. Audit Trail
```
AUDIT_LOGS (id, user_id, action, entity_type, entity_id)
    ├─ old_values: JSONB (previous state)
    ├─ new_values: JSONB (current state)
    ├─ timestamp: CURRENT_TIMESTAMP
    ├─ ip_address, user_agent
    └─ Tracks: CREATE, UPDATE, DELETE operations on critical entities
```

---

## Key Data Relationships

### Multi-Branch Data Flow
```
1. CENTRAL WAREHOUSE
   └─ warehouse_inventory (centralized stock)

2. STOCK TRANSFER REQUEST
   └─ Branch Manager requests stock from warehouse
   └─ Creates: stock_transfers record
   └─ Status progression: PENDING → IN_TRANSIT → RECEIVED

3. BRANCH RECEIVES STOCK
   └─ Warehouse staff creates transfer
   └─ Branch staff confirms receipt
   └─ system updates: branch_inventory
   └─ system updates: warehouse_inventory

4. REAL-TIME DASHBOARD VIEW
   └─ Admin sees live stock levels across all branches
   └─ Queries: branch_inventory + warehouse_inventory (cached)
```

### Financial Aggregation Pipeline
```
1. TRANSACTION RECORDED
   └─ POS creates: sales_transactions + sales_items
   └─ Updates: branch_inventory
   └─ Creates: payment_transactions

2. BATCH JOB (Every 5 minutes)
   └─ Calculate daily_financial_summary
   └─ Create: general_ledger entries
   └─ Update: cache with fresh totals

3. ADMIN DASHBOARD
   └─ Queries: daily_financial_summary (fast, pre-calculated)
   └─ Real-time updates: via Socket.IO
   └─ Refresh rate: 30 seconds

4. MONTHLY RECONCILIATION
   └─ Aggregate daily summaries → monthly_financial_summary
   └─ Calculate MoM growth, target achievement
   └─ Populate: general_ledger with summary entries
```

### Expiry Management
```
1. GOODS RECEIPT
   └─ Create: product_batches (batch_number, expiry_date, quantity)
   └─ status: 'ACTIVE'

2. MONITORING (Daily Job)
   └─ Query: v_expiry_watch_alert
   └─ Identify: items expiring within 90 days
   └─ Generate: notifications for store officers

3. STOCK USAGE
   └─ POS deducts quantity from product_batches
   └─ When quantity_available = 0:
   └─ Update: status = 'EXPIRED' (if past expiry_date)

4. ALERTS
   └─ CRITICAL: 7 days to expiry
   └─ HIGH: 30 days to expiry
   └─ MEDIUM: 60 days to expiry
```

---

## Cardinality Reference

| Relationship | From | To | Cardinality | Notes |
|---|---|---|---|---|
| Branch → Manager | branches | users | 1:1 | Optional |
| Branch → Users | branches | users | 1:N | Managers, Cashiers |
| Product → Category | products | categories | N:1 | Required |
| Product → Supplier | products | suppliers | N:1 | Optional |
| Warehouse Inventory | warehouse_inventory | products | 1:1 | Unique constraint |
| Branch Inventory | branch_inventory | branches, products | 1:N | Composite PK |
| Stock Transfer → Branch | stock_transfers | branches | N:1 | destination |
| Sales → Branch | sales_transactions | branches | N:1 | |
| Sales → Cashier | sales_transactions | users | N:1 | |
| Sales Items → Transaction | sales_items | sales_transactions | N:1 | |
| Sales Items → Product | sales_items | products | N:1 | Optional |
| Payment → Sales | payment_transactions | sales_transactions | N:1 | |
| Register Session → Branch | register_sessions | branches | N:1 | |
| Register Session → User | register_sessions | users | N:1 | opener/closer |
| Discrepancy → Session | cash_discrepancies | register_sessions | N:1 | |
| GL Entry → Branch | general_ledger | branches | N:1 | Optional |
| Purchase Order → Supplier | purchase_orders | suppliers | N:1 | |
| GRN → PO | goods_received_notes | purchase_orders | N:1 | Optional |
| Product Batch → Product | product_batches | products | N:1 | |
| Notification → User | notifications | users | N:1 | |
| Audit Log → User | audit_logs | users | N:1 | Optional |

---

## Data Integrity Constraints

### Unique Constraints
- `users.username` - Username must be unique
- `users.email` - Email must be unique
- `products.product_code` - Product code must be unique
- `branches.branch_code` - Branch code must be unique
- `warehouse_inventory.product_id` - One warehouse record per product
- `branch_inventory` - Composite unique on (branch_id, product_id)
- `daily_financial_summary` - Composite unique on (summary_date, branch_id)
- `monthly_financial_summary` - Composite unique on (year_month, branch_id)

### Foreign Key Constraints
- All branch references: ON DELETE CASCADE (delete branch → delete all related data)
- User references: ON DELETE RESTRICT (cannot delete user with related records)
- Product references: ON DELETE RESTRICT (cannot delete product with sales/inventory)
- Supplier references: ON DELETE SET NULL (nullable, can delete supplier)

### Check Constraints
- `users.role` - Must be one of: ADMIN, BRANCH_MANAGER, CASHIER, STORE_OFFICER, ACCOUNTANT
- `sales_transactions.discount_percentage` - Between 0-100
- `cash_discrepancies.discrepancy_type` - SHORT or OVER
- `payment_transactions.status` - PENDING, SUCCESS, FAILED, CANCELLED

---

## Performance Considerations

### High-Volume Tables
- `sales_transactions` - Expected 10,000+ records/day (10+ branches)
- `sales_items` - 3-5x volume of sales_transactions
- `audit_logs` - Grows continuously
- `general_ledger` - 10-50 entries per transaction

### Optimization Strategies
1. **Indexes**: Branch + Date combos on sales/financial tables
2. **Partitioning**: sales_transactions partitioned by branch
3. **Archiving**: Archive sales older than 1 year quarterly
4. **Views**: Pre-calculated summary views for dashboards
5. **Caching**: Redis cache for summary queries
6. **Read Replicas**: Reporting queries on replica DB
