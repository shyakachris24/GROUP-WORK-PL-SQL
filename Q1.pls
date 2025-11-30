-- Create patients table
CREATE TABLE patients (
    patient_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    age NUMBER,
    gender VARCHAR2(10),
    admitted VARCHAR2(3) DEFAULT 'NO' CHECK (admitted IN ('YES', 'NO'))
);

-- Create doctors table
CREATE TABLE doctors (
    doctor_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    specialty VARCHAR2(100)
);


CREATE OR REPLACE PACKAGE hospital_mgmt_pkg IS
    -- Define collection type for bulk processing
    TYPE patient_rec IS RECORD (
        patient_id patients.patient_id%TYPE,
        name patients.name%TYPE,
        age patients.age%TYPE,
        gender patients.gender%TYPE,
        admitted patients.admitted%TYPE
    );
    
    TYPE patient_table IS TABLE OF patient_rec;
    
    -- Procedure to insert multiple patients using bulk collection
    PROCEDURE bulk_load_patients(
        p_patients IN patient_table
    );
    
    -- Function to display all patients (returns a cursor)
    FUNCTION show_all_patients RETURN SYS_REFCURSOR;
    
    -- Function to return the number of admitted patients
    FUNCTION count_admitted RETURN NUMBER;
    
    -- Procedure to update a patient's status as admitted
    PROCEDURE admit_patient(
        p_patient_id IN patients.patient_id%TYPE
    );
    
    -- Additional helper procedure for testing
    PROCEDURE display_patient_info;
    
END hospital_mgmt_pkg;
/




CREATE OR REPLACE PACKAGE BODY hospital_mgmt_pkg IS

    -- Procedure to insert multiple patients using bulk collection and FORALL
    PROCEDURE bulk_load_patients(
        p_patients IN patient_table
    ) IS
    BEGIN
        IF p_patients IS NULL OR p_patients.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Error: No patient data provided');
            RETURN;
        END IF;
        
        -- Use FORALL for bulk insertion
        FORALL i IN 1..p_patients.COUNT
            INSERT INTO patients (patient_id, name, age, gender, admitted)
            VALUES (p_patients(i).patient_id, p_patients(i).name, 
                   p_patients(i).age, p_patients(i).gender, p_patients(i).admitted);
        
        COMMIT; -- Commit for data consistency
        
        DBMS_OUTPUT.PUT_LINE('Successfully loaded ' || SQL%ROWCOUNT || ' patients');
        
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error: Duplicate patient ID found');
            RAISE;
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Error during bulk load: ' || SQLERRM);
            RAISE;
    END bulk_load_patients;

    -- Function to display all patients using ref cursor
    FUNCTION show_all_patients RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT patient_id, name, age, gender, admitted
            FROM patients
            ORDER BY patient_id;
        
        RETURN v_cursor;
    END show_all_patients;

    -- Function to count admitted patients
    FUNCTION count_admitted RETURN NUMBER IS
        v_admitted_count NUMBER := 0;
    BEGIN
        SELECT COUNT(*)
        INTO v_admitted_count
        FROM patients
        WHERE admitted = 'YES';
        
        RETURN v_admitted_count;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RETURN -1; -- Error indicator
    END count_admitted;

    -- Procedure to admit a patient
    PROCEDURE admit_patient(
        p_patient_id IN patients.patient_id%TYPE
    ) IS
        v_current_status patients.admitted%TYPE;
    BEGIN
        -- Check if patient exists and current status
        BEGIN
            SELECT admitted INTO v_current_status
            FROM patients
            WHERE patient_id = p_patient_id;
            
            IF v_current_status = 'YES' THEN
                DBMS_OUTPUT.PUT_LINE('Patient ' || p_patient_id || ' is already admitted');
                RETURN;
            END IF;
            
            -- Update patient status to admitted
            UPDATE patients
            SET admitted = 'YES'
            WHERE patient_id = p_patient_id;
            
            IF SQL%ROWCOUNT = 1 THEN
                COMMIT;
                DBMS_OUTPUT.PUT_LINE('Patient ' || p_patient_id || ' admitted successfully');
            ELSE
                DBMS_OUTPUT.PUT_LINE('No patient found with ID: ' || p_patient_id);
            END IF;
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Error: Patient with ID ' || p_patient_id || ' not found');
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Error admitting patient: ' || SQLERRM);
        END;
        
    END admit_patient;

    -- Helper procedure to display patient information
    PROCEDURE display_patient_info IS
        v_cursor SYS_REFCURSOR;
        v_patient_id patients.patient_id%TYPE;
        v_name patients.name%TYPE;
        v_age patients.age%TYPE;
        v_gender patients.gender%TYPE;
        v_admitted patients.admitted%TYPE;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('=== PATIENT INFORMATION ===');
        DBMS_OUTPUT.PUT_LINE('ID  Name                 Age  Gender  Admitted');
        DBMS_OUTPUT.PUT_LINE('---------------------------------------------');
        
        v_cursor := show_all_patients;
        LOOP
            FETCH v_cursor INTO v_patient_id, v_name, v_age, v_gender, v_admitted;
            EXIT WHEN v_cursor%NOTFOUND;
            DBMS_OUTPUT.PUT_LINE(
                RPAD(v_patient_id, 4) || ' ' ||
                RPAD(v_name, 20) || ' ' ||
                RPAD(v_age, 4) || ' ' ||
                RPAD(v_gender, 7) || ' ' ||
                v_admitted
            );
        END LOOP;
        CLOSE v_cursor;
        
        DBMS_OUTPUT.PUT_LINE('Total admitted patients: ' || count_admitted);
        
    END display_patient_info;

END hospital_mgmt_pkg;
/



-- Test Script for Hospital Management Package
SET SERVEROUTPUT ON;

