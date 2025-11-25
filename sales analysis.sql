create table sales(
product_id number,
month number,
unit_sales number,
product_name varchar2(100),
supply_time number,
quantity_on_hand number
);

//total sales for each product
select product_name, sum(unit_sales)as total_sales
from sales
group by product_name;

//month in which a product has highest sales
select month, product_name, unit_sales
from(
select month, product_name, unit_sales,
rank() over(partition by product_name order by unit_sales desc) as rnk
from sales)
where rnk=1;

//month in which a product has low quantity on hand
select month, product_name, quantity_on_hand
from(
select month, product_name, quantity_on_hand,
rank() over(partition by product_name order by quantity_on_hand) as rnk
from sales)
where rnk=1;

//average supply time for each product
select product_name, avg(supply_time) as average_supply_time
from sales
group by product_name;

//identifying the month where quantity in hand is more with less sales
select month, product_name, unit_sales, quantity_on_hand
from(
select month, product_name, unit_sales, quantity_on_hand,(quantity_on_hand - unit_sales) as diff,
rank() over(partition by product_name order by (quantity_on_hand - unit_sales)desc)as rnk
from sales)
where rnk=1;

//analyzing maximum and minimum quantity of a product in an year
select product_name, max(quantity_on_hand) as max_quantity, min(quantity_on_hand) as min_quantity
from sales
group by product_name;

//pl/sql to check if required quantity is available or not
create or replace function check_stock(
    f_quantity in number,
    f_product  in varchar2,
    f_month in varchar2
) return varchar2
is
    stock  number;
    status varchar2(100);
begin
    select quantity_on_hand into stock
    from sales
    where lower(product_name) = lower(f_product) and lower(f_month) = lower(month);

    if stock = 0 then
        status := 'out of stock';
    elsif stock < f_quantity then
        status := 'low stock: only ' || stock || ' units available';
    else
        status := 'sufficient stock (' || stock || ' units available)';
    end if;
    return status;
end;
/

//calling the check_Stock function
set serveroutput on;
declare
  v_msg varchar2(200);
  quant number := '&quantity';
  prod varchar2(100) := '&product_name';
  month_num number := '&month';
begin
  v_msg := check_stock(quant, prod, month_num);
  dbms_output.put_line(v_msg);
end;
/

//return total sales of a product in the total year
create or replace function total_sales(
    func_prod in varchar2
) return number
is
    total_sales number;
begin
    select sum(unit_sales)
    into total_sales
    from sales
    where lower(product_name) = lower(func_prod);
return total_sales;
end;
/

//calling the total_sales function and consider user input
declare
    total number;
    prod varchar2(100) := '&product_name';
begin
    total := total_sales(prod);
    dbms_output.put_line('total sales of ' || prod || ' : ' || total);
end;
/

//retrieve the month that has highest sales for a given product
create or replace function highest_sales(
    f_prod in varchar2
) return varchar2
is
    v_sales number;
    v_month varchar2(50);
    v_result varchar2(200);
begin
    select unit_sales, month
    into v_sales, v_month
    from sales
    where lower(product_name) = lower(f_prod)
      and unit_sales = (
          select max(unit_sales)
          from sales
          where lower(product_name) = lower(f_prod)
      );
v_result := 'highest sales of ' || f_prod || ' is ' || v_sales || ' in ' || v_month || 'th month';
return v_result;
exception
    when no_data_found then
        return 'no data found for product: ' || f_prod;
end;
/

//calling the highest_sales function
set serveroutput on;
declare
    v_msg varchar2(200);
    prod varchar2(100) := '&product_name';
begin
    v_msg := highest_sales(prod);
    dbms_output.put_line(v_msg);
end;
/

//display unit sales when month and the product name is given by the user
create or replace function monthly_sales(
f_month in number,
f_product in varchar2
)return varchar2
is 
v_sales varchar2(100);
v_res varchar2(100);
begin
select unit_sales into v_sales
from sales
where lower(product_name)=lower(f_product) and month=f_month;
if f_month=1 then 
v_res := 'unit sales of ' || f_product ||' in ' || f_month || 'st month: ' ||v_sales;
elsif f_month=2 then 
v_res := 'unit sales of ' || f_product ||' in ' || f_month || 'nd month: ' ||v_sales;
elsif f_month=3 then
v_res := 'unit sales of ' || f_product ||' in ' || f_month || 'rd month: ' ||v_sales;
else
v_res := 'unit sales of ' || f_product ||' in ' || f_month || 'th month: ' ||v_sales;
end if;
return v_res;
end;
/

//calling the monthly_sales function
set serveroutput on;
declare
v_msg varchar2(100);
prod varchar2(100) := '&product_name';
month number := '&month';
begin
v_msg := monthly_sales(month, prod);
dbms_output.put_line(v_msg);
end;
/





