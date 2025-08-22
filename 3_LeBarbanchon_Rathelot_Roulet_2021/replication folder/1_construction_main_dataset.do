
* this do-file constructs our main dataset


* INPUT: 
* original pjc and di from sources
* de from 0_prepare_de.do
* dads_2004_2012_red, dads_cov, dads_2004_2012_idfhda from 0_prepare_dads.do

* INTERMEDIATE:
* inflow_claimants

* OUTPUT:
* basedetravail_final_qje


****************************************************************************
* A. Select an inflow of new claimants in ARE 2006, 2009 and 2011 (from PJC and DI)
* B. Match with the corresponding registered U spell (from DE)
* C. Match with Employment spells (from DADS)
* D. Normalizing some wage variable relative to minimum wage
* E. extra transformation of variables 


global path_project "C:\Users\Public\Documents\resW\export_dofile_soumission\"

cd ${path_project}data\

global SOURCES=

global OUTPUT="${path_project}output\"



global final_year="2012"

set more off, permanently
*use ${SOURCES}droit, clear

*******************************************************************************
* A. Select an inflow of new claimants in ARE 2006, 2009 and 2011 (from PJC)
****************************************************************************

* prepare di data to get the benefit type of the claim (general, annex 4, 8, 10)

use ${SOURCES}di, clear

sort idfhda region droit cdtdtfin dateouv

keep if allocation=="64"|allocation=="82"|allocation=="AC"
keep idfhda region cdtdtfin droit mtsjr dateouv allocation fil regpart durpayee
duplicates drop
* very few

sort idfhda droit dateouv
count if missing(regpart)
count if missing(mtsjr)
sum mtsjr, d
replace mtsjr=. if mtsjr==0

collapse (firstnm) regpart mtsjr (sum) dur_indemnisee=durpayee, by(idfhda droit)

label var regpart 		"CODE REGIME PARTICULIER"
label var mtsjr 		"MONTANT RETENU SJR" 
label var dur_indemnisee "Actual benefit duration"
count
compress 
save di_regpart, replace   




set more off
foreach geo in 1 2 3 4 5 7 8 9 { 

use ${SOURCES}pjc_`geo', clear
*use ${SOURCES}pjc_1, clear

sort idfhda droit cdtdtfin ddebpjc
*br idfhda droit cdtdtfin ddebpjc if allocation=="64"|allocation=="82"|allocation=="AC"

format odddmax %9.0g

destring pafuaffi, replace

replace pafdaffi="" if pafuaffi==0
replace pafuaffi=.  if pafuaffi==0

replace oddddpra=. if oddddpra==2936183 


foreach date in cdtdtdeb cdtdtfin odddtdpr odddtfpr {
replace `date'=. if `date'==2936183 
}

cap drop dur_lastjob
gen dur_lastjob=cdtdtfin-cdtdtdeb+1
lab var dur_lastjob "Duration of last job before U"



* Benefits= ARE 2006 or 2009 or 2011 
tab allocation
keep if allocation=="64"|allocation=="82"|allocation=="AC"

tab allocation filiere, m
* drop inconsistent observations 
drop if allocation=="64" & (filiere=="A"|filiere=="B"|filiere=="C"|filiere=="D")
drop if allocation=="82" & (filiere=="A"|filiere=="B"|filiere=="C"|filiere=="D")
count


gen cdouvpjc1=cdouvpjc=="01" 
tab cdouvpjc1
bys idfhda droit: egen cdouvpjc1_=total(cdouvpjc1)
label var cdouvpjc1_ "new claim"

gen cdouvpjc2=cdouvpjc=="02" 
tab cdouvpjc2
bys idfhda droit: egen cdouvpjc2_=total(cdouvpjc2)
label var cdouvpjc2_ "Readmission sur le droit"
tab cdouvpjc2_

sort idfhda droit ddebpjc
by idfhda droit: gen rk=_n
label var rk "Rank of pjc within droit"

drop if cdouvpjc1_>1

drop if cdouvpjc2_>1 & cdouvpjc1_==1
drop if cdouvpjc2_>2 & cdouvpjc1_==0
* we drop droit with more than 2 recomputations of entitlement
drop if cdouvpjc1_==0 & cdouvpjc2_==0
* we drop claims following a transfer or a reprise,
* for which we do not observe the first UI claim

sort idfhda cdtdtfin droit ddebpjc

*******************************************************
* we clean the data wrt the date of separation variable

drop if missing(cdtdtfin)


cap drop test
by idfhda cdtdtfin: gen test=droit==droit[_n-1]
*br idfhda cdtdtfin droit ddebpjc test
cap drop rk_
by idfhda cdtdtfin: gen rk_=_n
label var rk_ "Rank of pjc within droit X cdtdtfin"
tab test if rk_==1
tab test if rk_>1
cap drop test_ 
by idfhda cdtdtfin: egen test_=min(test) if rk_>1
tab test_
*br if test_==0
drop if test_==0
* marginal cases when same date of separation is used for 2 different claims
drop test 
drop test_
drop rk_

replace mtjalloc=. if typpjc!="1"
replace mtjnet=.   if typpjc!="1"
replace mtsjrpla=. if typpjc!="1"



gen dur_pjc=dfinpjcc-ddebpjc+1
replace dur_pjc=. if typpjc!="1"
label var dur_pjc "Duration of PJC with payment"
gen UBpayment=dur_pjc*mtjalloc
label var UBpayment "Sum of UB payments on PJC"

gen sanction=typpjc=="2"|cdfer=="15"|cdfer=="16"
label var sanction "Sanction"

count if missing(oddsbnp)
replace oddsbnp=. if oddsbnp==0


count if missing(odddmax)

replace odddmax=. if odddmax==0
*sum odddmax if odddmax>1095, d
replace odddmax=. if odddmax==9998


* I am setting the zeros of these variables to missing for the collapse
destring dalnbjdi, replace	
foreach var in oddmtdif oddmticp oddmtisl dalnbjdi {
replace `var'=. if `var'==0
}

gen ddebUB=ddebpjc if typpjc=="1"
format ddebUB %td
label var ddebUB "First date of UB payment within the claim (droit X cdtdtfin)"

gen dfinUB=dfinpjc if typpjc=="1"
format dfinUB %td
label var dfinUB "Last date of UB payment within the claim (droit X cdtdtfin)"

sort idfhda droit cdtdtfin ddebpjc
*br  idfhda droit cdtdtfin ddebpjc dfinpjc typ ddebU dfinU
collapse (firstnm) region cdtdtdeb ddebpjc cdouvpjc ///
	allocation filiere ddebUB mtjalloc mtjnet mtsjrpla oddsbnp ///
	dur_lastjob odddmax oddtpar ///
	oddddpra pafuaffi pafdaffi ///
	odddtdpr odddtfpr ///
	oddmtdif oddmticp oddmtisl dalnbjdi ///
	sanction ///
	(max) dfinUB ///
	(sum) dur_pjc UBpayment, by(idfhda droit cdtdtfin)
* by collapsing at the droit X cdtdtfin level, we generate as many claims as readmissions
* the PBD rules are unclear for these readmissions
	
label var idfhda        "Individual identifier"
label var region        "REGION"
label var droit         "DROIT CONSOMME"
label var allocation    "CODE ALLOCATION"
label var filiere       "FILIERE D INDEMNISATION"
label var mtjalloc      "MONTANT JOURNALIER ALLOCATION"
label var mtjnet        "MONTANT JOURNALIER NET"
label var odddmax       "DUREE MAXIMALE D INDEMNISATION"
label var oddtpar       "COEFFICIENT REDUCTEUR"
label var mtsjrpla      "MONTANT SJR PLAFONNE"
label var pafdaffi      "CODE UNITES AFFILIATION RETENU"
label var cdtdtdeb      "DATE DEBUT CONTRAT DE TRAVAIL"
label var odddtdpr      "DATE DEBUT PERIODE DE REFERENCE"
label var oddddpra      "DATE DE DEBUT DE LA PRA"
label var cdtdtfin      "DATE DE FIN CONTRAT DE TRAVAIL"
label var odddtfpr      "DATE FIN PERIODE DE REFERENCE"
label var pafuaffi      "NOMBRES D'UNITES D'AFFILIATION"
label var dalnbjdi      "NOMBRE DE JOURS DE DIFFERE"
label var oddsbnp       "SALAIRE BRUT NON PLAFONNE SUR LA PRC"
label var oddmtdif      "MONTANT INDEMNITES ICCP ISLR"
label var oddmticp      "MONTANT INDEMNITES ICCP"
label var oddmtisl      "MONTANT INDEMNITES ISLR"	

