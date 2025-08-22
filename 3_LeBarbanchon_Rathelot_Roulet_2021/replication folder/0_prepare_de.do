* This do-file prepares the DE data for various merge 


* INPUT: ${SOURCES}\de
 
* OUTPUT: de 

clear all
set matsize 1000
set maxvar 10000
set max_memory 11g

global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"

*******************************************************************************
* A. PREPARE DATA OF U SPELLS (DE)


use ${SOURCES}\de.dta, clear

************************
* Create some panel and date vars

egen idfhda_=group(idfhda)
gsort +idfhda_ -ndem 
xtset idfhda_

by idfhda_: gen dur_btw=datins-datann[_n-1]
label var dur_btw "non-U duration before U spell" 

gen regist_first=missing(dur_btw)
label var regist_first "First U spell ever"


cap drop regist_full
gen regist_full=regist_first
replace regist_full=dur_btw>181 if regist_first==0
label var regist_full "Full registration process"

gen datins_monthly=mofd(datins)
format datins_monthly %tm
label var datins_monthly "Date when U spell begins"


********************
* data cleaning
drop if motann=="$$" | motann=="**"


********************
* sample selection I

* restrict to metropolitan France
drop if region=="952"|region=="953"|region=="954"|region=="955"
* restrict to unemployed people
drop if catregr=="5"
* catregr==5 are people looking for a job but already in a job (like contrats aides)
 

*************************
* CLEAN the RESW variable

tab salunit, m

gen salunit_mis=missing(salunit)
label var salunit_mis "The unit of reservation wage is missing"
gen salmt_mis=missing(salmt)
label var salmt_mis "Reservation wage is missing"
tab salmt_mis salunit_mis

sum salmt if salmt_mis==0 & salunit_mis==1, d 
replace salmt=. if salmt_mis==0 & salunit_mis==1

sum salmt if salunit_mis==0, d
tab salunit if salmt==0
sum salmt if salunit=="0", d
replace salmt=. if salunit=="0"
replace salunit="" if salunit=="0"

sum salmt if (salunit=="H"|salunit=="M"|salunit=="A"), d

replace salmt=. if salmt==0
replace salmt=. if salmt==999999
replace salunit="" if missing(salmt)


replace salunit_mis=missing(salunit)
replace salmt_mis=missing(salmt)


replace salunit="M" if salunit=="H" & salmt>1200
replace salunit="A" if salunit=="M" & salmt>15000
replace salunit="M" if salunit=="A" & salmt<15000
replace salunit="H" if salunit=="M" & salmt<100


gen 	resW=salmt if salunit=="M"
replace resW=salmt*151.67 if salunit=="H"
replace resW=salmt/12 if salunit=="A"
label var resW "Monthly gross reservation wage"
gen salunit_M=salunit=="M"
gen salunit_H=salunit=="H"
gen salunit_A=salunit=="A"
label var salunit_M "Unit of reservation wage is monthly"
label var salunit_H "Unit of reservation wage is hourly"
label var salunit_A "Unit of reservation wage is annual"

compress
save de.dta, replace


*********************
* create useful covariates... 

use de.dta, clear

destring motins, gen(motins_)
label var motins "Reason to register as unemployed"
label var motins_ "Reason to register as unemployed"


gen age=floor((datins-datnais)/365.25)
label var age "Age at registration"

capture drop year 
gen year=year(datins)
label var year "Calendar year of registration"
tab year

capture drop quarter
gen quarter=quarter(datins)
label var quarter "Calendar quarter of registration" 
gen period_quarter=yq(year,quarter)
label var period_quarter "Quarter (date) of registration"
format period_quarter %tq
capture drop month 
gen month = month(datins)
label var month "Calendar month at registration"  

gen male=sexe=="1"
gen female=sexe=="2"
drop sexe


gen education=.
replace education=0 if nivfor=="AFS"
replace education=5 if nivfor=="CP4"
replace education=7 if nivfor=="CFG"
replace education=9 if nivfor=="C3A"
replace education=10.5 if nivfor=="C12"
replace education=11 if nivfor=="NV5"
replace education=12 if nivfor=="NV4"
replace education=14 if nivfor=="NV3"
replace education=15.5 if nivfor=="NV2"
replace education=18 if nivfor=="NV1"
label var education "Nb of years of initial education"
tab education, m 

capture drop education_
egen education_=group(education) 

drop if education==.
drop nivfor 
drop diplome

gen married=sitmat=="M"
gen single=sitmat=="C"
gen divorced=sitmat=="D"
gen widow=sitmat=="V"
drop sitmat 


count if missing(nenf)
rename nenf nchild
destring nchild, replace
label var nchild "Number of children"

gen child = nchild>0
label var child "Has at least one child"

gen dowdatins = dow(datins)
label var dowdatins "Day of the week when registering"

gen foreign=nat!="A"

gen cdi=contrat=="1"
label var cdi "Looking for a long term contract"
gen full_time=temps=="1"
label var full_time "Looking for a full-time job"


tab mobunit, m

replace mobunit="" if mobunit=="00"
gen mobunit_mis=missing(mobunit)
gen mobdist_mis=missing(mobdist)
tab mobdist_m mobunit_mis 
drop mobunit_mis mobdist_m
replace mobdist=. if missing(mobunit)

gen mobunit_mis=missing(mobunit)
gen mobdist_mis=missing(mobdist)


replace mobdist=mobdist*60 if mobunit=="H" 
replace mobunit="TPS" if mobunit=="H"|mobunit=="MN"
replace mobdist=. if mobdist>120&mobunit=="TPS"
replace mobdist=. if mobdist>200&mobunit=="KM"
replace mobunit="" if missing(mobdist)

destring exper, replace 

compress
save de.dta, replace


********************
* Adding the commuting zone variable by merging at the municipality level with a publicly available database

use de, clear

gen CODGEO=depcom2
replace CODGEO="75056" if inrange(CODGEO,"75101","75120") 
replace CODGEO="69123" if inrange(CODGEO,"69381","69389")
replace CODGEO="13055" if inrange(CODGEO,"13201","13216") 
sort CODGEO
merge m:1 CODGEO using ${SOURCES}ZE2010, keepusing(ZE2010)

cap drop CODGEO
drop if _m==2
drop _m
compress
save de, replace



