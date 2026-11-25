USE ecommerce;
GO

DROP TABLE IF EXISTS Silver.orders;
DROP TABLE IF EXISTS Silver.customers;
DROP TABLE IF EXISTS Silver.products;
DROP TABLE IF EXISTS Silver.salesman;
GO

CREATE OR ALTER FUNCTION Silver.fn_CleanText (@txt VARCHAR(500))
RETURNS VARCHAR(500)
AS
BEGIN
    DECLARE @res VARCHAR(500) = LTRIM(RTRIM(@txt));
    WHILE CHARINDEX('  ', @res) > 0
        SET @res = REPLACE(@res, '  ', ' ');
    RETURN NULLIF(@res, '');
END;
GO

CREATE TABLE Silver.customers (
    customer_id   INT PRIMARY KEY,
    first_name    VARCHAR(100),
    last_name     VARCHAR(100),
    segment       VARCHAR(30),
    city          VARCHAR(100),
    state         VARCHAR(20),
    street        VARCHAR(200),
    zip_code      VARCHAR(10),
    country       VARCHAR(50),
    latitude      DECIMAL(11,8),
    longitude     DECIMAL(11,8),
    birth_date    DATE,
    is_minor      BIT DEFAULT 0
);

CREATE TABLE Silver.products (
    product_card_id INT PRIMARY KEY,
    product_name    VARCHAR(200),
    product_price   DECIMAL(10,2),
    category_id     INT,
    category_name   VARCHAR(100),
    department_id   INT,
    department_name VARCHAR(100)
);

CREATE TABLE Silver.salesman (
    salesman_id          INT PRIMARY KEY,
    first_name           VARCHAR(100),
    last_name            VARCHAR(100),
    email                VARCHAR(200),
    market               VARCHAR(30),
    region               VARCHAR(60),
    hire_date            DATE,
    commission_rate      DECIMAL(5,3),
    is_hire_date_suspect BIT DEFAULT 0
);

CREATE TABLE Silver.orders (
    order_item_id           INT PRIMARY KEY,
    order_id                INT,
    customer_id             INT FOREIGN KEY REFERENCES Silver.customers(customer_id),
    product_card_id         INT FOREIGN KEY REFERENCES Silver.products(product_card_id),
    salesman_id             INT FOREIGN KEY REFERENCES Silver.salesman(salesman_id),
    payment_type            VARCHAR(30),
    order_status            VARCHAR(30),
    order_status_group      VARCHAR(30),
    shipping_mode           VARCHAR(30),
    delivery_status         VARCHAR(30),
    delivery_performance    VARCHAR(30),
    is_shipping_canceled    BIT,
    late_delivery_risk      BIT,
    market                  VARCHAR(30),
    order_region            VARCHAR(60),
    order_state             VARCHAR(100),
    order_zipcode           VARCHAR(10),
    order_datetime          DATETIME,
    shipping_datetime       DATETIME,
    days_shipping_real      INT,
    days_shipping_scheduled INT,
    quantity                INT,
    discount_amount         DECIMAL(10,2),
    item_total              DECIMAL(10,2),
    profit_amount           DECIMAL(10,2),
    profit_ratio            DECIMAL(7,4)
);
GO

SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'Silver';
GO

-------------------------------------------------------------------------------------------------------------
DELETE FROM Silver.orders;
DELETE FROM Silver.customers;
DELETE FROM Silver.products;
DELETE FROM Silver.salesman;

INSERT INTO Silver.customers (customer_id, first_name, last_name, segment, city, state, street, zip_code, country, latitude, longitude, birth_date)
SELECT Customer_Id, LTRIM(RTRIM(Customer_Fname)), LTRIM(RTRIM(Customer_Lname)), LTRIM(RTRIM(Customer_Segment)),
       LTRIM(RTRIM(Customer_City)), UPPER(LTRIM(RTRIM(Customer_State))), LTRIM(RTRIM(Customer_Street)),
       REPLACE(Customer_Zipcode, '.0', ''), LTRIM(RTRIM(Customer_Country)), Latitude, Longitude, Customer_Birth_Date
FROM Bronze.Customers;

UPDATE Silver.customers SET is_minor = 1 WHERE birth_date > '2000-01-31';

INSERT INTO Silver.products (product_card_id, product_name, product_price, category_id, category_name, department_id, department_name)
SELECT Product_Card_Id, LTRIM(RTRIM(Product_Name)), ROUND(Product_Price, 2),
       Category_Id, LTRIM(RTRIM(Category_Name)), Department_Id, LTRIM(RTRIM(Department_Name))
FROM Bronze.Products;

INSERT INTO Silver.salesman (salesman_id, first_name, last_name, email, market, region, hire_date, commission_rate)
SELECT Salesman_Id, LTRIM(RTRIM(Salesman_Fname)), LTRIM(RTRIM(Salesman_Lname)), LOWER(LTRIM(RTRIM(Salesman_Email))),
       LTRIM(RTRIM(Market)), LTRIM(RTRIM(Region)), Hire_Date, Commission_Rate
FROM Bronze.Salesman;

