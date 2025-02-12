# Data Analyst Skills project

This repository contains a collection of SQL queries designed to answer key questions about the Data Analyst role. The queries explore job postings, required skills, demand levels, and salary data to provide insights that can help professionals decide which skills to develop.

## Project Overview

The project addresses the following questions:

1. **What are the top-paying jobs for my role?**  

2. **What are the skills required for these top-paying roles?**  

3. **What are the most in-demand skills for my role?**  

4. **What are the top skills based on salary for my role?**  

5. **What are the most optimal skills to learn?**  
   **Optimal:** High Demand & High Paying


## Data Sources

For this project, I created my own database using **PostgreSQL** and worked with the data directly in **Visual Studio Code**. The database is designed to store and analyze data related to Data Analyst job postings. It consists of the following tables:
- **job_postings_fact:**  
  Contains the core job posting data (e.g., salary, job title, location, schedule type, posting date).

- **company_dim:**  
  Provides company details such as the company name.

- **skills_job_dim:**  
  Acts as a bridge between job postings and the skills required for each role.

- **skills_dim:**  
  Provides descriptive names for each skill, making the data more human-readable.

## SQL Queries

### 1. Top-Paying Jobs for the Data Analyst Role

This query returns the top 10 job postings for the Data Analyst role based on average salary. It joins the `job_postings_fact` table with `company_dim` to enrich the results with company names.

```sql
SELECT
    Job_id,                        
    job_title,                    
    job_location,                  
    job_schedule_type,           
    salary_year_avg,               
    job_posted_date,               
    name company_name             
FROM job_postings_fact
LEFT JOIN company_dim 
    ON job_postings_fact.company_id = company_dim.company_id
WHERE
    job_title_short = 'Data Analyst'  
    AND salary_year_avg IS NOT NULL   
ORDER BY salary_year_avg DESC       
LIMIT 5;
```
| job_id  | job_title                                                 | job_location    | job_schedule_type | salary_year_avg | job_posted_date | company_name                   |
|---------|-----------------------------------------------------------|-----------------|-------------------|-----------------|-----------------|--------------------------------|
| 226942  | Data Analyst                                              | Anywhere        | Full-time         | 650000.0        | 2023-02-20      | Mantys                         |
| 209315  | Data base administrator                                   | Belarus         | Full-time         | 400000.0        | 2023-10-03      | AT&T                           |
| 1110602 | HC Data Analyst , Senior                                  | Bethesda, MD    | Full-time         | 375000.0        | 2023-08-18      | Illuminate Mission Solutions   |
| 641501  | Head of Infrastructure Management & Data Analytics - Financial... | Jacksonville, FL | Full-time         | 375000.0        | 2023-07-03      | Citigroup, Inc                 |
| 229253  | Director of Safety Data Analysis                          | Austin, TX      | Full-time         | 375000.0        | 2023-04-21      | Torc Robotics                  |

<br><br>

### 2. Skills Required for Top-Paying Data Analyst Roles

A Common Table Expression (CTE) is used to first select the top-paying Data Analyst jobs. The query then joins this result with skills_job_dim and skills_dim to list the required skills.
```sql
WITH top_paying_jobs AS (
    SELECT
        Job_id,
        job_title,
        salary_year_avg,
        name company_name
    FROM job_postings_fact
    LEFT JOIN company_dim 
        ON job_postings_fact.company_id = company_dim.company_id
    WHERE
        job_title_short = 'Data Analyst'
        AND salary_year_avg IS NOT NULL
    ORDER BY salary_year_avg DESC
)
SELECT 
    top_paying_jobs.*,   
    skills             
FROM top_paying_jobs
INNER JOIN skills_job_dim 
    ON top_paying_jobs.job_id = skills_job_dim.job_id
INNER JOIN skills_dim 
    ON skills_job_dim.skill_id = skills_dim.skill_id
ORDER BY salary_year_avg DESC
LIMIT 1000;
```


### 3. In-Demand Skills for Data Analysts

This section includes multiple queries to analyze skill demand.
#### 3.1. Top 5 Skills for Data Analyst (All Jobs)

Counts the number of job postings per skill for the Data Analyst role.



```sql
SELECT 
    sc.job_title_short,        
    sd.skills,               
    sc.skill_count            
FROM (
    SELECT 
        j.job_title_short,
        sj.skill_id,
        COUNT(*) AS skill_count
    FROM job_postings_fact AS j
    JOIN skills_job_dim AS sj
        ON j.job_id = sj.job_id
    GROUP BY j.job_title_short, sj.skill_id
) AS sc
JOIN skills_dim AS sd
    ON sc.skill_id = sd.skill_id
WHERE job_title_short = 'Data Analyst'
ORDER BY sc.job_title_short, sc.skill_count DESC
LIMIT 5;

```
| job_title_short | skills   | skill_count |
|-----------------|----------|-------------|
| Data Analyst    | sql      | 92628       |
| Data Analyst    | excel    | 67031       |
| Data Analyst    | python   | 57326       |
| Data Analyst    | tableau  | 46554       |
| Data Analyst    | power bi | 39468       |
<br><br>

