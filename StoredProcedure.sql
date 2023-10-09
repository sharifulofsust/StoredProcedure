--Creating the Database
CREATE OR REPLACE DATABASE SALES;
USE DATABASE SALES;

CREATE OR REPLACE TABLE SALES_SAMPLE_DATA (
ORDERNUMBER NUMBER (8, 0),
QUANTITYORDERED NUMBER (8,2),
PRICEEACH NUMBER (8,2),
ORDERLINENUMBER NUMBER (3, 0),
SALES NUMBER (8,2),
ORDERDATE VARCHAR (16),
STATUS VARCHAR (16),
QTR_ID NUMBER (1,0),
MONTH_ID NUMBER (2,0),
YEAR_ID NUMBER (4,0),
PRODUCTLINE VARCHAR (32),
MSRP NUMBER (8,0),
PRODUCTCODE VARCHAR (16),
CUSTOMERNAME VARCHAR (52),
PHONE VARCHAR (26),
ADDRESSLINE1 VARCHAR (64),
ADDRESSLINE2 VARCHAR (64),
CITY VARCHAR (16),
STATE VARCHAR (16),
POSTALCODE VARCHAR (16),
COUNTRY VARCHAR (24),
TERRITORY VARCHAR (24),
CONTACTLASTNAME VARCHAR (16),
CONTACTFIRSTNAME VARCHAR (16),
DEALSIZE VARCHAR (15)
);




select * from sales_sample_data limit 5;


SELECT COUNT(*) FROM SALES_SAMPLE_DATA; --2823 record

--TOP 3 REVENUE GENERATING PRODUCTS
SELECT 
    PRODUCTLINE AS "PRODUCT NAME", ROUND(SUM(SALES),0) AS SALES
FROM SALES_SAMPLE_DATA
    GROUP BY 1
ORDER BY SALES DESC
    LIMIT 3;



--TOP 3 SELLING PRODUCTS
SELECT 
    PRODUCTLINE AS "PRODUCT NAME", COUNT(*) AS NUMBER_OF_TIMES_SOLD
FROM SALES_SAMPLE_DATA
    GROUP BY 1
ORDER BY NUMBER_OF_TIMES_SOLD DESC
    LIMIT 3;


--STORE PROCEDURE IN SNOWFLAKE
--TOP 3 REVENUE GENERATING PRODUCTS



CREATE OR REPLACE PROCEDURE top_3_revenue_generating_product()
RETURNS TABLE()
LANGUAGE SQL
AS
DECLARE
  res RESULTSET DEFAULT (
  SELECT PRODUCTLINE AS "PRODUCT NAME", ROUND(SUM(SALES),0) AS SALES
FROM SALES_SAMPLE_DATA
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
  );
BEGIN
  RETURN TABLE(res);
END;



CALL top_3_revenue_generating_product() ;



--TOP 5 MOST SELLING PRODUCTS

create or replace procedure top_5_selling_product()
returns table()
language sql
as declare temporary_object resultset default(
SELECT 
    PRODUCTLINE AS "PRODUCT NAME", COUNT(*) AS NUMBER_OF_TIMES_SOLD
FROM SALES_SAMPLE_DATA
    GROUP BY 1
ORDER BY NUMBER_OF_TIMES_SOLD DESC
    LIMIT 5
);
begin 
return table(temporary_object);
end;

call top_5_selling_product();




-- lets practice more. now we will represent only those data with different  delivery status 



select distinct status from sales_sample_data;


CREATE OR REPLACE PROCEDURE sales_table_with_status_filter(status_category varchar)
RETURNS TABLE()
LANGUAGE SQL
AS
DECLARE
  temporary  RESULTSET DEFAULT (
  SELECT * FROM SALES_SAMPLE_DATA
WHERE STATUS = :status_category
  );
BEGIN
  RETURN TABLE(temporary);
END;

CALL sales_table_with_status_filter('Shipped'); -- here in the bracket we can use any value of status category



