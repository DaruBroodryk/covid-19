use PortfolioProject
go
----------------------------------------
----Cases vs deaths
----------------------------------------
create or alter view vwCasesVSDeaths
as
select 
	[location], 
	[date],
	[total_cases],
	[total_deaths],
	(cast([total_deaths] as decimal(38,2))/cast([total_cases] as decimal(38,2))) * 100 as DeathPercentage
from 
	PortfolioProject..CovidDeaths
go
----------------------------------------
----Cases vs population
----------------------------------------
create or alter view vwCasesVSPopulation
as
select 
	[location], 
	[date],
	[total_cases],
	[population],
	(cast([total_cases] as decimal(38,2))/cast([population] as decimal(38,2))) * 100 as [PercentPolulationInfected]
from 
	PortfolioProject..CovidDeaths
go
----------------------------------------
----Infection rates
----------------------------------------
create or alter view vwHighestInfectionRates
as
select 
	[location],
	[population],
	max([total_cases]) as HigestInfectionCount,
	max(cast([total_cases] as decimal(38,2))/cast([population] as decimal(38,2))) * 100 as [PercentPolulationInfected]
from 
	PortfolioProject..CovidDeaths
group by 
	[location],[population]
go
----------------------------------------
----Death rates
----------------------------------------
create or alter view vwHighestDeathRates
as
select 
	[location],
	[population],
	max([total_deaths]) as DeathCount,
	max(cast([total_deaths] as decimal(38,2))/cast([population] as decimal(38,2))) * 100 as DeathRate
from 
	PortfolioProject..CovidDeaths
group by 
	[location],[population]
go
----------------------------------------
----Death counts
----------------------------------------
create or alter view vwHighestDeathCounts
as
select 
	[location],
	max(total_deaths) as [DeathCount]
from 
	PortfolioProject..CovidDeaths
group by 
	[location]
go
----------------------------------------
----Infection counts
----------------------------------------
create or alter view vwHighestInfectionCounts
as
select 
	[location],
	max([total_cases]) as [InfectionCount]
from 
	PortfolioProject..CovidDeaths
group by 
	[location]
go
----------------------------------------
----Death counts per Continent
----------------------------------------
create or alter view vwDeathCountvsContinent
as
select 
	isnull([continent],'Not Specified') as [Continent],
	max([total_deaths]) as [DeathCount]
from 
	PortfolioProject..CovidDeaths
group by 
	[continent]
go
----------------------------------------
----Infection counts per Continent
----------------------------------------
create or alter view vwInfectionCountvsContinent
as
select 
	isnull([continent],'Not Specified') as [Continent],
	max([total_cases]) as [InfectionCount]
from 
	PortfolioProject..CovidDeaths
group by 
	[continent]
go
----------------------------------------
----Global Numbers
----------------------------------------
create or alter view vwGlobal
as
select 
	[date],
	sum(cast([new_cases] as decimal(38,2))) as [TotalCases],
	sum(cast([new_deaths] as decimal(38,2))) as [TotalDeaths],
	case 
		when (sum(cast(isnull([new_deaths],1) as decimal(38,2))) / sum(cast(isnull([new_cases],1) as decimal(38,2)))) * 100 = 100 then 0 
		else (sum(cast(isnull([new_deaths],1) as decimal(38,2))) / sum(cast(isnull([new_cases],1) as decimal(38,2)))) * 100 
	end as [TotalDeathPercentage]
from 
	PortfolioProject..CovidDeaths
group by 
	[date]
go
----------------------------------------
----Population vs vaccination
----------------------------------------
create or alter view vwRunningTotals
as
with RunningCalc 
as
(
select 
	deaths.[continent],
	deaths.[location],
	deaths.[Date],
	deaths.[population],
	vaccinations.[new_vaccinations],
	sum(cast(vaccinations.[new_vaccinations] as decimal(38,2))) over (partition by deaths.[location] order by deaths.[location],deaths.[Date]) as [RunningTotalVaccinated]
from 
	PortfolioProject..CovidDeaths deaths
	inner join PortfolioProject..CovidVaccinations [vaccinations]
		on deaths.[location] = vaccinations.[location]
		and deaths.[date] = vaccinations.[date]
)
select 
	*,
	([RunningTotalVaccinated]/[population]) * 100 as [RunningTotalPercentageVaccinated]
from 
	RunningCalc
go
----------------------------------------
----Deaths vs vaccinations
----------------------------------------
create or alter view vwDeathVaccinations
as
select 
	isnull(deaths.[location],0) as [location],
	isnull(deaths.[date],0) as [date],
	isnull(deaths.[new_deaths],0) as [new_deaths],
	isnull(deaths.[total_deaths],0) as [total_deaths],
	isnull(vaccinations.[new_vaccinations],0) as [new_vaccinations],
	isnull(vaccinations.[total_vaccinations],0) as [total_vaccinations]
from 
	PortfolioProject..CovidDeaths deaths
	inner join PortfolioProject..CovidVaccinations [vaccinations]
		on deaths.[location] = vaccinations.[location]
		and deaths.[date] = vaccinations.[date]
go
----------------------------------------
--Queries used for Tableau Project
----------------------------------------
/*
Just a double check based off the data provided
numbers are extremely close so we will keep them - The Second includes "International"  Location
*/
-- 1. 

select 
	sum(cast(new_cases as decimal(38,2))) as total_cases, 
	sum(cast(new_deaths as decimal(38,2))) as total_deaths, 
	sum(cast(new_deaths as decimal(38,2)))/sum(cast(New_Cases as decimal(38,2)))*100 as DeathPercentage
from 
	PortfolioProject..CovidDeaths
where 
	continent is not null 
order by 1,2


-- 2. 

/*
We take these out as they are not inluded in the above queries and want to stay consistent
European Union is part of Europe
*/

select 
	location, 
	sum(cast(new_deaths as decimal(38,2))) as TotalDeathCount
from 
	PortfolioProject..CovidDeaths
where 
	continent is null 
	and location not in ('World', 'European Union', 'International')
group by 
	location
order by 
	TotalDeathCount desc


-- 3.
select 
	Location, 
	Population, 
	max(cast(total_cases as decimal(38,2))) as HighestInfectionCount,  
	max((cast(total_cases as decimal(38,2))/population))*100 as PercentPopulationInfected
from
	PortfolioProject..CovidDeaths
group by 
	Location, Population
order by
	PercentPopulationInfected desc


-- 4.
select 
	Location, 
	Population,
	date, 
	max(cast(total_cases as decimal(38,2))) as HighestInfectionCount, 
	max((cast(total_cases as decimal(38,2))/population))*100 as PercentPopulationInfected
from
	PortfolioProject..CovidDeaths
group by
	Location, 
	Population, 
	date
order by 
	PercentPopulationInfected desc