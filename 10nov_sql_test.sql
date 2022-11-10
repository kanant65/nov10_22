-- 1. Order Subtotals
-- For each order, calculate a subtotal for each Order (identified by OrderID). This is a simple query using GROUP BY to aggregate data 
-- for each order.

	SELECT OrderID,
		SUM(UnitPrice*Quantity) AS Subtotals
	FROM Order_details
    GROUP BY OrderID;
 
-- 2. Sales by Year
-- This query shows how to get the year part from Shipped_Date column. A subtotal is calculated by a sub-query for each order. The
--  sub-query forms a table and then joined with the Orders table.

	SELECT DISTINCT DATE(O.ShippedDate) AS ShippedDate, 
		O.OrderID, 
		I.Subtotal, 
		YEAR(O.ShippedDate) AS Year
	FROM Orders O
	INNER JOIN(
				SELECT DISTINCT OrderID, 
					  SUM(UnitPrice * Quantity) AS Subtotal
				FROM Order_details
				GROUP BY OrderID    
			) I
	ON O.OrderID = I.OrderID
	WHERE O.ShippedDate IS NOT NULL;

-- 3. Employee Sales by Country
-- For each employee, get their sales amount, broken down by country name.

	SELECT  E.Country,
			E.LastName, 
			E.FirstName, 
			O.ShippedDate,
			O.OrderID,
			I.Subtotal AS Sale_Amount
	FROM Employees E
	INNER JOIN Orders O INNER JOIN(
									SELECT DISTINCT OrderID, 
										  SUM(UnitPrice * Quantity) AS Subtotal
									FROM Order_details
									GROUP BY OrderID    
									) I
	ON E.EmployeeID = O.EmployeeID
	WHERE O.ShippedDate IS NOT NULL;	

-- 4. Alphabetical List of Products
-- This is a rather simple query to get an alphabetical list of products.

	SELECT  ProductID,
			ProductName,
            SupplierID,
            CategoryID,
            QuantityPerUnit,
            UnitPrice
	FROM Products
    ORDER BY ProductName;

-- 5. Current Product List
-- This is another simple query. No aggregation is used for summarizing data.

	SELECT 	ProductID,
			ProductName
	FROM Products
	WHERE Discontinued = 'n'
	ORDER BY ProductName;

-- 6. Order Details Extended
-- This query calculates sales price for each order after discount is applied.

	SELECT DISTINCT O.OrderID, 
					O.ProductID, 
					P.ProductName, 
					O.UnitPrice, 
					O.Quantity, 
					O.Discount, 
					ROUND(O.UnitPrice * O.Quantity * (1 - O.Discount), 2) AS ExtendedPrice
	FROM Products P
	INNER JOIN Order_Details O ON
    P.ProductID = O.ProductID
	ORDER BY O.OrderID;

-- 7. Sales by Category
-- For each category, we get the list of products sold and the total sales amount. Note that, in the second query, the inner query for 
-- table c is to get sales for each product on each order. It then joins with outer query on Product_ID. In the outer query, products are
-- grouped for each category.

	SELECT DISTINCT a.CategoryID, 
					a.CategoryName, 
					b.ProductName, 
					sum(c.ExtendedPrice) as ProductSales
	FROM Categories a 
	INNER JOIN Products b ON a.CategoryID = b.CategoryID
	INNER JOIN 
	(
		SELECT DISTINCT y.OrderID, 
			y.ProductID, 
			x.ProductName, 
			y.UnitPrice, 
			y.Quantity, 
			y.Discount, 
			ROUND(y.UnitPrice * y.Quantity * (1 - y.Discount), 2) AS ExtendedPrice
		FROM Products x
		INNER JOIN Order_Details y ON x.ProductID = y.ProductID
		ORDER BY y.OrderID
	) c ON c.ProductID = b.ProductID
	INNER JOIN Orders d ON d.OrderID = c.OrderID
	WHERE d.OrderDate BETWEEN DATE('1997/1/1') AND DATE('1997/12/31')
	GROUP BY a.CategoryID, a.CategoryName, b.ProductName
	ORDER BY a.CategoryName, b.ProductName, ProductSales;

