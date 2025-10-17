import delimited using "C:\Users\王亭烜\Desktop\RA\Kim_Cha\results\mna_media_comparability.csv", ///
    varnames(1) encoding(utf8) case(preserve) clear

********All sample ttest for mean********
ttest combined_car3 == 0
ttest combined_car5 == 0

********ttest for mean of Closure=1 and Closure=0********
ttest combined_car3 == 0 if Closure == 1
ttest combined_car3 == 0 if Closure == 0
ttest combined_car5 == 0 if Closure == 1
ttest combined_car5 == 0 if Closure == 0

ttest combined_car3 == 0 if Closure_Merge == 1
ttest combined_car3 == 0 if Closure_Merge == 0
ttest combined_car5 == 0 if Closure_Merge == 1
ttest combined_car5 == 0 if Closure_Merge == 0

********ttest for mean of Closure=1 and Closure=0 within small and big firm********
*gen m_value = ta_size * ta_prcc_f
xtile p100 = ta_size, n(100)
gen size_grp = (p100 > 50) 

ttest combined_car3 == 0 if ta_small == 1 & Closure == 1
ttest combined_car3 == 0 if ta_small == 1 & Closure == 0
ttest combined_car3 == 0 if ta_small == 0 & Closure == 1
ttest combined_car3 == 0 if ta_small == 0 & Closure == 0

ttest combined_car3 == 0 if ta_small == 1 & Closure_Merge == 1
ttest combined_car3 == 0 if ta_small == 1 & Closure_Merge == 0
ttest combined_car3 == 0 if ta_small == 0 & Closure_Merge == 1
ttest combined_car3 == 0 if ta_small == 0 & Closure_Merge == 0

ttest combined_car5 == 0 if ta_small == 1 & Closure == 1
ttest combined_car5 == 0 if ta_small == 1 & Closure == 0
ttest combined_car5 == 0 if ta_small == 0 & Closure == 1
ttest combined_car5 == 0 if ta_small == 0 & Closure == 0

ttest combined_car5 == 0 if ta_small == 1 & Closure_Merge == 1
ttest combined_car5 == 0 if ta_small == 1 & Closure_Merge == 0
ttest combined_car5 == 0 if ta_small == 0 & Closure_Merge == 1
ttest combined_car5 == 0 if ta_small == 0 & Closure_Merge == 0


