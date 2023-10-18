-- Написать функцию возвращающую Клиента с наибольшей суммой покупки.

create function [dbo].[max_sum_customer] ()
returns table as
return
	select top 1 o.CustomerID, ol.OrderID, sum(unitprice) as sum_check from Sales.OrderLines as ol
	join Sales.Orders as o on ol.OrderID = o.OrderID
	group by ol.OrderID, o.CustomerID
	order by sum_check desc


-- Написать хранимую процедуру с входящим параметром СustomerID, выводящую сумму покупки по этому клиенту.
-- Использовать таблицы :
-- Sales.Customers
-- Sales.Invoices
-- Sales.InvoiceLines

-- ================================================
-- Template generated from Template Explorer using:
-- Create Procedure (New Menu).SQL
--
-- Use the Specify Values for Template Parameters 
-- command (Ctrl-Shift-M) to fill in the parameter 
-- values below.
--
-- This block of comments will not be included in
-- the definition of the procedure.
-- ================================================
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
alter PROCEDURE [dbo].[customer_sum_check]
	-- Add the parameters for the stored procedure here
	@customerID int
AS
BEGIN
	SET NOCOUNT ON;

	select i.CustomerID, sum(UnitPrice) from Sales.InvoiceLines as il
	join Sales.Invoices as i on il.InvoiceID = i.InvoiceID
	where  i.CustomerID = '1'
	group by i.CustomerID
END
GO

-- Создать одинаковую функцию и хранимую процедуру, посмотреть в чем разница в производительности и почему.
-- Разница в производительности в половину(процед 25%, функ 50%). Так как функция возвращает значение.


-- Создайте табличную функцию покажите как ее можно вызвать для каждой строки result set'а без использования цикла.
-- функия возвращает самую большую покупку по каждому пользователю 
    
alter function [dbo].[max_sum_customer_function] (@customerid int)
returns table as
return
	select top 1 o.CustomerID, ol.OrderID, sum(unitprice) as sum_check from Sales.OrderLines as ol
	join Sales.Orders as o on ol.OrderID = o.OrderID
	where CustomerID = @customerid
	group by ol.OrderID, o.CustomerID
	order by sum_check desc


select * from Sales.Customers
cross apply dbo.[max_sum_customer_function](CustomerID) as a 

