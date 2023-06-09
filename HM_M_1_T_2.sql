/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, JOIN".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД WideWorldImporters можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/download/wide-world-importers-v1.0/WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters;

/*
1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".

Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.
*/

select StockItemID, StockItemName from Warehouse.StockItems
where StockItemName like '%urgent%' or StockItemName like 'Animal%'

/*
2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.

Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.
*/

select s.SupplierID, SupplierName from Purchasing.Suppliers as s
full join Purchasing.PurchaseOrders as p on s.SupplierID = p.SupplierID
where PurchaseOrderID is Null


/*
3. Заказы (Orders) с товарами ценой (UnitPrice) более 100$
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).

Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ (10.01.2011)
* название месяца, в котором был сделан заказ (используйте функцию FORMAT или DATENAME)
* номер квартала, в котором был сделан заказ (используйте функцию DATEPART)
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

select o.OrderID, FORMAT(OrderDate, 'dd.MM.yyyy') as date, DATENAME(MONTH, OrderDate) as month, 
DATEPART(QUARTER, OrderDate) as quarter, (DATEPART(MONTH, OrderDate)-1)/4 + 1 as [треть года],
CustomerName from Sales.Orders as o
left join Sales.OrderLines as l on o.OrderID = l.OrderID
left join Sales.Customers as c on c.CustomerID = o.CustomerID
where (UnitPrice > 100 or Quantity > 20) and o.PickingCompletedWhen is not null
order by quarter, [треть года], OrderDate
OFFSET 1000 ROWS FETCH FIRST 100 ROWS ONLY;

/*
4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).

Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

select d.DeliveryMethodName, ExpectedDeliveryDate, SupplierName, PreferredName, IsOrderFinalized from Purchasing.PurchaseOrders as p
left join Purchasing.Suppliers as s on p.SupplierID = s.SupplierID
left join Application.DeliveryMethods as d on s.DeliveryMethodID = d.DeliveryMethodID
left join Application.People as pe on p.ContactPersonID = pe.PersonID
where ExpectedDeliveryDate >= '2013-01-01' and ExpectedDeliveryDate <= '2013-01-31' 
and (d.DeliveryMethodName = 'Air Freight' or d.DeliveryMethodName = 'Refrigerated Air Freight')
and IsOrderFinalized = 1
order by ExpectedDeliveryDate 


/*
5. Десять последних продаж (по дате продажи - InvoiceDate) с именем клиента (клиент - CustomerID) и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов.

Вывести: ИД продажи (InvoiceID), дата продажи (InvoiceDate), имя заказчика (CustomerName), имя сотрудника (SalespersonFullName)
Таблицы: Sales.Invoices, Sales.Customers, Application.People.
*/

select TOP(10) InvoiceID, InvoiceDate, CustomerName, FullName from Sales.Invoices as i
left join Sales.Customers as c on i.CustomerID = c.CustomerID
left join Application.People as p on p.PersonID = i.SalespersonPersonID
order by InvoiceID desc

/*
6. Все ид и имена клиентов (клиент - CustomerID) и их контактные телефоны (PhoneNumber),
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems, имена клиентов и их контакты в таблице Sales.Customers.

Таблицы: Sales.Invoices, Sales.InvoiceLines, Sales.Customers, Warehouse.StockItems.
*/

select i.CustomerID, CustomerName, PhoneNumber  from Sales.InvoiceLines as l
left join Sales.Invoices as i on l.InvoiceID = i.InvoiceID
left join Warehouse.StockItems as s on l.StockItemID = s.StockItemID
left join Sales.Customers as c on i.CustomerID = c.CustomerID
where StockItemName = 'Chocolate frogs 250g'
