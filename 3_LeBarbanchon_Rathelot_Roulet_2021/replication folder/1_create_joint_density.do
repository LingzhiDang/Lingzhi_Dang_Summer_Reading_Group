* This dofile creates the dataset needed for the joint density plots (done in R)

* input: basedetravail_final_qje from 1_construction_main_dataset

* output: jointdensity to be used in with the R code Figure5


clear all

set matsize 1000
set maxvar 10000
set maxvar 32000
set max_memory 11g

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

use basedetravail_final_qje.dta, clear


sum mobdist if mobunit=="KM"
sca mobdist_KM=r(mean)
sum mobdist if mobunit!="KM"
sca mobdist_TPS=r(mean)

sca speed=scalar(mobdist_KM)/scalar(mobdist_TPS)*60
sca list speed
* speed =  41.097592

sum distanceE0 if mobunit=="KM"
sca distanceE0_KM=r(mean)
sum distanceE0 if mobunit!="KM"
sca distanceE0_TPS=r(mean)
tab female mobunit, row

sca speed_ADD=(scalar(mobdist_KM)+distanceE0_TPS-distanceE0_KM)/scalar(mobdist_TPS)*60
sca list speed_ADD
*speed_ADD =  37.076029

sca speed_MULT=(scalar(mobdist_KM)*distanceE0_TPS/distanceE0_KM)/scalar(mobdist_TPS)*60
sca list speed_MULT
*speed_MULT =  35.098035

replace mobdist=mobdist/60*scalar(speed_ADD) if mobunit!="KM"
label var mobdist "Max accepted commute in KM"

merge m:1 rome using vac_occ_minW
keep if _m==3
drop _m
label var occ_minW "Share of job ads at the minW within worker occupation"

*count if missing(occ_minW)
sum occ_minW, d
cap drop samp_occminW
gen samp_occminW=occ_minW>=r(mean) if missing(occ_minW)==0
label var samp_occminW "Worker searches occupation with high share of minèw_wage ads" 
tab samp_occminW


gen samp_resWminW=resWcorr<1.05*minW


keep if found_a_job

capture drop t_D
gen t_D=log(distanceE1)-log(mobdist)
cap drop log_postW_resW
gen log_postW_resW=log(postWcorr)-log_resWcorr

keep if found_a_job==1 
keep t_D log_postW_resW mobunit_tps female samp_resWminW  samp_occminW
drop if missing(t_D)
drop if missing(log_postW_resW)

saveold jointdensity.dta, replace version(12)


