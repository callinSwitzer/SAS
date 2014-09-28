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

*;
PROC CONTENTS; 
RUN;
*;

/* HERE ARE THE QUESETIONS FOR ANALYSIS
I. Are bees' buzz frequencies associated with variables 
temp, time of day, humidity?
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
	BEEN = BEENUM*1; 	/* Convert to numeric -- just another name for bee number */
	TEMP1 = TEMP*1; 	/* CONVERT TO NUMERIC*/
	HUM1 = HUM*1; 		/* CONVERT TO NUMERIC*/
	IT1 = IT*1; 		/* CONVERT TO NUMERIC*/
	/* drop unused variables */
	DROP AvgBUZZFREQ BEENUM TEMP HUM NOTES RecordingNAMES IT tag_description;
RUN;

/* sort data set */
PROC SORT DATA = AVGBEE;
	BY BEEN DateTime;
RUN; 

*;
proc contents varnum;
run;
*; 

/* MULTIPLE REGRESSION */

/* get only first observation of each bee for multiple regression
   and look at only the bees that are pollinating on tomatoes */
DATA first;
	SET avgbee;
	by been;
	if first.been;
	IF plant ~= "tomato" THEN DELETE;
	Drop absbuzzfreq recapture heldatconstdist channelrecorded;
RUN;
/* RUN MULTIPLE REGRESSION ON first encounter of bee */
ODS HTML PATH="C:\Users\cswitzer\Desktop\TEMP" BODY="reg.html";
PROC REG DATA = FIRST;
	TITLE "Multiple regression to determine what affects buzz freq";
	MODEL avgBuzzFreq1 = TEMP1 HUM1 / vif; /* look at variance inflation factor */
	/* when vif is high, that's problematic */
RUN;
QUIT;

*;
PROC REG DATA = FIRST;
	TITLE "look at temp vs humidity";
	MODEL TEMP1= HUM1;
RUN;
QUIT;
*;

*;
proc sgscatter data=first;
  title "Scatterplot Matrix for bees";
  matrix aVGbuzzfreq1 temp1 hum1 it1 / DIAGONAL = (HISTOGRAM KERNEL NORMAL);
run;
*;


/* MAKE SOME SCATTERPLOTS */
PROC SGSCATTER DATA = FIRST;
	PLOT AVGBUZZFREQ1*TEMP1 /  reg = (degree = 1 clm);
	TITLE1 "AVERAGE BUZZ FREQUENCY VS TEMP"; 
	FORMAT TEMP1 F8.2;
	LABEL TEMP1 = "Temperature (deg C)" 
			AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN;

*;
proc contents;
run;
*;
 
/*III. Do bees' buzz frequencies change over time?
/* get only bees that have multiple recordings */

DATA repSamples;
  SET avgbee ;
  BY been location;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  IF ~(first.been and last.been) THEN OUTPUT repSamples ;
RUN;

/* AVERAGE RESAMPLES BY DATE */
/* SORT*/
PROC SORT DATA = repsamples;
	BY been dateTime;

/* CALCULATE MEAN BUZZ FREQ BY BEE AND DATE and plant*/
PROC MEANS DATA = avgbee;
	CLASS been dateTime plant;
	VAR avgbuzzfreq1;
	OUTPUT OUT = bee;
RUN;

/* clean up data */
DATA bee1;
	SET bee (KEEP = avgbuzzfreq1 been _STAT_ plant datetime);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF been = "." THEN DELETE;
	IF plant = " " THEN DELETE;
	IF datetime = "." THEN DELETE; 
RUN;

*;
PROC MEANS DATA = bee1 MEAN;
	CLASS datetime been;
	VAR avgbuzzfreq1;
	OUTPUT OUT = bbbb;
RUN; 
*;



/* CALCULATE MEAN BUZZ FREQ BY BEE AND DATE*/
PROC MEANS DATA = avgbee;
	CLASS been datetime;
	VAR avgbuzzfreq1 hum1 temp1;
	OUTPUT OUT = bee;
RUN;

/* clean up data set */
DATA bee1;
	SET bee (KEEP = avgbuzzfreq1 been _STAT_ datetime temp1 hum1);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF been = "." THEN DELETE;
	IF datetime = "." THEN DELETE; 
