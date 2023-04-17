DROP USER HR CASCADE;
CREATE USER HR IDENTIFIED BY HR;
GRANT CONNECT,RESOURCE,dba TO HR;
GRANT UNLIMITED TABLESPACE TO HR;
ALTER PROFILE DEFAULT LIMIT PASSWORD_REUSE_TIME UNLIMITED;
ALTER PROFILE DEFAULT LIMIT PASSWORD_LIFE_TIME UNLIMITED;

CONNECT HR/HR@LOCALHOST:1521/XEPDB1


-- REGIONS table holds region information for locations
-- HR.LOCATIONS table has a foreign key to this table. 
CREATE TABLE regions  
    ( region_id      NUMBER   
                     CONSTRAINT region_id_nn NOT NULL 
    ,                CONSTRAINT reg_id_pk  
                        PRIMARY KEY (region_id) 
    , region_name    VARCHAR2(25)   
    );

-- COUNTRIES table holds country information for customers and company locations. 
-- OE.CUSTOMERS table and HR.LOCATIONS have a foreign key to this table.
CREATE TABLE countries   
    ( country_id      CHAR(2)   
                      CONSTRAINT country_id_nn NOT NULL 
    ,                 CONSTRAINT country_c_id_pk   
        	         PRIMARY KEY (country_id) 
    , country_name    VARCHAR2(40)   
    , region_id       NUMBER   
    ,                 CONSTRAINT countr_reg_fk  
        	         FOREIGN KEY (region_id)  
          	         REFERENCES regions (region_id)   
    )   
    ORGANIZATION INDEX;

-- LOCATIONS table holds address information for company departments. 
-- HR.DEPARTMENTS has a foreign key to this table. 
CREATE TABLE locations  
    ( location_id    NUMBER(4)  NOT NULL 
                     CONSTRAINT loc_id_pk  
       		        PRIMARY KEY  
    , street_address VARCHAR2(40)  
    , postal_code    VARCHAR2(12)  
    , city           VARCHAR2(30)  
	             CONSTRAINT loc_city_nn  NOT NULL  
    , state_province VARCHAR2(25)  
    , country_id     CHAR(2)  
    ,                CONSTRAINT loc_c_id_fk  
       		        FOREIGN KEY (country_id)  
        	        REFERENCES countries(country_id) 
    );

-- Useful for any subsequent addition of rows to LOCATIONS table 
-- Starts with 3300 
CREATE SEQUENCE locations_seq  
 START WITH     3300  
 INCREMENT BY   100  
 MAXVALUE       9900  
 NOCACHE  
 NOCYCLE;

-- DEPARTMENTS table holds company department information. 
-- HR.EMPLOYEES and HR.JOB_HISTORY have a foreign key to this table.
CREATE TABLE departments  
    ( department_id    NUMBER(4) 
                       CONSTRAINT dept_id_pk  
       		          PRIMARY KEY 
    , department_name  VARCHAR2(30)  
	               CONSTRAINT dept_name_nn  NOT NULL  
    , manager_id       NUMBER(6)  
    , location_id      NUMBER(4)  
    ,                  CONSTRAINT dept_loc_fk  
       		          FOREIGN KEY (location_id)  
        	          REFERENCES locations (location_id)  
    );

-- Useful for any subsequent addition of rows to DEPARTMENTS table
-- Starts with 280 
CREATE SEQUENCE departments_seq  
 START WITH     280  
 INCREMENT BY   10  
 MAXVALUE       9990  
 NOCACHE  
 NOCYCLE;

-- JOBS table holds the different names of job roles within the company. 
-- HR.EMPLOYEES has a foreign key to this table. 
CREATE TABLE jobs  
    ( job_id         VARCHAR2(10)  
                     CONSTRAINT job_id_pk  
      		        PRIMARY KEY 
    , job_title      VARCHAR2(35)  
	             CONSTRAINT job_title_nn  NOT NULL  
    , min_salary     NUMBER(6)  
    , max_salary     NUMBER(6)  
    );

-- EMPLOYEES table holds the employee personnel  information for the company. 
-- HR.EMPLOYEES has a self referencing foreign key to this table.
CREATE TABLE employees  
    ( employee_id    NUMBER(6)  
                     CONSTRAINT emp_emp_id_pk  
                        PRIMARY KEY 
    , first_name     VARCHAR2(20)  
    , last_name      VARCHAR2(25)  
	             CONSTRAINT emp_last_name_nn  NOT NULL  
    , email          VARCHAR2(25)  
	             CONSTRAINT emp_email_nn  NOT NULL  
    , CONSTRAINT     emp_email_uk  
                     UNIQUE (email)  
    , phone_number   VARCHAR2(20)  
    , hire_date      DATE  
	             CONSTRAINT emp_hire_date_nn  NOT NULL  
    , job_id         VARCHAR2(10)  
	             CONSTRAINT emp_job_nn  NOT NULL  
    , salary         NUMBER(8,2)  
                     CONSTRAINT emp_salary_min  
                        CHECK (salary > 0)  
    , commission_pct NUMBER(2,2)  
    , manager_id     NUMBER(6)  
    ,                CONSTRAINT emp_manager_fk  
                        FOREIGN KEY (manager_id)  
                        REFERENCES employees 
    , department_id  NUMBER(4)  
    ,                CONSTRAINT emp_dept_fk  
                        FOREIGN KEY (department_id)  
                        REFERENCES departments 
    );

-- The foreign key can now be created to the EMPLOYEES table.
ALTER TABLE departments  
   ADD (CONSTRAINT dept_mgr_fk  
      	FOREIGN KEY (manager_id)  
      	REFERENCES employees (employee_id)  
    );

-- Useful for any subsequent addition of rows to employees table.
-- Starts with 207  
CREATE SEQUENCE employees_seq  
 START WITH     207  
 INCREMENT BY   1  
 NOCACHE  
 NOCYCLE;

-- JOB_HISTORY table holds the history of jobs that employees have held in the past.
-- HR.JOBS, HR_DEPARTMENTS, and HR.EMPLOYEES have a foreign key to this table.
CREATE TABLE job_history  
    ( employee_id   NUMBER(6)  
	            CONSTRAINT jhist_employee_nn  NOT NULL  
    ,               CONSTRAINT jhist_emp_fk  
                       FOREIGN KEY (employee_id)  
                       REFERENCES employees  
    , start_date    DATE  
	            CONSTRAINT jhist_start_date_nn  NOT NULL  
    , end_date      DATE  
	            CONSTRAINT jhist_end_date_nn  NOT NULL  
    , job_id        VARCHAR2(10)  
	            CONSTRAINT jhist_job_nn  NOT NULL  
    ,               CONSTRAINT jhist_job_fk  
                       FOREIGN KEY (job_id)  
                       REFERENCES jobs  
    , department_id NUMBER(4)  
    ,               CONSTRAINT jhist_dept_fk  
                       FOREIGN KEY (department_id)  
                       REFERENCES departments 
    , CONSTRAINT    jhist_emp_id_st_date_pk  
                       PRIMARY KEY (employee_id, start_date) 
    , CONSTRAINT    jhist_date_interval  
                       CHECK (end_date > start_date)  
    ) ;

