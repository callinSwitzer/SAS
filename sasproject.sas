/********************************************************
|
| Callin Switzer
|
| Final SAS Project
|
| 9/24/2014
*********************************************************/

/* import data */
PROC IMPORT OUT= WORK.buzz 
            DATAFILE= "C:\Users\cswitzer\Desktop\Buzzes2_2014_09_26Final
.xlsx" 
            DBMS=EXCELCS REPLACE;
     RANGE="Buzzes2_2014_09_26Final$"; 
     SCANTEXT=YES;
     USEDATE=YES;
     SCANTIME=YES;
RUN;

/* DROP ROWS WHERE TEMP = NA */
DATA buzz;
	SET BUZZ;
	IF AvgBUZZFREQ = "NA" THEN DELETE;
	/* convert get date only */
	FORMAT DATE MMDDYY10.;
RUN; 

PROC CONTENTS; 
RUN;

/* HERE ARE THE QUESETIONS FOR ANALYSIS
I. Are bees' buzz frequencies associated with variables 
temp, time of day, humidity, or bee size?
	1. Multiple regression to see if buzz freq is correlated with 
	any of the environmental variables.
		a. Make sure to first buzz freq for each bee
II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant

III. Do bees' buzz frequencies change over time?
	1. Not quite sure how to analyze this. */

/* create new dataset has numeric, rather than character values*/
DATA AVGBEE;
	SET BUZZ;
	AvgBuzzFreq1 = avgbuzzfreq*1; /* CONVERT TO NUMERIC*/
	BEEN = BEENUM*1;
	TEMP1 = TEMP*1;
	HUM1 = HUM*1; 
	IT1 = IT*1; 
	DROP AvgBUZZFREQ BEENUM TEMP HUM NOTES RecordingNAMES IT tag_description;
RUN;
PROC SORT DATA = AVGBEE;
	BY BEEN DateTime;
RUN; 


proc contents varnum;
run;

/* MULTIPLE REGRESSION */

/* get only first observation of each bee for multiple regression
   and look at only the bees that are pollinating on tomatoes */
DATA first;
	set avgbee;
	by been;
	if first.been;
	IF plant ~= "tomato" THEN DELETE;
	Drop absbuzzfreq recapture heldatconstdist channelrecorded;
run;
/* RUN MULTIPLE REGRESSION ON first encounter of bee */
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regrr.html";
PROC REG DATA = FIRST;
	TITLE "Multiple regression to determine what affects buzz freq";
	MODEL avgBuzzFreq1 = TEMP1 HUM1 / vif;
RUN;
QUIT;

PROC REG DATA = FIRST;
	TITLE "look at temp vs humidity";
	MODEL TEMP1= HUM1;
RUN;
QUIT;
ODS HTML CLOSE;

ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regrr.html";
proc sgscatter data=first;
  title "Scatterplot Matrix for bees";
  matrix aVGbuzzfreq1 temp1 hum1 it1 / DIAGONAL = (HISTOGRAM KERNEL NORMAL);
run;
ODS HTML CLOSE; 


/* MAKE SOME SCATTERPLOTS */
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regr.html";
PROC SGSCATTER DATA = FIRST;
	PLOT AVGBUZZFREQ1*TEMP1 /  reg = (degree = 1 clm);
	TITLE1 "AVERAGE BUZZ FREQUENCY VS TEMP"; 
	FORMAT TEMP1 F8.2;
	LABEL TEMP1 = "Temperature (deg C)" 
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN;
ODS HTML CLOSE;

/*II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant*/

/* get only bees that have multiple recordings */

data repSamples;
  set avgbee ;
  by been LOCATION;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  if ~(first.been and last.been) then output repSamples ;
run;

/* AVERAGE RESAMPLES BY DATE */
/* SORT*/
PROC SORT DATA = RESAMPLES;
	BY BEEN DATETIME;

/* CALCULATE MEAN BUZZ FREQ BY BEE AND DATE and plant*/
PROC MEANS DATA = AVGBEE;
	CLASS BEEN DATETIME PLANT;
	VAR AVGBUZZFREQ1 ;
	OUTPUT OUT = BEE;
RUN;

DATA BEE1;
	SET BEE (KEEP = AVGBUZZFREQ1 BEEN _STAT_ plant DATETIME);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
	IF PLANT = " " THEN DELETE;
	IF DATETIME = "." THEN DELETE; 
RUN;


PROC MEANS DATA = BEE1 MEAN;
	CLASS DATETIME BEEN;
	VAR AVGBUZZFREQ1;
	OUTPUT OUT = bbbb;
RUN; 




/* CALCULATE MEAN BUZZ FREQ BY BEE AND DATE*/
PROC MEANS DATA = AVGBEE;
	CLASS BEEN DATETIME;
	VAR AVGBUZZFREQ1 ;
	OUTPUT OUT = BEE;
RUN;

DATA BEE1;
	SET BEE (KEEP = AVGBUZZFREQ1 BEEN _STAT_ DATETIME);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
	IF DATETIME = "." THEN DELETE; 
RUN;
/* THIS IS GREAT. NOW WE HAVE EACH INDIVIDUAL'S BUZZ FREQUENCY BY DATE*/
/* MAYBE I SHOULD GET TEMP AND HUMIDITY BY DATE, TOO */

/* GET DUPLICATES OF BEES */
data BEE1DUPS;
  set BEE1 ;
  by been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  if ~(first.been and last.been) then output BEE1DUPS ;
run;

/* CREATE A COUNT VARIABLE TO KEEP TRACK OF DAY NUMBER -- RIGHT NOW, THESE ARE JUST COUNTS */
proc sort data = BEE1DUPS;
  by BEEN;
run;

data BEE1DUPS;
  set BEE1DUPS;
  count + 1;
  by BEEN;
  if first.BEEN then count = 1;
run;

/* NOW PLOT IT */

ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regr.html";
/* scatterplot of data */
PROC SGSCATTER DATA = BEE1DUPS;
	PLOT AVGBUZZFREQ1*COUNT / GROUP = BEEN reg = (degree = 1 clm);
	TITLE1 "AVERAGE BUZZ FREQUENCY TIME"; 
	LABEL COUNT = "DAY" 
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN; 
ODS HTML CLOSE; 
























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
	SET BEE (KEEP = AVGBUZZFREQ1 BEEN _STAT_ plant DATETIME);
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
