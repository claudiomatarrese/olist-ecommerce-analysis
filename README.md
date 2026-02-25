# Olist - E-Commerce Analysis (SQL + Power BI)

Data Analysis Project based on the public **Olist Brazilian E-Commerce** dataset, available on Kaggle: 
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
**Olist** database has around **100,000 real orders** done from various marketplaces in Brazil during the period **2016-2018**. From the given data, it is possible to study the orders in several ways: order status and delivery speed, prices paid, method of payment, cost of shipping, geolocation of the clients, etc.
The objective of the project is to build a good structured pipeline with **PostgreSQL** and an interactive dashboard with **Power BI** that is clear and easily understandable in real business scenarios.


## Objectives
- Model data exclusively using **SQL**: data cleaning, aggregation, and validation
- Define clear KPIs that are reusable over time
- Create distinct separation between **data logic (SQL)** and **presentation (Power BI)** to reduce errors and ambiguity
- Build a dashboard that can be used for business decision-making and monitor & measure performance


## Technologies
- **PostgreSQL 17**
- **Power BI**
- Windows 11


## Project Structure
```
Olist_Project/
├── data_kaggle/   # Original Olist CSV files (used to load the database, not included in the repository)
├── sql/           # Complete SQL pipeline (schema, diagnostics, thematic analyses, KPIs, quality checks)
├── powerbi/	   # Power BI project folder (report file available via external link)
├── docs/
│   ├── Olist_Ecommerce_Analysis.pdf    # PDF export of the report
│   ├── powerbi_model.png               # Power BI data model screenshot (Model View)
│   ├── dashboard_executive.png         # Executive Overview page screenshot
│   └── dashboard_orders_logistics.png  # Orders & Logistics page screenshot
├── README.md      # Main documentation
```


## SQL Architecture
Structured and ordered pipeline:
- **Schema and raw diagnostics** → `00_schema.sql`, `00_raw_diagnostics.sql`
- **Thematic analyses (Phases 01-06)** → customers, orders & logistics, products, reviews, payments and sellers
- **KPI Master dashboard layer** → `07_kpi_master.sql`
- **Data quality checks** → `08_quality_checks.sql`

All KPIs are **calculated and defined in SQL**.


## Data Model (Power BI)
![Power BI Data Model](docs/powerbi_model.png)

- **Central fact table**: orders and logistics
- **Satellite tables**: customers, payments, and reviews
- **KPI views**: pre-aggregated in SQL and **intentionally disconnected** from the relational model

Design choice adopted to avoid:
- filter ambiguity
- duplicated logic
- KPI recalculation in DAX


## Power BI Dashboard
The report includes:
- Executive KPIs
- Orders and logistics performance
- Customer analysis and retention
- Product and category analysis
- Review quality
- Payment structure and methods

### Executive Overview
![Executive Overview](docs/dashboard_executive.png)

### Orders & Logistics
![Orders & Logistics](docs/dashboard_orders_logistics.png)

The Power BI report (.pbix) can be downloaded here: [Download Power BI report (.pbix)](https://drive.google.com/file/d/1BYSKC-0Dt-nKny-qMIh16yJJxt9JFxhw/view?usp=sharing)

A static PDF version of the dashboard is available in the `docs/` folder.


## Reproducibility
1. Create a new PostgreSQL 17 database  
2. Import the Olist dataset CSV files into the `data_kaggle/` directory 
3. Run the SQL scripts in numerical order (00 → 08)  
4. Connect Power BI to the PostgreSQL database  
5. Download the .pbix report from the link above and open it in Power BI Desktop.  


## Notes
- The dataset is not included in the repository
- Project designed for **professional portfolio**
