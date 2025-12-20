use universities;


-- 1) Create a GDP table
CREATE TABLE COUNTRY_GDP(COUNTRY_NAME VARCHAR(30),YEAR_2020 BIGINT);
SELECT * FROM COUNTRY_GDP;

-- 2) Standardize inconsistent country naming in GDP
UPDATE country_gdp
SET country_name = 'United States of America'
WHERE country_name = 'United States';

UPDATE country_gdp
SET country_name = 'Hong Kong'
WHERE country_name LIKE 'Hong Kong%';

UPDATE country_gdp
SET country_name = 'South Korea'
WHERE country_name LIKE 'Korea%';


SET SQL_SAFE_UPDATES = 0;
DELETE FROM COUNTRY_GDP
WHERE YEAR_2020=2020;
SET SQL_SAFE_UPDATES = 1;


-- 4) Create Analytical Table: GDP vs University Count by Country (CTAS)
-- Supports scatter plot: University_Count vs GDP
CREATE TABLE COUNTRY_GDP_VS_COUNTOF_UNI1 AS
	SELECT 
		c.country_name,
		COUNT(u.id) as total_universities,
		g.YEAR_2020
	FROM Country c
	JOIN country_gdp g
	ON c.country_name=g.country_name
	JOIN university u
	ON c.id=u.country_id
	GROUP BY c.country_name,g.year_2020
	ORDER BY g.year_2020 DESC;
    
    
-- 5) Validation: Total universities in dataset
SELECT COUNT(DISTINCT id) AS total_universities_in_dataset
FROM university;

-- 6) Validation: Total universities represented in rankings
SELECT COUNT(DISTINCT university_id) AS total_universities_in_rankings
FROM university_ranking_year;

-- 7) Universities in a Selected Ranking System
SELECT COUNT(DISTINCT university_id) AS universities_in_system
FROM university_ranking_year ury
LEFT JOIN ranking_criteria rc
ON ury.ranking_criteria_id=rc.id
WHERE ranking_system_id = 1;

-- 8) Detect mismatched GDP countries not present in master Country
SELECT g.country_name
FROM country_gdp g
LEFT JOIN country c ON g.country_name = c.country_name
WHERE c.country_name IS NULL;

-- 9) Check universities missing a country assignment
SELECT *
FROM university
WHERE country_id IS NULL;

-- 10) Year-wise distribution of ranked universities
SELECT year, COUNT(DISTINCT university_id) AS ranked_universities
FROM university_ranking_year
GROUP BY year
ORDER BY year;

-- 11) Ranked Universities by Ranking System Name (Global coverage)
SELECT 
    rs.system_name, 
    COUNT(DISTINCT ury.university_id) AS universities_ranked
FROM university_ranking_year ury
JOIN ranking_criteria rc 
    ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs 
    ON rc.ranking_system_id = rs.id
GROUP BY rs.system_name;

-- 12) Year-wise ranked universities for only Shanghai Ranking
SELECT 
    ury.year,
    COUNT(DISTINCT ury.university_id)
FROM university_ranking_year ury
JOIN ranking_criteria rc 
    ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs 
    ON rc.ranking_system_id = rs.id
WHERE rs.system_name = 'Shanghai Ranking'
GROUP BY ury.year
ORDER BY ury.year;


-- 13) Identify Shanghai universities that do not map to master table
SELECT ury.university_id
FROM university_ranking_year ury
LEFT JOIN university u ON ury.university_id = u.id
JOIN ranking_criteria rc ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs ON rc.ranking_system_id = rs.id
WHERE rs.system_name = 'Shanghai Ranking'
  AND u.id IS NULL;

-- 14) Shanghai Total: Raw count in SQL (Validation of measure logic)
SELECT COUNT(DISTINCT university_id)
FROM university_ranking_year ury
JOIN ranking_criteria rc ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs ON rc.ranking_system_id = rs.id
WHERE rs.system_name = 'Shanghai Ranking';

-- 15) Shanghai Mapped Count: After enforcing link to master University table
SELECT COUNT(DISTINCT ury.university_id)
FROM university_ranking_year ury
JOIN ranking_criteria rc ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs ON rc.ranking_system_id = rs.id
JOIN university u ON ury.university_id = u.id
WHERE rs.system_name = 'Shanghai Ranking';


-- 16) Score Range Validation by System (Min/Max Score Distribution)
SELECT 
    rs.system_name,
    MIN(ury.score) AS min_score,
    MAX(ury.score) AS max_score
FROM university_ranking_year ury
JOIN ranking_criteria rc ON ury.ranking_criteria_id = rc.id
JOIN ranking_system rs ON rc.ranking_system_id = rs.id
GROUP BY rs.system_name;

-- 17) Ranked Universities by Country (for heatmaps & bar charts)
SELECT 
    c.country_name,
    COUNT(DISTINCT ury.university_id) AS ranked_universities
FROM university_ranking_year ury
JOIN university u ON ury.university_id = u.id
JOIN country c ON u.country_id = c.id
GROUP BY c.country_name
ORDER BY ranked_universities DESC;


-- 18) Score Distribution Bucketed into 10-Point Ranges
SELECT
    ROUND(score, -1) AS score_bucket,
    COUNT(*) AS count_universities
FROM university_ranking_year
GROUP BY ROUND(score, -1)
ORDER BY score_bucket;

-- 19) Criteria Count per Ranking System (metadata validation)
SELECT
    rs.system_name,
    COUNT(DISTINCT rc.criteria_name) AS criteria_count
FROM ranking_criteria rc
JOIN ranking_system rs ON rc.ranking_system_id = rs.id
GROUP BY rs.system_name;

-- 20) Score completeness check for data quality
SELECT *
FROM university_ranking_year
WHERE score IS NULL;

