-- ============================================================
-- VACCINATION DATA ANALYSIS AND VISUALIZATION
-- MYSQL COMPLETE SQL SCRIPT
-- ============================================================

-- ============================================================
-- 1. SELECT DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS vaccination_db;

USE vaccination_db;


-- ============================================================
-- 2. CREATE COVERAGE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS coverage (
    record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `GROUP` VARCHAR(255),
    CODE VARCHAR(20),
    NAME VARCHAR(255),
    YEAR INT,
    ANTIGEN VARCHAR(100),
    ANTIGEN_DESCRIPTION TEXT,
    COVERAGE_CATEGORY VARCHAR(150),
    COVERAGE_CATEGORY_DESCRIPTION TEXT,
    TARGET_NUMBER DOUBLE,
    DOSES DOUBLE,
    COVERAGE DOUBLE
);


-- ============================================================
-- 3. CREATE INCIDENCE RATE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS incidence_rate (
    record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `GROUP` VARCHAR(255),
    CODE VARCHAR(20),
    NAME VARCHAR(255),
    YEAR INT,
    DISEASE VARCHAR(100),
    DISEASE_DESCRIPTION TEXT,
    DENOMINATOR DOUBLE,
    INCIDENCE_RATE DOUBLE
);


-- ============================================================
-- 4. CREATE REPORTED CASES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS reported_cases (
    record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    `GROUP` VARCHAR(255),
    CODE VARCHAR(20),
    NAME VARCHAR(255),
    YEAR INT,
    DISEASE VARCHAR(100),
    DISEASE_DESCRIPTION TEXT,
    CASES DOUBLE
);


-- ============================================================
-- 5. CREATE VACCINE INTRODUCTION TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS vaccine_introduction (
    record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ISO_3_CODE VARCHAR(10),
    COUNTRYNAME VARCHAR(255),
    WHO_REGION VARCHAR(100),
    YEAR INT,
    DESCRIPTION VARCHAR(255),
    INTRO VARCHAR(255)
);


-- ============================================================
-- 6. CREATE VACCINE SCHEDULE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS vaccine_schedule (
    record_id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ISO_3_CODE VARCHAR(10),
    COUNTRYNAME VARCHAR(255),
    WHO_REGION VARCHAR(100),
    YEAR INT,
    VACCINECODE VARCHAR(50),
    VACCINEDESCRIPTION TEXT,
    SCHEDULEROUNDS DOUBLE,
    TARGETPOP VARCHAR(100),
    TARGETPOP_DESCRIPTION TEXT,
    GEOAREA VARCHAR(255),
    AGEADMINISTERED VARCHAR(255),
    SOURCECOMMENT TEXT
);


-- ============================================================
-- 7. CHECK ALL TABLES
-- ============================================================

SHOW TABLES;

USE vaccination_db;

SELECT
    'coverage' AS table_name,
    COUNT(*) AS record_count
FROM coverage

UNION ALL

SELECT
    'incidence_rate',
    COUNT(*)
FROM incidence_rate

UNION ALL

SELECT
    'reported_cases',
    COUNT(*)
FROM reported_cases

UNION ALL

SELECT
    'vaccine_introduction',
    COUNT(*)
FROM vaccine_introduction

UNION ALL

SELECT
    'vaccine_schedule',
    COUNT(*)
FROM vaccine_schedule;


SELECT
    'vaccine_schedule',
    COUNT(*)
FROM vaccine_schedule;

-- ============================================================
-- 8. NORMALIZATION
-- ============================================================

-- COUNTRY MASTER TABLE
CREATE TABLE IF NOT EXISTS dim_country (
    country_id INT AUTO_INCREMENT PRIMARY KEY,
    country_code VARCHAR(20) NOT NULL UNIQUE,
    country_name VARCHAR(255) NOT NULL,
    who_region VARCHAR(100)
);


-- YEAR MASTER TABLE
CREATE TABLE IF NOT EXISTS dim_year (
    year_id INT AUTO_INCREMENT PRIMARY KEY,
    year_value INT NOT NULL UNIQUE
);


-- DISEASE MASTER TABLE
CREATE TABLE IF NOT EXISTS dim_disease (
    disease_id INT AUTO_INCREMENT PRIMARY KEY,
    disease_code VARCHAR(100) NOT NULL,
    disease_description VARCHAR(500),
    UNIQUE (disease_code, disease_description)
);


