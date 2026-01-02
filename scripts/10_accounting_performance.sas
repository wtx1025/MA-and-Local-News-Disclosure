data mna_media; 
	set PROC.mna_media_ivol; 
run;

proc import datafile="&data.\ap_compustat_data.csv"
	dbms=csv 
	out=comp_data 
	replace; 
run;

data comp_data(drop=costat curcd datafmt indfmt consol); 
	set comp_data; 
	if indfmt='INDL'; 
run;

/*Build accounting performance measure*/ 
/*post1, post2 (industry adjusted)*/

data comp_data; 
	set comp_data; 
	gvkey_char = put(gvkey, z6.); 
run;

proc sort data=comp_data;
	by gvkey fyear;
run;

data comp_data;
	set comp_data;
	by gvkey fyear;

	at_lag = lag(at);
	ceq_lag = lag(ceq);
	seq_lag = lag(seq);
	if first.gvkey then at_lag = .;
	if first.gvkey then ceq_lag = .;
	if first.gvkey then seq_lag = .;

	roa = ib  / at_lag;
	roe = ib / seq_lag;
run;

/*Industry-adjusted performance*/ 

data comp_data;
	set comp_data;
	sic2 = floor(sich/100);
run; 

proc sort data=comp_data;
	by fyear sic2;
run;

proc means data=comp_data noprint;
	by fyear sic2;
	var roa roe; 
	output out=ind_bench
	median= roa_ind roe_ind
	n= n_roa n_roe 
run;

proc sql;
    create table comp_data_ia as
    select 
        a.*,
        b.roa_ind, b.roe_ind, b.n_roa, b.n_roe,
	    (a.roa - b.roa_ind)  as roa_ia, (a.roe - b.roe_ind) as roe_ia 

    from comp_data as a left join ind_bench as b
    on a.sic2  = b.sic2 and a.fyear = b.fyear; 
quit;

data comp_data_ia;
	set comp_data_ia;

	if n_roa  < 80 then roa_ia  = .; /*drop observations in group with only little firms*/
	if n_roe  < 80 then roe_ia  = .; /*drop observations in group with only little firms*/
run;

/*Merge back to M&A sample*/ 
proc sql;
	create table mna_media_ap as 
	select a.*, b.roa_ia as roa_post2, b.roe_ia as roe_post2, b.n_roa, b.n_roe, b.datadate
	from mna_media as a left join comp_data_ia as b 
	on a.a_gvkey = b.gvkey_char and b.datadate > a.d_eff;
quit;

proc sort data=mna_media_ap;
	by dealid datadate;
run;

data mna_media_ap(drop=ord datadate);
	set mna_media_ap;
	by dealid datadate;

	retain ord;
	if first.dealid then ord = 0;
	ord + 1;

	if ord = 2 then output;  
run;

proc sql;
	create table mna_media_ap as 
	select a.*, b.roa_ia as roa_post1, b.roe_ia as roe_post1, b.n_roa, b.n_roe, b.datadate
	from mna_media_ap as a left join comp_data_ia as b 
	on a.a_gvkey = b.gvkey_char and b.datadate > a.d_eff;
quit;

proc sort data=mna_media_ap;
	by dealid datadate;
run;

data mna_media_ap(drop=ord datadate);
	set mna_media_ap;
	by dealid datadate;

	retain ord;
	if first.dealid then ord = 0;
	ord + 1;

	if ord = 1 then output;  
run;

/*Pre-roa*/
proc sql;
	create table mna_media_ap as 
	select a.*, b.roa_ia as roa_pre3, b.roe_ia as roe_pre3, b.datadate
	from mna_media_ap as a left join comp_data_ia as b 
	on a.a_gvkey = b.gvkey_char and b.datadate < a.d_eff;
quit;

proc sort data=mna_media_ap;
	by dealid descending datadate;
run;

data mna_media_ap(drop=ord datadate);
	set mna_media_ap;
	by dealid descending datadate;

	retain ord;
	if first.dealid then ord = 0;
	ord + 1;

	if ord = 3 then output;  
run;

proc sql;
	create table mna_media_ap as 
	select a.*, b.roa_ia as roa_pre2, b.roe_ia as roe_pre2, b.datadate
	from mna_media_ap as a left join comp_data_ia as b 
	on a.a_gvkey = b.gvkey_char and b.datadate < a.d_eff;
quit;

proc sort data=mna_media_ap;
	by dealid descending datadate;
run;

data mna_media_ap(drop=ord datadate);
	set mna_media_ap;
	by dealid descending datadate;

	retain ord;
	if first.dealid then ord = 0;
	ord + 1;

	if ord = 2 then output;  
run;

proc sql;
	create table mna_media_ap as 
	select a.*, b.roa_ia as roa_pre1, b.roe_ia as roe_pre1, b.datadate
	from mna_media_ap as a left join comp_data_ia as b 
	on a.a_gvkey = b.gvkey_char and b.datadate < a.d_eff;
quit;

proc sort data=mna_media_ap;
	by dealid descending datadate;
run;

data mna_media_ap(drop=ord datadate);
	set mna_media_ap;
	by dealid descending datadate;

	retain ord;
	if first.dealid then ord = 0;
	ord + 1;

	if ord = 1 then output;  
run;

%winsor(
    dsetin  = mna_media_ap,
    vars    = roa_post2 roe_post2 roa_post1 roe_post1 roa_pre2 roe_pre2 roa_pre1 roe_pre1 
			  roa_pre3 roe_pre3,
    type    = winsor,
    pctl    = 1 99                                                                                                                                                                  
);

data mna_media_ap;
	set mna_media_ap;
	if n(roa_post1, roa_post2) >= 2 then roa_post = mean(roa_post1,roa_post2);
	if n(roa_pre1, roa_pre2, roa_pre3) >=3 then roa_pre = mean(roa_pre1, roa_pre2, roa_pre3);
	if n(roe_post1, roe_post2) >= 2 then roe_post = mean(roe_post1,roe_post2);
	if n(roe_pre1, roe_pre2, roe_pre3) >= 3 then roe_pre = mean(roe_pre1, roe_pre2, roe_pre3);
	roa_diff = roa_post - roa_pre;
	roe_diff = roe_post - roe_pre;
run;

data mna_media_ap;
	set mna_media_ap;
	if y_ann_num >= 2005;
run;

/*Export data*/ 
data PROC.mna_media_ap;
    set mna_media_ap; 
run; 

proc export data=PROC.mna_media_ap 
	outfile="&proc.\mna_media_ap.csv"
	dbms=csv 
	replace; 
	putnames=yes; 
run;

/*
%winsor(
    dsetin  = mna_media_ap,
    vars    = roa_post2 roe_post2 roa_post1 roe_post1 roa_pre2 roe_pre2 roa_pre1 roe_pre1 roa_pre3 roe_pre3,
    type    = winsor,
    pctl    = 1 99                                                                                                                                                                  
);
*/ 