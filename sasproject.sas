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

proc contents;
run; 
/*III. Do bees' buzz frequencies change over time?
	1. Not quite sure how to analyze this. 
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
	VAR AVGBUZZFREQ1 HUM1 TEMP1;
	OUTPUT OUT = BEE;
RUN;

DATA BEE1;
	SET BEE (KEEP = AVGBUZZFREQ1 BEEN _STAT_ DATETIME TEMP1 HUM1);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
	IF DATETIME = "." THEN DELETE; 
RUN;
/* THIS IS GREAT. NOW WE HAVE EACH INDIVIDUAL'S BUZZ FREQUENCY BY DATE*/
/* also, avg temp and hum by date */

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


*;
DATA beeDate;
	set bee1dups;
	by been;
	if first.been then firstDate = 1;
	else firstDate = 0;
run; 

/* THIS GETS THE DATE DIFFERENCES BETWEEN OBSERVATIONS */
DATA BEEDATE1;
	SET BEEDATE;
	BY BEEN;
	RETAIN OLD_DATETIME; 
	IF FIRSTDATE = 1 THEN OLD_DATETIME = DATETIME;
	F_DATE = OLD_DATETIME;
	FORMAT F_DATE MMDDYY10.;
	DATE_DIFF = DATETIME - F_DATE; 
PROC PRINT; 
RUN;


data BEE1DUPS;
  set BEE1 ;
  by been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  if ~(first.been and last.been) then output BEE1DUPS ;

data BEE1DUPS;
  set BEE1DUPS;
  count + 1;
  by BEEN;
  if first.BEEN then count = 1;
  /* if count = 3, then delete -- so I can do pairwise testing */
  if count = 3 then delete; 
proc print;
	title "bee1dups"; 
run;


/* NOW PLOT IT */
ODS RTF STYLE = FESTIVAL; 
PROC SGSCATTER DATA = BEEDATE1;
	PLOT AVGBUZZFREQ1*DATE_DIFF / GROUP = BEEN reg = (degree = 1 clm);
	TITLE1 "AVERAGE BUZZ FREQUENCY TIME"; 
	LABEL DATE_DIFF = "DAY" 
			BEEn = "Bee Number"
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN;

PROC PRINT DATA = BEEDATE1; 
RUN; 

/* DO MULTIPLE REGRESSION -- this doesn't really make sense, b/c of the outliers */
PROC REG DATA = BEEDATE1; 
	TITLE "MULTIPLE REGRESSION FOR RECAPTURES";
	MODEL avgbuzzfreq1  = date_diff; 
RUN;
QUIT;

/* multiple regression with count -- also doesn't make sense, since their paired*/
PROC REG DATA = bee1dups; 
	TITLE "MULTIPLE REGRESSION FOR RECAPTURES";
	MODEL avgbuzzfreq1  = count; 
RUN;
QUIT;
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regr.html";
proc mixed data=bee1dups method=ml;
	title "Mixed linear model for bees";
	class been;
	model avgbuzzfreq1 =  temp1 hum1 count;
	random  been;
run;
ods close; 

/* do same for just count -- should be same as paired ttest */
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regr.html";
proc mixed data=bee1dups method=ml;
	title "Mixed linear model for bees";
	class been;
	model avgbuzzfreq1 = count;
	random  been;
run;
ods close; 

ods graphics on;
   
   proc ttest data = bee1dups;
      paired SBPbefore*SBPafter;
   run;

/* transpose for a ttest-- just to check results of mixed model */
proc transpose data = bee1dups out = pairT; 
	title "ttest setup";
	var avgbuzzfreq1; 
    by been;
data pairT; 
	set  pairT;
	drop _NAME_; 
	label col1 = "Obs 1" col2 = "Obs 2"; 
proc print; 
run ;

proc ttest data = pairt; 
	paired COL1 * COL2; 
run; 

proc glm data=bee1dups;
  class count;
  model avgbuzzfreq1 = temp1 hum1 count;
  repeated count 2 / printe;
run;
quit;
ods html close; 

/* LOOK AT THE POSSIBLE ODS STYLES
proc template;
  path sashelp.tmplmst;
  list styles;
run;
*/