label var ddebpjc       "First day of the claim (droit X separation)"
label var ddebUB        "First day of UB payment within the claim (droit X separation)"
label var dfinUB 		"Last date of UB payment within the claim (droit X cdtdtfin)"
label var dur_lastjob	"Duration of last job before unemployment (FH)"

label var dur_pjc 		"Duration of claim with payment (droit X separation)"
label var UBpayment 	"Sum of UB payments on claim (droit X separation)"
label var sanction 		"Sanction"

	
foreach var in oddmtdif oddmticp oddmtisl dalnbjdi {
replace `var'=0 if `var'==.
}

* we drop the observations without UB payments
*codebook mtjalloc mtjnet mtsjrpla
drop if missing(mtjalloc)

save pjc`geo'_, replace
use pjc`geo'_, clear

sort idfhda droit cdtdtfin 
* restrict to standard UI benefits (excluding temp help workers)
merge m:1 idfhda droit using di_regpart
keep if _merge==3
drop _merge
*tab regpart
keep if regpart=="00"
drop regpart

save inflow_`geo', replace
}



use inflow_1, clear
append using inflow_2
append using inflow_3
append using inflow_4
append using inflow_5
append using inflow_7
append using inflow_8
append using inflow_9
compress
*save inflow, replace
*use inflow, clear
sort idfhda droit cdtdtfin
duplicates report idfhda droit cdtdtfin
* very few  
duplicates drop idfhda droit cdtdtfin, force

sort idfhda cdtdtfin droit
duplicates report idfhda cdtdtfin droit  
duplicates report idfhda cdtdtfin  
* very few 
duplicates drop idfhda cdtdtfin, force

keep if cdouv=="01"|cdouv=="02"

sort idfhda cdtdtfin droit
save inflow_claimants, replace



	
*******************************************************************************
* B. match with the corresponding registered U spell (from DE)
*******************************************************************************

use inflow_claimants, clear

joinby idfhda using de 
rename depcom2 depcom

*drop if region=="952"|region=="953"|region=="954"|region=="955"
drop if substr(depcom,1,2)=="97"  |substr(depcom,1,2)=="98"
drop if substr(depcom,1,3)=="000" 

drop if missing(depcom)

* 5 communes pϲimϥs (insee.fr)
replace depcom="10019" if depcom=="10244" 
replace depcom="14697" if depcom=="14624"
replace depcom="57306" if depcom=="57450"
replace depcom="60537" if depcom=="60202"
replace depcom="68297" if depcom=="68047"


* Quelques codes de Corse
replace depcom="2A004" if depcom=="20004"
replace depcom="2B033" if depcom=="20033"
replace depcom="2B134" if depcom=="20134"
replace depcom="2A271" if depcom=="20271"
replace depcom="2B328" if depcom=="20328"
replace depcom="2B352" if depcom=="20352"

sort depcom
gen INSEE_COM=depcom
*merge m:1 depcom using ${SOURCES}centroids_depcom
merge m:1 INSEE_COM using ${SOURCES}GEOFLA_COMMUNE, ///
	keepusing(X_CENTROID Y_CENTROID)

drop if _m==2
drop _m
drop INSEE_COM
rename X_CENTROID xd
rename Y_CENTROID yd
label var xd "X-geographical coordinate of residence (centroid of municipality)"
label var yd "Y-geographical coordinate of residence (centroid of municipality)"

*sort idfhda cdtdtfin ddebpjc datins datann
*br idfhda  cdtdtdeb ddebpjc datins datann
sort idfhda cdtdtfin droit ddebUB datins datann
*br idfhda  cdtdtfin droit ddebUB datins datann

replace datann=mdy(1,1,2013) if missing(datann)

cap drop tag
*gen tag=inrange(ddebpjc,datins,datann-1)
gen tag=inrange(ddebUB,datins,datann-1)
label var tag "First day of UB payments within U spell"
*br idfhda cdtdtdeb ddebpjc datins datann tag

cap drop tot
by idfhda cdtdtfin droit: egen tot=total(tag) 
label var tot "Total number of U spells"
cap drop rk
by idfhda cdtdtfin droit: gen rk=_n
label var rk  "Rank of U spell"


keep if tag==1
drop tag
drop rk 
drop tot
count
* 758,213
compress 
save inflow_claimants, replace

use inflow_claimants, clear

* replicate the selection of JPUBE
tab motins
keep if  motins=="11"|motins=="12"|motins=="14"|motins=="19"|motins=="32" |motins=="99" 
keep if year(datins)>=2006

* select non-missing reservation wage
keep if salmt_mis==0

count
save inflow_claimants, replace








*******************************************************************************
* C. Match with dads data
*******************************************************************************

* we need to help stata to do the joinby
* because these are very large datasets

* we create the list of individuals appearing as new claimants at least once
use inflow_claimants, clear
keep idfhda
duplicates drop 
sort idfhda 
save inflow_claimants_idfhda, replace

* we select in the DADS the Emp spells corresponding to this list of new claimants
use inflow_claimants_idfhda, clear
* we first check whether they appear at least once in the DADS
merge 1:1 idfhda using dads_2004_2012_idfhda

keep if _m==3
drop _m
merge 1:m idfhda using dads_2004_2012_red
keep if _m==3
drop _m
save 2c_prejoinby, replace


* we match the list of all U variables from new claimants 
* with the already selected sample of DADS info
use inflow_claimants, clear
joinby idfhda using 2c_prejoinby
sort idfhda datins ddebE dfinE
duplicates report idfhda datins sir ddebE dfinE
compress
save inflow_claimants_dads, replace


use inflow_claimants_dads, clear



* we exclude all annexe jobs
keep if filtre=="1"
drop filtre

* we exclude jobs with missing var. (very very few)
drop if missing(sb)
drop if missing(dp)
drop if missing(nbheur)
count if nbheur==0
drop if nbheur==0
sum nbheur, d

* we used to exclude jobs still ongoing when people register as unemployed
* drop if inrange(datins,ddebE,dfinE)

* we try to tag the DADS job used to open the claim
* br idfhda droit cdtdtfin datins ddebU ddebE dfinE
sort idfhda droit cdtdtfin ddebE
cap drop tag
gen tag=inrange(dfinE,cdtdtfin-1,cdtdtfin)
label var tag "DADS job is separation job generating the claim"
* as dfinE is truncated at the 30th day for every month, we allow some fuzzy matching 

cap drop tot
by idfhda droit cdtdtfin : egen tot=total(tag) 
label var tot "Total number of DADS E spells"
cap drop rk
by idfhda droit cdtdtfin: gen rk=_n
label var rk "Rank of DADS E spell"


* claims with one DADS job that ends exactly around the date of the FH separation date

* we tag the DADS job whose end date is closest to the FH separation date 
gen lapse=dfinE-cdtdtfin
label var lapse "Difference btw end of DADS spell and FH separation date"
gen lapse_abs=abs(lapse)
label var lapse_abs "Absolute difference btw end of DADS spell and FH separation date"
by idfhda droit cdtdtfin: egen lapse_min=min(lapse_abs)
label var lapse_min "Min (across DADS spells) of absolute difference btw end of DADS spell and FH separation date"
gen tag_=lapse_abs==lapse_min
label var tag_ "E spell with end date closest to FH separation"

replace tag=1 if tag==0 & tag_==1 & inrange(lapse,-90,30)

cap drop tot
by idfhda droit cdtdtfin : egen tot=total(tag) 
label var tot "Is there a DADS job corresponding to the FH separation job? "

* let's exclude all the non-matched claims
keep if tot==1

gen dsep_=dfinE if tag==1
by idfhda droit cdtdtfin : egen dsep=mean(dsep_)
format dsep %td 
label var dsep "Separation date generating the claim (DADS)"
drop dsep_

gen before_sep=dfinE<=dsep
label var before_sep "Employment spell finishing before separation date"
gen after_sep=dsep<ddebE
label var after_sep "Employment spell starting after separation date"
tab before_sep after_sep, m
* this excludes ongoing jobs at the separation date
drop if before_sep==after_sep

sort idfhda droit cdtdtfin sir ddebE dfinE

cap drop continuous
gen continuous=inrange(ddebE,dfinE[_n-1]-31,dfinE[_n-1]+31)&idfhda==idfhda[_n-1]&datins==datins[_n-1]&sir==sir[_n-1]
label var continuous "In continuity with previous spell" 
cap drop spell
bys idfhda droit cdtdtfin sir: gen spell=_n
replace spell=spell[_n-1] if continuous==1 
label var spell "Identifier of continuous (within sir) E spell"

********************
* we exclude workers whose DADS jobs generating the claim is followed 
* by a continuous spell within the same firm
by idfhda droit cdtdtfin: gen f_continuous=continuous[_n+1] 
label var f_continuous "the DADS spell is directly followed by another DADS spell within same sir"  
gen excl=f_cont if tag==1
tab excl
cap drop tot
by idfhda droit cdtdtfin : egen tot=total(excl) 
label var tot "Is the DADS job corresponding to the FH separation job actually continuous?"
tab tot if rk==1, m

drop if tot==1
drop tot
drop excl

sort idfhda droit cdtdtfin after_sep sir spell ddebE dfinE
by idfhda droit cdtdtfin after_sep sir spell: egen debut=min(ddebE)
by idfhda droit cdtdtfin after_sep sir spell: egen fin=max(dfinE)
by idfhda droit cdtdtfin after_sep sir spell: egen dptot=sum(dp)
by idfhda droit cdtdtfin after_sep sir spell: egen nbheurtot=sum(nbheur)
by idfhda droit cdtdtfin after_sep sir spell: egen sbtot=sum(sb)
format debut %td	
format fin %td
label var debut "Start date of E spell within firm (over years since UB separation date)"
label var fin   "End date of E spell within firm (over years since UB separation date)"
label var dptot "Total E duration within firm (over years since UB separation date)"
label var nbheurtot "Total # hours worked within firm (over years since UB separation date)"
label var sbtot "Total wages within firm (over years since UB separation date)"


****************************
* we exclude partial UI jobs, ie. job starting during the claim  
cap drop partial_UI
gen partial_UI=inrange(ddebE, ddebU, dfinU-61)
* job ending during the claim  
replace partial_UI=inrange(dfinE, ddebU, dfinU-61) if partial_UI==0
* job including the claim
replace partial_UI=inrange(ddebU,ddebE,dfinE)&inrange(dfinU,ddebE,dfinE) if partial_UI==0
label var partial_UI "DADS job is under partial UI"
cap drop partial_UI_
by idfhda droit cdtdtfin : egen partial_UI_=total(partial_UI) 
label var partial_UI_ "Number of partial UI jobs within claim"
tab partial_UI_ if rk==1, m

drop if partial_UI==1

***************
* need to update selection on tags (as we may have suppressed some tagged jobs just above)
cap drop tot
by idfhda droit cdtdtfin : egen tot=total(tag) 
label var tot "Is there a DADS job corresponding to the FH separation job? "
keep if tot==1
drop tot

* we rank E spells before and after separation
sort idfhda droit cdtdtfin after_sep ddebE dfinE
cap drop rk
by idfhda droit cdtdtfin after_sep: gen rk=_n
cap drop tot 
by idfhda droit cdtdtfin after_sep: gen tot=_N
* br idfhda datins before_ins after_ins ddebE dfinE rk tot
replace rk=rk-tot if after_sep==0
label var rk "Rank of the Emp spell (reference is separation job)"
label var tot "Total number of DADS E spell before or after separation"
label var ce "Full time v. Part time (DADS)"

keep if rk==0|rk==1

gen pastW=wage if rk==0
gen postW=wage if rk==1
gen pastW_hourly=wage_hourly if rk==0
gen postW_hourly=wage_hourly if rk==1
drop wage
drop continuous spell debut fin


* create inetrmediate variable to reshape the data while doing the collapse
forvalues rk=0(1)1 {
gen ddebE`rk'=ddebE if rk==`rk'
gen dfinE`rk'=dfinE if rk==`rk'
gen sbE`rk'=sb if rk==`rk'
gen contratE`rk'=contrat_travail if rk==`rk'
gen dpE`rk'=dp if rk==`rk'
gen nbheurE`rk'=nbheur if rk==`rk'
gen dptotE`rk'=dptot if rk==`rk'
gen nbheurtotE`rk'=nbheurtot if rk==`rk'
gen sbtotE`rk'=sbtot if rk==`rk'
gen ceE`rk'=ce if rk==`rk'
gen a38E`rk'=a38 if rk==`rk'
gen pcsE`rk'=pcs4 if rk==`rk'
gen comE`rk'=comt if rk==`rk'
gen depE`rk'=dept if rk==`rk'
gen taille_E`rk'=nbsa_ent if rk==`rk'
gen firm_wage_fteE`rk'=mean_wage_fte if rk==`rk'
gen firm_wage_hourlyE`rk'=mean_wage_hourly if rk==`rk'
gen pcs_wage_fteE`rk'=pcs_wage_fte if rk==`rk'
gen pcs_wage_hourlyE`rk'=pcs_wage_hourly if rk==`rk'
gen xt_E`rk'=xt if rk==`rk'
gen yt_E`rk'=yt if rk==`rk'
gen xr_E`rk'=xr if rk==`rk'
gen yr_E`rk'=yr if rk==`rk'
gen depr_E`rk'=depr if rk==`rk'
gen comr_E`rk'=comr if rk==`rk'
gen sir_E`rk'=sir if rk==`rk'
}
format ddebE0 %td	
format ddebE1 %td	
format dfinE0 %td	
format dfinE1 %td	

