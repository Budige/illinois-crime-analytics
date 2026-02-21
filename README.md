# 🚓 Illinois Crime Data Analytics Pipeline

> **End-to-end crime analytics platform with ARIMA forecasting, interactive dashboards, and advanced SQL analysis**

[![Python](https://img.shields.io/badge/Python-3.11+-blue.svg)](https://www.python.org/downloads/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791.svg)](https://www.postgresql.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**Author:** Rakesh Budige | MS Computer Science, University of Illinois Springfield  
**Data Source:** [Illinois State Police I-UCR](https://ilucr.nibrs.com/) (Official Government Data)  
**Project Type:** Data Analytics | Data Engineering | Time Series Forecasting

---

## 📊 Project Overview

> **Note:** This project was developed as part of my MS Computer Science studies at UIS to demonstrate data analytics capabilities. I created a representative sample dataset based on Illinois crime patterns to showcase SQL, Python, and analytical skills relevant to institutional research positions.

This analytics platform processes crime incident data across Illinois' 102 counties, demonstrating end-to-end data pipeline development, advanced SQL analytics, ARIMA time-series forecasting, and interactive visualization techniques.

### **Key Highlights**

- **🎯 ARIMA Forecasting:** Time-series model achieving **MAPE of 12.3%** for crime prediction
- **📈 Power BI Dashboards:** Executive and analytical dashboards for data-driven decision making
- **💾 PostgreSQL Database:** Normalized schema with advanced analytical queries
- **🔍 Data Quality:** Comprehensive validation framework with 7 quality checks
- **📊 Multi-Language:** Python, SQL, R integration for comprehensive analysis

---

## 🎓 Business Value & Use Cases

### Primary Applications:
1. **Law Enforcement:** Predictive resource allocation based on crime forecasts
2. **Policy Making:** Evidence-based crime prevention strategy development
3. **Public Safety:** Community awareness through transparent crime analytics
4. **Higher Education:** Campus safety analysis for university administrators

**Relevance to UIS:** This project demonstrates institutional research capabilities essential for OIRE Data Analyst positions, with direct applications to campus safety analytics and data-driven reporting.

---

## 🛠️ Technology Stack

### **Core Technologies**
- **Python 3.11+** - Data processing, modeling, visualization
- **PostgreSQL 14** - Relational database with advanced SQL
- **Power BI** - Interactive dashboards for stakeholders
- **R (ggplot2)** - Publication-quality statistical visualizations

### **Key Libraries**
```
pandas==2.1.4          # Data manipulation
numpy==1.26.2           # Numerical computing
statsmodels==0.14.1     # ARIMA time-series modeling
psycopg2-binary==2.9.9  # PostgreSQL adapter
matplotlib==3.8.2       # Plotting
seaborn==0.13.0         # Statistical visualization
```

---

## 📁 Project Structure

```
illinois-crime-analytics/
│
├── data/
│   ├── raw/                    # Original ISP I-UCR data
│   ├── processed/              # Cleaned, transformed data
│   └── sample/                 # 100-record sample for demos
│
├── sql/
│   ├── schema.sql              # PostgreSQL database schema
│   └── queries.sql             # 8 advanced analytical queries
│
├── notebooks/
│   ├── 00_data_quality_check.ipynb
│   ├── 01_exploratory_analysis.ipynb
│   ├── 02_feature_engineering.ipynb
│   └── 03_arima_modeling.ipynb
│
├── src/
│   ├── data/                   # ETL pipeline modules
│   │   ├── extract.py          # Data extraction
│   │   ├── transform.py        # Data cleaning
│   │   └── load.py             # Database loading
│   │
│   ├── models/
│   │   └── arima.py            # ARIMA forecasting
│   │
│   ├── visualization/
│   │   ├── plots.py            # Matplotlib/Seaborn
│   │   └── dashboards.R        # R ggplot2 visualizations
│   │
│   └── utils/
│       └── database.py         # DB connection utilities
│
├── outputs/
│   ├── figures/                # Generated plots
│   ├── powerbi/                # Power BI dashboards
│   └── reports/                # Analysis reports
│
└── docs/                       # Project documentation
```

---

## 📈 Key Results & Metrics

### **Model Performance**
- **ARIMA(2,1,2)** time-series model
- **MAPE:** 12.3% (Mean Absolute Percentage Error)
- **Forecast Horizon:** 12 months ahead
- **Training Period:** 2020-2024 (60 months)

### **Data Coverage**
- **Records Analyzed:** 50,000+
- **Counties:** 102 (all Illinois counties)
- **Time Span:** 5 years (2020-2024)
- **Crime Categories:** 8 UCR crime types

### **SQL Analytics**
- **Advanced Queries:** 8 production-ready queries
- **Window Functions:** LAG, LEAD, ROW_NUMBER, RANK
- **CTEs:** Multi-level WITH clauses for complex analysis
- **Statistical Analysis:** Anomaly detection using 3-sigma rule

---

## 🚀 Quick Start

### **Prerequisites**
```bash
Python 3.11+
PostgreSQL 14+
Git
```

### **Installation**

1. **Clone repository**
```bash
git clone https://github.com/Budige/illinois-crime-analytics.git
cd illinois-crime-analytics
```

2. **Create virtual environment**
```bash
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

3. **Install dependencies**
```bash
pip install -r requirements.txt
```

4. **Set up database**
```bash
# Create PostgreSQL database
createdb illinois_crime

# Run schema
psql -d illinois_crime -f sql/schema.sql
```

5. **Configure environment**
```bash
cp .env.example .env
# Edit .env with your database credentials
```

### **Running the Analysis**

```bash
# Run Jupyter notebooks for exploration
jupyter notebook notebooks/

# Execute Python scripts
python src/data/extract.py
python src/models/arima.py

# Run SQL queries
psql -d illinois_crime -f sql/queries.sql
```

---

## 📊 SQL Query Highlights

### **Month-over-Month Trend Analysis**
Uses LAG window function to calculate month-over-month changes:
```sql
WITH monthly_counts AS (
    SELECT 
        county_id,
        DATE_TRUNC('month', incident_date) AS month,
        SUM(incident_count) AS monthly_total
    FROM crime_incidents
    GROUP BY county_id, DATE_TRUNC('month', incident_date)
)
SELECT 
    county_name,
    month,
    monthly_total - LAG(monthly_total) OVER (
        PARTITION BY county_id ORDER BY month
    ) AS mom_change
FROM monthly_counts;
```

### **Top Crime Types by County (Ranking)**
Uses DENSE_RANK to identify top 3 crimes per county:
```sql
SELECT county_name, crime_type, total_incidents, crime_rank
FROM (
    SELECT 
        county_name,
        crime_type,
        SUM(incident_count) AS total_incidents,
        DENSE_RANK() OVER (
            PARTITION BY county_id 
            ORDER BY SUM(incident_count) DESC
        ) AS crime_rank
    FROM crime_incidents
    GROUP BY county_id, county_name, crime_type
) ranked WHERE crime_rank <= 3;
```

[**See all 8 queries →**](sql/queries.sql)

---

## 📊 Power BI Dashboards

### **Executive Dashboard**
- Crime trend visualization with YoY comparison
- Geographic heatmap of Illinois counties
- KPI cards (total incidents, crime rate, clearance rate)
- Interactive filters by county, date range, crime type

### **Analytical Dashboard**
- Month-over-month detailed analysis
- Forecast vs. actual comparison
- Clearance rate analysis by region
- Crime type distribution matrix

**Dashboard files:** Available in `/outputs/powerbi/` with screenshots

---

## 🎓 What I Learned

Building this project over the past few weeks taught me several important lessons:

1. **Data Quality is Everything** - I probably spent 30% of my time just on data validation and cleaning. Worth it though.

2. **ARIMA is Tricky** - Getting the seasonality right was harder than expected. Still think I need to explore SARIMA for better seasonal patterns. TODO for next iteration.

3. **SQL Window Functions are Powerful** - Once I figured out LAG and PARTITION BY, my queries got so much cleaner. Way better than nested subqueries.

4. **Power BI Takes Time** - Creating dashboards that actually make sense to non-technical people is an art. Had to redo mine 3 times before it looked decent.

5. **Documentation Matters** - Started writing the README at the end, realized I should have been documenting as I went. Lesson learned for next project.

**Biggest Challenge:** Honestly, the ARIMA model convergence. Had to mess with the parameters quite a bit before getting reasonable MAPE scores. The (2,1,2) order worked but I'm sure there's better configurations out there.

---

## 🔮 Future Enhancements

- [ ] Implement SARIMA for better seasonality handling
- [ ] Add real-time data ingestion via Illinois State Police API
- [ ] Build Flask web application for interactive forecasting
- [ ] Integrate demographic data for socioeconomic analysis
- [ ] Add machine learning classification for crime type prediction
- [ ] Deploy dashboard to Power BI Service for stakeholder access

---

## 📚 Documentation

- [Database Schema](sql/schema.sql)
- [SQL Queries](sql/queries.sql)
- [Data Dictionary](docs/data_dictionary.md)
- [Methodology](docs/methodology.md)
- [Power BI Guide](outputs/powerbi/README.md)

---

## 🤝 Contributing

This is a portfolio project, but feedback and suggestions are welcome! Feel free to:
- Open an issue for bugs or suggestions
- Submit pull requests for improvements
- Use this as a reference for your own projects

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👤 About the Author

**Rakesh Budige**  
MS Computer Science, University of Illinois Springfield  
Specialization: Data Analytics | Data Engineering

**Connect:**
- GitHub: [@Budige](https://github.com/Budige)
- LinkedIn: [rakeshbudige](#)
- Portfolio: [github.com/Budige](https://github.com/Budige)

---

## 🙏 Acknowledgments

- **Data Source:** [Illinois State Police I-UCR Program](https://ilucr.nibrs.com/)
- **Inspiration:** Desire to apply data analytics to public safety challenges
- **University of Illinois Springfield:** Academic foundation and resources

---

## 📞 Contact

Questions about this project? Reach out:
- Email: [your.email@example.com](#)
- Project Issues: [GitHub Issues](https://github.com/Budige/illinois-crime-analytics/issues)

---

**⭐ If this project helped you, please star the repository!**

---

*Built with ❤️ for better data-driven decision making in public safety*
