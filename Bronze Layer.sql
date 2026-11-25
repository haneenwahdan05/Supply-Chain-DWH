USE ecommerce;
GO

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    p.rows AS row_count
FROM sys.tables t
JOIN sys.schemas s ON t.schema_id = s.schema_id
JOIN sys.partitions p ON t.object_id = p.object_id AND p.index_id IN (0, 1)
WHERE s.name = N'Bronze'
ORDER BY t.name;
GO
-------------------------------------------------------------------------------------------------------------
USE ecommerce;
GO

EXEC sp_rename 'dbo.[Customers (4)]', 'Customers';
GO

ALTER SCHEMA Bronze TRANSFER dbo.Customers;
ALTER SCHEMA Bronze TRANSFER dbo.Orders;
ALTER SCHEMA Bronze TRANSFER dbo.Products;
GO


Use ecommerce;
Go

Alter schema Bronze Transfer dbo.Salesman;
GO
-------------------------------------------------------------------------------------------------------------
USE ecommerce;
GO

SELECT 'Customers' AS table_name, COUNT(*) AS row_count FROM Bronze.Customers
UNION ALL
SELECT 'Products', COUNT(*) FROM Bronze.Products
UNION ALL
SELECT 'Orders', COUNT(*) FROM Bronze.Orders
UNION ALL
SELECT 'Salesman', COUNT(*) FROM Bronze.Salesman;
GO


SELECT COUNT(*) AS null_customers FROM Bronze.Customers WHERE Customer_Id IS NULL;
SELECT COUNT(*) AS null_products  FROM Bronze.Products  WHERE Product_Card_Id IS NULL;
SELECT COUNT(*) AS null_orders    FROM Bronze.Orders    WHERE Order_Id IS NULL;
SELECT COUNT(*) AS null_salesman  FROM Bronze.Salesman  WHERE Salesman_Id IS NULL;
GO

SELECT COUNT(*) AS market_quotes   FROM Bronze.Orders    WHERE Market LIKE '"%';
SELECT COUNT(*) AS street_quotes   FROM Bronze.Customers WHERE Customer_Street LIKE '"%';
SELECT COUNT(*) AS state_encoding  FROM Bronze.Orders    WHERE Order_State LIKE '%?%';
GO
-------------------------------------------------------------------------------------------------------------

SELECT COUNT(*) AS null_customers FROM Bronze.Customers WHERE Customer_Id IS NULL;
SELECT COUNT(*) AS blank_lname FROM Bronze.Customers WHERE Customer_Lname IS NULL OR Customer_Lname = '';
SELECT COUNT(*) AS blank_zipcode FROM Bronze.Customers WHERE Customer_Zipcode IS NULL OR Customer_Zipcode = '';

SELECT COUNT(*) AS null_products FROM Bronze.Products WHERE Product_Card_Id IS NULL;
SELECT COUNT(*) AS blank_desc FROM Bronze.Products WHERE Product_Description IS NULL OR Product_Description = '';

SELECT COUNT(*) AS null_salesman FROM Bronze.Salesman WHERE Salesman_Id IS NULL;

SELECT COUNT(*) AS null_order_items FROM Bronze.Orders WHERE Order_Item_Id IS NULL;
SELECT COUNT(*) AS null_orders FROM Bronze.Orders WHERE Order_Id IS NULL;
SELECT COUNT(*) AS blank_order_zip FROM Bronze.Orders WHERE Order_Zipcode IS NULL OR Order_Zipcode = '';
GO



SELECT Customer_Id, COUNT(*) FROM Bronze.Customers GROUP BY Customer_Id HAVING COUNT(*) > 1;
SELECT Product_Card_Id, COUNT(*) FROM Bronze.Products GROUP BY Product_Card_Id HAVING COUNT(*) > 1;
SELECT Salesman_Id, COUNT(*) FROM Bronze.Salesman GROUP BY Salesman_Id HAVING COUNT(*) > 1;
SELECT Order_Item_Id, COUNT(*) FROM Bronze.Orders GROUP BY Order_Item_Id HAVING COUNT(*) > 1;
GO



SELECT COUNT(*) AS missing_customers
FROM Bronze.Orders o
LEFT JOIN Bronze.Customers c ON o.Customer_Id = c.Customer_Id
WHERE c.Customer_Id IS NULL;

SELECT COUNT(*) AS missing_products
FROM Bronze.Orders o
LEFT JOIN Bronze.Products p ON o.Product_Card_Id = p.Product_Card_Id
WHERE p.Product_Card_Id IS NULL;

SELECT COUNT(*) AS missing_salesmen
FROM Bronze.Orders o
LEFT JOIN Bronze.Salesman s ON o.salesman_id = s.Salesman_Id
WHERE s.Salesman_Id IS NULL;
GO


SELECT Market, COUNT(*) AS total FROM Bronze.Orders GROUP BY Market;
SELECT Shipping_Mode, COUNT(*) AS total FROM Bronze.Orders GROUP BY Shipping_Mode;
SELECT Delivery_Status, COUNT(*) AS total FROM Bronze.Orders GROUP BY Delivery_Status;
SELECT Order_Status, COUNT(*) AS total FROM Bronze.Orders GROUP BY Order_Status;

SELECT COUNT(*) AS negative_benefit FROM Bronze.Orders WHERE Benefit_per_order < 0;
GO