USE ecommerce;
GO

IF SCHEMA_ID('Gold') IS NULL
    EXEC('CREATE SCHEMA Gold');
GO

DROP TABLE IF EXISTS Gold.FactOrders;
DROP TABLE IF EXISTS Gold.DimDate;
DROP TABLE IF EXISTS Gold.DimCustomers;
DROP TABLE IF EXISTS Gold.DimProducts;
DROP TABLE IF EXISTS Gold.DimSalesman;
GO

----Date
CREATE TABLE Gold.DimDate (
    date_key           INT PRIMARY KEY,
    full_date          DATE UNIQUE,
    calendar_year      INT,
    quarter_number     INT,
    quarter_name       VARCHAR(5),
    year_quarter       VARCHAR(10),
    month_number       INT,
    month_name         VARCHAR(15),
    month_short_name   VARCHAR(5),
    year_month         VARCHAR(10),
    year_month_number  INT,
    week_of_year       INT,
    day_of_month       INT,
    day_of_week_number INT,
    day_name           VARCHAR(15),
    is_weekend         BIT
);

----Customers

CREATE TABLE Gold.DimCustomers (
    customer_id          INT PRIMARY KEY,
    customer_name        VARCHAR(210),
    first_name           VARCHAR(100),
    last_name            VARCHAR(100),
    segment              VARCHAR(30),
    city                 VARCHAR(100),
    state                VARCHAR(20),
    country              VARCHAR(50),
    zip_code             VARCHAR(10),
    latitude             DECIMAL(11,8),
    longitude            DECIMAL(11,8),
    age_at_data_cutoff   INT,
    age_group            VARCHAR(15),
    age_group_sort       INT,
    is_minor             BIT
);

----Products
CREATE TABLE Gold.DimProducts (
    product_card_id     INT PRIMARY KEY,
    product_name        VARCHAR(200),
    product_price       DECIMAL(10,2),
    category_id         INT,
    category_name       VARCHAR(100),
    department_id       INT,
    department_name     VARCHAR(100),
    department_category VARCHAR(220)
);


----Salesman
CREATE TABLE Gold.DimSalesman (
    salesman_id       INT PRIMARY KEY,
    salesman_name     VARCHAR(210),
    salesman_display  VARCHAR(230),
    first_name        VARCHAR(100),
    last_name         VARCHAR(100),
    email             VARCHAR(200),
    market            VARCHAR(30),
    region            VARCHAR(60),
    hire_date         DATE,
    hire_date_quality VARCHAR(40),
    commission_rate   DECIMAL(5,3)
);


----Fact Table
CREATE TABLE Gold.FactOrders (
    order_item_id           INT PRIMARY KEY,
    order_id                INT,
    customer_id             INT FOREIGN KEY REFERENCES Gold.DimCustomers(customer_id),
    product_card_id         INT FOREIGN KEY REFERENCES Gold.DimProducts(product_card_id),
    salesman_id             INT FOREIGN KEY REFERENCES Gold.DimSalesman(salesman_id),
    order_date_key          INT FOREIGN KEY REFERENCES Gold.DimDate(date_key),
    shipping_date_key       INT FOREIGN KEY REFERENCES Gold.DimDate(date_key),
    order_datetime          DATETIME,
    shipping_datetime       DATETIME,
    payment_type            VARCHAR(30),
    order_status            VARCHAR(30),
    order_status_group      VARCHAR(30),
    shipping_mode           VARCHAR(30),
    delivery_performance    VARCHAR(30),
    is_shipping_canceled    BIT,
    is_late_delivery        BIT,
    market                  VARCHAR(30),
    order_region            VARCHAR(60),
    order_state             VARCHAR(100),
    quantity                INT,
    unit_price              DECIMAL(10,2),
    gross_sales             DECIMAL(12,2),
    discount_amount         DECIMAL(12,2),
    net_sales               DECIMAL(12,2),
    profit_amount           DECIMAL(12,2),
    profit_ratio            DECIMAL(7,4),
    days_shipping_real      INT,
    days_shipping_scheduled INT,
    shipping_delay_days     INT
);

