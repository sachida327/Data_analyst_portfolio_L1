/*
portfolio setup query
*/

use [L1 PORTFOLIP]

SELECT *
FROM dbo.coviddeath
order by 3,4


select location, date, total_cases_per_million, new_cases, total_deaths, population 
from [L1 PORTFOLIP]..coviddeath
order by 1, 2

-- looking at total cases vs total deaths

select location ,date,population, total_deaths, (population-total_deaths) as totalalive
from dbo.coviddeath

where total_deaths>10
order by 1,2

-- looking for total deaths in a per million 
select location ,date,population, total_deaths_per_million,total_cases_per_million, (total_deaths_per_million/total_cases_per_million)*100 as deathprecentagepermillion

from dbo.coviddeath
where total_deaths_per_million>1
order by 1,2


-- looking at total cases  vs popiultaion 
select location ,date,population, total_cases_per_million,(total_cases_per_million/population)*100 as casespermillion_popultaion

from dbo.coviddeath
where total_cases_per_million>1
order by 1,2


--looking at population countries with highest death  rate compared to poulation
select location,population, MAX(total_deaths) as mortalitly_count, max((total_deaths/population))*100 as mortality_rate
from dbo.coviddeath
group by location,population
order by mortalitly_count desc

--looking at total cases vs total deaths
select location,MAX(cast(Total_deaths As int )) as Total_death_count
from dbo.coviddeath
where continent is not null
group by location
order by Total_death_count desc 


--lets break down things by continent 


select continent,MAX(cast(Total_deaths As int )) as Total_death_count
from dbo.coviddeath
where continent is not null
group by continent
order by Total_death_count desc 

-- breaking it down by countries with null continent value

select location,MAX(cast(Total_deaths As int )) as Total_death_count
from dbo.coviddeath
where continent is not null
group by location
order by Total_death_count desc 

-- showing continent with deaths 
select continent,MAX(cast(Total_deaths As int )) as Total_death_count
from dbo.coviddeath
where continent is not null
group by continent
order by Total_death_count desc 

----breaking global numbers not for uses

--select location,total_cases_per_million, total_deaths,(total_cases_per_million/total_deaths)*100 as Death_percentage_per_million 
--from dbo.coviddeath
--where continent is not null and total_deaths_per_million>1

--order by Death_percentage_per_million desc 
SELECT 
    DaTe,
    SUM(new_cases) AS total_cases,
    SUM(CAST(new_deaths AS INT)) AS total_deaths,
    (SUM(CAST(new_deaths AS FLOAT)) / NULLIF(SUM(new_cases), 0)) * 100 AS death_percentage
FROM dbo.coviddeath
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date;


--  rolling vaccinations count
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    vac.new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS BIGINT)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS rolling_vaccinations
FROM dbo.coviddeath dea
JOIN dbo.covidvaccine vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
  AND vac.new_vaccinations IS NOT NULL
ORDER BY dea.location, dea.date;

-- use population vs vaccinated 
WITH popvsvac (
    continent,
    location,
    date,
    population,
    rolling_vaccinations
)
AS
(
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        SUM(CAST(vac.new_vaccinations AS BIGINT)) 
            OVER (
                PARTITION BY dea.location 
                ORDER BY dea.date
            ) AS rolling_vaccinations
    FROM dbo.coviddeath dea
    JOIN dbo.covidvaccine vac
        ON dea.location = vac.location
       AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
      AND vac.new_vaccinations IS NOT NULL
)
SELECT * 
FROM popvsvac
--ORDER BY location, date;

-- creating a temp table

create Table percentagepopulation_vaccinated
(
continent nvarchar(255),
location nvarchar(236),
date datetime,
population numeric,
New_vaccinations numeric,
rolling_vaccinations numeric

)
INSERT INTO dbo.percentagepopulation_vaccinated
(
    continent,
    location,
    date,
    population,
    rolling_vaccinations
)
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    SUM(CAST(ISNULL(vac.new_vaccinations, 0) AS BIGINT)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS rolling_vaccinations
FROM dbo.coviddeath dea
JOIN dbo.covidvaccine vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;

select * ,(rolling_vaccinations/population)*100 as vaccinated 
from dbo.percentagepopulation_vaccinated

ALTER TABLE dbo.percentagepopulation_vaccinated
DROP COLUMN New_vaccinations;


--- create view for data visulaisation
create view percenatgepoulation_vaccinated as
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    SUM(CAST(ISNULL(vac.new_vaccinations, 0) AS BIGINT)) 
        OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS rolling_vaccinations
FROM dbo.coviddeath dea
JOIN dbo.covidvaccine vac
    ON dea.location = vac.location
   AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--order by 2,3
select*
from percenatgepoulation_vaccinated

