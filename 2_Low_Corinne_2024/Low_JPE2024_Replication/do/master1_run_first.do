clear all
set scheme s2color

//cd "/Users/adstr/Dropbox (Penn)/Reproductive capital/Streamlined/Replication"
cd "C:\Users\dangl\Desktop\replication\Low, Corinne (2024)\Low_JPE2024_Replication\Low_JPE2024_Replication"

global datafile "usa_00009"


*------------------------------------------------------------------------------*
* Clean data for Matlab figures
*------------------------------------------------------------------------------*
* kids4categories
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

replace yrmarr=. if yrmarr==0
gen ageatmarriage=age-(year-yrmarr)
replace ageatmarriage=. if yrmarr==0
replace ageatmarriage=agemarr if ageatmarriage==.

gen educ_cat=1 if educ<=6
replace educ_cat=2 if educ==7 | educ==8 | educ==9
replace educ_cat=3 if educ==10
replace educ_cat=4 if educ==11

drop if sex==1

gen nochild=nchild==0
gen onechild=nchild==1
gen twochild=nchild==2
gen threechild=nchild==3
gen fourchild=(nchild>=4 & nchild~=.)

drop if marst==6
keep if age>=38 & age <=42

collapse nchild nochild onechild twochild threechild fourchild, by(educ_cat year)

export delimited "dta/kids4categories.csv", replace


* census data
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

* dummies for education level
gen		educ_cat = 1 	if educ <= 6
replace educ_cat = 2 	if inrange(educ,7,9)
replace educ_cat = 3    if educ==10
replace educ_cat = 4 	if educ==11

* dummy for married
gen married = (marst==1|marst==2)

* cpi-adjusted total income
gen inctot_adj 		=inctot*cpi99
gen inctot_sp_adj 	=inctot_sp*cpi99

* dummy for full-time work
gen fulltime  = (uhrswork >= 40 & uhrswork != .) | (year <= 1970 & hrswork2 >= 5 & hrswork2 != .)

* sample restriction
keep if race == 1 | race == 2
keep if inrange(age,41,50) 
keep if married == 1

* means for census graph - women only
preserve
	collapse (mean) inctot_sp_adj [aweight=perwt] if sex == 2, by(year educ_cat)	
	export delim using "dta/census_graph3.csv", nolab replace
restore

* create data for simulation
* expand using weights (no weights before 1990)
expand perwt if year >= 1990

* men
export delim year educ_cat inctot_adj perwt if sex == 1 /// any employment status
		using "dta/census_men.csv", nolabel replace	
		
* women
export delim year educ_cat inctot_adj perwt if sex == 2 & fulltime == 1 ///
		using "dta/census_women.csv", nolabel replace	





*------------------------------------------------------------------------------*
* Figure 1 - 2010 (for 45 - 55 year olds)
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if year==1950
drop if year~=2010
drop if age>55
drop if age <=45

*drop perwt
generate perwt_1 = 1

**repeat with adjusted income
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99


**generate age at marriage
gen second=marrno>1
replace second=. if marrno==.

replace yrmarr=. if yrmarr==0
gen ageatmarriage=age-(year-yrmarr)
replace ageatmarriage=. if yrmarr==0
replace ageatmarriage=. if ageatmarriage>55

gen ageatmarriage_sp=age_sp-(year-yrmarr)




*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys ageatmarriage sex second: egen m_inc=wtmean(inctot_sp_adj), weight(perwt)
bys ageatmarriage sex second: gen n2=_n

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys ageatmarriage sex second: generate xi_xbar_sq = (inctot_sp_adj - m_inc)^2
bys ageatmarriage sex second: generate wi_x_xi_xbar_sq = perwt*xi_xbar_sq 
bys ageatmarriage sex second: egen numerator = sum(wi_x_xi_xbar_sq)


*step 3 generate counts and count fraction
bys ageatmarriage sex second: egen c_inc=count(inctot_sp_adj) 
generate c_inc_minus_1 = c_inc-1
generate count_frac = c_inc_minus_1/c_inc


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys ageatmarriage sex second: egen sigma_wi_interim = sum(perwt) 
egen missing_inc = rowmiss(inctot_sp_adj)
bys ageatmarriage sex second: egen missing_within_categ = sum(missing_inc)
generate sigma_wi = sigma_wi_interim - missing_within_categ
generate denominator = count_frac*sigma_wi


*step5 numerator by denominator gives variance
gen wt_var = numerator/denominator 
generate wt_sd = sqrt(wt_var)

*-------*
* making standard error and intervals
*-------*
rename wt_sd sd_inc
gen se_inc=sd_inc/sqrt(c_inc)

replace m_inc=. if n2>1
replace se_inc=. if n2>1
gen u_inc=m_inc+1.96*se_inc
gen l_inc=m_inc-1.96*se_inc


**generate volume of marriages
bys sex second: gen totalmarriages=_N
bys ageatmarriage sex second: gen numbermarriages=_N
gen percentfirstmarriages=numbermarriages/totalmarriages
replace percentfirstmarriages=. if n2>1



