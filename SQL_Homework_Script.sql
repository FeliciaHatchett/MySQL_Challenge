use sakila;

select first_name, last_name from actor;

select concat_ws(" ", ucase(first_name), ucase(last_name)) as Actor_Name
from actor;

-- * 2a. You need to find the ID number, first name, and last name of an actor, of whom you know only the first name, "Joe." 
-- What is one query would you use to obtain this information?

select actor_id, first_name, last_name 
from actor
where first_name = "Joe";

-- * 2b. Find all actors whose last name contain the letters `GEN`:
select * from actor
where last_name like "%GEN%";

-- * 2c. Find all actors whose last names contain the letters `LI`. This time, order the rows by last name and first name, in that order:
select * from actor
where last_name like "%LI%"
order by last_name, first_name;

-- * 2d. Using `IN`, display the `country_id` and `country` columns of the following countries: Afghanistan, Bangladesh, and China:
select country_id, country 
from country
where country in ("Afghanistan", "Bangladesh", "China");

/* * 3a. You want to keep a description of each actor. 
You don't think you will be performing queries on a description, 
so create a column in the table `actor` named `description` 
and use the data type `BLOB` (Make sure to research the type `BLOB`, as the difference between it and `VARCHAR` are significant). */
alter table actor
add description BLOB;

select * from actor;

-- * 3b. Very quickly you realize that entering descriptions for each actor is too much effort. Delete the `description` column.
alter table actor
drop column description;

select * from actor;

-- * 4a. List the last names of actors, as well as how many actors have that last name.
select last_name, count(last_name) as last_name_count
from actor
group by last_name;

-- * 4b. List last names of actors and the number of actors who have that last name, but only for names that are shared by at least two actors
select last_name, count(last_name) as last_name_count
from actor
group by last_name
having last_name_count >= 2;

-- * 4c. The actor `HARPO WILLIAMS` was accidentally entered in the `actor` table as `GROUCHO WILLIAMS`. Write a query to fix the record.
SET SQL_SAFE_UPDATES = 0;

update actor
set first_name="HARPO"
where first_name="GROUCHO" and last_name="WILLIAMS";

select * from actor
where first_name="HARPO";

-- In a single query, if the first name of the actor is currently `HARPO`, change it to `GROUCHO`.
update actor
set first_name="GROUCHO"
where first_name="HARPO" and last_name="WILLIAMS";

SELECT * FROM actor
WHERE first_name="GROUCHO";

