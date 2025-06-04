***************************************************************;
* Last Update: May 2025                                       *; 
* This code matches the city-state with corresponding county. *;															  *;                           *;  
***************************************************************;
*
* <Some problems about the merging>
* 1. Some data does not have matching result due to irregular reasons, we
*    have to deal with them manually.
* 2. Basically, we reduce the PLACENAME (e.g. Alexandria city => Alexandria) and
*    match with ba_city in us_data. However, there may have both Alexandria city and 
*    Alexandria town, resulting in duplicated rows. Fortunately, city and town with 
*    same name usually locate in the same county so we keep the last data only. 
* 3. Extending problem 2, there are a few data with same ba_city and ba_state but with 
*    different county, this problem is caused by the fact that some city and town with 
*    same name locate in different county. These data also has to be corrected manually.
*;

**********************************************************
Part 1 : Import state_place data and company_city data
**********************************************************;
libname data "C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data"; 

data data.state_place;
	set data.state_place;
run;

data data.comp_city;
	set data.unique_comp_city;
run; 

**********************************************************
Part 2 : Remain only those compnies located in US
**********************************************************;

/*Create a list of states in U.S.
https://en.wikipedia.org/wiki/List_of_states_and_territories_of_the_United_States*/
%let us_states = AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA 
                 MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN 
                 TX UT VT VA WA WV WI WY DC;

/*Filter out companies whose head quarter are in U.S.*/
data us_data;
	set data.comp_city;
	if indexw("&us_states.", strip(upcase(ba_state))) > 0;
run;

**********************************************************
Part 3 : Merge company data with corresponding county
**********************************************************;
*
* step 1: remove 'city', 'CDP', 'town', 'township', 'village' from PLACENAME
* step 2: change the PLACENAME into upper case 
* step 3: merge us_data and state_place data using city and state
*;

data state_place;
	set data.state_place;
	place_reduce = tranwrd(PLACENAME,'city', '');
	place_reduce = tranwrd(place_reduce, 'CDP', '');
	place_reduce = tranwrd(place_reduce, 'township', '');
	place_reduce = tranwrd(place_reduce, 'town', '');
	place_reduce = tranwrd(place_reduce, 'village', ''); 
	place_reduce = tranwrd(place_reduce, 'borough', ''); 

	place_reduce = strip(upcase(place_reduce)); 
run; 

data us_data;
	set us_data;
	ba_city = upcase(ba_city);
run; 

proc sql;
	create table comp_county as 
	select us_data.*, state_place.* 
	from us_data left join state_place 
	on us_data.ba_city = state_place.place_reduce and us_data.ba_state = state_place.STATE;
quit; 

/*Examine whether there are data with same ba_city and ba_state but different county*/
proc sql;
    select ba_city, ba_state, count(distinct county) as county_count
    from comp_county
    group by ba_city, ba_state
    having calculated county_count > 1;
quit;

*************************************************************************
Part 4 : Mark the data without mathing results and export in csv file
*************************************************************************;

data comp_county;
	set comp_county;
	if STATE = '' then MATCH = 0;
	else MATCH = 1;
run; 

proc export data=comp_county 
    outfile="C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data\comp_county.csv"
    dbms=csv
    replace;
run;

*************************************************************************
Part 5 : Selects data with MATCH=1 and deal with the duplicated data
*************************************************************************;

data match;
	set comp_county;
	if match=1;
run; 

proc sort data=match;
	by ba_city ba_state county;
run;

data data_matched;
	set match;
	by ba_city ba_state county;
	if last.county;
run; 

proc export data=data_matched 
    outfile="C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data\data_matched.csv"
    dbms=csv
    replace;
run;

*************************************************************************
Part 6 : Selects data with MATCH=0 and divides them into three files
*************************************************************************;
*
* These 3 files must be filled manually and merge with data_matched. 
*;

/*
data unmatch;
	set comp_county;
	if MATCH=0;
run; 

data part1 part2 part3;
    set unmatch;
    if _N_ <= 150 then output part1;
    else if _N_ <= 300 then output part2;
    else output part3;
run;

proc export data=part1 
    outfile="C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data\part1.csv"
    dbms=csv
    replace;
run;

proc export data=part2 
    outfile="C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data\part2.csv"
    dbms=csv
    replace;
run;

proc export data=part3 
    outfile="C:\Users\¤ý«FÒj\Desktop\RA\Kim_Cha\Data\part3.csv"
    dbms=csv
    replace;
run;
*/ 