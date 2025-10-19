proc import datafile="C:\\Users\\¤ý«FÒj\\Desktop\\RA\\Kim_Cha\\results\\mna_media_conservatism.csv"
	dbms=csv 
	out = data
	replace;
	guessingrows=500; 
	getnames=yes;
run;

proc means data=data n mean std min p25 median p75 max maxdec=3;
	var combined_car3 combined_car5 a_car3_ffm a_car5_ffm;
run; 

proc means data=data n mean std min p25 median p75 max maxdec=3;
	var Closure Closure_Merge aq_lag1 conservatism;
run; 

proc means data=data n mean std min p25 median p75 max maxdec=3;
	var ta_size ac_size ta_leverage ac_leverage ta_fcf ac_fcf ta_tobinq ac_tobinq
	     ta_roa ac_roa ta_runup ac_runup ta_mtb ac_mtb ta_big4 ac_big4 rel_deal_size
		 ta_SaleGR aq_lag1;
run; 

data data;
	set data;
	if industrymerger = . then industrymerger = 0;
	if both_tech = . then both_tech = 0;
	if toehold = . then toehold = 0;
	if tender = . then tender = 0;
	if multibidder = . then multibidder = 0;
	if cashonly = . then cashonly = 0;
	if stockonly = . then stockonly = 0;
	if hostile = . then hostile = 0;
run;

proc means data=data n mean std min p25 median p75 max maxdec=3;
	var industrymerger both_tech toehold tender multibidder cashonly 
        stockonly hostile SharedAuditor;
run; 