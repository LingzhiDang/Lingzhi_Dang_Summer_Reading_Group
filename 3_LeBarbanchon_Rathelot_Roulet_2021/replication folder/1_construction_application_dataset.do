* This do-file prepares the MER data
* merges the dataset with Vacancies and de dataset
* left-joins with our workers sample


* INPUT: 
* m0, 
* de from 0_prepare_de, 
* vacancies`year'_all_clean : this is cleaned vacancy-level data for each year
*  basedetravail_final_qje from 1_construction_main_dataset.do

* INTERMEDIATE:
* m0_de_vac

* OUTPUT: 
* m0_de_vac_travail.dta





clear all
set matsize 1000
set maxvar 10000
set max_memory 11g


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"


**************************************************************************
* A. clean MER, vacancy and DE  datasets and left join all 3

use ${SOURCES}m0, clear

drop id0
sort numofr idfhda datmer 
order numofr idfhda datmer


drop if missing(numofr)

duplicates tag numofr idfhda, gen(dup)
drop if dup>0
drop dup

order numofr idfhda datmer orimer resmer motifres 

*tab orimer
drop if orimer=="N"
drop if orimer=="P"
encode orimer, gen(orimer2)
label var orimer2 "Who initiates contact?"
label drop orimer2
label define orimer2 1	"PES" ///
2	"Worker" ///
3	"Firm"
label val orimer2 orimer2
drop orimer
rename orimer2 orimer
tab resmer

gen year=year(datmer)

keep if inrange(year,2010,2012)
drop if inlist(region,"941","952","953","954","955")
save m0_2010_2012.dta, replace


use vacancies2010_all_clean, clear
drop reglietrv
append using vacancies2011_all_clean
drop reglietrv
append using vacancies2012_all_clean
drop reglietrv
drop if missing(idtpof)
*unique idtpof
duplicates tag idtpof, gen(dup2)
tab dup2
drop if dup2>0
drop dup2
compress

keep idtpof vac_duration vac vac_filled_ vac_filled ///
	dtecrepof dteeft dtedebctr dtesoroff filled ///
	nbroff salmenest trcsalsta nivfor secfor rome aplrome qlf ///
	durhebsta durheb cndexesta cndexe durctr ///
	typexp durexp durexpmonth typoffsta typoff typctr ///
	quoinimer idcdol anon appro ///
	siret naf trceffeta untrateta cometa ///
	natctr natsrv natdetoff etapof ///
	year_end month_end year month_start moista2 ///
	advance siren occupation jobtit ///
	wage minW any_exp typoffsta2 educ_req educ durhebsta2 highest_qlf ///
	CODGEO LIBGEO ZE2010 LIBZE2010 REG2016

cap drop vac_filled

foreach var in 	dtecrepof dteeft dtedebctr dtesoroff filled ///
	nbroff salmenest trcsalsta nivfor secfor rome aplrome qlf ///
	durhebsta durheb cndexesta cndexe durctr ///
	typexp durexp durexpmonth typoffsta typoff typctr ///
	quoinimer idcdol anon appro ///
	siret naf trceffeta untrateta cometa ///
	natctr natsrv natdetoff etapof ///
	year_end month_end year month_start moista2 ///
	advance siren occupation jobtit ///
	wage minW any_exp typoffsta2 educ_req educ durhebsta2 highest_qlf ///
	CODGEO LIBGEO ZE2010 LIBZE2010 REG2016 {
rename `var' vac_`var'
}

save vacancies20102012_all_clean, replace


use m0_2010_2012.dta, clear
rename rome rome_m0
gen idtpof=numofr
merge m:1 idtpof using vacancies20102012_all_clean
drop if _m==2
drop if _m==1
drop _m

drop catoff natcont typecont

sort vac_CODGEO
gen INSEE_COM=vac_CODGEO
merge m:1 INSEE_COM using ${SOURCES}GEOFLA_COMMUNE, ///
	keepusing(X_CENTROID Y_CENTROID)

