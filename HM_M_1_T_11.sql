--Проект

-- товар
create table goods (
	id_3 int not null identity(1, 1) primary key,
	name_category varchar(MAX) not null,
	name_category_group varchar(MAX),
	name_goods varchar(MAX) not null
);

-- Название товаров только с большой буквы
ALTER TABLE goods 
	ADD CONSTRAINT check_name_goods 
		CHECK (SUBSTRING(name_goods, 1, 1) >= 'A' and SUBSTRING(name_goods, 1, 1) <= 'Z');

-- поставщик
create table supliers (
	id_4 int not null identity(1, 1) primary key,
	name_supplier varchar(MAX)
);

-- Название постащика только с большой буквы
ALTER TABLE supliers 
	ADD CONSTRAINT check_name_supliers
		CHECK (SUBSTRING(name_supplier, 1, 1) >= 'A' and SUBSTRING(name_supplier, 1, 1) <= 'Z');

--склад \\ дата прибытия или убытия товара
create table warehouse_history (
	id_goods int,
	quantiry int,
	date_delivered date
);

-- Только сегодняшнюю дату можно добавить
ALTER TABLE warehouse_history 
	ADD CONSTRAINT check_data_warehouse_history
		CHECK (date_delivered = GETDATE());

-- продавцы
create table sellers (
	id_5 int not null identity(1, 1) primary key,
	name_surname varchar(MAX),
	pasport int,
	data_come date,
	position varchar(MAX)
);

-- Название продавца только с большой буквы
ALTER TABLE sellers 
	ADD CONSTRAINT check_name_supliers
		CHECK (SUBSTRING(name_surname, 1, 1) >= 'A' and SUBSTRING(name_surname, 1, 1) <= 'Z');

-- товар - продавец
create table goods_supliers (
	id_goods int FOREIGN KEY REFERENCES goods(id_3),
	id_supliers int FOREIGN KEY REFERENCES supliers(id_4),
	quantity int,
	price int,
	date_delivery date
);

-- Если кол-во больше нуля
ALTER TABLE goods_supliers 
	ADD CONSTRAINT check_quantity_goods_supliers 
		CHECK (quantity > 0);

-- продажа
create table sales (
	invoice int not null identity(1, 1) primary key,
	id_goods int FOREIGN KEY REFERENCES goods(id_3),
	quantity int,
	price int,
	date_ date,
	id_seller int
);

-- Если цена больше нуля
ALTER TABLE sales 
	ADD CONSTRAINT check_price_sales
		CHECK (price > 0);

create index idx_fio_seller on sellers (id_5);
