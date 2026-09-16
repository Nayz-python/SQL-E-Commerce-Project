
CREATE DATABASE ProjectDB;
GO

USE ProjectDB;
GO

-- 1. 
CREATE TABLE dbo.customers (
		Customer_ID NVARCHAR(50) NOT NULL PRIMARY KEY,
		Customer_Name NVARCHAR(50) ,
		Gender NVARCHAR(50),
		Age TINYINT,
		Age_Group NVARCHAR(50),
		Date_of_Birth DATE,
		Email VARCHAR(100),
		Phone VARCHAR(30),
		City NVARCHAR(50),
		State NVARCHAR(50),
		Pincode INT,
		Registration_Date DATE,
		Customer_Tier NVARCHAR(50),
		Total_Orders INT,
		Total_Spent FLOAT  );


		
	BULK INSERT dbo.customers
	FROM 'C:\path_to_your_folder\your_filename.csv'  --THIS FILE PATH IS DIFFERENT FOR EVERYONE
	WITH ( 
		FORMAT = 'CSV',
		FIRSTROW = 2,
		FIELDTERMINATOR = ',' ,
		ROWTERMINATOR = '\n' );


------------------------------------------------------

-- 2.
CREATE TABLE dbo.products(
		Product_ID NVARCHAR(50) NOT NULL PRIMARY KEY, 
		Product_Name NVARCHAR(50) NOT NULL,
		Category NVARCHAR(50) NULL,
		Brand NVARCHAR(50) NULL ,
		Original_Price FLOAT NOT NULL,
		Discount_Percent TINYINT NULL,
		Discount_Amount FLOAT NULL,
		Selling_Price FLOAT NOT NULL,
		Stock_Quantity TINYINT NOT NULL,
		Weight_kg FLOAT NULL,
		Avg_Rating FLOAT NULL,
		Total_Reviews INT NULL
		);

	BULK INSERT dbo.products
	FROM 'C:\path_to_your_folder\your_filename.csv'
	WITH ( 
		FORMAT = 'CSV',
		FIRSTROW = 2,
		FIELDTERMINATOR = ',' ,
		ROWTERMINATOR = '\n');


---------------------------------------------------------
-- 3.

CREATE TABLE dbo.sales(
	Order_ID NVARCHAR(50) NOT NULL PRIMARY KEY,
	Customer_ID NVARCHAR(50) NOT NULL,
	Product_ID NVARCHAR(50) NOT NULL,
	Order_Date DATE NOT NULL,
	Order_Time TIME NULL,
	Delivery_Date DATE NOT NULL,
	Quantity TINYINT NOT NULL ,
	Unit_Price FLOAT NOT NULL,
	Order_Value FLOAT NOT NULL,
	Shipping_Cost FLOAT NOT NULL,
	Coupon_Code NVARCHAR(50) NULL,
	Coupon_Discount FLOAT NULL,
	Total_Amount FLOAT NOT NULL,
	Payment_Mode NVARCHAR(50) NOT NULL,
	Order_Status NVARCHAR(50) NOT NULL,
	Rating FLOAT NULL,
	Review_Text NVARCHAR(50) NULL,
	City NVARCHAR(50) NULL,
	State NVARCHAR(50) NULL,
	Customer_Age TINYINT NULL,
	Customer_Age_Group NVARCHAR(50) NULL,
	-- Linking Foreign Keys to your other tables
	CONSTRAINT FK_Sales_Customers FOREIGN KEY (Customer_ID) REFERENCES dbo.customers(Customer_ID),
	CONSTRAINT FK_Sales_Products FOREIGN KEY (Product_ID) REFERENCES dbo.products(Product_ID)
	);


	BULK INSERT dbo.sales
	FROM 'C:\path_to_your_folder\your_filename.csv'
	WITH (
		FORMAT = 'CSV',
		FIRSTROW = 2,
		FIELDTERMINATOR = ',' ,
		ROWTERMINATOR = '\n');

