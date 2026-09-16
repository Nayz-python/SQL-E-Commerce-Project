
USE ProjectDB


--Q1. What is the overall date range, total revenue generated,total items sold, & average order value (AOV)?

SELECT
min(year(Order_Date)) AS Start_Date,
max(year(Order_Date)) AS End_Date,
Round(sum(Quantity * Unit_Price),0) AS Total_Revenue,
sum(Quantity) AS Total_Items_Sold ,
round(avg(Order_Value),1) AS Avg_Order_Value
FROM [ProjectDB].[dbo].[Sales]
WHERE Order_Status  NOT IN ('Cancelled', 'Returned');
 

 ---------------------------------------------------------
--Q2. How is total sales revenue distributed across differentpayment methods?

WITH Payment_Rank as(
	SELECT Payment_Mode,
	ROUND(sum(Order_Value),0) AS Total_Sales_Per_mode
	FROM [ProjectDB].[dbo].[Sales]
	WHERE Order_Status NOT IN ('Cancelled', 'Returned')
	GROUP BY Payment_Mode)


--Main Query
 SELECT Payment_Mode,Total_Sales_Per_mode,
 RANK() OVER(ORDER BY Total_Sales_Per_mode DESC) AS Rnk
 FROM Payment_Rank


--------------------------------------------------------------
--Q3. What are the top 5 cities and states by total sales revenue?

SELECT TOP 5 
TRIM(State) AS State, TRIM(City) AS City,
ROUND(sum(Order_Value),1) as Total_Revenue_Per_State,
RANK() over(ORDER BY sum(Order_Value ) DESC ) as Ranking
FROM [ProjectDB].[dbo].[Sales]
WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
GROUP BY State,City
ORDER BY Total_Revenue_Per_State DESC;


---------------------------------------------------------------
--Q4. How many customers have placed only 1 order versus repeat customers who have placed 2 or more orders?
 

 SELECT COUNT(Customer_ID) AS CUSTOMER_COUNT,CUSTOMER_TYPE
 FROM
 (
	SELECT Customer_ID, count(Order_ID) AS TOTAL_Orders,
	CASE 
		WHEN count(Order_ID) = 1 THEN 'New_Customer'
		WHEN count(Order_ID) >= 2 THEN 'Repeat_Customer'
	END AS CUSTOMER_TYPE
	FROM [ProjectDB].[dbo].[Sales]
	WHERE Order_Status NOT IN ('Cancelled', 'Returned')
	GROUP BY Customer_ID
   )Q  
WHERE TOTAL_Orders <= 2
GROUP BY  CUSTOMER_TYPE


-----------------------------------------------------------

--Q5. Who are the top 10 customers by total spend & how manytotal orders has each placed?


SELECT TOP 10 C.Customer_ID,C.Customer_Name,
SUM(S.Order_Value) AS Total_Spent,
COUNT(S.Order_ID)AS Total_Orders
FROM ProjectDB.dbo.customers C
JOIN ProjectDB.dbo.sales S
ON S.Customer_ID = C.Customer_ID
WHERE S.Order_Status  NOT IN ('Cancelled', 'Returned')
GROUP BY C.Customer_ID,C.Customer_Name
ORDER BY Total_Spent DESC

-------------------------------------------------------------
--Q6. How does total revenue and average order spend differacross CUSTOMER GENDER CATEGORY

SELECT C.Gender,
ROUND(SUM(c.Total_Spent),0) AS TOTAL_REVENUE,
ROUND(AVG(S.Order_Value),0) AS AVG_ORDER_SPEND,
concat(ROUND((SUM(S.Order_Value) /SUM(SUM(S.Order_Value)) OVER()) * 100,1),'%') AS REVENUE_PERCENTAGE --PERCENTAGE CONTRIBUTION PER GENDER
FROM ProjectDB.dbo.CUSTOMERS C 
JOIN ProjectDB.dbo.sales S
	ON C.Customer_ID = S.Customer_ID
WHERE S.Order_Status NOT IN ('Cancelled', 'Returned')
GROUP BY C.Gender
ORDER BY TOTAL_REVENUE DESC 


---------------------------------------------------------
--Q7. What is the revenue contribution and average spend per customer loyalty tier?


WITH Valid_Sales AS (
	SELECT Customer_ID, 
	SUM(Total_Amount) AS TOTAL_SPENT
	FROM ProjectDB.dbo.sales
	WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
    GROUP BY Customer_ID)