-- ANTIGEN MASTER TABLE
CREATE TABLE IF NOT EXISTS dim_antigen (
    antigen_id INT AUTO_INCREMENT PRIMARY KEY,
    antigen_code VARCHAR(100) NOT NULL,
    antigen_description VARCHAR(500),
    UNIQUE (antigen_code, antigen_description)
);


-- VACCINE MASTER TABLE
CREATE TABLE IF NOT EXISTS dim_vaccine (
    vaccine_id INT AUTO_INCREMENT PRIMARY KEY,
    vaccine_code VARCHAR(50) NOT NULL UNIQUE,
    vaccine_description VARCHAR(500)
);


-- ============================================================
-- 9. INSERT MASTER DATA
-- ============================================================

-- COUNTRIES
INSERT IGNORE INTO dim_country
(country_code, country_name, who_region)

SELECT DISTINCT
    CODE,
    NAME,
    NULL
FROM coverage
WHERE CODE IS NOT NULL
  AND NAME IS NOT NULL

UNION

SELECT DISTINCT
    ISO_3_CODE,
    COUNTRYNAME,
    WHO_REGION
FROM vaccine_introduction
WHERE ISO_3_CODE IS NOT NULL
  AND COUNTRYNAME IS NOT NULL;


-- YEARS
INSERT IGNORE INTO dim_year (year_value)

SELECT DISTINCT YEAR
FROM (
    SELECT YEAR FROM coverage
    UNION
    SELECT YEAR FROM incidence_rate
    UNION
    SELECT YEAR FROM reported_cases
    UNION
    SELECT YEAR FROM vaccine_introduction
    UNION
    SELECT YEAR FROM vaccine_schedule
) AS years
WHERE YEAR IS NOT NULL;


-- DISEASES
INSERT IGNORE INTO dim_disease
(disease_code, disease_description)

SELECT DISTINCT
    DISEASE,
    DISEASE_DESCRIPTION
FROM incidence_rate
WHERE DISEASE IS NOT NULL;


-- ANTIGENS
INSERT IGNORE INTO dim_antigen
(antigen_code, antigen_description)

SELECT DISTINCT
    ANTIGEN,
    ANTIGEN_DESCRIPTION
FROM coverage
WHERE ANTIGEN IS NOT NULL;


-- VACCINES
INSERT IGNORE INTO dim_vaccine
(vaccine_code, vaccine_description)

SELECT DISTINCT
    VACCINECODE,
    VACCINEDESCRIPTION
FROM vaccine_schedule
WHERE VACCINECODE IS NOT NULL;


-- ============================================================
-- 10. NORMALIZED COVERAGE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_coverage (
    coverage_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    country_id INT NOT NULL,
    year_id INT NOT NULL,
    antigen_id INT NOT NULL,

    coverage_category VARCHAR(150),
    coverage_category_description TEXT,

    target_number DOUBLE,
    doses DOUBLE,
    coverage DOUBLE,

    CONSTRAINT fk_coverage_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_coverage_year
        FOREIGN KEY (year_id)
        REFERENCES dim_year(year_id),

    CONSTRAINT fk_coverage_antigen
        FOREIGN KEY (antigen_id)
        REFERENCES dim_antigen(antigen_id)
);


-- ============================================================
-- 11. NORMALIZED INCIDENCE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_incidence_rate (
    incidence_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    country_id INT NOT NULL,
    year_id INT NOT NULL,
    disease_id INT NOT NULL,

    denominator DOUBLE,
    incidence_rate DOUBLE,

    CONSTRAINT fk_incidence_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_incidence_year
        FOREIGN KEY (year_id)
        REFERENCES dim_year(year_id),

    CONSTRAINT fk_incidence_disease
        FOREIGN KEY (disease_id)
        REFERENCES dim_disease(disease_id)
);


-- ============================================================
-- 12. NORMALIZED REPORTED CASES TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_reported_cases (
    cases_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    country_id INT NOT NULL,
    year_id INT NOT NULL,
    disease_id INT NOT NULL,

    cases DOUBLE,

    CONSTRAINT fk_cases_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_cases_year
        FOREIGN KEY (year_id)
        REFERENCES dim_year(year_id),

    CONSTRAINT fk_cases_disease
        FOREIGN KEY (disease_id)
        REFERENCES dim_disease(disease_id)
);


