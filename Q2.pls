-- Create employees table
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

-- Create salary audit table
CREATE TABLE salary_audit (
    audit_id NUMBER PRIMARY KEY,
    employee_id NUMBER,
    old_salary NUMBER(10,2),
    new_salary NUMBER(10,2),
    changed_by VARCHAR2(100),
    change_date DATE,
    operation_type VARCHAR2(20)
);

-- Create sequence for audit table
CREATE SEQUENCE salary_audit_seq START WITH 1 INCREMENT BY 1;

-- Insert sample data
INSERT INTO employees VALUES (1, 'John', 'Doe', 'john.doe@company.com', DATE '2020-01-15', 'Software Engineer', 50000, 'IT', 0.05);
INSERT INTO employees VALUES (2, 'Jane', 'Smith', 'jane.smith@company.com', DATE '2019-03-20', 'Senior Developer', 75000, 'IT', 0.05);
INSERT INTO employees VALUES (3, 'Robert', 'Johnson', 'robert.j@company.com', DATE '2021-06-10', 'HR Manager', 60000, 'HR', 0.05);
INSERT INTO employees VALUES (4, 'Maria', 'Garcia', 'maria.g@company.com', DATE '2018-11-05', 'Sales Director', 80000, 'Sales', 0.05);
INSERT INTO employees VALUES (5, 'James', 'Wilson', 'james.w@company.com', DATE '2022-02-28', 'Junior Analyst', 45000, 'Finance', 0.05);

COMMIT;





CREATE OR REPLACE PACKAGE hr_management_pkg 
-- Remove AUTHID CURRENT_USER if causing issues, or use DEFINER rights
AUTHID DEFINER  
IS
    -- Type for bulk processing
    TYPE employee_rec IS RECORD (
        employee_id employees.employee_id%TYPE,
        first_name employees.first_name%TYPE,
        last_name employees.last_name%TYPE,
        salary employees.salary%TYPE,
        net_salary NUMBER
    );
    
    TYPE employee_table IS TABLE OF employee_rec;
    
    -- Function to calculate RSSB tax and return net salary for employee ID
    FUNCTION calculate_net_salary_emp(
        p_employee_id IN employees.employee_id%TYPE
    ) RETURN NUMBER;
    
    -- Function to calculate net salary with custom parameters
    FUNCTION calculate_net_salary_custom(
        p_gross_salary IN NUMBER,
        p_tax_rate IN NUMBER DEFAULT 0.05
    ) RETURN NUMBER;
    
    -- Function to get employee details with net salary
    FUNCTION get_employee_net_salary(
        p_employee_id IN employees.employee_id%TYPE
    ) RETURN employee_rec;
    
    -- Dynamic procedure for various operations
    PROCEDURE dynamic_employee_operation(
        p_operation_type IN VARCHAR2,
        p_employee_id IN NUMBER DEFAULT NULL,
        p_new_salary IN NUMBER DEFAULT NULL,
        p_department IN VARCHAR2 DEFAULT NULL
    );
    
    -- Procedure for bulk salary processing
    PROCEDURE bulk_salary_report(
        p_department IN VARCHAR2 DEFAULT NULL
    );
    
    -- Procedure to demonstrate user context
    PROCEDURE show_user_context;
    
END hr_management_pkg;
/





