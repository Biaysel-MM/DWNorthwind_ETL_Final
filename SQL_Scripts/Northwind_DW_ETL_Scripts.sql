-- Crear la base de datos limpia
CREATE DATABASE dwventas
GO

USE dwventas
GO

-- Tabla DimCustomers
CREATE TABLE [dbo].[DimCustomers](
    [CustomerKey] [int] IDENTITY(1,1) NOT NULL,
    [CustomerID] [nchar](5) NOT NULL,
    [CompanyName] [nvarchar](40) NOT NULL,
    [ContactName] [nvarchar](30) NULL,
    CONSTRAINT [PK_DimCustomers] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
)
GO

-- Tabla DimEmployees
CREATE TABLE [dbo].[DimEmployees](
    [EmployeeKey] [int] IDENTITY(1,1) NOT NULL,
    [EmployeeID] [int] NOT NULL,
    [LastName] [nvarchar](20) NOT NULL,
    [FirstName] [nvarchar](10) NOT NULL,
    CONSTRAINT [PK_DimEmployees] PRIMARY KEY CLUSTERED ([EmployeeKey] ASC)
)
GO

-- Tabla DimProducts
CREATE TABLE [dbo].[DimProducts](
    [ProductKey] [int] IDENTITY(1,1) NOT NULL,
    [ProductID] [int] NOT NULL,
    [ProductName] [nvarchar](40) NOT NULL,
    CONSTRAINT [PK_DimProducts] PRIMARY KEY CLUSTERED ([ProductKey] ASC)
)
GO



--  Creación de Tablas Dimensiones

-- Cargar DimCustomers
INSERT INTO [dbo].[DimCustomers] (
    [CustomerID], [CompanyName], [ContactName]
)
SELECT 
    [CustomerID], [CompanyName], [ContactName]
FROM [Northwind].[dbo].[Customers]
GO

-- Cargar DimEmployees
INSERT INTO [dbo].[DimEmployees] (
    [EmployeeID], [LastName], [FirstName]
)
SELECT 
    [EmployeeID], [LastName], [FirstName]
FROM [Northwind].[dbo].[Employees]
GO

-- Cargar DimProducts
INSERT INTO [dbo].[DimProducts] (
    [ProductID], [ProductName]
)
SELECT 
    [ProductID], [ProductName]
FROM [Northwind].[dbo].[Products]
GO

-- Verificar carga
SELECT 
    (SELECT COUNT(*) FROM DimCustomers) AS TotalCustomers,
    (SELECT COUNT(*) FROM DimEmployees) AS TotalEmployees,
    (SELECT COUNT(*) FROM DimProducts) AS TotalProducts
GO



-- Creación de Fact Tables
-- FactOrders
CREATE TABLE [dbo].[FactOrders](
    [OrderKey] [int] IDENTITY(1,1) NOT NULL,
    [OrderID] [int] NOT NULL,
    [CustomerKey] [int] NOT NULL,
    [EmployeeKey] [int] NOT NULL,
    [OrderDate] [datetime] NOT NULL,
    [SalesAmount] [money] NULL,
    CONSTRAINT [PK_FactOrders] PRIMARY KEY CLUSTERED ([OrderKey] ASC)
)
GO

-- FactCustomers
CREATE TABLE [dbo].[FactCustomers](
    [CustomerKey] [int] NOT NULL,
    [CustomerID] [nchar](5) NOT NULL,
    [TotalOrders] [int] NULL,
    [TotalAmount] [money] NULL,
    CONSTRAINT [PK_FactCustomers] PRIMARY KEY CLUSTERED ([CustomerKey] ASC)
)
GO

-- FactOrderDetails
CREATE TABLE [dbo].[FactOrderDetails](
    [OrderDetailKey] [int] IDENTITY(1,1) NOT NULL,
    [OrderKey] [int] NOT NULL,
    [ProductKey] [int] NOT NULL,
    [UnitPrice] [money] NOT NULL,
    [Quantity] [smallint] NOT NULL,
    [LineTotal] [money] NULL,
    CONSTRAINT [PK_FactOrderDetails] PRIMARY KEY CLUSTERED ([OrderDetailKey] ASC)
)
GO



