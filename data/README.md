# Data Sources & Documentation

## Primary Data Source

**Illinois State Police - Uniform Crime Reporting (I-UCR)**
- **URL:** https://ilucr.nibrs.com/
- **Type:** Official government data (public, free)
- **Format:** NIBRS (National Incident-Based Reporting System)
- **Coverage:** 2016-2024, all 102 Illinois counties
- **Update Frequency:** Annual
- **Data Quality:** Government-certified, law enforcement submitted

## Dataset Structure

### Raw Data (`data/raw/`)
- Original files from Illinois State Police I-UCR
- Immutable - never modified directly
- Documented provenance for verification

### Processed Data (`data/processed/`)
- `crime_cleaned.csv` - Cleaned and standardized crime incidents
- `county_population.csv` - Illinois county population reference
- `crime_monthly_agg.csv` - Monthly aggregated statistics

### Sample Data (`data/sample/`)
- `crime_sample_100.csv` - 100-record sample for demos and testing

## Data Fields

| Field | Type | Description | Source |
|-------|------|-------------|--------|
| incident_date | Date | Date of crime incident | ISP I-UCR |
| county_name | String | Illinois county name | ISP I-UCR |
| crime_type | String | UCR crime category | ISP I-UCR |
| incident_count | Integer | Number of incidents | ISP I-UCR |
| cleared_count | Integer | Number of cases solved | ISP I-UCR |
| population | Integer | County population | US Census Bureau |
| crime_rate_per_100k | Float | Calculated rate | Derived |

## Data Quality Notes

### Known Issues
- Some counties have missing data for certain months (documented in quality checks)
- Population estimates updated annually (may not reflect mid-year changes)
- Crime type categorization changed in 2021 (NIBRS transition)

### Quality Checks Performed
1. Schema validation
2. Completeness check (missing values)
3. Range validation (no negative counts)
4. Temporal validation (no future dates)
5. County validation (exactly 102 Illinois counties)
6. Duplicate detection
7. Statistical outlier analysis

## Data Usage

### Citation
When using this data, please cite:
```
Illinois State Police. (2024). Illinois Uniform Crime Reporting (I-UCR) Program. 
Retrieved from https://ilucr.nibrs.com/
```

### License
Illinois State Police I-UCR data is public domain.
This project's derivative works are under MIT License.

## Contact

Questions about data sources or quality?
- Check: [docs/data_quality.md](../docs/data_quality.md)
- Email: [your.email@example.com]
