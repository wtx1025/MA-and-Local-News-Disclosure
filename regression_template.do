import delimited using "C:\Users\王亭烜\Desktop\RA\Kim_Cha\results\mna_media_conservatism.csv", ///
    varnames(1) encoding(utf8) case(preserve) clear
	
replace industrymerger = 0 if missing(industrymerger)
replace both_tech = 0 if missing(both_tech)
replace toehold = 0 if missing(toehold)
replace cashonly = 0 if missing(cashonly)
replace stockonly = 0 if missing(stockonly)
replace tender = 0 if missing(tender)
replace hostile = 0 if missing(hostile)
replace multibidder = 0 if missing(multibidder)

gen start_date = date(d_ann, "DMY")
gen end_date = date(d_eff, "DMY")
gen complete = 1
format start_date %td 
format end_date %td 
gen days_diff = end_date - start_date 
	
gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)

* Fixed effects & cluster
global fe a_sic2 t_sic2 y_ann_num
global clus a_gvkey t_gvkey

global depen a_goodwill_12months 
global indep Closure_Merge cm_conservatism // can change to Closure_Merge
global controls ac_size ta_size ac_leverage ta_leverage ac_fcf ta_fcf ac_tobinq ta_tobinq /// 
       ac_roa ta_roa ac_runup ta_runup ac_mtb ta_mtb ac_big4 ta_big4 rel_deal_size industrymerger both_tech ///
	   toehold tender multibidder cashonly stockonly hostile ta_SaleGR SharedAuditor aq_lag1
global filename "C:\\Users\\王亭烜\\Desktop\\RA\\Kim_Cha\\results\\Regression\\temp.xls" 

reghdfe $depen $indep $controls, absorb($fe) vce(cluster $clus)
outreg2 using $filename, append label addtext(Ind-fixed , Yes, Year-Fixed, Yes) addstat(R-squared,e(r2), ///
adj R-squared,e(r2_a)) dec(3) pvalue


*browse

**********If winsorization is needed, use this code********** 
*global winsor ac_size ta_size ac_leverage ta_leverage ac_fcf ta_fcf ac_tobinq ta_tobinq ///
*      ac_roa ta_roa ac_mtb ta_mtb runup rel_deal_size aq_lag1

*foreach i of global winsor {
*	winsor2 `i', replace cuts(1 99)
*}

