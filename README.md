## 👥 Group Members  
This project was completed by the following team members:  
- SHYAKA CHRIS — Student ID: 27889
- IRAKOZE TESSY MICK -Student ID: 27632
- RUKUNDO ESPOIR -Student ID: 27678
- NSHUTI MUGABO ARSENE -Student ID: 27668

# 🏥 PL/SQL Database Management Systems

This repository contains comprehensive PL/SQL implementations for Hospital Management and HR Employee Management systems. Each system demonstrates advanced PL/SQL programming concepts and best practices.

## 📚 Projects Overview

### 1. 🏥 Hospital Management System  
A patient and doctor management system with bulk processing capabilities and admission tracking.

### 2. 👥 HR Employee Management System
A comprehensive human resources system with salary calculations, tax processing, and dynamic operations.

---

## 🏥 HOSPITAL MANAGEMENT SYSTEM

### 📋 Features
- **Patient Management**: Bulk patient registration and updates
- **Admission Tracking**: Real-time admission status management
- **Doctor Information**: Specialist and doctor management
- **Bulk Processing**: Efficient handling of multiple records
- **Reporting**: Comprehensive patient and admission reports

### 🗄️ Database Schema
```sql
-- Patients Table
CREATE TABLE patients (
    patient_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    age NUMBER,
    gender VARCHAR2(10),
    admitted VARCHAR2(3) DEFAULT 'NO' CHECK (admitted IN ('YES', 'NO'))
);

-- Doctors Table
CREATE TABLE doctors (
    doctor_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    specialty VARCHAR2(100)
);
```

### 💻 PL/SQL Concepts Demonstrated
- ✅ **Collections**: Custom table types for patient data
- ✅ **Bulk Processing**: FORALL for efficient multiple inserts
- ✅ **Packages**: Encapsulated hospital management logic
- ✅ **Cursors**: REF CURSOR for flexible data retrieval
- ✅ **Functions**: Analytical functions for patient counting
- ✅ **Procedures**: Status updates and bulk operations

### 🎯 Key Procedures & Functions

#### `bulk_load_patients()`
- **Purpose**: Mass patient registration using collections
- **Features**: Bulk insertion with FORALL, error handling
- **Usage**:
```sql
DECLARE
    v_patients hospital_mgmt_pkg.patient_table;
BEGIN
    v_patients.EXTEND(3);
    v_patients(1) := hospital_mgmt_pkg.patient_rec(101, 'John Doe', 45, 'Male', 'NO');
    hospital_mgmt_pkg.bulk_load_patients(v_patients);
END;
/
```

#### `show_all_patients()`
- **Purpose**: Returns REF CURSOR for patient data display
- **Features**: Flexible data retrieval for reporting
- **Usage**: Returns sys_refcursor for all patient records

#### `count_admitted()`
- **Purpose**: Real-time admission statistics
- **Features**: Returns count of currently admitted patients
- **Usage**:
```sql
v_count := hospital_mgmt_pkg.count_admitted();
```

#### `admit_patient()`
- **Purpose**: Patient status management
- **Features**: Updates admission status with validation
- **Usage**:
```sql
hospital_mgmt_pkg.admit_patient(101);
```

### 🔧 Installation & Setup

```sql
-- Run the complete hospital management script
@hospital_management.sql

-- Verify installation
SELECT object_name, object_type 
FROM user_objects 
WHERE object_name LIKE 'HOSPITAL%';
```

### 🧪 Testing Examples

```sql
-- Test bulk patient loading
BEGIN
    hospital_mgmt_pkg.bulk_load_patients(v_patients);
END;

-- Test admission process
BEGIN
    hospital_mgmt_pkg.admit_patient(101);
    DBMS_OUTPUT.PUT_LINE('Admitted patients: ' || hospital_mgmt_pkg.count_admitted());
END;

-- Display all patients
BEGIN
    hospital_mgmt_pkg.display_patient_info;
END;
```

---

## 👥 HR EMPLOYEE MANAGEMENT SYSTEM

### 📋 Features
- **Salary Calculations**: RSSB tax computation and net salary
- **Dynamic Operations**: Flexible procedures using dynamic SQL
- **Security Context**: User privilege management
- **Bulk Processing**: Employee data in batches
- **Audit Trail**: Comprehensive salary change tracking

### 🗄️ Database Schema
```sql
-- Employees Table
CREATE TABLE employees (
    employee_id NUMBER PRIMARY KEY,
    first_name VARCHAR2(50),
    last_name VARCHAR2(50),
    email VARCHAR2(100),
    hire_date DATE,
    job_title VARCHAR2(100),
    salary NUMBER(10,2),
    department VARCHAR2(50),
    rssb_tax_rate NUMBER(5,3) DEFAULT 0.05
);

-- Salary Audit Table
CREATE TABLE salary_audit (
    audit_id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    old_salary NUMBER(10,2),
    new_salary NUMBER(10,2),
    changed_by VARCHAR2(100),
    change_date DATE,
    operation_type VARCHAR2(20)
);
```

