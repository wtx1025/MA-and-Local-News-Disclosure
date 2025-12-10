********************************************************************************;
* Last Update: 2025/11													       *;
* This SAS code computes the analyst coverage for target usomg I/B/E/S data    *;                                            																			*;
********************************************************************************;

*********************
Part 1 : Import data
*********************;
data crsp_comp_link; 
	set DAT.comp_crsp_00_23; 
run;

data mna_media; 
	set PROC.mna_media_distance; 
run;

proc import datafile="&data.\ibes_data.csv" 
	dbms=csv 
	out=ibes_data
	replace;
	guessingrows=10000;
run;

proc import datafile="&data.\ibes_crsp_link.csv" 
	dbms=csv
	out=ibes_crsp_link
	replace;
	guessingrows=10000;
run;

proc import datafile="&data.\sich_data.csv" 
	dbms=csv 
	out=sich_data
	replace;
	guessingrows=1000;
run;

************************************************
Part 2 : Select day of calculating coverage
************************************************;
data ibes_data;
    set ibes_data;
    fyear_ibes = year(fpedats);
	year = year(statpers);
    diff = fpedats - statpers;          
    if 0 <= diff <= 90;                 
    format statpers fpedats date9.;
run;

proc sort data=ibes_data;
    by ticker fyear_ibes statpers;
run;

data ibes_year_last;
    set ibes_data;
    by ticker fyear_ibes;
    if first.fyear_ibes then output;    
run; 

************************************************
Part 3 : Calculate coverage and dispersion
************************************************;

data ibes_year_last;
	set ibes_year_last;
	if meanest ne 0 then disp = stdev / abs(meanest);
	else disp = .;

	if not missing(disp) and abs(disp) > 3 then disp = .;
	if NUMEST < 3 then disp = .;
run; 

*****************************************************************
Part 4 : Generate percentile ranking and merge with M&A sample
*****************************************************************;

*Merge with CRSP; 
proc sql;
    create table ibes_year_perm as
    select  a.*, b.permno
    from    ibes_year_last as a
    left join ibes_crsp_link as b
      on    a.ticker   = b.ticker
     and    a.statpers between b.sdate and b.edate
     and    b.score = 1;
quit;

*Merge with Compustat; 
proc sql;
    create table full_panel as
    select  a.*, b.gvkey, b.fyear
    from ibes_year_perm as a left join crsp_comp_link as b
      on  a.permno = b.permno and a.fyear_ibes = b.fyear;
quit;

*Generate percentile ranking;
data sich_data; 
	set sich_data; 
	if 0 <= sich <= 9999 then sic2 = floor(sich/100); 
	else sic2 = .;
	gvkey_char = put(gvkey, z6.); 
run;

proc sql;
	create table full_panel as 
	select a.*, b.sic2 from 
	full_panel as a left join sich_data as b 
	on a.gvkey = b.gvkey_char and a.year = b.fyear;
run; 

proc sort data=full_panel;
    by year;
run;

proc rank data=full_panel groups=100 out=full_panel ties=mean;
    by year;
    var numest disp;                     
    ranks numest_pct disp_pct;        
run;

*Merge with M&A data;  
proc sql;
	create table mna_media_ibes as 
	select a.*, b.numest, b.disp, b.numest_pct, b.disp_pct from
	mna_media as a left join full_panel as b 
	on a.t_gvkey = b.gvkey and a.y_ann_num - 1 = b.fyear;
quit;

***********************
Part 5 : Export data
***********************;
data PROC.mna_media_ibes; 
	set mna_media_ibes; 
run;
 
proc export data=PROC.mna_media_ibes outfile="&proc.\mna_media_ibes.csv"  
	dbms=csv 
	replace; 
	putnames=yes; 
run;