*****************************************************************************;
* Last Update: 2025/9													    *;
* This SAS code construct some of the control variables needed              *;																			*;
*****************************************************************************;

***************************************************
Part 1 - Import mna data, compustat financial data
***************************************************; 
 
data mna_media;
	set PROC.mna_media_big4;
run;

proc import datafile="&data.\additional_compustat_data.csv" 
	dbms=csv 
	out=comp_data
	replace;
run;

data comp_data(drop=costat curcd datafmt indfmt consol);
    set comp_data;
	if indfmt='INDL'; 
run;

*****************************************************
Part 2 - construct liquidity and SaleGR for acquirer
*****************************************************;

proc sort data=comp_data; 
	by gvkey fyear datadate; 
run; 

data comp_data;
	set comp_data;
	by gvkey fyear datadate;
	if last.fyear;
run; 

data comp_data;
	set comp_data;
	by gvkey;
	gvkey_char = put(gvkey, z6.);
	liquidity = (che + lct) / at;

	sale_lag = lag(sale);
	if first.gvkey then sale_lag = .;
	d_sale = (sale - sale_lag) / sale_lag;
run;

proc sort data=comp_data; 
	by gvkey fyear; 
run; 

proc expand data=comp_data out=comp_data method=none;
	by gvkey;
	id fyear;
	convert d_sale = saleGR / transformout = (movave 1);
run;

proc sql;
	create table mna_media_ac as 
	select a.*, b.liquidity as ac_liquidity, b.SaleGR as ac_SaleGR
	from mna_media as a left join comp_data as b 
	on a.a_gvkey = b.gvkey_char and b.fyear = a.y_ann_num - 1;
quit; 

*********************************************
Part 3 - liquidity and SaleGR for target
*********************************************;
 
proc sql;
	create table mna_media_ta as 
	select a.*, b.liquidity as ta_liquidity, b.SaleGR as ta_SaleGR
	from mna_media_ac as a left join comp_data as b 
	on a.t_gvkey = b.gvkey_char and b.fyear = a.y_ann_num - 1;
quit; 

**************************
Part 4 - export the data
**************************;

data PROC.mna_media_final;
    set mna_media_ta; 
run; 

proc export data=PROC.mna_media_final 
	outfile="&proc.\mna_media_final.csv"
	dbms=csv 
	replace; 
	putnames=yes; 
run;
