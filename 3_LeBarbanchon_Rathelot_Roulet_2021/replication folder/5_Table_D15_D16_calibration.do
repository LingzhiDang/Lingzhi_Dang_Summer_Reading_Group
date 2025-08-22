* This do-file produces the table of targeted moments useful for the calibration


* INPUT:
* basedetravail_final_qje, clear

* OUTPUT: 
* calibration_sum_stat.dta gives, broken down or not by family status, separately for men and women
* and restricting to job finders + non minW workers
*	medians for search criteria, search outcomes (U duration, wages and commute)
*	gender gaps in residualized search and labor market outcomes 
* calibration_distance_distribution.dta gives average variance and kurtosis of residualized log commute
*	also reconverted in levels 
* calibration_wage_dsitrubtion.dta gives average variance and kurtosis of residualized log wages 
*	also reconverted in levels 




clear all

set matsize 1000
set maxvar 10000
set max_memory 14g

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

use basedetravail_final_qje, clear

global occE0="fapE0"

keep if found_a_job==1
 
 gen non_minW_workers=resWcorr_minW>1.05



***************************************************************
* Descriptive statistics by family status and for the whole sample, by gender
****************************************************************

	
foreach var in  dur_U dur_lastjob ///
	distanceE0 mobdist_km mobdist_tps  distanceE1 ///
	pastW_minW resWcorr_minW  postW_minW {
	
* single childess
sum `var' if male==1&married==0&child==0&non_minW_workers==1, d
sca `var'_gp1_men=r(p50)

sum `var' if female==1&married==0&child==0&non_minW_workers==1, d
sca `var'_gp1_women=r(p50)

* married without kids
sum `var' if male==1&married==1&non_minW_workers==1&child==0, d
sca `var'_gp2_men=r(p50)

sum `var' if female==1&married==1&non_minW_workers==1&child==0, d 
sca `var'_gp2_women=r(p50)


* single with kids
sum `var' if male==1&married==0&child==1&non_minW_workers==1, d 
sca `var'_gp3_men=r(p50)

sum `var' if female==1&married==0&child==1&non_minW_workers==1, d 
sca `var'_gp3_women=r(p50)


* married with kids
sum `var' if male==1&married==1&non_minW_workers==1&child==1, d
sca `var'_gp4_men=r(p50)

sum `var' if female==1&married==1&non_minW_workers==1&child==1, d 
sca `var'_gp4_women=r(p50)

* not by family status 
sum `var' if male==1&non_minW_workers==1, d
sca `var'_gp5_men=r(p50)

sum `var' if female==1&non_minW_workers==1, d 
sca `var'_gp5_women=r(p50)



gen med`var'3=scalar(`var'_gp1_men)
gen med`var'6=scalar(`var'_gp1_women)

gen med`var'9=scalar(`var'_gp2_men)
gen med`var'12=scalar(`var'_gp2_women)

gen med`var'15=scalar(`var'_gp3_men)
gen med`var'18=scalar(`var'_gp3_women)

gen med`var'21=scalar(`var'_gp4_men)
gen med`var'24=scalar(`var'_gp4_women)

gen med`var'25=scalar(`var'_gp5_men)
gen med`var'26=scalar(`var'_gp5_women)
gen med`var'27=scalar(`var'_gp5_men)
gen med`var'28=scalar(`var'_gp5_women)
* reason we define it twice is because after 25 an 26 will be used for specifications with previous job controls
* and 27 28 for specifications without 
preserve 
keep med`var'*
duplicates drop
gen index=1
reshape long med`var', i(index) j(sample)
gen men=1 if sample==3|sample==9|sample==15|sample==21|sample==25|sample==27
replace men=0 if men==.
gen married=1 if sample==9|sample==12|sample==21|sample==24
gen children=1 if sample==15|sample==18|sample==21|sample==24
replace married=0 if married==.&sample!=25&sample!=26&sample!=27&sample!=28
replace  children=0 if children==.&sample!=25&sample!=26&sample!=27&sample!=28
drop index  
order sample men married children  med`var'
rename med`var' `var'
save calibration_`var'.dta, replace 
restore 
}

gen single_children=single*child
gen married_children=married*child
gen childless=child==0
gen married_childless=married*childless
gen single_childless=single*childless

gen female_single_children=female*single_children
gen female_married_children=female*married_children
gen female_married_childless=female*married_childless
gen female_single_childless=female*single_childless

gen male_single_children=male*single_children
gen male_married_children=male*married_children
gen male_married_childless=male*married_childless
gen male_single_childless=male*single_childless


foreach var in  log_dur_U log_postW log_distanceE1   {
 

reghdfe `var' ///
	female_single_childless female_married_childless female_single_children female_married_children ///
	married_childless single_children married_children /// 
	log_PBD prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job & resWcorr_minW>1.05, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		


gen gap`var'3= - _b[female_single_childless]
gen gap`var'6=_b[female_single_childless]
gen gap`var'9=- _b[female_married_childless] 
gen gap`var'12=_b[female_married_childless] 
gen gap`var'15=- _b[female_single_children]  
gen gap`var'18=_b[female_single_children]
gen gap`var'21= -_b[female_married_children]  
gen gap`var'24=_b[female_married_children]  


reghdfe `var' ///
	female single_childless married_childless single_children married_children ///
	log_PBD prev_fulltime prev_cdi log_distanceE0 ///
	if found_a_job & resWcorr_minW>1.05, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		


gen gap`var'25= - _b[female]
gen gap`var'26=  _b[female]

	
	reghdfe `var' ///
	female single_childless married_childless single_children married_children ///
	if found_a_job & resWcorr_minW>1.05, a(i.age  i.education_  ///
	  i.cz#i.period_quarter) cluster(idfhda_)	
	  
	  
gen gap`var'27= - _b[female]
gen gap`var'28=  _b[female]
	
preserve 
keep gap`var'*
duplicates drop
gen index=1
reshape long gap`var', i(index) j(sample)
gen men=1 if sample==3|sample==9|sample==15|sample==21|sample==25|sample==27
replace men=0 if men==.
gen married=1 if sample==9|sample==12|sample==21|sample==24
gen children=1 if sample==15|sample==18|sample==21|sample==24
replace married=0 if married==.&sample!=25&sample!=26&sample!=27&sample!=28
replace  children=0 if children==.&sample!=25&sample!=26&sample!=27&sample!=28
drop index  
order sample men married children  gap`var'
save calibration_`var'.dta, replace 
restore 
	
}


foreach var in log_resWcorr log_mobdist {
  

reghdfe `var' ///
	female_single_childless female_married_childless female_single_children female_married_children ///
	married_childless single_children married_children /// male_married_childless male_single_children male_married_children ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if resWcorr_minW>1.05, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		


gen gap`var'3= - _b[female_single_childless]
gen gap`var'6=_b[female_single_childless]
gen gap`var'9=- _b[female_married_childless] 
gen gap`var'12=_b[female_married_childless] 
gen gap`var'15=- _b[female_single_children]  
gen gap`var'18=_b[female_single_children]
gen gap`var'21= -_b[female_married_children]  
gen gap`var'24=_b[female_married_children]  


reghdfe `var' ///
	female single_childless married_childless single_children married_children ///
	log_PBD mobunit_tps i.salunit_ ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if resWcorr_minW>1.05, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) cluster(idfhda_)		


gen gap`var'25= - _b[female]
gen gap`var'26=_b[female]
 
	reghdfe `var' ///
	female single_childless married_childless single_children married_children ///
	 mobunit_tps i.salunit_ if resWcorr_minW>1.05, a(i.age i.education_  ///
	i.cz#i.period_quarter) cluster(idfhda_)		


gen gap`var'27= - _b[female]
gen gap`var'28=_b[female]
	
preserve 
keep gap`var'*
duplicates drop
gen index=1
reshape long gap`var', i(index) j(sample)
gen men=1 if sample==3|sample==9|sample==15|sample==21|sample==25|sample==27
replace men=0 if men==.
gen married=1 if sample==9|sample==12|sample==21|sample==24
gen children=1 if sample==15|sample==18|sample==21|sample==24
replace married=0 if married==.&sample!=25&sample!=26&sample!=27&sample!=28
replace  children=0 if children==.&sample!=25&sample!=26&sample!=27&sample!=28
drop index  
order sample men married children  gap`var'
save calibration_`var'.dta, replace 
restore 
	
}


preserve
use calibration_dur_U, clear
foreach var in     log_dur_U dur_lastjob ///
	distanceE0 mobdist_km mobdist_tps  distanceE1 pastW_minW resWcorr_minW  ///
	log_resWcorr log_mobdist  postW_minW log_postW log_distanceE1 {
merge 1:1 sample using calibration_`var'.dta
drop _m
save ${OUTPUT}calibration_sum_stat.dta, replace
}
restore






