CREATE TABLE netflix_content (
    show_id VARCHAR(10) PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    title VARCHAR(255) NOT NULL,
    cast_in TEXT,
    country VARCHAR(100),
    release_year INT,
    rating VARCHAR(10),
    duration VARCHAR(50),
    listed_in TEXT,
    date_added DATE
);

---Анализ данных с сайта Netflix

--- 1. Проверка данных
--- Проверка на нулевые значения
SELECT 
    COUNT(*) AS total_rows,
    COUNT (show_id) AS show_id_not_null,
    COUNT(type) AS type_not_null,
    COUNT(title) AS title_not_null,
    COUNT(cast_in) AS cast_in_not_null,
    COUNT(country) AS country_not_null,
    COUNT(release_year) AS release_year_not_null,
    COUNT(rating) AS rating_not_null,
    COUNT(duration) AS duration_not_null,
    COUNT(listed_in) AS listed_in_not_null,
    COUNT(date_added) AS date_added_not_null
FROM netflix_content;

--- Проверка на количество уникальных id и названий фильмов
SELECT
COUNT(DISTINCT show_id) AS uniq_id,
COUNT(DISTINCT title) AS uniq_title
FROM netflix_content;


---Найдено 2 недостающих значения в столбце данных "Страна", находим id записей
SELECT *
FROM netflix_content
WHERE country IS NULL;

---Добавлена страна производства для фильма Eyes of Thief (2014) и D.P (2021)
UPDATE netflix_content
SET country = 'Palestine'
WHERE show_id = 366::varchar;

UPDATE netflix_content
SET country = 'South Korea'
WHERE show_id = 194::varchar;

---Проверка на регистры
SELECT type, COUNT(*)
FROM netflix_content
WHERE type = 'Movie' OR type = 'TV Show'
GROUP BY type;


--- 2.Анализ данных
--- Динамика по годам
SELECT release_year, 
	count(release_year) AS count_release,
	SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS count_movie,
	SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS count_tv
FROM netflix_content
GROUP BY release_year
ORDER BY release_year;

--- Анализ по странам (топ-10 стран)
SELECT country,
	count (country) AS count_country,
	ROUND((count(country)::NUMERIC / (SELECT count(*) FROM netflix_content)::NUMERIC) *100,1) as percent_country
FROM netflix_content
GROUP BY  country
ORDER BY count_country DESC
LIMIT 10;

--- Анализ по возрастному рейтингу
SELECT rating, count(rating) AS count_rating,
	SUM(CASE WHEN type = 'Movie' THEN 1 ELSE 0 END) AS count_movie,
	SUM(CASE WHEN type = 'TV Show' THEN 1 ELSE 0 END) AS count_tv
FROM netflix_content
GROUP BY rating
ORDER BY count_rating DESC;

--- Анализ по жанрам
SELECT 
TRIM(UNNEST(STRING_TO_ARRAY(listed_in,','))) AS genre,
COUNT(*) as count_genre
FROM netflix_content
GROUP BY genre
ORDER BY count_genre DESC
LIMIT 15;

--- Средняя длительность фильмов и сериалов по годам
SELECT release_year,
ROUND(AVG(CASE WHEN type = 'Movie' THEN  REPLACE(duration, ' min', '')::NUMERIC ELSE NULL END),1) AS avg_movie,
ROUND(AVG(CASE WHEN type = 'TV Show' THEN  REPLACE(REPLACE(duration, ' Seasons', ''),' Season', '')::NUMERIC  ELSE NULL END),1) AS avg_tv
FROM netflix_content
GROUP BY release_year
ORDER BY release_year;

--- Количество сериалов без продолжения
SELECT release_year,
	COUNT(*) AS count_all_tv_show,
	COUNT(CASE WHEN duration like '1 Season' THEN 1 END) AS count_1_season,
	ROUND(COUNT(CASE WHEN duration LIKE '1 Season' THEN 1 END)::NUMERIC / COUNT(*) * 100, 1) AS percent
FROM netflix_content
WHERE type ='TV Show'
GROUP BY release_year
ORDER BY release_year;


--- Дополнительный анализ базы данных
--- 1.Эволюция контентной стратегии Netflix во времени
select extract (year from date_added) as year_date_added,
	round(avg(extract (year from date_added) - release_year), 0) as avg_diff
from netflix_content
group by extract (year from date_added)
order by extract (year from date_added)

-- Аналогичный расчет среднего разрыва между годом выпуска и годом добавления отдельно для Movie, отдельно для TV Show.
select extract (year from date_added) as year_date_added,
	round(avg(extract(year from date_added) - release_year) filter (where type = 'Movie')) as avg_diff_movie,
	round(avg(extract(year from date_added) - release_year) filter (where type = 'TV Show')) as avg_diff_tw_show
from netflix_content
group by extract (year from date_added)
order by year_date_added

-- Посчитаю долю контента со "взрослым" рейтингом от общего числа тайтлов каждого года выпуска.
select release_year,
	count(show_id) as total_count,
	round(
		count(show_id) filter (where rating = 'TV-MA' or rating = 'R' or rating = 'NC-17')::numeric / count(show_id) * 100, 1) as percent_old
from netflix_content
group by release_year
order by release_year

-- На всякий случай проведу проверку: найду все записи, где год добавления меньше, чем год выпуска. 
-- Найдено 14 записей, 12 - сериалы, 2 - фильмы.
select title, type, release_year, date_added
from netflix_content
where extract(year from date_added) < release_year