-- 8. Ten Most Expensive Products
-- The two queries below return the same result. It demonstrates how MySQL limits the number of records returned.
-- The first query uses correlated sub-query to get the top 10 most expensive products.
-- The second query retrieves data from an ordered sub-query table and then the keyword LIMIT is used outside the sub-query to restrict 
-- the number of rows returned.

	SELECT 
		*
    FROM(
		SELECT DISTINCT ProductName AS Ten_Most_Expensive_Products, 
						UnitPrice
		FROM Products
		ORDER BY UnitPrice DESC
) AS I
limit 10;

-- 9. Products by Category
-- This is a simple query 

	SELECT DISTINCT C.CategoryName, 
					P.ProductName, 
					P.QuantityPerUnit, 
					P.UnitsInStock, 
					P.Discontinued
	FROM Categories C
	INNER JOIN Products P ON
    C.CategoryID = P.CategoryID
	WHERE P.Discontinued = 'N';

-- 10. Customers and Suppliers by City
-- This query shows how to use UNION to merge Customers and Suppliers into one result set by identifying them as having different
--  relationships to Northwind Traders - Customers and Suppliers.

	SELECT City, 
			CompanyName, 
            ContactName,
            'Customers' AS Relationship 
	FROM Customers
	UNION
	SELECT City,
			CompanyName,
            ContactName, 
            'Suppliers'
	FROM Suppliers
	order by City, CompanyName;

-- 11. Products Above Average Price
-- This query shows how to use sub-query to get a single value (average unit price) that can be used in the outer-query.

	SELECT DISTINCT ProductName,
					UnitPrice
	FROM Products
	WHERE UnitPrice >	(SELECT AVG(UnitPrice) 
						FROM Products
						)
	ORDER BY UnitPrice;
    
-- 12. Product Sales for 1997
-- This query shows how to group categories and products by quarters and shows sales amount for each quarter.

	SELECT DISTINCT A.CategoryName, 
					B.ProductName, 
					SUM(C.UnitPrice * C.Quantity * (1 - C.Discount)) AS ProductSales,
					CONCAT('Qtr ', QUARTER(D.ShippedDate)) AS ShippedQuarter
	FROM Categories A
	INNER JOIN Products B ON
    A.CategoryID = B.CategoryID
	INNER JOIN Order_Details C ON
    B.ProductID = C.ProductID
	INNER JOIN Orders D ON
    D.OrderID = C.OrderID
    WHERE D.ShippedDate IS NOT NULL
	GROUP BY A.CategoryName, 
    B.ProductName, 
    CONCAT('Qtr ', QUARTER(D.ShippedDate))
	ORDER BY A.CategoryName, 
			B.ProductName, 
			ShippedQuarter;
    
-- 13. Category Sales for 1997
-- This query shows sales figures by categories - mainly just aggregation with sub-query. The inner query aggregates to product level, 
-- and the outer query further aggregates the result set from inner-query to category level.

SELECT  CategoryName,
		FORMAT(SUM(ProductSales), 2) AS CategorySales
FROM(
		SELECT DISTINCT A.CategoryName, 
						B.ProductName, 
				FORMAT(SUM(C.UnitPrice * C.Quantity * (1 - C.Discount)), 2) AS ProductSales,
				CONCAT('Qtr ', QUARTER(D.ShippedDate)) AS ShippedQuarter
		FROM Categories AS A
		INNER JOIN Products AS B ON A.CategoryID = B.CategoryID
		INNER JOIN Order_Details AS C ON B.ProductID = C.ProductID
		INNER JOIN Orders AS D ON D.OrderID = C.OrderID 
		WHERE D.ShippedDate BETWEEN DATE('1997-01-01') AND DATE('1997-12-31')
		GROUP BY A.CategoryName, 
				B.ProductName, 
				CONCAT('Qtr ', QUARTER(D.ShippedDate))
		ORDER BY A.CategoryName, 
				B.ProductName, 
				ShippedQuarter
	) AS I
GROUP BY CategoryName
ORDER BY CategoryName;

