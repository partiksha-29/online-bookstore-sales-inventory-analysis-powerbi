-- ============================================================
-- ONLINE BOOKSTORE SQL PROJECT
-- ============================================================

--CREATE DATABASE (run this first, then connect to it before the rest)
DROP DATABASE IF EXISTS Online_Bookstore;
CREATE DATABASE Online_Bookstore;

--SWITCH TO THE DATABASE
\c Online_Bookstore;

-- ============================================================
-- CREATE TABLES
-- ============================================================

CREATE TABLE Books (
	Book_ID SERIAL PRIMARY KEY,
	Title VARCHAR(100),
	Author VARCHAR(100),
	Genre VARCHAR(100),
	Published_Year INT,
	Price NUMERIC(10,2),
	Stock INT
);

CREATE TABLE Customers (
	Customer_ID SERIAL PRIMARY KEY,
	Name VARCHAR(100),
	Email VARCHAR(100),
	Phone VARCHAR(15),
	City VARCHAR(50),
	Country VARCHAR(150)
);

CREATE TABLE Orders (
	Order_ID SERIAL PRIMARY KEY,
	Customer_ID INT REFERENCES Customers(Customer_ID),
	Book_ID INT REFERENCES Books(Book_ID),
	Order_Date DATE,
	Quantity INT,
	Total_Amount NUMERIC(10,2)
);

SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;

-- ============================================================
-- IMPORT DATA
-- NOTE: Update these file paths to match where your CSVs live
-- on your own machine before running.
-- ============================================================

--Import Data into Books Table
COPY Books(Book_ID, Title, Author, Genre, Published_Year, Price, Stock)
FROM 'D:\Books.csv'
DELIMITER ','
CSV HEADER;

--Import Data into Customers Table
COPY Customers(Customer_ID, Name, Email, Phone, City, Country)
FROM 'D:\Customers.csv'
DELIMITER ','
CSV HEADER;

--Import Data into Orders Table
COPY Orders(Order_ID, Customer_ID, Book_ID, Order_Date, Quantity, Total_Amount)
FROM 'D:\Orders.csv'
DELIMITER ','
CSV HEADER;

-- ============================================================
-- BASIC QUERIES
-- ============================================================

--1) Retrieve all books in the "Fiction" genre:
SELECT * FROM Books
WHERE Genre = 'Fiction';

--2) Find books published after the year 1950:
SELECT * FROM Books
WHERE Published_Year > 1950;

--3) List all customers from Canada:
SELECT * FROM Customers
WHERE Country = 'Canada';

--4) Show orders placed in November 2023:
SELECT * FROM Orders
WHERE Order_Date BETWEEN '2023-11-01' AND '2023-11-30';

--5) Retrieve the total stock of books available:
SELECT SUM(Stock) AS Total_Stock
FROM Books;

--6) Find the details of the most expensive book:
SELECT * FROM Books
ORDER BY Price DESC
LIMIT 1;

--7) Show all orders where more than 1 quantity of a book was ordered:
SELECT * FROM Orders
WHERE Quantity > 1;

--8) Retrieve all orders where the total amount exceeds $20:
SELECT * FROM Orders
WHERE Total_Amount > 20;

--9) List all genres available in the books table:
SELECT DISTINCT Genre FROM Books;

--10) Find the book with the lowest stock:
SELECT * FROM Books
ORDER BY Stock
LIMIT 1;

--11) Calculate the total revenue generated from all orders:
SELECT SUM(Total_Amount) AS Revenue
FROM Orders;

-- ============================================================
-- AGGREGATE / GROUP BY QUERIES
-- ============================================================

--1) Retrieve the total number of books sold for each genre:
SELECT b.Genre, SUM(o.Quantity) AS Total_Sold
FROM Books b
JOIN Orders o ON b.Book_ID = o.Book_ID
GROUP BY b.Genre;

--2) Find the average price of books in the "Fantasy" genre:
SELECT AVG(Price) AS Average_Price FROM Books
WHERE Genre = 'Fantasy';

--3) List customers who have placed at least 2 orders:
SELECT c.Name, o.Customer_ID, COUNT(o.Order_ID) AS Order_Count
FROM Orders o
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY o.Customer_ID, c.Name
HAVING COUNT(o.Order_ID) >= 2;

--4) Find the most frequently ordered book:
SELECT o.Book_ID, b.Title, COUNT(o.Order_ID) AS Order_Count
FROM Orders o
JOIN Books b ON o.Book_ID = b.Book_ID
GROUP BY o.Book_ID, b.Title
ORDER BY Order_Count DESC
LIMIT 1;

--5) Show the top 3 most expensive books in the 'Fantasy' genre:
SELECT * FROM Books
WHERE Genre = 'Fantasy'
ORDER BY Price DESC
LIMIT 3;

--6) Retrieve the total quantity of books sold by each author:
SELECT b.Author, SUM(o.Quantity) AS Total_Books_Sold
FROM Books b
JOIN Orders o ON o.Book_ID = b.Book_ID
GROUP BY b.Author;

--7) List the cities where customers who spent over $30 are located:
SELECT DISTINCT c.City, o.Total_Amount
FROM Customers c
JOIN Orders o ON c.Customer_ID = o.Customer_ID
WHERE o.Total_Amount > 30;

