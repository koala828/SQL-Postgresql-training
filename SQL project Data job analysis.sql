/*
Questions to answer
1. What are the top-paying jobs for my role?
2. What are the Skills required for these top-paying roles?
3. What are the most in-demand skills for my role?
4. What are the top skills based on salary for my role?
5. What are the most optimal skills to learn?
    5.a Optimal: High Demand & High Paying
*/

/* ============================================================
   1. What are the top-paying jobs for my role?
   
   This query returns the top 10 job postings for the 'Data Analyst' role
   ordered by the average annual salary. The main tables are:
   
   - job_postings_fact: Contains the core job posting data (e.g., salary,
     job title, location, schedule type, posting date).
   - company_dim: Provides company details such as the company name.
   
   We join the company information via company_id, filter for 'Data Analyst'
   jobs with a non-null salary, and order by salary_year_avg descending.
   ============================================================ */
SELECT
    Job_id,                        -- Unique identifier for the job
    job_title,                     -- Full job title text
    job_location,                  -- Job location
    job_schedule_type,             -- Type of schedule (full-time, part-time, etc.)
    salary_year_avg,               -- Average annual salary for the posting
    job_posted_date,               -- Date when the job was posted
    name company_name              -- Company name from company_dim
FROM job_postings_fact
LEFT JOIN company_dim 
    ON job_postings_fact.company_id = company_dim.company_id
WHERE
    job_title_short = 'Data Analyst'  -- Focusing on Data Analyst roles
    AND salary_year_avg IS NOT NULL   -- Exclude jobs with missing salary info
ORDER BY salary_year_avg DESC         -- Highest salaries first
LIMIT 10;

/*
Note:
For this query, jobs from all locations are included. This is because in some regions 
(e.g., Nordic countries) salary information might be missing, and Data Analyst roles 
can span multiple countries.
*/

/* ============================================================
   2. What are the Skills required for these top-paying roles?
   
   This query identifies the skills required for the top-paying Data Analyst jobs.
   It uses a common table expression (CTE) to first select the top-paying jobs.
   
   Tables used:
   
   - job_postings_fact: Provides the job details including salary.
   - company_dim: Supplies the company name.
   - skills_job_dim: Bridges job postings with the skills required.
   - skills_dim: Provides descriptive names for each skill.
   
   We first build a CTE (top_paying_jobs) that selects the top-paying job postings.
   Then, we join this CTE with the skills tables to list the skills required for each job.
   ============================================================ */
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
    top_paying_jobs.*,   -- All job posting details from the top-paying jobs CTE
    skills               -- Skill name from skills_dim
FROM top_paying_jobs
INNER JOIN skills_job_dim 
    ON top_paying_jobs.job_id = skills_job_dim.job_id  -- Join to get the skills linked to each job
INNER JOIN skills_dim 
    ON skills_job_dim.skill_id = skills_dim.skill_id       -- Retrieve the human-readable skill names
ORDER BY salary_year_avg DESC
LIMIT 1000;

/* ============================================================
   3. What are the most in-demand skills for Data Analysts?
   
   This section includes several queries to explore the demand for skills in 
   the Data Analyst role. The main tables involved are:
   
   - job_postings_fact: Contains job posting information.
   - skills_job_dim: Connects job postings to skills.
   - skills_dim: Provides skill names.
   
   The following queries calculate counts of job postings by skill, filtered by:
     a) All Data Analyst jobs.
     b) Data Analyst jobs with high-paying salaries (>= 50,000).
     c) Remote Data Analyst jobs with high-paying salaries.
   ============================================================ */

-- 3.a. TOP 10 Skills for Data Analyst (ALL JOBS)
SELECT 
    sc.job_title_short,        -- Job title (should be 'Data Analyst')
    sd.skills,                 -- Skill name from skills_dim
    sc.skill_count             -- Count of job postings requiring the skill
