-- Library Management System Database
-- Created by [Davis]

-- Create database
CREATE DATABASE IF NOT EXISTS LibraryManagementSystem;
USE LibraryManagementSystem;

-- =============================================
-- TABLES FOR LIBRARY USERS
-- =============================================

-- User accounts table
CREATE TABLE users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) NOT NULL UNIQUE,
    user_role ENUM('admin', 'librarian', 'member') NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    last_login DATETIME,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT chk_email_format CHECK (email LIKE '%@%.%')
);

-- Members table
CREATE TABLE members (
    member_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other', 'Prefer not to say'),
    phone VARCHAR(20) NOT NULL,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    membership_type ENUM('Regular', 'Student', 'Senior', 'Premium') DEFAULT 'Regular',
    membership_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    membership_expiry DATE NOT NULL DEFAULT (DATE_ADD(CURRENT_DATE, INTERVAL 1 YEAR)),
    membership_status ENUM('Active', 'Expired', 'Suspended', 'Terminated') DEFAULT 'Active',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_member_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL,
    CONSTRAINT chk_phone_format CHECK (phone REGEXP '^[0-9\\-\\+\\(\\) ]{10,20}$'),
    CONSTRAINT chk_membership_dates CHECK (membership_expiry >= membership_date)
);

-- Librarians table
CREATE TABLE librarians (
    librarian_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    hire_date DATE NOT NULL,
    position VARCHAR(100) NOT NULL,
    salary DECIMAL(10, 2),
    supervisor_id INT,
    department VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_librarian_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE,
    CONSTRAINT fk_librarian_supervisor FOREIGN KEY (supervisor_id) REFERENCES librarians(librarian_id) ON DELETE SET NULL,
    CONSTRAINT chk_salary CHECK (salary >= 0)
);

-- =============================================
-- LIBRARY MATERIALS TABLES
-- =============================================