local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway (rarea u_inc l_inc ageatmarriage if sex==1, color(gs13) lwidth(none)) ///
       (rarea u_inc l_inc ageatmarriage if sex==2, color(gs13) lwidth(none)) ///
	   (pcarrowi 14000 42 21000 42, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 52000 23 59000 23, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 17000 23.5 17000 25.5, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (line m_inc ageatmarriage if sex==1, lpattern(solid) lcolor(black) mcolor(blue) ysc(r(0 80000)) ylabel(0(20000)80000, nogrid)) ///
	   (line m_inc ageatmarriage if sex==2, lpattern(dash) lcolor(black) mcolor(red) lpattern(longdash)) ///
	   (bar percentfirstmarriages ageatmarriage if sex==2, color(gs5) ///
	   yaxis(2) ylabel(0(.1).3, axis(2)) ytitle("Density of First Marriages",axis(2)) ) if ageatmarriage>19 & ageatmarriage<=45  & second==0, xtick(20(5)45) ///
	   legend(order(1) label(1 95% CI) position(2) ring(0) col(1) size(small) symysize(*.5) symxsize(*.5)) ///
	   text(13000 42 "Men's Spousal Income", size(small)) ///
	   text(51000 26 "Women's Spousal Income", size(small)) ///
	   text(17300 30 "Density of First Marriages", size(small)) ///
	   ytitle("Mean Spousal Income") ///
	   xtitle("Age at First Marriage") ///
	   ylabel(, nogrid angle(horizontal)  ) ///
	   aspectratio(`inv_golden_ratio') ///
	   yscale(nofextend axis(1)) yscale(nofextend axis(2)) xscale(nofextend) ///
	   graphregion(fcolor(white) lcolor(white)) 
graph export "gph/spouse_inc_by_age.eps", replace

*------------------------------------------------------------------------------*
* Figure 2
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear
drop if bpl>99
*-------*
* sample restrictions
*-------*
drop if year==1950
drop if sex==1
keep if age>40 & age<=50

*-----*
*creating (outcome) adjusted income measures (this is real income)
*-----*
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99

*-----*
*create fine education categories
*-----*
gen educ_fine_cat=.
replace educ_fine_cat=1 if educ<6
replace educ_fine_cat=2 if educ==6
replace educ_fine_cat=3 if educ==7 | educ==8 | educ==9
replace educ_fine_cat=4 if educ==10
replace educ_fine_cat=5 if educ==11

collapse inctot inctot_adj inctot_sp inctot_sp_adj, by(educ_fine_cat year)

*making line graphs side by side
*line provided by CL
twoway (line inctot_sp_adj educ_fine_cat, lcolor(black)) ///
       (line inctot_adj educ_fine_cat, lcolor(gray) lpattern(dash)), ///
	   by(year, rows(1) note(" ") graphregion(color(white))) ///
subtitle(, fcolor(gs13) lcolor(white)) ///
legend(pos(6) row(1) order(1 "Spousal Income" 2 "Own Income")) ///
xlabel(1 "<H" 2 "H" 3 "SC" 4 "C" 5 "C+", labsize(small) nogrid) ///
ylabel(0 20000 40000 60000 80000, labsize(medium)) ///
yline(0 20000 40000 60000 80000, lcolor(gs14) lpattern(solid)) ///
xtitle("Education") ///
ytitle("Income, 1999 USD")
graph export "gph/nonmonotonicity.eps", replace


*------------------------------------------------------------------------------*
* Figure 6
*------------------------------------------------------------------------------*
*making the collapsed data for the bar graphs
set more off, perm
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if year==1950
drop if sex==1 
drop if marst==6
keep if age>=38 & age <=42

replace yrmarr=. if yrmarr==0
gen ageatmarriage=age-(year-yrmarr)
replace ageatmarriage=. if yrmarr==0
replace ageatmarriage=agemarr if ageatmarriage==.

gen educ_cat2=1 if educ<=6
replace educ_cat2=2 if educ==7 | educ==8 | educ==9
replace educ_cat2=3 if educ==10
replace educ_cat2=4 if educ==11

label define educ_cat_lab 1 "high school" 2 "some college" 3 "college ed." 4 "highly ed."
label values educ_cat2 educ_cat_lab


gen child0=nchild==0
gen child1=nchild==1
gen child2=nchild==2
gen child3=nchild==3
gen child4=(nchild>=4 & nchild~=.)

gen childborn0=chborn==1
gen childborn1=chborn==2
gen childborn2=chborn==3
gen childborn3=chborn==4
gen childborn4=(chborn>=5 & chborn~=.)

collapse child0 child1 child2 child3 child4 childborn0 childborn1 childborn2 childborn3 childborn4 [pweight=perwt], by(educ_cat2 year)

*-------*
*now reshape the collapsed dataset to make it long form
*-------*
reshape long child childborn, i(year educ_cat2) j(child_cat)
gsort educ_cat2 child_cat year

rename child child_vals
rename childborn childborn_vals
rename child_cat child_cat_code

tempfile collapsed_final
save `collapsed_final'

*----------*
* Data for bar graph 1 - Children in HH
*----------*
drop childborn_vals
keep if year == 1970 | year == 2010


*generate a column that will place the bars in the desired location
gen educandyear1 = .
replace educandyear1 = 1.2 if year == 1970 & educ_cat2 == 1
replace educandyear1 = 3.2 if year == 1970 & educ_cat2 == 2
replace educandyear1 = 5.2 if year == 1970 & educ_cat2 == 3
replace educandyear1 = 7.2 if year == 1970 & educ_cat2 == 4

replace educandyear1 = 10.2 if year == 2010 & educ_cat2 == 1
replace educandyear1 = 12.2 if year == 2010 & educ_cat2 == 2
replace educandyear1 = 14.2 if year == 2010 & educ_cat2 == 3
replace educandyear1 = 16.2 if year == 2010 & educ_cat2 == 4
bys educandyear1 (child_cat_code) : generate child_vals_cum = sum(child_vals)

*------------------------------------------------------------------------------*
* Bar graph 1 - Children in HH
*------------------------------------------------------------------------------*

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond"
twoway bar child_vals_cum educandyear1 if child_cat_code == 4, barw(1.6) bcolor(gs3)|| ///
	   bar child_vals_cum educandyear1 if child_cat_code == 3, barw(1.6) bcolor(gs6)|| ///
       bar child_vals_cum educandyear1 if child_cat_code == 2, barw(1.6) bcolor(gs9)|| ///
       bar child_vals_cum educandyear1 if child_cat_code == 1, barw(1.6) bcolor(gs11)|| ///
	   bar child_vals_cum educandyear1 if child_cat_code == 0, barw(1.6) bcolor(gs14) ///
	   legend(order(1 "4+"                    ///
                    2 "3"                         ///
                    3 "2"                      ///
                    4 "1"                         ///
                    5 "0") size(medium) pos(3) cols(1) region(style(none)) subtitle("Children") symxsize(6))       ///
	   ytitle("") ///
	   ylabel(0 "0" .20 "20%" .40  "40%" .60 "60%" .80 "80%" 1 "100%", noticks nogrid angle(0) labsize(medium)) ///
	   xtitle("") ///
	   xlabel("") ///
	   graphregion(color(white)) ///
	   aspectratio(`inv_golden_ratio') ///
	   text(-.07 1.2 "High" -.07 3.2 "Some" -.07 5.2 "College" -.07 7.2 "Highly") ///
	   text(-.14 1.2 "School" -.14 3.2 "College" -.14 5.2 "Educ." -.14 7.2 "Educ.") ///
	   text(-.07 10.2 "High" -.07 12.2 "Some" -.07 14.2 "College" -.07 16.2 "Highly") ///
	   text(-.14 10.2 "School" -.14 12.2 "College" -.14 14.2 "Educ." -.14 16.2 "Educ.")  ///
	   text(-.22 4.2 "1970" -.22 13.2 "2010" , size(medium))
graph export "gph/ed_child.eps", replace
	   
	 
	 *------------------------------------------------------------------------------*
* Figure A1
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if year==1950
drop if year~=2010
drop if age>45
drop if age <=36


**repeat with adjusted income
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99


**generate age at marriage
gen second=marrno>1
replace second=. if marrno==.

replace yrmarr=. if yrmarr==0
gen ageatmarriage=age-(year-yrmarr)
replace ageatmarriage=. if yrmarr==0
replace ageatmarriage=. if ageatmarriage>45

gen ageatmarriage_sp=age_sp-(year-yrmarr)


*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys ageatmarriage sex second: egen m_inc=wtmean(inctot_sp_adj), weight(perwt)
bys ageatmarriage sex second: gen n2=_n

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys ageatmarriage sex second: generate xi_xbar_sq = (inctot_sp_adj - m_inc)^2
bys ageatmarriage sex second: generate wi_x_xi_xbar_sq = perwt*xi_xbar_sq 
bys ageatmarriage sex second: egen numerator = sum(wi_x_xi_xbar_sq)


*step 3 generate counts and count fraction
bys ageatmarriage sex second: egen c_inc=count(inctot_sp_adj) 
generate c_inc_minus_1 = c_inc-1
generate count_frac = c_inc_minus_1/c_inc


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys ageatmarriage sex second: egen sigma_wi_interim = sum(perwt) 
egen missing_inc = rowmiss(inctot_sp_adj)
bys ageatmarriage sex second: egen missing_within_categ = sum(missing_inc)
generate sigma_wi = sigma_wi_interim - missing_within_categ
generate denominator = count_frac*sigma_wi


*step5 numerator by denominator gives variance
gen wt_var = numerator/denominator 
generate wt_sd = sqrt(wt_var)

*-------*
* making standard error and intervals
*-------*
rename wt_sd sd_inc
gen se_inc=sd_inc/sqrt(c_inc)

replace m_inc=. if n2>1
replace se_inc=. if n2>1
gen u_inc=m_inc+1.96*se_inc
gen l_inc=m_inc-1.96*se_inc


**generate volume of marriages
bys sex second: gen totalmarriages=_N
bys ageatmarriage sex second: gen numbermarriages=_N
gen percentfirstmarriages=numbermarriages/totalmarriages
replace percentfirstmarriages=. if n2>1



local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway (rarea u_inc l_inc ageatmarriage if sex==1, color(gs13) lwidth(none)) ///
       (rarea u_inc l_inc ageatmarriage if sex==2, color(gs13) lwidth(none)) ///
	   (pcarrowi 21500 32 26000 32, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 50000 23 54500 23, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 12500 27 17000 27, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (line m_inc ageatmarriage if sex==1, lpattern(solid) lcolor(black) mcolor(blue) ysc(r(0 70000)) ylabel(0(10000)70000, nogrid)) ///
	   (line m_inc ageatmarriage if sex==2, lpattern(dash) lcolor(black) mcolor(red) lpattern(longdash)) ///
	   (bar percentfirstmarriages ageatmarriage if sex==2, color(gs5) ///
	   yaxis(2) ylabel(0(.1).3, axis(2)) ytitle("Density of First Marriages",axis(2)) ) if ageatmarriage>19 & ageatmarriage<=35  & second==0, xtick(20(5)35) ///
	   legend(order(1) label(1 95% CI) position(2) ring(0) col(1) size(small) symysize(*.5) symxsize(*.5)) ///
	   text(19500 32 "Men's Spousal Income", size(small)) ///
	   text(49000 24 "Women's Spousal Income", size(small)) ///
	   text(19000 27 "Density of First Marriages", size(small)) ///
	   ytitle("Mean Spousal Income") ///
	   xtitle("Age at First Marriage") ///
	   ylabel(, nogrid angle(horizontal)  ) ///
	   aspectratio(`inv_golden_ratio') ///
	   yscale(nofextend axis(1)) yscale(nofextend axis(2)) xscale(nofextend) ///
	   graphregion(fcolor(white) lcolor(white)) 
graph export "gph/figA1_spouse_in_by_age_36_45.eps", replace


*------------------------------------------------------------------------------*
* Figure A2
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if year==1950
drop if sex==1
keep if age>40 & age<=50
**generate age at marriage
gen second=marrno>1
replace second=. if marrno==.
keep if second==0

*-----*
*creating (outcome) adjusted income measures (this is real income)
*-----*
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99

*-----*
*create fine education categories
*-----*
gen educ_fine_cat=.
replace educ_fine_cat=1 if educ<6
replace educ_fine_cat=2 if educ==6
replace educ_fine_cat=3 if educ==7 | educ==8 | educ==9
replace educ_fine_cat=4 if educ==10
replace educ_fine_cat=5 if educ==11

collapse inctot inctot_adj inctot_sp inctot_sp_adj, by(educ_fine_cat year)

*making line graphs side by side
*line provided by CL
twoway (line inctot_sp_adj educ_fine_cat, lcolor(black)) ///
       (line inctot_adj educ_fine_cat, lcolor(gray) lpattern(dash)), ///
	   by(year, rows(1) note(" ") graphregion(color(white))) ///
subtitle(, fcolor(gs13) lcolor(white)) ///
legend(pos(6) row(1) order(1 "Spousal Income" 2 "Own Income")) ///
xlabel(1 "<H" 2 "H" 3 "SC" 4 "C" 5 "C+", labsize(small) nogrid) ///
ylabel(0 20000 40000 60000 80000, labsize(medium)) ///
yline(0 20000 40000 60000 80000, lcolor(gs14) lpattern(solid)) ///
xtitle("Education") ///
ytitle("Income, 1999 USD") 
graph export "gph/figA2_nonmonotonicity_firstonly.eps", replace
	
	
*------------------------------------------------------------------------------*
* Figure A3
*------------------------------------------------------------------------------*

*Marriage
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if year==1950
drop if age<=40
drop if age>50
drop if sex==1



**repeat with adjusted income
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99



************
**PREP
***********

generate highlyeducated=(educ==11)
generate collegeeducated=(educ==10)
generate everyoneelse=(educ~=11 & educ~=10)
gen educ_cat=1 if educ~=10 & educ ~=11
replace educ_cat=2 if educ==10
replace educ_cat=3 if educ==11

generate married=(marst==1|marst==2)
generate evermarried=(marst~=6)
gen second=marrno>1
replace second=. if marrno==.

bys year: egen m_highlyed=mean(highlyeducated) 
bys year: egen m_collegeed=mean(collegeeducated) 
bys year: egen m_elseed=mean(everyoneelse) 

**generate income means and sd
*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys year educ_cat: egen m_inctot_sp_adj=wtmean(inctot_sp_adj), weight(perwt)

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys year educ_cat: generate xi_xbar_sq = (inctot_sp_adj - m_inctot_sp_adj)^2
bys year educ_cat: generate wi_x_xi_xbar_sq = perwt*xi_xbar_sq 
bys year educ_cat: egen numerator = sum(wi_x_xi_xbar_sq)


*step 3 generate counts and count fraction
bys year educ_cat: egen c_inctot_sp_adj=count(inctot_sp_adj) 
generate c_inc_minus_1 = c_inctot_sp_adj-1
generate count_frac = c_inc_minus_1/c_inctot_sp_adj


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys year educ_cat: egen sigma_wi_interim = sum(perwt) 
egen missing_inc = rowmiss(inctot_sp_adj)
bys year educ_cat: egen missing_within_categ = sum(missing_inc)
generate sigma_wi = sigma_wi_interim - missing_within_categ
generate denominator = count_frac*sigma_wi


*step5 numerator by denominator gives variance
gen wt_var = numerator/denominator 
generate wt_sd = sqrt(wt_var)


*-------*
* making standard error and intervals
*-------*
rename wt_sd sd_inctot_sp_adj
gen se_inctot_sp_adj=sd_inctot_sp_adj/sqrt(c_inctot_sp_adj)

gen u_inctot_sp_adj=m_inctot_sp_adj+1.96*se_inctot_sp_adj
gen l_inctot_sp_adj=m_inctot_sp_adj-1.96*se_inctot_sp_adj


bys year educ_cat: gen n=_n

foreach var of varlist m_inctot_sp_adj u_inctot_sp_adj l_inctot_sp_adj{
replace `var'=. if n>1
}
	

**gen marriage rate means and SDs	
	
*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys year educ_cat: egen m_evermarried=wtmean(evermarried), weight(perwt)

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys year educ_cat: generate xi_xbar_sq1 = (evermarried - m_evermarried)^2
bys year educ_cat: generate wi_x_xi_xbar_sq1 = perwt*xi_xbar_sq1
bys year educ_cat: egen numerator1 = sum(wi_x_xi_xbar_sq1)


*step 3 generate counts and count fraction
bys year educ_cat: egen c_evermarried=count(evermarried) 
generate c_inc_minus_11 = c_evermarried-1
generate count_frac1 = c_inc_minus_11/c_evermarried


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys year educ_cat: egen sigma_wi_interim1 = sum(perwt) 
egen missing_inc1 = rowmiss(evermarried)
bys year educ_cat: egen missing_within_categ1 = sum(missing_inc1)
generate sigma_wi1 = sigma_wi_interim1 - missing_within_categ1
generate denominator1 = count_frac1*sigma_wi1


*step5 numerator by denominator gives variance
gen wt_var1 = numerator1/denominator1 
generate wt_sd1 = sqrt(wt_var1)


*-------*
* making standard error and intervals
*-------*
rename wt_sd1 sd_evermarried
gen se_evermarried=sd_evermarried/sqrt(c_evermarried)

gen u_evermarried=m_evermarried+1.96*se_evermarried
gen l_evermarried=m_evermarried-1.96*se_evermarried


bys year educ_cat: gen n2=_n

foreach var of varlist m_evermarried u_evermarried l_evermarried{
replace `var'=. if n2>1
}
		
	

**gen currently married rates means and SDs

*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys year educ_cat: egen m_married=wtmean(married), weight(perwt)


*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys year educ_cat: generate xi_xbar_sq2 = (married - m_married)^2
bys year educ_cat: generate wi_x_xi_xbar_sq2 = perwt*xi_xbar_sq2 
bys year educ_cat: egen numerator2 = sum(wi_x_xi_xbar_sq2)


*step 3 generate counts and count fraction
bys year educ_cat: egen c_married=count(married) 
generate c_inc_minus_12 = c_married-1
generate count_frac2 = c_inc_minus_12/c_married


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys year educ_cat: egen sigma_wi_interim2 = sum(perwt) 
egen missing_inc2 = rowmiss(married)
bys year educ_cat: egen missing_within_categ2 = sum(missing_inc2)
generate sigma_wi2 = sigma_wi_interim2 - missing_within_categ2
generate denominator2 = count_frac2*sigma_wi2


*step5 numerator by denominator gives variance
gen wt_var2 = numerator2/denominator2 
generate wt_sd2 = sqrt(wt_var2)


*-------*
* making standard error and intervals
*-------*
rename wt_sd2 sd_married
gen se_married=sd_married/sqrt(c_married)

gen u_married=m_married+1.96*se_married
gen l_married=m_married-1.96*se_married

foreach var of varlist m_married u_married l_married{
replace `var'=. if n2>1
}
	

****** (1) Income ********
**by birth cohort
**right now use 41 to 50
gen p_highlyed=m_highlyed*100
gen p_college=m_collegeed*100
replace p_highlyed=. if n>1
replace p_college=. if n>1


format  %3.2f  p_highlyed
format  %3.2f  p_college


**create difference in spousal income for college vs graduate
gen inc_sp_college=m_inctot_sp_adj if educ==10
bys year: egen m_inc_sp_college=mean(inc_sp_college)
gen inc_sp_highly=m_inctot_sp_adj if educ==11
bys year: egen m_inc_sp_highly=mean(inc_sp_highly)
gen d_income=m_inc_sp_highly-inc_sp_college 
bys year: gen n_d=_n

gen p_highly_scale= p_highlyed*300
replace p_highly_scale=. if n_d>1


*********************************
**REDO RESTRICTING TO FIRST MARRIAGES
*********************************
gen educ_cat2=educ_cat
replace educ_cat2=0 if educ<6
replace educ_cat2=1 if educ==6
replace educ_cat2=2 if educ>6 & educ<10
replace educ_cat2=4 if educ==10
replace educ_cat2=5 if educ==11



**generate income means and sd

bys year educ_cat2 second: egen m_inctot_sp_adj2_f=wtmean(inctot_sp_adj), weight(perwt)

bys year educ_cat2 second: egen sd_inctot_sp_adj2_f=sd(inctot_sp_adj)
bys year educ_cat2 second: egen c_inctot_sp_adj2_f=count(inctot_sp_adj) 
gen se_inctot_sp_adj2_f=sd_inctot_sp_adj2_f/sqrt(c_inctot_sp_adj2_f)


gen u_inctot_sp_adj2_f=m_inctot_sp_adj2_f+1.96*se_inctot_sp_adj2_f
gen l_inctot_sp_adj2_f=m_inctot_sp_adj2_f-1.96*se_inctot_sp_adj2_f

drop n2
bys year educ_cat2 second: gen n2=_n

foreach var of varlist m_inctot_sp_adj2_f u_inctot_sp_adj2_f l_inctot_sp_adj2_f{
replace `var'=. if n2>1
}


local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway (rarea u_evermarried l_evermarried year if educ==11, color(gs13) lwidth(none)) ///
       (rarea u_evermarried l_evermarried year if educ==10, color(gs13) lwidth(none))  ///
	   (pcarrowi 0.85 1995 0.865 1995, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 0.91 1975 0.925 1975, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 0.91 2000 0.925 2000, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (line m_evermarried year if educ==11, lpattern(solid) lcolor(gray)) ///
	   (line m_evermarried year if educ==10, lpattern(dash) lcolor(gray)) ///
	   (line m_evermarried year if educ_cat==1, lcolor(gs11) lpattern(shortdash)) , ///
	legend(order(2) label(2 95% CI) position(4) ring(0) col(1) size(small) symysize(*.5) symxsize(*.5)) ///
	text(0.90 1976 "College Educated", size(medsmall)) ///
	text(0.84 1995 "Highly Educated", size(medsmall)) ///
	text(0.955 2000 "Everyone", size(medsmall)) ///
	text(0.94 2000 "Else", size(medsmall)) ///
	ytitle("Percent Ever Married") ///
	xtitle("Census Year") ///
	ylabel(, nogrid angle(horizontal)  ) ///
	aspectratio(`inv_golden_ratio') ///
	yscale( nofextend ) xscale(nofextend) ///
	scale(1.5) ///
	graphregion(fcolor(white) lcolor(white)) 
graph export "gph/figA3_left_evermarried.eps", replace
	
	
*Divorce
use "src/$datafile.dta", clear
drop if bpl>99 // keep only native born

*-------*
* sample restrictions
*-------*
drop if age<=40
drop if age>50
drop if year==1950
drop if sex==1


replace agemarr=. if agemarr==0
replace yrmarr=. if yrmarr==0|yrmarr<birthyr

replace agemarr=yrmarr-birthyr if year==2010
replace yrmarr=agemarr+birthyr if yrmarr==.

generate highlyeducated=(educ==11)
generate collegeeducated=(educ==10)
gen highlyvcollege=.
replace highlyvcollege=1 if highlyeducated==1
replace highlyvcollege=0 if collegeeducated==1

generate evermarried=(marst~=6)

**repeat with adjusted income


gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99



gen educ_cat=1 if educ~=10 & educ ~=11
replace educ_cat=2 if educ==10
replace educ_cat=3 if educ==11




**Currently divorced**


gen nowdivorced=(marst==4)
replace nowdivorced=. if evermarried==0

*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys year educ_cat: egen m_nowdivorced=wtmean(nowdivorced), weight(perwt)

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys year educ_cat: generate xi_xbar_sq = (nowdivorced - m_nowdivorced)^2
bys year educ_cat: generate wi_x_xi_xbar_sq = perwt*xi_xbar_sq 
bys year educ_cat: egen numerator = sum(wi_x_xi_xbar_sq)


*step 3 generate counts and count fraction
bys year educ_cat: egen c_nowdivorced=count(nowdivorced) 
generate c_inc_minus_1 = c_nowdivorced-1
generate count_frac = c_inc_minus_1/c_nowdivorced


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys year educ_cat: egen sigma_wi_interim = sum(perwt) 
egen missing_inc = rowmiss(nowdivorced)
bys year educ_cat: egen missing_within_categ = sum(missing_inc)
generate sigma_wi = sigma_wi_interim - missing_within_categ
generate denominator = count_frac*sigma_wi


*step5 numerator by denominator gives variance
gen wt_var = numerator/denominator 
generate wt_sd = sqrt(wt_var)


*-------*
* making standard error and intervals
*-------*
rename wt_sd sd_nowdivorced
gen se_nowdivorced=sd_nowdivorced/sqrt(c_nowdivorced)

gen u_nowdivorced=m_nowdivorced+1.96*se_nowdivorced
gen l_nowdivorced=m_nowdivorced-1.96*se_nowdivorced


bys year educ_cat: gen n=_n

foreach var of varlist m_nowdivorced u_nowdivorced l_nowdivorced{
replace `var'=. if n>1
}
	



local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway (rarea u_nowdivorced l_nowdivorced year if educ==11, color(gs13) lwidth(none)) ///
	   (rarea u_nowdivorced l_nowdivorced year if educ==10, color(gs13) lwidth(none))  ///
	   (pcarrowi 0.140 1993 0.152 1993, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 0.200 1990 0.210 1990, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi 0.200 2005 0.215 2005, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (line m_nowdivorced year if educ==11, lpattern(solid) lcolor(gray)) ///
	   (line m_nowdivorced year if educ==10, lpattern(dash) lcolor(gray)) ///
	   (line m_nowdivorced year if educ_cat==1, lcolor(gs11) lpattern(shortdash)) , ///
	legend(order(2) label(2 95% CI) position(4) ring(0) col(1) size(small) symysize(*.5) symxsize(*.5)) ///
	text(0.132 1997 "College Educated", size(medsmall)) ///
	text(0.220 1990 "Highly Educated", size(medsmall)) ///
	text(0.196 2005 "Everyone", size(medsmall)) ///
	text(0.183 2005 "Else", size(medsmall)) ///
	ytitle("Percent Currently Divorced") ///
	xtitle(Census Year) ///
	ylabel(, nogrid angle(horizontal)  ) ///
	aspectratio(`inv_golden_ratio') ///
	yscale( nofextend ) xscale(nofextend) ///
	scale(1.5) ///
	graphregion(fcolor(white) lcolor(white)) 
graph export "gph/figA3_right_divorce.eps", replace




*------------------------------------------------------------------------------*
* Figure A6
*------------------------------------------------------------------------------*
*----------*
* Data for bar graph 2 - Children born
*----------*
use `collapsed_final', clear
drop child_vals
keep if year == 1970 | year == 1990

*generate a column that will place the bars in the desired location
gen educandyear1 = .
replace educandyear1 = 1.2 if year == 1970 & educ_cat2 == 1
replace educandyear1 = 3.2 if year == 1970 & educ_cat2 == 2
replace educandyear1 = 5.2 if year == 1970 & educ_cat2 == 3
replace educandyear1 = 7.2 if year == 1970 & educ_cat2 == 4

replace educandyear1 = 10.2 if year == 1990 & educ_cat2 == 1
replace educandyear1 = 12.2 if year == 1990 & educ_cat2 == 2
replace educandyear1 = 14.2 if year == 1990 & educ_cat2 == 3
replace educandyear1 = 16.2 if year == 1990 & educ_cat2 == 4

bys educandyear1 (child_cat_code) : generate childborn_vals_cum = sum(childborn_vals)

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond"
twoway bar childborn_vals_cum educandyear1 if child_cat_code == 4, barw(1.6) bcolor(gs3)|| ///
	   bar childborn_vals_cum educandyear1 if child_cat_code == 3, barw(1.6) bcolor(gs6)|| ///
       bar childborn_vals_cum educandyear1 if child_cat_code == 2, barw(1.6) bcolor(gs9)|| ///
       bar childborn_vals_cum educandyear1 if child_cat_code == 1, barw(1.6) bcolor(gs11)|| ///
	   bar childborn_vals_cum educandyear1 if child_cat_code == 0, barw(1.6) bcolor(gs14) ///
	   legend(order(1 "4+"                    ///
                    2 "3"                         ///
                    3 "2"                      ///
                    4 "1"                         ///
                    5 "0") size(medium) pos(3) cols(1) region(style(none)) symxsize(6))       ///
	   ytitle("") ///
	   ylabel(0 "0" .20 "20%" .40  "40%" .60 "60%" .80 "80%" 1 "100%", noticks nogrid angle(0) labsize(medium)) ///
	   xtitle("") ///
	   xlabel("") ///
	   graphregion(color(white)) ///
	   aspectratio(`inv_golden_ratio') ///
	   text(-.07 1.2 "High" -.07 3.2 "Some" -.07 5.2 "College" -.07 7.2 "Highly") ///
	   text(-.14 1.2 "School" -.14 3.2 "College" -.14 5.2 "Educ." -.14 7.2 "Educ.") ///
	   text(-.07 10.2 "High" -.07 12.2 "Some" -.07 14.2 "College" -.07 16.2 "Highly") ///
	   text(-.14 10.2 "School" -.14 12.2 "College" -.14 14.2 "Educ." -.14 16.2 "Educ.")  ///
	   text(-.21 4.2 "1970" -.21 13.2 "1990" , size(medium)) ///
	   text(0.8 18.7 "Children", size(medium)) ///
	   text(0.75 18.7 "Born", size(medium))
graph export "gph/figA6_4ed_childborn.eps", replace


	
*------------------------------------------------------------------------------*
* Figure A10
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear	
drop if bpl>99 // keep only native born
	
*-------*
* sample restrictions
*-------*
drop if year==1950
drop if age<=40
drop if age>50
drop if sex==1


**data has both sexes, years 1960-2010, and ages 30-60


**repeat with adjusted income
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99

************
**PREP
***********

generate highlyeducated=(educ==11)
generate collegeeducated=(educ==10)
generate everyoneelse=(educ~=11 & educ~=10)
gen educ_cat=1 if educ~=10 & educ ~=11
replace educ_cat=2 if educ==10
replace educ_cat=3 if educ==11

generate married=(marst==1|marst==2)
generate evermarried=(marst~=6)
gen second=marrno>1
replace second=. if marrno==.

bys year: egen m_highlyed=mean(highlyeducated) 
bys year: egen m_collegeed=mean(collegeeducated) 
bys year: egen m_elseed=mean(everyoneelse) 


*-------*
* computing weighted mean and standard error
*-------*
*step1 generate weighted mean
bys year educ_cat: egen m_inctot_sp_adj=wtmean(inctot_sp_adj), weight(perwt)

*step2 generate numerator of weighted standard deviation sum(wi*(xi - mean)^2)
bys year educ_cat: generate xi_xbar_sq = (inctot_sp_adj - m_inctot_sp_adj)^2
bys year educ_cat: generate wi_x_xi_xbar_sq = perwt*xi_xbar_sq 
bys year educ_cat: egen numerator = sum(wi_x_xi_xbar_sq)


*step 3 generate counts and count fraction
bys year educ_cat: egen c_inctot_sp_adj=count(inctot_sp_adj) 
generate c_inc_minus_1 = c_inctot_sp_adj-1
generate count_frac = c_inc_minus_1/c_inctot_sp_adj


*step4 generate denominator of weighted standard deviation ((N-1)/N)*sum(wi) - remember we have all non zero weights
bys year educ_cat: egen sigma_wi_interim = sum(perwt) 
egen missing_inc = rowmiss(inctot_sp_adj)
bys year educ_cat: egen missing_within_categ = sum(missing_inc)
generate sigma_wi = sigma_wi_interim - missing_within_categ
generate denominator = count_frac*sigma_wi


*step5 numerator by denominator gives variance
gen wt_var = numerator/denominator 
generate wt_sd = sqrt(wt_var)


*-------*
* making standard error and intervals
*-------*
rename wt_sd sd_inctot_sp_adj
gen se_inctot_sp_adj=sd_inctot_sp_adj/sqrt(c_inctot_sp_adj)

gen u_inctot_sp_adj=m_inctot_sp_adj+1.96*se_inctot_sp_adj
gen l_inctot_sp_adj=m_inctot_sp_adj-1.96*se_inctot_sp_adj


bys year educ_cat: gen n=_n

foreach var of varlist m_inctot_sp_adj u_inctot_sp_adj l_inctot_sp_adj{
replace `var'=. if n>1
}
	
	
****** (1) Income ********
**by birth cohort
**right now use 41 to 50


gen p_highlyed=m_highlyed*100
gen p_college=m_collegeed*100
replace p_highlyed=. if n>1
replace p_college=. if n>1


format  %3.2f  p_highlyed
format  %3.2f  p_college


**create difference in spousal income for college vs graduate
gen inc_sp_college=m_inctot_sp_adj if educ==10
bys year: egen m_inc_sp_college=mean(inc_sp_college)
gen inc_sp_highly=m_inctot_sp_adj if educ==11
bys year: egen m_inc_sp_highly=mean(inc_sp_highly)
gen d_income=m_inc_sp_highly-inc_sp_college 
bys year: gen n_d=_n

gen p_highly_scale= p_highlyed*300
replace p_highly_scale=. if n_d>1

local inv_golden_ratio = 2 / ( sqrt(5) + 1 )
graph set window fontface "Garamond" 
twoway (bar p_highly_scale year, color(gs5)) ///
	   (pcarrowi 4800 1993 4800 1996, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	   (pcarrowi -100 1960 -1000 1962, msize(0) mcolor(white) lcolor(black) lwidth(0.1)) ///
	(connected d_income year, lpattern(dash) lcolor(gray) mcolor(black) m(circle)), ///
	ytitle("Spousal Income Gap, Highly Ed - College, 1999 USDs") yscale( range(-5000(5000)7000) ) ylabel(-5000(5000)5000) ///
	xtitle(Census Year) xscale( range(1960 2012) ) ///
	yline(0, lcolor(black)) ///
	ylabel(, nogrid angle(horizontal)  ) ///
	text(5000 1989 "Spousal", size(medium)) ///
	text(4300 1989 "Income Gap", size(medium)) ///
	text(-1200 1965 "Percent Highly", size(medium)) ///
	text(-1800 1965 "Educated", size(medium)) ///
	aspectratio(`inv_golden_ratio') ///
	yscale( nofextend ) xscale(nofextend) ///
	graphregion(fcolor(white) lcolor(white)) legend(off)
graph export "gph/figA10_percenthighlyandgap.eps", replace

	
	
	
*==============================================================================*
*    TABLES
*------------------------------------------------------------------------------*

*------------------------------------------------------------------------------*
* Table 1
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear

*----------------------*
* sample restrictions
*----------------------*
drop if bpl>99 // keep only native born
drop if year==1950
drop if sex==1

*-----*
*creating (outcome) adjusted income measures (this is real income)
*-----*
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99

*-----------------------------------*
* creating education level indicator
*-----------------------------------*
* High school or less
generate highschorless = 0
replace highschorless = 1 if educ <= 6

* Some college
generate somecoll = 0
replace somecoll = 1 if educ == 7 | educ == 8 | educ == 9

* College educated
generate collegeeducated=(educ==10)

* Highly educated
generate highlyeducated=(educ==11)

*-----------------------------------------*
* creating comparison between groups indicator
*-----------------------------------------*

* Some college vs high school (takes value 0 if some college and 1 if high school)
generate somecollvhighsch = .
replace somecollvhighsch = 0 if somecoll == 1
replace somecollvhighsch = 1 if highschorless == 1


* College vs somecollege (takes value 0 if college and 1 if some college)
generate collvsomecoll = .
replace collvsomecoll = 0 if collegeeducated == 1
replace collvsomecoll = 1 if somecoll == 1


* Highly ed vs College (takes value 0 if highly ed and 1 if college)
generate highlyvcollege = .
replace highlyvcollege = 0 if highlyeducated == 1
replace highlyvcollege = 1 if collegeeducated == 1

*-----------*
* LaTeX friendly outputs
*-----------*
*creating proprtion of children variable
gen child_geq_four = .
replace child_geq_four = 0 if nchild < 4
replace child_geq_four = 1 if nchild >= 4

*creating proprtion of children born variable
gen chborn_geq_four = .
replace chborn_geq_four = 0 if chborn < 4
replace chborn_geq_four = 1 if chborn >= 4


*creating age at marriage
replace yrmarr=. if yrmarr==0
gen ageatmarriage=age-(year-yrmarr)
replace ageatmarriage=. if yrmarr==0
replace ageatmarriage=agemarr if ageatmarriage==.


keep year race marst educ age perwt ///
     inctot_adj agemarr ageatmarriage inctot_sp_adj nchild child_geq_four chborn chborn_geq_four ///
	 highschorless somecoll collegeeducated highlyeducated ///
	 somecollvhighsch collvsomecoll highlyvcollege

label variable inctot_adj "Income"
label variable inctot_sp_adj "Spousal Income"
label variable ageatmarriage "Age at Marriage"
label variable nchild "Children in HH"
label variable child_geq_four "$\geq$ 4 children in HH"
label variable chborn "Children ever born"
label variable chborn_geq_four "$\geq$ 4 children ever born"


*-----------------------------------------*
* Summary statistics table
*-----------------------------------------*
* http://repec.org/bocode/e/estout/hlp_estpost.html

// easier to use categorical var instead of different binary vars
gen eductbl = 1 if highschorless==1
replace eductbl = 2 if somecoll==1
replace eductbl = 3 if collegeeducated==1
replace eductbl = 4 if highlyeducated==1
label define educlvl 1 "$\leq$ High School" 2 "Some college" 3 "College Ed." 4 "Highly Ed - College Ed."
label values eductbl educlvl

// initialize matrix
matrix mymat = J(5,5,.)

// first 4 columns
forval col = 1/4 {
	// row counter
	local row = 1
	
	// income
	foreach var in inctot_adj inctot_sp_adj {
		sum `var'  if year == 1970 & age >= 41 & age < 51 & eductbl==`col' [fweight = perwt]
		local mean: di %6.0f r(mean)
		matrix mymat[`row',`col'] = `mean'
		di mymat[`row', `col']
		local row = `row' + 1
	}
	
	// age at marriage 
	sum ageatmarriage if year == 1970 & age >= 41 & age < 51 & marst != 6 & eductbl==`col' [fweight = perwt]
	matrix mymat[`row',`col'] = r(mean)
	local row = `row' + 1
	
	// children 
	foreach var in nchild child_geq_four {
		sum `var' if year == 1970 & age >= 38 & age < 43 & marst != 6 & eductbl==`col' [fweight = perwt]
		matrix mymat[`row', `col'] = r(mean)
		local row = `row' + 1
	}
	
}

// last column 
* Highly ed vs College (takes value 0 if highly ed and 1 if college)
generate highly_minus_college = .
replace highly_minus_college = 0 if collegeeducated == 1
replace highly_minus_college = 1 if highlyeducated == 1
reg inctot_adj highly_minus_college if year == 1970 & age >= 41 & age < 51 [pweight = perwt]
matrix mymat[1,5] = e(b)[1,1]
reg inctot_sp_adj highly_minus_college if year == 1970 & age >= 41 & age < 51 [pweight = perwt]
matrix mymat[2,5] = e(b)[1,1]
reg ageatmarriage highly_minus_college if year == 1970 & age >= 41 & age < 51 & marst != 6 [pweight = perwt]
matrix mymat[3,5] = e(b)[1,1]
reg nchild highly_minus_college if year == 1970 & age >= 38 & age < 43 & marst != 6 [pweight = perwt]
matrix mymat[4,5] = e(b)[1,1]
reg child_geq_four highly_minus_college if year == 1970 & age >= 38 & age < 43 & marst != 6 [pweight = perwt]
matrix mymat[5,5] = e(b)[1,1]

matrix list mymat

matrix colnames mymat = "$\leq$ High School" "Some college" "College Ed." "Highly Ed." "Highly Ed -\\ College Ed."
matrix rownames mymat = "Income" "Spousal Income" "Age at Marriage" "Children in HH" "$\geq 4$ Children in HH"

esttab matrix(mymat, fmt(%12.2fc)) using "tbl/table1_sumstats_educ.tex", booktabs nomtitle replace



*------------------------------------------------------------------------------*
* Table A1
*------------------------------------------------------------------------------*
use "src/$datafile.dta", clear
drop if bpl > 99

*----------------------*
* sample restrictions
*----------------------*
*drop if race~=1
drop if year==1950
drop if age<=41
drop if age>51
drop if sex==1

*-----*
*creating (outcome) adjusted income measures (this is real income)
*-----*
gen incwage_adj=incwage*cpi99
gen incwage_sp_adj=incwage_sp*cpi99
gen inctot_adj=inctot*cpi99
gen inctot_sp_adj=inctot_sp*cpi99

* creating indicators/treatment variable
generate highlyeducated=(educ==11)
generate collegeeducated=(educ==10)

* highlyvcollege variable is 1 if the person is highly educated and 0 if college educated
gen highlyvcollege=.
replace highlyvcollege=1 if highlyeducated==1
replace highlyvcollege=0 if collegeeducated==1

**all years
gen I_year1960=year==1960
gen H_year1960Xhvc=I_year1960*highlyvcollege
gen I_year1970=year==1970
gen H_year1970Xhvc=I_year1970*highlyvcollege
gen I_year1980=year==1980
gen H_year1980Xhvc=I_year1980*highlyvcollege
gen I_year1990=year==1990
gen H_year1990Xhvc=I_year1990*highlyvcollege
gen I_year2000=year==2000
gen H_year2000Xhvc=I_year2000*highlyvcollege
gen I_year2010=year==2010
gen H_year2010Xhvc=I_year2010*highlyvcollege

label variable H_year1960Xhv "1960 $\times$ highly ed."
label variable H_year1970Xhv "1970 $\times$ highly ed."
label variable H_year1980Xhv "1980 $\times$ highly ed."
label variable H_year1990Xhv "1990 $\times$ highly ed."
label variable H_year2000Xhv "2000 $\times$ highly ed."
label variable H_year2010Xhv "2010 $\times$ highly ed."



eststo col1: regress inctot_sp_adj H_* I_* [pweight = perwt]
estadd local yearfe = "Y"
estadd scalar obs = e(N)

**add age fixed effects
xi i.birthyr
eststo col2: regress inctot_sp_adj H_* I_* _I* [pweight = perwt]
estadd local yearfe = "Y"
estadd local yobfe = "Y"
estadd scalar obs = e(N)

**add spouse age control
*xi i.birthyr
eststo col3: regress inctot_sp_adj H_* age_sp I_* _I* [pweight = perwt]
estadd local yearfe = "Y"
estadd local yobfe = "Y"
estadd local spouse_age = "Y"
estadd scalar obs = e(N)

esttab col1 col2 col3 using "tbl/tableA1_spouse_inc_educ.tex", se keep(H* _cons) b(%6.0fc) label nomtitle noobs stats(yearfe yobfe spouse_age obs, labels("Year FE" "YOB FE" "Spouse Age" "Observations") fmt(%7.0fc)) mgroups("Dependent variable: Spousal income, 1999 USD", span prefix(\multicolumn{@span}{c}{) suffix(})) replace
	
