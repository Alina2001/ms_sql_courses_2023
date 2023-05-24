/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "03 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".

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
1. Посчитать среднюю цену товара, общую сумму продажи по месяцам.
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select DATEPART(year, InvoiceDate) as year, DATEPART(MONTH, InvoiceDate) as month,
avg(UnitPrice) as averange, sum(ExtendedPrice) as SUM from Sales.Invoices as i
left join Sales.InvoiceLines as il on i.InvoiceID = il.InvoiceID
group by DATEPART(year, InvoiceDate), DATEPART(MONTH, InvoiceDate)
order by DATEPART(year, InvoiceDate), DATEPART(MONTH, InvoiceDate)


/*
2. Отобразить все месяцы, где общая сумма продаж превысила 4 600 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select DATEPART(year, InvoiceDate) as year, DATEPART(MONTH, InvoiceDate) as month,
sum(ExtendedPrice) as SUM from Sales.Invoices as i
left join Sales.InvoiceLines as il on i.InvoiceID = il.InvoiceID
group by DATEPART(year, InvoiceDate), DATEPART(MONTH, InvoiceDate)
having sum(ExtendedPrice) > 4600000
order by year, month


/*
3. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.
*/

select * from Sales.Invoices
select * from Sales.OrderLines
select * from Sales.Orders
select * from Sales.InvoiceLines

select DATEPART(year, i.InvoiceDate) as year, DATEPART(MONTH, i.InvoiceDate) as month,
s.StockItemName, sum(ExtendedPrice) as sumPrice,  sum(Quantity) as quantity, min(il.LastEditedWhen) as minDate
from Sales.Invoices as i
left join Sales.InvoiceLines as il on i.InvoiceID = il.InvoiceID
left join Warehouse.StockItems as s on il.StockItemID = s.StockItemID
group by DATEPART(year, i.InvoiceDate), DATEPART(MONTH, i.InvoiceDate), s.StockItemName
having sum(Quantity) < 50 
order by year, month 


-- ---------------------------------------------------------------------------
-- Опционально
-- ---------------------------------------------------------------------------
/*
Написать запросы 2-3 так, чтобы если в каком-то месяце не было продаж,
то этот месяц также отображался бы в результатах, но там были нули.
*/
