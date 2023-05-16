/*
Covid 19 Data Exploration

Skills used: Joins, CTE's, Subqueries, Union All, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/

Select *
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Order by location, date;


Select location, date, total_cases, total_deaths, population
	from PorfolioProjects..CovidDeaths
	Where continent is not null
	Order by location, date;


-- Total Cases vs Total Deaths: showing the rate of deaths on infected people in any country.

Select location, date, population, total_cases, total_deaths, (Cast(total_deaths as float)/total_cases)*100 as DeathRateonInfected
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Order by location, date;


-- Total Cases vs Population: showing the rate of infected people in any country.

Select location, date, population, total_cases, (total_cases/population)*100 as InfectedRate
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Order by location, date;
	

-- Total Deaths vs Population: showing the rate of deaths in any country.

Select location, date, population, total_deaths, (Cast(total_deaths as float)/population)*100 as DeathRateonPopulation
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Order by location, date;


-- Top 20 Countries with highest death rate on infected people.

Select Top 20 location, population, Max(Cast(total_cases as Float)) as Total_Cases, Max(Cast(total_Deaths as Float)) as Total_Deaths,
	(Max(Cast(total_Deaths as Float))/Max(Cast(total_cases as Float)))*100 as DeathRateOnInfected
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by location, population
	Order by DeathRateOnInfected Desc;

-- Or we could just CTEs and Joins to attain the desired result-set
With A as
	(
	Select location, population, Max(Cast(Total_Cases as Float)) as Total_Cases
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by location, population
	),
	B as
	(
	Select location, Max(Cast(total_deaths as Float)) as Total_Deaths
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by location
	)
	Select Top 20 A.Location, A.Population, A.Total_Cases, B.Total_Deaths, (B.Total_Deaths/A.Total_Cases)*100 as DeathRateOnInfected
	From A join B
	on A.location = B.location
	Order by DeathRateOnInfected Desc;


-- Top 20 Countries with highest infected rate.

Select Top 20 location, population, Max(Cast(total_cases as Float)) as Total_Cases,
	(Max(Cast(total_cases as Float))/population)*100 as InfectedRate
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by location, population
	Order by InfectedRate Desc;


-- Top 20 Countries with highest death rate on population.

Select Top 20 location, population, Max(Cast(total_Deaths as Float)) as Total_Deaths,
	(Max(Cast(total_Deaths as Float))/population)*100 as DeathRateOnPopulation
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by location, population
	Order by DeathRateOnPopulation Desc;


-- Top 3 Countries with highest death rate on infected people of each Continents.

Select Continent, location, population, Total_Cases, Total_Deaths, DeathRateOnInfected From
	(
	Select continent, location, population, Max(Cast(total_cases as Float)) as Total_Cases, Max(Cast(total_Deaths as Float)) as Total_Deaths,
	(Max(Cast(total_Deaths as Float))/Max(Cast(total_cases as Float)))*100 as DeathRateOnInfected,
	Row_number() Over (Partition By Continent Order by (Max(Cast(total_Deaths as Float))/Max(Cast(total_cases as Float)))*100 Desc) as Row_Count
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by continent, location, population
	) as A
	Where Row_Count<4;


-- Top 3 Countries with highest infected rate of each Continents.

With A as
	(
	Select continent, location, population, Max(Cast(total_cases as Float)) as Total_Cases,
	(Max(Cast(total_cases as Float))/Population)*100 as InfectedRate,
	Row_number() Over (Partition By Continent Order by (Max(Cast(total_cases as Float))/Population)*100 Desc) as Row_Count
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by continent, location, population
	)
	Select Continent, location, population, Total_Cases, InfectedRate From A
		Where Row_Count<4;


-- Top 3 Countries with highest death rate on population of each Continents.

With A as
	(
	Select continent, location, population, Max(Cast(total_Deaths as Float)) as Total_Deaths,
	(Max(Cast(total_Deaths as Float))/Population)*100 as DeathRateOnPopulation,
	Row_number() Over (Partition By Continent Order by (Max(Cast(total_Deaths as Float))/Population)*100 Desc) as Row_Count
	From PorfolioProjects..CovidDeaths
	Where continent is not null
	Group by continent, location, population
	)
	Select Continent, location, population, Total_Deaths, DeathRateOnPopulation From A
		Where Row_Count<4;


-- Summarizing DeathRateOnInfected, InfectedRate, DeathRateOnPopulation by Continents and Global	

Select continent, location, population, Max(Cast(total_cases as Float)) as Total_Cases, Max(Cast(total_Deaths as Float)) as Total_Deaths
	Into #Temp
	From PorfolioProjects..CovidDeaths
	Where continent is not null 
	Group by continent, location, population
Select Continent,Sum(population) as Population, Sum(Total_Cases) as Cases, Sum(Total_Deaths) as Deaths
	From #Temp
	Group by Continent
Union All
Select 'Total', Sum(population) as Population, Sum(Total_Cases) as Cases, Sum(Total_Deaths) as Deaths
	From #Temp


-- The percentage of Population that has recieved at least one Covid Vaccine

Create View VaccinatedPercentage as
With A as
	(
	Select Dea.continent, Dea.location, Dea.population, Convert(float,Vac.people_vaccinated) as PeopleVaccinated,
	ROW_NUMBER() Over (Partition by Dea.location Order by Convert(float,Vac.people_vaccinated) Desc) as R
		From PorfolioProjects..CovidDeaths as Dea
		Join PorfolioProjects..CovidVaccinations as Vac
		On Dea.location = Vac.location
		And Dea.date = Vac.Date
		Where Dea.continent is not null
	)
Select continent, location, population, isnull(PeopleVaccinated,0) as PeopleVaccinated, (isnull(PeopleVaccinated,0)/population)*100 as VaccinatedPercentage
	From A
	Where R < 2
