-- Rostou v prùbìhu let mzdy ve všech odvìtvích, nebo v nìkterých klesají?

WITH avg_salaries_diff AS
	(SELECT 
		year_ ,
		quarter_  ,
		industry_branch_name ,
		value_CZK ,
		value_CZK - lag(value_CZK) OVER (PARTITION BY industry_branch_name ORDER BY year_, quarter_) AS QonQ_diff ,
		FIRST_VALUE(value_CZK) OVER (PARTITION BY industry_branch_name ORDER BY year_, quarter_) AS vychozi,
		FIRST_VALUE(value_CZK) OVER (PARTITION BY industry_branch_name ORDER BY year_ DESC, quarter_ DESC) AS posledni
	 FROM t_nikola_novotna_projekt_SQL_primary_final
	 WHERE value_type = 'avg salary by industry'
	 ORDER BY industry_branch_name,
		year_ ,
		quarter_ )
SELECT 
	industry_branch_name ,
	CAST (avg(QonQ_diff) AS DECIMAL (7,2)) AS prum_mezikvart_rozdil_CZK,
	CAST ((posledni/vychozi - 1) * 100 AS DECIMAL (7,2)) AS procentualni_prirustek
	FROM avg_salaries_diff 
GROUP BY industry_branch_name ; -- prum. mezikvartalni prirustek a celkovy prirustek v % za sledovane obdobi 

WITH avg_salaries_diff AS
	(SELECT 
		year_ ,
		quarter_  ,
		industry_branch_name ,
		value_CZK ,
		value_CZK - lag(value_CZK) OVER (PARTITION BY industry_branch_name ORDER BY year_, quarter_) AS QonQ_diff ,
		CAST (value_CZK / lag(value_CZK) OVER (PARTITION BY industry_branch_name ORDER BY year_, quarter_) AS DECIMAL (7,3)) AS QonQ_percentage_diff
	FROM t_nikola_novotna_projekt_SQL_primary_final
	WHERE value_type = 'avg salary by industry'
	ORDER BY industry_branch_name,
		year_ ,
		quarter_)	
SELECT 
	industry_branch_name ,
	year_ ,
	quarter_ ,
	QonQ_diff ,
	QonQ_percentage_diff
FROM avg_salaries_diff
WHERE QonQ_diff < 1;

-- Kolik je možné si koupit litrù mléka a kilogramù chleba za první a poslední 
-- srovnatelné období v dostupných datech cen a mezd?

SELECT *
FROM t_nikola_novotna_projekt_SQL_primary_final
WHERE produkt LIKE 'Mléko%' AND 
	  year_ = 2006 AND quarter_ = 1;
	 
WITH cena_mleka AS	 
	(SELECT 
		year_ ,
		produkt ,
		CAST (avg(value_CZK) AS DECIMAL (7,2)) AS prumerna_cena_mleka
		FROM t_nikola_novotna_projekt_SQL_primary_final
		WHERE produkt LIKE 'Mléko%'
		GROUP BY produkt, year_ ),
cena_chleba AS 
	(SELECT 
		year_ ,
		produkt ,
		CAST (avg(value_CZK) AS DECIMAL (7,2)) AS prumerna_cena_chleba
		FROM t_nikola_novotna_projekt_SQL_primary_final
		WHERE produkt LIKE 'Chléb%'
		GROUP BY produkt, year_ ),
prumerna_mzda AS 
	(SELECT 
		year_ ,
		CAST (avg(value_CZK) AS DECIMAL (7,2)) AS prumerna_mzda
		FROM t_nikola_novotna_projekt_SQL_primary_final
		WHERE value_type = 'avg salary by industry'
		GROUP BY year_)
SELECT
	cc.year_ ,
	cc.prumerna_cena_chleba,
	cm.prumerna_cena_mleka,
	CAST (pm.prumerna_mzda * 12 / cc.prumerna_cena_chleba AS DECIMAL (7,2)) AS dostupne_mnozstvi_chleba_za_rok,
	CAST (pm.prumerna_mzda * 12 / cm.prumerna_cena_mleka AS DECIMAL (7,2)) AS dostupne_mnozstvi_mleka_za_rok	
FROM cena_mleka cm
JOIN cena_chleba cc 
	ON cm.year_ = cc.year_
JOIN prumerna_mzda pm
	ON pm.year_ = cc.year_
WHERE cc.year_ IN ('2006','2018');

-- Která kategorie potravin zdražuje nejpomaleji (je u ní nejnižší percentuální meziroèní nárùst)?

CREATE OR REPLACE VIEW ceny_potravin AS
	SELECT 
		year_ ,
		produkt ,
		avg(value_CZK) AS avg_price_per_Y
	FROM t_nikola_novotna_projekt_SQL_primary_final
	WHERE value_type LIKE '%price%'
	GROUP BY produkt, year_ ;


SELECT
	year_,
	produkt,
	min(change_in_percentage) 
FROM (
	SELECT 
		year_ ,
		produkt ,
		avg_price_per_Y ,
		CAST ((avg_price_per_Y / (lag(avg_price_per_Y) OVER (PARTITION BY produkt ORDER BY year_))-1)*100 AS DECIMAL (7,3) ) AS change_in_percentage
	FROM ceny_potravin 
	ORDER BY
		produkt,
		year_
		) base
		; -- nejvýznamnìjší pokles ceny byl zaznamenán u produktu Banány Žluté v roce 2006
		
