-- ecommerce_schema.sql
-- E-commerce Store database schema (MySQL / InnoDB)
-- Run: SOURCE ecommerce_schema.sql; or paste into a MySQL client

DROP DATABASE IF EXISTS ecommerce_store;
CREATE DATABASE ecommerce_store CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE ecommerce_store;

-- ------------------------------------------------------------
-- Categories (hierarchical, optional parent-child)
-- ------------------------------------------------------------
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  slug VARCHAR(120) NOT NULL,
  parent_id INT NULL,
  description TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_category_slug (slug),
  CONSTRAINT fk_categories_parent FOREIGN KEY (parent_id)
    REFERENCES categories(category_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Suppliers
-- ------------------------------------------------------------
CREATE TABLE suppliers (
  supplier_id INT AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(150) NOT NULL,
  contact_email VARCHAR(255),
  phone VARCHAR(50),
  address TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Products
-- ------------------------------------------------------------
CREATE TABLE products (
  product_id INT AUTO_INCREMENT PRIMARY KEY,
  sku VARCHAR(64) NOT NULL,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  supplier_id INT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_product_sku (sku),
  INDEX idx_product_name (name),
  CONSTRAINT fk_products_supplier FOREIGN KEY (supplier_id)
    REFERENCES suppliers(supplier_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Many-to-Many: product_categories
-- ------------------------------------------------------------
CREATE TABLE product_categories (
  product_id INT NOT NULL,
  category_id INT NOT NULL,
  PRIMARY KEY (product_id, category_id),
  CONSTRAINT fk_pc_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_pc_category FOREIGN KEY (category_id)
    REFERENCES categories(category_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Customers (users)
-- ------------------------------------------------------------
CREATE TABLE customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(100) NOT NULL,
  last_name VARCHAR(100) NOT NULL,
  email VARCHAR(255) NOT NULL,
  phone VARCHAR(50),
  password_hash VARCHAR(255) NOT NULL, -- store hashed passwords
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  UNIQUE KEY uq_customer_email (email)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Addresses (One-to-Many: customer -> addresses)
-- ------------------------------------------------------------
CREATE TABLE addresses (
  address_id INT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  label VARCHAR(100), -- e.g., "Home", "Office"
  line1 VARCHAR(255) NOT NULL,
  line2 VARCHAR(255),
  city VARCHAR(100) NOT NULL,
  state VARCHAR(100),
  postal_code VARCHAR(30),
  country VARCHAR(100) NOT NULL,
  is_default BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_addresses_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Orders
-- ------------------------------------------------------------
CREATE TABLE orders (
  order_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  customer_id INT NOT NULL,
  shipping_address_id INT NOT NULL,
  billing_address_id INT NULL,
  order_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  status ENUM('pending','processing','shipped','delivered','cancelled','refunded') NOT NULL DEFAULT 'pending',
  total_amount DECIMAL(12,2) NOT NULL DEFAULT 0.00,
  notes TEXT,
  CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_orders_shipping_address FOREIGN KEY (shipping_address_id)
    REFERENCES addresses(address_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_orders_billing_address FOREIGN KEY (billing_address_id)
    REFERENCES addresses(address_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Order Items (One-to-Many: order -> order_items)
-- ------------------------------------------------------------
CREATE TABLE order_items (
  order_item_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  product_id INT NOT NULL,
  quantity INT NOT NULL DEFAULT 1,
  unit_price DECIMAL(12,2) NOT NULL,
  line_total DECIMAL(14,2) GENERATED ALWAYS AS (quantity * unit_price) VIRTUAL,
  CONSTRAINT fk_order_items_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_order_items_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE RESTRICT ON UPDATE CASCADE,
  INDEX idx_order_items_orderid (order_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Payments (One-to-One / One-to-Many depending on model)
-- ------------------------------------------------------------
CREATE TABLE payments (
  payment_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  order_id BIGINT NOT NULL,
  paid_at TIMESTAMP NULL,
  amount DECIMAL(12,2) NOT NULL,
  method ENUM('card','paypal','bank_transfer','cash_on_delivery') NOT NULL,
  status ENUM('pending','completed','failed','refunded') NOT NULL DEFAULT 'pending',
  transaction_reference VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_payments_order FOREIGN KEY (order_id)
    REFERENCES orders(order_id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uq_payment_txref (transaction_reference)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Inventory (tracks stock per product)
-- ------------------------------------------------------------
CREATE TABLE inventory (
  inventory_id INT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  quantity_on_hand INT NOT NULL DEFAULT 0,
  reserved INT NOT NULL DEFAULT 0,
  safety_stock INT NOT NULL DEFAULT 0,
  last_updated TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_inventory_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
  UNIQUE KEY uq_inventory_product (product_id)
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Product Reviews (customer writes review for product) - One-to-Many
-- ------------------------------------------------------------
CREATE TABLE reviews (
  review_id BIGINT AUTO_INCREMENT PRIMARY KEY,
  product_id INT NOT NULL,
  customer_id INT NOT NULL,
  rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  title VARCHAR(255),
  body TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_reviews_product FOREIGN KEY (product_id)
    REFERENCES products(product_id) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_reviews_customer FOREIGN KEY (customer_id)
    REFERENCES customers(customer_id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB;

-- ------------------------------------------------------------
-- Example view: order summary (optional)
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_order_summary AS
SELECT
  o.order_id,
  o.order_date,
  o.customer_id,
  CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
  o.status,
  o.total_amount,
  COALESCE(p.status, 'no_payment') AS payment_status
FROM orders o
LEFT JOIN customers c ON c.customer_id = o.customer_id
LEFT JOIN payments p ON p.order_id = o.order_id;

-- ------------------------------------------------------------
-- Sample indexes to help queries (non-exhaustive)
-- ------------------------------------------------------------
CREATE INDEX idx_products_price ON products(price);
CREATE INDEX idx_orders_customer_date ON orders(customer_id, order_date);

-- ------------------------------------------------------------
-- OPTIONAL: Example stored procedure to recalculate order total
-- (keeps DB consistent in case application forgets)
-- ------------------------------------------------------------
DELIMITER $$
CREATE PROCEDURE sp_recalculate_order_total(IN p_order_id BIGINT)
BEGIN
  DECLARE v_total DECIMAL(14,2) DEFAULT 0.00;
  SELECT COALESCE(SUM(quantity * unit_price), 0.00) INTO v_total
    FROM order_items WHERE order_id = p_order_id;
  UPDATE orders SET total_amount = v_total WHERE order_id = p_order_id;
END$$
DELIMITER ;

-- ------------------------------------------------------------
-- Done. You can now create products, customers, orders, etc.
-- ------------------------------------------------------------
