data mna_media; 
	set PROC.mna_media_ap; 
run;

proc import datafile="&data.\additional_compustat_data2.csv"
	dbms=csv 
	out=comp_data 
	replace; 
	guessingrows = 1000;
run;

data comp_data(drop=costat curcd datafmt indfmt consol); 
	set comp_data; 
	if indfmt='INDL'; 
run;

proc sort data=comp_data; by gvkey; run;
data comp_data;
	set comp_data;
	by gvkey;
	at_lag = lag(at);
	if first.gvkey then at_lag = .;
	if xrd = . then xrd = 0;
	cta = che / at_lag;
	pta = ppent / at_lag;
	xta = xrd / at_lag;
	sta = sale / at_lag;
run;

data comp_data; 
	set comp_data; 
	gvkey_char = put(gvkey, z6.); 
run;

proc sql;
	create table mna_media_ad as
	select a.*, b.cta, b.pta, b.xta, b.sta, b.sale, b.fyear 
	from mna_media as a left join comp_data as b 
	on a.a_gvkey=b.gvkey_char and b.fyear = a.y_ann_num - 1;
quit; 

data mna_media_ad;
	set mna_media_ad(rename=(
		cta = ac_cta pta = ac_pta xta = ac_xta sta = ac_sta sale = ac_sale 
	));
run; 

proc sql;
	create table mna_media_ad as
	select a.*, b.cta, b.pta, b.xta, b.sta, b.sale, b.fyear 
	from mna_media_ad as a left join comp_data as b 
	on a.t_gvkey=b.gvkey_char and b.fyear = a.y_ann_num - 1;
quit; 

data mna_media_ad;
	set mna_media_ad(rename=(
		cta = ta_cta pta = ta_pta xta = ta_xta sta = ta_sta sale = ta_sale
	));
	ac_om = ac_oibdp / ac_sale;
	ta_om = ta_oibdp / ta_sale;
run; 

data PROC.mna_media_ad;
    set mna_media_ad; 
run; 

proc export data=PROC.mna_media_ad 
	outfile="&proc.\mna_media_ad.csv"
	dbms=csv 
	replace; 
	putnames=yes; 
run;