collapse (firstnm) pastW* postW* sbE0 sbE1 ///
	ddebE0 ddebE1 dfinE0 dfinE1 ceE0 ceE1 ///
	contratE0 contratE1 dpE0 dpE1 nbheurE0 nbheurE1 ///
	dptotE0 dptotE1 nbheurtotE0 nbheurtotE1 sbtotE0 sbtotE1 ///
	depE0 depE1 comE0 comE1 depr_E0 depr_E1 comr_E0 comr_E1 taille_E0 taille_E1 ///
	a38E0 a38E1 pcsE0 pcsE1 firm_wage_fteE0 firm_wage_fteE1 ///
	firm_wage_hourlyE0 firm_wage_hourlyE1 yt* xt* yr* xr* pcs_wage* sir_E* ///
	partial_UI_ , by(idfhda droit cdtdtfin)

label var pastW "FTE gross monthly wage (DADS) of last job before U registration"
label var postW "FTE gross monthly wage (DADS) of first job after U registration"
label var pastW_hourly "Average gross hourly wage (DADS) of last job before U registration"
label var postW_hourly "Average gross hourly wage (DADS) of first job after U registration"
label var sbE0 "Gross annual wage (DADS) of last job before U registration"
label var sbE1 "Gross annual wage (DADS) of first job after U registration"

