import delimited using "C:\Users\王亭烜\Desktop\RA\Kim_Cha\results\mna_media_conservatism.csv", ///
    varnames(1) encoding(utf8) case(preserve) clear

drop if missing(SharedAuditor) | missing(ta_SaleGR) | missing(ta_big4) | missing(ac_big4) | ///
        missing(conservatism) | missing(ac_runup) | missing(ta_runup) | missing(rel_deal_size)
xtile p100_2 = conservatism, n(100)
gen high = (p100_2 > 50)
keep if Closure == 1

global x2 "combined_car3 combined_car5"

count if high==1

local obs1=r(N)

count if high==0

local obs0=r(N)

* Comparison

eststo clear

quietly estpost tabstat $x2 if high==1, stat(mean p50) column(stat)

              matrix p50_1=e(p50)

              eststo A

quietly estpost tabstat $x2 if high==0, stat(mean p50) column(stat)

              matrix p50_0=e(p50)

              eststo B

quietly estpost ttest $x2, by(high)

              matrix mean=(-1)*e(b)

              estadd matrix mean

              matrix p_mean=e(p)

              estadd matrix p_mean

              matrix p_p50=J(1,1,.)

              foreach i of global x2 {

              quietly ranksum `i', by(high)

              scalar p=2*(1-normal(abs(r(z))))

              matrix p_p50=p_p50,p

              }

              matrix p_p50=p_p50[1,2...]

              matrix rownames p_p50=p50

              matrix colnames p_p50=$x2

              estadd matrix p_p50

              eststo C

esttab A B C using "C:\\Users\\王亭烜\\Desktop\\RA\\Kim_Cha\\results\\Regression\\temp.csv", csv append title(Panel : `obs1' Transactions with COW adoption vs `obs0' Transactions without COW adoption) ///
mtitles("Deal with adoption (N=`obs1'):a" "Deal without adoption (N=`obs0'):b" "Test of difference (a-b): p-value") collabels("Mean" "Median" "t-test" "Wilcoxon z-test") nonumbers varwidth(15) label cells("mean(pattern(1 1 0) fmt(%8.3fc)) p50(pattern(1 1 0) fmt(%8.3fc)) p_mean(pattern(0 0 1) fmt(%8.3fc) star pvalue(p_mean)) p_p50(pattern(0 0 1) fmt(%8.3fc) star pvalue(p_p50))") starlevels(* 0.10 ** 0.05 *** 0.01) nonotes noobs
