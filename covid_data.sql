/*These SQL queries explore data from two tables, Covid Deaths and Covid Vaccinations. 
The queries are used to answer various questions about the impact of Covid-19, including:
•	Total cases vs. total deaths: The likelihood of dying if you contract Covid in a particular location. 
•	Total cases vs. population: The percentage of the population infected with Covid.
•	Countries with the highest infection rate compared to the population. 
•	Countries with the highest death count per population. 
•	The continents with the highest death count per population. 
•	The total number of cases and deaths globally. 
•	The total population vs. vaccinations: The percentage of the population that has received at least one Covid vaccine. 
The queries use various techniques such as joins, CTE's, temp tables, windows functions, aggregate functions, creating views, and converting data types.
*/


Select *
From  CovidDeaths
Where continent is not null 
order by 3,4


-- Select Data that we are going to be starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From  CovidDeaths
Where continent is not null 
order by 1,2


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From  CovidDeaths
Where location like 'U%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From  CovidDeaths
order by 1,2


-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From  CovidDeaths
Group by Location, Population
order by PercentPopulationInfected desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From  CovidDeaths
Where continent is not null 
Group by Location
order by TotalDeathCount desc



-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From  CovidDeaths
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From  CovidDeaths
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From  CovidDeaths deaths
Join  CovidVaccinations vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From  CovidDeaths deaths
Join  CovidVaccinations vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists PercentPopulationVaccinated
Create Table PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into PercentPopulationVaccinated
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(bigint,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From  CovidDeaths deaths
Join  CovidVaccinations vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date

Select *, (RollingPeopleVaccinated/Population)*100
From PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View VW_PercentPopulationVaccinated as
Select deaths.continent, deaths.location, deaths.date, deaths.population, vaccinations.new_vaccinations
, SUM(CONVERT(int,vaccinations.new_vaccinations)) OVER (Partition by deaths.Location Order by deaths.location, deaths.Date) as RollingPeopleVaccinated
From  CovidDeaths deaths
Join  CovidVaccinations vaccinations
	On deaths.location = vaccinations.location
	and deaths.date = vaccinations.date
where deaths.continent is not null