label var ddebE0 "Starting date (within calendar year) of last job before U registration"
label var ddebE1 "Starting date (within calendar year) of first job after U registration"
label var dfinE0 "Ending date (within calendar year) of last job before U registration"
label var dfinE1 "Ending date (within calendar year) of first job after U registration"

label var ceE0 "Full time v. Part time Last job before U registration (DADS)"
label var ceE1 "Full time v. Part time First job after U registration (DADS)"

label var contratE0 "Contract type of last job before U registration (DADS)"
label var contratE1 "Contract type of first job after U registration (DADS)"

label var dpE0 "# paid days (within calendar year) of last job before U registration (DADS)"
label var dpE1 "# paid days (within calendar year) of first job after U registration (DADS)"

label var nbheurE0 "# work hours (within calendar year) of last job before U registration (DADS)"
label var nbheurE1 "# work hours (within calendar year) of first job after U registration (DADS)"

label var dptotE0 "# paid days (over years) of last job before U registration (DADS)"
label var dptotE1 "# paid days (over years) of first job after U registration (DADS)"
label var nbheurtotE0 "# work hours (over years) of last job before U registration (DADS)"
label var nbheurtotE1 "# work hours (over years) of first job after U registration (DADS)"
label var sbtotE0 "Gross wage (over years) of last job before U registration (DADS)"
label var sbtotE1 "Gross wage (over years) of first job after U registration (DADS)"

label var depE0 "Department of separation job (DADS)"
label var depE1 "Department of first job after separation (DADS)"
label var comE0 "Municipality of separation job (DADS)"
label var comE1 "Municipality of first job after separation (DADS)"
label var taille_E0 "Firm size of separation job (DADS)"
label var taille_E1 "Firm size of first job after separation (DADS)"
label var a38E0 "Firm industry of separation job (DADS)"
label var a38E1 "Firm industry of first job after separation (DADS)"
label var pcsE0 "Occupation of separation job (DADS)"
label var pcsE1 "Occupation of first job after separation (DADS)"
label var firm_wage_fteE0 "Firm average FTE monthly wage of separation job (DADS)"
label var firm_wage_fteE1 "Firm average FTE monthly wage of first job after separation (DADS)"
label var firm_wage_hourlyE0 "Firm average hourly wage of separation job (DADS)"
label var firm_wage_hourlyE1 "Firm average hourly wage of first job after separation (DADS)"
label var yt_E0 "Y-coordinate of workplace of separation job (DADS)"
label var yt_E1 "Y-coordinate of workplace of first job after separation (DADS)"
label var xt_E0 "X-coordinate of workplace of separation job (DADS)"
label var xt_E1 "X-coordinate of workplace of first job after separation (DADS)"
label var yt_E0 "Y-coordinate of residence at the time of E0 job"
label var yt_E1 "Y-coordinate of residence at the time of E1 job"
label var xt_E0 "X-coordinate of residence at the time of E0 job "
label var xt_E1 "X-coordinate of residence at the time of E1 job"
label var pcs_wage_fteE0 "Occupation average FTE monthly wage of separation job (DADS)"
label var pcs_wage_fteE1 "Occupation average FTE monthly wage of first job after separation (DADS)"
label var pcs_wage_hourlyE0 "Occupation average hourly wage of separation job (DADS)"
label var pcs_wage_hourlyE1 "Occupation average hourly wage of first job after separation (DADS)"
label var sir_E0 "Firm identifier of separation job (DADS)"
label var sir_E1 "Firm identifier of first job after separation (DADS)"

label var partial_UI_ "Number of partial UI jobs within claim"

merge 1:m idfhda droit cdtdtfin using inflow_claimants	

keep if _m==3
drop _m
	
capture drop sjr 	
gen sjr=mtsjr*30.5
label var sjr "Monthly reference wage (FH)"
count if missing(sjr)
capture drop sjr_hourly
gen sjr_hourly=mtsjr/5	
label var sjr_hourly "Hourly reference wage (FH)"
	
compress	
save basedetravail_claimants, replace


*********
* Adding info on local labor market conditions

use basedetravail_claimants, clear

rename ZE2010 ze

capture drop stock_ze vac_ze_quarter
*merge m:1 ze period_quarter using V_quarter_ze_stata13
merge m:1 ze period_quarter using ${SOURCES}V_quarter_ze
keep if _merge==3
drop _merge
*merge m:1 ze period_quarter using U_quarter_ze_stata13
merge m:1 ze period_quarter using ${SOURCES}U_quarter_ze
keep if _merge==3
drop _merge

gen log_V=log(vac_ze)
gen log_Ustock=log(stock_ze)
gen log_U=log(flow_ze)
gen log_Vnat = log(vac)
gen log_Unat = log(flow)
gen log_theta=log(vac_ze/stock_ze)
label var log_V "Number of new vacancies this quarter in the CZ (log)"
label var log_U "Number of new job seekers this quarter in the CZ (log)"
label var log_Ustock "Stock of job seekers this quarter in the CZ (log)"
label var log_theta "Labor market tightness in the CZ (log)"

order idfhda cdtdtfin droit allocation cdtdtdeb ddebUB ///
	allocation filiere ddebUB mtjalloc mtjnet mtsjrpla oddsbnp mtsjr ///
	dur_lastjob odddmax oddtpar ///
	oddddpra pafuaffi pafdaffi ///
	odddtdpr odddtfpr ///
	oddmtdif oddmticp oddmtisl dalnbjdi ///
	ddebE0 dfinE0 datins datann dur_indemnisee dur_btw ddebE1 dfinE1  ///
	pastW pastW_hourly sjr sjr_hourly postW postW_hourly ///
	ceE0 ceE1 contratE0 contratE1 dpE0 dpE1 nbheurE0 nbheurE1 sbE0 sbE1

save basedetravail_claimants, replace







*******************************************************************************
* D. Normalizing some wage variables relative to minimum wage
*******************************************************************************

use basedetravail_claimants, clear

xtset idfhda_ 

count

gen resW_pastW=resW/pastW
label var resW_pastW "Ratio of reservation wage to pastW"
sum resW_pastW, d

global TRIM="inrange(resW_pastW,0.4,3) & pastW!=. & sjr!=. "


gen resW_hourly=salmt if salunit=="H"
label var resW_hourly "Hourly gross reservation wage"
gen resW_pastW_hourly=resW_hourly/pastW_hourly
label var resW_pastW_hourly "Ratio of reservation wage to pastW, hourly"
sum resW_pastW_hourly, d
gen resW_sjr_hourly=resW_hourly/sjr_hourly
label var resW_sjr_hourly "Ratio of reservation wage to SJR, hourly"

sum pastW if inrange(resW_pastW,0.4,3), d

forvalues year=2006(1)2012 { 
foreach var in resW resW_hourly pastW pastW_hourly postW postW_hourly sjr sjr_hourly { 
centile `var' if year==`year', c(2 98)
replace `var'=r(c_1) if year==`year' & missing(`var')==0 & `var'<r(c_1)
replace `var'=r(c_2) if year==`year' & missing(`var')==0 & `var'>r(c_2)
}
}


