/* Выберите сотрудников (Application.People), 
которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2013 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.
*/

select PersonID, FullName, IsSalesperson from Application.People as ap
where IsSalesperson = 1 and not EXISTS (select distinct SalespersonPersonID from Sales.Invoices as si
where InvoiceDate = '2013-07-04' )

-----

with temp as (
select distinct SalespersonPersonID from Sales.Invoices as si
where InvoiceDate = '2013-07-04'
)
select PersonID, FullName, IsSalesperson from Application.People as ap
join temp
on PersonID = SalespersonPersonID
where IsSalesperson = 1 and PersonID is null


/*Выберите товары с минимальной ценой (подзапросом). 
Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.
*/

select distinct so.StockItemID, StockItemName, so.UnitPrice
from Sales.OrderLines as so
join Warehouse.StockItems as ws
on ws.stockItemID = so.StockItemID
where so.UnitPrice = (select min(UnitPrice) as min from Sales.OrderLines)

select * from Warehouse.StockItems

/*
Выберите информацию по клиентам, 
которые перевели компании пять 
максимальных платежей из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE).
*/

with temp as(
select top 5 CustomerID, sum(TransactionAmount) as sum from Sales.CustomerTransactions
group by CustomerID
order by sum desc)

select * from Sales.Customers as sc
join temp 
on temp.CustomerID = sc.CustomerID
where temp.CustomerID is not null

----

select * from Sales.Customers as sc
join (select top 5 CustomerID, sum(TransactionAmount) as sum from Sales.CustomerTransactions
group by CustomerID
order by sum desc) as temp
on temp.CustomerID = sc.CustomerID
where temp.CustomerID is not null

/*
Выберите города (ид и название), 
в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, 
также имя сотрудника, который осуществлял упаковку заказов (PackedByPersonID).
*/

-- PackedByPersonID == invoiceID, orderID, customerID
select * from Sales.Invoices
-- unitPrice == invoiceID(повторения)
select * from Sales.InvoiceLines
-- cituName == cityID
select * from Application.Cities
-- customerName == customerID, deliveryCityID
select * from Sales.Customers
-- personID = fullname
select * from Application.People

select top 3 sil.InvoiceID, customerName, fullName as packedByPerson, cityName, sum(UnitPrice) as sum from Sales.InvoiceLines as sil
join Sales.Invoices as si
on si.InvoiceID = sil.InvoiceID
join Sales.Customers as sc
on sc.CustomerID = si.CustomerID
join Application.People as ap
on ap.PersonID = PackedByPersonID
join Application.Cities as ac
on sc.DeliveryCityID = CityID
group by sil.InvoiceID, customerName, fullName, cityName
order by sum desc