CREATE INDEX IX_FactOrders_order_date ON Gold.FactOrders(order_date_key);
CREATE INDEX IX_FactOrders_ship_date ON Gold.FactOrders(shipping_date_key);
CREATE INDEX IX_FactOrders_customer ON Gold.FactOrders(customer_id);
CREATE INDEX IX_FactOrders_product ON Gold.FactOrders(product_card_id);
CREATE INDEX IX_FactOrders_salesman ON Gold.FactOrders(salesman_id);
CREATE INDEX IX_FactOrders_order_id ON Gold.FactOrders(order_id);
GO

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Gold';
GO
-------------------------------------------------------------------------------------------------------------
USE ecommerce;
GO

DELETE FROM Gold.FactOrders;
DELETE FROM Gold.DimDate;
DELETE FROM Gold.DimCustomers;
DELETE FROM Gold.DimProducts;
DELETE FROM Gold.DimSalesman;
GO

DECLARE @dt DATE = '2015-01-01';
DECLARE @end_dt DATE = '2018-12-31';

WHILE @dt <= @end_dt
BEGIN
    INSERT INTO Gold.DimDate (
        date_key, full_date, calendar_year, quarter_number, quarter_name,
        year_quarter, month_number, month_name, month_short_name,
        year_month, year_month_number, week_of_year, day_of_month,
        day_of_week_number, day_name, is_weekend
    )
    VALUES (
        YEAR(@dt) * 10000 + MONTH(@dt) * 100 + DAY(@dt),
        @dt,
        YEAR(@dt),
        DATEPART(QUARTER, @dt),
        'Q' + CAST(DATEPART(QUARTER, @dt) AS VARCHAR(2)),
        CAST(YEAR(@dt) AS VARCHAR(4)) + '-Q' + CAST(DATEPART(QUARTER, @dt) AS VARCHAR(2)),
        MONTH(@dt),
        DATENAME(MONTH, @dt),
        LEFT(DATENAME(MONTH, @dt), 3),
        CAST(YEAR(@dt) AS VARCHAR(4)) + '-' + RIGHT('0' + CAST(MONTH(@dt) AS VARCHAR(2)), 2),
        YEAR(@dt) * 100 + MONTH(@dt),
        DATEPART(ISO_WEEK, @dt),
        DAY(@dt),
        (DATEDIFF(DAY, '1900-01-01', @dt) % 7) + 1,
        DATENAME(WEEKDAY, @dt),
        CASE WHEN (DATEDIFF(DAY, '1900-01-01', @dt) % 7) + 1 IN (6, 7) THEN 1 ELSE 0 END
    );

    SET @dt = DATEADD(DAY, 1, @dt);
END;
GO

INSERT INTO Gold.DimCustomers (
    customer_id, customer_name, first_name, last_name, segment,
    city, state, country, zip_code, latitude, longitude,
    age_at_data_cutoff, age_group, age_group_sort, is_minor
)
SELECT customer_id,
       LTRIM(RTRIM(ISNULL(first_name, '') + ' ' + ISNULL(last_name, ''))),
       first_name, last_name, segment,
       city, state, country, zip_code, latitude, longitude,
       DATEDIFF(YEAR, birth_date, '2018-01-31'),
       NULL, NULL, ISNULL(is_minor, 0)
FROM Silver.customers;