-- * 5a. You cannot locate the schema of the `address` table. Which query would you use to re-create it?
CREATE TABLE IF NOT EXISTS `address` (
  `address_id` smallint(5) unsigned NOT NULL AUTO_INCREMENT,
  `address` varchar(50) NOT NULL,
  `address2` varchar(50) DEFAULT NULL,
  `district` varchar(20) NOT NULL,
  `city_id` smallint(5) unsigned NOT NULL,
  `postal_code` varchar(10) DEFAULT NULL,
  `phone` varchar(20) NOT NULL,
  `location` geometry NOT NULL,
  `last_update` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`address_id`),
  KEY `idx_fk_city_id` (`city_id`),
  SPATIAL KEY `idx_location` (`location`),
  CONSTRAINT `fk_address_city` FOREIGN KEY (`city_id`) REFERENCES `city` (`city_id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=606 DEFAULT CHARSET=utf8;

-- * 6a. Use `JOIN` to display the first and last names, as well as the address, of each staff member. Use the tables `staff` and `address`:
SELECT staff.first_name, staff.last_name, address.address
FROM staff
JOIN address
ON staff.address_id=address.address_id;

-- * 6b. Use `JOIN` to display the total amount rung up by each staff member in August of 2005. Use tables `staff` and `payment`.
SELECT staff.last_name, sum(amount)
from payment
join staff
on staff.staff_id=payment.staff_id 
where payment_date like "2005-08-%"
group by last_name;

-- * 6c. List each film and the number of actors who are listed for that film. Use tables `film_actor` and `film`. Use inner join.
select film.title, count(actor_id) as actor_count
from film_actor
join film
on film.film_id=film_actor.film_id
group by title;

-- * 6d. How many copies of the film `Hunchback Impossible` exist in the inventory system?
select * from film;
select * from inventory;

select film.title, count(inventory_id) as inventory_count
from inventory
join film
on film.film_id=inventory.film_id
where title="Hunchback Impossible";

/** 6e. Using the tables `payment` and `customer` and the `JOIN` command, list the total paid by each customer. 
List the customers alphabetically by last name:*/
select customer.first_name, customer.last_name, sum(amount) as `Total Amount Paid`
from payment
join customer
on customer.customer_id=payment.customer_id
group by last_name
order by last_name;

-- Use subqueries to display the titles of movies starting with the letters `K` and `Q` whose language is English.
select title
from film
where (title like "K%" or 
title like "Q%") and
language_id in 
	(
    select language_id
    from language
    where name="English");
    
-- * 7b. Use subqueries to display all actors who appear in the film `Alone Trip`.
CREATE OR REPLACE VIEW alone_trip_actors as
select concat_ws(" ", first_name, last_name) as `Alone Trip Actors`
from actor
where actor_id in
	(
    select actor_id
    from film_actor
    where film_id in
		(
        select film_id 
        from film
        where title="Alone Trip"));
select * from alone_trip_actors;


/* 7c. You want to run an email marketing campaign in Canada, 
for which you will need the names and email addresses of all Canadian customers. Use joins to retrieve this information.*/
CREATE OR REPLACE VIEW canadian_customers as 
SELECT
customer.first_name, customer.last_name, customer.email
FROM customer
JOIN address ON customer.address_id = address.address_id
JOIN city ON city.city_id = address.city_id
JOIN country ON city.country_id=country.country_id
WHERE country.country = "Canada";

select * from canadian_customers;

/** 7d. Sales have been lagging among young families, and you wish to target all family movies for a promotion. 
Identify all movies categorized as family films.*/
CREATE OR REPLACE VIEW family_films as
SELECT film.title
FROM film

JOIN film_category ON film.film_id=film_category.film_id
JOIN category ON film_category.category_id=category.category_id

WHERE category.name="Family";

select * from family_films;

-- * 7e. Display the most frequently rented movies in descending order.
CREATE OR REPLACE VIEW frequent_rentals as
select film.title, count(rental.inventory_id) as 'Most Frequently Rented Copies'
from film
join inventory on film.film_id=inventory.film_id
join rental on rental.inventory_id=inventory.inventory_id

group by title
order by count(rental.inventory_id) desc;

select * from frequent_rentals;

-- * 7f. Write a query to display how much business, in dollars, each store brought in.
CREATE OR REPLACE VIEW store_revenue as 
select store.store_id, sum(payment.amount) as 'Amount Earned (USD)'
from store
join staff on store.store_id=staff.store_id
join payment on payment.staff_id=staff.staff_id
group by store_id;

select * from store_revenue;

-- * 7g. Write a query to display for each store its store ID, city, and country.
CREATE OR REPLACE VIEW store_locations as
select store.store_id as Store, city.city as City, country.country as Country
from store
join address on store.address_id=address.address_id
join city on city.city_id=address.city_id
join country on country.country_id=city.country_id
group by store_id;

select * from store_locations;

/* 7h. List the top five genres in gross revenue in descending order. 
8a. Use the solution from the problem above to create a view.
8b. How would you display the view that you created in 8a? */
Create or replace view top_five_genres as 
select category.name as Genre, sum(payment.amount) as 'Gross Revenue'
from category
join film_category on category.category_id=film_category.category_id
join inventory on film_category.film_id=inventory.film_id
join rental on inventory.inventory_id=rental.inventory_id
join payment on rental.rental_id=payment.rental_id

group by name
order by sum(payment.amount) desc
limit 5;

select * from top_five_genres;

DROP VIEW top_five_genres;








