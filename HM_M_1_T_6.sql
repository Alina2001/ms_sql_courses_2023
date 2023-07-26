/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "06 - Оконные функции".

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
1. Сделать расчет суммы продаж нарастающим итогом по месяцам с 2015 года 
(в рамках одного месяца он будет одинаковый, нарастать будет в течение времени выборки).
Выведите: id продажи, название клиента, дату продажи, сумму продажи, сумму нарастающим итогом

Пример:
-------------+----------------------------
Дата продажи | Нарастающий итог по месяцу
-------------+----------------------------
 2015-01-29   | 4801725.31
 2015-01-30	 | 4801725.31
 2015-01-31	 | 4801725.31
 2015-02-01	 | 9626342.98
 2015-02-02	 | 9626342.98
 2015-02-03	 | 9626342.98
Продажи можно взять из таблицы Invoices.
Нарастающий итог должен быть без оконной функции.
*/

with temp as(
	select si.InvoiceID, si.ContactPersonID, si.InvoiceDate, 
	sum(UnitPrice) as sumAll  
	from Sales.Invoices as si
	join Sales.InvoiceLines as sil
	on si.InvoiceID = sil.InvoiceID
	group by si.InvoiceID, si.ContactPersonID, si.InvoiceDate
)

select InvoiceID, ContactPersonID, CustomerName, InvoiceDate, sumAll, 
(
	select sum(sumAll) from temp as t
	where t.InvoiceDate <= temp.InvoiceDate and temp.InvoiceID >= t.InvoiceID 
) 
as sumBefore 
from temp
join Sales.Customers as sc
on sc.CustomerID = ContactPersonID 
order by InvoiceDate, InvoiceID

/*
2. Сделайте расчет суммы нарастающим итогом в предыдущем запросе с помощью оконной функции.
   Сравните производительность запросов 1 и 2 с помощью set statistics time, io on
*/

with temp as(
	select si.InvoiceID, si.ContactPersonID, si.InvoiceDate, sum(UnitPrice) as sumAll
	from Sales.Invoices as si
	join Sales.InvoiceLines as sil
	on si.InvoiceID = sil.InvoiceID
	group by si.InvoiceID, si.ContactPersonID, si.InvoiceDate
)

select *, 
sum(sumAll) over (order by InvoiceID, InvoiceDate) as sumBefore
from temp
order by InvoiceID, InvoiceDate

/*
3. Вывести список 2х самых популярных продуктов (по количеству проданных) 
в каждом месяце за 2016 год (по 2 самых популярных продукта в каждом месяце).
*/

select StockItemName, month, numberPopular from (
	select *,
	ROW_NUMBER() over (partition by month 
	order by QuantityAll desc) as numberPopular
	from (select distinct StockItemID, month(InvoiceDate) as month,
		sum(Quantity) over (partition by StockItemID, month(InvoiceDate) 
		order by StockItemID) as QuantityAll
		from Sales.InvoiceLines as sil
		join Sales.Invoices as si
		on sil.InvoiceID = si.InvoiceID) q
		) w
join Warehouse.StockItems as wsi
on w.StockItemID = wsi.StockItemID
where numberPopular <= 2
order by month, numberPopular


/*
4. Функции одним запросом
Посчитайте по таблице товаров (в вывод также должен попасть ид товара, название, брэнд и цена):
* пронумеруйте записи по названию товара, так чтобы при изменении буквы алфавита нумерация начиналась заново
* посчитайте общее количество товаров и выведете полем в этом же запросе
* посчитайте общее количество товаров в зависимости от первой буквы названия товара
* отобразите следующий id товара исходя из того, что порядок отображения товаров по имени 
* предыдущий ид товара с тем же порядком отображения (по имени)
* названия товара 2 строки назад, в случае если предыдущей строки нет нужно вывести "No items"
* сформируйте 30 групп товаров по полю вес товара на 1 шт
Для этой задачи НЕ нужно писать аналог без аналитических функций.
*/

select *,
LEAD(FirstLetter) over (order by FirstLetter, StockItemName) as next,
LAG(FirstLetter) over (order by FirstLetter, StockItemName ) as last,
first_value(StockItemName) over (order by FirstLetter, StockItemName rows between 2 preceding and current row) 
as name_2_ago,
NTILE(30) over (order by FirstLetter, StockItemName) as group_
from 
(
	select StockItemID, StockItemName, Brand, UnitPrice,
	RANK() over (order by substring(StockItemName, 1, 1)) as FirstLetter,
	COUNT(StockItemID) over () as AllStock,
	COUNT(substring(StockItemName, 1, 1)) over (order by substring(StockItemName, 1, 1))
	as AllSameLetter
	from Warehouse.StockItems
) qwe
order by FirstLetter, StockItemName

/*
5. По каждому сотруднику выведите последнего клиента, которому сотрудник что-то продал.
   В результатах должны быть ид и фамилия сотрудника, ид и название клиента, дата продажи, сумму сделки.
*/

select SalespersonPersonID, FullName, 
ContactPersonID, CustomerName,
InvoiceDate, sum from (
	select SalespersonPersonID, ap.FullName, 
	ContactPersonID, sc.CustomerName,
	InvoiceDate, sum(UnitPrice) as sum,
	ROW_NUMBER() over (partition by SalespersonPersonID order by InvoiceDate desc)
	as number
	from Sales.Invoices as si
	join Sales.InvoiceLines as sil
	on si.InvoiceID = sil.InvoiceID
	join Application.People as ap
	on SalespersonPersonID = ap.PersonID
	join Sales.Customers as sc
	on sc.CustomerID = ContactPersonID
	group by si.InvoiceID, SalespersonPersonID, ContactPersonID, 
	ap.FullName,sc.CustomerName,InvoiceDate
) qwe
where number = 1
order by SalespersonPersonID, InvoiceDate

/*
6. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки.
*/

select ContactPersonID, CustomerName, StockItemID, UnitPrice, InvoiceDate from
(
	select *, 
	ROW_NUMBER() over (partition by ContactPersonID, StockItemID order by InvoiceDate desc)
	as last
	from
	(
		select ContactPersonID, CustomerName, StockItemID, UnitPrice, InvoiceDate,
		DENSE_RANK() over (partition by ContactPersonID order by UnitPrice desc, StockItemID) 
		as number
		from Sales.Invoices as si
		join Sales.InvoiceLines as sil
		on si.InvoiceID = sil.InvoiceID
		join Sales.Customers as sc
		on si.ContactPersonID = sc.CustomerID
	) qwe
	where number <= 2
) t
where last = 1
order by ContactPersonID, UnitPrice desc
