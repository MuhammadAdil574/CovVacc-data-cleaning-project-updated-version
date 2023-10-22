-- LOAD DATA LOCAL INFILE "C:/Users/mjnon/Downloads/CovidDeathsCSV.csv" INTO TABLE covdeaths FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES ;

SHOW DATABASES;
DROP TABLE IF EXISTS covdeaths, covvacc;

SET SQL_SAFE_UPDATES = 0; -- REMOVING SAFE CHECK FOR DELETING/UPDATING LARGE AMOUNTS OF DATA AT ONCE.
SET @@GLOBAL.local_infile = 1;
-- LOAD DATA LOCAL INFILE "C:/Users/hp/Downloads/owid-covid-data.csv" INTO TABLE covdeaths FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES ;




Create database COV_project;
show databases ;

USE COV_project;
-- in order to save or delete big files
SET SQL_SAFE_UPDATES=0;
-- in order to import data from your own computer into MYsql
SET GLOBAL local_infile=1;


set global local_infile=true;

-- DATA IMPORT FOR COVID DEATHS.
show tables;
select * from cov_death;
-- delete from cov_death;

 -- LOAD DATA LOCAL INFILE "C:/Users/hp/Downloads/CovDeaths.csv" INTO TABLE cov_death FIELDS TERMINATED BY ',' ENCLOSED BY '"'
 -- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES ;


-- DATA IMPORT FOR COVID VACCINATION
show tables;
select * from cov_vacc;
-- delete from cov_vacc;

-- LOAD DATA LOCAL INFILE "C:/Users/hp/Downloads/CovVacc.csv" INTO TABLE cov_vacc FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\r\n'
-- IGNORE 1 LINES ;

-- select data that we are going to be using

select location, date, total_cases, population , new_cases, total_deaths from cov_death
order by 1,2 ;

-- Total cases vs Total deaths

select location, date, total_cases , total_deaths , (total_deaths/total_cases)* 100 as Death_Percentage 
from cov_death order by 1,2 ;

-- percentage in differnt countries 
-- USA

select location, date, total_cases , total_deaths , (total_deaths/total_cases)* 100 as Death_Percentage 
from cov_death where location like '%States%'
order by 1,2 ;

-- Germany

select location, date, total_cases , total_deaths , (total_deaths/total_cases)* 100 as Death_Percentage 
from cov_death where location like '%Germany%'
order by 1,2 ;

-- Mexico
select location, date, total_cases , total_deaths , (total_deaths/total_cases)* 100 as Death_Percentage 
from cov_death where location like '%Mexico%'
order by 1,2 ;

-- Tota_cases vs Population
select location, date, total_cases , total_deaths , (total_cases/population)* 100 as Death_Percentage 
from cov_death 
order by 1,2 ;

-- looking at highest infection rate as compare to  population

select location , population , max(total_cases)  as Highestinfectioncount , max((total_cases/population)) * 100 
as Percent_Population_Infected from cov_death 
Group by location , population 
Order by Highestinfectioncount desc;

-- showing coutries with highest death counts per population

select location ,  max(total_deaths) as TotalDeaths  from cov_death 
where continent is not null
Group by location 
Order by TotalDeaths desc;

-- Lets break things down with continent


select continent ,  max(total_deaths) as TotalDeaths  from cov_death 
where continent is not null
Group by continent 
Order by TotalDeaths desc;

-- Global Numbers

select  date, sum(new_cases) from cov_death 
group by date
order by 2,1 ;


-- covid vacc table
select * from cov_vacc;

-- looking at total population vs vaccinations

select dea.continent, dea.location, dea.date,dea.population, vac.new_vaccinations from cov_death as dea 
join
cov_vacc as vac 
on dea.location= vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2,4;


-- DESC cov_vacc;

-- SELECT cast(120.43 AS INT) ;
-- SELECT CAST(120.43 AS INT);
-- SELECT CAST(120.43 AS SIGNED);

-- population vs Vaccination
-- it shows the percentage of people getting atleast one vaccination in a year

select dea.continent, dea.location, dea.date,dea.population , vac.new_vaccinations,
sum(convert(int , vac.new_vaccinations)) over ( partition by dea.location order by dea.location , dea.date)
 from cov_death as dea 
join
cov_vacc as vac 
on dea.location= vac.location
and dea.date=vac.date
where dea.continent is not null
order by 2,3 ;

-- Use of CTE

with popvsvac (continent , location , date, popultation, new_vaccinations, Rollingvaccinated)
as 

select dea.continent, dea.location, dea.date,dea.population , vac.new_vaccinations,
sum(convert(int, vac.new_vaccinations)) over ( partition by dea.location order by dea.location , dea.date) 
as Rollingvaccinated
From cov_death as dea 
join cov_vacc as vac 
on dea.location= vac.location
and dea.date=vac.date
where dea.continent is not null
-- order by 2,3
select * (Rollingvaccinated/population)*100 
from popvsvac;

-- Using Temp Table to perform Calculation on Partition By in previous query


-- DROP Table if exists PercentPopulationVaccinated

Create Table PercentPopulationVaccinated
(
Continent varchar(255),
Location varchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
Rollingvaccinated numeric
)

Insert into PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as Rollingvaccinated
--  (Rollingvaccinated/population)*100
From cov_death as dea
Join cov_vacc as  vac
	On dea.location = vac.location
	and dea.date = vac.date
-- where dea.continent is not null 
-- order by 2,3

Select *, (Rollingvaccinated/Population)*100
From PercentPopulationVaccinated


-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 