-- ============================================================
-- 13. NORMALIZED VACCINE SCHEDULE TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS fact_vaccine_schedule (
    schedule_id BIGINT AUTO_INCREMENT PRIMARY KEY,

    country_id INT NOT NULL,
    year_id INT NOT NULL,
    vaccine_id INT NOT NULL,

    schedule_rounds DOUBLE,
    target_population VARCHAR(100),
    target_population_description TEXT,
    geographic_area VARCHAR(255),
    age_administered VARCHAR(255),
    source_comment TEXT,

    CONSTRAINT fk_schedule_country
        FOREIGN KEY (country_id)
        REFERENCES dim_country(country_id),

    CONSTRAINT fk_schedule_year
        FOREIGN KEY (year_id)
        REFERENCES dim_year(year_id),

    CONSTRAINT fk_schedule_vaccine
        FOREIGN KEY (vaccine_id)
        REFERENCES dim_vaccine(vaccine_id)
);


-- ============================================================
-- 14. INSERT DATA INTO NORMALIZED TABLES
-- ============================================================

-- COVERAGE
INSERT INTO fact_coverage
(
    country_id,
    year_id,
    antigen_id,
    coverage_category,
    coverage_category_description,
    target_number,
    doses,
    coverage
)
SELECT
    c.country_id,
    y.year_id,
    a.antigen_id,
    s.COVERAGE_CATEGORY,
    s.COVERAGE_CATEGORY_DESCRIPTION,
    s.TARGET_NUMBER,
    s.DOSES,
    s.COVERAGE
FROM coverage s
JOIN dim_country c
    ON c.country_code = s.CODE
JOIN dim_year y
    ON y.year_value = s.YEAR
JOIN dim_antigen a
    ON a.antigen_code = s.ANTIGEN;


-- INCIDENCE
INSERT INTO fact_incidence_rate
(
    country_id,
    year_id,
    disease_id,
    denominator,
    incidence_rate
)
SELECT
    c.country_id,
    y.year_id,
    d.disease_id,
    s.DENOMINATOR,
    s.INCIDENCE_RATE
FROM incidence_rate s
JOIN dim_country c
    ON c.country_code = s.CODE
JOIN dim_year y
    ON y.year_value = s.YEAR
JOIN dim_disease d
    ON d.disease_code = s.DISEASE;


-- REPORTED CASES
INSERT INTO fact_reported_cases
(
    country_id,
    year_id,
    disease_id,
    cases
)
SELECT
    c.country_id,
    y.year_id,
    d.disease_id,
    s.CASES
FROM reported_cases s
JOIN dim_country c
    ON c.country_code = s.CODE
JOIN dim_year y
    ON y.year_value = s.YEAR
JOIN dim_disease d
    ON d.disease_code = s.DISEASE;


-- VACCINE SCHEDULE
INSERT INTO fact_vaccine_schedule
(
    country_id,
    year_id,
    vaccine_id,
    schedule_rounds,
    target_population,
    target_population_description,
    geographic_area,
    age_administered,
    source_comment
)
SELECT
    c.country_id,
    y.year_id,
    v.vaccine_id,
    s.SCHEDULEROUNDS,
    s.TARGETPOP,
    s.TARGETPOP_DESCRIPTION,
    s.GEOAREA,
    s.AGEADMINISTERED,
    s.SOURCECOMMENT
FROM vaccine_schedule s
JOIN dim_country c
    ON c.country_code = s.ISO_3_CODE
JOIN dim_year y
    ON y.year_value = s.YEAR
JOIN dim_vaccine v
    ON v.vaccine_code = s.VACCINECODE;


-- ============================================================
-- 15. DATA INTEGRITY / RELATIONSHIP CHECK
-- ============================================================

SELECT
    TABLE_NAME,
    COLUMN_NAME,
    CONSTRAINT_NAME,
    REFERENCED_TABLE_NAME,
    REFERENCED_COLUMN_NAME
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE
WHERE TABLE_SCHEMA = 'vaccination_db'
  AND REFERENCED_TABLE_NAME IS NOT NULL
ORDER BY TABLE_NAME, COLUMN_NAME;


-- ============================================================
-- 16. FINAL NORMALIZED TABLE CHECK
-- ============================================================

SHOW TABLES;