capture drop pastW_minW
gen 	pastW_minW=.
replace pastW_minW=pastW/1154 if dfinE0<(mdy( 6,30,2005))
replace pastW_minW=pastW/1217 if inrange(dfinE0,mdy( 6,30,2005),mdy( 6,30,2006))	
replace pastW_minW=pastW/1254 if inrange(dfinE0,mdy( 6,30,2006),mdy( 6,29,2007))	
replace pastW_minW=pastW/1280 if inrange(dfinE0,mdy( 6,29,2007),mdy( 4,29,2008))	
replace pastW_minW=pastW/1308 if inrange(dfinE0,mdy( 4,29,2008),mdy( 6,28,2008))	
replace pastW_minW=pastW/1321 if inrange(dfinE0,mdy( 6,28,2008),mdy( 6,26,2009))	
replace pastW_minW=pastW/1337 if inrange(dfinE0,mdy( 6,26,2009),mdy(12,17,2009))	
replace pastW_minW=pastW/1343 if inrange(dfinE0,mdy(12,17,2009),mdy(12,17,2010))	
replace pastW_minW=pastW/1365 if inrange(dfinE0,mdy(12,17,2010),mdy(11,30,2011))	
replace pastW_minW=pastW/1393 if inrange(dfinE0,mdy(11,30,2011),mdy(12,23,2011))	
replace pastW_minW=pastW/1398 if inrange(dfinE0,mdy(12,23,2011),mdy( 6,29,2012))	
replace pastW_minW=pastW/1425 if inrange(dfinE0,mdy( 6,29,2012),mdy(12,21,2012))	
replace pastW_minW=pastW/1430 if inrange(dfinE0,mdy(12,21,2012),mdy(12,19,2013))	
replace pastW_minW=pastW/1445 if inrange(dfinE0,mdy(12,19,2013),mdy(12,22,2014))	
replace pastW_minW=pastW/1457 if dfinE0>mdy(12,22,2014)
label var pastW_minW "Past wage rate over the minW prevailing the year of end of contract" 


capture drop postW_minW
gen 	postW_minW=.
replace postW_minW=postW/1154 if ddebE1<(mdy( 6,30,2005))
replace postW_minW=postW/1217 if inrange(ddebE1,mdy( 6,30,2005),mdy( 6,30,2006))	
replace postW_minW=postW/1254 if inrange(ddebE1,mdy( 6,30,2006),mdy( 6,29,2007))	
replace postW_minW=postW/1280 if inrange(ddebE1,mdy( 6,29,2007),mdy( 4,29,2008))	
replace postW_minW=postW/1308 if inrange(ddebE1,mdy( 4,29,2008),mdy( 6,28,2008))	
replace postW_minW=postW/1321 if inrange(ddebE1,mdy( 6,28,2008),mdy( 6,26,2009))	
replace postW_minW=postW/1337 if inrange(ddebE1,mdy( 6,26,2009),mdy(12,17,2009))	
replace postW_minW=postW/1343 if inrange(ddebE1,mdy(12,17,2009),mdy(12,17,2010))	
replace postW_minW=postW/1365 if inrange(ddebE1,mdy(12,17,2010),mdy(11,30,2011))	
replace postW_minW=postW/1393 if inrange(ddebE1,mdy(11,30,2011),mdy(12,23,2011))	
replace postW_minW=postW/1398 if inrange(ddebE1,mdy(12,23,2011),mdy( 6,29,2012))	
replace postW_minW=postW/1425 if inrange(ddebE1,mdy( 6,29,2012),mdy(12,21,2012))	
replace postW_minW=postW/1430 if inrange(ddebE1,mdy(12,21,2012),mdy(12,19,2013))	
replace postW_minW=postW/1445 if inrange(ddebE1,mdy(12,19,2013),mdy(12,22,2014))	
replace postW_minW=postW/1457 if ddebE1>mdy(12,22,2014)
label var postW_minW "Post wage rate over the minW prevailing the year of start of contract" 


capture drop pastW_lt_minW
gen 	pastW_lt_minW=.
replace pastW_lt_minW=pastW_minW<1 if missing(pastW_minW)==0
label var pastW_lt_minW "Past wage below the minW prevailing one year before the registration date" 
count if missing(pastW_lt_minW)


capture drop resW_minW
gen 	resW_minW=.
replace resW_minW=resW/1154 if datins<(mdy( 6,30,2005))
replace resW_minW=resW/1217 if inrange(datins,mdy( 6,30,2005),mdy( 6,30,2006))	
replace resW_minW=resW/1254 if inrange(datins,mdy( 6,30,2006),mdy( 6,29,2007))	
replace resW_minW=resW/1280 if inrange(datins,mdy( 6,29,2007),mdy( 4,29,2008))	
replace resW_minW=resW/1308 if inrange(datins,mdy( 4,29,2008),mdy( 6,28,2008))	
replace resW_minW=resW/1321 if inrange(datins,mdy( 6,28,2008),mdy( 6,26,2009))	
replace resW_minW=resW/1337 if inrange(datins,mdy( 6,26,2009),mdy(12,17,2009))	
replace resW_minW=resW/1343 if inrange(datins,mdy(12,17,2009),mdy(12,17,2010))	
replace resW_minW=resW/1365 if inrange(datins,mdy(12,17,2010),mdy(11,30,2011))	
replace resW_minW=resW/1393 if inrange(datins,mdy(11,30,2011),mdy(12,23,2011))	
replace resW_minW=resW/1398 if inrange(datins,mdy(12,23,2011),mdy( 6,29,2012))	
replace resW_minW=resW/1425 if inrange(datins,mdy( 6,29,2012),mdy(12,21,2012))	
replace resW_minW=resW/1430 if inrange(datins,mdy(12,21,2012),mdy(12,19,2013))	
replace resW_minW=resW/1445 if inrange(datins,mdy(12,19,2013),mdy(12,22,2014))	
replace resW_minW=resW/1457 if datins>mdy(12,22,2014)
count if missing(resW_minW)
label var resW_minW "Reservation wage rate over the minW prevailing at U registration" 

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
replace minW=1445 if inrange(datins,mdy(12,19,2013),mdy(12,22,2014))	
replace minW=1457 if datins>mdy(12,22,2014)
count if missing(minW)
tab minW
label var minW "Min wage prevailing at the registration date"

capture drop minW_hourly
gen 	minW_hourly=.
replace minW_hourly=6.83 if datins<(mdy( 6,30,2005))
replace minW_hourly=8.03 if inrange(datins,mdy( 6,30,2005),mdy( 6,30,2006))	
replace minW_hourly=8.27 if inrange(datins,mdy( 6,30,2006),mdy( 6,29,2007))	
replace minW_hourly=8.44 if inrange(datins,mdy( 6,29,2007),mdy( 4,29,2008))	
replace minW_hourly=8.63 if inrange(datins,mdy( 4,29,2008),mdy( 6,28,2008))	
replace minW_hourly=8.71 if inrange(datins,mdy( 6,28,2008),mdy( 6,26,2009))	
replace minW_hourly=8.82 if inrange(datins,mdy( 6,26,2009),mdy(12,17,2009))	
replace minW_hourly=8.86 if inrange(datins,mdy(12,17,2009),mdy(12,17,2010))	
replace minW_hourly=9    if inrange(datins,mdy(12,17,2010),mdy(11,30,2011))	
replace minW_hourly=9.19 if inrange(datins,mdy(11,30,2011),mdy(12,23,2011))	
replace minW_hourly=9.22 if inrange(datins,mdy(12,23,2011),mdy( 6,29,2012))	
replace minW_hourly=9.40 if inrange(datins,mdy( 6,29,2012),mdy(12,21,2012))	
replace minW_hourly=9.43 if inrange(datins,mdy(12,21,2012),mdy(12,19,2013))	
replace minW_hourly=9.53 if inrange(datins,mdy(12,19,2013),mdy(12,22,2014))	
replace minW_hourly=9.61 if datins>mdy(12,22,2014)
count if missing(minW_hourly)
label var minW_hourly "Hourly minimum wage prevailing at the registration date"


capture drop resW_at_minW
gen resW_at_minW=inrange(resW,minW-1,minW+1)
label var resW_at_minW "Reservation wage is at the min wage prevailing at registration"

capture drop resW_lt_minW
gen resW_lt_minW=resW<(minW-1)
label var resW_lt_minW "Reservation wage is less than the min wage prevailing at registration"
capture drop resW_gt_minW
gen resW_gt_minW=resW>(minW+1)
label var resW_gt_minW "Reservation wage is greater than the min wage prevailing at registration"