--8) Find the customer who spent the most on orders:
SELECT c.Customer_ID, c.Name, SUM(o.Total_Amount) AS Total_Spent
FROM Orders o
JOIN Customers c ON o.Customer_ID = c.Customer_ID
GROUP BY c.Customer_ID, c.Name
ORDER BY Total_Spent DESC
LIMIT 1;

-- ============================================================
-- SUBQUERIES
-- ============================================================

--1) Find books whose price is greater than the average price of all books:
SELECT * FROM Books
WHERE Price > (SELECT AVG(Price) FROM Books);

--2) Find customers who placed more orders than the average number of orders:
SELECT Customer_ID, COUNT(Order_ID) AS Total_Orders
FROM Orders
GROUP BY Customer_ID
HAVING COUNT(Order_ID) >
(
	SELECT AVG(Order_Count)
	FROM (
		SELECT COUNT(Order_ID) AS Order_Count
		FROM Orders
		GROUP BY Customer_ID
	) sub
);

--3) Find the most expensive book in each genre:
SELECT Title, Genre, Price
FROM Books b1
WHERE Price =
(
	SELECT MAX(Price)
	FROM Books b2
	WHERE b1.Genre = b2.Genre
);

--4) Show customers who never placed any order:
SELECT Name
FROM Customers
WHERE Customer_ID NOT IN
(
	SELECT Customer_ID
	FROM Orders
);

--5) Find books that were ordered at least once:
SELECT Title, Book_ID
FROM Books
WHERE Book_ID IN
(
	SELECT DISTINCT Book_ID
	FROM Orders
);

-- ============================================================
-- CTEs
-- ============================================================

--1) Find top 5 customers based on total spending:
WITH Customer_Spending AS
(
	SELECT Customer_ID, SUM(Total_Amount) AS Total_Spent
	FROM Orders
	GROUP BY Customer_ID
)
SELECT Customer_ID, Total_Spent FROM Customer_Spending
ORDER BY Total_Spent DESC
LIMIT 5;

--2) Find average book price for each genre using a CTE:
WITH Avg_Price_Genre AS
(
	SELECT Genre, AVG(Price) AS Avg_Price
	FROM Books
	GROUP BY Genre
)
SELECT * FROM Avg_Price_Genre;

--3) Find customers who spent more than average spending:
WITH Customer_Spending AS
(
	SELECT Customer_ID, SUM(Total_Amount) AS Total_Spent
	FROM Orders
	GROUP BY Customer_ID
)
SELECT Customer_ID, Total_Spent
FROM Customer_Spending
WHERE Total_Spent >
(
	SELECT AVG(Total_Spent)
	FROM Customer_Spending
);

--4) Calculate remaining stock after orders:
WITH Sold_Books AS
(
	SELECT Book_ID, SUM(Quantity) AS Quantity_Sold
	FROM Orders
	GROUP BY Book_ID
)
SELECT b.Title, b.Book_ID, b.Stock - COALESCE(s.Quantity_Sold, 0) AS Remaining_Stock
FROM Books b
LEFT JOIN Sold_Books s ON b.Book_ID = s.Book_ID;

--5) Find monthly sales:
SELECT EXTRACT(YEAR FROM Order_Date) AS Year,
       EXTRACT(MONTH FROM Order_Date) AS Month,
       SUM(Total_Amount) AS Sales
FROM Orders
GROUP BY Year, Month
ORDER BY Year ASC, Month ASC;

-- ============================================================
-- WINDOW FUNCTIONS
-- ============================================================

--1) Rank books based on price:
SELECT Title, Price, RANK() OVER (ORDER BY Price DESC) AS Ranking
FROM Books;

--2) Find the second highest priced book:
SELECT * FROM
(
	SELECT Title, Price, DENSE_RANK() OVER (ORDER BY Price DESC) AS Rnk
	FROM Books
) t
WHERE Rnk = 2;

--3) Show running total of sales:
SELECT Order_Date, Total_Amount,
SUM(Total_Amount) OVER (ORDER BY Order_Date) AS Running_Total
FROM Orders;

--4) Find highest spending customer in each city:
SELECT * FROM
(
	SELECT c.Name, c.City, o.Total_Amount,
	DENSE_RANK() OVER (PARTITION BY c.City ORDER BY o.Total_Amount DESC) AS Rnk
	FROM Customers c
	JOIN Orders o ON c.Customer_ID = o.Customer_ID
) t
WHERE Rnk = 1;

--5) Compare current order amount with previous order:
SELECT Order_ID, Order_Date, Total_Amount,
LAG(Total_Amount) OVER (ORDER BY Order_Date) AS Previous_Order
FROM Orders;

--6) Find difference between current and previous order amount (per customer):
SELECT Order_ID,
	Customer_ID, Order_Date, Total_Amount,
	Total_Amount - LAG(Total_Amount) OVER
	(PARTITION BY Customer_ID ORDER BY Order_Date) AS Difference
FROM Orders;

--7) Find cumulative quantity sold for each book:
SELECT Book_ID, Order_Date, Quantity,
SUM(Quantity) OVER (PARTITION BY Book_ID ORDER BY Order_Date) AS Cumulative_Qty
FROM Orders;
