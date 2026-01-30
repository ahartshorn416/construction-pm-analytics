CREATE DATABASE construction_pm;

CREATE TABLE tasks_stage (
    ref TEXT,
    status TEXT,
    location TEXT,
    description TEXT,
    created TEXT,
    target TEXT,
    type TEXT,
    to_package TEXT,
    status_changed TEXT,
    association TEXT,
    overdue TEXT,
    images TEXT,
    comments TEXT,
    documents TEXT,
    priority TEXT,
    cause TEXT,
    project TEXT,
    report_status TEXT,
    task_group TEXT
);

CREATE TABLE forms_stage (
    ref TEXT,
    status TEXT,
    location TEXT,
    name TEXT,
    created TEXT,
    type TEXT,
    status_changed TEXT,
    open_actions TEXT,
    total_actions TEXT,
    association TEXT,
    overdue TEXT,
    images TEXT,
    comments TEXT,
    documents TEXT,
    project TEXT,
    report_forms_status TEXT,
    report_forms_group TEXT
);

CREATE TABLE forms_clean AS
SELECT
    ref AS form_id,
    status,
    location,
    name AS form_name,
    TO_DATE(NULLIF(created, ''), 'DD/MM/YYYY') AS created_date,
    type AS form_type,
    TO_DATE(NULLIF(status_changed, ''), 'DD/MM/YYYY') AS status_changed_date,
    open_actions::INT,
    total_actions::INT,
    overdue::BOOLEAN,
    images::BOOLEAN,
    comments::BOOLEAN,
    documents::BOOLEAN,
    project,
    report_forms_status,
    report_forms_group
FROM forms_stage;

CREATE TABLE tasks_clean AS
SELECT
    ref AS task_id,
    status,
    location,
    description,

    CASE
        WHEN created ~ '^[0-9]+$'
        THEN DATE '1899-12-30' + created::INT
        ELSE TO_DATE(NULLIF(created,''), 'DD/MM/YYYY')
    END AS created_date,

    CASE
        WHEN target ~ '^[0-9]+$'
        THEN DATE '1899-12-30' + target::INT
        ELSE TO_DATE(NULLIF(target,''), 'DD/MM/YYYY')
    END AS target_date,

    type AS task_type,
    to_package,

    CASE
        WHEN status_changed ~ '^[0-9]+$'
        THEN DATE '1899-12-30' + status_changed::INT
        ELSE TO_DATE(NULLIF(status_changed,''), 'DD/MM/YYYY')
    END AS status_changed_date,

    association,
    overdue::BOOLEAN,
    images::BOOLEAN,
    comments::BOOLEAN,
    documents::BOOLEAN,
    priority,
    cause,
    project,
    report_status,
    task_group
FROM tasks_stage;

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

SELECT
    t.project,
    COUNT(DISTINCT t.task_id) AS total_tasks,
    SUM(t.is_overdue_flag) AS overdue_tasks,
    COUNT(DISTINCT f.form_id) AS total_forms,
    SUM(CASE WHEN f.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_forms
FROM tasks_clean t
LEFT JOIN forms_clean f
  ON t.project = f.project
GROUP BY t.project;

CREATE TABLE project_kpis AS
SELECT
    t.project,

    COUNT(DISTINCT t.task_id) AS total_tasks,
    SUM(CASE WHEN t.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,

    ROUND(
      100.0 * SUM(CASE WHEN t.overdue = TRUE THEN 1 ELSE 0 END)
      / COUNT(DISTINCT t.task_id), 2
    ) AS overdue_task_pct,

    COUNT(DISTINCT f.form_id) AS total_forms,
    SUM(CASE WHEN f.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_forms,

    ROUND(
      100.0 * SUM(CASE WHEN f.overdue = TRUE THEN 1 ELSE 0 END)
      / NULLIF(COUNT(DISTINCT f.form_id),0), 2
    ) AS overdue_form_pct

FROM tasks_clean t
LEFT JOIN forms_clean f
  ON t.project = f.project
GROUP BY t.project;

SELECT
    task_group,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
    ROUND(
      100.0 * SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS overdue_pct
FROM tasks_clean
GROUP BY task_group
ORDER BY overdue_pct DESC;

SELECT
    priority,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks
FROM tasks_clean
GROUP BY priority
ORDER BY overdue_tasks DESC;

CREATE TABLE project_risk AS
SELECT
    project,

    (SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) * 1.0
     + SUM(CASE WHEN priority = 'High' THEN 0.5 ELSE 0 END)
     + COUNT(DISTINCT task_group) * 0.2
    ) AS risk_score

FROM tasks_clean
GROUP BY project
ORDER BY risk_score DESC;

SELECT
    DATE_TRUNC('month', created_date) AS month,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks
FROM tasks_clean
GROUP BY month
ORDER BY month;

SELECT
    cause,
    COUNT(*) AS total_tasks,
    SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
    ROUND(
      100.0 * SUM(CASE WHEN overdue = TRUE THEN 1 ELSE 0 END) / COUNT(*), 2
    ) AS overdue_pct
FROM tasks_clean
WHERE cause IS NOT NULL AND cause <> ''
GROUP BY cause
ORDER BY overdue_pct DESC;

SELECT
    task_id,
    created_date,
    status_changed_date,
    target_date,
    (target_date - status_changed_date) AS days_remaining_at_change
FROM tasks_clean
WHERE overdue = TRUE
  AND status_changed_date IS NOT NULL;

 SELECT
    t.project,
    SUM(CASE WHEN t.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_tasks,
    SUM(CASE WHEN f.overdue = TRUE THEN 1 ELSE 0 END) AS overdue_forms
FROM tasks_clean t
LEFT JOIN forms_clean f
  ON t.project = f.project
GROUP BY t.project
ORDER BY overdue_forms DESC;



