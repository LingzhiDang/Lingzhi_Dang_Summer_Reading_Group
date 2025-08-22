/*
This dofile creates Table 8 (choice model)

* It first creates a dataset that assigns to each job seeker a relevant set of vacancies

* It then estimates conditional logit model for the probability of applying 

* input: m0_vac_de_travail from in 1_construction_application_dataset

* output : base_choice_model


*/


clear all
set matsize 1000
set maxvar 10000
set max_memory 11g

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

 



* by quarter, create identifiers for relevant markets (3-digit occupation X CZ cell with at least 30 offers)  
* we create 2 set of identifiers because it will be useful afterwards 
forvalues k=2010(1)2012 {
forvalues q=1(3)10{
use m0_vac_de_travail, clear

keep if vac_dtecrepof_monthly>=ym(`k',`q')&vac_dtecrepof_monthly<=ym(`k',`q'+2) 
 
 gen vac_rome3dig=substr(vac_rome,1,3)
egen group_vac=group(vac_rome3dig vac_ZE2010)
bys group_vac: egen count=count(numofr)
keep if count>=30

capture drop group_vac
egen group_vac=group(vac_rome3dig vac_ZE2010)

keep group_vac vac_rome3dig vac_ZE2010  
duplicates drop
sort vac_rome vac_ZE
save group_vac`k'_Q`q', replace

rename group_vac group_de
rename vac_ZE ZE2010
rename vac_rome3dig rome3dig
sort rome3dig ZE2010
save group_DE`k'_Q`q', replace 
}
}

* code for first quarter of each year (code for the remaining 3 quarters follow)
forvalues k=2010(1)2012 {

use m0_vac_de_travail, clear

gen vac_rome3dig=substr(vac_rome,1,3)
gen rome3dig=substr(rome,1,3)


* each offer is assigned its market identifier for the relevant quarter 
merge m:1 vac_rome3dig vac_ZE2010 using group_vac`k'_Q1
keep if _m==3
drop _m

* each applicant is assigned its market identifier based on CZ of residence and declared occupation
* note that she can apply to offers outside her market  , hence the need to have a separate market identifier
* for applicants and vacancies
merge m:1  rome3dig ZE2010 using group_DE`k'_Q1
keep if _m==3
drop _m

keep   group_vac group_de numofr idfhda vac_dtecrepof_monthly datins
sum group_vac
sca nb_`k'_Q1=scalar(r(max))

* in what follows we assign to each job seeker 
* all the job ads which correspond to her CZ of residence and declared occupation
* and which are posted in teh quarter following her registration 
forvalues j=1(1)`r(max)' {

preserve 
keep if group_vac==`j'&vac_dtecrepof_monthly>=ym(`k',1)&vac_dtecrepof_monthly<=ym(`k',3) 
keep numofr
duplicates drop
save job_ad_`j', replace 
restore 

preserve
keep if group_de==`j'&datins>=mdy(10,1,`k'-1)&datins<=mdy(12,31,`k'-1)
keep idfhda   numofr
merge m:1 numofr using job_ad_`j'
drop if _m==1
drop _m 

fillin idfhda numofr
gen applied=_fillin==0


save DE_vac`j'_`k'_Q1, replace 
restore
}
}

* similar code for the remaining 3 quarters 
forvalues k=2010(1)2012 {
forvalues q=4(3)10{
use m0_vac_de_travail, clear

gen vac_rome3dig=substr(vac_rome,1,3)
gen rome3dig=substr(rome,1,3)

merge m:1 vac_rome3dig vac_ZE2010 using group_vac`k'_Q`q'
keep if _m==3
drop _m

merge m:1  rome3dig ZE2010 using group_DE`k'_Q`q'
keep if _m==3
drop _m

keep   group_vac group_de numofr idfhda vac_dtecrepof_monthly datins

sum group_vac
sca nb_`k'_Q`q'=scalar(r(max))

forvalues j=1(1)`r(max)' {

preserve 
keep if group_vac==`j'&vac_dtecrepof_monthly>=ym(`k',`q')&vac_dtecrepof_monthly<=ym(`k',`q'+2) 
keep numofr
duplicates drop
save job_ad_`j', replace 

restore 
preserve

keep if group_de==`j'&datins>=mdy(`q'-3,1,`k')&datins<=mdy(`q'-1,31,`k')
keep idfhda   numofr

merge m:1 numofr using job_ad_`j'
drop if _m==1
drop _m


fillin idfhda numofr
gen applied=_fillin==0
drop if missing(idfhda)

save DE_vac`j'_`k'_Q`q', replace 
restore
}
}
}





forvalues k=2010(1)2012 {
forvalues q=1(3)10{
sca list nb_`k'_Q`q'
}
}

