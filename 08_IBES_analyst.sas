libname CKW2 "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data";
libname CKW "C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results";
%let coordinate_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\zipcode_Census_2000.xlsx;
%let out_file = C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\mna_media_ibes.csv;
%let out = C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\results\; 

/*Read data*/ 
data crsp_comp_link; 
	set CKW2.comp_crsp_00_23; 
run;

data mna_media; 
	set CKW.mna_media_conservatism2; 
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Downloads\\xcjusc5tqttndlkl.csv"
	dbms=csv 
	out=ibes_data
	replace;
	guessingrows=10000;
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Downloads\\ibes_crsp_link.csv"
	dbms=csv
	out=ibes_crsp_link
	replace;
	guessingrows=10000;
run;

proc import datafile="C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\Data\\data\\sich_data.csv"
	dbms=csv 
	out=sich_data
	replace;
	guessingrows=1000;
run;

/*Select representation*/ 
/*
data ibes_data;
    set ibes_data;
	fyear_ibes = year(fpedats);
    year  = year(statpers);              
    year_end  = mdy(12, 31, year);       
	diff_end  = abs(year_end - statpers);   

    format statpers year_end date9.;
run;

proc sort data=ibes_data;
    by ticker year diff_end;  
run;

data ibes_year_last;
    set ibes_data;
    by ticker year;
    if first.year then output; 
run;
*/

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

/*Calculate covergae and dispersion*/

data ibes_year_last;
	set ibes_year_last;
	if meanest ne 0 then disp = stdev / abs(meanest);
	else disp = .;

	if not missing(disp) and abs(disp) > 3 then disp = .;
	if NUMEST < 3 then disp = .;
run; 

/*Merge with CRSP*/ 
proc sql;
    create table ibes_year_perm as
    select  a.*, b.permno
    from    ibes_year_last as a
    left join ibes_crsp_link as b
      on    a.ticker   = b.ticker
     and    a.statpers between b.sdate and b.edate
     and    b.score = 1;
quit;

/*Merge with Compustat*/ 
proc sql;
    create table full_panel as
    select  a.*, b.gvkey, b.fyear
    from ibes_year_perm as a left join crsp_comp_link as b
      on  a.permno = b.permno and a.fyear_ibes = b.fyear;
quit;

/*Generate percentile ranking*/ 

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

/*Merge with M&A data*/ 
proc sql;
	create table mna_media_ibes as 
	select a.*, b.numest, b.disp, b.numest_pct, b.disp_pct from
	mna_media as a left join full_panel as b 
	on a.t_gvkey = b.gvkey and a.y_ann_num - 1 = b.fyear;
quit;

/*Export data*/ 
libname outlib "&out";
data outlib.mna_media_ibes; set mna_media_ibes; run; 
proc export data=outlib.mna_media_ibes outfile="&out_file" dbms=csv replace; putnames=yes; run;
libname outlib clear;
libname CKW clear; 
libname CKW2 clear;