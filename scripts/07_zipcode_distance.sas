*****************************************************************************;
* Last Update: 2025/11													    *;
* This SAS code computes the distance between acquirer and target using     *;
* zip code data                                                             *;                                               																			*;
*****************************************************************************;

*************************************************************************
Part 1 - Import mna data, zip code data, and lat-long coordinates data
*************************************************************************; 

data mna_media; 
	set PROC.mna_media_conservatism2; 
run;

data zip_data;
	set DAT.comp_cik_03_18_media;
run;

proc import datafile="&data.\zipcode_Census_2000.xlsx"  
	dbms=xlsx 
	out=coordinate_data
	replace;
run;

***********************************
Part 2 - Build 2-letter state name
***********************************;

data mna_media;
	set mna_media;
	if a_state = "Alabama" then a_state2 = "AL";
	if a_state = "Alaska" then a_state2 = "AK";
	if a_state = "Arizona" then a_state2 = "AZ";
	if a_state = "Arkansas" then a_state2 = "AR";
	if a_state = "California" then a_state2 = "CA";
	if a_state = "Colorado" then a_state2 = "CO";
	if a_state = "Connecticut" then a_state2 = "CT";
	if a_state = "Delaware" then a_state2 = "DL";
	if a_state = "District of Columbia" then a_state2 = "DC";
	if a_state = "Florida" then a_state2 = "FL";
	if a_state = "Georgia" then a_state2 = "GA";
	if a_state = "Hawaii" then a_state2 = "HI";
	if a_state = "Idaho" then a_state2 = "ID";
	if a_state = "Illinois" then a_state2 = "IL";
	if a_state = "Indiana" then a_state2 = "IN";
	if a_state = "Iowa" then a_state2 = "IA";
	if a_state = "Kansas" then a_state2 = "KS";
	if a_state = "Kentucky" then a_state2 = "KY";
	if a_state = "Louisiana" then a_state2 = "LA";
	if a_state = "Maine" then a_state2 = "ME";
	if a_state = "Maryland" then a_state2 = "MD";
	if a_state = "Massachusetts" then a_state2 = "MA";
	if a_state = "Michigan" then a_state2 = "MI";
	if a_state = "Minnesota" then a_state2 = "MN";
	if a_state = "Mississippi" then a_state2 = "MS";
	if a_state = "Missouri" then a_state2 = "MO";
	if a_state = "Montana" then a_state2 = "MT";
	if a_state = "Nebraska" then a_state2 = "NE";
	if a_state = "Nevada" then a_state2 = "NV";
	if a_state = "New Hampshire" then a_state2 = "NH";
	if a_state = "New Jersey" then a_state2 = "NJ";
	if a_state = "New Mexico" then a_state2 = "NM";
	if a_state = "New York" then a_state2 = "NY";
	if a_state = "North Carolina" then a_state2 = "NC";
	if a_state = "North Dakota" then a_state2 = "ND";
	if a_state = "Ohio" then a_state2 = "OH";
	if a_state = "Oklahoma" then a_state2 = "OK";
	if a_state = "Oregon" then a_state2 = "OR";
	if a_state = "Pennsylvania" then a_state2 = "PA";
	if a_state = "Rhode Island" then a_state2 = "RI";
	if a_state = "South Carolina" then a_state2 = "SC";
	if a_state = "South Dakota" then a_state2 = "SD";
	if a_state = "Tennessee" then a_state2 = "TN";
	if a_state = "Texas" then a_state2 = "TX";
	if a_state = "Utah" then a_state2 = "UT";
	if a_state = "Vermont" then a_state2 = "VT";
	if a_state = "Virginia" then a_state2 = "VA";
	if a_state = "Washington" then a_state2 = "WA";
	if a_state = "Wisconsin" then a_state2 = "WI";
	if a_state = "Wyoming" then a_state2 = "WY";

	if t_state = "Alabama" then t_state2 = "AL";
	if t_state = "Alaska" then t_state2 = "AK";
	if t_state = "Arizona" then t_state2 = "AZ";
	if t_state = "Arkansas" then t_state2 = "AR";
	if t_state = "California" then t_state2 = "CA";
	if t_state = "Colorado" then t_state2 = "CO";
	if t_state = "Connecticut" then t_state2 = "CT";
	if t_state = "Delaware" then t_state2 = "DL";
	if t_state = "District of Columbia" then t_state2 = "DC";
	if t_state = "Florida" then t_state2 = "FL";
	if t_state = "Georgia" then t_state2 = "GA";
	if t_state = "Hawaii" then t_state2 = "HI";
	if t_state = "Idaho" then t_state2 = "ID";
	if t_state = "Illinois" then t_state2 = "IL";
	if t_state = "Indiana" then t_state2 = "IN";
	if t_state = "Iowa" then t_state2 = "IA";
	if t_state = "Kansas" then t_state2 = "KS";
	if t_state = "Kentucky" then t_state2 = "KY";
	if t_state = "Louisiana" then t_state2 = "LA";
	if t_state = "Maine" then t_state2 = "ME";
	if t_state = "Maryland" then t_state2 = "MD";
	if t_state = "Massachusetts" then t_state2 = "MA";
	if t_state = "Michigan" then t_state2 = "MI";
	if t_state = "Minnesota" then t_state2 = "MN";
	if t_state = "Mississippi" then t_state2 = "MS";
	if t_state = "Missouri" then t_state2 = "MO";
	if t_state = "Montana" then t_state2 = "MT";
	if t_state = "Nebraska" then t_state2 = "NE";
	if t_state = "Nevada" then t_state2 = "NV";
	if t_state = "New Hampshire" then t_state2 = "NH";
	if t_state = "New Jersey" then t_state2 = "NJ";
	if t_state = "New Mexico" then t_state2 = "NM";
	if t_state = "New York" then t_state2 = "NY";
	if t_state = "North Carolina" then t_state2 = "NC";
	if t_state = "North Dakota" then t_state2 = "ND";
	if t_state = "Ohio" then t_state2 = "OH";
	if t_state = "Oklahoma" then t_state2 = "OK";
	if t_state = "Oregon" then t_state2 = "OR";
	if t_state = "Pennsylvania" then t_state2 = "PA";
	if t_state = "Rhode Island" then t_state2 = "RI";
	if t_state = "South Carolina" then t_state2 = "SC";
	if t_state = "South Dakota" then t_state2 = "SD";
	if t_state = "Tennessee" then t_state2 = "TN";
	if t_state = "Texas" then t_state2 = "TX";
	if t_state = "Utah" then t_state2 = "UT";
	if t_state = "Vermont" then t_state2 = "VT";
	if t_state = "Virginia" then t_state2 = "VA";
	if t_state = "Washington" then t_state2 = "WA";
	if t_state = "Wisconsin" then t_state2 = "WI";
	if t_state = "Wyoming" then t_state2 = "WY";