-- 14. Quarterly Orders by Product
-- This query shows how to convert order dates to the corresponding quarters. It also demonstrates how SUM function is used together with
--  CASE statement to get sales for each quarter, where quarters are converted from OrderDate column.

	 SELECT A.ProductName, 
			D.CompanyName, 
		YEAR(OrderDate) AS OrderYear,
		FORMAT(SUM(CASE QUARTER(C.OrderDate) WHEN '1' 
			THEN B.UnitPrice*B.Quantity*(1-B.Discount) else 0 end), 0) "Qtr 1",
		FORMAT(SUM(CASE QUARTER(C.OrderDate) WHEN '2' 
			THEN B.UnitPrice*B.Quantity*(1-B.Discount) else 0 end), 0) "Qtr 2",
		FORMAT(SUM(CASE QUARTER(C.OrderDate) when '3' 
			THEN B.UnitPrice*B.Quantity*(1-B.Discount) else 0 end), 0) "Qtr 3",
		FORMAT(SUM(CASE QUARTER(C.OrderDate) when '4' 
			THEN B.UnitPrice*B.Quantity*(1-B.Discount) else 0 end), 0) "Qtr 4" 
	from Products A 
	INNER JOIN Order_Details B on A.ProductID = B.ProductID
	INNER JOIN Orders C on C.OrderID = B.OrderID
	INNER JOIN Customers D on D.CustomerID = C.CustomerID 
	WHERE C.OrderDate IS NOT NULL
	GROUP BY A.ProductName, 
		    D.CompanyName, 
		   year(OrderDate)
	ORDER BY A.ProductName, D.CompanyName;

-- 15. Invoice
-- A simple query to get detailed information for each sale so that invoice can be issued.

	SELECT DISTINCT B.ShipName, 
					B.ShipAddress, 
					B.ShipCity, 
					B.ShipRegion, 
					B.ShipPostalCode, 
					B.ShipCountry, 
					B.CustomerID, 
					C.CompanyName, 
					C.Address, 
					C.City, 
					C.Region, 
					C.PostalCode, 
					C.Country, 
			CONCAT(D.FirstName,  ' ', D.LastName) AS Salesperson, 
					B.OrderID, 
					B.OrderDate, 
					B.RequiredDate, 
					B.ShippedDate, 
					A.CompanyName, 
					E.ProductID, 
					F.ProductName, 
					E.UnitPrice, 
					E.Quantity, 
					E.Discount,
					E.UnitPrice * E.Quantity * (1 - E.Discount) as ExtendedPrice,
					B.Freight
	FROM Shippers A 
	INNER JOIN Orders B ON A.ShipperID = B.ShipVia 
	INNER JOIN Customers C ON C.CustomerID = B.CustomerID
	INNER JOIN Employees D ON D.EmployeeID = B.EmployeeID
	INNER JOIN Order_Details E ON B.OrderID = E.OrderID
	INNER JOIN Products F ON F.ProductID = E.ProductID
	ORDER BY B.ShipName;
 
-- 16. Number of units in stock by category and supplier continent
-- This query shows that case statement is used in GROUP BY clause to list the number of units in stock for each product category and 
-- supplier's continent. Note that, if only s.Country (not the case statement) is used in the GROUP BY, duplicated rows will exist for each product category and supplier continent.

	SELECT C.CategoryName AS "Product Category", 
		   CASE WHEN S.Country IN 
					 ('UK','Spain','Sweden','Germany','Norway',
					  'Denmark','Netherlands','Finland','Italy','France')
				THEN 'Europe'
				WHEN S.Country IN ('USA','Canada','Brazil') 
				THEN 'America'
				ELSE 'Asia-Pacific'
			END AS "Supplier Continent", 
			SUM(P.UnitsInStock) AS UnitsInStock
	FROM Suppliers S
	INNER JOIN Products P ON P.SupplierID=S.SupplierID
	INNER JOIN Categories C ON C.CategoryID=P.CategoryID 
	GROUP BY C.CategoryName, 
			 CASE WHEN S.Country IN 
					 ('UK','Spain','Sweden','Germany','Norway',
					  'Denmark','Netherlands','Finland','Italy','France')
				  THEN 'Europe'
				  WHEN S.Country IN ('USA','Canada','Brazil') 
				  THEN 'America'
				  ELSE 'Asia-Pacific'
			 END
	ORDER BY S.Country;
	 




