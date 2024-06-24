-- Subdatasets used for Tableau
-- VIEW Summary_death: Summary table of total death amount among Continents
-- VIEW New_vacc_pop_portion: Cumulated_new_vaccinations, location, date ...
-- VIEW: Summary_New_death: total cases, total death and death perc
-- VIEW Infect_info: Countries with Highest Infection Rate compared to Population

-- Death:

-- Take a quick look

SELECT *
FROM public."COVID_Death"
WHERE continent is not null 
ORDER BY 3,4


-- Preprocess data: remove unstrucured data

UPDATE public."COVID_Death"
SET location = 'Cote dlvoire'
WHERE location LIKE '%Cote%';



-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM public."COVID_Death"
WHERE continent is not null 
ORDER by 1,2


-- Descriptive analysis
-- Total Cases Vs Total Deaths: Shows likelihood of dying if got covid in your country (E.G. US)

SELECT Location, date, total_cases,total_deaths, 
       ROUND((total_deaths:: NUMERIC/total_cases:: NUMERIC)*100 ,2) as Death_Portion
FROM  public."COVID_Death"
WHERE location LIKE '%States%' AND continent is not null 
ORDER BY 1,2


-- Total Cases Vs Population
-- Shows the percentage of population infected with Covid  (US as example)

SELECT Location, date, Population, total_cases, 
       ROUND((total_cases:: NUMERIC/Population:: NUMERIC)*100 ,2) as Infect_Portion
FROM public."COVID_Death"
WHERE total_cases IS NOT NULL AND location LIKE '%States%' AND continent is not null 
ORDER BY 1,2


--VIEW Infect_info: Countries with Highest Infection Rate compared to Population

CREATE VIEW Infect_info AS

(SELECT Location, Population, MAX(total_cases) as Highest_Infection_num, 
       MAX (ROUND((total_cases:: NUMERIC/Population:: NUMERIC)*100 ,2)) as Infect_Portion
	   
FROM  public."COVID_Death"
WHERE total_cases IS NOT NULL -- Exclude country that not have recorded data about infected situation
GROUP BY Location, Population
ORDER BY Infect_Portion DESC)


-- Countries with Highest Death Count per Population
-- US has largest death amount: 1,188,935

SELECT Location, MAX(cast(Total_deaths as int)) as Total_Death_num
FROM  public."COVID_Death"
--Where location like '%states%'
WHERE continent IS NOT NULL AND Total_deaths IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death number among population

--Problems: north america only include US data not canada, so need to fix
-- When we filter out null value under continent, we also give up data that should be added to continent sum number
SELECT Location, MAX(cast(Total_deaths as int)) as Total_Death_num
FROM  public."COVID_Death"
--Where location like '%states%'
WHERE continent IS NULL AND Total_deaths IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC

-- Convert data type: Total_deaths to integer
-- SELECT continent, 
--        MAX(cast(Total_deaths as int)) as Total_Death_num
-- FROM public."COVID_Death"
-- WHERE continent is not null 
-- GROUP BY continent
-- ORDER BY  Total_Death_num DESC

SELECT continent, -- only not null value under continent
       MAX(Total_deaths ) as Total_Death_num
FROM public."COVID_Death"
WHERE continent is not null 
GROUP BY continent
ORDER BY  Total_Death_num DESC



-- Combine these tables by uisng union all

CREATE VIEW Summary_death AS
(WITH Summary_death AS
(
(SELECT Location, MAX(cast(Total_deaths as int)) as Total_Death_num
FROM  public."COVID_Death"
WHERE continent IS NULL AND Total_deaths IS NOT NULL
GROUP BY Location
ORDER BY 2 DESC)

UNION ALL

(SELECT continent, -- only not null value under continent
       MAX(Total_deaths ) as Total_Death_num
FROM public."COVID_Death"
WHERE continent is not null 
GROUP BY continent
ORDER BY  Total_Death_num DESC)
)




-- Global number: 
-- Summary table of total death amount among Continents.

SELECT Location, SUM(Total_Death_num) AS Final_death_num
FROM Summary_death
WHERE Location NOT LIKE '%income%' AND Location NOT LIKE '%Union%' -- get rid of abnormal class (income class)
GROUP BY Location
)