RUN;
/* THIS IS GREAT. NOW WE HAVE EACH INDIVIDUAL'S BUZZ FREQUENCY BY DATE*/
/* also, avg temp and hum by date */

/* GET DUPLICATES OF BEES */
DATA bee1dups;
  SET bee1 ;
  BY been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  IF ~(first.been and last.been) THEN OUTPUT bee1dups ;
RUN;

/* CREATE A COUNT VARIABLE TO KEEP TRACK OF DAY NUMBER -- RIGHT NOW, THESE ARE JUST COUNTS */
PROC SORT DATA = bee1dups;
  BY been;
RUN;



DATA beeDate;
	SET bee1dups;
	BY been;
	IF first.been THEN firstDate = 1;
	ELSE firstDate = 0;
RUN; 

/* THIS GETS THE DATE DIFFERENCES BETWEEN OBSERVATIONS */
DATA beedate1;
	SET beedate;
	BY been;
	RETAIN OLD_DATETIME; 
	IF firstDate = 1 THEN OLD_DATETIME = datetime;
	F_DATE = OLD_DATETIME;
	FORMAT F_DATE MMDDYY10.;
	DATE_DIFF = datetime - F_DATE; 
PROC PRINT; 
RUN;


DATA bee1dups;
  SET bee1 ;
  BY been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  IF ~(first.been and last.been) THEN OUTPUT bee1dups ;

DATA bee1dups;
  SET bee1dups;
  count + 1;
  BY been;
  IF first.BEEN THEN count = 1;
  /* if count = 3, then delete -- so I can do pairwise testing */
  IF count = 3 THEN DELETE; 
PROC PRINT;
	TITLE "dataset for pairwise assessment"; 
RUN;


/* NOW PLOT IT */
PROC SGSCATTER DATA = beedate1;
	PLOT avgbuzzfreq1*DATE_DIFF / GROUP = been reg = (degree = 1 clm);
	TITLE1 "Average buzz frequency over time"; 
	LABEL DATE_DIFF = "DAY" 
			been = "Bee Number"
			avgbuzzfreq1 = "Average buzz frequency (Hz)";
RUN;

/* this looks a little weird, and I think it will be very difficult
to analyze, so I will analyze with count, rather than date */

PROC PRINT DATA = beedate1; 
RUN; 

*;
/* DO MULTIPLE REGRESSION -- this doesn't really make sense, b/c of the outliers */
PROC REG DATA = BEEDATE1; 
	TITLE "MULTIPLE REGRESSION FOR RECAPTURES";
	MODEL avgbuzzfreq1  = date_diff; 
RUN;
QUIT;
*;

*;
/* multiple regression with count -- also doesn't make sense, since their paired*/
PROC REG DATA = bee1dups; 
	TITLE "MULTIPLE REGRESSION FOR RECAPTURES";
	MODEL avgbuzzfreq1  = count; 
RUN;
QUIT;
*;



/* a mixed effects model will help analyze paired data, while accounting for differences
in humidity and temperature */
PROC MIXED DATA=bee1dups METHOD=ml; /* maximum likelihood method for estimating covariance parameters */
	TITLE "Mixed linear model for bees";
	CLASS been;
	MODEL avgbuzzfreq1 =  temp1 hum1 count; /*these are the fixed effects in the model */
	RANDOM  been; /* This is identifying bee number as a random effect in the model*/
run;

*;
/* do same for just count -- should be same as paired ttest */
proc mixed data=bee1dups method=ml;
	title "Mixed linear model for bees";
	class been;
	model avgbuzzfreq1 = count;
	random  been;
run;
*;


*;
/* transpose for a ttest-- just to check results of mixed model */
PROC TRANSPOSE DATA = bee1dups OUT = pairT; 
	TITLE "ttest setup";
	VAR avgbuzzfreq1; 
    BY been;
data pairT; 
	SET  pairT;
	DROP _NAME_; 
	LABEL col1 = "Obs 1" col2 = "Obs 2"; 
PROC TTEST DATA = pairt; 
	PAIRED COL1 * COL2; 