UPDATE Silver.salesman SET market = 'Europe' WHERE market = 'EU';
UPDATE Silver.salesman SET market = 'Pacific Asia' WHERE market IN ('APAC', 'Asia-Pacific');
UPDATE Silver.salesman SET market = 'LATAM' WHERE market = 'Latin America';
UPDATE Silver.salesman SET market = 'USCA' WHERE market IN ('U.S.-Canada', 'US and Canada', 'US & Canada');
UPDATE Silver.salesman SET market = 'Africa' WHERE market = 'AFR';

SELECT COUNT(*) FROM Silver.customers;
SELECT COUNT(*) FROM Silver.products;
SELECT COUNT(*) FROM Silver.salesman;

-------------------------------------------------------------------------------------------------------------

DELETE FROM Silver.orders;

INSERT INTO Silver.orders (
    order_item_id, order_id, customer_id, product_card_id, salesman_id,
    payment_type, order_status, shipping_mode, delivery_status,
    late_delivery_risk, market, order_region, order_state, order_zipcode,
    order_datetime, shipping_datetime, days_shipping_real, days_shipping_scheduled,
    quantity, discount_amount, item_total, profit_amount, profit_ratio
)
SELECT Order_Item_Id, Order_Id, Customer_Id, Product_Card_Id, salesman_id,
       LTRIM(RTRIM(Type)), LTRIM(RTRIM(Order_Status)), LTRIM(RTRIM(Shipping_Mode)), LTRIM(RTRIM(Delivery_Status)),
       Late_delivery_risk, LTRIM(RTRIM(Market)), LTRIM(RTRIM(Order_Region)), LTRIM(RTRIM(Order_State)), Order_Zipcode,
       order_date_DateOrders, shipping_date_DateOrders, Days_for_shipping_real, Days_for_shipment_scheduled,
       Order_Item_Quantity, ROUND(Order_Item_Discount, 2), ROUND(Order_Item_Total, 2),
       ROUND(Benefit_per_order, 2), ROUND(Order_Item_Profit_Ratio, 4)
FROM Bronze.Orders;

UPDATE Silver.orders SET market = 'Europe' WHERE market IN ('EU', 'Europe');
UPDATE Silver.orders SET market = 'Pacific Asia' WHERE market IN ('APAC', 'Asia-Pacific', 'Pacific Asia');
UPDATE Silver.orders SET market = 'LATAM' WHERE market = 'Latin America';
UPDATE Silver.orders SET market = 'USCA' WHERE market IN ('U.S.-Canada', 'US and Canada', 'US & Canada');
UPDATE Silver.orders SET market = 'Africa' WHERE market = 'AFR';

UPDATE Silver.orders SET shipping_mode = 'Standard Class' WHERE shipping_mode IN ('STANDARD CLASS', 'STANDARD', 'STD CLASS');
UPDATE Silver.orders SET shipping_mode = 'Second Class' WHERE shipping_mode IN ('SECOND CLASS', '2ND CLASS');
UPDATE Silver.orders SET shipping_mode = 'First Class' WHERE shipping_mode IN ('FIRST CLASS', '1ST CLASS');
UPDATE Silver.orders SET shipping_mode = 'Same Day' WHERE shipping_mode IN ('SAME DAY', 'SAME-DAY');

UPDATE Silver.orders SET is_shipping_canceled = 1, delivery_performance = 'Not applicable' WHERE delivery_status = 'Shipping canceled';
UPDATE Silver.orders SET is_shipping_canceled = 0, delivery_performance = delivery_status WHERE delivery_status <> 'Shipping canceled';

SELECT COUNT(*) FROM Silver.orders;
-------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS bronze_customers FROM Bronze.Customers;
SELECT COUNT(*) AS silver_customers FROM Silver.customers;

SELECT COUNT(*) AS bronze_products FROM Bronze.Products;
SELECT COUNT(*) AS silver_products FROM Silver.products;

SELECT COUNT(*) AS bronze_salesman FROM Bronze.Salesman;
SELECT COUNT(*) AS silver_salesman FROM Silver.salesman;

SELECT COUNT(*) AS bronze_orders FROM Bronze.Orders;
SELECT COUNT(*) AS silver_orders FROM Silver.orders;

SELECT COUNT(*) AS missing_cust FROM Silver.orders o
LEFT JOIN Silver.customers c ON o.customer_id = c.customer_id
WHERE c.customer_id IS NULL;

SELECT COUNT(*) AS missing_prod FROM Silver.orders o
LEFT JOIN Silver.products p ON o.product_card_id = p.product_card_id
WHERE p.product_card_id IS NULL;

SELECT COUNT(*) AS missing_sales FROM Silver.orders o
LEFT JOIN Silver.salesman s ON o.salesman_id = s.salesman_id
WHERE s.salesman_id IS NULL;

SELECT COUNT(DISTINCT market) AS markets FROM Silver.orders;
SELECT COUNT(DISTINCT shipping_mode) AS shipping_modes FROM Silver.orders;
SELECT COUNT(DISTINCT delivery_status) AS delivery_statuses FROM Silver.orders;
SELECT COUNT(DISTINCT order_status) AS order_statuses FROM Silver.orders;
SELECT COUNT(DISTINCT order_region) AS regions FROM Silver.orders;

SELECT COUNT(*) AS bad_dates FROM Silver.orders WHERE shipping_datetime < order_datetime;
SELECT MIN(order_datetime) AS min_order, MAX(order_datetime) AS max_order FROM Silver.orders;