***************************************************
* Commute residuals, broken down by family status
****************************************************
use basedetravail_final_qje, clear

global occE0="fapE0"

keep if found_a_job==1
 


cap drop sample

gen sample=3 	if male==1 & married==0 & child==0 &resWcorr_minW>1.05
replace sample=6 	if male==0 & married==0 & child==0 &resWcorr_minW>1.05	
replace sample=9 	if male==1 & married==1 & child==0 & resWcorr_minW>1.05
replace sample=12 	if male==0 & married==1 & child==0 & resWcorr_minW>1.05	
replace sample=15	if male==1 & married==0 & child==1 & resWcorr_minW>1.05
replace sample=18	if male==0 & married==0 & child==1 & resWcorr_minW>1.05	
replace sample=21	if male==1 & married==1 & child==1 & resWcorr_minW>1.05	
replace sample=24 	if male==0 & married==1 & child==1 & resWcorr_minW>1.05	


foreach var in distanceE1 {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}





foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==0 &resWcorr_minW>1.05	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in 6 12 18 24  {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in 6 12 18 24  {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 6 12 18 24  {
mat M= M \(`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==1 & resWcorr_minW>1.05	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in 3 9  15 21  {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in 3 9  15 21  {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in 3 9  15 21  {
mat M=M\ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}

	mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_distance_distribution_part1.dta, replace 
restore



********************************************************************************
* Commute residuals, not broken down by family status
********************************************************************************


cap drop sample

gen sample=.
replace sample=25 	if male==1 & resWcorr_minW>1.05	
replace sample=26 	if male==0 & resWcorr_minW>1.05	


foreach var in distanceE1 {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}





foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==0 & resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in  26 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in  26 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 26 {
mat M= M \(`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==1 & resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in  25 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in  25 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in  25 {
mat M= M\ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_distance_distribution_part2.dta, replace 
restore


********************************************************
* Commute residuals, with no previous job controls
********************************************************

cap drop sample

gen sample=.	
replace sample=27 	if male==1 & resWcorr_minW>1.05	
replace sample=28 	if male==0 & resWcorr_minW>1.05	

foreach var in distanceE1 {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	, a(i.age  i.education_    ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}



foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	if male==0 &resWcorr_minW>1.05 ///
	, a(i.age  i.education_  ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in  28 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in 28 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 28 {
mat M= M \ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_distanceE1 {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	if male==1 & resWcorr_minW>1.05 ///
	, a(i.age  i.education_  ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_distanceE1 {
foreach s in  27 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in distanceE1 {
foreach s in  27 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in  27 {
mat M=M \ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_distance_distribution_part3.dta, replace 
restore

use calibration_distance_distribution_part1, clear
append using calibration_distance_distribution_part2
append using calibration_distance_distribution_part3
save ${OUTPUT}calibration_distance_distribution, replace



********************************************************************************
* Wage residuals (TLB)
********************************************************************************

use basedetravail_final_qje, clear

global occE0="fapE0"

keep if found_a_job==1
 
 gen non_minW_workers=resWcorr_minW>1.05



***************************************************
* Wage residuals, broken down by family status
****************************************************


cap drop sample

gen sample=3 	if male==1 & married==0 & child==0 &resWcorr_minW>1.05
replace sample=6 	if male==0 & married==0 & child==0 &resWcorr_minW>1.05	
replace sample=9 	if male==1 & married==1 & child==0 & resWcorr_minW>1.05
replace sample=12 	if male==0 & married==1 & child==0 & resWcorr_minW>1.05	
replace sample=15	if male==1 & married==0 & child==1 & resWcorr_minW>1.05
replace sample=18	if male==0 & married==0 & child==1 & resWcorr_minW>1.05	
replace sample=21	if male==1 & married==1 & child==1 & resWcorr_minW>1.05	
replace sample=24 	if male==0 & married==1 & child==1 & resWcorr_minW>1.05	


foreach var in postW {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}





foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==0 &resWcorr_minW>1.05	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in 6 12 18 24  {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in 6 12 18 24  {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 6 12 18 24  {
mat M= M \(`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==1 & resWcorr_minW>1.05	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in 3 9  15 21  {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in 3 9  15 21  {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in 3 9  15 21  {
mat M=M\ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}

	mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_wage_distribution_part1.dta, replace 
restore



********************************************************************************
* Wage residuals, not broken down by family status
********************************************************************************


cap drop sample

gen sample=.
replace sample=25 	if male==1 & resWcorr_minW>1.05	
replace sample=26 	if male==0 & resWcorr_minW>1.05	


foreach var in postW {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}





foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==0 & resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in  26 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in  26 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 26 {
mat M= M \(`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	log_PBD ///
	prev_fulltime prev_cdi log_distanceE0 ///
	if male==1 & resWcorr_minW>1.05 ///
	, a(i.age i.exper i.education_  ///
	${occE0}_ i.pastW_bins  ///
	i.a38E0_#i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in  25 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in  25 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in  25 {
mat M= M\ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_wage_distribution_part2.dta, replace 
restore


********************************************************
* Wage residuals, with no previous job controls
********************************************************

cap drop sample

gen sample=.	
replace sample=27 	if male==1 & resWcorr_minW>1.05	
replace sample=28 	if male==0 & resWcorr_minW>1.05	

foreach var in postW {
sum `var' , d
sca mean_exp_gp=r(mean)
sca var_exp_gp=r(Var)
sca sd_exp_gp=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp))^2-scalar(var_exp_gp))^2
sum test_`var', d
sca W4_exp_gp=r(mean)

}
*sca list exp_gp
*sca list sd_exp_gp

foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	male##child ///
	, a(i.age  i.education_    ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
sca mean_resid_gp=r(mean)
sca var_resid_gp=r(Var)
sca sd_resid_gp=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp))^2-scalar(var_resid_gp))^2
sum test_resid, d
sca W4_resid_gp=r(mean)
sum `var' if e(sample)
sca mean_gp=r(mean)
sca var_gp=r(Var)
sca sd_gp=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp))^2-scalar(var_gp))^2 
sum test, d
sca W4_gp=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals)
sum exp_resid 
sca mean_exp_resid_gp=r(mean)
sca var_exp_resid_gp=r(Var)
sca sd_exp_resid_gp=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp))^2-scalar(var_exp_resid_gp))^2 
sum test_exp_resid, d
sca W4_exp_resid_gp=r(mean)
}



foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	if male==0 &resWcorr_minW>1.05 ///
	, a(i.age  i.education_  ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in  28 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in 28 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}

mat M= (0, mean_exp_gp, sd_exp_gp, var_exp_gp, W4_exp_gp, /*
	*/ mean_exp_resid_gp, sd_exp_resid_gp, var_exp_resid_gp, W4_exp_resid_gp,/*
	*/ mean_gp, sd_gp, var_gp, W4_gp, /*
	*/ mean_resid_gp, sd_resid_gp, var_resid_gp, W4_resid_gp)

mat list M

foreach s in 28 {
mat M= M \ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat colnames M = sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
mat list M


foreach var in log_postW {
capture drop residuals
capture drop exp_resid
reghdfe `var' ///
	married##child ///
	if male==1 & resWcorr_minW>1.05 ///
	, a(i.age  i.education_  ///
	i.cz#i.period_quarter) residuals cluster(idfhda_)		
predict residuals, r 
sum residuals 
}

foreach var in log_postW {
foreach s in  27 {
sum residuals if sample==`s'
sca mean_resid_gp`s'=r(mean)
sca var_resid_gp`s'=r(Var)
sca sd_resid_gp`s'=r(sd)
cap drop test_resid
gen test_resid= ((residuals-scalar(mean_resid_gp`s'))^2-scalar(var_resid_gp`s'))^2 if sample==`s'
sum test_resid, d
sca W4_resid_gp`s'=r(mean)
sum `var' if e(sample) & sample==`s'
sca mean_gp`s'=r(mean)
sca var_gp`s'=r(Var)
sca sd_gp`s'=r(sd)
cap drop test
gen test= ((`var'-scalar(mean_gp`s'))^2-scalar(var_gp`s'))^2 if e(sample) & sample==`s'
sum test, d
sca W4_gp`s'=r(mean)
cap drop exp_resid
gen exp_resid=exp(scalar(mean_gp)+residuals) if sample==`s'
sum exp_resid if sample==`s'
sca mean_exp_resid_gp`s'=r(mean)
sca var_exp_resid_gp`s'=r(Var)
sca sd_exp_resid_gp`s'=r(sd)
cap drop test_exp_resid
gen test_exp_resid= ((exp_resid-scalar(mean_exp_resid_gp`s'))^2-scalar(var_exp_resid_gp`s'))^2 if sample==`s'
sum test_exp_resid, d
sca W4_exp_resid_gp`s'=r(mean)
}
}

foreach var in postW {
foreach s in  27 {
sum `var' if sample==`s', d
sca mean_exp_gp`s'=r(mean)
sca var_exp_gp`s'=r(Var)
sca sd_exp_gp`s'=r(sd)
cap drop test_`var'
gen test_`var'= ((`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s'))^2 if sample==`s'
*gen test_`var'= (`var'-scalar(mean_exp_gp`s'))^2-scalar(var_exp_gp`s') if sample==`s'
sum test_`var', d
sca W4_exp_gp`s'=r(mean)
}
}


foreach s in  27 {
mat M=M \ (`s', mean_exp_gp`s', sd_exp_gp`s', var_exp_gp`s', W4_exp_gp`s', /*
	*/ mean_exp_resid_gp`s', sd_exp_resid_gp`s', var_exp_resid_gp`s', W4_exp_resid_gp`s',/*
	*/ mean_gp`s', sd_gp`s', var_gp`s', W4_gp`s', /*
	*/ mean_resid_gp`s', sd_resid_gp`s', var_resid_gp`s', W4_resid_gp`s')
}
mat list M

preserve
svmat M, names(col)
keep sample_ mean_exp_gp sd_exp_gp var_exp_gp W4_exp_gp /*
	*/ mean_exp_resid_gp sd_exp_resid_gp var_exp_resid_gp W4_exp_resid_gp /*
	*/ mean_gp sd_gp var_gp W4_gp /*
	*/ mean_resid_gp sd_resid_gp var_resid_gp W4_resid_gp
drop if missing(sample_)==1
drop if sample_==0
sort sample
save calibration_wage_distribution_part3.dta, replace 
restore

use calibration_wage_distribution_part1, clear
append using calibration_wage_distribution_part2
append using calibration_wage_distribution_part3
save ${OUTPUT}calibration_wage_distribution, replace
