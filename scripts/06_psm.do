/*******************************************************************************************
* Script   : psm_1to3.do
* Purpose  : Implement propensity score matching (PSM) as a robustness check for the effect
*            of local media closure (Closure) on M&A outcomes. For each outcome variable,
*            we construct a 1-to-3 matched sample and estimate the average treatment effect
*            of Closure on the matched sample.
*
* Data:
*   - Input  : "$proc/reg_sample_`dv'.csv" for each dependent variable in $depen3
*              (outcome-specific regression sample)
*   - Output :
*       * "$proc/pscore_`dv'.dta"             : dataset with estimated propensity scores
*       * "$proc/psmatch_1to3_`dv'.dta"       : 1-to-3 matched sample from psmatch2
*       * "$results/balance_table_1to3_`dv'.csv"
*       * "$results/psm_regression_1to3_`dv'.csv"
*
* Main steps (for each dependent variable dv in $depen3):
*
*   1. Load outcome-specific sample:
*        - Import "$proc/reg_sample_`dv'.csv" and save as reg_sample_`dv'.dta.
*
*   2. Estimate propensity scores:
*        - Drop observations with missing values in covariates $x
*          (ac_size, ta_size, ac_roa, ta_roa).
*        - Estimate a logit model:
*              logit Closure $x i.t_sic2 i.y_ann_num
*        - Predict the propensity score (pscore).
*        - Construct pscore2 = y_ann_num*10000 + t_sic2*10 + pscore to encode
*          year and industry (t_sic2) together with the propensity score, so that
*          matches are effectively restricted within year–industry cells.
*        - Keep dealid, Closure, y_ann_num, a_sic2, t_sic2, pscore, pscore2 and
*          save as pscore_`dv'.dta.
*
*   3. Perform 1-to-3 nearest-neighbor matching:
*        - Use psmatch2 with pscore(pscore2), caliper(0.5), neighbor(3):
*              psmatch2 Closure, pscore(pscore2) caliper(0.5) neighbor(3)
*        - Keep only observations with _support == 1 (matched treated and controls)
*          and save as psmatch_1to3_`dv'.dta.
*
*   4. Construct covariate balance table:
*        - Merge the matched sample with reg_sample_`dv'.dta to recover covariates $x.
*        - For Closure = 1 and Closure = 0 separately, compute means and medians of $x
*          using estpost tabstat.
*        - Run estpost ttest $x, by(Closure) to obtain differences in means and
*          associated p-values.
*        - Export a balance table
*              "$results/balance_table_1to3_`dv'.csv"
*          summarizing mean, median, and p-value for each covariate.
*
*   5. Estimate treatment effect (ATE) on the matched sample:
*        - Merge psmatch_1to3_`dv'.dta with reg_sample_`dv'.dta to recover `dv',
*          $x, and fixed-effect / cluster variables (`fe', `clus').
*        - Keep only matched observations (merge == 3) with positive weights _weight.
*        - Run a weighted reghdfe regression:
*              reghdfe `dv' Closure $x [aw = _weight],
*                      absorb(a_sic2 t_sic2 y_ann_num)
*                      vce(cluster a_gvkey t_gvkey)
*        - Export the regression result to
*              "$results/psm_regression_1to3_`dv'.csv"
*          reporting coefficient estimates, p-values, significance stars, and N.
*
* This script provides a PSM-based robustness check, showing whether the estimated
* effect of local media closure on M&A outcomes is robust to re-weighting the sample
* toward comparable treated and control deals with similar observable characteristics.
*******************************************************************************************/


global x ac_size ta_size ac_roa ta_roa ac_leverage ta_leverage
local fe   a_sic2 t_sic2 y_ann_num
local clus a_gvkey t_gvkey

foreach dv of global depen3 {

    clear
    import delimited "$proc/reg_sample_combined_car3.csv", /// "$proc/reg_sample_`dv'.csv"
        varnames(1) encoding(utf8) case(preserve) clear
	
	*gen a_sic2 = floor(a_sic/100) if !missing(a_sic)
	*gen t_sic2 = floor(t_sic/100) if !missing(t_sic)
	
    save "$proc/reg_sample_`dv'.dta", replace

   // Estimate propensity score --------------------------------------------------------
    foreach i of global x {
        drop if `i' == .
    }

    quietly logit Closure $x i.t_sic2 i.y_ann_num
    predict pscore if e(sample), pr

    gen double pscore2 = y_ann_num*10000 + t_sic2*10 + pscore

    keep dealid Closure y_ann_num a_sic2 t_sic2 pscore pscore2
    tab Closure

    save "$proc/pscore_`dv'.dta", replace

    // Matching process (1 to 3) -------------------------------------------------------
    use "$proc/pscore_`dv'.dta", clear
    psmatch2 Closure, pscore(pscore2) caliper(0.5) neighbor(3)

    keep if _support == 1
    tab Closure

    save "$proc/psmatch_1to3_`dv'.dta", replace

    // Make balance table --------------------------------------------------------------
    use "$proc/psmatch_1to3_`dv'.dta", clear
    merge 1:1 dealid using "$proc/reg_sample_`dv'.dta", ///
        keepusing($x) gen(_merge)
    keep if _merge == 3
    drop _merge
	
	drop if missing(_weight)
    drop if _weight <= 0

    quietly count if Closure == 1
    di "Matched sample (1:3) for `dv' - Closure = 1 : " r(N)
    quietly count if Closure == 0
    di "Matched sample (1:3) for `dv' - Closure = 0 : " r(N)

    eststo clear
    quietly estpost tabstat $x if Closure==1, stat(mean p50) column(stat)
    matrix p50_1 = e(p50)
    eststo A

    quietly estpost tabstat $x if Closure==0, stat(mean p50) column(stat)
    matrix p50_0 = e(p50)
    eststo B
	
    quietly estpost ttest $x, by(Closure)
    matrix mean   = (-1)*e(b)
    estadd matrix mean
    matrix p_mean = e(p)
    estadd matrix p_mean
    eststo C

    esttab A B C using ///
        "$results/balance_table_1to3_`dv'.csv", ///
        cells("mean(fmt(3)) p50(fmt(3)) p_mean(fmt(3))") ///
        collabels("Mean" "Median" "p-value") ///
        mtitle("Closure=1" "Closure=0" "Diff in means") ///
        nonumber noobs replace

    // ATE -----------------------------------------------------------------------------    
    use "$proc/psmatch_1to3_`dv'.dta", clear
    merge 1:1 dealid using "$proc/reg_sample_`dv'.dta", ///
        keepusing(`dv' $x `fe' `clus') gen(_merge)

    count if Closure == 1 & _weight == 1
    di "Number of treated matched for `dv' = " r(N)

    keep if _merge == 3
    drop _merge
    drop if missing(_weight)
    drop if _weight <= 0

    eststo clear
    reghdfe `dv' Closure $x [aw = _weight], ///
        absorb(`fe') vce(cluster `clus')
    eststo `dv'_psm1to3

    count if e(sample) & Closure == 1
    local N1 = r(N)
    count if e(sample) & Closure == 0
    local N0 = r(N)

    estadd scalar N1 = `N1'
    estadd scalar N0 = `N0'

    esttab `dv'_psm1to3 using ///
        "$results/psm_regression_1to3_`dv'.csv", ///
        b(3) p(3) star(* 0.10 ** 0.05 *** 0.01) ///
        mtitle("`dv' (1:3 matched)") ///
        stats(N N1 N0 r2_a, ///
              fmt(0 0 0 3) ///
              labels("N" "N (Closure=1)" "N (Closure=0)" "Adj. R-sq")) ///
        nonumber noobs replace
}



