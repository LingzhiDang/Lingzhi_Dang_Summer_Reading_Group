libname source "\\casd.fr\casdfs\Projets\SALMATL\Data\DADS_Panel tous salariés_2015";

* in order to allow the stata CASD to open large datasets;
* we drop annex jobs and jobs in the public sector;
* we make a selection of relevant variables;
*proc freq data=test; *table an; *run;


data test_pre2009; set source.Pan15; 
where FILTRE EQ "1" and PTT EQ "0" and AN <2007 and CATJUR NE "5498" and 
( substr(CATJUR,1,1)='2' OR substr(CATJUR,1,1)='3' OR substr(CATJUR,1,1)='5' 
OR substr(CATJUR,1,1)='6' OR substr(CATJUR,1,1)='8' OR substr(CATJUR,1,1)='9'); run; 


data test_pre2009; set test_pre2009;
	keep an NNINOUV DOMEMPL
	age annai sx cs1 cs2 cs1_anc cs2_anc PCS4 PCS_v2
	 nbheur CE CE_RED ADMIN DP ENTPAN ENTSIR SB SBR 
	comR comT depR depT regN regR regT
	domempl sir sirfict NIC4
	A38 APE40 APEN APEN2 APET APET2
	NES5 NES36 NES36N
	st catjur;
run;

PROC EXPORT DATA= test_pre2009
            OUTFILE= "C:\Users\Public\Documents\resW\data\Paneldads_pre2009.dta" 
            DBMS=STATA REPLACE;
RUN;


data test_post2009; set source.Pan15; 
where FILTRE EQ "1" and PTT EQ "0" and AN >2006 and CATJUR NE "5498" and 
( substr(CATJUR,1,1)='2' OR substr(CATJUR,1,1)='3' OR substr(CATJUR,1,1)='5' 
OR substr(CATJUR,1,1)='6' OR substr(CATJUR,1,1)='8' OR substr(CATJUR,1,1)='9'); run; 

data test_post2009; set test_post2009;
	keep an NNINOUV DOMEMPL
	age annai sx cs1 cs2 cs1_anc cs2_anc PCS4 PCS_v2
	 nbheur CE CE_RED ADMIN DP ENTPAN ENTSIR SB SBR 
	comR comT depR depT regN regR regT
	domempl sir sirfict NIC4
	A38 APE40 APEN APEN2 APET APET2
	NES5 NES36 NES36N
	st catjur;
run;

PROC EXPORT DATA= test_post2009
            OUTFILE= "C:\Users\Public\Documents\resW\data\Paneldads_post2009.dta" 
            DBMS=STATA REPLACE;
RUN;
