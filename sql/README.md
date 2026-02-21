# SQL Queries Documentation

## Query Files

- `schema.sql` - Database schema (3 normalized tables)
- `queries.sql` - 8 analytical queries for crime analysis

## Query Performance Notes

The month-over-month query (Query 2) can be slow with the full dataset. Using the composite index on (county_id, incident_date, crime_type) helps a lot.

I tested this on my local PostgreSQL instance:
- Without index: ~850ms
- With composite index: ~120ms

Definitely worth the index overhead for queries we run frequently.

## Query Complexity

Started with simple SELECT statements, then added:
1. Basic JOINs (Query 1)
2. Window functions - LAG was game-changer (Query 2)
3. CTEs for readability (Query 4)
4. Statistical analysis with Z-scores (Query 7)

The ranking query (Query 3) using DENSE_RANK() is probably my favorite. Clean way to get top N per group without messy subqueries.

## TODO

- [ ] Add query for year-over-year crime type shifts
- [ ] Create materialized view for frequently accessed aggregations
- [ ] Optimize the anomaly detection query (currently does full table scan)
