/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".

Задания выполняются с использованием базы данных WideWorldImporters.

Бэкап БД можно скачать отсюда:
https://github.com/Microsoft/sql-server-samples/releases/tag/wide-world-importers-v1.0
Нужен WideWorldImporters-Full.bak

Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/

-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/*
1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------
*/

select InvoiceDate, [2] as 'Sylvanite, MT', [3] as 'Peeples Valley, AZ', 
[4] as 'Medicine Lodge, KS', [5] as 'Gasport, NY', [6] as 'Jessie, ND'
from (
	select InvoiceID, si.CustomerID, DATETRUNC(month,InvoiceDate) AS  InvoiceDate from sales.invoices as si
	join Sales.Customers as sc
	on si.CustomerID = sc.CustomerID
	where si.CustomerID in (2,3,4,5,6)
) as temp
pivot (count(InvoiceID) for CustomerID
in ([2], [3], [4], [5] , [6])
) as pivotTable



/*
2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+--------------------
*/

select * 
from(
	select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2 from Sales.Customers
	where CustomerName like 'Tailspin Toys%'
) temp
unpivot (AddressLine for TypeAddress in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2))
as pivotDate
order by CustomerName

/*
3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+-------
*/

select  *
from (
	select CountryID, CountryName, IsoAlpha3Code, CAST([IsoNumericCode] AS nvarchar(3)) as IsoNumericCode
	from Application.Countries
) temp
unpivot (Code for typeCode in (IsoAlpha3Code, IsoNumericCode)) 
as unpivotData

/*
4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select CustomerID, CustomerName, StockItemID, UnitPrice, InvoiceDate from
(
	select *, 
	ROW_NUMBER() over (partition by CustomerID, StockItemID order by InvoiceDate desc)
	as last
	from
	(
		select sil.InvoiceID, StockItemID, UnitPrice, s.CustomerID, InvoiceDate, CustomerName,
		DENSE_RANK() over (partition by ContactPersonID order by UnitPrice desc, StockItemID) 
		as number
		from Sales.InvoiceLines as sil
		cross apply(select * from Sales.Invoices as si where sil.InvoiceID = si.InvoiceID) s
		cross apply(select * from Sales.Customers as sc where s.CustomerID = sc.CustomerID) c
	) qwe
	where number <= 2
) t
where last = 1
order by CustomerID, UnitPrice desc
