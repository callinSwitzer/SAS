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
RUN; 

/* HERE ARE THE QUESETIONS FOR ANALYSIS
I. Are bees' buzz frequencies associated with variables 
temp, time of day, humidity, or bee size?
	1. Multiple regression to see if buzz freq is correlated with 
	any of the environmental variables.
		a. Make sure to use the average buzz freq for each bee
		b. Calculate the avg buzz freq BY beeNum
II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant

III. Do bees' buzz frequencies change over time?
	1. Not quite sure how to analyze this. */

/* create new dataset that is just the average of each bee's buzzes*/
DATA AVGBEE;
	SET CLEANBUZZ (KEEP= BEENUM ABSBUZZFREQ);
	AvgBuzzFreq = absbuzzfreq*1; /* CONVERT TO NUMERIC*/
	BEEN = BEENUM*1;
	DROP ABSBUZZFREQ BEENUM;
RUN; 

/* SORT*/
PROC SORT DATA = AVGBEE;
	BY BEEN;
RUN; 

/* CALCULATE MEAN BUZZ FREQ BY BEE*/
PROC MEANS DATA = AVGBEE;
	CLASS BEEN;
	VAR AVGBUZZFREQ;
	OUTPUT OUT = BEE;
RUN;

DATA BEE1;
	SET BEE (KEEP = AVGBUZZFREQ BEEN _STAT_);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
RUN;

/* merge avg by bee and ...