capture drop resW_at_anyminW
gen resW_at_anyminW=0
foreach minW in 1254 1280 1308 1321 1337 1343 1365 1393 1398 1425 {
replace resW_at_anyminW=resW_at_anyminW+inrange(resW,`minW'-1,`minW'+1)
}
label var resW_at_anyminW "Reservation at any min wage level prevailing from 2006 to 2012"



capture drop resW_at_minW_hourly
gen resW_at_minW_hourly=resW_hourly==minW_hourly
label var resW_at_minW "Reservation wage is at the min wage prevailing at registration"


capture drop resW_at_anyminW_hourly
gen resW_at_anyminW_hourly=0
foreach minW in 6.83 8.03 8.27 8.44 8.63 8.71 8.82 8.86 9 9.19 9.22 9.40 9.43 9.53 9.61 {
replace resW_at_anyminW_hourl=resW_at_anyminW_hourly+inrange(resW_hourly,`minW'-0.01,`minW'+0.01)
}
label var resW_at_anyminW_hourly "Hourly reservation wage at any min wage level prevailing from 2006 to 2012"
tab resW_at_anyminW_hourly if salunit=="H"

capture drop resW_lt_minW_hourly
gen resW_lt_minW_hourly=resW_hourly<(minW_hourly-0.01)
label var resW_lt_minW_hourly "Reservation wage is less than the min wage prevailing at registration"
capture drop resW_gt_minW_hourly
gen resW_gt_minW_hourly=resW_hourly>(minW_hourly+0.01)
label var resW_gt_minW_hourly "Reservation wage is greater than the min wage prevailing at registration"

gen postW_pastW=postW/pastW
label var postW_pastW "Ratio of post-U wage to past wage, monthly"

gen postW_resW=postW/resW
label var postW_resW "Ratio of post-U wage to reservation wage, monthly"
sum postW_resW if salunit=="M", d

gen postW_resW_hourly=postW_hourly/resW_hourly
label var postW_resW_hourly "Ratio of post-U wage to reservation wage, hourly"
sum postW_resW_hourly if salunit=="H", d




capture drop past_minW
gen 	past_minW=.
replace past_minW=1154 if dfinE0<(mdy( 6,30,2005))
replace past_minW=1217 if inrange(dfinE0,mdy( 6,30,2005),mdy( 6,30,2006))	
replace past_minW=1254 if inrange(dfinE0,mdy( 6,30,2006),mdy( 6,29,2007))	
replace past_minW=1280 if inrange(dfinE0,mdy( 6,29,2007),mdy( 4,29,2008))	
replace past_minW=1308 if inrange(dfinE0,mdy( 4,29,2008),mdy( 6,28,2008))	
replace past_minW=1321 if inrange(dfinE0,mdy( 6,28,2008),mdy( 6,26,2009))	
replace past_minW=1337 if inrange(dfinE0,mdy( 6,26,2009),mdy(12,17,2009))	
replace past_minW=1343 if inrange(dfinE0,mdy(12,17,2009),mdy(12,17,2010))	
replace past_minW=1365 if inrange(dfinE0,mdy(12,17,2010),mdy(11,30,2011))	
replace past_minW=1393 if inrange(dfinE0,mdy(11,30,2011),mdy(12,23,2011))	
replace past_minW=1398 if inrange(dfinE0,mdy(12,23,2011),mdy( 6,29,2012))	
replace past_minW=1425 if inrange(dfinE0,mdy( 6,29,2012),mdy(12,21,2012))	
replace past_minW=1430 if inrange(dfinE0,mdy(12,21,2012),mdy(12,19,2013))	
replace past_minW=1445 if inrange(dfinE0,mdy(12,19,2013),mdy(12,22,2014))	
replace past_minW=1457 if dfinE0>mdy(12,22,2014)
label var past_minW "minW prevailing the year of end of contract" 


capture drop post_minW
gen 	post_minW=.
replace post_minW=1154 if ddebE1<(mdy( 6,30,2005))
replace post_minW=1217 if inrange(ddebE1,mdy( 6,30,2005),mdy( 6,30,2006))	
replace post_minW=1254 if inrange(ddebE1,mdy( 6,30,2006),mdy( 6,29,2007))	
replace post_minW=1280 if inrange(ddebE1,mdy( 6,29,2007),mdy( 4,29,2008))	
replace post_minW=1308 if inrange(ddebE1,mdy( 4,29,2008),mdy( 6,28,2008))	
replace post_minW=1321 if inrange(ddebE1,mdy( 6,28,2008),mdy( 6,26,2009))	
replace post_minW=1337 if inrange(ddebE1,mdy( 6,26,2009),mdy(12,17,2009))	
replace post_minW=1343 if inrange(ddebE1,mdy(12,17,2009),mdy(12,17,2010))	
replace post_minW=1365 if inrange(ddebE1,mdy(12,17,2010),mdy(11,30,2011))	
replace post_minW=1393 if inrange(ddebE1,mdy(11,30,2011),mdy(12,23,2011))	
replace post_minW=1398 if inrange(ddebE1,mdy(12,23,2011),mdy( 6,29,2012))	
replace post_minW=1425 if inrange(ddebE1,mdy( 6,29,2012),mdy(12,21,2012))	
replace post_minW=1430 if inrange(ddebE1,mdy(12,21,2012),mdy(12,19,2013))	
replace post_minW=1445 if inrange(ddebE1,mdy(12,19,2013),mdy(12,22,2014))	
replace post_minW=1457 if ddebE1>mdy(12,22,2014)
label var post_minW "minW prevailing the year of start of contract" 


capture drop resWcorr
gen     resWcorr=round(resW)
replace resWcorr=minW if resW_at_anyminW==1
label var resWcorr "Reservation wage (corrected)"

capture drop log_resWcorr
gen log_resWcorr=log(resWcorr)

capture drop resWcorr_minW
gen resWcorr_minW=resWcorr/minW
label var resWcorr_minW "Reservation wage (corrected) divided by min wage"

capture drop log_resWcorr_minW
gen log_resWcorr_minW=log(resWcorr_minW)

cap drop pastWcorr
gen pastWcorr=pastW
replace pastWcorr=past_minW if pastWcorr<past_minW
label var pastWcorr "FTE gross monthly wage (DADS) of last job before U registration"

cap drop postWcorr
gen postWcorr=postW
replace postWcorr=post_minW if postWcorr<post_minW
label var postWcorr "FTE gross monthly wage (DADS) of first job after U registration"

cap drop resWcorr_pastWcorr
gen resWcorr_pastWcorr=resWcorr/pastWcorr
label var resWcorr_pastWcorr "Reservation wage / Previous wage"

cap drop postWcorr_resWcorr
gen postWcorr_resWcorr=postWcorr/resWcorr
label var postWcorr_resWcorr "Reemployment wage / Reservation wage"

capture drop log_resWcorr_pastW
gen log_resWcorr_pastW=log(resWcorr_pastW)

save basedetravail_claimants, replace









*******************************************************************************
* E. extra transformation of variables
*******************************************************************************

use basedetravail_claimants, clear
global TRIM="inrange(resW_pastW,0.4,3) & pastW!=. & sjr!=. "

* creating tenure variables
tab pafdaffi, m
replace pafdaffi="" if pafdaffi=="E" |pafdaffi=="8"

desc pafuaffi
gen tenure=pafuaffi
replace tenure=round(pafuaffi/5) if pafdaffi=="H"
replace tenure=round(pafuaffi*30.5) if pafdaffi=="M"
replace tenure=. if pafdaffi==""
lab var tenure "# days with contributions (FH)"


gen log_resW=log(resW)
gen log_pastW=log(pastW)
gen log_sjr=log(sjr)
gen log_postW=log(postW)


capture drop pastW_bins
egen pastW_bins=cut(pastW), group(20)
*bys pastW_bins: sum pastW, d
*binscatter resW pastW if ${SAMP} & ${TRIM}, nquantiles(20) gen(pastW_bins)
capture drop sjr_bins
egen sjr_bins=cut(sjr), group(20)

gen log_tenure=log(tenure)
gen log_PBD=log(odddmax)

gen dur_NE=ddebE1-dfinE0	
label var dur_NE "Non-employment duration (DADS)"	

gen dur_NE_=ddebE1-cdtdtfin	
label var dur_NE_ "Non-employment duration (DADS-FH)"

gen dur_U=datann-datins	
label var dur_U "Unemployment duration (FH register)"

sum dur_NE, d 
*hist dur_NE, width(7)
count if missing(dur_NE)
 
forvalues year=2006(1)2012 { 
foreach var in dur_NE dur_U dur_indemnisee { 
centile `var' if year==`year', c(2 98)
replace `var'=r(c_1) if year==`year' & missing(`var')==0 & `var'<r(c_1)
replace `var'=r(c_2) if year==`year' & missing(`var')==0 & `var'>r(c_2)
}
}
	

gen log_dur_NE=log(dur_NE)
gen log_dur_NE_=log(dur_NE_)
gen log_dur_U=log(dur_U)
gen log_dur_UI=log(dur_indemnis)
gen log_dur_pjc=log(dur_pjc)

sort idfhda datins ddebUB
duplicates drop idfhda datins, force 


gen age2=age*age
gen exper2=exper*exper


gen jobfinding=missing(dur_NE)==0
gen jobfinding_2years=inrange(dur_NE,0,730)

* relate occupation PCS from DADS to FAP
replace pcsE0=strlower(pcsE0)
replace pcsE1=strlower(pcsE1)

gen PCS=pcsE0
merge m:1 PCS using ${SOURCES}passage_pcs_fap2009
tab PCS if _m==1, m
drop if _m==2
drop _m
cap drop PCS
rename FAP fapE0
label var fapE0 "Occupation of separation job FAP (DADS)"
replace pcsE0="" if missing(fapE0)==1
encode fapE0,gen(fapE0_)
replace fapE0_=0 if missing(fapE0_) 

gen PCS=pcsE1
merge m:1 PCS using ${SOURCES}passage_pcs_fap2009
tab PCS if _m==1, m
drop if _m==2
drop _m
cap drop PCS 
rename FAP fapE1
label var fapE1 "Occupation of new job FAP (DADS)"
replace pcsE1="" if missing(fapE1)==1
encode fapE1,gen(fapE1_)
replace fapE1_=0 if missing(fapE1_) & jobfinding_2years==1

* relate occupation ROME from FH to FAP
gen ROME=rome
gen QUALIF=qualif
merge m:1 ROME QUALIF using ${SOURCES}passage_romev3_fap2009
tab ROME if _m==1, m
tab ROME QUALIF if _m==2 
drop if _m==2
drop _m
cap drop ROME QUALIF
rename FAP fapU
label var fapU "Occupation of job sought (FH)"
encode fapU, gen(fapU_)
*tab fapU_,nolabel  m
replace fapU_=0 if missing(fapU_)

* compute change in occupations
cap drop fap_same_U_E0
*gen fap_same_U_E0=fapU==fapE0 if missing(fapU)==0 & missing(fapE0)==0
gen fap_same_U_E0=fapU_==fapE0_ if missing(fapU_)==0 & missing(fapE0_)==0
label var fap_same_U_E0 "Search in the same 4-digit occupation as past job" 
tab fap_same_U_E0 

cap drop fap_same_E1_E0
*gen fap_same_E1_E0=fapE1==fapE0 if missing(fapE1)==0 & missing(fapE0)==0
gen fap_same_E1_E0=fapE1_==fapE0_ if missing(fapE1_)==0 & missing(fapE0_)==0
label var fap_same_E1_E0 "Found job in the same 4-digit occupation as past job" 
tab fap_same_E1_E0

cap drop fap_same_E1_U
*gen fap_same_E1_U=fapE1==fapU if missing(fapE1)==0 & missing(fapU)==0
gen fap_same_E1_U=fapE1_==fapU_ if missing(fapE1_)==0 & missing(fapU_)==0
label var fap_same_E1_U "Found job in the same 4-digit occupation as searched occupation"
tab fap_same_E1_U

* aggregate FAP from 4-digit to 3- and 1-digit 
foreach var in E0 U E1 {
cap drop fap3`var'
gen fap3`var'=substr(fap`var',1,3)
cap drop fap1`var'
gen fap1`var'=substr(fap`var',1,1)
}
* compute change in occupations at aggregate level
foreach level in 1 3 {
cap drop fap`level'_same_U_E0
gen fap`level'_same_U_E0=fap`level'U==fap`level'E0 if missing(fap`level'U)==0 
* & missing(fap`level'E0)==0
label var fap`level'_same_U_E0 "Search in the same `level'-digit occupation as past job" 
tab fap`level'_same_U_E0 

cap drop fap`level'_same_E1_E0
gen fap`level'_same_E1_E0=fap`level'E1==fap`level'E0 if missing(fap`level'E1)==0 
* & missing(fap`level'E0)==0
label var fap`level'_same_E1_E0 "Found job in the same `level'-digit occupation as past job" 
tab fap`level'_same_E1_E0

cap drop fap`level'_same_E1_U
gen fap`level'_same_E1_U=fap`level'E1==fap`level'U if missing(fap`level'E1)==0 & missing(fap`level'U)==0
label var fap`level'_same_E1_U "Found job in the same `level'-digit occupation as searched occupation"
tab fap`level'_same_E1_U
}

* add labels on the 1-digit level variables
foreach var in E0 U E1 {
replace fap1`var'="A : Agriculture, marine, pêche" if fap1`var'=="A"
replace fap1`var'="B : Bâtiment, travaux publics" if fap1`var'=="B"
replace fap1`var'="C : Électricité, électronique" if fap1`var'=="C"
replace fap1`var'="D : Mécanique, travail des métaux" if fap1`var'=="D"
replace fap1`var'="E : Industries de process" if fap1`var'=="E"
replace fap1`var'="F : Matériaux souples, bois, industries graphiques" if fap1`var'=="F"
replace fap1`var'="G : Maintenance" if fap1`var'=="G"
replace fap1`var'="H : Ingénieurs et cadres de l'industrie" if fap1`var'=="H"
replace fap1`var'="J : Transports, logistique et tourisme" if fap1`var'=="J"
replace fap1`var'="K : Artisanat" if fap1`var'=="K"
replace fap1`var'="L : Gestion, administration des entreprises" if fap1`var'=="L"
replace fap1`var'="M : Informatique et télécommunications" if fap1`var'=="M"
replace fap1`var'="N : Études et recherche" if fap1`var'=="N"
replace fap1`var'="P : Administration publique, professions juridiques, armée et police" if fap1`var'=="P"
replace fap1`var'="Q : Banque et assurances" if fap1`var'=="Q"
replace fap1`var'="R : Commerce" if fap1`var'=="R"
replace fap1`var'="S : Hôtellerie, restauration, alimentation" if fap1`var'=="S"
replace fap1`var'="T : Services aux particuliers et aux collectivités" if fap1`var'=="T"
replace fap1`var'="U : Communication, information, art et spectacle" if fap1`var'=="U"
replace fap1`var'="V : Santé, action sociale, culturelle et sportive" if fap1`var'=="V"
replace fap1`var'="W : Enseignement, formation" if fap1`var'=="W"
replace fap1`var'="X : Politique, religion" if fap1`var'=="X"
replace fap1`var'="Z : Non renseigné ou autre"  if fap1`var'=="Z" 
}
foreach var in E0 U E1 {
rename fap1`var' fap1`var'_
encode fap1`var'_,g(fap1`var')
cap drop fap1`var'_
}
label var fap1U  "Occupation of job sought - 1digit (FH)"
label var fap1E0 "Occupation of previous job - 1digit (DADS)"
label var fap1E1 "Occupation of next job - 1digit (DADS)"
label var fap3U  "Occupation of job sought - 3digit (FH)"
label var fap3E0 "Occupation of previous job - 3digit (DADS)"
label var fap3E1 "Occupation of next job - 3digit (DADS)"


gen married_female=married*female
gen married_male=married*male
gen child_female=child*female
gen child_male=child*male
gen kids2=nchild>=2
gen kids2_female=kids2*female
gen kids2_male=kids2*male

egen occupation=group(pcsE0)
egen cz=group(ze)

gen distanceE0=sqrt((yt_E0-yr_E0)*(yt_E0-yr_E0)+(xt_E0-xr_E0)*(xt_E0-xr_E0))
replace distanceE0=distanceE0/1000
gen prev_fulltime=ceE0=="C"
gen prev_cdi=contratE0=="01"

gen log_mobdist=log(mobdist)
gen mobunit_tps=mobunit=="TPS"
gen log_distanceE0=log(distanceE0)

tab period_quarter, gen(periodedummy)

gen distanceE1=sqrt((yt_E1-yr_E1)*(yt_E1-yr_E1)+(xt_E1-xr_E1)*(xt_E1-xr_E1))
replace distanceE1=distanceE1/1000
gen log_distanceE1=log(distanceE1)
gen fulltimeE1=ceE1=="C"
gen cdiE1=contratE1=="01"


save, replace 

***********************************************************************************************
* modification contrat, temps, rome recherchés pour avoir la valeur de début de spell
**********************************************************************************************


use ${SOURCES}catregr, clear
drop ndem
gen year=year(jourfv)
drop if year<2006
drop year
rename contrat contrat_old
rename temps temps_old
rename catregr catregr_old
save catregr_, replace 

use ${SOURCES}rome, clear
drop ndem romeapl
gen year=year(jourfv)
drop if year<2006
drop year
drop if missing(rome)
rename rome rome_old
save rome_, replace 

use ${SOURCES}GEOFLA_COMMUNE, clear
keep INSEE SUPERFICIE
rename INSEE depcom
rename SUPER superficie
save  commune_superficie, replace 

use basedetravail_claimants, clear
unique idfhda datins

joinby idfhda using rome_, unmatched(master)
sort idfhda


gen further_updates=jourdv>=datins&jourfv<=datann
sort idfhda datins jourdv
bys idfhda datins: gen rank_romechange=sum(further_updates)

capture drop irrelevant 
gen irrelevant=(jourdv>=datann|jourfv<datins)&_m==3

replace rome=rome_old if rank==1&irrelevant==0

drop if rank>1|(rank==1&irrelevant==1)

sort idfhda datins irrel
drop jourdv jourfv rome_old _m rank_r further_updates irrel 

duplicates drop 
count
duplicates drop idfhda datins, force

save basedetravail_claimants_updatedrome, replace 

use basedetravail_claimants_updatedrome, clear

joinby idfhda using catregr_ , unmatched(master)
sort idfhda

gen further_updates=jourdv>=datins&jourfv<=datann
sort idfhda datins jourdv
bys idfhda datins: gen rank_change=sum(further_updates)

capture drop irrelevant 
gen irrelevant=(jourdv>=datann|jourfv<datins)&_m==3

replace contrat=contrat_old if rank==1&irrelevant==0
replace temps=temps_old if rank==1&irrelevant==0
replace catregr=catregr_old if rank==1&irrelevant==0

drop if rank>1|(rank==1&irrelevant==1)
drop jourdv jourfv contrat_old temps_old catregr_old _m rank_c further_updates irrel 

duplicates drop 
duplicates drop idfhda datins, force

save basedetravail_claimants_updated, replace 



****************************
** replacing distance for commune travail = commune workplace 
****************************
use commune_superficie , clear
keep depcom superficie
rename depcom depcomt_E0
rename superficie superficie_E0
sort depcom
save commune_superficie_E0, replace 

use commune_superficie , clear
keep depcom superficie
rename depcom depcomt_E1
rename superficie superficie_E1
sort depcom
save commune_superficie_E1, replace 


use basedetravail_claimants_updated, clear
gen depcomt_E0=depE0+comE0
gen depcomt_E1=depE1+comE1
merge m:1 depcomt_E0 using commune_superficie_E0
drop if _m==2
drop _m
merge m:1 depcomt_E1 using commune_superficie_E1
drop if _m==2
drop _m

gen depcomr_E0=depr_E0+comr_E0
gen depcomr_E1=depr_E1+comr_E1

replace distanceE0=(2/3)*sqrt((superficie_E0*0.01)/3.14) if depcomr_E0==depcomt_E0
replace distanceE1=(2/3)*sqrt((superficie_E1*0.01)/3.14) if depcomr_E1==depcomt_E1


save, replace 

*******************************************************************************
* add mobdist in KM for everybody

sum mobdist if mobunit=="KM"
sca mobdist_KM=r(mean)
sum mobdist if mobunit!="KM"
sca mobdist_TPS=r(mean)

sca speed=scalar(mobdist_KM)/scalar(mobdist_TPS)*60
sca list speed

sum distanceE0 if mobunit=="KM"
sca distanceE0_KM=r(mean)
sum distanceE0 if mobunit!="KM"
sca distanceE0_TPS=r(mean)
tab female mobunit, row

sca speed_ADD=(scalar(mobdist_KM)+distanceE0_TPS-distanceE0_KM)/scalar(mobdist_TPS)*60
sca list speed_ADD

sca speed_MULT=(scalar(mobdist_KM)*distanceE0_TPS/distanceE0_KM)/scalar(mobdist_TPS)*60
sca list speed_MULT

gen mobdist_convKM=mobdist
replace mobdist_convKM=mobdist_convKM/60*scalar(speed_ADD) if mobunit!="KM"


gen single_withchild=(married==0)*child
gen childless_single=(married==0)*(child==0)
gen single_withchild_male=male*single_withchild
gen single_withchild_female=female*single_withchild
gen childless_single_male=male*childless_single
gen childless_single_female=female*childless_single
gen married_withchild=(married==1)*child
gen childless_married=(married==1)*(child==0)
gen married_withchild_male=male*married_withchild
gen married_withchild_female=female*married_withchild
gen childless_married_male=male*childless_married
gen childless_married_female=female*childless_married

global occE0="fapE0"

encode a38E0, gen(a38E0_)

capture drop cdi
gen cdi=contrat=="1"

capture drop full_time
gen full_time=temps=="1"
gen fulltime=temps=="1"

drop if motins=="32"

capture drop found_a_job
gen found_a_job=dur_NE<=730

capture drop fulltimeE1 cdiE1
gen fulltimeE1=ceE1=="C"
gen cdiE1=contratE1=="01"
replace fulltimeE1=. if ceE1=="" & found_a_job==0
replace cdiE1=. if contratE1=="" & found_a_job==0

encode salunit, gen(salunit_)
tab salunit_

capture drop log_mobdist
replace mobdist=. if mobunit=="FE"
replace mobdist=1 if mobdist<1
gen log_mobdist=log(mobdist)
capture drop mobunit_tps
gen mobunit_tps=mobunit=="TPS"
replace mobunit_tps=. if mobunit==""|mobunit=="FE"
drop if mobdist==.

gen dur_NE_within2years=dur_NE if dur_NE<=730
replace dur_NE_within2years=. if dur_NE>730

gen mobdist_km=mobdist if mobunit=="KM"
gen mobdist_tps=mobdist if mobunit_tps==1

capture drop log_distance*
sum distanceE1, d
sca p95E1=r(p95)
sum distanceE0, d
sca p95E0=r(p95)
sca list p95E0
replace distanceE1=p95E1 if distanceE1>p95E1 &distanceE1!=.
replace distanceE0=p95E0 if distanceE0>p95E0 &distanceE0!=.

gen log_distanceE0=log(distanceE0)
gen log_distanceE1=log(distanceE1)


cap drop hours_day
gen hours_dayE0=nbheurE0/(dpE0*5/7)
gen weekly_hoursE0=(nbheurE0/dpE0)*7


save basedetravail_final_qje, replace 