FROM (
    -- Subquery: count the number of postings per skill for each job title
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
LIMIT 10;

-- 3.b. TOP 10 Skills for Data Analyst (HIGH PAYING JOBS)
SELECT 
    sc.job_title_short,        -- Should be 'Data Analyst'
    sd.skills,                 -- Skill name
    sc.skill_count             -- Count of job postings with the skill
FROM (
    -- Subquery: count the postings per skill, filtered by high salary (>= 50,000)
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
LIMIT 10;

-- 3.c. TOP 10 Skills for Data Analyst Remote Jobs (with Salary >= 50,000)
SELECT 
    sc.job_title_short,        -- Job title, here expected to be 'Data Analyst'
    sd.skills AS skill_name,   -- Skill name
    sc.skill_count             -- Count of postings for remote jobs requiring the skill
FROM (
    -- Subquery: count the postings per skill for remote jobs with high salary and matching job title
    SELECT 
        j.job_title_short,
        sj.skill_id,
        j.job_work_from_home,     -- Indicates if the job is remote
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
WHERE sc.job_work_from_home = TRUE    -- Only remote jobs
ORDER BY sc.skill_count DESC
LIMIT 10;

/*
Observation:
The top 4 skills remain consistent across high-paying jobs, remote jobs, and all jobs:
   1. SQL
   2. Excel
   3. Python
   4. Tableau
   Additional skills like R and Power BI appear in the top 5/6.
*/

/* ============================================================
   EXTRA: Select Only the Top 5 Skills for Each Job Title
   
   This query uses a window function to rank skills by their count for each 
   job title. The ROW_NUMBER() function resets for each job title (partitioned 
   by job_title_short). Then, we filter to only include the top 5 skills per job title.
   
   Tables:
   - job_postings_fact: Contains job posting details.
   - skills_job_dim: Bridges job postings with skills.
   - skills_dim: Provides descriptive skill names.
   ============================================================ */
SELECT job_title_short, skills, skill_count
FROM (
    SELECT 
        sc.job_title_short,
        sd.skills,
        sc.skill_count,
        ROW_NUMBER() OVER (
            PARTITION BY sc.job_title_short 
            ORDER BY sc.skill_count DESC
        ) AS rn  -- Row number ranking each skill within its job title
    FROM (
        -- Subquery: count postings per skill for each job title
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
) AS ranked
WHERE rn <= 5  -- Only include the top 5 skills per job title
ORDER BY job_title_short, skill_count DESC;




-- 4. What are the top skills based on salary for my role?

-- ============================================================
-- Query 1: Top Skills Based on Average Salary
--
-- Description:
-- This query calculates the average salary for each skill required
-- for Data Analyst roles. It joins three tables:
--   • job_postings_fact (jpf): Contains job postings and salary data.
--   • skills_job_dim (sjd): Bridges job postings with their required skills.
--   • skills_dim (sd): Provides descriptive names for each skill.
-- The query filters out job postings with NULL salary values,
-- groups the data by skill, and orders the skills by the computed
-- average salary (highest first). It returns the top 50 skills.
-- ============================================================

SELECT
    sd.skills,                                    -- Skill name from the skills dimension table
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary  -- Average salary rounded to 0 decimals
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id  -- Linking jobs to skills
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id       -- Getting skill names
WHERE job_title_short = 'Data Analyst'  -- Focus on Data Analyst roles
  AND salary_year_avg IS NOT NULL       -- Exclude rows with missing salary data
GROUP BY sd.skills                      -- Group by skill
ORDER BY avg_salary DESC                -- Order by highest average salary
LIMIT 50;                               -- Limit to top 50 results

-- ============================================================
-- Query 2: Detailed Salary Spread for Each Skill
--
-- Description:
-- This query extends the analysis from Query 1 by providing more
-- details about the salary distribution for each skill required
-- for Data Analyst roles. It computes:
--   • avg_salary: The average salary for each skill.
--   • min_salary: The lowest salary observed for each skill.
--   • max_salary: The highest salary observed for each skill.
--   • salary_std_dev: The standard deviation of the salaries, which
--     indicates how spread out the salary figures are.
-- The same joins and filtering conditions are applied, and the data
-- is ordered by average salary in descending order (top 50 results).
-- ============================================================

SELECT
    sd.skills,                                     -- Skill name
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary,  -- Average salary (rounded)
    MIN(jpf.salary_year_avg) AS min_salary,             -- Minimum salary observed
    MAX(jpf.salary_year_avg) AS max_salary,             -- Maximum salary observed
    ROUND(STDDEV(jpf.salary_year_avg), 0) AS salary_std_dev  -- Standard deviation of salary (rounded)
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.salary_year_avg IS NOT NULL
GROUP BY sd.skills
ORDER BY avg_salary DESC
LIMIT 50;

-- ============================================================
-- Query 3: Salary Spread with Job Count Filter to counter extreme values
--
-- Description:
-- This query builds on Query 2 by adding a count of distinct job
-- postings for each skill. This count (job_count) helps identify
-- how many job postings are associated with each skill. A HAVING
-- clause is applied to filter out skills that appear in fewer than
-- 5 job postings, which helps exclude extreme or niche values that
-- might distort the analysis. The output is the same as Query 2,
-- but with the additional job_count column, ordered by average
-- salary in descending order (top 50 results).
-- ============================================================

SELECT
    sd.skills,                                      -- Skill name
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary, -- Average salary (rounded)
    MIN(jpf.salary_year_avg) AS min_salary,           -- Minimum salary
    MAX(jpf.salary_year_avg) AS max_salary,           -- Maximum salary
    ROUND(STDDEV(jpf.salary_year_avg), 0) AS salary_std_dev, -- Salary standard deviation (rounded)
    COUNT(DISTINCT jpf.job_id) AS job_count           -- Count of distinct job postings for each skill
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.salary_year_avg IS NOT NULL
GROUP BY sd.skills
HAVING COUNT(DISTINCT jpf.job_id) > 5   -- Include only skills with more than 5 job postings
ORDER BY avg_salary DESC
LIMIT 50;







SELECT
    sd.skills,                                      -- Skill name
    ROUND(AVG(jpf.salary_year_avg), 0) AS avg_salary, -- Average salary (rounded)
    MIN(jpf.salary_year_avg) AS min_salary,           -- Minimum salary
    MAX(jpf.salary_year_avg) AS max_salary,           -- Maximum salary
    ROUND(STDDEV(jpf.salary_year_avg), 0) AS salary_std_dev, -- Salary standard deviation (rounded)
    COUNT(DISTINCT jpf.job_id) AS job_count           -- Count of distinct job postings for each skill
FROM job_postings_fact jpf
INNER JOIN skills_job_dim sjd ON jpf.job_id = sjd.job_id
INNER JOIN skills_dim sd ON sjd.skill_id = sd.skill_id
WHERE jpf.job_title_short = 'Data Analyst'
  AND jpf.salary_year_avg IS NOT NULL
GROUP BY sd.skills
HAVING COUNT(DISTINCT jpf.job_id) > 5   -- Include only skills with more than 5 job postings
ORDER BY avg_salary DESC
LIMIT 25;


/* ============================================================
   4. Takeaway
    Premium for Niche Skills:
    Some specialized or niche skills (e.g., gitlab, kafka, pytorch, tensorflow) tend to have higher average salaries (up to around 134K) despite having fewer job postings. This suggests that expertise in these areas may command a premium.

    High-Demand, Broadly Adopted Skills:
    Skills like spark, snowflake, and hadoop appear in many job postings (with job counts in the high hundreds or over a hundred) but tend to have slightly lower average salaries compared to niche skills. This reflects broader market adoption and higher competition, which may temper the salary premium.

    Salary Variability:
    The wide ranges between the minimum and maximum salaries—as well as relatively large standard deviations—indicate considerable variation. This could be due to factors such as differences in company size, geographic location, or experience level. For example, while gitlab has an average of around 134K, its salaries range from about 57K to 205K.

    Market Balance:
    The data overall shows a balance between demand and compensation: highly specialized skills can lead to higher earnings but appear in fewer positions, while more common skills offer broader opportunities with slightly lower average pay.

In summary, if you're targeting a Data Analyst role, developing niche technical skills might yield higher pay, but you may also consider the volume of opportunities in the market when deciding which skills to focus on.

   ============================================================ */


-- 5. What are the most optimal skills to learn?
--
-- Identify skills in high demand and pay for data analyst roles
-- concentrate on remote positions with specified salaries
    
-- Final table has 3 columns: skills, demand_count and avg_salary and the data is on skill level, order by demand_count since that provides highest job security
-- demand count is count(skills_job_dim.job_id) as demand_couint
    
    -- 5.a Optimal: High Demand & High Paying


-- 5. What are the most optimal skills to learn?
-- 5.a Optimal: High Demand & High Paying
--
-- Description:
-- This query identifies skills for Data Analyst roles that are in high demand
-- and command high salaries, concentrating on remote positions with salary data.
-- The final result includes:
--    • skills: the name of the skill,
--    • demand_count: the number of job postings requiring that skill,
--    • avg_salary: the average salary for postings requiring the skill.
-- Filtering:
--    • Only include Data Analyst roles.
--    • Focus on remote jobs (job_work_from_home = TRUE).
--    • Exclude job postings with missing salary data.

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
LIMIT 10;               

-- top 5 skills 
--   1. SQL
--   2. Excel
--   3. Python
--   4. Tableau
--   5. R

-- Now if we order by salary instead
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
HAVING COUNT(DISTINCT jpf.job_id) > 10  -- Include only skills with more than 10 job postings
ORDER BY avg_salary DESC, 
        demand_count DESC
LIMIT 10;     

-- top 5 skills
-- 1. go
-- 2. confluence
-- 3. hadoop
-- 4. Snowflake
-- 5. Azure

-- Alot of cloud computing jobs