-- Global death portion
-- Problem: division by 0 due to the possibility we got 0 new cases so we assign 0 to this situation

SELECT date, 
       SUM(new_cases) AS Total_new_cases, 
	   SUM(new_deaths) AS Total_new_death,
       ROUND( CASE WHEN SUM(new_cases)=0 THEN 0
			       ELSE (SUM(new_deaths):: NUMERIC/SUM(new_cases):: NUMERIC)*100
			       END
		   ,2) as Death_Portion_Globally
FROM  public."COVID_Death"
WHERE continent IS NOT NULL
GROUP BY 1
ORDER BY 1


-- Across the world, we got 0.91% death rate among new cases appeared.

SELECT  
       SUM(new_cases) AS Total_new_cases, 
	   SUM(new_deaths) AS Total_new_death,
       ROUND( CASE WHEN SUM(new_cases)=0 THEN 0
			       ELSE (SUM(new_deaths):: NUMERIC/SUM(new_cases):: NUMERIC)*100
			       END
		   ,2) as Death_Portion_Globally
FROM  public."COVID_Death"
WHERE continent IS NOT NULL

ORDER BY 1





-- Vaccination:


-- Totoal population Vs Vaccinations
-- Add new column: get cumulative increase in the number of people newly vaccinated
-- CTE
WITH Vacc_pop AS 
(SELECT dea.continent,
       dea.location,
	   dea.date,
	   dea.population,
	   vacc.new_vaccinations, -- New vaccinations amount per day
	   SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS  Cumulated_new_vaccinations
	   
	   
FROM public."COVID_Vaccination" vacc
JOIN public."COVID_Death" dea
    ON vacc.location= dea.location
	AND vacc.date= dea.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date
)

SELECT *, ROUND((Cumulated_new_vaccinations:: NUMERIC/population:: NUMERIC)*100,2) AS Per_vacc_of_pop
FROM Vacc_pop

-- Temporary table way

DROP TABLE  IF EXISTS Vacc_pop

CREATE TEMP TABLE Vacc_pop  (
continent varchar(255),
location  varchar(255),
date date,
population numeric,
new_vaccinations numeric,
Cumulated_new_vaccinations numeric
)

INSERT INTO Vacc_pop 

SELECT dea.continent,
       dea.location,
	   dea.date,
	   dea.population,
	   vacc.new_vaccinations, -- New vaccinations amount per day
	   SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS  Cumulated_new_vaccinations
	   
	   
FROM public."COVID_Vaccination" vacc
JOIN public."COVID_Death" dea
    ON vacc.location= dea.location
	AND vacc.date= dea.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date

SELECT *, ROUND((Cumulated_new_vaccinations:: NUMERIC/population:: NUMERIC)*100,2) AS Per_vacc_of_pop
FROM Vacc_pop 


-- Create view for visualization: VIEW New_vacc_pop_portion (Permenant one)

CREATE VIEW New_vacc_pop_portion AS

(SELECT dea.continent,
       dea.location,
	   dea.date,
	   dea.population,
	   vacc.new_vaccinations, -- New vaccinations amount per day
	   SUM(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS  Cumulated_new_vaccinations
	   
	   
FROM public."COVID_Vaccination" vacc
JOIN public."COVID_Death" dea
    ON vacc.location= dea.location
	AND vacc.date= dea.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.location, dea.date
)

-- VIEW: Summary_New_death: total cases, total death and death perc

CREATE VIEW Summary_New_death AS
(SELECT SUM(new_cases) AS Total_new_cases, 
       SUM(new_deaths) AS Total_new_death, 
	   ROUND(100*SUM(new_deaths)::NUMERIC/SUM(new_cases)::NUMERIC,2) AS New_case_death_perc
FROM public."COVID_Death"
)

 