#### 3.2. Top 5 Skills for Data Analyst (High-Paying Jobs)

Counts postings per skill for high-paying Data Analyst jobs (salary ≥ 50,000).



```sql
SELECT 
    sc.job_title_short,      
    sd.skills,                 
    sc.skill_count           
FROM (
    SELECT 
        j.job_title_short,
        sj.skill_id,
        COUNT(*) AS skill_count
    FROM job_postings_fact AS j
    JOIN skills_job_dim AS sj
        ON j.job_id = sj.job_id
    WHERE j.salary_year_avg >= 50000
    GROUP BY j.job_title_short, sj.skill_id
) AS sc
JOIN skills_dim AS sd
    ON sc.skill_id = sd.skill_id
WHERE job_title_short = 'Data Analyst'
ORDER BY sc.job_title_short, sc.skill_count DESC
LIMIT 5;

```
| job_title_short | skills   | skill_count |
|-----------------|----------|-------------|
| Data Analyst    | sql      | 3013        |
| Data Analyst    | excel    | 2046        |
| Data Analyst    | python   | 1818        |
| Data Analyst    | tableau  | 1627        |
| Data Analyst    | r        | 1059        |
<br><br>

#### 3.3. Top 5 Skills for Data Analyst Remote Jobs (High-Paying)

Focuses on remote Data Analyst jobs with high salaries.


```sql
SELECT 
    sc.job_title_short,       
    sd.skills AS skill_name,  
    sc.skill_count            
FROM (
    SELECT 
        j.job_title_short,
        sj.skill_id,
        j.job_work_from_home,    
        COUNT(*) AS skill_count
    FROM job_postings_fact AS j
    JOIN skills_job_dim AS sj
        ON j.job_id = sj.job_id
    WHERE j.salary_year_avg >= 50000
      AND j.job_title_short = 'Data Analyst'
    GROUP BY j.job_title_short, sj.skill_id, j.job_work_from_home
) AS sc
JOIN skills_dim AS sd
    ON sc.skill_id = sd.skill_id
WHERE sc.job_work_from_home = TRUE   
ORDER BY sc.skill_count DESC
LIMIT 5;

```
| job_title_short | skill_name | skill_count |
|-----------------|------------|-------------|
| Data Analyst    | sql        | 392         |
| Data Analyst    | excel      | 249         |
| Data Analyst    | python     | 234         |
| Data Analyst    | tableau    | 229         |
| Data Analyst    | r          | 146         |

<br><br>

### 4. Top Skills Based on Salary for Data Analysts

This set of queries examines salary metrics (average, minimum, maximum, standard deviation) per skill.
#### 4.1. Top Skills by Average Salary

```sql
SELECT
    sd.skills,                                 
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary  
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id  
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id    
WHERE job_title_short = 'Data Analyst'  
  AND salary_year_avg IS NOT NULL     
GROUP BY sd.skills                   
ORDER BY avg_salary DESC               
LIMIT 5;

```
| skills    | avg_salary |
|-----------|------------|
| svn       | 400000     |
| solidity  | 179000     |
| couchbase | 160515     |
| datarobot | 155486     |
| golang    | 155000     |
<br><br>

#### 4.2. Detailed Salary Spread for Each Skill

```sql
SELECT
    sd.skills,                                     
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary,  
    MIN(jpf.salary_year_avg) AS min_salary,             
    MAX(jpf.salary_year_avg) AS max_salary,             
    ROUND(STDDEV(jpf.salary_year_avg), 0) AS salary_std_dev  
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.salary_year_avg IS NOT NULL
GROUP BY sd.skills
ORDER BY avg_salary DESC
LIMIT 5;

```
| skills    | avg_salary | min_salary | max_salary | salary_std_dev |
|-----------|------------|------------|------------|----------------|
| svn       | 400000     | 400000.0   | 400000.0   |                |
| solidity  | 179000     | 179000.0   | 179000.0   |                |
| couchbase | 160515     | 160515.0   | 160515.0   |                |
| datarobot | 155486     | 155485.5   | 155485.5   |                |
| golang    | 155000     | 145000.0   | 165000.0   | 14142          |

<br><br>

#### 4.3. Salary Spread with Job Count Filter

