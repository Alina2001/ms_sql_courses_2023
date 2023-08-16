/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "10 - Операторы изменения данных".

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
1. Довставлять в базу пять записей используя insert в таблицу Customers или Suppliers 
*/

insert into Purchasing.Suppliers
(SupplierID,SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID,PaymentDays,PhoneNumber,
FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy)
select top 5 SupplierID + 100,SupplierName + '_test',SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID,PaymentDays,PhoneNumber,
FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy
from Purchasing.Suppliers


-- для определения сколько полей в таблице являются обязательными, но не автогенерируемыми
	select string_agg(name, ',') as t from (
		select name from sys.columns
		where object_id = (select OBJECT_ID('Purchasing.Suppliers')) 
		and is_nullable = 0
		and generated_always_type = 0 ) a 


/*
2. Удалите одну запись из Customers, которая была вами добавлена
*/

select top 6 * from Purchasing.Suppliers
order by SupplierID desc

delete from Purchasing.Suppliers
where  SupplierID like '20%'


/*
3. Изменить одну запись, из добавленных через UPDATE
*/

update Purchasing.Suppliers
set SupplierID = 14
where SupplierID = 102

/*
4. Написать MERGE, который вставит вставит запись в клиенты, если ее там нет, и изменит если она уже есть
*/


with temp as
(
	select top 1 SupplierID + 200  as SupplierID,SupplierName + '_test01' as SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID,PaymentDays,PhoneNumber,
		FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy from Purchasing.Suppliers 
)

merge Purchasing.Suppliers as target
using temp
on target.supplierName = temp.supplierName
when matched 
	then update set SupplierID = 210
when not matched 
	then insert
		(SupplierID,SupplierName,SupplierCategoryID,PrimaryContactPersonID,AlternateContactPersonID,DeliveryCityID,PostalCityID,PaymentDays,PhoneNumber,
		FaxNumber,WebsiteURL,DeliveryAddressLine1,DeliveryPostalCode,PostalAddressLine1,PostalPostalCode,LastEditedBy)
		values(temp.SupplierID,temp.SupplierName,temp.SupplierCategoryID,temp.PrimaryContactPersonID,temp.AlternateContactPersonID,temp.DeliveryCityID,temp.PostalCityID,temp.PaymentDays,temp.PhoneNumber,
		temp.FaxNumber,temp.WebsiteURL,temp.DeliveryAddressLine1,temp.DeliveryPostalCode,temp.PostalAddressLine1,temp.PostalPostalCode,temp.LastEditedBy);

/*
5. Напишите запрос, который выгрузит данные через bcp out и загрузить через bulk insert
*/

-- Запуск из командной строки
bcp " SELECT top 1 * from [WideWorldImporters].[Purchasing].[Suppliers]" queryout "C:\Test\test.csv" -T -w -t \t  -S localhost\SQL2023


BULK INSERT Purchasing.Suppliers
FROM 'C:\Test\test.csv'
WITH 
	(
	BATCHSIZE = 1000, 
	DATAFILETYPE = 'widechar',
	FIELDTERMINATOR = '\t',
	ROWTERMINATOR ='\n',
	KEEPNULLS,
	TABLOCK        
	);