UPDATE Gold.DimCustomers SET age_at_data_cutoff = NULL WHERE age_at_data_cutoff < 0;
UPDATE Gold.DimCustomers SET age_group = 'Under 18', age_group_sort = 1 WHERE age_at_data_cutoff < 18;
UPDATE Gold.DimCustomers SET age_group = '18-24', age_group_sort = 2 WHERE age_at_data_cutoff BETWEEN 18 AND 24;
UPDATE Gold.DimCustomers SET age_group = '25-34', age_group_sort = 3 WHERE age_at_data_cutoff BETWEEN 25 AND 34;
UPDATE Gold.DimCustomers SET age_group = '35-44', age_group_sort = 4 WHERE age_at_data_cutoff BETWEEN 35 AND 44;
UPDATE Gold.DimCustomers SET age_group = '45-54', age_group_sort = 5 WHERE age_at_data_cutoff BETWEEN 45 AND 54;
UPDATE Gold.DimCustomers SET age_group = '55-64', age_group_sort = 6 WHERE age_at_data_cutoff BETWEEN 55 AND 64;
UPDATE Gold.DimCustomers SET age_group = '65+', age_group_sort = 7 WHERE age_at_data_cutoff >= 65;
GO

INSERT INTO Gold.DimProducts (
    product_card_id, product_name, product_price, category_id,
    category_name, department_id, department_name, department_category
)
SELECT product_card_id, product_name, product_price, category_id,
       category_name, department_id, department_name,
       ISNULL(department_name, '') + ' > ' + ISNULL(category_name, '')
FROM Silver.products;
GO

INSERT INTO Gold.DimSalesman (
    salesman_id, salesman_name, salesman_display, first_name, last_name,
    email, market, region, hire_date, hire_date_quality, commission_rate
)
SELECT salesman_id,
       LTRIM(RTRIM(ISNULL(first_name, '') + ' ' + ISNULL(last_name, ''))),
       LTRIM(RTRIM(ISNULL(first_name, '') + ' ' + ISNULL(last_name, ''))) + ' (#' + CAST(salesman_id AS VARCHAR(10)) + ')',
       first_name, last_name, email, market, region, hire_date, 'OK', commission_rate
FROM Silver.salesman;

UPDATE Gold.DimSalesman SET hire_date_quality = 'Unknown' WHERE hire_date IS NULL;
---UPDATE Gold.DimSalesman SET hire_date_quality = 'Suspect - hired after first order' WHERE is_hire_date_suspect = 1;
GO

INSERT INTO Gold.FactOrders (
    order_item_id, order_id, customer_id, product_card_id, salesman_id,
    order_date_key, shipping_date_key, order_datetime, shipping_datetime,
    payment_type, order_status, order_status_group, shipping_mode,
    delivery_performance, is_shipping_canceled, is_late_delivery,
    market, order_region, order_state, quantity, unit_price,
    gross_sales, discount_amount, net_sales, profit_amount, profit_ratio,
    days_shipping_real, days_shipping_scheduled, shipping_delay_days
)
SELECT o.order_item_id, o.order_id, o.customer_id, o.product_card_id, o.salesman_id,
       YEAR(o.order_datetime) * 10000 + MONTH(o.order_datetime) * 100 + DAY(o.order_datetime),
       YEAR(o.shipping_datetime) * 10000 + MONTH(o.shipping_datetime) * 100 + DAY(o.shipping_datetime),
       o.order_datetime, o.shipping_datetime,
       o.payment_type, o.order_status, o.order_status_group, o.shipping_mode,
       o.delivery_performance, o.is_shipping_canceled,
       CASE WHEN o.delivery_performance = 'Late delivery' THEN 1 ELSE 0 END,
       o.market, o.order_region, o.order_state,
       o.quantity, p.product_price,
       o.item_total + o.discount_amount, o.discount_amount, o.item_total,
       o.profit_amount, o.profit_ratio,
       o.days_shipping_real, o.days_shipping_scheduled,
       o.days_shipping_real - o.days_shipping_scheduled
FROM Silver.orders o
JOIN Silver.products p ON p.product_card_id = o.product_card_id;

UPDATE Gold.FactOrders SET shipping_delay_days = NULL WHERE is_shipping_canceled = 1;
GO