/*
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="regr.html";
/* scatterplot of data */
PROC SGSCATTER DATA = BEE1DUPS;
	PLOT AVGBUZZFREQ1*COUNT / GROUP = BEEN reg = (degree = 1 clm);
	TITLE1 "AVERAGE BUZZ FREQUENCY TIME"; 
	LABEL COUNT = "DAY" 
			been = "Bee Number"
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN; 
ODS HTML CLOSE; 



/*
II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant */





/* get avg buzz freq for bees that have buzzed on more than one type of plant */
data avgbee1; 
	set avgbee;
	if location ~= "greenhouse" then delete;  

PROC MEANS DATA = AVGBEE1;
	CLASS BEEN plant;
	VAR AVGBUZZFREQ1 HUM1 TEMP1;
	OUTPUT OUT = BEE2;
RUN;

DATA BEE2;
	SET BEE2 (KEEP = AVGBUZZFREQ1 BEEN _STAT_ TEMP1 HUM1 PLANT);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF BEEN = "." THEN DELETE;
	IF PLANT = " " THEN DELETE; 
PROC PRINT; 
RUN;
/* THIS IS GREAT. NOW WE HAVE EACH INDIVIDUAL'S BUZZ FREQUENCY BY PLANT*/
/* also, avg temp and hum by PLANT */

/* GET DUPLICATES OF BEES -- I ONLY BEES THAT VISITED MORE THAN ONE PLANT */
data BEE12DUPS;
  set BEE2 ;
  by been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  if ~(first.been and last.been) then output BEE12DUPS ;
PROC PRINT;

run;


/* SCATTERPLOT WITH LINES CONNECTING INDIVIDUALS */
PROC SGSCATTER DATA = BEE12DUPS;
	PLOT AVGBUZZFREQ1*PLANT;
	TITLE1 "AVERAGE BUZZ FREQUENCY VS PLANT"; 
	LABEL AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN;

PROC SGSCATTER DATA = BEE12DUPS;
	PLOT AVGBUZZFREQ1*PLANT / GROUP = BEEN;
	TITLE1 "AVERAGE BUZZ FREQUENCY TIME"; 
	LABEL 	been = "Bee Number"
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN; 
/* THIS LOOKS OKAY, BUT IT WOULD LOOK BETTER IF WE PLOTTED AFFINE AS A REFERENCE PLANT */

/* MAKE A REFERENCE PLANT, AND PLOT DIFFERENCES*/
PROC SORT DATA = BEE12DUPS;
	BY BEEN PLANT;
PROC PRINT; 
RUN; 

DATA BEE12DUPS;
	set bee12dups;
	by been;
	if first.been then firstPLANT = 1;
	else firstPLANT = 0;
PROC PRINT; 
run; 

/* get average by bee, for comparison */
proc means data = bee12dups; 
	output out = bea;
	class been;
run; 

data bea1;
	set bea;
	if been = "." then delete;
	if _STAT_ ~= "MEAN" then delete;
	drop _type_ _freq_ _stat_ firstPlant hum1 temp1;
	av = avgbuzzfreq1;
proc print; 
run; 

/*merge the averages back into the dataset */
DATA beerepavg; 
  MERGE bea1 bee12dups; 
  BY been; 
proc print; 
RUN; 

/* THIS GETS THE differences between plant observations */
DATA BEEPLANT;
	SET beerepavg;
	BUZZ_DIFF = AVGBUZZFREQ1 - av; 
PROC PRINT; 
RUN;

PROC SGSCATTER DATA = BEEPLANT;
	PLOT BUZZ_DIFF*PLANT / GROUP = BEEN;
	TITLE1 "AVERAGE BUZZ FREQUENCY TIME"; 
	LABEL 	been = "Bee Number"
			BUZZ_DIFF = "Average buzz frequency difference (Hz)"; 
RUN; 

PROC SGPLOT DATA = BEEPLANT; 
	series X = PLANT Y = BUZZ_DIFF/ GROUP = BEEN; 
	scatter X = PLANT Y = BUZZ_DIFF/ GROUP = BEEN; 
 	REFLINE 0 / TRANSPARENCY = 0.5 
 	LABEL = ('Exacume affine'); 
 	TITLE 'Average buzz frequency by plant for three different bees'; 
 	LABEL 	been = "Bee Number"
			BUZZ_DIFF = "Average buzz frequency difference (Hz)"; 
RUN; 





























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
