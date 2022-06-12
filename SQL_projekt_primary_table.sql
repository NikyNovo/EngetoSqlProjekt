-- puvodni:
-- 
--  CREATE OR REPLACE VIEW avg_salaries_by_industry AS 
-- 	SELECT 
-- 		cp.payroll_year AS year_,
-- 		cp.payroll_quarter AS quarter_,
-- 		'avg salary by industry' AS value_type ,
-- 		cp.value AS value_CZK,
-- 		cpib.name AS industry_branch_name ,
-- 		'n/a' AS produkt
-- 	FROM czechia_payroll cp 
-- 	JOIN czechia_payroll_calculation cpc 
-- 			ON cp.calculation_code = cpc.code 
-- 	JOIN czechia_payroll_industry_branch cpib 
-- 			ON cp.industry_branch_code = cpib.code 
-- 	JOIN czechia_payroll_unit cpu 
-- 			ON cp.unit_code = cpu.code 
-- 	JOIN czechia_payroll_value_type cpvt 
-- 			ON cp.value_type_code = cpvt.code 
-- 	WHERE 1=1
-- 	AND cp.value_type_code = 5958 -- prum. hruba mzda
-- 	AND cp.calculation_code = 100 -- pouze fizicky
-- 	-- AND cp.industry_branch_code NOT NULL
-- 	ORDER BY cp.payroll_year , cp.payroll_quarter 
-- 	;
-- 
-- CREATE OR REPLACE VIEW food_price_evolution_CZE AS 
-- 	SELECT 
-- 		YEAR (date_from) AS year_,
-- 		quarter(date_from) AS quarter_,
-- 		'AVG price per Q' AS value_type,
-- 		AVG(cp.value) AS value_CZK ,
-- 		'n/a' AS industry_branch_name ,
-- 		cpc.name AS produkt
-- 	FROM czechia_price cp
-- 	LEFT JOIN czechia_price_category cpc 
-- 		ON cp.category_code = cpc.code 
-- 	LEFT JOIN czechia_region cr 
-- 		ON cp.region_code = cr.code 
-- 	GROUP BY year_ , quarter_, produkt
-- 	ORDER BY year_, quarter_, produkt
-- 		;
-- 	
-- CREATE TABLE t_nikola_novotna_projekt_SQL_primary_final AS
-- 	SELECT 
-- 		asbi.*,
-- 		fpec.produkt ,
-- 		CAST (fpec.avg_price_per_quarter AS DECIMAL (7,2) )
-- 	FROM avg_salaries_by_industry asbi
-- 	JOIN food_price_evolution_cze fpec
-- 		ON asbi.year_ = fpec.year_ 
-- 		AND asbi.quarter_ = fpec.quarter_ ;
-- 	

-- 2. varianta primary table

DROP TABLE t_nikola_novotna_projekt_SQL_primary_final;
	
CREATE TABLE t_nikola_novotna_projekt_SQL_primary_final AS
	SELECT 
		cp.payroll_year AS year_,
		cp.payroll_quarter AS quarter_,
		'avg salary by industry' AS value_type ,
		cp.value AS value_CZK,
		cpib.name AS industry_branch_name ,
		'n/a' AS produkt
	FROM czechia_payroll cp 
	JOIN czechia_payroll_calculation cpc 
			ON cp.calculation_code = cpc.code 
	JOIN czechia_payroll_industry_branch cpib 
			ON cp.industry_branch_code = cpib.code 
	JOIN czechia_payroll_unit cpu 
			ON cp.unit_code = cpu.code 
	JOIN czechia_payroll_value_type cpvt 
			ON cp.value_type_code = cpvt.code 
	WHERE 1=1
	AND cp.value_type_code = 5958 -- prum. hruba mzda
	AND cp.calculation_code = 100 -- pouze fizicky
UNION 
	SELECT 
		YEAR (date_from) AS year_,
		quarter(date_from) AS quarter_,
		'avg price per Q' AS value_type,
		AVG(cp.value) AS value_CZK ,
		'n/a' AS industry_branch_name ,
		cpc.name AS produkt
	FROM czechia_price cp
	LEFT JOIN czechia_price_category cpc 
		ON cp.category_code = cpc.code 
	LEFT JOIN czechia_region cr 
		ON cp.region_code = cr.code 
	GROUP BY year_ , quarter_, produkt
		;	
	
	