run;

*************************************************************
Part 3 - Merge mna_media and zip_data using gvkey and fyear
*************************************************************;

proc sql; 
	create table mna_media_azip_all as 
	select a.*, b.ba_state as a_ba_state, b.fyear as temp_fyear, b.ba_zip5 as a_zip 
	from mna_media as a left join zip_data as b 
	on a.a_gvkey = b.gvkey and b.fyear <= a.y_ann_num - 1; 
quit; 

proc sql; create table mna_media_azip_best as 
	select * from mna_media_azip_all 
	group by dealid having temp_fyear = max(temp_fyear); 
quit; 

proc sql; create table mna_media_tzip_all as 
	select a.*, b.ba_state as t_ba_state, b.fyear as temp_fyear, b.ba_zip5 as t_zip 
	from mna_media as a left join zip_data as b 
	on a.t_gvkey = b.gvkey and b.fyear <= a.y_ann_num - 1; 
quit; 

proc sql; 
	create table mna_media_tzip_best as 
	select * from mna_media_tzip_all 
	group by dealid having temp_fyear = max(temp_fyear); 
quit; 
 
proc sql;
	create table mna_media_zip_best as 
	select a.*, b.t_ba_state, b.t_zip 
	from mna_media_azip_best as a left join mna_media_tzip_best as b
	on a.dealid = b.dealid;
quit;

data mna_media;
	set mna_media_zip_best;
run;

**********************************************
Part 4 - Merge mna_media and coordinate_data
**********************************************;

data coord_num coord_pseudo;
    set coordinate_data;
    state2 = substr(zip, 1, 2);
    zip5   = substr(zip, 3, 7);
    zip3   = substr(zip5, 1, 3);

    if lengthn(zip5) = 5 and compress(zip5, '0123456789') = '' then do;
        output coord_num;
    end;
    
    else if lengthn(zip5) = 5 and compress(zip5, '0123456789') ne '' 
		and substr(zip5, 4, 2) = 'HH' then do;
        output coord_pseudo;
    end;
run;

proc sql;
    create table mna_media_acoor as
    select 
        a.*,
        coalesce(b1.Latitude,  b2.Latitude)  as a_lat,
        coalesce(b1.Longitude, b2.Longitude) as a_lon
    from mna_media as a

    left join coord_num as b1
        on  a.a_state2 = b1.state2
        and a.a_zip    = b1.zip5

    left join coord_pseudo as b2
        on  a.a_state2          = b2.state2
        and substr(a.a_zip, 1, 3) = b2.zip3
    ;
quit;

proc sql;
    create table mna_media_tcoor as
    select 
        a.*,
        coalesce(b1.Latitude,  b2.Latitude)  as t_lat,
        coalesce(b1.Longitude, b2.Longitude) as t_lon
    from mna_media_acoor as a

    left join coord_num as b1
        on  a.t_state2 = b1.state2
        and a.t_zip    = b1.zip5

    left join coord_pseudo as b2
        on  a.t_state2          = b2.state2
        and substr(a.t_zip, 1, 3) = b2.zip3
    ;
quit; 

*********************************************************
Part 5 - Calculate distance between acquirer and target
*********************************************************;

data mna_media_tcoor;
	set mna_media_tcoor;
	dist_K = geodist(a_lat, a_lon, t_lat, t_lon, 'K');
	dist_M = geodist(a_lat, a_lon, t_lat, t_lon, 'M');
run;

**********************
Part 6 - Export data
**********************;

data PROC.mna_media_distance; 
	set mna_media_tcoor; 
run;
 
proc export data=PROC.mna_media_distance outfile="&proc.\mna_media_distance.csv" 
	dbms=csv 
	replace; 
	putnames=yes; 
run;