This version adds a filter to exclude skills with fewer than 5 job postings.

```sql
SELECT
    sd.skills,                                  
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary, 
    MIN(jpf.salary_year_avg) AS min_salary,           
    MAX(jpf.salary_year_avg) AS max_salary,        
    ROUND(STDDEV(jpf.salary_year_avg), 0) AS salary_std_dev, 
    COUNT(DISTINCT jpf.job_id) AS job_count          
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.salary_year_avg IS NOT NULL
GROUP BY sd.skills
HAVING COUNT(DISTINCT jpf.job_id) > 5   
ORDER BY avg_salary DESC
LIMIT 5;

```
| skills     | avg_salary | min_salary | max_salary | salary_std_dev | job_count |
|------------|------------|------------|------------|----------------|-----------|
| gitlab     | 134126     | 57500.0   | 205000.0  | 59503          | 7         |
| kafka      | 129999     | 51014.0   | 400000.0  | 56233          | 40        |
| pytorch    | 125226     | 70000.0   | 220000.0  | 41687          | 20        |
| perl       | 124686     | 56700.0   | 186500.0  | 37721          | 20        |
| tensorflow | 120647     | 77500.0   | 198000.0  | 36847          | 24        |
<br><br>

### 5. Optimal Skills to Learn (High Demand & High Paying)

Identifies optimal skills by combining demand (job posting count) and salary data. The query focuses on remote Data Analyst roles with specified salaries.
```sql
SELECT
    sd.skills,                                    
    COUNT(sjd.job_id) AS demand_count,            
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary  
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id  
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id      
WHERE jpf.job_title_short = 'Data Analyst' 
  AND jpf.job_work_from_home = TRUE      
  AND jpf.salary_year_avg IS NOT NULL      
GROUP BY sd.skills                          
ORDER BY demand_count DESC               
LIMIT 5;

```
| skills  | demand_count | avg_salary |
|---------|--------------|------------|
| sql     | 398          | 97237      |
| excel   | 256          | 87288      |
| python  | 236          | 101397     |
| tableau | 230          | 99288      |
| r       | 148          | 100499     |
<br><br>

Additionally, ordering by salary can yield alternative insights:

```sql
SELECT
    sd.skills,                                     
    COUNT(sjd.job_id) AS demand_count,             
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary 
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id  
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id       
WHERE jpf.job_title_short = 'Data Analyst'   
  AND jpf.job_work_from_home = TRUE         
  AND jpf.salary_year_avg IS NOT NULL        
GROUP BY sd.skills  
HAVING COUNT(DISTINCT jpf.job_id) > 10 
ORDER BY avg_salary DESC, demand_count DESC
LIMIT 10;

```
| skills     | demand_count | avg_salary |
|------------|--------------|------------|
| go         | 27           | 115320     |
| confluence | 11           | 114210     |
| hadoop     | 22           | 113193     |
| snowflake  | 37           | 112948     |
| azure      | 34           | 111225     |
| bigquery   | 13           | 109654     |
| aws        | 32           | 108317     |
| java       | 17           | 106906     |
| ssis       | 12           | 106683     |
| jira       | 20           | 104918     |


### Project Takeaway - Learning SQL is great!

- **Premium for Niche Skills:**  
  Some specialized or niche skills (e.g., gitlab, kafka, pytorch, tensorflow) tend to have higher average salaries despite having fewer job postings. This suggests that expertise in these areas may command a premium.

- **High-Demand, Broadly Adopted Skills:**  
  Skills like spark, snowflake, and hadoop appear in many job postings (with job counts in the high hundreds or over a hundred) but tend to have slightly lower average salaries compared to niche skills. This reflects broader market adoption and higher competition, which may temper the salary premium.


- **Salary Variability:**  
  The wide ranges between the minimum and maximum salaries—as well as relatively large standard deviations—indicate considerable variation. This could be due to factors such as differences in company size, geographic location, or experience level. For example, while gitlab has an average of around 134K, its salaries range from about 57K to 205K.

- **Market Balance:**  
 The data overall shows a balance between demand and compensation: highly specialized skills can lead to higher earnings but appear in fewer positions, while more common skills offer broader opportunities with slightly lower average pay.

In summary, if you're targeting a Data Analyst role, developing niche technical skills might yield higher pay, but you may also consider the volume of opportunities in the market when deciding which skills to focus on.

### Takeaway for me
I have learned a great deal about SQL and the entire process—from creating my own PostgreSQL database, collecting and organizing data, to designing tables and working with them to draw out interesting information. This project primarily showcases data querying, but I have also been working with data definition (DDL) and data manipulation (DML) languages to better understand the production of tables. 