CREATE OR REPLACE PACKAGE BODY hr_management_pkg IS

    -- Function to calculate net salary for a specific employee
    FUNCTION calculate_net_salary_emp(
        p_employee_id IN employees.employee_id%TYPE
    ) RETURN NUMBER IS
        v_gross_salary employees.salary%TYPE;
        v_tax_rate employees.rssb_tax_rate%TYPE;
        v_net_salary NUMBER;
    BEGIN
        -- Get employee's gross salary and tax rate
        SELECT salary, rssb_tax_rate 
        INTO v_gross_salary, v_tax_rate
        FROM employees 
        WHERE employee_id = p_employee_id;
        
        -- Calculate net salary: Gross - (Gross * Tax Rate)
        v_net_salary := v_gross_salary - (v_gross_salary * v_tax_rate);
        
        RETURN ROUND(v_net_salary, 2);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Employee ID ' || p_employee_id || ' not found');
        WHEN OTHERS THEN
            RAISE_APPLICATION_ERROR(-20002, 'Error calculating net salary: ' || SQLERRM);
    END calculate_net_salary_emp;

    -- Function to calculate net salary with provided parameters
    FUNCTION calculate_net_salary_custom(
        p_gross_salary IN NUMBER,
        p_tax_rate IN NUMBER DEFAULT 0.05
    ) RETURN NUMBER IS
        v_net_salary NUMBER;
    BEGIN
        -- Validate input parameters
        IF p_gross_salary IS NULL OR p_gross_salary < 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Invalid gross salary value');
        END IF;
        
        IF p_tax_rate < 0 OR p_tax_rate > 1 THEN
            RAISE_APPLICATION_ERROR(-20004, 'Tax rate must be between 0 and 1');
        END IF;
        
        -- Calculate net salary
        v_net_salary := p_gross_salary - (p_gross_salary * p_tax_rate);
        
        RETURN ROUND(v_net_salary, 2);
        
    END calculate_net_salary_custom;

    -- Function to get complete employee details with net salary
    FUNCTION get_employee_net_salary(
        p_employee_id IN employees.employee_id%TYPE
    ) RETURN employee_rec IS
        v_employee employee_rec;
    BEGIN
        SELECT e.employee_id, e.first_name, e.last_name, e.salary,
               calculate_net_salary_emp(e.employee_id) as net_salary
        INTO v_employee
        FROM employees e
        WHERE e.employee_id = p_employee_id;
        
        RETURN v_employee;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20001, 'Employee ID ' || p_employee_id || ' not found');
    END get_employee_net_salary;

    -- Dynamic procedure using EXECUTE IMMEDIATE
    PROCEDURE dynamic_employee_operation(
        p_operation_type IN VARCHAR2,
        p_employee_id IN NUMBER DEFAULT NULL,
        p_new_salary IN NUMBER DEFAULT NULL,
        p_department IN VARCHAR2 DEFAULT NULL
    ) IS
        v_sql_stmt VARCHAR2(1000);
        v_old_salary employees.salary%TYPE;
        v_current_user VARCHAR2(100);
    BEGIN
        -- Use USER instead of CURRENT_USER
        v_current_user := 'Operation performed by: ' || USER;
        DBMS_OUTPUT.PUT_LINE(v_current_user);
        
        -- Convert operation type to uppercase for case-insensitive comparison
        CASE UPPER(p_operation_type)
            WHEN 'UPDATE_SALARY' THEN
                IF p_employee_id IS NULL OR p_new_salary IS NULL THEN
                    RAISE_APPLICATION_ERROR(-20005, 'Employee ID and new salary required for update');
                END IF;
                
                -- Get old salary for audit
                SELECT salary INTO v_old_salary 
                FROM employees 
                WHERE employee_id = p_employee_id;
                
                -- Dynamic SQL for salary update
                v_sql_stmt := 'UPDATE employees SET salary = :1 WHERE employee_id = :2';
                EXECUTE IMMEDIATE v_sql_stmt USING p_new_salary, p_employee_id;
                
                -- Audit the change
                INSERT INTO salary_audit (audit_id, employee_id, old_salary, new_salary, changed_by, change_date, operation_type)
                VALUES (salary_audit_seq.NEXTVAL, p_employee_id, v_old_salary, p_new_salary, USER, SYSDATE, 'SALARY_UPDATE');
                
                DBMS_OUTPUT.PUT_LINE('Salary updated for employee ' || p_employee_id || 
                                    ' from ' || v_old_salary || ' to ' || p_new_salary);
            
            WHEN 'DEPARTMENT_REPORT' THEN
                -- Dynamic SQL for department report
                IF p_department IS NOT NULL THEN
                    v_sql_stmt := 'SELECT employee_id, first_name, last_name, salary, department 
                                   FROM employees 
                                   WHERE department = :1 
                                   ORDER BY salary DESC';
                    DECLARE
                        v_emp_id employees.employee_id%TYPE;
                        v_first_name employees.first_name%TYPE;
                        v_last_name employees.last_name%TYPE;
                        v_salary employees.salary%TYPE;
                        v_dept employees.department%TYPE;
                        TYPE ref_cursor IS REF CURSOR;
                        v_cursor ref_cursor;
                    BEGIN
                        OPEN v_cursor FOR v_sql_stmt USING p_department;
                        DBMS_OUTPUT.PUT_LINE('Department Report for ' || p_department || ':');
                        DBMS_OUTPUT.PUT_LINE('ID  Name                 Salary    Department');
                        DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
                        LOOP
                            FETCH v_cursor INTO v_emp_id, v_first_name, v_last_name, v_salary, v_dept;
                            EXIT WHEN v_cursor%NOTFOUND;
                            DBMS_OUTPUT.PUT_LINE(
                                RPAD(v_emp_id, 4) || ' ' ||
                                RPAD(v_first_name || ' ' || v_last_name, 20) || ' ' ||
                                RPAD(v_salary, 9) || ' ' ||
                                v_dept
                            );
                        END LOOP;
                        CLOSE v_cursor;
                    END;
                ELSE
                    -- Report for all departments
                    v_sql_stmt := 'SELECT department, COUNT(*), AVG(salary) 
                                   FROM employees 
                                   GROUP BY department 
                                   ORDER BY department';
                    DECLARE
                        v_dept employees.department%TYPE;
                        v_count NUMBER;
                        v_avg_salary NUMBER;
                        TYPE ref_cursor IS REF CURSOR;
                        v_cursor ref_cursor;
                    BEGIN
                        OPEN v_cursor FOR v_sql_stmt;
                        DBMS_OUTPUT.PUT_LINE('Department Summary Report:');
                        DBMS_OUTPUT.PUT_LINE('Department     Employee Count  Avg Salary');
                        DBMS_OUTPUT.PUT_LINE('------------------------------------------');
                        LOOP
                            FETCH v_cursor INTO v_dept, v_count, v_avg_salary;
                            EXIT WHEN v_cursor%NOTFOUND;
                            DBMS_OUTPUT.PUT_LINE(
                                RPAD(v_dept, 15) || ' ' ||
                                RPAD(v_count, 15) || ' ' ||
                                ROUND(v_avg_salary, 2)
                            );
                        END LOOP;
                        CLOSE v_cursor;
                    END;
                END IF;
            
            WHEN 'INSERT_EMPLOYEE' THEN
                -- Dynamic insert (simplified for demonstration)
                DBMS_OUTPUT.PUT_LINE('Insert operation would go here with proper parameters');
            
            ELSE
                RAISE_APPLICATION_ERROR(-20006, 'Invalid operation type: ' || p_operation_type || 
                                        '. Valid operations: UPDATE_SALARY, DEPARTMENT_REPORT, INSERT_EMPLOYEE');
        END CASE;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END dynamic_employee_operation;

    -- Bulk processing procedure using cursor and loop
    PROCEDURE bulk_salary_report(
        p_department IN VARCHAR2 DEFAULT NULL
    ) IS
        CURSOR emp_cursor IS
            SELECT employee_id, first_name, last_name, salary, department, rssb_tax_rate
            FROM employees
            WHERE (p_department IS NULL OR department = p_department)
            ORDER BY department, salary DESC;
            
        v_total_gross NUMBER := 0;
        v_total_tax NUMBER := 0;
        v_total_net NUMBER := 0;
        v_employee_count NUMBER := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== BULK SALARY REPORT ===');
        IF p_department IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Department: ' || p_department);
        END IF;
        DBMS_OUTPUT.PUT_LINE('ID  Name                 Gross Salary  Tax Rate  Tax Amount  Net Salary');
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------');
        
        FOR emp_rec IN emp_cursor LOOP
            v_employee_count := v_employee_count + 1;
            
            DECLARE
                v_tax_amount NUMBER := emp_rec.salary * emp_rec.rssb_tax_rate;
                v_net_salary NUMBER := emp_rec.salary - v_tax_amount;
            BEGIN
                DBMS_OUTPUT.PUT_LINE(
                    RPAD(emp_rec.employee_id, 4) || ' ' ||
                    RPAD(emp_rec.first_name || ' ' || emp_rec.last_name, 20) || ' ' ||
                    RPAD(emp_rec.salary, 13) || ' ' ||
                    RPAD(emp_rec.rssb_tax_rate * 100 || '%', 9) || ' ' ||
                    RPAD(ROUND(v_tax_amount, 2), 11) || ' ' ||
                    ROUND(v_net_salary, 2)
                );
                
                v_total_gross := v_total_gross + emp_rec.salary;
                v_total_tax := v_total_tax + v_tax_amount;
                v_total_net := v_total_net + v_net_salary;
            END;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('----------------------------------------------------------------------');
        DBMS_OUTPUT.PUT_LINE('TOTALS for ' || v_employee_count || ' employees:');
        DBMS_OUTPUT.PUT_LINE('Gross: ' || ROUND(v_total_gross, 2) || 
                           ' | Tax: ' || ROUND(v_total_tax, 2) || 
                           ' | Net: ' || ROUND(v_total_net, 2));
        
    END bulk_salary_report;

    -- Procedure to demonstrate user context
    PROCEDURE show_user_context IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== USER CONTEXT DEMONSTRATION ===');
        DBMS_OUTPUT.PUT_LINE('Current user: ' || USER);
        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE('Explanation:');
        DBMS_OUTPUT.PUT_LINE('- USER returns the name of the current session user');
        DBMS_OUTPUT.PUT_LINE('- The package uses AUTHID DEFINER (default) which means');
        DBMS_OUTPUT.PUT_LINE('  it executes with the privileges of the package owner');
    END show_user_context;

