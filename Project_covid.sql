-- Julio 2023,Romina Sepulveda
-- Projecto 1 Portafolio
-- Objetivo: Explorar y visualizar información de covid

-- 1. Check conneccion con las tablas
SELECT * FROM coviddeaths;
SELECT * FROM covidvaccinations;


-- 2. Explorar las columnas a utilizar / Explore columnas to use.

SELECT location,
  total_cases,
  STR_TO_DATE(date, '%c/%d/%y') AS date,
  total_cases,
  new_cases,
  total_deaths,
  population
FROM  coviddeaths
WHERE continent IS NOT NULL
ORDER BY 1,2;


-- 3. Explorar la probabilidad de morir en caso de contagio en Chile/ Explore the likelihood of  dying if you contract covid in Chile

SELECT location,
  STR_TO_DATE(date, '%c/%d/%y') AS date,
  total_cases,
  total_deaths,
  (total_deaths/total_cases)*100 as DeathPercentage
FROM  coviddeaths
WHERE location LIKE '%chile%'
    AND continent IS NOT NULL
ORDER BY 1,2;



-- Casos Totales vs Población / Looking at Total Cases vs Population
-- Porcentaje de la población que shows what percentage of population got covid
SELECT location,
  STR_TO_DATE(date, '%c/%d/%y') AS date,
  population,
  total_cases,
  (total_cases/population)*100 as Percentage_Population_Infected
FROM  coviddeaths
WHERE location LIKE '%chile%'
    AND continent IS NOT NULL
ORDER BY 1,2
;


-- Países con la mayor taza de contagio / Looking countries have the higthest infeccion rate compare to Population

SELECT location,
  population,
  MAX(total_cases) AS HighestInfectionCount,
  MAX((total_cases/population)*100) as Percentage_Population_Infected
FROM  coviddeaths
WHERE  continent IS NOT NULL
GROUP BY location,
		 population
ORDER BY Percentage_Population_Infected DESC;



-- Paises con el mayor cantidad de muertes por poblacion //  Showing coutries with the highest death count per Population

SELECT
  location,
  MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM  coviddeaths
WHERE  continent IS NOT NULL
  AND location NOT IN ('North America', 'European Union', 'South America')
GROUP BY location
ORDER BY TotalDeathCount DESC;


-- Continente con el mayor cantidad de muertes por poblacion //  Showing continent with the highest death count per Population

SELECT
  continent,
  MAX(CAST(total_deaths AS SIGNED)) AS TotalDeathCount
FROM  coviddeaths
WHERE  continent IS NOT NULL
 -- AND continent NOT IN ('North America', 'European Union', 'South America')
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Cantidad de contagiados acumulados diarios en el mundo
SELECT
      STR_TO_DATE(date, '%c/%d/%y') AS date,
      SUM(new_cases) AS global_cases,
      SUM(new_deaths) AS global_deaths,
      ROUND(SUM(new_deaths)/SUM(new_cases) * 100, 2 )AS gobal_rate
FROM coviddeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2 ;

-- Poblacion total vs vacunas / Total Population vs Vaccination

SELECT
  dea.continent,
  dea.location,
  STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
  dea.population,
  vac.new_vaccinations
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;

--- Recuento de vacunas acumuladas diarias por location/

SELECT
  dea.continent,
  dea.location,
  STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
  dea.population,
  vac.new_vaccinations,
  SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
FROM coviddeaths dea
JOIN covidvaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3;


-- using a cte to make further calculations over the last query

WITH PeovsVac (continent, location, date, population , new_vaccinations, rolling_people_vaccinated)
AS ( SELECT
      dea.continent,
      dea.location,
      STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
      dea.population,
      vac.new_vaccinations,
      SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    ORDER BY 2,3 )
SELECT * ,
       (rolling_people_vaccinated/population)*100 AS taza_vacc_population
FROM PeovsVac;



WITH PeovsVac -- (continent, location, date, population , new_vaccinations, rolling_people_vaccinated) #puedo usar algunas de las columnas de a
AS ( SELECT
      dea.continent,
      dea.location,
      STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
      dea.population,
      vac.new_vaccinations,
      SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as rolling_people_vaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
    ORDER BY 2,3 )
SELECT * ,
       (rolling_people_vaccinated/population)*100 AS taza_vacc_population
FROM PeovsVac;

-- TEMP TABLE

DROP TABLE IF EXISTS  _PercentPopulationVaccinated
CREATE TABLE _PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO _PercentPopulationVaccinated
SELECT dea.continent,
      dea.location,
      STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
      dea.population,
      vac.new_vaccinations,
      SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
   --  WHERE dea.continent IS NOT NULL

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM _PercentPopulationVaccinated


-- Create View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent,
      dea.location,
      STR_TO_DATE(dea.date, '%c/%d/%y') AS date,
      dea.population,
      vac.new_vaccinations,
      SUM(CAST(vac.new_vaccinations AS SIGNED)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
    FROM coviddeaths dea
    JOIN covidvaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL










