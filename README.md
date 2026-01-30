# 🏗️ Construction Project Management Dashboard
---

## 🌟 Overview
This project analyzes **tasks and forms** from construction project management to uncover **overdue work, bottlenecks, and project risks**.  

The **Tableau dashboard is fully interactive** and includes:  
- ✅ Key Performance Indicators (KPIs)  
- ✅ Project Risk Rating  
- ✅ Delay Trends Over Time  
- ✅ Root Cause Analysis  
- ✅ Overdue Tasks by Task Group  

Managers can **filter, drill down, and explore data dynamically** to make data-driven decisions.

---

## 🚀 Project Goals
- Identify **task groups contributing most to delays**  
- Monitor **project-level KPIs** for tasks and forms  
- Calculate **project risk scores** combining overdue tasks, priority, and team complexity  
- Provide a **dynamic, interactive dashboard** for root cause and trend analysis  

---

## 📁 Data
- **Source:** `tasks_clean.csv`, `forms_clean.csv`  
- **Key Columns:**  
  - `task_id` / `form_id` – Unique identifiers  
  - `task_group` / `report_forms_group` – Responsible team  
  - `overdue` – 0 (on-time) / 1 (overdue) flag  
  - `created_date`, `target_date`, `status_changed_date` – Task timelines  
  - `priority`, `cause` – Task attributes  

---

## 🛠 Tools & Technologies
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Data-blue?logo=postgresql&style=for-the-badge)]  
[![Tableau](https://img.shields.io/badge/Tableau-Visualization-blue?logo=tableau&style=for-the-badge)]  
[![Excel](https://img.shields.io/badge/Excel-Data-orange?logo=microsoft-excel&style=for-the-badge)]  

---

## 🧹 Data Cleaning & Transformation
- Convert Excel-style or string dates to SQL `DATE`  
- Convert `overdue`, `images`, `comments`, `documents` to Boolean  
- Add helper columns:  
  - `is_overdue_flag` → numeric for counts  
  - `days_overdue` → days past target  

```sql
ALTER TABLE tasks_clean
ADD COLUMN is_overdue_flag INT,
ADD COLUMN days_overdue INT;

UPDATE tasks_clean
SET
    is_overdue_flag = CASE WHEN overdue = TRUE THEN 1 ELSE 0 END,
    days_overdue = CASE
        WHEN overdue = TRUE AND target_date IS NOT NULL
        THEN CURRENT_DATE - target_date
        ELSE 0
    END;

## 📊 Key Analysis
Project-Level Summary
- Total vs overdue tasks/forms per project
SELECT
    t.project,
    COUNT(DISTINCT t.task_id) AS total_tasks,
    SUM(CASE WHEN t.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
    COUNT(DISTINCT f.form_id) AS total_forms,
    SUM(CASE WHEN f.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_forms
FROM tasks_clean t
LEFT JOIN forms_clean f
  ON t.project = f.project
GROUP BY t.project;

Task Group Analysis
- Identify teams causing delays

SELECT
    task_group,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
    ROUND(100.0 * SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS overdue_pct
FROM tasks_clean
GROUP BY task_group
ORDER BY overdue_pct DESC;

Priority & Root Cause Analysis

SELECT priority, COUNT(*) AS total_tasks,
       SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks
FROM tasks_clean
GROUP BY priority
ORDER BY overdue_tasks DESC;

SELECT cause, COUNT(*) AS total_tasks,
       SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
       ROUND(100.0 * SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2) AS overdue_pct
FROM tasks_clean
WHERE cause IS NOT NULL AND cause <> ''
GROUP BY cause
ORDER BY overdue_pct DESC;

Project Risk Score
- Combines overdue tasks, high priority, and team complexity

CREATE TABLE project_risk AS
SELECT
    project,
    COALESCE(SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END),0) * 1.0
  + COALESCE(SUM(CASE WHEN priority='High' THEN 0.5 ELSE 0 END),0)
  + COALESCE(COUNT(DISTINCT task_group)*0.2,0) AS risk_score
FROM tasks_clean
GROUP BY project
ORDER BY risk_score DESC;

Time-Based Trends
- Monthly analysis of overdue tasks

SELECT DATE_TRUNC('month', created_date) AS month,
       COUNT(*) AS total_tasks,
       SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks
FROM tasks_clean
GROUP BY month
ORDER BY month;

##📈 Interactive Dashboard Features

- KPI Cards: Total tasks/forms, overdue %, project risk rating
- Delay Trends Over Time
- Root Cause Analysis by cause and priority
- Overdue Tasks by Task Group bar chart
- Dynamic filters: project, task group, priority, date ranges

🌐 Tableau Public Embed
[<iframe src="YOUR_TABLEAU_PUBLIC_EMBED_LINK" width="1000" height="800"></iframe>](https://public.tableau.com/app/profile/alison.hartshorn/viz/ConstructionProjectExecutiveOverview/ConstructionProjectExecutiveOverview#1)