-- EMP_DETAILS_VIEW joins the employees, jobs, departments, jobs, countries, and locations table to provide details about employees.
CREATE OR REPLACE VIEW emp_details_view  
  (employee_id,  
   job_id,  
   manager_id,  
   department_id,  
   location_id,  
   country_id,  
   first_name,  
   last_name,  
   salary,  
   commission_pct,  
   department_name,  
   job_title,  
   city,  
   state_province,  
   country_name,  
   region_name)  
AS SELECT  
  e.employee_id,   
  e.job_id,   
  e.manager_id,   
  e.department_id,  
  d.location_id,  
  l.country_id,  
  e.first_name,  
  e.last_name,  
  e.salary,  
  e.commission_pct,  
  d.department_name,  
  j.job_title,  
  l.city,  
  l.state_province,  
  c.country_name,  
  r.region_name  
FROM  
  employees e,  
  departments d,  
  jobs j,  
  locations l,  
  countries c,  
  regions r  
WHERE e.department_id = d.department_id  
  AND d.location_id = l.location_id  
  AND l.country_id = c.country_id  
  AND c.region_id = r.region_id  
  AND j.job_id = e.job_id   
WITH READ ONLY;

-- insert data into the REGIONS table
BEGIN  
INSERT INTO regions VALUES   
        ( 1  
        , 'Europe'   
        );  
  
INSERT INTO regions VALUES   
        ( 2  
        , 'Americas'   
        );  
  
INSERT INTO regions VALUES   
        ( 3  
        , 'Asia'   
        );  
  
INSERT INTO regions VALUES   
        ( 4  
        , 'Middle East and Africa'   
        );  
END; 
/

-- insert data into the COUNTRIES table 
BEGIN  
INSERT INTO countries VALUES   
        ( 'IT'  
        , 'Italy'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'JP'  
        , 'Japan'  
	, 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'US'  
        , 'United States of America'  
        , 2   
        );  
  
INSERT INTO countries VALUES   
        ( 'CA'  
        , 'Canada'  
        , 2   
        );  
  
INSERT INTO countries VALUES   
        ( 'CN'  
        , 'China'  
        , 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'IN'  
        , 'India'  
        , 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'AU'  
        , 'Australia'  
        , 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'ZW'  
        , 'Zimbabwe'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'SG'  
        , 'Singapore'  
        , 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'UK'  
        , 'United Kingdom'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'FR'  
        , 'France'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'DE'  
        , 'Germany'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'ZM'  
        , 'Zambia'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'EG'  
        , 'Egypt'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'BR'  
        , 'Brazil'  
        , 2   
        );  
  
INSERT INTO countries VALUES   
        ( 'CH'  
        , 'Switzerland'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'NL'  
        , 'Netherlands'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'MX'  
        , 'Mexico'  
        , 2   
        );  
  
INSERT INTO countries VALUES   
        ( 'KW'  
        , 'Kuwait'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'IL'  
        , 'Israel'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'DK'  
        , 'Denmark'  
        , 1   
        );  
  
INSERT INTO countries VALUES   
        ( 'ML'  
        , 'Malaysia'  
        , 3   
        );  
  
INSERT INTO countries VALUES   
        ( 'NG'  
        , 'Nigeria'  
        , 4   
        );  
  
INSERT INTO countries VALUES   
        ( 'AR'  
        , 'Argentina'  
        , 2   
        );  
  
INSERT INTO countries VALUES   
        ( 'BE'  
        , 'Belgium'  
        , 1   
        );  
END; 
/

-- insert data into the LOCATIONS table
BEGIN  
INSERT INTO locations VALUES   
        ( 1000   
        , '1297 Via Cola di Rie'  
        , '00989'  
        , 'Roma'  
        , NULL  
        , 'IT'  
        );  
  
INSERT INTO locations VALUES   
        ( 1100   
        , '93091 Calle della Testa'  
        , '10934'  
        , 'Venice'  
        , NULL  
        , 'IT'  
        );  
  
INSERT INTO locations VALUES   
        ( 1200   
        , '2017 Shinjuku-ku'  
        , '1689'  
        , 'Tokyo'  
        , 'Tokyo Prefecture'  
        , 'JP'  
        );  
  
INSERT INTO locations VALUES   
        ( 1300   
        , '9450 Kamiya-cho'  
        , '6823'  
        , 'Hiroshima'  
        , NULL  
        , 'JP'  
        );  
  
INSERT INTO locations VALUES   
        ( 1400   
        , '2014 Jabberwocky Rd'  
        , '26192'  
        , 'Southlake'  
        , 'Texas'  
        , 'US'  
        );  
  
INSERT INTO locations VALUES   
        ( 1500   
        , '2011 Interiors Blvd'  
        , '99236'  
        , 'South San Francisco'  
        , 'California'  
        , 'US'  
        );  
  
INSERT INTO locations VALUES   
        ( 1600   
        , '2007 Zagora St'  
        , '50090'  
        , 'South Brunswick'  
        , 'New Jersey'  
        , 'US'  
        );  
  
INSERT INTO locations VALUES   
        ( 1700   
        , '2004 Charade Rd'  
        , '98199'  
        , 'Seattle'  
        , 'Washington'  
        , 'US'  
        );  
  
INSERT INTO locations VALUES   
        ( 1800   
        , '147 Spadina Ave'  
        , 'M5V 2L7'  
        , 'Toronto'  
        , 'Ontario'  
        , 'CA'  
        );  
  
INSERT INTO locations VALUES   
        ( 1900   
        , '6092 Boxwood St'  
        , 'YSW 9T2'  
        , 'Whitehorse'  
        , 'Yukon'  
        , 'CA'  
        );  
  
INSERT INTO locations VALUES   
        ( 2000   
        , '40-5-12 Laogianggen'  
        , '190518'  
        , 'Beijing'  
        , NULL  
        , 'CN'  
        );  
  
INSERT INTO locations VALUES   
        ( 2100   
        , '1298 Vileparle (E)'  
        , '490231'  
        , 'Bombay'  
        , 'Maharashtra'  
        , 'IN'  
        );  
  
INSERT INTO locations VALUES   
        ( 2200   
        , '12-98 Victoria Street'  
        , '2901'  
        , 'Sydney'  
        , 'New South Wales'  
        , 'AU'  
        );  
  
INSERT INTO locations VALUES   
        ( 2300   
        , '198 Clementi North'  
        , '540198'  
        , 'Singapore'  
        , NULL  
        , 'SG'  
        );  
  
INSERT INTO locations VALUES   
        ( 2400   
        , '8204 Arthur St'  
        , NULL  
        , 'London'  
        , NULL  
        , 'UK'  
        );  
  
INSERT INTO locations VALUES   
        ( 2500   
        , 'Magdalen Centre, The Oxford Science Park'  
        , 'OX9 9ZB'  
        , 'Oxford'  
        , 'Oxford'  
        , 'UK'  
        );  
  