SELECT COUNT(*) AS dim_date FROM Gold.DimDate;
SELECT COUNT(*) AS dim_customers FROM Gold.DimCustomers;
SELECT COUNT(*) AS dim_products FROM Gold.DimProducts;
SELECT COUNT(*) AS dim_salesman FROM Gold.DimSalesman;
SELECT COUNT(*) AS fact_orders FROM Gold.FactOrders;
GO
-------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS silver_customers, (SELECT COUNT(*) FROM Gold.DimCustomers) AS gold_customers;
SELECT COUNT(*) AS silver_products,  (SELECT COUNT(*) FROM Gold.DimProducts)  AS gold_products;
SELECT COUNT(*) AS silver_salesman,  (SELECT COUNT(*) FROM Gold.DimSalesman)  AS gold_salesman;
SELECT COUNT(*) AS silver_orders,    (SELECT COUNT(*) FROM Gold.FactOrders)   AS gold_orders;
GO

SELECT COUNT(*) AS missing_customers
FROM Gold.FactOrders f
LEFT JOIN Gold.DimCustomers c ON f.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_products
FROM Gold.FactOrders f
LEFT JOIN Gold.DimProducts p ON f.product_card_id = p.product_card_id
WHERE p.product_card_id IS NULL;

SELECT COUNT(*) AS missing_salesman
FROM Gold.FactOrders f
LEFT JOIN Gold.DimSalesman s ON f.salesman_id = s.salesman_id
WHERE s.salesman_id IS NULL;

SELECT COUNT(*) AS missing_order_dates
FROM Gold.FactOrders f
LEFT JOIN Gold.DimDate d ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL;

SELECT COUNT(*) AS missing_ship_dates
FROM Gold.FactOrders f
LEFT JOIN Gold.DimDate d ON f.shipping_date_key = d.date_key
WHERE d.date_key IS NULL;
GO

SELECT SUM(item_total) AS silver_sales, (SELECT SUM(net_sales) FROM Gold.FactOrders) AS gold_sales FROM Silver.orders;
SELECT SUM(profit_amount) AS silver_profit, (SELECT SUM(profit_amount) FROM Gold.FactOrders) AS gold_profit FROM Silver.orders;
SELECT SUM(quantity) AS silver_qty, (SELECT SUM(quantity) FROM Gold.FactOrders) AS gold_qty FROM Silver.orders;
GO

----kpis
SELECT COUNT(*) AS total_items,
       COUNT(DISTINCT order_id) AS total_orders,
       SUM(net_sales) AS total_net_sales,
       SUM(gross_sales) AS total_gross_sales,
       SUM(profit_amount) AS total_profit
FROM Gold.FactOrders;

SELECT YEAR(order_datetime) AS order_year,
       COUNT(*) AS items_count,
       SUM(net_sales) AS year_sales,
       SUM(profit_amount) AS year_profit
FROM Gold.FactOrders
GROUP BY YEAR(order_datetime)
ORDER BY order_year;
GO


USE ecommerce;
SELECT COUNT(*) FROM Gold.FactOrders;


USE ecommerce;

SELECT 
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type
FROM sys.objects o
JOIN sys.schemas s ON o.schema_id = s.schema_id
WHERE o.type IN ('U', 'V', 'P')
ORDER BY s.name, o.type_desc, o.name




SELECT DISTINCT o.salesman_id, COUNT(*) AS rows_count
FROM Silver.orders o
LEFT JOIN Gold.DimSalesman s ON o.salesman_id = s.salesman_id
WHERE s.salesman_id IS NULL
GROUP BY o.salesman_id;


INSERT INTO Gold.DimSalesman (salesman_id)
SELECT DISTINCT o.salesman_id
FROM Silver.orders o
LEFT JOIN Gold.DimSalesman s ON o.salesman_id = s.salesman_id
WHERE o.salesman_id IS NOT NULL
  AND s.salesman_id IS NULL;

SELECT COUNT(*) FROM Gold.FactOrders;


SELECT COLUMN_NAME 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_SCHEMA = 'Gold' AND TABLE_NAME = 'DimSalesman';