--MAIN QUERY 
SELECT C.Customer_Tier,
ROUND(AVG(S.TOTAL_SPENT),1) AS AVG_SPEND,
CONCAT(
ROUND(SUM(S.TOTAL_SPENT) / SUM(SUM(S.TOTAL_SPENT))OVER()*100,1),'%') AS REVENUE_SHARE,
RANK() OVER(ORDER BY AVG(S.TOTAL_SPENT) DESC) AS RANKING_CUSTOMERS
FROM Valid_Sales S
JOIN ProjectDB.dbo.customers c 
	ON c.Customer_ID = S.Customer_ID
GROUP BY Customer_Tier
ORDER BY AVG_SPEND DESC

------------------------------------------------------------
--Q8. Which cities experience the highest average shipping delays?

SELECT  City, Delivery_Performance ,
COUNT(Order_ID) AS Total_Orders
FROM (
	SELECT Order_ID,City,Order_Date,Delivery_Date, 
		CASE 
			WHEN Shipping_Delay_Days <=3 THEN 'Fast Delivery'
			WHEN Shipping_Delay_Days BETWEEN 4 AND 7 THEN 'Standard'
			ELSE 'Delayed'
		END AS Delivery_Performance
	FROM(
		SELECT Order_ID,City,Order_Date,Delivery_Date, 
		DATEDIFF(DAY,Order_Date, Delivery_Date) AS Shipping_Delay_Days
		FROM ProjectDB.dbo.sales
		WHERE Order_Status = 'Delivered'
	)Q1 
)Q2
GROUP BY  City, Delivery_Performance
ORDER BY  City, Total_Orders DESC


-----------------------------------------
--Q9. What are the top 5 best-selling products by total revenue,and TOP 5 WHICH ARE MOST SOLD BY QUANTITY


WITH PRODUCTS_RANKS AS(
	SELECT  P.Product_Name,
	ROUND(SUM(S.Total_Amount),1)  AS REVENUE,
	SUM(S.Quantity)  AS TOTAL_Qty,
	DENSE_RANK() OVER(ORDER BY SUM(S.Total_Amount) DESC) AS Revenue_Rank,
	DENSE_RANK() OVER(ORDER BY SUM(S.Quantity) DESC) AS QTY_RANK
	FROM ProjectDB.dbo.products P
	JOIN ProjectDB.dbo.sales S
		ON S.Product_ID = P.Product_ID
	WHERE S.Order_Status  NOT IN ('Cancelled', 'Returned')
	GROUP BY P.Category,P.Product_Name)


--MAIN QUERY
SELECT TOP 5 Product_Name, REVENUE,
Revenue_Rank, TOTAL_Qty, QTY_RANK
FROM PRODUCTS_RANKS
ORDER BY REVENUE DESC


----------------------------------------------------------
--Q10. Which product categories have the highest return rate(%) and what is the total revenue lost due to returned items?

--Return_Rate_formula = no.of returned items / total item sold * 100

SELECT P.Category,
SUM(CASE when S.Order_Status = 'Returned' THEN S.Quantity END * 100.0) /(sum(S.Quantity)) AS Return_rate
,ROUND(SUM(CASE when S.Order_Status = 'Returned' THEN S.Total_Amount END),1) AS REVENUE_LOST
FROM ProjectDB.dbo.Sales S
left join ProjectDB.dbo.products P
	ON P.Product_ID = S.Product_ID
GROUP BY P.Category
ORDER BY Return_rate DESC


----------------------------------------------------------

--Q11. Which product brands generate the highest total revenue and have the highest average selling prices?
 
SELECT P.Brand,
ROUND(SUM(S.Total_Amount),1) AS REVENUE,
ROUND(AVG(P.Selling_Price),1) AS AVG_PRICE
FROM ProjectDB.dbo.Sales S
left join ProjectDB.dbo.products P
	ON P.Product_ID = S.Product_ID
WHERE Order_Status NOT IN ('Cancelled', 'Returned')
GROUP BY P.Brand
ORDER BY REVENUE desc, AVG_PRICE DESC
	

------------------------------------------------------------
--Q12. Which high-rated products (rating >= 4.0) have low total sales volume, indicating potential for better marketing?

SELECT P.Product_ID,P.Product_Name,SUM(S.Quantity) AS UNITS_SOLD
FROM ProjectDB.dbo.products P
LEFT JOIN ProjectDB.dbo.sales S
	ON P.Product_ID = S.Product_ID
WHERE P.Avg_Rating >= 4.0 AND Order_Status NOT IN ('Cancelled', 'Returned')
GROUP BY P.Product_ID,P.Product_Name 
ORDER BY UNITS_SOLD


-------------------------------------------------------
--Q13. Does offering a higher discount on products result in higher total sales volume and total revenue?