INSERT INTO locations VALUES   
        ( 2600   
        , '9702 Chester Road'  
        , '09629850293'  
        , 'Stretford'  
        , 'Manchester'  
        , 'UK'  
        );  
  
INSERT INTO locations VALUES   
        ( 2700   
        , 'Schwanthalerstr. 7031'  
        , '80925'  
        , 'Munich'  
        , 'Bavaria'  
        , 'DE'  
        );  
  
INSERT INTO locations VALUES   
        ( 2800   
        , 'Rua Frei Caneca 1360 '  
        , '01307-002'  
        , 'Sao Paulo'  
        , 'Sao Paulo'  
        , 'BR'  
        );  
  
INSERT INTO locations VALUES   
        ( 2900   
        , '20 Rue des Corps-Saints'  
        , '1730'  
        , 'Geneva'  
        , 'Geneve'  
        , 'CH'  
        );  
  
INSERT INTO locations VALUES   
        ( 3000   
        , 'Murtenstrasse 921'  
        , '3095'  
        , 'Bern'  
        , 'BE'  
        , 'CH'  
        );  
  
INSERT INTO locations VALUES   
        ( 3100   
        , 'Pieter Breughelstraat 837'  
        , '3029SK'  
        , 'Utrecht'  
        , 'Utrecht'  
        , 'NL'  
        );  
  
INSERT INTO locations VALUES   
        ( 3200   
        , 'Mariano Escobedo 9991'  
        , '11932'  
        , 'Mexico City'  
        , 'Distrito Federal,'  
        , 'MX'  
        );  
END; 
/

-- disable integrity constraint to EMPLOYEES to load data
ALTER TABLE departments   
  DISABLE CONSTRAINT dept_mgr_fk;

-- insert data into the DEPARTMENTS table
BEGIN  
INSERT INTO departments VALUES   
        ( 10  
        , 'Administration'  
        , 200  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 20  
        , 'Marketing'  
        , 201  
        , 1800  
        );  
                                  
INSERT INTO departments VALUES   
        ( 30  
        , 'Purchasing'  
        , 114  
        , 1700  
	);  
                  
INSERT INTO departments VALUES   
        ( 40  
        , 'Human Resources'  
        , 203  
        , 2400  
        );  
  
INSERT INTO departments VALUES   
        ( 50  
        , 'Shipping'  
        , 121  
        , 1500  
        );  
                  
INSERT INTO departments VALUES   
        ( 60   
        , 'IT'  
        , 103  
        , 1400  
        );  
                  
INSERT INTO departments VALUES   
        ( 70   
        , 'Public Relations'  
        , 204  
        , 2700  
        );  
                  
INSERT INTO departments VALUES   
        ( 80   
        , 'Sales'  
        , 145  
        , 2500  
        );  
                  
INSERT INTO departments VALUES   
        ( 90   
        , 'Executive'  
        , 100  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 100   
        , 'Finance'  
        , 108  
        , 1700  
        );  
                  
INSERT INTO departments VALUES   
        ( 110   
        , 'Accounting'  
        , 205  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 120   
        , 'Treasury'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 130   
        , 'Corporate Tax'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 140   
        , 'Control And Credit'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 150   
        , 'Shareholder Services'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 160   
        , 'Benefits'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 170   
        , 'Manufacturing'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 180   
        , 'Construction'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 190   
        , 'Contracting'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 200   
        , 'Operations'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 210   
        , 'IT Support'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 220   
        , 'NOC'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 230   
        , 'IT Helpdesk'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 240   
        , 'Government Sales'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 250   
        , 'Retail Sales'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 260   
        , 'Recruiting'  
        , NULL  
        , 1700  
        );  
  
INSERT INTO departments VALUES   
        ( 270   
        , 'Payroll'  
        , NULL  
        , 1700  
        );  
END; 
/

-- insert data into the JOBS table
BEGIN  
INSERT INTO jobs VALUES   
        ( 'AD_PRES'  
        , 'President'  
        , 20080  
        , 40000  
        );  
INSERT INTO jobs VALUES   
        ( 'AD_VP'  
        , 'Administration Vice President'  
        , 15000  
        , 30000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'AD_ASST'  
        , 'Administration Assistant'  
        , 3000  
        , 6000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'FI_MGR'  
        , 'Finance Manager'  
        , 8200  
        , 16000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'FI_ACCOUNT'  
        , 'Accountant'  
        , 4200  
        , 9000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'AC_MGR'  
        , 'Accounting Manager'  
        , 8200  
        , 16000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'AC_ACCOUNT'  
        , 'Public Accountant'  
        , 4200  
        , 9000  
        );  
INSERT INTO jobs VALUES   
        ( 'SA_MAN'  
        , 'Sales Manager'  
        , 10000  
        , 20080  
        );  
  
INSERT INTO jobs VALUES   
        ( 'SA_REP'  
        , 'Sales Representative'  
        , 6000  
        , 12008  
        );  
  
INSERT INTO jobs VALUES   
        ( 'PU_MAN'  
        , 'Purchasing Manager'  
        , 8000  
        , 15000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'PU_CLERK'  
        , 'Purchasing Clerk'  
        , 2500  
        , 5500  
        );  
  
INSERT INTO jobs VALUES   
        ( 'ST_MAN'  
        , 'Stock Manager'  
        , 5500  
        , 8500  
        );  
INSERT INTO jobs VALUES   
        ( 'ST_CLERK'  
        , 'Stock Clerk'  
        , 2008  
        , 5000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'SH_CLERK'  
        , 'Shipping Clerk'  
        , 2500  
        , 5500  
        );  
  
INSERT INTO jobs VALUES   
        ( 'IT_PROG'  
        , 'Programmer'  
        , 4000  
        , 10000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'MK_MAN'  
        , 'Marketing Manager'  
        , 9000  
        , 15000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'MK_REP'  
        , 'Marketing Representative'  
        , 4000  
        , 9000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'HR_REP'  
        , 'Human Resources Representative'  
        , 4000  
        , 9000  
        );  
  
INSERT INTO jobs VALUES   
        ( 'PR_REP'  
        , 'Public Relations Representative'  
        , 4500  
        , 10500  
        );  
END; 
/

-- insert data into the EMPLOYEES table 1
BEGIN    
INSERT INTO employees VALUES     
        ( 100    
        , 'Steven'    
        , 'King'    
        , 'SKING'    
        , '515.123.4567'    
        , TO_DATE('17-06-2003', 'dd-MM-yyyy')    
        , 'AD_PRES'    
        , 24000    
        , NULL    
        , NULL    
        , 90    
        );    
    
INSERT INTO employees VALUES     
        ( 101    
        , 'Neena'    
        , 'Kochhar'    
        , 'NKOCHHAR'    
        , '515.123.4568'    
        , TO_DATE('21-09-2005', 'dd-MM-yyyy')    
        , 'AD_VP'    
        , 17000    
        , NULL    
        , 100    
        , 90    
        );    
    
