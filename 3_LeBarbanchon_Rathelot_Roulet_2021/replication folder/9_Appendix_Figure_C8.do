* this do-file creates Appendix Figure C8 (distribution of distances  between workers' residence and vacancy workplace)

* vacancy sample: posted in 2010

* For every municipality, compute the number of vacancies at a distance of 1 KM, 2 KM etc
* then we append all with weights depending on number of job-seekers in each municipality in 2010 (computed from our main dataset)

* INPUT: 
* vac_com_quarter_2005_2012
* basedetravail_final_qje

* INTERMEDIATE:
* vac_com and de_com

* OUTPUT:
* hist_1_14636

clear all

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

set matsize 1000
set maxvar 10000
set max_memory 11g

use ${SOURCES}ZE2010, clear
sort CODGEO
gen CODGEO_=_n
label var CODGEO_ "Numerical index of municipalities"
keep CODGEO CODGEO_ 
save CODGEO_index, replace


*********************************************
* prepare quarterly data of vacancy postings at municipality level
use ${SOURCES}vac_com_quarter_2005_2012, clear
count if missing(ze)
count
sort depcom
gen CODGEO=depcom
replace CODGEO="75056" if inrange(CODGEO,"75101","75120") 
replace CODGEO="69123" if inrange(CODGEO,"69381","69389")
replace CODGEO="13055" if inrange(CODGEO,"13201","13216") 
sort CODGEO
merge m:1 CODGEO using ${SOURCES}ZE2010, keepusing(ZE2010)
drop if _m==2
drop if _m==1
drop _m
rename depcom depcomv
label var depcomv "Municipality of vacancy"
drop ze
rename ZE2010 ze
merge m:1 CODGEO using CODGEO_index
keep if _m==3
drop _m
drop CODGEO
sort ze period_quarter depcom
save vac_com_quarter_2005_2012.dta, replace



*********************************************
* prepare vacancy sample

use vac_com_quarter_2005_2012.dta, clear
keep if inrange(period_quarter,yq(2010,1),yq(2010,4))
collapse (sum) vac_com_quarter (first) ze CODGEO_, by(depcomv)
label var depcomv "Municipality of vacancy"
label var CODGEO_ "Numerical index of municipalities"
rename  vac_com_quarter vac_com
label var vac_com "Number of new vacancies per municipality"
gen INSEE_COM=depcomv
merge m:1 INSEE_COM using ${SOURCES}GEOFLA_COMMUNE, ///
	keepusing(X_CENTROID Y_CENTROID SUPERFICIE)
keep if _m==3
rename X_CENTROID xv
rename Y_CENTROID yv
label var xv "X-geo coord of residence (centroid of municip)"
label var yv "Y-geo coord of residence (centroid of municip)"
rename SUPERFICIE superficiev
label var superficiev "Area in hectares of residence municipality"
drop _m
drop INSEE_COM
drop CODGEO_
gen C=1
save vac_com_2010.dta, replace



*********************************************
* prepare worker sample 

use basedetravail_final_qje, clear
keep if year==2010
gen C=1
collapse (sum) C (first) ze, by(depcom)
*collapse (sum) C, by(depcomr_E0)
rename C de_com
label var de_com "nb of new unemployed per municipality"
rename ze ze_de

gen CODGEO=depcom
replace CODGEO="75056" if inrange(CODGEO,"75101","75120") 
replace CODGEO="69123" if inrange(CODGEO,"69381","69389")
replace CODGEO="13055" if inrange(CODGEO,"13201","13216")
merge m:1 CODGEO using CODGEO_index
keep if _m==3
drop _m
drop CODGEO

gen INSEE_COM=depcom
merge m:1 INSEE_COM using ${SOURCES}GEOFLA_COMMUNE, ///
	keepusing(X_CENTROID Y_CENTROID SUPERFICIE)
keep if _m==3
rename X_CENTROID xr
rename Y_CENTROID yr
label var xr "X-geo coord of residence (centroid of municip)"
label var yr "Y-geo coord of residence (centroid of municip)"
rename SUPERFICIE superficier
label var superficier "Area in hectares of residence municipality"
drop _m
drop INSEE_COM
* variables to perform pseudo-matches below 
gen C=1
save de_com_2010, replace


use de_com_2010, clear
count 
* there are: 14,636 municipalities with job seekers
total de_com
gen toto=runiform()
gsort -de_com +toto
gen progress=sum(de_com)
replace progress=progress/66205
count if progress<0.9
save de_com_2010, replace


forvalues i=1(1)14636 {

use de_com_2010, clear
keep if _n==`i'
joinby C using vac_com_2010

gen distance=sqrt((yv-yr)*(yv-yr)+(xv-xr)*(xv-xr))
replace distance=distance/1000
replace distance=(2/3)*sqrt((superficier*0.01)/3.14) if depcom==depcomv

gen distance_=floor(distance)
keep if inrange(distance_,0,200)
collapse (first) depcom de_com ze_de CODGEO_ ///
	(sum) vac_com, by(distance_)

save hist_`i', replace
	
}



use hist_1, clear
forvalues i=2(1)14636 {
append using hist_`i'
}
compress
save hist_1_14636, replace



********************************************************************************
* analyze unconditional commute offer density

use hist_1_14636, clear

sort depcom distance_

sort depcom distance_
by depcom: gen rk=_n
total de_com if rk==1 

* we renormalize to take into account the distribution of workers across municipalities
replace vac_com=vac_com*de_com/66205
collapse (sum) vac_com, by(distance_)
label var vac_com "Vacancy Frequency"
label var distance_ "Vacancy-residence distance (in KM)"

keep if inrange(distance_,0,120)

tw bar vac_com distance_ if inrange(distance_,0,120), ///
	xlabel(0(20)120) ///
	title("Distribution of distances" /// 
	"from worker residence to vacancy workplace") ///
	note("Sample: new jobseekers in 2010, vacancies posted in 2010" ///
	"Weighted by jobseekers distribution over municipalities")
graph export ${OUTPUT}hist_distance_residence_vacancy.pdf, replace	

total vac_com
*320,762
replace vac_com=vac_com/320762
label var vac_com "Vacancy Density"

tw bar vac_com distance_ if inrange(distance_,0,120), ///
	xlabel(0(20)120) ///
	title("Distribution of distances" /// 
	"from worker residence to vacancy workplace") ///
	note("Sample: new jobseekers in 2010, vacancies posted in 2010" ///
	"Weighted by jobseekers distribution over municipalities")
graph export ${OUTPUT}density_distance_residence_vacancy.pdf, replace	