WITH Discount_Products AS(
	SELECT  Coupon_Code,
	SUM(Quantity) AS UNITS_SOLD,
	ROUND(SUM(Total_Amount),1) AS REVENUE
	FROM ProjectDB.dbo.SALES 
	WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
	GROUP BY Coupon_Code) 


--MAIN QUERY
SELECT *, RANK() OVER(ORDER BY REVENUE DESC) AS RANKING_COUPONS
FROM Discount_Products


-----------------------------------------------------------
--Q14. What percentage of total orders used a coupon code, and how did that impact net revenue?

--percentage = (Orders with Coupons * 100.0) / Total Orders

SELECT COUNT(*) AS TOTAL_ORDERS,
ROUND(COUNT(
	CASE WHEN Coupon_Code IS NOT NULL THEN Order_ID END),1) as TOTAL_COUPONS, 
CONCAT(
ROUND(COUNT(
	CASE WHEN Coupon_Code IS NOT NULL THEN Order_ID END) * 100.0 / COUNT(*),1),'%') AS COUPON_ORDERS_PERCENT,
ROUND(SUM(
	CASE WHEN Coupon_Code IS NOT NULL THEN (Total_Amount - ISNULL(Coupon_Discount, 0)) ELSE 0 END),1) AS REVENUE_WITH_COUPON,
ROUND(SUM(
	CASE WHEN Coupon_Code IS NULL  THEN Total_Amount END),1) AS REVENUE_WITHOUT_COUPON
FROM ProjectDB.dbo.sales
WHERE Order_Status  NOT IN ('Cancelled', 'Returned')


-------------------------------------------------------
--Q15. How does delivery time impact customer review ratings ?
 
 --Avg_delivery time is approx 7 days and fast delivery time is within 3 days

 SELECT 
    ROUND(AVG(CASE when DIFF < 3 THEN Rating END),2) AS FAST_DELIVERY_AVG_RATING,
    COUNT(CASE WHEN DIFF < 3 THEN Rating END) as Count_Fast_Orders,

    ROUND(AVG(CASE WHEN DIFF >= 7 THEN Rating END),2) AS SLOW_DELIVERY_AVG_RATING,
    COUNT(CASE WHEN DIFF >=7 THEN Rating END) as Count_slow_Orders
FROM (
     SELECT Order_Date, Delivery_Date, Rating,
     DATEDIFF(DAY,Order_Date,Delivery_Date) AS DIFF
     FROM ProjectDB.dbo.sales
	 WHERE Order_Status = 'Delivered'
) q 
 

 -------------------------------------------------------
 --Q16. Monthly Revenue Growth: 
 --What is the month-over-month (MoM) revenue growth percentageover time?


SELECT 
 MNTH,
 ROUND(TOTAL_Revenue,1) AS TOTAL_Revenue,
 ROUND(PRVS_MONTH_REVENUE,1) AS PRVS_MONTH_REVENUE,
 ROUND((TOTAL_Revenue - PRVS_MONTH_REVENUE) / PRVS_MONTH_REVENUE * 100.0,2)  AS MOM_PERCENTAGE,
 CASE 
	WHEN TOTAL_Revenue > PRVS_MONTH_REVENUE THEN 'Increase'
	WHEN TOTAL_Revenue < PRVS_MONTH_REVENUE THEN 'Decrease'
	ELSE 'Flat'
END AS Performance
FROM (
	SELECT MNTH, 
		TOTAL_Revenue,
		lag(TOTAL_Revenue,1) over(Order by MNTH)  AS PRVS_MONTH_REVENUE
	FROM (
			SELECT  FORMAT(Order_Date,'MM-yyyy') AS MNTH,
			SUM(Total_Amount) AS TOTAL_Revenue
			FROM ProjectDB.dbo.sales
			WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
			GROUP BY  FORMAT(Order_Date,'MM-yyyy')
		)Q1
)Q2
ORDER BY MNTH 


------------------------------------------------------
--Q17. What are the top 3 best-selling products within each product category..

 WITH Product_Sales_Summary as(
	  SELECT P.Product_Name,P.Category,
	  SUM(S.Quantity) AS Total_units_sold
	  FROM ProjectDB.dbo.products P
	  LEFT JOIN ProjectDB.dbo.sales  S
		ON P.Product_ID = S.Product_ID
	  WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
	 GROUP BY P.Product_Name,P.Category),
Ranked_Products AS(
	SELECT Product_Name,Category,Total_units_sold,
	Dense_Rank() OVER(PARTITION BY Category ORDER BY Total_units_sold desc ) AS TOP_RANKING
	FROM Product_Sales_Summary)
	