INSERT INTO employees VALUES     
        ( 102    
        , 'Lex'    
        , 'De Haan'    
        , 'LDEHAAN'    
        , '515.123.4569'    
        , TO_DATE('13-01-2001', 'dd-MM-yyyy')    
        , 'AD_VP'    
        , 17000    
        , NULL    
        , 100    
        , 90    
        );    
    
INSERT INTO employees VALUES     
        ( 103    
        , 'Alexander'    
        , 'Hunold'    
        , 'AHUNOLD'    
        , '590.423.4567'    
        , TO_DATE('03-01-2006', 'dd-MM-yyyy')    
        , 'IT_PROG'    
        , 9000    
        , NULL    
        , 102    
        , 60    
        );    
    
INSERT INTO employees VALUES     
        ( 104    
        , 'Bruce'    
        , 'Ernst'    
        , 'BERNST'    
        , '590.423.4568'    
        , TO_DATE('21-05-2007', 'dd-MM-yyyy')    
        , 'IT_PROG'    
        , 6000    
        , NULL    
        , 103    
        , 60    
        );    
    
INSERT INTO employees VALUES     
        ( 105    
        , 'David'    
        , 'Austin'    
        , 'DAUSTIN'    
        , '590.423.4569'    
        , TO_DATE('25-06-2005', 'dd-MM-yyyy')    
        , 'IT_PROG'    
        , 4800    
        , NULL    
        , 103    
        , 60    
        );    
    
INSERT INTO employees VALUES     
        ( 106    
        , 'Valli'    
        , 'Pataballa'    
        , 'VPATABAL'    
        , '590.423.4560'    
        , TO_DATE('05-02-2006', 'dd-MM-yyyy')    
        , 'IT_PROG'    
        , 4800    
        , NULL    
        , 103    
        , 60    
        );    
    
INSERT INTO employees VALUES     
        ( 107    
        , 'Diana'    
        , 'Lorentz'    
        , 'DLORENTZ'    
        , '590.423.5567'    
        , TO_DATE('07-02-2007', 'dd-MM-yyyy')    
        , 'IT_PROG'    
        , 4200    
        , NULL    
        , 103    
        , 60    
        );    
    
INSERT INTO employees VALUES     
        ( 108    
        , 'Nancy'    
        , 'Greenberg'    
        , 'NGREENBE'    
        , '515.124.4569'    
        , TO_DATE('17-08-2002', 'dd-MM-yyyy')    
        , 'FI_MGR'    
        , 12008    
        , NULL    
        , 101    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 109    
        , 'Daniel'    
        , 'Faviet'    
        , 'DFAVIET'    
        , '515.124.4169'    
        , TO_DATE('16-08-2002', 'dd-MM-yyyy')    
        , 'FI_ACCOUNT'    
        , 9000    
        , NULL    
        , 108    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 110    
        , 'John'    
        , 'Chen'    
        , 'JCHEN'    
        , '515.124.4269'    
        , TO_DATE('28-09-2005', 'dd-MM-yyyy')    
        , 'FI_ACCOUNT'    
        , 8200    
        , NULL    
        , 108    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 111    
        , 'Ismael'    
        , 'Sciarra'    
        , 'ISCIARRA'    
        , '515.124.4369'    
        , TO_DATE('30-09-2005', 'dd-MM-yyyy')    
        , 'FI_ACCOUNT'    
        , 7700    
        , NULL    
        , 108    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 112    
        , 'Jose Manuel'    
        , 'Urman'    
        , 'JMURMAN'    
        , '515.124.4469'    
        , TO_DATE('07-03-2006', 'dd-MM-yyyy')    
        , 'FI_ACCOUNT'    
        , 7800    
        , NULL    
        , 108    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 113    
        , 'Luis'    
        , 'Popp'    
        , 'LPOPP'    
        , '515.124.4567'    
        , TO_DATE('07-12-2007', 'dd-MM-yyyy')    
        , 'FI_ACCOUNT'    
        , 6900    
        , NULL    
        , 108    
        , 100    
        );    
    
INSERT INTO employees VALUES     
        ( 114    
        , 'Den'    
        , 'Raphaely'    
        , 'DRAPHEAL'    
        , '515.127.4561'    
        , TO_DATE('07-12-2002', 'dd-MM-yyyy')    
        , 'PU_MAN'    
        , 11000    
        , NULL    
        , 100    
        , 30    
        );    
    
INSERT INTO employees VALUES     
        ( 115    
        , 'Alexander'    
        , 'Khoo'    
        , 'AKHOO'    
        , '515.127.4562'    
        , TO_DATE('18-05-2003', 'dd-MM-yyyy')    
        , 'PU_CLERK'    
        , 3100    
        , NULL    
        , 114    
        , 30    
        );    
    
INSERT INTO employees VALUES     
        ( 116    
        , 'Shelli'    
        , 'Baida'    
        , 'SBAIDA'    
        , '515.127.4563'    
        , TO_DATE('24-12-2005', 'dd-MM-yyyy')    
        , 'PU_CLERK'    
        , 2900    
        , NULL    
        , 114    
        , 30    
        );    
    
INSERT INTO employees VALUES     
        ( 117    
        , 'Sigal'    
        , 'Tobias'    
        , 'STOBIAS'    
        , '515.127.4564'    
        , TO_DATE('24-07-2005', 'dd-MM-yyyy')    
        , 'PU_CLERK'    
        , 2800    
        , NULL    
        , 114    
        , 30    
        );    
    
INSERT INTO employees VALUES     
        ( 118    
        , 'Guy'    
        , 'Himuro'    
        , 'GHIMURO'    
        , '515.127.4565'    
        , TO_DATE('15-11-2006', 'dd-MM-yyyy')    
        , 'PU_CLERK'    
        , 2600    
        , NULL    
        , 114    
        , 30    
        );    
    
INSERT INTO employees VALUES     
        ( 119    
        , 'Karen'    
        , 'Colmenares'    
        , 'KCOLMENA'    
        , '515.127.4566'    
        , TO_DATE('10-08-2007', 'dd-MM-yyyy')    
        , 'PU_CLERK'    
        , 2500    
        , NULL    
        , 114    
        , 30    
        );    
END; 
/

