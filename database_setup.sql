-- Sheba Bar Stock Management System - MySQL Database Setup
-- Run this script in phpMyAdmin or MySQL command line

-- Create database
CREATE DATABASE IF NOT EXISTS shebabar;
USE shebabar;

-- Users table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('owner', 'manager', 'employee') NOT NULL,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    sync_status TINYINT(1) DEFAULT 0
);

-- Products table
CREATE TABLE products (
    product_id INT AUTO_INCREMENT PRIMARY KEY,
    product_name VARCHAR(100) NOT NULL,
    category VARCHAR(50) NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    current_stock INT DEFAULT 0,
    min_stock_level INT DEFAULT 5,
    is_active TINYINT(1) DEFAULT 1,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    sync_status TINYINT(1) DEFAULT 0
);

-- Stock movements table
CREATE TABLE stock_movements (
    movement_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    movement_type ENUM('BYINJIYE', 'BYAGURISHIJWE', 'BYONGEWE') NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    notes TEXT,
    user_id INT NOT NULL,
    movement_date DATE NOT NULL,
    movement_time TIME NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TINYINT(1) DEFAULT 0,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

-- Daily summaries table
CREATE TABLE daily_summaries (
    summary_id INT AUTO_INCREMENT PRIMARY KEY,
    summary_date DATE UNIQUE NOT NULL,
    total_sales_quantity INT DEFAULT 0,
    total_sales_amount DECIMAL(10,2) DEFAULT 0,
    total_incoming_quantity INT DEFAULT 0,
    total_damaged_quantity INT DEFAULT 0,
    total_damaged_amount DECIMAL(10,2) DEFAULT 0,
    closing_stock_value DECIMAL(10,2) DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    sync_status TINYINT(1) DEFAULT 0
);

-- Product daily snapshots table
CREATE TABLE product_daily_snapshots (
    snapshot_id INT AUTO_INCREMENT PRIMARY KEY,
    product_id INT NOT NULL,
    snapshot_date DATE NOT NULL,
    opening_stock INT NOT NULL,
    incoming INT DEFAULT 0,
    sold INT DEFAULT 0,
    damaged INT DEFAULT 0,
    closing_stock INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_value DECIMAL(10,2) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    sync_status TINYINT(1) DEFAULT 0,
    UNIQUE KEY unique_product_date (product_id, snapshot_date),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Sync queue table
CREATE TABLE sync_queue (
    queue_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(50) NOT NULL,
    operation ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    record_id INT NOT NULL,
    data TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    retry_count INT DEFAULT 0,
    status ENUM('pending', 'synced', 'failed') DEFAULT 'pending'
);

-- Sync history table
CREATE TABLE sync_history (
    history_id INT AUTO_INCREMENT PRIMARY KEY,
    sync_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    success TINYINT(1) NOT NULL,
    items_synced INT DEFAULT 0,
    error_message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default admin user (username: admin, password: admin123)
INSERT INTO users (username, password_hash, full_name, role, sync_status) 
VALUES ('admin', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9', 'Administrator', 'owner', 1);

-- Insert sample products
INSERT INTO products (product_name, category, unit_price, current_stock, min_stock_level) VALUES
('Mutzig', 'Inzoga', 800.00, 50, 10),
('Primus', 'Inzoga', 700.00, 30, 10),
('Amstel', 'Inzoga', 900.00, 25, 5),
('Coca Cola', 'Ibinyobwa', 400.00, 100, 20),
('Fanta', 'Ibinyobwa', 400.00, 80, 20),
('Sprite', 'Ibinyobwa', 400.00, 60, 15),
('Igikoma cy\'Ubuki', 'Ubwoba', 1500.00, 20, 5),
('Urwagwa', 'Ubwoba', 2000.00, 15, 3);

-- Create indexes for better performance
CREATE INDEX idx_stock_movements_date ON stock_movements(movement_date);
CREATE INDEX idx_stock_movements_product ON stock_movements(product_id);
CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_users_username ON users(username);

-- Show success message
SELECT 'Database setup completed successfully!' as Status;
