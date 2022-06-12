
CREATE TABLE t_nikola_novotna_project_SQL_secondary_final AS
	SELECT 
		`year` ,
		c.country,
		e.GDP,
		e.population,
		e.gini,
		e.taxes,
		c.abbreviation ,
		c.capital_city ,
		c.continent ,
		c.currency_name ,
		c.currency_code 
	FROM economies e
	JOIN countries c 
		ON e.country = c.country 
	WHERE c.continent LIKE 'Europe'
	ORDER BY c.country, `year` 
;       