-- insert data into the EMPLOYEES table 2
-- Broken out due to 10k limit per statement
begin 
INSERT INTO employees VALUES     
        ( 120    
        , 'Matthew'    
        , 'Weiss'    
        , 'MWEISS'    
        , '650.123.1234'    
        , TO_DATE('18-07-2004', 'dd-MM-yyyy')    
        , 'ST_MAN'    
        , 8000    
        , NULL    
        , 100    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 121    
        , 'Adam'    
        , 'Fripp'    
        , 'AFRIPP'    
        , '650.123.2234'    
        , TO_DATE('10-04-2005', 'dd-MM-yyyy')    
        , 'ST_MAN'    
        , 8200    
        , NULL    
        , 100    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 122    
        , 'Payam'    
        , 'Kaufling'    
        , 'PKAUFLIN'    
        , '650.123.3234'    
        , TO_DATE('01-05-2003', 'dd-MM-yyyy')    
        , 'ST_MAN'    
        , 7900    
        , NULL    
        , 100    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 123    
        , 'Shanta'    
        , 'Vollman'    
        , 'SVOLLMAN'    
        , '650.123.4234'    
        , TO_DATE('10-10-2005', 'dd-MM-yyyy')    
        , 'ST_MAN'    
        , 6500    
        , NULL    
        , 100    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 124    
        , 'Kevin'    
        , 'Mourgos'    
        , 'KMOURGOS'    
        , '650.123.5234'    
        , TO_DATE('16-11-2007', 'dd-MM-yyyy')    
        , 'ST_MAN'    
        , 5800    
        , NULL    
        , 100    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 125    
        , 'Julia'    
        , 'Nayer'    
        , 'JNAYER'    
        , '650.124.1214'    
        , TO_DATE('16-07-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3200    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 126    
        , 'Irene'    
        , 'Mikkilineni'    
        , 'IMIKKILI'    
        , '650.124.1224'    
        , TO_DATE('28-09-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2700    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 127    
        , 'James'    
        , 'Landry'    
        , 'JLANDRY'    
        , '650.124.1334'    
        , TO_DATE('14-01-2007', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2400    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 128    
        , 'Steven'    
        , 'Markle'    
        , 'SMARKLE'    
        , '650.124.1434'    
        , TO_DATE('08-03-2008', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2200    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 129    
        , 'Laura'    
        , 'Bissot'    
        , 'LBISSOT'    
        , '650.124.5234'    
        , TO_DATE('20-08-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3300    
        , NULL    
        , 121    
        , 50    
        );    
END; 
/

-- insert data into the EMPLOYEES table 3
-- Broken out due to 10k limit per statement
begin  
INSERT INTO employees VALUES     
        ( 130    
        , 'Mozhe'    
        , 'Atkinson'    
        , 'MATKINSO'    
        , '650.124.6234'    
        , TO_DATE('30-10-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2800    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 131    
        , 'James'    
        , 'Marlow'    
        , 'JAMRLOW'    
        , '650.124.7234'    
        , TO_DATE('16-02-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2500    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 132    
        , 'TJ'    
        , 'Olson'    
        , 'TJOLSON'    
        , '650.124.8234'    
        , TO_DATE('10-04-2007', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2100    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 133    
        , 'Jason'    
        , 'Mallin'    
        , 'JMALLIN'    
        , '650.127.1934'    
        , TO_DATE('14-06-2004', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3300    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 134    
        , 'Michael'    
        , 'Rogers'    
        , 'MROGERS'    
        , '650.127.1834'    
        , TO_DATE('26-08-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2900    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 135    
        , 'Ki'    
        , 'Gee'    
        , 'KGEE'    
        , '650.127.1734'    
        , TO_DATE('12-12-2007', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2400    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 136    
        , 'Hazel'    
        , 'Philtanker'    
        , 'HPHILTAN'    
        , '650.127.1634'    
        , TO_DATE('06-02-2008', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2200    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 137    
        , 'Renske'    
        , 'Ladwig'    
        , 'RLADWIG'    
        , '650.121.1234'    
        , TO_DATE('14-07-2003', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3600    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 138    
        , 'Stephen'    
        , 'Stiles'    
        , 'SSTILES'    
        , '650.121.2034'    
        , TO_DATE('26-10-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3200    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 139    
        , 'John'    
        , 'Seo'    
        , 'JSEO'    
        , '650.121.2019'    
        , TO_DATE('12-02-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2700    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 140    
        , 'Joshua'    
        , 'Patel'    
        , 'JPATEL'    
        , '650.121.1834'    
        , TO_DATE('06-04-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2500    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 141    
        , 'Trenna'    
        , 'Rajs'    
        , 'TRAJS'    
        , '650.121.8009'    
        , TO_DATE('17-10-2003', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3500    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 142    
        , 'Curtis'    
        , 'Davies'    
        , 'CDAVIES'    
        , '650.121.2994'    
        , TO_DATE('29-01-2005', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 3100    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 143    
        , 'Randall'    
        , 'Matos'    
        , 'RMATOS'    
        , '650.121.2874'    
        , TO_DATE('15-03-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2600    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 144    
        , 'Peter'    
        , 'Vargas'    
        , 'PVARGAS'    
        , '650.121.2004'    
        , TO_DATE('09-07-2006', 'dd-MM-yyyy')    
        , 'ST_CLERK'    
        , 2500    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 145    
        , 'John'    
        , 'Russell'    
        , 'JRUSSEL'    
        , '011.44.1344.429268'    
        , TO_DATE('01-10-2004', 'dd-MM-yyyy')    
        , 'SA_MAN'    
        , 14000    
        , .4    
        , 100    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 146    
        , 'Karen'    
        , 'Partners'    
        , 'KPARTNER'    
        , '011.44.1344.467268'    
        , TO_DATE('05-01-2005', 'dd-MM-yyyy')    
        , 'SA_MAN'    
        , 13500    
        , .3    
        , 100    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 147    
        , 'Alberto'    
        , 'Errazuriz'    
        , 'AERRAZUR'    
        , '011.44.1344.429278'    
        , TO_DATE('10-03-2005', 'dd-MM-yyyy')    
        , 'SA_MAN'    
        , 12000    
        , .3    
        , 100    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 148    
        , 'Gerald'    
        , 'Cambrault'    
        , 'GCAMBRAU'    
        , '011.44.1344.619268'    
        , TO_DATE('15-10-2007', 'dd-MM-yyyy')    
        , 'SA_MAN'    
        , 11000    
        , .3    
        , 100    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 149    
        , 'Eleni'    
        , 'Zlotkey'    
        , 'EZLOTKEY'    
        , '011.44.1344.429018'    
        , TO_DATE('29-01-2008', 'dd-MM-yyyy')    
        , 'SA_MAN'    
        , 10500    
        , .2    
        , 100    
        , 80    
        );    
end;
/

-- insert data into the EMPLOYEES table 4
begin 
INSERT INTO employees VALUES     
        ( 150    
        , 'Peter'    
        , 'Tucker'    
        , 'PTUCKER'    
        , '011.44.1344.129268'    
        , TO_DATE('30-01-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 10000    
        , .3    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 151    
        , 'David'    
        , 'Bernstein'    
        , 'DBERNSTE'    
        , '011.44.1344.345268'    
        , TO_DATE('24-03-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9500    
        , .25    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 152    
        , 'Peter'    
        , 'Hall'    
        , 'PHALL'    
        , '011.44.1344.478968'    
        , TO_DATE('20-08-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9000    
        , .25    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 153    
        , 'Christopher'    
        , 'Olsen'    
        , 'COLSEN'    
        , '011.44.1344.498718'    
        , TO_DATE('30-03-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 8000    
        , .2    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 154    
        , 'Nanette'    
        , 'Cambrault'    
        , 'NCAMBRAU'    
        , '011.44.1344.987668'    
        , TO_DATE('09-12-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7500    
        , .2    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 155    
        , 'Oliver'    
        , 'Tuvault'    
        , 'OTUVAULT'    
        , '011.44.1344.486508'    
        , TO_DATE('23-11-2007', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7000    
        , .15    
        , 145    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 156    
        , 'Janette'    
        , 'King'    
        , 'JKING'    
        , '011.44.1345.429268'    
        , TO_DATE('30-01-2004', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 10000    
        , .35    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 157    
        , 'Patrick'    
        , 'Sully'    
        , 'PSULLY'    
        , '011.44.1345.929268'    
        , TO_DATE('04-03-2004', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9500    
        , .35    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 158    
        , 'Allan'    
        , 'McEwen'    
        , 'AMCEWEN'    
        , '011.44.1345.829268'    
        , TO_DATE('01-08-2004', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9000    
        , .35    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 159    
        , 'Lindsey'    
        , 'Smith'    
        , 'LSMITH'    
        , '011.44.1345.729268'    
        , TO_DATE('10-03-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 8000    
        , .3    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 160    
        , 'Louise'    
        , 'Doran'    
        , 'LDORAN'    
        , '011.44.1345.629268'    
        , TO_DATE('15-12-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7500    
        , .3    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 161    
        , 'Sarath'    
        , 'Sewall'    
        , 'SSEWALL'    
        , '011.44.1345.529268'    
        , TO_DATE('03-11-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7000    
        , .25    
        , 146    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 162    
        , 'Clara'    
        , 'Vishney'    
        , 'CVISHNEY'    
        , '011.44.1346.129268'    
        , TO_DATE('11-11-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 10500    
        , .25    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 163    
        , 'Danielle'    
        , 'Greene'    
        , 'DGREENE'    
        , '011.44.1346.229268'    
        , TO_DATE('19-03-2007', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9500    
        , .15    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 164    
        , 'Mattea'    
        , 'Marvins'    
        , 'MMARVINS'    
        , '011.44.1346.329268'    
        , TO_DATE('24-01-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7200    
        , .10    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 165    
        , 'David'    
        , 'Lee'    
        , 'DLEE'    
        , '011.44.1346.529268'    
        , TO_DATE('23-02-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 6800    
        , .1    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 166    
        , 'Sundar'    
        , 'Ande'    
        , 'SANDE'    
        , '011.44.1346.629268'    
        , TO_DATE('24-03-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 6400    
        , .10    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 167    
        , 'Amit'    
        , 'Banda'    
        , 'ABANDA'    
        , '011.44.1346.729268'    
        , TO_DATE('21-04-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 6200    
        , .10    
        , 147    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 168    
        , 'Lisa'    
        , 'Ozer'    
        , 'LOZER'    
        , '011.44.1343.929268'    
        , TO_DATE('11-03-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 11500    
        , .25    
        , 148    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 169      
        , 'Harrison'    
        , 'Bloom'    
        , 'HBLOOM'    
        , '011.44.1343.829268'    
        , TO_DATE('23-03-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 10000    
        , .20    
        , 148    
        , 80    
        );    
end;
/

-- insert data into the EMPLOYEES table 5
-- Broken out due to 10k limit per statement
begin  
INSERT INTO employees VALUES     
        ( 170    
        , 'Tayler'    
        , 'Fox'    
        , 'TFOX'    
        , '011.44.1343.729268'    
        , TO_DATE('24-01-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 9600    
        , .20    
        , 148    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 171    
        , 'William'    
        , 'Smith'    
        , 'WSMITH'    
        , '011.44.1343.629268'    
        , TO_DATE('23-02-2007', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7400    
        , .15    
        , 148    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 172    
        , 'Elizabeth'    
        , 'Bates'    
        , 'EBATES'    
        , '011.44.1343.529268'    
        , TO_DATE('24-03-2007', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7300    
        , .15    
        , 148    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 173    
        , 'Sundita'    
        , 'Kumar'    
        , 'SKUMAR'    
        , '011.44.1343.329268'    
        , TO_DATE('21-04-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 6100    
        , .10    
        , 148    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 174    
        , 'Ellen'    
        , 'Abel'    
        , 'EABEL'    
        , '011.44.1644.429267'    
        , TO_DATE('11-05-2004', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 11000    
        , .30    
        , 149    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 175    
        , 'Alyssa'    
        , 'Hutton'    
        , 'AHUTTON'    
        , '011.44.1644.429266'    
        , TO_DATE('19-03-2005', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 8800    
        , .25    
        , 149    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 176    
        , 'Jonathon'    
        , 'Taylor'    
        , 'JTAYLOR'    
        , '011.44.1644.429265'    
        , TO_DATE('24-03-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 8600    
        , .20    
        , 149    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 177    
        , 'Jack'    
        , 'Livingston'    
        , 'JLIVINGS'    
        , '011.44.1644.429264'    
        , TO_DATE('23-04-2006', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 8400    
        , .20    
        , 149    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 178    
        , 'Kimberely'    
        , 'Grant'    
        , 'KGRANT'    
        , '011.44.1644.429263'    
        , TO_DATE('24-05-2007', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 7000    
        , .15    
        , 149    
        , NULL    
        );    
    
INSERT INTO employees VALUES     
        ( 179    
        , 'Charles'    
        , 'Johnson'    
        , 'CJOHNSON'    
        , '011.44.1644.429262'    
        , TO_DATE('04-01-2008', 'dd-MM-yyyy')    
        , 'SA_REP'    
        , 6200    
        , .10    
        , 149    
        , 80    
        );    
    
INSERT INTO employees VALUES     
        ( 180    
        , 'Winston'    
        , 'Taylor'    
        , 'WTAYLOR'    
        , '650.507.9876'    
        , TO_DATE('24-01-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3200    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 181    
        , 'Jean'    
        , 'Fleaur'    
        , 'JFLEAUR'    
        , '650.507.9877'    
        , TO_DATE('23-02-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3100    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 182    
        , 'Martha'    
        , 'Sullivan'    
        , 'MSULLIVA'    
        , '650.507.9878'    
        , TO_DATE('21-06-2007', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2500    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 183    
        , 'Girard'    
        , 'Geoni'    
        , 'GGEONI'    
        , '650.507.9879'    
        , TO_DATE('03-02-2008', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2800    
        , NULL    
        , 120    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 184    
        , 'Nandita'    
        , 'Sarchand'    
        , 'NSARCHAN'    
        , '650.509.1876'    
        , TO_DATE('27-01-2004', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 4200    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 185    
        , 'Alexis'    
        , 'Bull'    
        , 'ABULL'    
        , '650.509.2876'    
        , TO_DATE('20-02-2005', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 4100    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 186    
        , 'Julia'    
        , 'Dellinger'    
        , 'JDELLING'    
        , '650.509.3876'    
        , TO_DATE('24-06-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3400    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 187    
        , 'Anthony'    
        , 'Cabrio'    
        , 'ACABRIO'    
        , '650.509.4876'    
        , TO_DATE('07-02-2007', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3000    
        , NULL    
        , 121    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 188    
        , 'Kelly'    
        , 'Chung'    
        , 'KCHUNG'    
        , '650.505.1876'    
        , TO_DATE('14-06-2005', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3800    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 189    
        , 'Jennifer'    
        , 'Dilly'    
        , 'JDILLY'    
        , '650.505.2876'    
        , TO_DATE('13-08-2005', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3600    
        , NULL    
        , 122    
        , 50    
        );    
end;
/

-- insert data into the EMPLOYEES table 6
-- Broken out due to 10k limit per statement
begin  
INSERT INTO employees VALUES     
        ( 190    
        , 'Timothy'    
        , 'Gates'    
        , 'TGATES'    
        , '650.505.3876'    
        , TO_DATE('11-07-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2900    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 191    
        , 'Randall'    
        , 'Perkins'    
        , 'RPERKINS'    
        , '650.505.4876'    
        , TO_DATE('19-12-2007', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2500    
        , NULL    
        , 122    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 192    
        , 'Sarah'    
        , 'Bell'    
        , 'SBELL'    
        , '650.501.1876'    
        , TO_DATE('04-02-2004', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 4000    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 193    
        , 'Britney'    
        , 'Everett'    
        , 'BEVERETT'    
        , '650.501.2876'    
        , TO_DATE('03-03-2005', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3900    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 194    
        , 'Samuel'    
        , 'McCain'    
        , 'SMCCAIN'    
        , '650.501.3876'    
        , TO_DATE('01-07-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3200    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 195    
        , 'Vance'    
        , 'Jones'    
        , 'VJONES'    
        , '650.501.4876'    
        , TO_DATE('17-03-2007', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2800    
        , NULL    
        , 123    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 196    
        , 'Alana'    
        , 'Walsh'    
        , 'AWALSH'    
        , '650.507.9811'    
        , TO_DATE('24-04-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3100    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 197    
        , 'Kevin'    
        , 'Feeney'    
        , 'KFEENEY'    
        , '650.507.9822'    
        , TO_DATE('23-05-2006', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 3000    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 198    
        , 'Donald'    
        , 'OConnell'    
        , 'DOCONNEL'    
        , '650.507.9833'    
        , TO_DATE('21-06-2007', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2600    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 199    
        , 'Douglas'    
        , 'Grant'    
        , 'DGRANT'    
        , '650.507.9844'    
        , TO_DATE('13-01-2008', 'dd-MM-yyyy')    
        , 'SH_CLERK'    
        , 2600    
        , NULL    
        , 124    
        , 50    
        );    
    
INSERT INTO employees VALUES     
        ( 200    
        , 'Jennifer'    
        , 'Whalen'    
        , 'JWHALEN'    
        , '515.123.4444'    
        , TO_DATE('17-09-2003', 'dd-MM-yyyy')    
        , 'AD_ASST'    
        , 4400    
        , NULL    
        , 101    
        , 10    
        );    
    
INSERT INTO employees VALUES     
        ( 201    
        , 'Michael'    
        , 'Hartstein'    
        , 'MHARTSTE'    
        , '515.123.5555'    
        , TO_DATE('17-02-2004', 'dd-MM-yyyy')    
        , 'MK_MAN'    
        , 13000    
        , NULL    
        , 100    
        , 20    
        );    
    
INSERT INTO employees VALUES     
        ( 202    
        , 'Pat'    
        , 'Fay'    
        , 'PFAY'    
        , '603.123.6666'    
        , TO_DATE('17-08-2005', 'dd-MM-yyyy')    
        , 'MK_REP'    
        , 6000    
        , NULL    
        , 201    
        , 20    
        );    
    
INSERT INTO employees VALUES     
        ( 203    
        , 'Susan'    
        , 'Mavris'    
        , 'SMAVRIS'    
        , '515.123.7777'    
        , TO_DATE('07-06-2002', 'dd-MM-yyyy')    
        , 'HR_REP'    
        , 6500    
        , NULL    
        , 101    
        , 40    
        );    
    
INSERT INTO employees VALUES     
        ( 204    
        , 'Hermann'    
        , 'Baer'    
        , 'HBAER'    
        , '515.123.8888'    
        , TO_DATE('07-06-2002', 'dd-MM-yyyy')    
        , 'PR_REP'    
        , 10000    
        , NULL    
        , 101    
        , 70    
        );    
    
INSERT INTO employees VALUES     
        ( 205    
        , 'Shelley'    
        , 'Higgins'    
        , 'SHIGGINS'    
        , '515.123.8080'    
        , TO_DATE('07-06-2002', 'dd-MM-yyyy')    
        , 'AC_MGR'    
        , 12008    
        , NULL    
        , 101    
        , 110    
        );    
    
INSERT INTO employees VALUES     
        ( 206    
        , 'William'    
        , 'Gietz'    
        , 'WGIETZ'    
        , '515.123.8181'    
        , TO_DATE('07-06-2002', 'dd-MM-yyyy')    
        , 'AC_ACCOUNT'    
        , 8300    
        , NULL    
        , 205    
        , 110    
        );    
END;
/

-- insert data into the JOB_HISTORY table
BEGIN  
INSERT INTO job_history  
VALUES (102  
       , TO_DATE('13-01-2001', 'dd-MM-yyyy')  
       , TO_DATE('24-07-2006', 'dd-MM-yyyy')  
       , 'IT_PROG'  
       , 60);  
  
INSERT INTO job_history  
VALUES (101  
       , TO_DATE('21-09-1997', 'dd-MM-yyyy')  
       , TO_DATE('27-10-2001', 'dd-MM-yyyy')  
       , 'AC_ACCOUNT'  
       , 110);  
  
INSERT INTO job_history  
VALUES (101  
       , TO_DATE('28-10-2001', 'dd-MM-yyyy')  
       , TO_DATE('15-03-2005', 'dd-MM-yyyy')  
       , 'AC_MGR'  
       , 110);  
  
INSERT INTO job_history  
VALUES (201  
       , TO_DATE('17-02-2004', 'dd-MM-yyyy')  
       , TO_DATE('19-12-2007', 'dd-MM-yyyy')  
       , 'MK_REP'  
       , 20);  
  
INSERT INTO job_history  
VALUES  (114  
        , TO_DATE('24-03-2006', 'dd-MM-yyyy')  
        , TO_DATE('31-12-2007', 'dd-MM-yyyy')  
        , 'ST_CLERK'  
        , 50  
        );  
  
INSERT INTO job_history  
VALUES  (122  
        , TO_DATE('01-01-2007', 'dd-MM-yyyy')  
        , TO_DATE('31-12-2007', 'dd-MM-yyyy')  
        , 'ST_CLERK'  
        , 50  
        );  
  
INSERT INTO job_history  
VALUES  (200  
        , TO_DATE('17-09-1995', 'dd-MM-yyyy')  
        , TO_DATE('17-06-2001', 'dd-MM-yyyy')  
        , 'AD_ASST'  
        , 90  
        );  
  
INSERT INTO job_history  
VALUES  (176  
        , TO_DATE('24-03-2006', 'dd-MM-yyyy')  
        , TO_DATE('31-12-2006', 'dd-MM-yyyy')  
        , 'SA_REP'  
        , 80  
        );  
  
INSERT INTO job_history  
VALUES  (176  
        , TO_DATE('01-01-2007', 'dd-MM-yyyy')  
        , TO_DATE('31-12-2007', 'dd-MM-yyyy')  
        , 'SA_MAN'  
        , 80  
        );  
  
INSERT INTO job_history  
VALUES  (200  
        , TO_DATE('01-07-2002', 'dd-MM-yyyy')  
        , TO_DATE('31-12-2006', 'dd-MM-yyyy')  
        , 'AC_ACCOUNT'  
        , 90  
        );  
END; 
/

-- enable integrity constraint to DEPARTMENTS
ALTER TABLE departments   
  ENABLE CONSTRAINT dept_mgr_fk;

-- procedure to limit edit of EMPLOYEES to normal office hours
CREATE OR REPLACE PROCEDURE secure_dml  
IS  
BEGIN  
  IF TO_CHAR (SYSDATE, 'HH24:MI') NOT BETWEEN '08:00' AND '18:00'  
        OR TO_CHAR (SYSDATE, 'DY') IN ('SAT', 'SUN') THEN  
	RAISE_APPLICATION_ERROR (-20205,   
		'You may only make changes during normal office hours');  
  END IF;  
END secure_dml; 
/

-- trigger on EMPLOYEES to invoke the SECURE_DML procedure
CREATE OR REPLACE TRIGGER secure_employees  
  BEFORE INSERT OR UPDATE OR DELETE ON employees  
BEGIN  
  secure_dml;  
END secure_employees; 
/

-- disable SECURE_EMPLOYEES trigger so data can be used at any time (given that this is a sample schema)
ALTER TRIGGER secure_employees DISABLE;

-- procedure to add a row to the JOB_HISTORY table
CREATE OR REPLACE PROCEDURE add_job_history  
  (  p_emp_id          job_history.employee_id%type  
   , p_start_date      job_history.start_date%type  
   , p_end_date        job_history.end_date%type  
   , p_job_id          job_history.job_id%type  
   , p_department_id   job_history.department_id%type   
   )  
IS  
BEGIN  
  INSERT INTO job_history (employee_id, start_date, end_date,   
                           job_id, department_id)  
    VALUES(p_emp_id, p_start_date, p_end_date, p_job_id, p_department_id);  
END add_job_history; 
/

-- row trigger to call the ADD_JOB_HISTORY procedure when data is updated in the job_id or department_id columns in the EMPLOYEES table
CREATE OR REPLACE TRIGGER update_job_history  
  AFTER UPDATE OF job_id, department_id ON employees  
  FOR EACH ROW  
BEGIN  
  add_job_history(:old.employee_id, :old.hire_date, sysdate,   
                  :old.job_id, :old.department_id);  
END; 
/

-- Beginning of comments on tables and columns
COMMENT ON TABLE regions   
IS 'Regions table that contains region numbers and names. Contains 4 rows; references with the Countries table.';

COMMENT ON COLUMN regions.region_id  
IS 'Primary key of regions table.';

COMMENT ON COLUMN regions.region_name  
IS 'Names of regions. Locations are in the countries of these regions.';

COMMENT ON TABLE locations  
IS 'Locations table that contains specific address of a specific office, warehouse, and/or production site of a company. Does not store addresses or locations of customers. Contains 23 rows; references with the departments and countries tables. ';

COMMENT ON COLUMN locations.location_id  
IS 'Primary key of locations table';

COMMENT ON COLUMN locations.street_address  
IS 'Street address of an office, warehouse, or production site of a company. Contains building number and street name';

COMMENT ON COLUMN locations.postal_code  
IS 'Postal code of the location of an office, warehouse, or production site of a company. ';

COMMENT ON COLUMN locations.city  
IS 'A not null column that shows city where an office, warehouse, or production site of a company is located. ';

COMMENT ON COLUMN locations.state_province  
IS 'State or Province where an office, warehouse, or production site of a company is located.';

COMMENT ON COLUMN locations.country_id  
IS 'Country where an office, warehouse, or production site of a company is located. Foreign key to country_id column of the countries table.';

COMMENT ON TABLE departments  
IS 'Departments table that shows details of departments where employees work. Contains 27 rows; references with locations, employees, and job_history tables.';

COMMENT ON COLUMN departments.department_id  
IS 'Primary key column of departments table.';

COMMENT ON COLUMN departments.department_name  
IS 'A not null column that shows name of a department. Administration, Marketing, Purchasing, Human Resources, Shipping, IT, Executive, Public Relations, Sales, Finance, and Accounting. ';

COMMENT ON COLUMN departments.manager_id 
IS 'Manager_id of a department. Foreign key to employee_id column of employees table. The manager_id column of the employee table references this column.';

COMMENT ON COLUMN departments.location_id  
IS 'Location id where a department is located. Foreign key to location_id column of locations table.';

COMMENT ON TABLE job_history  
IS 'Table that stores job history of the employees. If an employee  changes departments within the job or changes jobs within the department,  new rows get inserted into this table with old job information of the employee. Contains a complex primary key: employee_id+start_date. Contains 25 rows. References with jobs, employees, and departments tables.';

COMMENT ON COLUMN job_history.employee_id  
IS 'A not null column in the complex primary key employee_id+start_date. Foreign key to employee_id column of the employee table';

COMMENT ON COLUMN job_history.start_date  
IS 'A not null column in the complex primary key employee_id+start_date.  Must be less than the end_date of the job_history table. (enforced by constraint jhist_date_interval)';

COMMENT ON COLUMN job_history.end_date  
IS 'Last day of the employee in this job role. A not null column. Must be greater than the start_date of the job_history table.  (enforced by constraint jhist_date_interval)';

COMMENT ON COLUMN job_history.job_id  
IS 'Job role in which the employee worked in the past; foreign key to job_id column in the jobs table. A not null column.';

COMMENT ON COLUMN job_history.department_id 
IS 'Department id in which the employee worked in the past; foreign key to deparment_id column in the departments table';

COMMENT ON TABLE countries  
IS 'country table. Contains 25 rows. References with locations table.';

COMMENT ON COLUMN countries.country_id  
IS 'Primary key of countries table.';

COMMENT ON COLUMN countries.country_name  
IS 'Country name';

COMMENT ON COLUMN countries.region_id  
IS 'Region ID for the country. Foreign key to region_id column in the departments table.';

COMMENT ON TABLE jobs  
IS 'jobs table with job titles and salary ranges. Contains 19 rows. References with employees and job_history table.';

COMMENT ON COLUMN jobs.job_id  
IS 'Primary key of jobs table.';

COMMENT ON COLUMN jobs.job_title  
IS 'A not null column that shows job title, e.g. AD_VP, FI_ACCOUNTANT';

COMMENT ON COLUMN jobs.min_salary  
IS 'Minimum salary for a job title.';

COMMENT ON COLUMN jobs.max_salary  
IS 'Maximum salary for a job title';