use DE_vac1_2010_Q1, clear
forvalues j=2(1)2046 {
	append using DE_vac`j'_2010_Q1
	}
forvalues j=1(1)2021 {
	append using DE_vac`j'_2010_Q4
}
forvalues j=1(1)2066 {
	append using DE_vac`j'_2010_Q7
}
forvalues j=1(1)1826 {
	append using DE_vac`j'_2010_Q10
}
forvalues j=1(1)2493 {
	append using DE_vac`j'_2011_Q1
}
forvalues j=1(1)2367 {
	append using DE_vac`j'_2011_Q4
}
forvalues j=1(1)2283 {
	append using DE_vac`j'_2011_Q7
}
forvalues j=1(1)1959 {
	append using DE_vac`j'_2011_Q10
}
forvalues j=1(1)2449 {
	append using DE_vac`j'_2012_Q1
}
forvalues j=1(1)2130 {
	append using DE_vac`j'_2012_Q4
}
compress


save base_jobchoice_total_.dta, replace
 
 
 
 ************************************************************************
 * adding some relevant variables and restricting to relevant set 
 ************************************************************************
 
use m0_vac_de_travail, clear
gen mobunit_tps=mobunit=="TPS"
keep idfhda female de_yr de_xr de_superficyr depcom2    education_  age exper   de_cz  datins foreign  resWcorr_minW
duplicates drop
duplicates drop idfhda ,  force

save clogit_de_info, replace 
 
 
use m0_vac_de_travail, clear
keep numofr vac_ZE2010 vac_ZE2010_ vac_dtecrepof vac_xo vac_yo vac_CODGEO vac_wage vac_rome vac_dtecrepof vac_aplrome vac_salmenest vac_typctr ///
vac_durheb_hours vac_durhebsta2 vac_trcsalsta vac_wage vacWcorr  vac_wage_actual vac_siret vac_qlf vac_siren
*drop if vac_wage==.
duplicates drop 
save clogit_job_info, replace 

 
use base_jobchoice_total_, clear

* dropping job ads to which no one from the relevant cell applied 
bys numofr: egen proba_appliquer=mean(applied)
drop if proba_appliquer==0
drop proba_appliquer

* dropping  applicants who never applied in the revelant cell (doesn't drop any observation) 
bys idfhda: egen proba_appliquer=mean(applied)
drop if proba_appliquer==0
drop proba_appliquer

merge m:1 idfhda  using clogit_de_info
keep if _m==3
drop _m


merge m:1 numofr using clogit_job_info
keep if  _m==3
drop _m



*cap drop distance_de_vac
gen distance_de_vac=sqrt((de_yr-vac_yo)*(de_yr-vac_yo)+(de_xr-vac_xo)*(de_xr-vac_xo))
replace distance_de_vac=distance_de_vac/1000
replace distance_de_vac=(2/3)*sqrt((de_superficyr*0.01)/3.14) if depcom2==vac_CODGEO
label var distance_de_vac "Distance btw worker residence and vacancy workplace (in KM)"

gen log_distance=log(distance_de_vac)

gen female_log_distance=log_distance*female

capture drop year quarter
gen quarter=quarter(vac_dtecrepof)
gen year=year(vac_dtecrepof)
gen period_quarter=yq(year,quarter)
format period_quarter %tq

gen C=1

cap drop missing_cov
gen missing_cov=0	
foreach var in 	applied   age exper  education_ female period_quarter {
	disp "`var'"
	count if missing(`var')
	replace missing_cov=missing_cov|missing(`var')
	}
tab missing_cov	


global SAMP="resWcorr_minW>1.05&resWcorr_minW!=."
disp "${SAMP}"

egen group=group(numofr female )


clogit applied   ///
	log_distance female_log_distance female,  group(group) vce(robust)
outreg2 using ${OUTPUT}table_choice_model.tex, replace   ///
	keep(log_distance female_log_distance female) ///
	addtext("Job ad FE","X","Sample","","Worker controls","")

	clogit applied   ///
	log_distance female_log_distance ///
	female if ${SAMP},  group(group) vce(robust)
outreg2 using ${OUTPUT}table_choice_model.tex, append    ///
	keep(log_distance female_log_distance female) ///
	addtext("Job ad FE","X","Sample",">minW workers","Worker controls","")
	
	clogit applied   ///
	log_distance female_log_distance ///
	female i.age i.education_ i.exper foreign if ${SAMP},  group(group) vce(robust) 
outreg2 using ${OUTPUT}table_choice_model.tex, append  ///
	keep(log_distance female_log_distance female) ///
	addtext("Job ad FE","X","Sample",">minW workers","Worker controls","X")