--Main query
select  Category, Product_Name, TOP_RANKING
FROM Ranked_Products
WHERE TOP_RANKING <= 3
ORDER BY MAX(Total_units_sold) OVER (PARTITION BY Category) DESC, TOP_RANKING ASC;


----------------------------------------------------------
--Q18. RFM Customer Segmentation:
--How can we categorize customers into High, Medium, and Low value tiers based on their spend and order frequency?

WITH CUSTOMER_METRICS AS(
	SELECT C.Customer_Name,
	COUNT((S.Order_ID)) AS ORDER_FREQUENCY, 
	SUM(S.Total_Amount) AS OVER_ALL_SPEND
	FROM ProjectDB.dbo.customers C
	JOIN ProjectDB.dbo.sales S ON S.Customer_ID = C.Customer_ID
	WHERE S.Order_Status  NOT IN ('Cancelled', 'Returned')
	GROUP BY C.Customer_Name ) ,
CUSTOMER_BUCKET AS(
	SELECT Customer_Name,ORDER_FREQUENCY,OVER_ALL_SPEND,
	--NTILE(3) OVER(ORDER BY OVER_ALL_SPEND DESC,ORDER_FREQUENCY desc ) AS BUCKET
	NTILE(3) OVER(ORDER BY OVER_ALL_SPEND DESC) AS BUCKET_1,
	NTILE(3) OVER(ORDER BY ORDER_FREQUENCY desc ) AS BUCKET_2
	FROM CUSTOMER_METRICS) 


--Main Query
SELECT Customer_Name, ORDER_FREQUENCY,
OVER_ALL_SPEND, BUCKET_1 + BUCKET_2 as COMBINE_SCORE,
	CASE 
		WHEN BUCKET_1 + BUCKET_2 <= 3 THEN 'HIGH_VALUE_CUST'
		WHEN BUCKET_1 + BUCKET_2 = 4  THEN 'MEDIUM_VALUE_CUST'
		ELSE  'LOW_VALUE_CUST'
	END CUSTOMER_TIER
FROM CUSTOMER_BUCKET
ORDER BY OVER_ALL_SPEND DESC


---------------------------------------------------------------
--Q19. Customer Retention: 
--What percentage of customers who made their first purchase in a given month returned to place another order in the following month?


WITH First_Purchases AS (
    SELECT Customer_ID,
      MIN(Order_Date) AS First_order_Dt
    FROM ProjectDB.dbo.sales
	WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
    GROUP BY Customer_ID),
Check_Returns AS (
    SELECT f.Customer_ID,f.First_order_Dt,
         -- Checking if any order date falls in the exact next month
        MAX(CASE 
            WHEN s.Order_Date >= DATEADD(month, 1, f.First_order_Dt) 
             AND s.Order_Date < DATEADD(month, 2, f.First_order_Dt) 
            THEN 1 ELSE 0 END) AS Returned_Next_Month
    FROM First_Purchases f
    JOIN ProjectDB.dbo.sales s ON f.Customer_ID = s.Customer_ID
    GROUP BY f.Customer_ID, f.First_order_Dt)


--main query
SELECT 
    FORMAT(First_order_Dt, 'yyyy-MM') AS Cohort_Month,
    COUNT(Customer_ID) AS Total_New_Customers,
    SUM(Returned_Next_Month) AS Customers_Who_Returned,
    concat(
    round(CAST(SUM(Returned_Next_Month) AS FLOAT) / COUNT(Customer_ID) * 100,1),'%') AS Retention_Percentage
FROM Check_Returns
GROUP BY FORMAT(First_order_Dt, 'yyyy-MM')
ORDER BY Cohort_Month;


------------------------------------------------------------

-- Q20. Find the total lifetime spend for each customer, and 

--Using  CUME_DIST() to calculate spending percentile so that i can isolate top 10% highest-spending VIP customers.

WITH Customer_Spend AS (
	SELECT Customer_ID,
	SUM(Total_Amount) AS TOTAL_SPEND
	FROM ProjectDB.dbo.Sales
	WHERE Order_Status  NOT IN ('Cancelled', 'Returned')
	GROUP BY Customer_ID) ,
Customer_Percentile as(
	SELECT Customer_ID,TOTAL_SPEND,
	CUME_DIST() OVER(ORDER BY TOTAL_SPEND DESC) as DIST
	from Customer_Spend)


SELECT * 
FROM Customer_Percentile
WHERE DIST <= 0.10
ORDER BY TOTAL_SPEND DESC
--Here im getting more than 10%,bcz ive high val customers


----------------- THE END --------------------------