--now we will try to use stored procedure with arguments


select distinct status from sales_sample_data; /** here the status of the products are shipped,disputed, in process,cancelled and on hold. We want to find top sales for these different catsgories**/


CREATE OR REPLACE PROCEDURE get_top_3_sales_with_arg(status_category varchar)
RETURNS TABLE()
LANGUAGE SQL
AS
DECLARE
  temporary_object RESULTSET DEFAULT (
  SELECT PRODUCTLINE AS "PRODUCT NAME", ROUND(SUM(SALES),0) AS SALES
FROM SALES_SAMPLE_DATA
WHERE STATUS = :status_category
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3
  );
BEGIN
  RETURN TABLE(temporary_object);
END;

call get_top_3_sales_with_arg('Cancelled');   /** here in the bracket we put any value of the status category and we can find values with respect to that category and it works as like as a filter**/

call get_top_3_sales_with_arg('Shipped');


-- now we will try to delete those records where postal code is null
SELECT count(*) FROM SALES_SAMPLE_DATA WHERE POSTALCODE IS NULL; --76


SELECT * FROM SALES_SAMPLE_DATA WHERE POSTALCODE IS NULL;

CREATE OR REPLACE PROCEDURE PURGE_NULL_POSTALCODE()
RETURNS TABLE ()
LANGUAGE SQL
AS
DECLARE
  res RESULTSET DEFAULT (
  DELETE FROM SALES_SAMPLE_DATA WHERE POSTALCODE IS NULL
  );
BEGIN
  RETURN TABLE(res);
END;


CALL PURGE_NULL_POSTALCODE();

SELECT count(*) FROM SALES_SAMPLE_DATA WHERE POSTALCODE IS NULL;





--UDF
-- creating a simple orders table
create or replace table orders(
    order_id number,
    customer_id_fk number,
    item_id_fk number,
    retail_price number(10,2),
    purchase_price number(10,2),
    sold_quantity number(3),
    country_code varchar(2)
);


-- inserting handful records
insert into orders 
(order_id, customer_id_fk, item_id_fk,retail_price,purchase_price, sold_quantity,country_code)
values
(1,1,1,99.2,89.6,2,'US'),
(2,8,2,17.1,11,10,'IN'),
(3,5,1,827,900.99,5,'JP'),
(4,10,4,200,172,7,'DE');

-- lets check the records
select * from orders;


CREATE OR REPLACE FUNCTION 
calculate_profit(retail_price number, purchase_price number, sold_quantity number)
RETURNS NUMBER (10,2)
COMMENT = 'this is simple profit calculator'
as 
$$
 SELECT ((retail_price - purchase_price) * sold_quantity)
$$
;


select 
    item_id_fk,
    retail_price,
    purchase_price, 
    sold_quantity, 
    calculate_profit(retail_price,purchase_price, sold_quantity) as profit_udf 
from orders ;

-- here we have seen how to use user defined function. We can solve the problem in the following way too!


select 
    item_id_fk,
    retail_price,
    purchase_price, 
    sold_quantity,
    ((retail_price - purchase_price) * sold_quantity) as profit
from orders ;



-- create bit more complex udf
create or replace function country_name(country_code string)
returns string
as 
$$
 select country_code || '-' ||case
        when country_code='US' then 'USA'
        when country_code='IN' then 'India'
        when country_code='JP' then 'Japan'
        when country_code='DE' then 'Germany'
        else 'Unknown'
    end
$$;

select 
    item_id_fk,
    retail_price,
    purchase_price, 
    sold_quantity,
    calculate_profit(retail_price,purchase_price, sold_quantity) as profit_udf ,
    country_name(country_code) as country_udf
 from orders ;




-- now lets understand show and desc function features.
show functions;

-- filter by using object name
show functions like 'COUNTRY%';
show functions like'%PROFIT';

-- how to describe a function using desc function sql keywords
desc function country_name(string);




select * from sales_sample_data;