drop if _m==2
rename X_CENTROID vac_xo
rename Y_CENTROID vac_yo
label var vac_xo "X-geo coord of job ad (centroid of municip)"
label var vac_yo "Y-geo coord of job ad (centroid of municip)"
drop _m
drop INSEE_COM
label var vac_CODGEO "Municipality code of job ad" 

save m0_intermediate.dta, replace


use de, clear
replace datann=mdy(1,1,2013) if missing(datann)
gen year_end=year(datann)
gen samp=year_end>2009
keep if samp
drop samp
*unique idfhda
sort idfhda datins

save de_20102012.dta, replace


use m0_intermediate, clear

cap drop year
gen year_mer=year(datmer)

sort idfhda datmer
joinby idfhda using de_20102012

keep if inrange(datmer,datins,datann)

unique numof idfhda
duplicates tag numof idfhda, gen(dup_)
tab dup_
drop if dup_>0

compress
save m0_vac_de.dta, replace




*************************************************************************
* B. create analysis variables

use m0_vac_de.dta, clear

sort idfhda datins 
merge m:1 idfhda datins using basedetravail_final_qje, ///
	keepusing(pastW pastW_hourly postW postW_hourly sbE0 sbE1 ///
	ceE0 ceE1 contratE0 contratE1 dpE0 dpE1 nbheurE0 nbheurE1 ///
	a38E0 a38E1 sir_E0 sir_E1 ///
	pcsE0 pcsE1 fapE0 fapE0_ fapE1 fapE1_ fapU fapU_ ///
	yt_E0 yt_E1 xt_E0 xt_E1 yr_E0 yr_E1 xr_E0 xr_E1 ///
	depcomt_E0 depcomt_E1 depcomr_E0 depcomr_E1 ///
	distanceE0 log_distanceE0 distanceE1 log_distanceE1 ///
	prev_fulltime prev_cdi fulltimeE1 cdiE1 log_PBD)

drop if _m==2
drop _m

* outcome!
gen hire=resmer=="A"

********
* worker variables 

keep if inrange(age,18,55)

encode rome, gen(de_rome)

gen dur_U_mer=datmer-datins
label var dur_U_mer "Unemployment duration at application date"
drop if dur_U_mer>2443

gen INSEE_COM=depcom2
merge m:1 INSEE_COM using ${SOURCES}GEOFLA_COMMUNE, ///
	keepusing(X_CENTROID Y_CENTROID SUPERFICIE)

drop if _m==2
drop if _m==1
rename X_CENTROID de_xr
rename Y_CENTROID de_yr
rename SUPERFICIE de_superficyr
label var de_xr "X-geo coord of unemployed (centroid of municip)"
label var de_yr "Y-geo coord of unemployed (centroid of municip)"
label var de_superficyr "Superficy of unemployed municipality"
drop _m
drop INSEE_COM

destring ZE2010, gen(de_cz)
label var de_cz "CZ of job-seeker"

*************
* Vacancy characteristics

gen vac_durheb_hours=floor(vac_durheb/100)
label var vac_durheb_hours "Posted job nb of hours worked"

gen log_vac_hours=log(vac_durheb_hours)
label var vac_durheb_hours "Posted hours worked on job ad (in log)"

gen datmer_monthly=mofd(datmer)
format datmer_monthly %tm
label var datmer_monthly "Contact date"

gen vac_dtecrepof_monthly=mofd(vac_dtecrepof)
format vac_dtecrepof_monthly %tm
label var vac_dtecrepof_monthly "Vacancy posting date (in month)"


encode vac_ZE2010, gen(vac_ZE2010_)

