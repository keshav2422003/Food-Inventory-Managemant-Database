drop database if exists food_inventory_management;
create database food_inventory_management;
use food_inventory_management;

-- stores food item details
create table items(
	id int primary key auto_increment,
    items varchar(100),
    category enum("liquid","food","fruit") not null,
    unit_price int not null,
    total_stock int null
);
-- supplier information
create table supplier(
	id int primary key auto_increment ,
    supplier_name varchar(100) not null,
    contact_number bigint
);
-- places name where item can be delivered
create table available_place(
	place_id int primary key auto_increment ,
    place enum("Noida" , "Delhi", "Gaziabad" , "Goa") not null
);

-- tracks current stock
create table stock_table(
	stock_id varchar(10) primary key,
    item_id int not null,
    available_stock int not null,
    foreign key (item_id) references items(id)
);

-- records food purchases
create table order_details(order_details
	order_id int primary key auto_increment,
    customer_name varchar(50),
    order_item_id int not null,
    order_date timestamp default current_timestamp,
    supplier_id int not null,
    order_quentity int not null,
    sales_channel enum("store","online"),
    amount int not null,
    place_id int not null,
    foreign key (order_item_id) references items(id),
    foreign key (supplier_id) references supplier(id),
    foreign key (place_id) references available_place(place_id)
);
truncate table available_place;
alter table order_details drop constraint order_details_ibfk_3;
alter table order_details add constraint add_fk_availablePlace foreign key(place_id) references available_place(place_id);

alter table stock_table add column last_update_time timestamp ;
update items set total_stock = total_stock + 5 where id = 1;


select * from available_place;
select * from items;
select * from supplier;
select * from stock_table;
select * from order_details;

drop table available_place;
SHOW TABLES LIKE 'available_place';


-- updating all stocks in 'stock_table' Table  -- only one time run 
UPDATE stock_table
        JOIN
    items ON stock_table.item_id = items.id 
SET 
    stock_table.available_stock = COALESCE(items.total_stock,
            stock_table.available_stock);

-- Trigger >-- Auto increment stock Id
delimiter // 
create trigger before_insert_stock_id
before insert on stock_table
for each row
begin
    set new.stock_id = concat("S" , (select ifnull(max(cast(substr(stock_id , 2) as unsigned )),0) +1 from stock_table) );  
end //
delimiter ;

-- Trigger >-- Auto insert new item in stock . (Insert row)item.item_id and their total stock in stock_table with adding a new row of new item
delimiter //
create trigger insert_new_stock_item
after insert on items
for each row
begin 
	insert into stock_table(item_id , available_stock) select new.id , new.total_stock;   -- when insert only one row we can use 'select' command and when we have multiple row to insert we use 'value' along with insert
     -- (easy method) INSERT INTO stock_table(item_id, available_stock) VALUES (NEW.id, NEW.total_stock);

end //    
delimiter ; 

-- drop trigger insert_new_stock_item;	
	
-- Trigger >-- after purchase quentity , remaining stock in will be updated in stock_table
delimiter //            
create trigger update_available__stock
after insert on order_details
for each row
begin 
		declare item_id_var varchar(100);
        set item_id_var = (select order_item_id from order_details order by order_id desc limit 1);
		update stock_table set available_stock = (select total_stock from items where id = item_id_var) - (select sum(order_quentity) from order_details  where item_id = item_id_var) where item_id = item_id_var;
end//
delimiter ;     

-- Trigger >-- total price(cash, amount) will be automatic add(insert) in order_details table when a person buy something and add their information in order_detail table
delimiter //
create trigger auto_sum_amount
before insert on order_details
for each row
begin 
	set new.amount = new.order_quentity * (select unit_price from items where  id = new.order_item_id);
end //   
delimiter ;   

drop trigger update_available__stock;
insert into order_details(order_item_id ,supplier_id,order_quentity ,   place_id)
values(3 , 3 , 2 ,  3);

-- Trigger ># update stock in main table(items table) , items stock will be also update in stock_table (with increase or decrease stock value)
delimiter //
create trigger update_total_stock
after update on items
for each row 
begin 
	declare var int;
	set var = new.total_stock - old.total_stock;
    if var >0 then
    update stock_table set available_stock = available_stock + var where stock_table.item_id = new.id;
    end if;
    if var < 0 then
    update stock_table  set available_stock = available_stock + var where stock_table.item_id = new.id;
    end if;
end //    
delimiter ;
update items set total_stock = total_stock - 30 where id = 2;
update items set total_stock = total_stock + 30 where id = 3;

-- Trigger >-- Generate error when items stock is not available
delimiter //
create trigger generate_error_of_stock 
before insert on order_details
for each row
begin
    -- Check if stock is zero    
    if (select available_stock from stock_table where item_id = new.order_item_id)  = 0 then
       signal sqlstate "45000"
       set message_text = "item quentity is  zero";
	end if;
	-- Check if order quantity exceeds available stock
	if new.order_quentity > (select available_stock from stock_table where item_id = new.order_item_id) then
		signal sqlstate "45000"
        set message_text =  "low item quentity";
    end if;
end//
delimiter ;
drop trigger generate_error_of_stock;
-- insert into order_details(order_item_id , supplier_id , order_quentity , place_id)
-- 	values (1 , 3 , 40 , 1);

-- Trigger >-- always update time, date whenever anything is updated in table
delimiter //    
create trigger update_stock_time_when_update
before update on stock_table 
for each row   
begin 
 set new.last_update_time = now();
 end//
delimiter ;

-- Trigger >-- update_stock_time_when_insert  , always update time, date whenever anything is inserted in a table
delimiter //    
create trigger update_stock_time_when_insert
before insert on stock_table 
for each row   
begin 
 set new.last_update_time = now();
 end//
delimiter ;

update items set total_stock = total_stock+10 where id = 1;
select * from stock_table;
alter table stock_table drop column new_update_time;

-- ------------------------------------------------- 
select * from items;         
SELECT 
    stock_table.stock_id,
    stock_table.item_id,
    items.items,
    items.total_stock,
    stock_table.available_stock
FROM
    stock_table
        INNER JOIN
    items ON stock_table.item_id = items.id;        
        
show databases;    

select * from items;
insert into items(id , items , category, unit_price , total_stock) values(17 , "water" ,"liquid" , 20, 100);
update items set total_stock = total_stock+10 where id = 15;
desc items;
select * from stock_table;
drop trigger stock_update_time_on_insert;
drop trigger stock_update_time;    
        