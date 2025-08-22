* This do-file creates the job-to-job transitions dataset

* INPUT:
* dads_2004_2012_red
* de
* commune_superficie
* ze

* INTERMEDIATE: 
* job2job_2004_2012_
* E_U_E_transitions

* OUTPUT:
* job2job_2004_2012

clear all


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

global last_year="2012"
global first_year="2004"

*set maxvar 10000
set max_memory 14g
set matsize 2000

use dads_2004_2012_red.dta, clear

****************************
* extra cleaning and sample selection
* we exclude annex jobs
keep if filtre=="1"
drop filtre

* we exclude jobs with missing var.
drop if missing(sb)
drop if missing(dp)
drop if missing(nbheur)
drop if nbheur==0
sort idfhda ddebE dfinE 
duplicates report idfhda ddebE dfinE

sort idfhda ddebE dfinE sir
duplicates report idfhda ddebE dfinE sir


****************************
* tag job-to-job transition

* entsir gives the year in which the indiv entered in the firm 
sum entsir, d
gen E1=floor(entsir)==an
label var E1 "Indicator of destination job"

by idfhda: gen E0=E1[_n+1]
label var E0 "Last emp spell before hiring in new firm"

cap drop durNE
by idfhda: gen durNE=ddebE-dfinE[_n-1] if E1==1
label var durNE "Duration btw job separation and hiring in new firm"

replace durNE=. if durNE<0

save job2job_2004_2012_.dta, replace

* we merge new hirings with U registers
* to tag whether the indiv was registered 
* as unemployed between her last job and the new hire
use job2job_2004_2012_.dta, clear

by idfhda: gen dfinE0=dfinE[_n-1] 
format dfinE0 %td

*keep new hirings
keep if E1==1
drop if dfinE0==.
drop if durNE<0
keep idfhda sir ddebE dfinE dfinE0
duplicates report
duplicates report idfhda sir ddebE
 
* join U registers
joinby idfhda using de
sort idfhda ddebE sir datins datann
count if missing(datins)
count if missing(datann)
replace datann=mdy(1,1,2013) if missing(datann)

* tag whether U spell intersects with NEmp spell 
cap drop U_spell_
gen U_spell_=0
replace U_spell_=1 if datins<=ddebE & datann>=dfinE0
by idfhda ddebE sir: egen U_spell=total(U_spell_) 

* keep only new hirings with a previous U spell
keep idfhda sir ddebE dfinE U_spell
keep if U_spell>0
replace U_spell=1 if missing(U_spell)==0
duplicates drop 
sort idfhda ddebE sir
compress
save E_U_E_transitions.dta, replace

use job2job_2004_2012_.dta, clear
* merge with list of new hirings with previous U spell
merge 1:1 idfhda ddebE dfinE sir using E_U_E_transitions
label var U_spell "Unemp. between hiring date and last separation"
replace U_spell=0 if missing(U_spell)


* we choose the folling sample definition
global SAMP="E1==1 & U_spell==0 & inrange(durNE,0,190)"

* prepare variables for regressions
sort idfhda ddebE dfinE sir 
tab ce
drop if ce=="D"
gen dp_FTE=dp if ce=="C"
replace dp_FTE=0.5*dp if ce=="P"
by idfhda: gen expe=sum(dp_FTE)
label var expe "Nb of days worked since 2004"


gen dist=sqrt((yt-yr)*(yt-yr)+(xt-xr)*(xt-xr))/1000
label var dist "Commuting distance (in km)"
replace dist=(2/3)*sqrt((superficie*0.01)/3.14) if codegeot==codegeor

sort idfhda ddebE dfinE sir
duplicates report idfhda ddebE dfinE sir

foreach var in wage_hourly dp {
	cap drop `var'E0
	by idfhda: gen `var'E0=`var'[_n-1] if E1==1
	cap drop log_`var'
	gen log_`var'=log(`var')
	cap drop log_`var'E0
	gen log_`var'E0=log(`var'E0)
}

foreach var in sb sbr wage dist nbheur expe {
	cap drop `var'E0
	by idfhda: gen `var'E0=`var'[_n-1] if E1==1
	cap drop log_`var'
	gen log_`var'=log(`var'+1)
	cap drop log_`var'E0
	gen log_`var'E0=log(`var'E0+1)
}

count if missing(cs2)
count if missing(pcs4)
count if missing(pcs_v2)

tab contrat_travail
gen CDI=contrat_travail=="01"
gen FT=ce=="C"
encode a38, gen(a38_)
encode pcs4, gen(pcs4_)
replace pcs4_=0 if missing(pcs4_)

foreach var in cs2 CDI FT a38_  pcs4_ {
	cap drop `var'E0
	by idfhda: gen `var'E0=`var'[_n-1] if E1==1
}

tab cs2E0, m
foreach var in cs2E0 {
	cap drop `var'_	
	encode `var', gen(`var'_)
	replace `var'_=0 if missing(`var')
}


gen female=sx=="0"
gen age=an-annai
label var age "Age"

cap drop dip_tot_
encode dip_tot, gen(dip_tot_)
replace dip_tot_=0 if missing(dip_tot)

gen education=.
replace education=5 if dip_tot=="2"
replace education=9 if dip_tot=="3"
replace education=11 if dip_tot=="4"
replace education=12 if dip_tot=="5"|dip_tot=="6"
replace education=14 if dip_tot=="7"
replace education=17 if dip_tot=="8"
label var education "Years of education"

compress
save job2job_2004_2012.dta, replace

* add commuting zones
use job2job_2004_2012.dta, clear

cap drop depcom
gen depcom=codegeor
label var depcom "Residence municipality"

cap drop _m
merge m:1 depcom using ${SOURCES}ze 
drop if inlist(substr(depr,1,2),"97","98","99")
keep if _m==3
drop _m

sort idfhda ddebE dfinE sir  
compress
save job2job_2004_2012.dta, replace


	