foreach var in vac_dtecrepof {
capture drop minW`var'
gen 	minW`var'=.
replace minW`var'=1154 if `var'<(mdy( 6,30,2005)) & missing(`var')==0
replace minW`var'=1217 if inrange(`var',mdy( 6,30,2005),mdy( 6,30,2006))	
replace minW`var'=1254 if inrange(`var',mdy( 6,30,2006),mdy( 6,29,2007))	
replace minW`var'=1280 if inrange(`var',mdy( 6,29,2007),mdy( 4,29,2008))	
replace minW`var'=1308 if inrange(`var',mdy( 4,29,2008),mdy( 6,28,2008))	
replace minW`var'=1321 if inrange(`var',mdy( 6,28,2008),mdy( 6,26,2009))	
replace minW`var'=1337 if inrange(`var',mdy( 6,26,2009),mdy(12,17,2009))	
replace minW`var'=1343 if inrange(`var',mdy(12,17,2009),mdy(12,17,2010))	
replace minW`var'=1365 if inrange(`var',mdy(12,17,2010),mdy(11,30,2011))	
replace minW`var'=1393 if inrange(`var',mdy(11,30,2011),mdy(12,23,2011))	
replace minW`var'=1398 if inrange(`var',mdy(12,23,2011),mdy( 6,29,2012))	
replace minW`var'=1425 if inrange(`var',mdy( 6,29,2012),mdy(12,21,2012))	
replace minW`var'=1430 if inrange(`var',mdy(12,21,2012),mdy(12,19,2013))	
replace minW`var'=1445 if inrange(`var',mdy(12,19,2013),mdy(12,22,2014))	
replace minW`var'=1457 if `var'>mdy(12,22,2014) & missing(`var')==0
count if missing(minW`var')
label var minW`var' "Min wage prevailing at `var'"
}

cap drop vacWcorr
gen vacWcorr=round(vac_wage)
foreach var in vac_dtecrepof {
replace vacWcorr=minW`var' if vacWcorr<minW`var' & missing(vacWcorr)==0
label var vacWcorr "FTE gross monthly posted wage at posting date"
}


