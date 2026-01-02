/********************************************************************************************
* Program:		master.do
* Purpose:		Generate all tables with one click. 
*
* Steps:
*	(1) Change the user name (username) and the path (main) to this replication package.
*	(2) Set the script indicator of the scripts you want to run to 1 (recommended: run
*       all scripts each time).
*	(3) Check the tables in folder `results` under replication package. 
********************************************************************************************/

set more off 
set varabbrev off 
clear all
macro drop _all 

if "$main"=="" {
    if "`c(username)'" == "王亭烜" {
        global main "C:\Users\王亭烜\Desktop\Replication Package"
    }
    else {
        display as error "User not recognized."
        exit 198
    }
}

local subdirectories data scripts results proc 
foreach folder of local subdirectories{
	cap mkdir "$main/`folder'"
	global `folder' "$main/`folder'"
}

// Shared variables --------------------------------------------------------------------
global depen combined_car3 combined_car5 roa_diff roe_diff  
global depen2 combined_car3
global depen3 combined_car3 roa_diff
global controls ac_size ta_size ac_leverage ta_leverage ///
                ac_roa ta_roa ac_runup ta_runup ac_mtb ta_mtb ///
			    industrymerger both_tech multibidder ///
				rel_deal_size cashonly stockonly ///
                ac_big4 ta_big4 ta_SaleGR ta_loss 
				 
global winsor  ac_size ta_size ac_leverage ta_leverage ac_roa ta_roa ///
               ac_mtb ta_mtb ac_runup ta_runup rel_deal_size ta_SaleGR
			   
global fe a_sic2 t_sic2 y_ann_num
global clus a_gvkey t_gvkey 
global charlist aq_lag1 conservatism

// Run scripts -------------------------------------------------------------------------
local 01_mainTab = 1 
local 02_summary = 1
local 03_channels = 1
local 04_mitigate_all = 1
local 05_mitigate_sub = 1
local 06_psm = 1

// H1 Baseline Regression (Table 3)
if (`01_mainTab' == 1) do "$scripts/01_mainTab.do" 
// INPUTS
//  "$\Replication Package\proc\mna_media_ap.csv"
// OUTPUTS
//  "$\Replication Package\results\main_table.csv"

// Distribution Table & Descriptive Statistics (Table 1 & 2) 
if (`02_summary' == 1) do "$scripts/02_summary.do"
// INPUTS
//  "$\Replication Package\proc\reg_sample_combined_car3.csv"
// OUTPUTS
//  "$\Replication Package\results\distribution_table.csv"
//  "$\Replication Package\results\descriptive_table.csv"

// Channel analysis (Table 4 & Table 5)
if (`03_channels' == 1) do "$scripts/03_channels.do" 
// INPUTS
//  "$\Replication Package\proc\mna_media_ap.csv"
// OUTPUTS
//  "$\Replication Package\results\channels.csv"

// H2 Baseline Regression (Table 6)
if (`04_mitigate_all' == 1) do "$scripts/04_mitigate_all.do" 
// INPUTS
//  "$\Replication Package\proc\mna_media_ap.csv"
// OUTPUTS
//  "$\Replication Package\results\mitigate_all.csv"

// H2 Baseline Regression in subsample (Table 7 & Table 8)
if (`05_mitigate_sub' == 1) do "$scripts/05_mitigate_sub.do" 
// INPUTS
//  "$\Replication Package\proc\mna_media_ap.csv"
// OUTPUTS
//  "$\Replication Package\results\mitigate_sub.csv"

// Propensity Score Matching (Table 9)
if (`06_psm' == 1) do "$scripts/06_psm.do" 
// INPUTS
//  "$\Replication Package\proc\reg_sample_combined_car3.csv"
//  "$\Replication Package\proc\reg_sample_roa_diff.csv"
// OUTPUTS
//  "$\Replication Package\results\balance_table_1to3_combined_car3.csv"
//  "$\Replication Package\results\balance_table_1to3_roa_diff.csv"
//  "$\Replication Package\results\psm_regression_1to3_combined_car3.csv"
//  "$\Replication Package\results\psm_regression_1to3_roa_diff.csv"