END hr_management_pkg;
/









-- Corrected Test Script
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== HR EMPLOYEE MANAGEMENT SYSTEM TEST ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 1: Demonstrate user context
    DBMS_OUTPUT.PUT_LINE('TEST 1: USER CONTEXT');
    DBMS_OUTPUT.PUT_LINE('---------------------');
    hr_management_pkg.show_user_context;
    
    -- Test 2: Calculate net salary for individual employees
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 2: INDIVIDUAL NET SALARY CALCULATION');
    DBMS_OUTPUT.PUT_LINE('-----------------------------------------');
    
    DECLARE
        v_net_salary NUMBER;
        v_employee hr_management_pkg.employee_rec;
    BEGIN
        -- Test function with employee ID
        v_net_salary := hr_management_pkg.calculate_net_salary_emp(1);
        DBMS_OUTPUT.PUT_LINE('Employee 1 net salary: $' || v_net_salary);
        
        -- Test custom function with direct values
        v_net_salary := hr_management_pkg.calculate_net_salary_custom(50000, 0.05);
        DBMS_OUTPUT.PUT_LINE('Custom calculation (50,000 at 5%): $' || v_net_salary);
        
        -- Test function returning record
        v_employee := hr_management_pkg.get_employee_net_salary(2);
        DBMS_OUTPUT.PUT_LINE('Employee ' || v_employee.employee_id || ': ' || 
                           v_employee.first_name || ' ' || v_employee.last_name ||
                           ' | Gross: $' || v_employee.salary || 
                           ' | Net: $' || v_employee.net_salary);
    END;
    
    -- Test 3: Dynamic procedure - Salary update
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 3: DYNAMIC SALARY UPDATE');
    DBMS_OUTPUT.PUT_LINE('-----------------------------');
    hr_management_pkg.dynamic_employee_operation(
        p_operation_type => 'UPDATE_SALARY',
        p_employee_id => 1,
        p_new_salary => 55000
    );
    
    -- Test 4: Bulk salary report
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 4: BULK SALARY REPORT');
    DBMS_OUTPUT.PUT_LINE('---------------------------');
    hr_management_pkg.bulk_salary_report('IT');
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== ALL TESTS COMPLETED SUCCESSFULLY ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