RUN; 
*;

/* LOOK AT THE POSSIBLE ODS STYLES
proc template;
  path sashelp.tmplmst;
  list styles;
run;
*/

/* scatterplot of data */
PROC SGPLOT DATA = bee1dups NOAUTOLEGEND;
	SCATTER	X=count Y= avgbuzzfreq1;
	SERIES X = count Y = avgbuzzfreq1 / group = been; 
	XAXIS MIN = 0.9 MAX = 2.1 INTEGER;
	TITLE1 "Average buzz frequency over time"; 
	LABEL count = "Observation number" 
			been = "Bee Number"
			avgbuzzfreq1 = "Average buzz frequency (Hz)";
RUN;


/*
II. Do bees' buzz frequencies change when they pollinate different
plants?
	1. Start by plotting avg buzz freq by plant (with individual 
	bees' buzzes averaged for each plant.
	2. Plot individual bees' buzz frequency for each plant */





/* get avg buzz freq for bees that have buzzed on more than one type of plant */
DATA avgbee1; 
	SET avgbee;
	IF location ~= "greenhouse" THEN DELETE;  
PROC MEANS DATA = avgbee1;
	CLASS been plant;
	VAR avgbuzzfreq1 hum1 temp1;
	OUTPUT OUT = bee2;
RUN;

DATA bee2;
	SET bee2 (KEEP = avgbuzzfreq1 been _STAT_ temp1 hum1 plant);
	IF _STAT_ ^= "MEAN" THEN DELETE; 
	DROP _STAT_;
	IF been = "." THEN DELETE;
	IF plant = " " THEN DELETE; 
PROC PRINT; 
RUN;
/* NOW WE HAVE EACH INDIVIDUAL'S BUZZ FREQUENCY BY PLANT*/
/* also, avg temp and hum by PLANT */

/* GET DUPLICATES OF BEES -- I ONLY BEES THAT VISITED MORE THAN ONE PLANT */
DATA bee12dups;
  SET bee2 ;
  BY been;
  /* if the bee number is in the dataset more than once, ouput to repSamples */
  IF ~(first.been and last.been) then output bee12dups;
PROC PRINT;
RUN;
/* I'm not going to use the humidity and temp in this analysis, but I will use it in the future! */


/* SCATTERPLOT WITH LINES CONNECTING INDIVIDUALS */
PROC SGPLOT DATA = bee12dups NOAUTOLEGEND;
	SCATTER x = plant y=avgbuzzfreq1;
	Series x= plant y = avgbuzzfreq1 / GROUP = BEEN;
	TITLE1 "AVERAGE BUZZ FREQUENCY VS PLANT"; 
	LABEL AVGBUZZFREQ1 = "Average buzz frequency (Hz)";
RUN;
/* THIS LOOKS OKAY, BUT IT WOULD LOOK BETTER IF SUBTRACTED EACH BEE'S AVERAGE */

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

/* rename plants to get a nice graph */;
data bpa;
	set beeplant;
	if plant = "affine" then plantNum = 1;
	else if plant = "carolinense" then plantNum = 2 ;
	else if plant = 'dulcamara' then plantNum = 3 ;
	else plantNum = '.' ;

	/* RENAME PLANTS */
	if plant = "affine" THEN name = "Persian Violet";
	else if plant = "carolinense" then name = "Horsenettle";
	else if plant = 'dulcamara' then name = "Nightshade";
	else name = "Jalapeño";
proc print; 
run; 

/* make a nice graph */
PROC SGPLOT DATA = bpa NOAUTOLEGEND;
	SCATTER x = name y=BUZZ_DIFF;
	Series x= name y = BUZZ_DIFF / GROUP = BEEN;
	REFLINE 0 / TRANSPARENCY = 0.5 LABEL = ('Average for each bee');
	TITLE 'Average buzz frequency by plant for three different bees'; 
 	LABEL 	been = "Bee Number"
			BUZZ_DIFF = "Average buzz frequency difference (Hz)"
			name = "Common plant name";
RUN;

/* nested anova -- finds significant difference between groups --
maybe not valid b/c of small sample size 
also, it doesn't take temp or humidity into account*/