### 💻 PL/SQL Concepts Demonstrated
- ✅ **Functions**: RSSB tax calculations with custom implementations
- ✅ **Dynamic SQL**: EXECUTE IMMEDIATE for flexible operations
- ✅ **Security**: USER context management
- ✅ **Bulk Processing**: Cursor-based employee processing
- ✅ **Error Handling**: Comprehensive exception management
- ✅ **Audit Trail**: Complete change history tracking

### 🎯 Key Procedures & Functions

#### `calculate_net_salary_emp()`
- **Purpose**: Calculate net salary after RSSB tax for specific employee
- **Features**: Tax rate lookup, validation, error handling
- **Usage**:
```sql
v_net_salary := hr_management_pkg.calculate_net_salary_emp(101);
```

#### `calculate_net_salary_custom()`
- **Purpose**: Calculate net salary with custom parameters
- **Features**: Direct salary and tax rate input
- **Usage**:
```sql
v_net_salary := hr_management_pkg.calculate_net_salary_custom(50000, 0.05);
```

#### `dynamic_employee_operation()`
- **Purpose**: Dynamic SQL for various HR operations
- **Features**: Salary updates, department reports, audit trail
- **Usage**:
```sql
hr_management_pkg.dynamic_employee_operation(
    p_operation_type => 'UPDATE_SALARY',
    p_employee_id => 101,
    p_new_salary => 60000
);
```

#### `bulk_salary_report()`
- **Purpose**: Generate comprehensive salary reports
- **Features**: Department filtering, totals calculation
- **Usage**:
```sql
hr_management_pkg.bulk_salary_report('IT');
```

#### `show_user_context()`
- **Purpose**: Demonstrate security context and user privileges
- **Features**: USER context display, security explanation

### 🔧 Installation & Setup

```sql
-- Run the complete HR management script
@hr_management.sql

-- Verify installation
SELECT object_name, object_type 
FROM user_objects 
WHERE object_name LIKE 'HR_MANAGEMENT%';
```

### 🧪 Testing Examples

```sql
-- Test salary calculation
BEGIN
    v_net_salary := hr_management_pkg.calculate_net_salary_emp(101);
    DBMS_OUTPUT.PUT_LINE('Net Salary: $' || v_net_salary);
END;

-- Test dynamic operations
BEGIN
    hr_management_pkg.dynamic_employee_operation(
        p_operation_type => 'DEPARTMENT_REPORT',
        p_department => 'IT'
    );
END;

-- Test bulk reporting
BEGIN
    hr_management_pkg.bulk_salary_report;
END;
```

---

## 🚀 Quick Start Guide

### Prerequisites
- Oracle Database 11g or higher
- SQL*Plus or SQL Developer
- Basic PL/SQL execution privileges

### Installation Steps
1. **Download** the SQL scripts
2. **Connect** to your Oracle database:
   ```sql
   sqlplus username/password@database
   ```
3. **Execute** the desired system:
   ```sql
   -- For Hospital Management
   @hospital_management.sql
   
   -- For HR Management
   @hr_management.sql
   ```

### 📁 Project Structure
```
plsql-systems/
├── 📄 README.md
├── 🏥 hospital_management.sql
├── 👥 hr_management.sql
├── 🔧 installation_guide.md
└── 💡 examples/
    ├── hospital_examples.sql
    └── hr_examples.sql
```

---

## 🎯 Learning Outcomes

### PL/SQL Mastery
- **Collections & Bulk Processing**: Efficient data handling
- **Package Development**: Modular and maintainable code
- **Dynamic SQL**: Flexible database operations
- **Error Handling**: Robust exception management
- **Security Implementation**: User context and privileges

### Real-World Applications
- **Hospital Workflows**: Patient admission and tracking
- **HR Operations**: Salary management and reporting
- **Data Integrity**: Constraint enforcement and validation
- **Audit Compliance**: Comprehensive change tracking

### Performance Optimization
- **Bulk Operations**: Reduced database round-trips
- **Cursor Management**: Efficient data retrieval
- **Transaction Control**: Proper commit/rollback strategies

---

## 🤝 Contributing

We welcome contributions! Please feel free to:
- Submit bug reports and feature requests
- Improve documentation and examples
- Add new test cases and scenarios
- Optimize existing code and queries

### Contribution Guidelines
1. Follow Oracle PL/SQL coding standards
2. Include comprehensive error handling
3. Add detailed comments for complex logic
4. Test thoroughly with various scenarios

---

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

---

## 📞 Support

For questions or issues:
1. Check the examples in each system's test scripts
2. Review the comprehensive comments in the code
3. Open an issue in the GitHub repository

---

**⭐ Star this repository if you find these PL/SQL implementations helpful for learning database programming!**

---
*Last Updated: December 2024*  
*Oracle PL/SQL Version: 11g and above*  
*Designed for Educational and Enterprise Use*
  
