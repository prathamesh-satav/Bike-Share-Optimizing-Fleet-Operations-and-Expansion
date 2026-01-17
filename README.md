# MetroCycle Analytics: Optimizing Fleet Operations & Expansion

MetroCycle Analytics is an end-to-end business intelligence project designed to solve the **Rebalancing Problem** in urban bike-sharing systems. By analyzing rider flows, weather patterns, and station capacity, the system delivers actionable insights to fleet managers, helping prevent station shortages and identify infrastructure expansion opportunities.

---

## Table of Contents
- [Business Problem](#business-problem)
- [Solution Architecture](#solution-architecture)
- [Key Features](#key-features)
- [Tech Stack](#tech-stack)
- [Installation & Usage](#installation--usage)
- [Insights & Visuals](#insights--visuals)
- [Author](#author)

---

## Business Problem

In a busy metropolitan bike network, two critical issues erode revenue and customer trust:

1. **The Rebalancing Problem**  
   Commuter patterns cause stations in residential areas (Suburbs) to empty out by 8:00 AM, while commercial hubs (Financial District) overflow, preventing users from docking bikes. This leads to lost trips and user frustration.

2. **Infrastructure Blind Spots**  
   City planners lack granular data on *desire lines*—the most common real-world routes taken by riders—making it difficult to justify high-cost investments in protected bike lanes.

**Project Goal**  
Build a data pipeline to:
- Flag **High-Risk stations** in near real time  
- Visualize **net traffic flow** to optimize truck schedules and guide infrastructure planning

---

## Solution Architecture

The project follows a classic **ELT (Extract, Load, Transform)** pipeline designed for high-volume transactional data.

1. **Data Simulation (Python)**  
   A custom Python script generates realistic, non-uniform trip data by simulating:
   - Seasonality
   - Weather impact (e.g., reduced ridership during rain)
   - Rush-hour commuter tides vs casual usage patterns

2. **Data Warehousing (PostgreSQL)**  
   - Raw trip logs are loaded into PostgreSQL
   - SQL Views act as the transformation layer
   - Complex logic includes hourly net flow calculations and station risk scoring

3. **Visualization (Power BI)**  
   - Star Schema model for analytics
   - Advanced DAX measures
   - Natural Language Querying (Q&A) for ad-hoc insights

---

## Key Features

- **Dynamic Rebalancing Alerts**  
  SQL-based classification of stations into:
  - High Risk: Empty
  - High Risk: Full
  - Normal  
  Based on AM Rush Hour (7–9 AM) flow velocity

- **Weather Impact Analysis**  
  Measures how rain, snow, and extreme temperatures suppress *Casual* ridership, while *Subscriber* demand remains relatively inelastic

- **Route Analytics**  
  Identifies top Origin–Destination (OD) pairs to support protected bike lane planning

- **Commuter Scoring**  
  A DAX-based metric distinguishing **Work stations** from **Leisure stations** using weekday vs weekend trip ratios

---

## Tech Stack

- **Python**: pandas, numpy, random (Data generation & simulation)
- **Database**: PostgreSQL (Analytics engine & data warehouse)
- **BI Tool**: Power BI (Import/DirectQuery, DAX, Q&A/NLQ)
- **Languages**: SQL, DAX, Python

---

## Installation & Usage

### Step 1: Generate the Data

Run the Python script to generate the three core datasets:

- `stations.csv`
- `weather.csv`
- `trips.csv`

The script simulates **150,000+ trips** with realistic rush-hour distributions and weather correlations.

python generate_bike_data.py
## Step 2: Database Setup (PostgreSQL)

Follow these steps carefully to avoid common **permission denied** errors on Windows systems.

### Install PostgreSQL
Ensure **PostgreSQL** and **pgAdmin** (or any preferred SQL client) are installed and running.

---

### Prepare the File System (Important)

PostgreSQL background services often do not have permission to read files from protected directories such as **Desktop** or **Documents**.

1. Navigate to `C:\`
2. Create a new folder named `Temp`
3. Move the generated CSV files into the following path:


---

### Execute the SQL Script

1. Open **pgAdmin** and connect to your database
2. Open the **Query Tool**
3. Load the file `bike_share_analysis.sql`

**Note:**  
The SQL script assumes that all CSV files are located in `C:/Temp/`.  
If you use a different directory, update the `COPY` commands in the SQL script accordingly.

4. Run the script. This will:
   - Create the required schema and tables
   - Bulk load the CSV data
   - Build analytical SQL views for Power BI

---

## Step 3: Power BI Connection

1. Open `MetroCycle Analytics.pbix`
2. Navigate to:

3. Select the existing **PostgreSQL** connection and click **Change Source**
4. Update the following fields:
   - **Server:** `localhost`
   - **Database:** Database name created in Step 2
5. Click **Close**
6. Click **Refresh** in the Home ribbon

Power BI will reload the data, recompute all DAX measures, and populate the dashboard visuals.

---

## Insights & Visuals

The dashboard is organized into three strategic analytical views.

---

### 1. Operations Commander Map

**Target Audience:** Fleet Managers  

**Visual:**  
- Map with conditional formatting

**Indicators:**  
- Red bubbles: Stations emptying out (Need refill)  
- Orange bubbles: Stations full (Need pickup)

**Key Insight:**  
Suburban districts experience strong negative flow during morning rush hours, requiring truck intervention **before 7:00 AM** to prevent service outages.

---

### 2. Strategic Expansion

**Visual:** Scatter Plot (Commuter Score vs Utilization)

**Insight:**  
Identifies:
- Cash Cows (high utilization, commuter-heavy stations)
- Dead Zones (low utilization, weak demand)

**Visual:** Flow Analysis (Origin–Destination pairs)

**Insight:**  
The **Uptown ↔ Financial District** corridor emerges as the highest-priority candidate for new protected bike lane infrastructure.

---

### 3. Time Series Analysis

**Visual:** Line charts segmented by user type

**Insight:**  
- Subscribers display a clear **double-hump** demand pattern (8 AM and 6 PM peaks)
- Casual users exhibit smoother, afternoon-centric demand curves

