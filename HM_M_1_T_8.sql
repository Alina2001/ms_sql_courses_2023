/*
Домашнее задание по курсу MS SQL Server Developer в OTUS.

Занятие "08 - Выборки из XML и JSON полей".

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
Примечания к заданиям 1, 2:
* Если с выгрузкой в файл будут проблемы, то можно сделать просто SELECT c результатом в виде XML. 
* Если у вас в проекте предусмотрен экспорт/импорт в XML, то можете взять свой XML и свои таблицы.
* Если с этим XML вам будет скучно, то можете взять любые открытые данные и импортировать их в таблицы (например, с https://data.gov.ru).
* Пример экспорта/импорта в файл https://docs.microsoft.com/en-us/sql/relational-databases/import-export/examples-of-bulk-import-and-export-of-xml-documents-sql-server
*/


/*
1. В личном кабинете есть файл StockItems.xml.
Это данные из таблицы Warehouse.StockItems.
Преобразовать эти данные в плоскую таблицу с полями, аналогичными Warehouse.StockItems.
Поля: StockItemName, SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit, LeadTimeDays, IsChillerStock, TaxRate, UnitPrice 

Загрузить эти данные в таблицу Warehouse.StockItems: 
существующие записи в таблице обновить, отсутствующие добавить (сопоставлять записи по полю StockItemName). 

Сделать два варианта: с помощью OPENXML и через XQuery.
*/

-- Переменная, в которую считаем XML-файл
DECLARE @xmlDocument XML;

-- Считываем XML-файл в переменную
-- !!! измените путь к XML-файлу
SELECT @xmlDocument = BulkColumn
FROM OPENROWSET
(BULK 'C:\Users\Pasal\Downloads\StockItems.xml', 
 SINGLE_CLOB)
AS data;

-- Проверяем, что в @xmlDocument
SELECT @xmlDocument AS [@xmlDocument];

DECLARE @docHandle INT;
EXEC sp_xml_preparedocument @docHandle OUTPUT, @xmlDocument;

-- docHandle - это просто число
SELECT @docHandle AS docHandle;

DROP TABLE IF EXISTS #Orders;

CREATE TABLE #Orders(
	[SupplierID] INT,
	[StockItemName] NVARCHAR(100),
	[UnitPackageID] INT,
	[OuterPackageID] INT,
	[QuantityPerOuter] INT,
	[TypicalWeightPerUnit] float,
	[LeadTimeDays] INT,
	[IsChillerStock] INT,
	[TaxRate] float,
	[UnitPrice] NVARCHAR(100)
	);


INSERT INTO #Orders
SELECT *
FROM OPENXML(@docHandle, N'/StockItems/Item')
WITH ( 
	[SupplierID] INT 'SupplierID',
	[StockItemName] NVARCHAR(100) '@Name',
	[UnitPackageID] INT 'Package/UnitPackageID',
	[OuterPackageID] INT 'Package/OuterPackageID',
	[QuantityPerOuter] INT 'Package/QuantityPerOuter',
	[TypicalWeightPerUnit] float 'Package/TypicalWeightPerUnit',
	[LeadTimeDays] INT 'LeadTimeDays',
	[IsChillerStock] INT 'IsChillerStock',
	[TaxRate] float 'TaxRate',
	[UnitPrice] NVARCHAR(100) 'UnitPrice'
	);

select * from #Orders
where StockItemName not in (select StockItemName COLLATE Cyrillic_General_CI_AS from Warehouse.StockItems)
order by SupplierID, UnitPackageID, OuterPackageID, QuantityPerOuter, TypicalWeightPerUnit

update SI
set  si.[SupplierID] = o.[SupplierID],
si.UnitPackageID = o.UnitPackageID,
si.OuterPackageID = o.OuterPackageID,
si.QuantityPerOuter = o.QuantityPerOuter,
si.TypicalWeightPerUnit = o.TypicalWeightPerUnit,
si.LeadTimeDays = o.LeadTimeDays,
si.IsChillerStock = o.IsChillerStock,
si.TaxRate = o.TaxRate,
si.UnitPrice = o.UnitPrice
from Warehouse.StockItems SI 
join #Orders O on O.StockItemName=SI.StockItemName
COLLATE Cyrillic_General_CI_AS

alter table #orders add LastEditedBy int
update #Orders
set LastEditedBy = 1

insert into Warehouse.StockItems
(SupplierID,
StockItemName,
UnitPackageID,
OuterPackageID,
QuantityPerOuter,
TypicalWeightPerUnit,
LeadTimeDays,
IsChillerStock,
TaxRate,
UnitPrice,
LastEditedBy)
select * 
from #orders as o 
where o.StockItemName not in (select StockItemName COLLATE Cyrillic_General_CI_AS from Warehouse.StockItems) 


/*
2. Выгрузить данные из таблицы StockItems в такой же xml-файл, как StockItems.xml
*/

Select * from Warehouse.StockItems
for xml path('Item'), ROOT('StockItems')

/*
3. В таблице Warehouse.StockItems в колонке CustomFields есть данные в JSON.
Написать SELECT для вывода:
- StockItemID
- StockItemName
- CountryOfManufacture (из CustomFields)
- FirstTag (из поля CustomFields, первое значение из массива Tags)
*/

select StockItemID, 
StockItemName,
json_value(CustomFields, '$.CountryOfManufacture') as CountryOfManufacture,
json_value(wsi.CustomFields, '$.Tags[0]') as FirstTag
from Warehouse.StockItems as si


/*
4. Найти в StockItems строки, где есть тэг "Vintage".
Вывести: 
- StockItemID
- StockItemName
- (опционально) все теги (из CustomFields) через запятую в одном поле

Тэги искать в поле CustomFields, а не в Tags.
Запрос написать через функции работы с JSON.
Для поиска использовать равенство, использовать LIKE запрещено.

Должно быть в таком виде:
... where ... = 'Vintage'

Так принято не будет:
... where ... Tags like '%Vintage%'
... where ... CustomFields like '%Vintage%' 
*/

select si.StockItemID, si.StockItemName, json_query(si.CustomFields, '$.Tags') from Warehouse.StockItems as si
where EXists(select Tags.value from Warehouse.StockItems as wsi
cross apply openjson(wsi.CustomFields, '$.Tags') Tags
where wsi.StockItemName = si.StockItemName and Tags.value = 'Vintage')