-- Procedimientos de Limpieza y Carga

-- Procedimiento para limpiar TODAS las fact tables
CREATE OR ALTER PROCEDURE [dbo].[sp_CleanAllFactTables]
AS
BEGIN
    TRUNCATE TABLE [dbo].[FactOrderDetails]
    TRUNCATE TABLE [dbo].[FactCustomers]
    TRUNCATE TABLE [dbo].[FactOrders]
    PRINT 'Todas las Fact Tables han sido limpiadas'
END
GO

-- Procedimiento para cargar FactOrders (versión simplificada y optimizada)
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadFactOrders]
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[FactOrders] (
        [OrderID], [CustomerKey], [EmployeeKey], [OrderDate], [SalesAmount]
    )
    SELECT 
        o.OrderID,
        c.CustomerKey,
        e.EmployeeKey,
        o.OrderDate,
        ISNULL((SELECT SUM(UnitPrice * Quantity * (1 - Discount)) 
               FROM [Northwind].[dbo].[Order Details] od 
               WHERE od.OrderID = o.OrderID), 0) AS SalesAmount
    FROM 
        [Northwind].[dbo].[Orders] o
        INNER JOIN [dwventas].[dbo].[DimCustomers] c ON o.CustomerID = c.CustomerID
        INNER JOIN [dwventas].[dbo].[DimEmployees] e ON o.EmployeeID = e.EmployeeID
    
    PRINT 'FactOrders cargada correctamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO

-- Procedimiento para cargar FactCustomers
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadFactCustomers]
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[FactCustomers] (
        [CustomerKey], [CustomerID], [TotalOrders], [TotalAmount]
    )
    SELECT 
        c.CustomerKey,
        c.CustomerID,
        COUNT(DISTINCT o.OrderID) AS TotalOrders,
        ISNULL(SUM(od.UnitPrice * od.Quantity * (1 - od.Discount)), 0) AS TotalAmount
    FROM 
        [dwventas].[dbo].[DimCustomers] c
        LEFT JOIN [Northwind].[dbo].[Orders] o ON c.CustomerID = o.CustomerID
        LEFT JOIN [Northwind].[dbo].[Order Details] od ON o.OrderID = od.OrderID
    GROUP BY 
        c.CustomerKey, c.CustomerID
    
    PRINT 'FactCustomers cargada correctamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO

-- Procedimiento para cargar FactOrderDetails
CREATE OR ALTER PROCEDURE [dbo].[sp_LoadFactOrderDetails]
AS
BEGIN
    SET NOCOUNT ON;
    
    INSERT INTO [dbo].[FactOrderDetails] (
        [OrderKey], [ProductKey], [UnitPrice], [Quantity], [LineTotal]
    )
    SELECT 
        fo.OrderKey,
        p.ProductKey,
        od.UnitPrice,
        od.Quantity,
        (od.UnitPrice * od.Quantity * (1 - od.Discount)) AS LineTotal
    FROM 
        [Northwind].[dbo].[Order Details] od
        INNER JOIN [dwventas].[dbo].[FactOrders] fo ON od.OrderID = fo.OrderID
        INNER JOIN [dwventas].[dbo].[DimProducts] p ON od.ProductID = p.ProductID
    
    PRINT 'FactOrderDetails cargada correctamente. Filas insertadas: ' + CAST(@@ROWCOUNT AS VARCHAR)
END
GO

-- Verifica los datos antes y despues de cargar los datos 
-- Verificar conteos
SELECT 
    (SELECT COUNT(*) FROM FactOrders) AS TotalOrders,
    (SELECT COUNT(*) FROM FactCustomers) AS TotalCustomers,
    (SELECT COUNT(*) FROM FactOrderDetails) AS TotalOrderDetails

-- Ejemplo de datos
SELECT TOP 5 * FROM FactOrders
SELECT TOP 5 * FROM FactCustomers
SELECT TOP 5 * FROM FactOrderDetails