DECLARE
    -- Declare patient collection for bulk loading
    v_patients hospital_mgmt_pkg.patient_table := hospital_mgmt_pkg.patient_table();
    
    -- Variables for testing
    v_cursor SYS_REFCURSOR;
    v_patient_id patients.patient_id%TYPE;
    v_name patients.name%TYPE;
    v_age patients.age%TYPE;
    v_gender patients.gender%TYPE;
    v_admitted patients.admitted%TYPE;
    v_admitted_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== HOSPITAL MANAGEMENT SYSTEM TEST ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Step 1: Prepare patient data for bulk loading
    DBMS_OUTPUT.PUT_LINE('1. PREPARING PATIENT DATA FOR BULK LOAD...');
    v_patients.EXTEND(6); -- Extend collection to hold 6 patients
    
    -- Initialize patient records
    v_patients(1) := hospital_mgmt_pkg.patient_rec(101, 'John Smith', 45, 'Male', 'NO');
    v_patients(2) := hospital_mgmt_pkg.patient_rec(102, 'Maria Garcia', 32, 'Female', 'NO');
    v_patients(3) := hospital_mgmt_pkg.patient_rec(103, 'Robert Johnson', 67, 'Male', 'YES');
    v_patients(4) := hospital_mgmt_pkg.patient_rec(104, 'Sarah Williams', 28, 'Female', 'NO');
    v_patients(5) := hospital_mgmt_pkg.patient_rec(105, 'Michael Brown', 53, 'Male', 'YES');
    v_patients(6) := hospital_mgmt_pkg.patient_rec(106, 'Emily Davis', 39, 'Female', 'NO');
    
    DBMS_OUTPUT.PUT_LINE('   Prepared ' || v_patients.COUNT || ' patient records');
    
    -- Step 2: Bulk load patients
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('2. BULK LOADING PATIENTS...');
    hospital_mgmt_pkg.bulk_load_patients(v_patients);
    
    -- Step 3: Display all patients using the helper procedure
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('3. DISPLAYING ALL PATIENTS...');
    hospital_mgmt_pkg.display_patient_info;
    
    -- Step 4: Test count_admitted function
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('4. TESTING COUNT_ADMITTED FUNCTION...');
    v_admitted_count := hospital_mgmt_pkg.count_admitted;
    DBMS_OUTPUT.PUT_LINE('   Currently admitted patients: ' || v_admitted_count);
    
    -- Step 5: Admit more patients
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('5. ADMITTING ADDITIONAL PATIENTS...');
    hospital_mgmt_pkg.admit_patient(101); -- Admit John Smith
    hospital_mgmt_pkg.admit_patient(104); -- Admit Sarah Williams
    hospital_mgmt_pkg.admit_patient(999); -- Try to admit non-existent patient
    
    -- Step 6: Verify changes
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('6. VERIFYING CHANGES...');
    v_admitted_count := hospital_mgmt_pkg.count_admitted;
    DBMS_OUTPUT.PUT_LINE('   Admitted patients after updates: ' || v_admitted_count);
    
    -- Step 7: Display final patient status
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('7. FINAL PATIENT STATUS...');
    hospital_mgmt_pkg.display_patient_info;
    
    -- Step 8: Test show_all_patients function with manual cursor handling
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('8. TESTING SHOW_ALL_PATIENTS WITH MANUAL CURSOR...');
    v_cursor := hospital_mgmt_pkg.show_all_patients;
    
    DBMS_OUTPUT.PUT_LINE('   Patient List from Cursor:');
    LOOP
        FETCH v_cursor INTO v_patient_id, v_name, v_age, v_gender, v_admitted;
        EXIT WHEN v_cursor%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('   - ' || v_name || ' (ID: ' || v_patient_id || ', Admitted: ' || v_admitted || ')');
    END LOOP;
    CLOSE v_cursor;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST COMPLETED SUCCESSFULLY ===');
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error during test: ' || SQLERRM);
        IF v_cursor%ISOPEN THEN
            CLOSE v_cursor;
        END IF;
END;
/




-- Additional Test Cases
SET SERVEROUTPUT ON;

BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ADDITIONAL TEST CASES ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    -- Test 1: Empty collection handling
    DBMS_OUTPUT.PUT_LINE('TEST 1: Testing empty collection handling...');
    DECLARE
        v_empty_patients hospital_mgmt_pkg.patient_table := hospital_mgmt_pkg.patient_table();
    BEGIN
        hospital_mgmt_pkg.bulk_load_patients(v_empty_patients);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('   Empty collection handled properly');
    END;
    
    -- Test 2: Duplicate patient ID
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 2: Testing duplicate patient ID...');
    DECLARE
        v_dup_patients hospital_mgmt_pkg.patient_table := hospital_mgmt_pkg.patient_table();
    BEGIN
        v_dup_patients.EXTEND(1);
        v_dup_patients(1) := hospital_mgmt_pkg.patient_rec(101, 'Duplicate Patient', 25, 'Male', 'NO');
        hospital_mgmt_pkg.bulk_load_patients(v_dup_patients);
    EXCEPTION
        WHEN DUP_VAL_ON_INDEX THEN
            DBMS_OUTPUT.PUT_LINE('   Duplicate ID properly rejected');
    END;
    
    -- Test 3: Admit already admitted patient
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 3: Testing admission of already admitted patient...');
    hospital_mgmt_pkg.admit_patient(103); -- Already admitted from initial data
    
    -- Test 4: Count admitted after all operations
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('TEST 4: Final admitted count...');
    DBMS_OUTPUT.PUT_LINE('   Total admitted patients: ' || hospital_mgmt_pkg.count_admitted);
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== ADDITIONAL TESTS COMPLETED ===');
    
END;
/