foreach wage in vac_wage {
foreach date in vac_dtecrepof {
capture drop `wage'_at_minW
gen `wage'_at_minW=inrange(`wage',minW`date'-1,minW`date'+1) ///
	if missing(`wage')==0
label var `wage'_at_minW "Vacancy wage is at the min wage prevailing at posting"
}
}

foreach wage in vac_wage {
capture drop `wage'_at_anyminW
gen `wage'_at_anyminW=0 if missing(`wage')==0
foreach minW in 1154 1217 1254 1280 1308 1321 1337 1343 1365 1393 1398 1425 1430 {
replace `wage'_at_anyminW=`wage'_at_anyminW+inrange(`wage',`minW'-1,`minW'+1) ///
	if missing(`wage')==0
}
label var `wage'_at_anyminW "Reservation at any min wage level prevailing from 2006 to 2012"
}


gen log_vac_wage=log(vac_wage)	

	
cap drop vac_fulltime
gen vac_fulltime=vac_durheb_hours>34 if missing(vac_durheb_hours)==0
label var vac_fulltime "Ad for a full-time job"

cap drop vac_wage_actual
gen vac_wage_actual=vac_wage*vac_durheb_hours/35
label var vac_wage_actual "Monthly posted wage accounting for hours required"
gen log_vac_wage_actual=log(vac_wage_actual)


replace vac_typctr=1 if vac_typctr==12	
replace vac_typctr=2 if vac_typctr==13	
replace vac_typctr=3 if vac_typctr==14	
replace vac_typctr=4 if vac_typctr==15	
replace vac_typctr=5 if vac_typctr==16	
replace vac_typctr=6 if vac_typctr==17	

replace vac_typoff=1 if vac_typoff==12	
replace vac_typoff=2 if vac_typoff==13	
replace vac_typoff=3 if vac_typoff==14	
replace vac_typoff=4 if vac_typoff==15	
replace vac_typoff=5 if vac_typoff==16	
replace vac_typoff=6 if vac_typoff==17	
replace vac_typoff=7 if vac_typoff==18	
replace vac_typoff=8 if vac_typoff==19	

cap drop vac_cdi
gen vac_cdi=vac_typoff==1 if missing(vac_typoff)==0


****************
* DISTANCES BTW worker characteristics and vacancy requirements

gen distance_de_vac=sqrt((de_yr-vac_yo)*(de_yr-vac_yo)+(de_xr-vac_xo)*(de_xr-vac_xo))
replace distance_de_vac=distance_de_vac/1000

replace distance_de_vac=(2/3)*sqrt((de_superficyr*0.01)/3.14) if depcom2==vac_CODGEO
label var distance_de_vac "Distance btw worker residence and vacancy workplace (in KM)"

gen log_distance_de_vac=log(distance_de_vac)

gen de_vac_muni=depcom2==vac_CODGEO
labe var de_vac_muni "Applicant lives in the workplace municipality"

gen de_vac_rome=vac_rome==rome
label var de_vac_rome "Same occ. on job ad and stated by worker"

cap drop vac_education
gen vac_education=.
replace vac_education=0 if vac_nivfor=="AFS"
replace vac_education=5 if vac_nivfor=="CP4"
replace vac_education=7 if vac_nivfor=="CFG"
replace vac_education=9 if vac_nivfor=="C3A"
replace vac_education=10.5 if vac_nivfor=="C12"
replace vac_education=11 if vac_nivfor=="NV5"
replace vac_education=12 if vac_nivfor=="NV4"
replace vac_education=14 if vac_nivfor=="NV3"
replace vac_education=15.5 if vac_nivfor=="NV2"
replace vac_education=18 if vac_nivfor=="NV1"
label var vac_education "Required Nb of years of initial education"

cap drop de_vac_educ
gen de_vac_educ=99
replace de_vac_educ=vac_education==education if vac_educ_req==1
label var de_vac_educ "Applicant has the min required level of education"

drop if vac_durexpmonth>120
replace exper=12*exper
label var exper "Worker experience in month"

replace exper=360 if exper>360 & missing(exper)==0 
gen de_vac_exp=exper>=vac_durexpmonth
label var de_vac_exp "Worker has at the least the required experience" 

gen dur_mer=datmer-vac_dtecrepof
label var dur_mer "Duration btw posting date and contact date"
sum dur_mer, d
replace dur_mer=r(p1)  if missing(dur_mer)==0 & dur_mer<r(p1)
replace dur_mer=r(p99) if missing(dur_mer)==0 & dur_mer>r(p99)

destring qualif, replace
gen de_vac_qlf=qualif==vac_qlf
label var de_vac_qlf "Same qualification for applicant and vacancy"


********
* create variables for the pool of applicants to a vacancy 
sort numofr datmer
egen numofr_=group(numofr)
sort numofr_ datmer
xtset numofr_
by numofr_: egen vac_female=mean(female) 
label var vac_female "Share of female applicants to the vacancy"
by numofr_: gen vac_nb=_N 
label var vac_nb "Total nb applicants to the vacancy"

gen 	vac_diversity_gender=0
replace vac_diversity_gender=1 if vac_female>0 & vac_female<1 
label var vac_diversity_gender "Vac. has applicants of both gender"

by numofr_: gen vac_rk=_n

by numofr_: egen vac_hire=max(hire)
label var vac_hire "At least one hire on the vacancy"


**********************
* vars for the pool of applications per applicant

sort idfhda_ datmer
by idfhda_: gen de_rk=_n
by idfhda_: gen de_nb=_N
label var de_nb "Total nb applications by job seeker"
by idfhda_: egen de_hire=max(hire)
label var de_hire "Job seeker hired through PES application" 
sort numofr_ datmer

**********************
* sampling var

sort idfhda_ datmer
by idfhda_:  gen samp_=uniform() if de_rk==1
by idfhda_: egen samp=mean(samp)
drop samp_
sort numofr_ datmer



********************
* non minimu wage workers flag 

capture drop minW
gen 	minW=.
replace minW=1154 if datins<(mdy( 6,30,2005))
replace minW=1217 if inrange(datins,mdy( 6,30,2005),mdy( 6,30,2006))	
replace minW=1254 if inrange(datins,mdy( 6,30,2006),mdy( 6,29,2007))	
replace minW=1280 if inrange(datins,mdy( 6,29,2007),mdy( 4,29,2008))	
replace minW=1308 if inrange(datins,mdy( 4,29,2008),mdy( 6,28,2008))	
replace minW=1321 if inrange(datins,mdy( 6,28,2008),mdy( 6,26,2009))	
replace minW=1337 if inrange(datins,mdy( 6,26,2009),mdy(12,17,2009))	
replace minW=1343 if inrange(datins,mdy(12,17,2009),mdy(12,17,2010))	
replace minW=1365 if inrange(datins,mdy(12,17,2010),mdy(11,30,2011))	
replace minW=1393 if inrange(datins,mdy(11,30,2011),mdy(12,23,2011))	
replace minW=1398 if inrange(datins,mdy(12,23,2011),mdy( 6,29,2012))	
replace minW=1425 if inrange(datins,mdy( 6,29,2012),mdy(12,21,2012))	
replace minW=1430 if inrange(datins,mdy(12,21,2012),mdy(12,19,2013))	
count if missing(minW)
tab minW
label var minW "Min wage prevailing at the registration date"

capture drop resW_at_anyminW
gen resW_at_anyminW=0
foreach minW in 1254 1280 1308 1321 1337 1343 1365 1393 1398 1425 {
replace resW_at_anyminW=resW_at_anyminW+inrange(resW,`minW'-1,`minW'+1)
}
label var resW_at_anyminW "Reservation at any min wage level prevailing from 2006 to 2012"

capture drop resWcorr
gen     resWcorr=round(resW)
replace resWcorr=minW if resW_at_anyminW==1
label var resWcorr "Reservation wage (corrected)"

capture drop resWcorr_minW
gen resWcorr_minW=resWcorr/minW
label var resWcorr_minW "Reservation wage (corrected) divided by min wage"

* alternative definitions of non minW workers 
cap drop vac_occ_minW
bys vac_rome: egen vac_occ_minW=mean(vac_wage_at_minW) if vac_rk==1
label var vac_occ_minW "Share of job ads at the minW within vacancy occupation"

preserve
keep vac_rome vac_occ_minW
drop if missing(vac_rome)
drop if missing(vac_occ_minW)
rename vac_rome rome
sort rome
duplicates drop rome vac_occ_minW, force
rename vac_occ_minW occ_minW
label var occ_minW "Share of job ads at the minW within occupation"
save vac_occ_minW.dta, replace
restore

merge m:1 rome using vac_occ_minW
keep if _m==3
drop _m
label var occ_minW "Share of job ads at the minW within worker occupation"

sum occ_minW, d
cap drop samp_occminW
gen samp_occminW=occ_minW>=r(mean) if missing(occ_minW)==0
label var samp_occminW "Worker searches occupation with high share of minèw_wage ads" 


****************
* compute weight vars 

bys de_rome: gen  size_rome=_N
label var size_rome "Nb of applications by job-seekers preferring a given occupation"
bys de_rome: egen size_rome_women=total(female)
label var size_rome "Nb of applications by women preferring a given occupation"
bys de_rome: egen size_rome_men=total(male)
label var size_rome "Nb of applications by men preferring a given occupation"
bys de_rome: gen  de_rome_rk=_n
label var de_rome_rk "to keep one observations per occupation"


gen share_rome_women=size_rome_women/size_rome
label var share_rome_women "Share of women within a given preferred occupation"

gen weight=1 
replace weight= size_rome_women/size_rome_men if female==0
label var weight "Weight to match the occupation distribution of men to that of women "

compress



save m0_vac_de_travail.dta, replace


