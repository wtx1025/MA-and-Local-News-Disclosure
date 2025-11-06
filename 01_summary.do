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

********Fixed effects & cluster********
gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
gen t_sic2 = floor(t_sic/100) if !missing(t_sic)
global fe a_sic2 t_sic2 y_ann_num
global clus a_gvkey t_gvkey

********Define variables********
global depen combined_car5
global indep Closure
global controls ac_size ta_size ac_leverage ta_leverage ac_fcf ta_fcf ac_tobinq ta_tobinq /// 
       ac_roa ta_roa ac_runup ta_runup ac_mtb ta_mtb rel_deal_size industrymerger both_tech ///
	   toehold tender multibidder cashonly stockonly hostile ta_SaleGR SharedAuditor aq_lag1 ///
	   ac_big4 ta_big4

********Run regression********
reghdfe $depen $indep $controls, absorb($fe) vce(cluster $clus)

********Summary Statistics********
gen byte in_sample = e(sample) 
label var in_sample "1 = used in reghdfe estimation"
estpost tabstat $depen conservatism $indep $controls if in_sample, ///
    stats(n mean sd p25 p50 p75) columns(stat)

esttab using "C:\Users\王亭烜\Desktop\RA\Kim_Cha\results\Regression\summary.csv", ///
    cells("n(fmt(0)) mean(fmt(3)) sd(fmt(3)) p25(fmt(3)) p50(fmt(3)) p75(fmt(3))") ///
    nomtitle nonumber replace csv