-- Publishers table
CREATE TABLE publishers (
    publisher_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address VARCHAR(255),
    phone VARCHAR(20),
    email VARCHAR(100),
    website VARCHAR(100),
    founding_year YEAR,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Authors table
CREATE TABLE authors (
    author_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    birth_year YEAR,
    death_year YEAR,
    nationality VARCHAR(50),
    biography TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT author_unique UNIQUE (first_name, last_name, birth_year)
);

-- Material categories table
CREATE TABLE material_categories (
    category_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    loan_period_days INT NOT NULL DEFAULT 14,
    max_renewals INT NOT NULL DEFAULT 2,
    daily_fine_rate DECIMAL(5,2) NOT NULL DEFAULT 0.25,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Library materials table (books, ebooks, etc.)
CREATE TABLE library_materials (
    material_id INT AUTO_INCREMENT PRIMARY KEY,
    category_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    publisher_id INT,
    publication_year YEAR,
    edition VARCHAR(50),
    isbn VARCHAR(20) UNIQUE,
    language VARCHAR(30) DEFAULT 'English',
    description TEXT,
    table_of_contents TEXT,
    cover_image VARCHAR(255),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_material_category FOREIGN KEY (category_id) REFERENCES material_categories(category_id) ON DELETE RESTRICT,
    CONSTRAINT fk_material_publisher FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id) ON DELETE SET NULL
);

-- Material authors junction table
CREATE TABLE material_authors (
    material_id INT NOT NULL,
    author_id INT NOT NULL,
    contribution_type VARCHAR(50) DEFAULT 'Primary Author',
    PRIMARY KEY (material_id, author_id),
    CONSTRAINT fk_ma_material FOREIGN KEY (material_id) REFERENCES library_materials(material_id) ON DELETE CASCADE,
    CONSTRAINT fk_ma_author FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

-- Subjects table
CREATE TABLE subjects (
    subject_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT,
    parent_subject_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_subject_parent FOREIGN KEY (parent_subject_id) REFERENCES subjects(subject_id) ON DELETE SET NULL
);

-- Material subjects junction table
CREATE TABLE material_subjects (
    material_id INT NOT NULL,
    subject_id INT NOT NULL,
    PRIMARY KEY (material_id, subject_id),
    CONSTRAINT fk_ms_material FOREIGN KEY (material_id) REFERENCES library_materials(material_id) ON DELETE CASCADE,
    CONSTRAINT fk_ms_subject FOREIGN KEY (subject_id) REFERENCES subjects(subject_id) ON DELETE CASCADE
);

-- Material copies table
CREATE TABLE material_copies (
    copy_id INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    barcode VARCHAR(50) UNIQUE NOT NULL,
    acquisition_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    acquisition_cost DECIMAL(10,2),
    format ENUM('Print', 'E-book', 'Audiobook', 'CD/DVD', 'Other') DEFAULT 'Print',
    location VARCHAR(100) NOT NULL,
    shelf_location VARCHAR(50) NOT NULL,
    status ENUM('Available', 'Checked Out', 'On Hold', 'Lost', 'Damaged', 'In Repair', 'Withdrawn') DEFAULT 'Available',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_copy_material FOREIGN KEY (material_id) REFERENCES library_materials(material_id) ON DELETE CASCADE
);

-- =============================================
-- CIRCULATION TABLES
-- =============================================

-- Loan statuses table
CREATE TABLE loan_statuses (
    status_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default loan statuses
INSERT INTO loan_statuses (name, description) VALUES
('Checked Out', 'Item is currently checked out'),
('Returned', 'Item has been returned'),
('Overdue', 'Item is overdue'),
('Lost', 'Item has been reported lost'),
('Renewed', 'Item has been renewed');

-- Loans table
CREATE TABLE loans (
    loan_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    member_id INT NOT NULL,
    checked_out_by INT NOT NULL,
    checkout_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    due_date DATE NOT NULL,
    return_date DATETIME,
    returned_to INT,
    status_id INT NOT NULL DEFAULT 1,
    renewal_count INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_loan_copy FOREIGN KEY (copy_id) REFERENCES material_copies(copy_id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_checked_out_by FOREIGN KEY (checked_out_by) REFERENCES librarians(librarian_id) ON DELETE RESTRICT,
    CONSTRAINT fk_loan_returned_to FOREIGN KEY (returned_to) REFERENCES librarians(librarian_id) ON DELETE SET NULL,
    CONSTRAINT fk_loan_status FOREIGN KEY (status_id) REFERENCES loan_statuses(status_id) ON DELETE RESTRICT,
    CONSTRAINT chk_due_date CHECK (due_date > DATE(checkout_date)),
    CONSTRAINT chk_return_date CHECK (return_date IS NULL OR return_date >= checkout_date)
);

-- Holds table
CREATE TABLE holds (
    hold_id INT AUTO_INCREMENT PRIMARY KEY,
    material_id INT NOT NULL,
    member_id INT NOT NULL,
    placed_by INT NOT NULL,
    hold_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expiry_date DATETIME,
    status ENUM('Pending', 'Fulfilled', 'Cancelled', 'Expired') DEFAULT 'Pending',
    notification_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_hold_material FOREIGN KEY (material_id) REFERENCES library_materials(material_id) ON DELETE CASCADE,
    CONSTRAINT fk_hold_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_hold_placed_by FOREIGN KEY (placed_by) REFERENCES librarians(librarian_id) ON DELETE RESTRICT,
    CONSTRAINT unique_active_hold UNIQUE (material_id, member_id, status)
);

-- Fines table
CREATE TABLE fines (
    fine_id INT AUTO_INCREMENT PRIMARY KEY,
    loan_id INT,
    member_id INT NOT NULL,
    fine_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    amount DECIMAL(10,2) NOT NULL,
    reason ENUM('Overdue', 'Lost', 'Damaged', 'Other') NOT NULL,
    paid_amount DECIMAL(10,2) DEFAULT 0.00,
    payment_date DATE,
    status ENUM('Pending', 'Partially Paid', 'Paid', 'Waived') DEFAULT 'Pending',
    waived_by INT,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_fine_loan FOREIGN KEY (loan_id) REFERENCES loans(loan_id) ON DELETE SET NULL,
    CONSTRAINT fk_fine_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_fine_waived_by FOREIGN KEY (waived_by) REFERENCES librarians(librarian_id) ON DELETE SET NULL,
    CONSTRAINT chk_fine_amount CHECK (amount >= 0),
    CONSTRAINT chk_paid_amount CHECK (paid_amount <= amount AND paid_amount >= 0)
);

-- =============================================
-- LIBRARY BRANCHES TABLES
-- =============================================

-- Branches table
CREATE TABLE branches (
    branch_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    address VARCHAR(255) NOT NULL,
    city VARCHAR(50) NOT NULL,
    state VARCHAR(50) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    phone VARCHAR(20) NOT NULL,
    email VARCHAR(100),
    opening_hours TEXT,
    manager_id INT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_branch_manager FOREIGN KEY (manager_id) REFERENCES librarians(librarian_id) ON DELETE SET NULL
);

-- Branch transfers table
CREATE TABLE branch_transfers (
    transfer_id INT AUTO_INCREMENT PRIMARY KEY,
    copy_id INT NOT NULL,
    from_branch_id INT NOT NULL,
    to_branch_id INT NOT NULL,
    requested_by INT NOT NULL,
    processed_by INT,
    request_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    process_date DATETIME,
    status ENUM('Pending', 'In Transit', 'Completed', 'Cancelled') DEFAULT 'Pending',
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_transfer_copy FOREIGN KEY (copy_id) REFERENCES material_copies(copy_id) ON DELETE CASCADE,
    CONSTRAINT fk_transfer_from_branch FOREIGN KEY (from_branch_id) REFERENCES branches(branch_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transfer_to_branch FOREIGN KEY (to_branch_id) REFERENCES branches(branch_id) ON DELETE RESTRICT,
    CONSTRAINT fk_transfer_requested_by FOREIGN KEY (requested_by) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT fk_transfer_processed_by FOREIGN KEY (processed_by) REFERENCES librarians(librarian_id) ON DELETE SET NULL,
    CONSTRAINT chk_different_branches CHECK (from_branch_id != to_branch_id)
);

-- =============================================
-- LIBRARY EVENTS TABLES
-- =============================================

-- Library events table
CREATE TABLE library_events (
    event_id INT AUTO_INCREMENT PRIMARY KEY,
    branch_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    type ENUM('Book Club', 'Author Reading', 'Workshop', 'Lecture', 'Exhibition', 'Other') NOT NULL,
    start_datetime DATETIME NOT NULL,
    end_datetime DATETIME NOT NULL,
    location VARCHAR(100) NOT NULL,
    max_attendees INT,
    registration_required BOOLEAN DEFAULT FALSE,
    created_by INT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_event_branch FOREIGN KEY (branch_id) REFERENCES branches(branch_id) ON DELETE CASCADE,
    CONSTRAINT fk_event_created_by FOREIGN KEY (created_by) REFERENCES librarians(librarian_id) ON DELETE RESTRICT,
    CONSTRAINT chk_event_times CHECK (end_datetime > start_datetime)
);

-- Event registrations table
CREATE TABLE event_registrations (
    registration_id INT AUTO_INCREMENT PRIMARY KEY,
    event_id INT NOT NULL,
    member_id INT NOT NULL,
    registration_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    attended BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_registration_event FOREIGN KEY (event_id) REFERENCES library_events(event_id) ON DELETE CASCADE,
    CONSTRAINT fk_registration_member FOREIGN KEY (member_id) REFERENCES members(member_id) ON DELETE CASCADE,
    CONSTRAINT unique_event_member UNIQUE (event_id, member_id)
);

-- =============================================
-- SYSTEM TABLES
-- =============================================

-- System settings table
CREATE TABLE system_settings (
    setting_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    value TEXT NOT NULL,
    data_type ENUM('string', 'integer', 'boolean', 'float', 'json') NOT NULL DEFAULT 'string',
    description TEXT,
    is_editable BOOLEAN DEFAULT TRUE,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insert default system settings
INSERT INTO system_settings (name, value, data_type, description) VALUES
('max_loans_per_member', '10', 'integer', 'Maximum number of items a member can check out at once'),
('default_loan_period', '14', 'integer', 'Default loan period in days'),
('max_renewals', '2', 'integer', 'Maximum number of times an item can be renewed'),
('overdue_fine_per_day', '0.25', 'float', 'Daily fine for overdue items in currency'),
('grace_period_days', '3', 'integer', 'Grace period before fines start accruing'),
('hold_expiry_days', '7', 'integer', 'Number of days a hold remains active before expiring'),
('max_holds_per_member', '5', 'integer', 'Maximum number of holds a member can place');

-- Audit logs table
CREATE TABLE audit_logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(100) NOT NULL,
    entity_id INT NOT NULL,
    old_values JSON,
    new_values JSON,
    ip_address VARCHAR(45),
    user_agent TEXT,
    timestamp DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL
);

-- Notifications table
CREATE TABLE notifications (
    notification_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    type ENUM('Overdue', 'Hold Available', 'Fine', 'Membership', 'Event', 'Other') NOT NULL,
    reference_id INT,
    reference_type VARCHAR(50),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_notification_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE CASCADE
);

-- =============================================
-- CREATE VIEWS
-- =============================================

-- Member information view
CREATE VIEW view_member_info AS
SELECT 
    m.member_id,
    m.first_name,
    m.last_name,
    m.phone,
    u.email,
    m.membership_type,
    m.membership_status,
    m.membership_date,
    m.membership_expiry,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    COUNT(DISTINCT h.hold_id) AS active_holds,
    SUM(CASE WHEN f.status != 'Paid' THEN f.amount - f.paid_amount ELSE 0 END) AS outstanding_fines
FROM 
    members m
LEFT JOIN 
    users u ON m.user_id = u.user_id
LEFT JOIN 
    loans l ON m.member_id = l.member_id AND l.status_id = 1
LEFT JOIN 
    holds h ON m.member_id = h.member_id AND h.status = 'Pending'
LEFT JOIN 
    fines f ON m.member_id = f.member_id AND f.status != 'Paid'
GROUP BY 
    m.member_id;

-- Overdue materials view
CREATE VIEW view_overdue_materials AS
SELECT 
    l.loan_id,
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    lm.title,
    lm.isbn,
    c.copy_id,
    c.barcode,
    l.checkout_date,
    l.due_date,
    DATEDIFF(CURRENT_DATE, l.due_date) AS days_overdue,
    (DATEDIFF(CURRENT_DATE, l.due_date) * cat.daily_fine_rate) AS calculated_fine
FROM 
    loans l
JOIN 
    members m ON l.member_id = m.member_id
JOIN 
    material_copies c ON l.copy_id = c.copy_id
JOIN 
    library_materials lm ON c.material_id = lm.material_id
JOIN 
    material_categories cat ON lm.category_id = cat.category_id
WHERE 
    l.return_date IS NULL 
    AND l.due_date < CURRENT_DATE
    AND l.status_id = 1;

-- Available materials view
CREATE VIEW view_available_materials AS
SELECT 
    lm.material_id,
    lm.title,
    lm.isbn,
    GROUP_CONCAT(DISTINCT CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    cat.name AS category,
    c.copy_id,
    c.barcode,
    c.location,
    c.shelf_location
FROM 
    library_materials lm
JOIN 
    material_categories cat ON lm.category_id = cat.category_id
JOIN 
    material_copies c ON lm.material_id = c.material_id
LEFT JOIN 
    material_authors ma ON lm.material_id = ma.material_id
LEFT JOIN 
    authors a ON ma.author_id = a.author_id
WHERE 
    c.status = 'Available'
GROUP BY 
    c.copy_id;

-- Material details view
CREATE VIEW view_material_details AS
SELECT 
    lm.material_id,
    lm.title,
    lm.isbn,
    lm.publication_year,
    lm.edition,
    lm.language,
    lm.description,
    p.name AS publisher,
    cat.name AS category,
    cat.loan_period_days,
    cat.max_renewals,
    cat.daily_fine_rate,
    GROUP_CONCAT(DISTINCT CONCAT(a.first_name, ' ', a.last_name) SEPARATOR ', ') AS authors,
    GROUP_CONCAT(DISTINCT s.name SEPARATOR ', ') AS subjects,
    COUNT(DISTINCT c.copy_id) AS total_copies,
    SUM(CASE WHEN c.status = 'Available' THEN 1 ELSE 0 END) AS available_copies
FROM 
    library_materials lm
LEFT JOIN 
    publishers p ON lm.publisher_id = p.publisher_id
LEFT JOIN 
    material_categories cat ON lm.category_id = cat.category_id
LEFT JOIN 
    material_authors ma ON lm.material_id = ma.material_id
LEFT JOIN 
    authors a ON ma.author_id = a.author_id
LEFT JOIN 
    material_subjects ms ON lm.material_id = ms.material_id
LEFT JOIN 
    subjects s ON ms.subject_id = s.subject_id
LEFT JOIN 
    material_copies c ON lm.material_id = c.material_id
GROUP BY 
    lm.material_id;

-- Active holds view
CREATE VIEW view_active_holds AS
SELECT 
    h.hold_id,
    lm.material_id,
    lm.title,
    m.member_id,
    CONCAT(m.first_name, ' ', m.last_name) AS member_name,
    h.hold_date,
    h.expiry_date,
    DATEDIFF(h.expiry_date, CURRENT_DATE) AS days_remaining,
    COUNT(c.copy_id) AS available_copies,
    h.status
FROM 
    holds h
JOIN 
    library_materials lm ON h.material_id = lm.material_id
JOIN 
    members m ON h.member_id = m.member_id
LEFT JOIN 
    material_copies c ON lm.material_id = c.material_id AND c.status = 'Available'
WHERE 
    h.status = 'Pending'
GROUP BY 
    h.hold_id;

-- =============================================
-- CREATE TRIGGERS
-- =============================================

-- Trigger to update loan status when item is returned
DELIMITER //

DROP TRIGGER IF EXISTS after_loan_return//
CREATE TRIGGER after_loan_return
BEFORE UPDATE ON loans
FOR EACH ROW
BEGIN
    IF NEW.return_date IS NOT NULL AND OLD.return_date IS NULL THEN
        SET NEW.status_id = 2; -- Set status to 'Returned'
        
        -- Update the copy status to 'Available'
        UPDATE material_copies 
        SET status = 'Available' 
        WHERE copy_id = NEW.copy_id;
    END IF;
END//

DROP TRIGGER IF EXISTS check_overdue_fines//
CREATE TRIGGER check_overdue_fines
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
    DECLARE grace_period INT;
    DECLARE daily_fine_rate DECIMAL(5,2);
    DECLARE days_overdue INT;
    DECLARE fine_amount DECIMAL(10,2);
    
    -- Get system settings
    SELECT CAST(value AS UNSIGNED) INTO grace_period 
    FROM system_settings 
    WHERE name = 'grace_period_days';
    
    SELECT CAST(value AS DECIMAL(5,2)) INTO daily_fine_rate 
    FROM system_settings 
    WHERE name = 'overdue_fine_per_day';
    
    -- Calculate days overdue (after grace period)
    SET days_overdue = DATEDIFF(CURRENT_DATE, NEW.due_date) - grace_period;
    
    -- If item is overdue and no fine exists yet
    IF NEW.return_date IS NULL AND NEW.due_date < CURRENT_DATE AND days_overdue > 0 THEN
        -- Calculate fine amount
        SET fine_amount = days_overdue * daily_fine_rate;
        
        -- Check if a fine already exists
        IF NOT EXISTS (SELECT 1 FROM fines WHERE loan_id = NEW.loan_id AND reason = 'Overdue') THEN
            -- Create new fine record
            INSERT INTO fines (loan_id, member_id, amount, reason)
            VALUES (NEW.loan_id, NEW.member_id, fine_amount, 'Overdue');
            
            -- Create notification for member
            INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
            SELECT u.user_id, 'Overdue Item', 
                   CONCAT('Your item "', lm.title, '" is overdue. Please return it as soon as possible to avoid additional fines.'),
                   'Overdue', NEW.loan_id, 'Loan'
            FROM members m
            JOIN users u ON m.user_id = u.user_id
            JOIN loans l ON m.member_id = l.member_id
            JOIN material_copies c ON l.copy_id = c.copy_id
            JOIN library_materials lm ON c.material_id = lm.material_id
            WHERE m.member_id = NEW.member_id AND l.loan_id = NEW.loan_id;
        ELSE
            -- Update existing fine
            UPDATE fines 
            SET amount = fine_amount 
            WHERE loan_id = NEW.loan_id AND reason = 'Overdue';
        END IF;
    END IF;
END//

DROP TRIGGER IF EXISTS after_loan_checkout//
CREATE TRIGGER after_loan_checkout
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
    -- Update the copy status to 'Checked Out'
    UPDATE material_copies 
    SET status = 'Checked Out' 
    WHERE copy_id = NEW.copy_id;
    
    -- Check if there are any pending holds for this material
    IF EXISTS (SELECT 1 FROM holds WHERE material_id = (SELECT material_id FROM material_copies WHERE copy_id = NEW.copy_id) AND status = 'Pending') THEN
        -- Create notification for the next person in hold queue
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
        SELECT u.user_id, 'Hold Available', 
               CONCAT('The item "', lm.title, '" you placed on hold is now available. Please pick it up within 7 days.'),
               'Hold Available', h.hold_id, 'Hold'
        FROM holds h
        JOIN members m ON h.member_id = m.member_id
        JOIN users u ON m.user_id = u.user_id
        JOIN library_materials lm ON h.material_id = lm.material_id
        WHERE h.material_id = (SELECT material_id FROM material_copies WHERE copy_id = NEW.copy_id)
        AND h.status = 'Pending'
        ORDER BY h.hold_date ASC
        LIMIT 1;
    END IF;
END//

DROP TRIGGER IF EXISTS after_member_update//
CREATE TRIGGER after_member_update
AFTER UPDATE ON members
FOR EACH ROW
BEGIN
    DECLARE old_values JSON;
    DECLARE new_values JSON;
    DECLARE changer_id INT;
    
    -- Create JSON objects for old and new member values
    SET old_values = JSON_OBJECT(
        'first_name', OLD.first_name,
        'last_name', OLD.last_name,
        'phone', OLD.phone,
        'address', OLD.address,
        'membership_type', OLD.membership_type,
        'membership_status', OLD.membership_status,
        'membership_expiry', OLD.membership_expiry
    );
    
    SET new_values = JSON_OBJECT(
        'first_name', NEW.first_name,
        'last_name', NEW.last_name,
        'phone', NEW.phone,
        'address', NEW.address,
        'membership_type', NEW.membership_type,
        'membership_status', NEW.membership_status,
        'membership_expiry', NEW.membership_expiry
    );
    
    -- Identify the user who made the change
    SELECT user_id INTO changer_id
    FROM users
    WHERE username = CURRENT_USER()
    LIMIT 1;
    
    -- Insert the change into the audit log
    INSERT INTO audit_logs (user_id, action, entity_type, entity_id, old_values, new_values)
    VALUES (changer_id, 'UPDATE', 'member', NEW.member_id, old_values, new_values);
    
    -- If membership was renewed, create notification
    IF NEW.membership_expiry > OLD.membership_expiry THEN
        INSERT INTO notifications (user_id, title, message, type, reference_id, reference_type)
        SELECT u.user_id, 'Membership Renewed', 
               CONCAT('Your membership has been renewed until ', DATE_FORMAT(NEW.membership_expiry, '%M %d, %Y')),
               'Membership', NEW.member_id, 'Member'
        FROM members m
        JOIN users u ON m.user_id = u.user_id
        WHERE m.member_id = NEW.member_id;
    END IF;
END//

DELIMITER ;

-- =============================================
-- INSERT SAMPLE DATA
-- =============================================

-- Insert sample publishers
INSERT INTO publishers (name, address, phone, email, website, founding_year) VALUES
('Penguin Random House', '1745 Broadway, New York, NY 10019', '212-782-9000', 'info@penguinrandomhouse.com', 'www.penguinrandomhouse.com', 2013),
('HarperCollins', '195 Broadway, New York, NY 10007', '212-207-7000', 'info@harpercollins.com', 'www.harpercollins.com', 1989),
('Simon & Schuster', '1230 Avenue of the Americas, New York, NY 10020', '212-698-7000', 'info@simonandschuster.com', 'www.simonandschuster.com', 1924),
('Macmillan', '120 Broadway, New York, NY 10271', '646-307-5151', 'info@macmillan.com', 'www.macmillan.com', 1869),
('Hachette Book Group', '1290 Avenue of the Americas, New York, NY 10104', '212-364-1100', 'info@hachettebookgroup.com', 'www.hachettebookgroup.com', 2006);

-- Insert sample authors
INSERT INTO authors (first_name, last_name, birth_year, death_year, nationality) VALUES
('J.K.', 'Rowling', 1965, NULL, 'British'),
('Stephen', 'King', 1947, NULL, 'American'),
('George R.R.', 'Martin', 1948, NULL, 'American'),
('Margaret', 'Atwood', 1939, NULL, 'Canadian'),
('Haruki', 'Murakami', 1949, NULL, 'Japanese'),
('Agatha', 'Christie', 1890, 1976, 'British'),
('Ernest', 'Hemingway', 1899, 1961, 'American'),
('Toni', 'Morrison', 1931, 2019, 'American');

-- Insert sample material categories
INSERT INTO material_categories (name, description, loan_period_days, max_renewals, daily_fine_rate) VALUES
('Fiction', 'Novels and short stories', 21, 2, 0.25),
('Non-Fiction', 'Factual works including biographies and histories', 21, 2, 0.25),
('Reference', 'Materials that may not be checked out', 0, 0, 0.00),
('Children', 'Books for children', 28, 3, 0.10),
('Audiobooks', 'Recorded books', 14, 1, 0.50),
('E-books', 'Digital books', 14, 1, 0.00),
('Periodicals', 'Magazines and journals', 7, 0, 0.50);

-- Insert sample subjects
INSERT INTO subjects (name, description) VALUES
('Fantasy', 'Fantasy literature'),
('Science Fiction', 'Science fiction literature'),
('Mystery', 'Mystery and detective fiction'),
('Biography', 'Biographical works'),
('History', 'Historical works'),
('Science', 'Scientific works'),
('Technology', 'Technology and computing'),
('Art', 'Art and photography'),
('Travel', 'Travel guides and literature');

-- Insert sample library materials
INSERT INTO library_materials (category_id, title, publisher_id, publication_year, edition, isbn, language, description) VALUES
(1, 'Harry Potter and the Philosopher''s Stone', 1, 1997, '1st', '9780747532743', 'English', 'The first book in the Harry Potter series'),
(1, 'The Shining', 2, 1977, '1st', '9780385121675', 'English', 'A horror novel by Stephen King'),
(1, 'A Game of Thrones', 3, 1996, '1st', '9780553103540', 'English', 'The first book in A Song of Ice and Fire series'),
(1, 'The Handmaid''s Tale', 4, 1985, '1st', '9780385490818', 'English', 'A dystopian novel by Margaret Atwood'),
(1, 'Norwegian Wood', 5, 1987, '1st', '9780375704024', 'English', 'A novel by Haruki Murakami'),
(2, 'A Brief History of Time', 1, 1988, '1st', '9780553053401', 'English', 'A popular science book by Stephen Hawking'),
(2, 'Becoming', 2, 2018, '1st', '9781524763138', 'English', 'Memoir by Michelle Obama'),
(3, 'Oxford English Dictionary', 3, 1884, '2nd', '9780198611868', 'English', 'The definitive record of the English language'),
(4, 'Where the Wild Things Are', 4, 1963, '1st', '9780060254926', 'English', 'Children''s picture book by Maurice Sendak'),
(5, 'The Hobbit (Audiobook)', 5, 1937, 'Unabridged', '9780345339683', 'English', 'Audiobook version of J.R.R. Tolkien''s classic');

-- Insert material-author relationships
INSERT INTO material_authors (material_id, author_id) VALUES
(1, 1),
(2, 2),
(3, 3),
(4, 4),
(5, 5);

-- Insert material-subject relationships
INSERT INTO material_subjects (material_id, subject_id) VALUES
(1, 1),
(2, 1),
(2, 3),
(3, 1),
(4, 1),
(5, 1),
(6, 6),
(7, 4),
(8, 6),
(9, 4),
(10, 1);

-- Insert sample material copies
INSERT INTO material_copies (material_id, barcode, acquisition_date, format, location, shelf_location) VALUES
(1, 'LIB000001', '2020-01-15', 'Print', 'Main Library', 'Fiction A-Z ROW'),
(1, 'LIB000002', '2020-01-15', 'Print', 'Main Library', 'Fiction A-Z ROW'),
(2, 'LIB000003', '2019-05-20', 'Print', 'Main Library', 'Fiction A-Z KIN'),
(3, 'LIB000004', '2018-11-10', 'Print', 'Main Library', 'Fiction A-Z MAR'),
(4, 'LIB000005', '2021-02-28', 'Print', 'Main Library', 'Fiction A-Z ATW'),
(5, 'LIB000006', '2020-07-15', 'Print', 'Main Library', 'Fiction A-Z MUR'),
(6, 'LIB000008', '2019-09-05', 'E-book', 'Digital Collection', 'Online'),
(7, 'LIB000009', '2021-03-10', 'Print', 'Main Library', 'Biography OBAMA'),
(7, 'LIB000010', '2021-03-10', 'Audiobook', 'Media Center', 'Audiobook B OBAMA'),
(8, 'LIB000011', '2015-01-01', 'Print', 'Reference Section', 'REF 423 OED'),
(9, 'LIB000012', '2017-06-15', 'Print', 'Children''s Section', 'E SEN'),
(9, 'LIB000013', '2017-06-15', 'Print', 'North Branch', 'Children E SEN'),
(10, 'LIB000014', '2018-11-20', 'Audiobook', 'Media Center', 'Audiobook F TOL'),
(10, 'LIB000015', '2018-11-20', 'CD/DVD', 'Media Center', 'CD F TOL'),

-- Additional copies of popular titles
(1, 'LIB000016', '2021-05-10', 'Print', 'South Branch', 'Fiction ROW'),
(1, 'LIB000017', '2021-05-10', 'E-book', 'Digital Collection', 'Online'),
(2, 'LIB000018', '2020-10-15', 'Print', 'South Branch', 'Fiction KIN'),
(3, 'LIB000019', '2019-08-22', 'Print', 'East Branch', 'Fiction MAR'),
(3, 'LIB000020', '2022-01-05', 'E-book', 'Digital Collection', 'Online'),
(4, 'LIB000021', '2021-11-30', 'Print', 'West Branch', 'Fiction ATW'),
(5, 'LIB000022', '2020-09-18', 'Print', 'North Branch', 'Fiction MUR'),

-- Periodicals
(7, 'LIB000023', '2022-02-15', 'Periodical', 'Magazine Section', 'Current'),
(7, 'LIB000024', '2022-03-15', 'Periodical', 'Magazine Section', 'Current'),
(7, 'LIB000025', '2022-01-15', 'Periodical', 'Magazine Section', 'Back Issues');

-- Insert sample branches
INSERT INTO branches (name, address, city, state, postal_code, phone, email, opening_hours) VALUES
('Main Library', '123 Library Lane', 'Springfield', 'IL', '62701', '217-555-1000', 'main@springfieldlibrary.org', 'Mon-Thu 9am-9pm, Fri-Sat 9am-6pm, Sun 1pm-5pm'),
('North Branch', '456 North Street', 'Springfield', 'IL', '62702', '217-555-1001', 'north@springfieldlibrary.org', 'Mon-Wed 10am-8pm, Thu-Fri 10am-6pm, Sat 10am-5pm'),
('South Branch', '789 South Avenue', 'Springfield', 'IL', '62703', '217-555-1002', 'south@springfieldlibrary.org', 'Mon-Tue 10am-8pm, Wed-Fri 10am-6pm, Sat 10am-5pm'),
('East Branch', '321 East Boulevard', 'Springfield', 'IL', '62704', '217-555-1003', 'east@springfieldlibrary.org', 'Mon-Fri 10am-6pm, Sat 10am-5pm'),
('West Branch', '654 West Road', 'Springfield', 'IL', '62705', '217-555-1004', 'west@springfieldlibrary.org', 'Tue-Thu 10am-8pm, Fri-Sat 10am-6pm');

-- Insert sample users
INSERT INTO users (username, password_hash, email, user_role, is_active) VALUES
('admin1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'admin1@springfieldlibrary.org', 'admin', TRUE),
('librarian1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'librarian1@springfieldlibrary.org', 'librarian', TRUE),
('librarian2', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'librarian2@springfieldlibrary.org', 'librarian', TRUE),
('member1', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'john.doe@email.com', 'member', TRUE),
('member2', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'jane.smith@email.com', 'member', TRUE),
('member3', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'robert.johnson@email.com', 'member', TRUE);

-- Insert sample librarians
INSERT INTO librarians (user_id, first_name, last_name, hire_date, position, salary, department) VALUES
(2, 'Sarah', 'Williams', '2015-06-15', 'Head Librarian', 65000.00, 'Administration'),
(3, 'Michael', 'Brown', '2018-03-10', 'Reference Librarian', 55000.00, 'Reference Services');

-- Insert sample members
INSERT INTO members (user_id, first_name, last_name, date_of_birth, gender, phone, address, city, state, postal_code, membership_type) VALUES
(4, 'John', 'Doe', '1985-07-22', 'Male', '217-555-2001', '100 Main Street', 'Springfield', 'IL', '62701', 'Regular'),
(5, 'Jane', 'Smith', '1990-11-15', 'Female', '217-555-2002', '200 Oak Avenue', 'Springfield', 'IL', '62702', 'Premium'),
(6, 'Robert', 'Johnson', '1978-04-30', 'Male', '217-555-2003', '300 Pine Road', 'Springfield', 'IL', '62703', 'Student');

-- Insert sample loans
INSERT INTO loans (copy_id, member_id, checked_out_by, checkout_date, due_date, status_id) VALUES
(1, 1, 1, '2023-01-10 14:30:00', '2023-01-31', 1),
(3, 2, 1, '2023-01-15 11:15:00', '2023-02-05', 1),
(6, 3, 2, '2023-01-20 16:45:00', '2023-02-10', 1),
(9, 1, 2, '2023-01-05 10:00:00', '2023-01-26', 2),
(12, 2, 1, '2023-01-12 13:20:00', '2023-02-02', 1);

-- Insert sample holds
INSERT INTO holds (material_id, member_id, placed_by, hold_date, expiry_date, status) VALUES
(4, 1, 1, '2023-01-18 09:30:00', '2023-01-25', 'Pending'),
(7, 3, 2, '2023-01-19 15:45:00', '2023-01-26', 'Pending'),
(2, 2, 1, '2023-01-10 11:00:00', '2023-01-17', 'Fulfilled');

-- Insert sample fines
INSERT INTO fines (loan_id, member_id, fine_date, amount, reason, status) VALUES
(4, 1, '2023-01-27', 2.50, 'Overdue', 'Paid'),
(NULL, 2, '2023-01-15', 25.00, 'Lost', 'Pending');

-- Insert sample library events
INSERT INTO library_events (branch_id, title, description, type, start_datetime, end_datetime, location, max_attendees, registration_required, created_by) VALUES
(1, 'Book Club: The Handmaid''s Tale', 'Monthly book club discussion of Margaret Atwood''s classic novel', 'Book Club', '2023-02-15 18:00:00', '2023-02-15 20:00:00', 'Meeting Room A', 20, TRUE, 1),
(2, 'Children''s Story Time', 'Weekly story time for children ages 3-6', 'Workshop', '2023-02-10 10:30:00', '2023-02-10 11:15:00', 'Children''s Area', 15, FALSE, 2),
(3, 'Author Reading: Local Writers', 'Reading and Q&A with local authors', 'Author Reading', '2023-02-20 19:00:00', '2023-02-20 21:00:00', 'Community Room', 50, TRUE, 1);

-- Insert sample event registrations
INSERT INTO event_registrations (event_id, member_id, registration_date) VALUES
(1, 1, '2023-01-25 14:30:00'),
(1, 2, '2023-01-26 10:15:00'),
(3, 3, '2023-02-01 16:20:00');

-- Update branch managers
UPDATE branches SET manager_id = 1 WHERE branch_id = 1;
UPDATE branches SET manager_id = 2 WHERE branch_id IN (2, 3, 4, 5);