/* first convert beenum to character */
/*
data beeplant1;
	set beeplant;
	Bee = STRIP(PUT(been, 8.));
run;
*/

/* get rid of jalapeno, since I have only one observation */
DATA beeplant2;
	SET beeplant;
	IF plant = "jalapeno" THEN DELETE;
PROC PRINT;
RUN;

/* One way to do anova 
PROC GLM DATA=beeplant1;
       CLASS bee plant;
       MODEL avgbuzzfreq1 = bee plant;
       *MEANS plant/TUKEY;
             TITLE 'Repeated Measures ANOVA on buzzes on different plants';
RUN;
*/

/* this is the right way, if wer didn't have repeated measures -- this assumes been and plant are independent */
PROC anova DATA=beeplant2;
       CLASS been plant;
       MODEL buzz_diff = been plant;
       MEANS plant/snk; /* Student-Newman-Keuls Test to find differences among groups */
             TITLE 'Repeated Measures ANOVA on buzzes on different plants';
RUN;

/* CLEANUP */
DATA bb;
	SET beeplant;
	DROP av hum1 temp1 firstplant buzz_diff bee;
	TITLE "Cleaned up data -- bb"
PROC PRINT;
RUN;

/* get data in correct form for repeated measures anova --
transpose to wide format and clean it upa a bit*/
PROC TRANSPOSE DATA = beeplant OUT = bpt; 
	TITLE "Wide format for repreated measures ANOVA";
	VAR avgbuzzfreq1; 
	ID plant;
	BY been;
DATA bpt; 
	SET  bpt;
	DROP _NAME_; 
PROC PRINT;
RUN;

/* now repeated measures anova -- this is the correct way to analyze this data
Assuming: there is no strong effect of temp humidity or time (those variables are left out)
Also future work will need larger sample sizes.
*/
PROC ANOVA DATA = bpt;
	TITLE "One-way Anova, using repeated measures";
	MODEL AFFINE CAROLINENSE DULCAMARA = / NOUNI;
	REPEATED buzz 3 (1 2 3 );
RUN; 

/* This is correct */

/* recode plant to be a number */

data bp3;
	set beeplant;
	if plant = "affine" then plantNum = 1;
	else if plant = "carolinense" then plantNum = 2 ;
	else if plant = 'dulcamara' then plantNum = 3 ;
	else plantNum = '.' ;

	/* RENAME PLANTS */
	if plant = "affine" THEN name = "Persian Violet";
	else if plant = "carolinense" then name = "Horsenettle";
	else if plant = 'dulcamara' then name = "Nightshade";
	else name = "Jalapeño";
proc print; 
run; 

/* now do anova -- this is not a repeated measures anova*/
proc anova data = bp3;
	class been name;
	model avgBuzzfreq1 = been name;
	means NAME / snk;
run;

/* boxplots */
proc sort data = bp3;
	by name;
run;


PROC SGPLOT DATA = bp3;
	VBOX avgbuzzfreq1 / CATEGORY=name GROUPORDER= data;
 	TITLE 'Average buzz frequency by plant for three different bees'; 
 	LABEL 	name = "Plant Name"
			avgbuzzfreq1 = "Average buzz frequency(Hz)"; 
RUN; 

* connect the dots with lines;
PROC SGPLOT DATA = bp3 NOAUTOLEGEND; /* puts no legend in the plot */
	SERIES X = name Y = BUZZ_DIFF / GROUP = been; 
	SCATTER X = name Y = BUZZ_DIFF / GROUP= been; 
 	REFLINE 0 / TRANSPARENCY = 0.5 
 	LABEL = ('Average for each bee'); 
 	TITLE 'Average buzz frequency by plant for three different bees'; 
 	LABEL 	been = "Bee Number"
			BUZZ_DIFF = "Average buzz frequency difference (Hz)"; 
RUN; 
/* repeated measures anova == correct  */


/* This is the same as above 
proc print data = bpt;
run; 

proc anova data = bpT;
	model affine carolinense dulcamara  = /nouni;
	repeated buzz 3 (1 2 3);
run; 
*/
