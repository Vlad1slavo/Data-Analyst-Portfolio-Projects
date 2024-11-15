
Select *
From covid..CovidDeaths
order by 3,4

Select *
From covid..CovidVaccinations
order by 3,4

--Select Data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From covid..CovidDeaths
order by 1,2


-- Looking at Total Causes vs Totak Deaths
SELECT 
    location, date, total_cases, total_deaths,
    CASE 
        WHEN total_cases = 0 THEN 0
        ELSE (total_deaths / total_cases) * 100
    END AS DeathPercentage
From covid..CovidDeaths
Where location like '%raine%'
order by 5 DESC

--Looking at Total Cases vs Population
-- Shows what percentage of population got Covid
SELECT 
    location, date, population, total_cases, (total_cases/population)*100 as CasePercentage
From covid..CovidDeaths
Where location='Ukraine'
order by 5 DESC

--Looking at Countries with Highest Infection Rate compare to Population

SELECT 
    location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From covid..CovidDeaths
Group by location, population
order by PercentPopulationInfected DESC


--Showing Countries with Highest Death Count per Population

SELECT 
    location, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid..CovidDeaths
Where continent is not null
Group by location
order by TotalDeathCount DESC


--Lets break things down by continent
--Showing continents with the highest death count per population

SELECT 
    continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From covid..CovidDeaths
Where continent is not null
Group by continent
order by TotalDeathCount DESC

--GLOBAL NUMBERS

SELECT 
    SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths,
	CASE 
        WHEN SUM(new_cases) = 0 THEN 0
        ELSE (SUM(cast(new_deaths as int)) / SUM(new_cases)) * 100
    END AS DeathPercentage
From covid..CovidDeaths
Where continent is not null
order by 1,2

--Looking at Total Population vs Vaccination
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, COALESCE(vac.new_vaccinations, 0))) 
        OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/population)*100
From 
    covid..CovidDeaths dea
Join 
    covid..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
Where 
    dea.continent is not null
Order by 
    dea.location, dea.date;

--Use CTE
With PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, COALESCE(vac.new_vaccinations, 0))) 
        OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/vac.population)*100
From 
    covid..CovidDeaths dea
Join 
    covid..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
Where 
    dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPercent
From PopvsVac

--Temp Table
DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentPopulationVaccinated
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, COALESCE(vac.new_vaccinations, 0))) 
        OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/vac.population)*100
From 
    covid..CovidDeaths dea
Join 
    covid..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
Where 
    dea.location='Ukraine'

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated

--Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations, 
    SUM(CONVERT(bigint, COALESCE(vac.new_vaccinations, 0))) 
        OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
	--(RollingPeopleVaccinated/vac.population)*100
From 
    covid..CovidDeaths dea
Join 
    covid..CovidVaccinations vac
    On dea.location = vac.location
    and dea.date = vac.date
Where 
    dea.continent is not null
