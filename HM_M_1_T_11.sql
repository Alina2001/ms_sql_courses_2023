--Проект

-- категория товара
create table category (
	id_1 int,
	name_category varchar(MAX)
);

-- подкатегория
create table category_group (
	id_2 int,
	name_category_group varchar(MAX)
);

-- товар
create table goods (
	id_3 int,
	name_goods varchar(MAX)
);

-- поставщик
create table supliers (
	id_4 int,
	name_supplier varchar(MAX)
);

--склад \\ дата прибытия или убытия товара
create table warehouse_history (
	id_goods int,
	quantiry int,
	date_delivered date
);

-- продавцы
create table sellers (
	id_5 int,
	name_surname varchar(MAX),
	pasport int,
	data_come date,
	position varchar(MAX)
);

-- товар - продавец
create table goods_supliers (
	id_goods int,
	id_supliers int,
	quantity int,
	date_delivery date
);

-- продажа
create table sales (
	invoice int,
	id_goods int,
	quantity int,
	price int,
	date_ date,
	id_seller int
);

--доп. таб.
create table cat_cat_group (
	id_1 int,
	id_2 int
);

create table cat_group_good (
	id_2 int,
	id_3 int
);