SELECT
	produkt,
	avg(change_in_percentage) zmena_ceny_za_sledovane_obdobi
FROM (
	SELECT 
		year_ ,
		produkt ,
		avg_price_per_Y ,
		CAST ((avg_price_per_Y / (lag(avg_price_per_Y) OVER (PARTITION BY produkt ORDER BY year_))-1)*100 AS DECIMAL (7,3) ) AS change_in_percentage
	FROM ceny_potravin 
	ORDER BY
		produkt,
		year_
		) base
GROUP BY produkt
ORDER BY zmena_ceny_za_sledovane_obdobi; -- produkty cukr krystalový, rajská jablka èervená kulatá za sledované odbodí zlevnila, nejpomaleji zdražovaly banány
		
-- Existuje rok, ve kterém byl meziroèní nárùst cen potravin výraznì vyšší než rùst mezd (vìtší než 10 %)?

 CREATE OR REPLACE VIEW mezirocni_rust_cen AS
	SELECT 
		year_ ,
		produkt ,
		avg_price_per_Y ,
		CAST ((avg_price_per_Y / (lag(avg_price_per_Y) OVER (PARTITION BY produkt  ORDER BY produkt, year_))-1)*100 AS DECIMAL (7,3) ) AS change_in_percentage -- meziroèní nárùst ceny
	FROM ceny_potravin 
	ORDER BY
		produkt,
		year_;
	
SELECT 
	year_,
	avg(change_in_percentage) AS prumerny_prirustek_cen
FROM mezirocni_rust_cen
	-- WHERE change_in_percentage IS NOT NULL 
	GROUP BY year_;
	

CREATE OR REPLACE VIEW rocni_prumer_mezd AS
	SELECT 
		year_ ,
		CAST (avg(value_CZK) AS DECIMAL (7,2)) AS avg_salary
	FROM t_nikola_novotna_projekt_SQL_primary_final
	WHERE value_type LIKE '%salary%'
	GROUP BY year_ ;



WITH prumerny_prirustek_cen AS
	(SELECT 
		year_,
		CAST (avg(change_in_percentage) AS DECIMAL (7,2)) AS mezirocni_rust_cen
		FROM mezirocni_rust_cen
		-- WHERE change_in_percentage IS NOT NULL 
		GROUP BY year_),
	mezirocni_rust_mezd AS 
	(SELECT 
		year_ ,
		CAST((avg_salary/lag(avg_salary) OVER (ORDER BY year_) - 1 )* 100 AS DECIMAL (7,2)) AS mezirocni_rust_mezd
		FROM rocni_prumer_mezd 
		ORDER BY year_)
SELECT 
	ppc.year_,
	ppc.mezirocni_rust_cen,
	mrm.mezirocni_rust_mezd
FROM prumerny_prirustek_cen ppc
JOIN mezirocni_rust_mezd mrm
	ON mrm.year_ = ppc.year_
WHERE ppc.mezirocni_rust_cen > mrm.mezirocni_rust_mezd; -- meziroèní rùst cen potravin byl vyšší v letech viz OUTPUT, výraznì vyšší byl v roce 2013.

-- Má výška HDP vliv na zmìny ve mzdách a cenách potravin? Neboli, pokud HDP vzroste výraznìji v jednom roce, 
-- projeví se to na cenách potravin èi mzdách ve stejném nebo násdujícím roce výraznìjším rùstem?

CREATE OR REPLACE VIEW HDP_CZE AS
	SELECT 
	`year` ,
	country, 
	GDP 
	FROM t_nikola_novotna_project_sql_secondary_final
	WHERE country = 'Czech republic';



-- k  následujícím joinout ještì pøírùstky HDP

WITH prumerny_prirustek_cen AS
	(SELECT 
		year_,
		CAST (avg(change_in_percentage) AS DECIMAL (7,2)) AS mezirocni_rust_cen
		FROM mezirocni_rust_cen
		-- WHERE change_in_percentage IS NOT NULL 
		GROUP BY year_),
	mezirocni_rust_mezd AS 
	(SELECT 
		year_ ,
		CAST((avg_salary/lag(avg_salary) OVER (ORDER BY year_) - 1 )* 100 AS DECIMAL (7,2)) AS mezirocni_rust_mezd
		FROM rocni_prumer_mezd 
		ORDER BY year_),
	rust_HDP_CZE AS 
	(SELECT 
		`year`,
		CAST((GDP/lag(GDP) OVER (ORDER BY `year`) - 1 )* 100 AS DECIMAL (7,2)) AS mezirocni_rust_HDP
	 FROM hdp_cze )
SELECT 
	ppc.year_,
	ppc.mezirocni_rust_cen,
	mrm.mezirocni_rust_mezd,
	hdp.mezirocni_rust_HDP
FROM prumerny_prirustek_cen ppc
JOIN mezirocni_rust_mezd mrm
	ON mrm.year_ = ppc.year_
JOIN rust_hdp_cze hdp
	ON hdp.`year` = mrm.year_
	; 
	-- v letech kdy klesalo HDP, docházelo k pomalejšímu rùstu, v nìkterých pøípadech i k poklesu mezd.
    -- výraznìjí rùst HDP v jednom roce >5 % podpoøil rùst mezd v roce následujícím 