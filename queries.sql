--
-- Queries to produce a flat-file JSON version of entire database for use in multidimensional indexer
-- 
-- N.B. these queries require PostgreSQL 9.4, which is currently in beta
--

DROP VIEW sales;
CREATE VIEW sales AS
  SELECT ticket_sales.id AS id,
         date AS date,
         weekday AS weekday,
         registers.id AS register_id,
         total_sold AS sold,
         seating_categories.name AS raw_section,
         (price_per_ticket_l::REAL + price_per_ticket_s / 20.0) AS price,
         CASE WHEN seating_categories.id IN (18,39,60,80,88,94,101,108,116,126,137,143) THEN 'parterre'
            WHEN seating_categories.id IN (7,8,9,10,15,20,27,28,37,42,43,44,57,63,64,65,78,83,85,89,91,95,98,102,109,113,117,123,127,134,139) THEN 'première Loge'
            ELSE 'autre'
         END AS section
  FROM ticket_sales JOIN registers ON (register_id = registers.id)
                    JOIN register_periods ON (registers.register_period_id = register_periods.id)
                    JOIN register_period_seating_categories USING (register_period_id, seating_category_id)
                    JOIN seating_categories ON (seating_category_id = seating_categories.id)
  WHERE total_sold > 0
    AND date > '1740-04-01' AND date <= '1793-03-26'
  ORDER BY date, ordering;

COPY (SELECT json_agg(sales) FROM sales) TO PROGRAM $$ruby -p -e 'gsub(/\\n/, "\n")' > /Users/yorkc/Desktop/MIT/cfrp-dimensional/sales.json$$;

DROP VIEW playbill;
CREATE VIEW playbill AS
	SELECT register_plays.id AS id,
	       date AS date,
         registers.id AS register_id,
	       ordering AS order,
	       author AS author,
	       title AS title,
	       genre AS genre,
	       acts AS acts
	FROM register_plays JOIN registers ON (register_id = registers.id)
	                    JOIN plays ON (play_id = plays.id)
  WHERE date > '1740-04-01' AND date <= '1793-03-26'
	ORDER BY date, ordering;

COPY (SELECT json_agg(playbill) FROM playbill) TO PROGRAM $$ruby -p -e 'gsub(/\\n/, "\n")' > /Users/yorkc/Desktop/MIT/cfrp-dimensional/playbill.json$$;
