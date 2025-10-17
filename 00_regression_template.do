import delimited using "C:\Users\王亭烜\Desktop\RA\Kim_Cha\results\mna_media_comparability.csv", ///
    varnames(1) encoding(utf8) case(preserve) clear
	
replace industrymerger = 0 if missing(industrymerger)
replace both_tech = 0 if missing(both_tech)
replace toehold = 0 if missing(toehold)
replace cashonly = 0 if missing(cashonly)
replace stockonly = 0 if missing(stockonly)
replace tender = 0 if missing(tender)
replace hostile = 0 if missing(hostile)
replace multibidder = 0 if missing(multibidder)
gen m_value = ta_scho * ta_prcc_f

********Cut data into subsample******** 
xtile p100 = compare_pct, n(100)
drop if p100 > 50 | compare_pct == . // divide our sample into p100<=50 and p100>50

********Interaction Term********
*gen high = (p100 > 50)
*gen c_high = Closure * high 
*gen cm_high = Closure_Merge * high

********Fixed effects & cluster********
gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
*gen t_sic2 = floor(t_sic/100) if !missing(t_sic)
global fe a_sic2 t_sic2 y_ann_num
global clus a_gvkey t_gvkey

********Define variables********
global depen a_car5_ffm
global indep Closure_Merge
global controls ac_size ta_size ac_leverage ta_leverage ac_fcf ta_fcf ac_tobinq ta_tobinq /// 
       ac_roa ta_roa ac_runup ta_runup ac_mtb ta_mtb ac_big4 ta_big4 rel_deal_size industrymerger both_tech ///
	   toehold tender multibidder cashonly stockonly hostile ta_SaleGR SharedAuditor aq_lag1
global filename "C:\\Users\\王亭烜\\Desktop\\RA\\Kim_Cha\\results\\Regression\\temp.xls" 

********Winsorization********
global winsor ac_size ta_size ac_leverage ta_leverage ac_fcf ta_fcf ac_tobinq ta_tobinq ///
      ac_roa ta_roa ac_mtb ta_mtb ac_runup ta_runup rel_deal_size ta_SaleGR 

foreach i of global winsor {
	winsor2 `i', replace cuts(0.5 99.5)
}

********Run regression********
reghdfe $depen $indep $controls, absorb($fe) vce(cluster $clus)
outreg2 using $filename, append label addtext(Ind-fixed , Yes, Year-Fixed, Yes) addstat(R-squared,e(r2), ///
adj R-squared,e(r2_a)) dec(3) pvalue

browse


