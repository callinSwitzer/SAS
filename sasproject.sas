/********************************************************
|
| Callin Switzer
|
| Final SAS Project
|
| 9/24/2014
*********************************************************/

/* import data */
PROC IMPORT DATAFILE = "C:\USERS\CSWITZER\DESKTOP\Buzzes_2014_08_29.csv"
	OUT = BUZZ
	DBMS = CSV
	REPLACE; 
	GETNAMES = YES;
RUN; 


/* DROP ROWS WHERE TEMP = NA */
DATA CLEANBUZZ;
	SET BUZZ;
	IF ABSBUZZFREQ = "NA" THEN DELETE;
	/* convert get date only */
	date1 = DATEPART(datetIME); 
	FORMAT DATE1 MMDDYY10.;
RUN; 

PROC CONTENTS; 
RUN;

/* HERE ARE THE QUESETIONS FOR ANALYSIS
I. Are bees' buzz frequencies associated with variables 
temp, time of day, humidity, or bee size?
	1. Multiple regression to see if buzz freq is correlated with 
	any of the environmental variables.
		a. Make sure to first buzz freq for each bee
		b. Calculate the avg buzz freq BY beeNum
II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant

III. Do bees' buzz frequencies change over time?
	1. Not quite sure how to analyze this. */

/* create new dataset has numeric, rather than character values*/
DATA AVGBEE;
	SET CLEANBUZZ;
	AvgBuzzFreq = absbuzzfreq*1; /* CONVERT TO NUMERIC*/
	BEEN = BEENUM*1;
	TEMP1 = TEMP*1;
	HUM1 = HUM*1; 
	DROP ABSBUZZFREQ BEENUM TEMP HUM;
RUN;

/* MULTIPLE REGRESSION */

/* get only first observation of each bee for multiple regression */
PROC SORT DATA = AVGBEE;
	BY BEEN;
RUN; 

 data nodups;
   set avgBee;
   by been;
   if first.BEEN then output nodups;
  run;

*/ RUN MULTIPLE REGRESSION ON nodups */


/* SORT*/
PROC SORT DATA = AVGBEE;
	BY BEEN DATE1;
RUN; 

/* CALCULATE MEAN BUZZ FREQ BY BEE AND DATE and plant*/
PROC MEANS DATA = AVGBEE;
	CLASS BEEN DATE1 PLANT;
	VAR AVGBUZZFREQ ;
	OUTPUT OUT = BEE;
RUN;

/* get first recording of each bee */
DATA BEE1;
	SET BEE (KEEP = AVGBUZZFREQ BEEN _STAT_ plant);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
	IF PLANT = " " THEN DELETE;
RUN;

 /* get rid of duplicates */
proc sort data=bee1 nodup out=want1;
by been;
quit; 

/* plot;


/* merge avg by bee and ...

/* THIS COULD BE HANDY FOR SORTING -- FROM HW0.SAS */
/*Solution using PROC SQL*/

PROC SQL;
 CREATE TABLE candy_choose AS
 SELECT * 
 FROM myplace.candy
 GROUP BY brand
 HAVING COUNT(brand)>2;
QUIT;

/*the asterick means that we select all the variables*/

/*how do we obtain the brand frequencies (as done for both PROC FREQ & PROC MEANS)?*/

PROC SQL;
 CREATE TABLE numbers AS
 SELECT brand, COUNT(brand) AS brand_count
 FROM myplace.candy
 GROUP BY brand;
QUIT;

