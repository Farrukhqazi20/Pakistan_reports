 ****************************************************************
*Hemoglobin and Screening Code for ReMAPP Study
*Last Updated: 02/07/2022 ALB
*Users: 
****************************************************************

cd "C:\Farrukh_data\Anemia\data" //UPDATE BY USER
****************************************************************
*Part 1: Compiling Final Dataset - Maternal
*Merging all forms into single dataset 

cd "C:\Farrukh_data\Anemia\data"

	use mnh01_pID, clear 
	
	merge m:1 SUBJID using mnh02 
		ren _merge mer02
        
	
	merge m:1 PREGNANCY_ID using mnh03a_pID 
	    ren _merge mer03a 
		
	merge m:1 PREGNANCY_ID using mnh03b_pID 
		ren _merge mer3b
		
	merge m:1 PREGNANCY_ID using mnh04_pID
		ren _merge mer04
		
	merge m:1 PREGNANCY_ID using mnh05_pID 
		ren _merge mer05
		
	merge m:1 PREGNANCY_ID using mnh06_pID 
	     ren _merge mer06 
		 
	merge m:1 PREGNANCY_ID using mnh07_pID 
		ren _merge mer07
		
	merge m:1 PREGNANCY_ID using mnh08_pID 
		ren _merge mer08
	
	*merge 1:1 CASEID using `mnh11' 
	*	drop _merge
		
	*merge 1:1 CASEID using `mnh13' 
	*	drop _merge
		
	*merge 1:1 CASEID using `mnh14' 
	*	drop _merge
		
	*merge 1:1 CASEID using `mnh17' 
	*	drop _merge
		
	*merge 1:1 CASEID using `mnh18' 
	*	drop _merge
		
	*merge 1:1 CASEID using `mnh25' 
	*	drop _merge

*************************************************
*Part 2: Data Cleaning
*************************************************

***************dropping the IDs who did not fill consent

keep if M01_CON_YN_DSDECOD== 1

duplicates report SUBJID
duplicates report PREGNANCY_ID


* fixing M07_CBC_HB_LBORRES2

*******i have locked this command because we have already this variable in numeric

*replace M07_CBC_HB_LBORRES2=" " if (M07_CBC_HB_LBORRES2=="NEGATIVE ")
lab def M07_CBC_HB_LBORRES2 -7 "Negative"
lab val M07_CBC_HB_LBORRES2 M07_CBC_HB_LBORRES2
 
*cleaning continuous variables
	foreach x of varlist  ///
	M07_CBC_HB_LBORRES1 M07_CBC_HB_LBORRES2 M07_CBC_HB_LBORRES3 M07_CBC_HB_LBORRES4 M07_HB_POC_LBORRES1 M07_HB_POC_LBORRES2 M07_HB_POC_LBORRES3 M07_HB_POC_LBORRES4 M08_SPHB_LBORRES1 M08_SPHB_LBORRES2 M08_SPHB_LBORRES3 M08_SPHB_LBORRES4 M08_SPHB_LBORRES5 M08_SPHB_LBORRES6 M08_SPHB_LBORRES7 M08_SPHB_LBORRES8 M08_SPHB_LBORRES9 M08_SPHB_LBORRES10 M08_SPHB_LBORRES11 M08_SPHB_LBORRES12 M08_SPHB_LBORRES13  ///
	M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES {
		replace `x' = . if `x' == -7
		destring `x', replace 
}		

*cleaning date variables
	
	*foreach x of varlist M01_LMP_SCDAT M01_SCRN_OBSSTDAT {
	*replace `x' = "" if(`x' =="SKIPPED")
	*gen date2=date(`x', "YMD") 
	*rename `x' `x'_str
	*rename date2 `x'
	*format `x' %d 
	
	*}
	foreach var of varlist M01_LMP_SCDAT M01_SCRN_OBSSTDAT M01_EDD_SCDAT M01_ESTIMATED_EDD_SCDAT {
	replace `var' = "" if(`var' == "-7")
	}
	rename M01_LMP_SCDAT M01_LMP_SCDAT_str
	rename M01_SCRN_OBSSTDAT M01_SCRN_OBSSTDAT_str
	rename M01_EDD_SCDAT M01_EDD_SCDAT_str
	rename M01_ESTIMATED_EDD_SCDAT M01_ESTIMATED_EDD_SCDAT_str
	
	gen M01_LMP_SCDAT=date(M01_LMP_SCDAT_str, "MDY") 
	format M01_LMP_SCDAT %d 
	
	gen M01_SCRN_OBSSTDAT=date(M01_SCRN_OBSSTDAT_str, "MDY") 
	format M01_SCRN_OBSSTDAT %d 
     
	gen M01_EDD_SCDAT=date(M01_EDD_SCDAT_str, "MDY") 
	format M01_EDD_SCDAT %d 
	
	gen M01_ESTIMATED_EDD_SCDAT=date(M01_ESTIMATED_EDD_SCDAT_str, "MDY") 
	format M01_ESTIMATED_EDD_SCDAT %d 

	

***********adding additional codes for the calculation of missing gestational age

******gestational age calculation for missing IDs
	
gen edd_for_missing= M01_EDD_SCDAT if M01_ESTIMATED_EDD_SCDAT== .
format edd_for_missing %d
gen lmp_for_missing= edd_for_missing - 280
format lmp_for_missing %d
gen gest_age_missing= M01_SCRN_OBSSTDAT - lmp_for_missing

gen gest_age_missing1= M01_SCRN_OBSSTDAT - lmp_for_missing

gen gest_age_week =  gest_age_missing/7 
*replace gest_age_week=  round(gest_age_week)

gen gest_age_month =  gest_age_missing/30 
*replace gest_age_month=  round(gest_age_month)

replace M01_GEST_AGE_WKS_SCORRES= gest_age_week if  M01_GEST_AGE_WKS_SCORRES== .

replace M01_GEST_AGE_MOS_SCORRES= gest_age_month if  M01_GEST_AGE_MOS_SCORRES== .


************************gestational age by Ultra sound
	
gen gest_age_us_week=.
replace gest_age_us_week= M06_US_GA_WEEKS_AGE1 + (M06_US_GA_DAYS_AGE1/7) if (M06_US_GA_WEEKS_AGE1!= . & M06_US_GA_DAYS_AGE1!= .)

gen gest_age_us_month= gest_age_us_week/4 if gest_age_us_week!= .

*replace gest_age_us_week= round(gest_age_us_week)
*replace gest_age_us_month= round(gest_age_us_month)


replace gest_age_us_week= M01_GEST_AGE_WKS_SCORRES if gest_age_us_week== .
replace gest_age_us_month= M01_GEST_AGE_MOS_SCORRES if gest_age_us_month== .

	
	
*calculating LMP for all participants
gen lmp_cal=.
replace lmp_cal=M01_LMP_SCDAT if(M01_LMP_SCDAT!=.)
replace lmp_cal=lmp_for_missing if (lmp_cal== .) 
replace lmp_cal=M01_SCRN_OBSSTDAT-(gest_age_us_week*7) if(M01_LMP_SCDAT==. & M01_GEST_AGE_MOS_SCORRES ==. )
replace lmp_cal=M01_SCRN_OBSSTDAT-(gest_age_us_month*30.5) if (M01_LMP_SCDAT==. & M01_GEST_AGE_WKS_SCORRES==.)
format lmp_cal %d

*calculating gestage at enrollment for all participants
	*in days
	gen gestage_days_enroll=.
	replace gestage_days_enroll=(M01_SCRN_OBSSTDAT-lmp_cal)
	label var gestage_days_enroll "Gestational age at enrollment (days)"

	*in weeks
			gen gestage_weeks_enroll=.
			replace gestage_weeks_enroll=gestage_days_enroll/7
			label var gestage_weeks_enroll "Gestational age at enrollment (weeks)"
		
				summ gestage_weeks_enroll

	*in trimesters
	gen tri_enroll=.
		replace tri_enroll=1 if(gestage_weeks_enroll>3 & gestage_weeks_enroll<14)
		replace tri_enroll=2 if(gestage_weeks_enroll>=14 & gestage_weeks_enroll<27)
		replace tri_enroll=3 if(gestage_weeks_enroll>=27 & gestage_weeks_enroll<43)	

*summarizing gestational age at enrollment
	summ gestage_days_enroll
	tab tri_enroll,m
****************************************************************
*Do Files For Form Merge and Data Cleaning

*include "ReMAPP-Data-Cleaning-Form-Merge-2022-01-20"

*creating subfolder for figures
shell mkdir plots


	***************************************************************
	*Label values used throughout the code
	 label define yesno 0 "no" 1 "yes"

	 label define yesno1 0 "no" 1 "yes" 9 "unknown"

	****************************************************************
	*Table a.1: Enrollment numbers for PRiSMA MNH Study

	*Creating variable for screened for PRiSMA - currently based on if date of screening recorded
		gen screened_prisma=.
		replace screened_prisma = 1 if M01_SCRN_OBSSTDAT!= .
		replace screened_prisma =0 if M01_SCRN_OBSSTDAT== .
		label var screened_prisma "Participant was screened for enrollment"
		label define screened_prisma 1"yes" 0"no"
		label val screened_prisma screened_prisma

	*Creating variable for eligibility for PRiSMA
		gen eligible_prisma=.
		replace eligible_prisma= 1 if (M01_AGE_IEORRES == 1 & M01_PC_IEORRES == 1 & M01_EXCL_YN_IEORRES == 0) 
		replace eligible_prisma=0 if (M01_AGE_IEORRES != 1 | M01_PC_IEORRES != 1 | M01_EXCL_YN_IEORRES != 0) 
		label var eligible_prisma "Participant was found eligible for PRiSMA"
		label def eligible_prisma 1"yes" 0"no"
		lab val eligible_prisma eligible_prisma
		
	*Creating variable for enrolled for PRiSMA - this is assuming you cannot consent and not enroll
	*"M01_CON_SIGNYN_DSDECOD" this variable is not available in our data set
		gen enrolled_prisma=.
		replace enrolled_prisma=1 if (M01_CON_YN_DSDECOD==1)
		replace enrolled_prisma=0 if ( M01_CON_YN_DSDECOD!=1)
		label var enrolled_prisma "Participant enrolled for PRiSMA"
		label define enrolled_prisma 1"yes" 2"no"
		
	****************************************************************
	*Table a.2:  Site demographics for PRiSMA MNH Study 

	*Creating maternal age at enrollment variable - using date at enrollment  
		
		*cleaning date variables
        gen dob=date(M01_BRTHDAT , "MDY")
	    format dob %td
		gen scrn_date=(M01_SCRN_OBSSTDAT)
		format scrn_date %td
	
		*cleaning age variable
		replace M01_ESTIMATED_AGE= . if(M01_ESTIMATED_AGE== -7)
		*destring M01_ESTIMATED_AGE, replace 
		
		*maternal age at enrollment 
		gen mat_age_enroll=.
		replace mat_age_enroll=(scrn_date-dob)/365
		replace mat_age_enroll=M01_ESTIMATED_AGE if mat_age_enroll==.
		label var mat_age_enroll "Maternal age at enrollment"
		ta mat_age_enroll,m
		
	*Creating BMI at enrollment variable
		*TBD
	
	*Creating variable for gestational age at enrollment 
		
		*converting dates of LMP and screening to date format
	
	*foreach x of varlist M01_LMP_SCDAT {
		*replace `x' = "" if(`x' =="SKIPPED")
		*gen date2=date(`x', "DMY") 
		*rename `x' `x'_str
		*rename date2 `x'
		*format `x' %d 
	*}
	
		*converting estimated gestational age variables to numeric
		*foreach x of varlist M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES {
		*replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		*destring `x', replace 
		*}
	
		*calculating last menstrual cycle (LMP) for all participants
		
		*gen lmp_cal=.
		*replace lmp_cal=M01_LMP_SCDAT if(M01_LMP_SCDAT!=.)
		*replace lmp_cal=scrn_date-(M01_GEST_AGE_WKS_SCORRES*7) if(M01_LMP_SCDAT==. & M01_GEST_AGE_MOS_SCORRES ==. )
		*replace lmp_cal=scrn_date-(M01_GEST_AGE_MOS_SCORRES*30.5) if (M01_LMP_SCDAT==. & M01_GEST_AGE_WKS_SCORRES==.)
		*format lmp_cal %d
		label var lmp_cal "Calculated date of LMP at enrollment - incl est gest age"

		*calculating gestage at enrollment for all participants
			*in days
			
			*gen gestage_days_enroll=.
			*replace gestage_days_enroll=(scrn_date-lmp_cal)
			*label var gestage_days_enroll "Gestational age at enrollment (days)"
		
			*in weeks
			
			*gen gestage_weeks_enroll=.
			*replace gestage_weeks_enroll=gestage_days_enroll/7
			*label var gestage_weeks_enroll "Gestational age at enrollment (weeks)"
		
				summ gestage_weeks_enroll
				
				*looking at implausible gestational age at enrollment <4 weeks or >42
				list PREGNANCY_ID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll gestage_weeks_enroll if gestage_weeks_enroll>42 & gestage_weeks_enroll!=.
				
				*looking at implausible gestational age at enrollment <4 weeks or >42
				list PREGNANCY_ID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll gestage_weeks_enroll if gestage_weeks_enroll<4 & gestage_weeks_enroll!=.
			
		
		*in trimesters
		
		*gen tri_enroll=.
		*replace tri_enroll=1 if(gestage_weeks_enroll>3 & gestage_weeks_enroll<14)
		*replace tri_enroll=2 if(gestage_weeks_enroll>=14 & gestage_weeks_enroll<27)
		*replace tri_enroll=3 if(gestage_weeks_enroll>=27 & gestage_weeks_enroll<43)	
	
	*Marital Status - married or cohabitating
		
		label define marital_stat1 1 "Married" 2 "Not married but living with partner" 3 "Divorced/seperated" 4 "Widowed" 5 "Single - never married"
		label values M02_MARITAL_SCORRES marital_stat1
		
		
		*creating variable for married or cohabitating - combining 1 and 2 categories of M02_MARITAL_SCORRES
		gen married=.
		replace married=1 if (M02_MARITAL_SCORRES==1 | M02_MARITAL_SCORRES==2)
		replace married=0 if (M02_MARITAL_SCORRES==3 | M02_MARITAL_SCORRES==4 | M02_MARITAL_SCORRES==5)
		label var married "Participant married or cohabitating at enrollment?"
		lab def married 1"Yes" 0"No"
		label values married married
		
	*Creating variable for parity - defined as woman who has not had a live birth
		
		*converting variables M03a_PH_LIVE_RPORRES to numeric
		
		
		*foreach x of varlist M03a_PH_LIVE_RPORRES {
		*replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		*destring `x', replace 
		*}
		 
		gen parity=.
		replace parity=0 if (M03a_PH_PREV_RPORRES==0 | M03a_PH_LIVE_RPORRES ==0)
		replace parity=1 if (M03a_PH_LIVE_RPORRES >=1 & M03a_PH_LIVE_RPORRES!=.)
		label var parity "Parity"
		label define parity1 0 "Nulliparous" 1 ">=1 live births"
		label values parity parity1
		ta parity,m

	****************************************************************
	*Hemoglobin values

	*fixing M07_CBC_HB_LBORRES2
	*replace M07_CBC_HB_LBORRES2=" " if (M07_CBC_HB_LBORRES2=="NEGATIVE ")

	*cleaning continuous variables
		
		*foreach x of varlist  ///
		*M07_CBC_HB_LBORRES* M07_HB_POC_LBORRES* M08_SPHB_LBORRES* ///
		*{
		*	replace `x' = "" if(`x' =="SKIPPED" | `x' == "UNDEFINED")
		*	destring `x', replace 
	*}
	
		*great code to list if not numeric! 
			*gen byte flag_notnumeric = real(M08_SPHB_LBORRES1)==.

	 *list CASEID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll if gestage_days_enroll>280

 
	**************************************************
	*Log file for Screening and Site Demographics
	**************************************************
		capture log close
		log using "ReMAPP_ANC_Screening_14_feb_2022.txt", text  replace
					
		*Screening vs enrolled
				table eligible_prisma enrolled_prisma if screened_prisma== 1
				
		*Site Demographics
			*Maternal Age at Enrollment 
				summ mat_age_enroll
			
			*Gestational age at Enrollment (weeks)
				summ gestage_weeks_enroll
				
			*Trimester at enrollment
				tab tri_enroll
			
			*Marital Status
				tab M02_MARITAL_SCORRES
				
			*Parity
				tab parity 

		log close 
	
*************************************************
*Part 3: Data Checks
*************************************************
 
		 ***Checking Hemoglobin and Gestational Age
		 *******************************************************
		 *reformating data to be long again
		 keep PREGNANCY_ID M07_visit_date1 M07_visit_date2 M07_visit_date3 M07_visit_date4 M07_CBC_HB_LBORRES1 M07_CBC_HB_LBORRES2 M07_CBC_HB_LBORRES3 M07_CBC_HB_LBORRES4 M07_HB_POC_LBORRES1 M07_HB_POC_LBORRES2 M07_HB_POC_LBORRES3 M07_HB_POC_LBORRES4 M07_lab_visit_tot M08_visit_date1 M08_visit_date2 M08_visit_date3 M08_visit_date4 M08_visit_date5 M08_visit_date6 M08_visit_date7 M08_visit_date8 M08_visit_date9 M08_visit_date10 M08_visit_date11 M08_visit_date12 M08_visit_date13  M08_SPHB_LBORRES1 M08_SPHB_LBORRES2 M08_SPHB_LBORRES3 M08_SPHB_LBORRES4 M08_SPHB_LBORRES5 M08_SPHB_LBORRES6 M08_SPHB_LBORRES7 M08_SPHB_LBORRES8 M08_SPHB_LBORRES9 M08_SPHB_LBORRES10 M08_SPHB_LBORRES11 M08_SPHB_LBORRES12 M08_SPHB_LBORRES13 ///
		 lmp_cal 

		 reshape long M07_visit_date M07_CBC_HB_LBORRES M07_HB_POC_LBORRES M08_visit_date M08_SPHB_LBORRES, i(PREGNANCY_ID) j(visit_num)  
		 
		 *dropping observations if no M07 or M08 visit
		 drop if M07_visit_date==. & M08_visit_date==.
		 
		 *dropping observation if no hemoglobin measures 
		 drop if M07_CBC_HB_LBORRES==. & M07_HB_POC_LBORRES==. & M08_SPHB_LBORRES==.
		 
		 ***Since we have multiple measures of hemoglobin we need to separate datasets - can append datasets after

		 
		 *CBC 
		  preserve 
			*only keeping observations with CBC results
			keep if M07_CBC_HB_LBORRES!=. // only CBC results
			
			*renaming variables to match during append
			rename M07_CBC_HB_LBORRES hemoglobin 
			rename M07_visit_date visit_date
			
			*generating variable for hemoglobin test type
			gen hem_type="CBC"
			
			*keeping relevant variables for CBC
			keep PREGNANCY_ID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile cbc
			sort PREGNANCY_ID
			save cbc_14_feb,replace
			
			restore
		 
		 *POC
		 preserve 
			*only keeping observations with POC results
			keep if M07_HB_POC_LBORRES!=. // only POC results
			
			*renaming variables to match during append
			rename M07_HB_POC_LBORRES hemoglobin 
			rename M07_visit_date visit_date
			
			*generating variable for hemoglobin test type
			gen hem_type="POC"
			
			*keeping relevant variables for CBC
			keep PREGNANCY_ID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile poc
			sort PREGNANCY_ID
			save poc_14_feb,replace
			
			restore
		 
		 *Sp
		 preserve 
			*only keeping observations with  results
			keep if M08_SPHB_LBORRES!=. // only Sp results
			
			*renaming variables to match during append
			rename M08_SPHB_LBORRES hemoglobin 
			rename M08_visit_date visit_date
			
			*generating variable for hemoglobin test type
			gen hem_type="SpHb"
			
			*keeping relevant variables for CBC
			keep PREGNANCY_ID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile sphb
			sort PREGNANCY_ID
			save sphb_14_feb,replace
			
			restore
			
		****Appending Datasets 
		use cbc_14_feb, clear 
			
			append using poc_14_feb
			append using sphb_14_feb

		*****Creating Variables
			 *average number of hemoglobin measure per patient 
				sort PREGNANCY_ID
				bysort PREGNANCY_ID: gen hem_num=_n 
				bysort PREGNANCY_ID: gen hem_tot=_N //total number of hemoglobin measures 
				
			 *creating gestational age at visit 
			 gen gestage=visit_date-lmp_cal
			 
			list if gestage>300 & gestage!=.
			
			replace gestage=. if(gestage>300 & gestage!=.) //9 values changed
			 
			 
				*trimester
				gen tri_lab=.
				replace tri_lab=1 if(gestage<=91)
				replace tri_lab=2 if(gestage>91 & gestage<=182)
				replace tri_lab=3 if(gestage>182 & gestage<=300)
				ta tri_lab,m

			*Anemia 
				*CDC definition
				gen anemia_CDC = .
				replace anemia_CDC=0 if(hemoglobin>=11 & (tri_lab==1 | tri_lab==3) & hemoglobin!=.)
				replace anemia_CDC=0 if(hemoglobin>=10.5 & tri_lab==2 & hemoglobin!=.)
				replace anemia_CDC=1 if(hemoglobin<11 & tri_lab==1)
				replace anemia_CDC=1 if(hemoglobin<10.5 & tri_lab==2)
				replace anemia_CDC=1 if(hemoglobin<11.0 & tri_lab==3)
				ta anemia_CDC,m
				*WHO
				gen anemia_WHO=.
				replace anemia_WHO=0 if(hemoglobin>=11 & hemoglobin!=.)
				replace anemia_WHO=1 if(hemoglobin<11)
				replace anemia_WHO=2 if(hemoglobin<10)
				replace anemia_WHO=3 if(hemoglobin<7)
				ta anemia_WHO,m
					*labeling values
						label define who1 0 "Normal Hemoglobin" 1 "Mild Anemia" 2 "Moderate Anemia" 3 "Severe Anemia"
						label values anemia_WHO who1
						
						

******************************************************************	
*****Code for Log File
******************************************************************
			capture log close
			log using "ReMAPP_ANC_Hemoglobin_14_feb_2022.txt", text  replace
			
			*Summary of ANC Hemoglobin Results
			
			*Table of Type of Hemoglobin Tests run for ANC 
			tab hem_type
			
			*Number of hemoglobin tests per participant
			tab hem_tot if hem_num==1
			
			*hemoglobin checks 
			list if hemoglobin>18
			
				replace hemoglobin=. if(hemoglobin>18)
				
			list if hemoglobin<5
				replace hemoglobin=. if(hemoglobin<2)
				
			*Distribution of hemoglobin
			summ hemoglobin
			
			bysort tri_lab: summ hemoglobin
			
			*Prevalence of Anemia
				*CDC definition
				tab anemia_CDC
				
				*WHO definition
				tab anemia_WHO
			
			log close 
			
********************************************
****Histograms
********************************************
			
			*Scatter plot
		 twoway (scatter hemoglobin gestage if hem_type=="CBC", color(green%30)) ///
			 (scatter hemoglobin gestage if hem_type=="POC", color(blue%30)) ///
			 (scatter hemoglobin gestage if hem_type=="SpHb", color(red%30)), ///
			 legend(order (1 "CBC" 2 "POC" 3 "SpHb")) xtitle("Gestational Age (days)") ///
			 ytitle("Hemoglobin (g/dL)") title("Scatter Plot of Hemoglobin vs. Gestational Age")
			 graph export plots/scatter_hb_gestage_14_feb.png, replace 
			
			
			**All Observatons - CBC, POC, SpHb methods
			*histogram
			histogram hemoglobin 
				graph export plots/all_hemoglobin_14_Feb.png,replace  
			
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(0.5) color(green%30)) ///
			   (histogram hemoglobin  if tri_lab==2, width(0.5) color(blue%30)) ///
			   (histogram hemoglobin if tri_lab==3, width(0.5) color(red%30)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				graph export plots/all_hemoglobin_tri1_14_feb.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
				graph export plots/all_hemoglobin_tri2_14_feb.png, replace
			 
			**Only CBC
			preserve 
			keep if hem_type=="CBC"
			*histogram - CBC Only
			histogram hemoglobin 
				graph export plots/cbc_hemoglobin.png, replace
			
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(0.5) color(green%30)) ///
			   (histogram hemoglobin  if tri_lab==2, width(0.5) color(blue%30)) ///
			   (histogram hemoglobin if tri_lab==3, width(0.5) color(red%30)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				graph export plots/cbc_hemoglobin_tri1.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
				graph export plots/cbc_hemoglobin_tri2.png, replace 
			 
			 restore 
			 
			**Only POC ******not available in Pakistan data 
			
			**//preserve 
			*keep if hem_type=="POC"
			
			*histogram - POC Only
			
			*histogram hemoglobin 
			*	graph export plots/poc_hemoglobin.png, replace
				
			*histogram by trimester - same graph
			
			*twoway (histogram hemoglobin if tri_lab==1, width(1) color(green%30)) ///
			 *  (histogram hemoglobin  if tri_lab==2, width(1) color(blue%30)) ///
			  * (histogram hemoglobin if tri_lab==3, width(1) color(red%30)), ///
			  *legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				*	graph export plots/poc_hemoglobin_tri1.png, replace ///
			  
			 *histrogram by trimester - different graphs
			 
			 *twoway histogram hemoglobin, by(tri_lab) 
				*	graph export plots/poc_hemoglobin_tri2.png, replace  
			
			 *restore 			 
			 
			**Only SpHb
			preserve 
			keep if hem_type=="SpHb"
			*histogram - SbHb Only
			histogram hemoglobin 
				graph export plots/SbHb_hemoglobin.png, replace
			
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(0.5) color(green%30)) ///
			   (histogram hemoglobin  if tri_lab==2, width(0.5) color(blue%30)) ///
			   (histogram hemoglobin if tri_lab==3, width(0.5) color(red%30)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				graph export plots/SbHb_hemoglobin_tri1.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
				graph export plots/SbHb_hemoglobin_tri2.png, replace 
			 
			 restore 
			
			
*******************************************************************************************************
*Comparison of Hemoglobin measures taken on same day
*******************************************************************************************************
	 *preserve
	 
	*Creating variable for hemoglobin on same day
		
			sort PREGNANCY_ID visit_date
				bysort PREGNANCY_ID visit_date: gen hem_day=_n 
				bysort PREGNANCY_ID visit_date: gen hem_sameday=_N // in Kenya data POC and SbHb is what is most commonly happening on the same day
		
	*creating dataset of only paired hemoglobin measures
		keep if hem_sameday>1 
		
		gen hem_sphb=.
		replace hem_sphb=hemoglobin if hem_type=="SpHb"
		
		gen hem_cbc=.
		replace hem_cbc=hemoglobin if hem_type=="CBC"
		
		gen hem_poc=.
		replace hem_poc=hemoglobin if hem_type=="POC"
		
		*gen hem_type_num = . if hem_type== ""	
		*replace hem_type_num= 1 if hem_type== "CBC"
		*replace hem_type_num= 2 if hem_type== "SpHb"
		*lab def hem_type_num 1"CBC" 2"SpHb"
		*lab val hem_type_num hem_type_num
		*ta hem_type_num
		
		drop hem_num hem_tot tri_lab anemia_CDC anemia_WHO hem_day hem_sameday hem_sphb hem_cbc hem_poc
		
		reshape wide hemoglobin , i(PREGNANCY_ID visit_date)  j(hem_type) string
		
	*******************************************************
	*Point of Care vs SpHb - Comment out if you do not have SpHb values
	*******************************************************
	****Scatter plot of hem_sphb and hem_poc
		
		
		****We donot have values of POC so making it comment
		
		*twoway (lfit hemoglobinPOC hemoglobinSpHb, lcolor(gray) lpattern(dash) lwidth(vthick)) /// line of fit code
		 *(function y=x, ra(hemoglobinSpHb) clcolor(gs4)) /// diagonal line of unity
		*(scatter hemoglobinPOC hemoglobinSpHb , mcolor(black) msize(vsmall)), /// make dots appear for scatter, y x axis
		*legend(off) /// hide legend
		*title("Scatter Plot", color(black)) ///
		*ytitle("POC Hemoglobin") /// 
		*xtitle("SpHb Hemoglobin") /// 
		*xline(11, lpattern(solid) lcolor(gray)) /// cutoff for Anemia - WHO
		*yline(11, lpattern(solid) lcolor(gray)) /// ditto
		*graphregion(color(white)) ylabel(, grid glcolor(gs14)) /// white background, light gray lines
		*aspectratio(1) // force figure to be a 1x1 square, not a rectangle
		*graph save plots/pocsphb_scatterplot.gph, replace // need graph to merge later
		*graph export plots/pocsphb_scatterplot.png, width(4000) replace
		
	*****Bland altman plot for hemoglobin measures
		***prep for figure 
		*gen mean_hem_sphb=(hemoglobinPOC+hemoglobinSpHb)/2 // this will be the x-axis
		*gen diff_hem_sphb=hemoglobinPOC-hemoglobinSpHb // this will be y-axis
		*sum diff_hem_sphb // this allows you to make a macro of the mean ("r(mean)") of the y axis variable
		*global mean1=r(mean) // this saves the macro as mean1, to be called later
		*global lowerCL1=r(mean) - 2*r(sd) // this saves a macro for the mean+2 times the SD ("r(sd)")
		*global upperCL1=r(mean) + 2*r(sd)
		***make graph
		*graph twoway scatter diff_hem_sphb mean_hem_sphb, ///
		*legend(off) mcolor(black) ///
		*ytitle("POC Minus SpHb") /// 
		*xtitle("Average of POC and SpHb ") /// 
		*title("Bland-Altman", color(black)) /// 
		*yline($mean1, lpattern(shortdash) lcolor(gray)) /// calls the macro from above
		*yline($lowerCL1, lpattern(dash) lcolor(gray)) /// ditto
		*yline($upperCL1, lpattern(dash) lcolor(gray)) /// 
		*graphregion(color(white)) ylabel(, grid glcolor(gs14)) /// white background
		*aspectratio(1) //
		***save graph
		*graph save plots/pocsphb_bland_altman.gph, replace
		*graph export plots/pocsphb_bland_altman.png, width(4000) replace		
		
		*graph combine plots/pocsphb_scatterplot.gph plots/pocsphb_bland_altman.gph, ///
		*graphregion(color(white)) ///
		*title("Comparison of POC and SpHb Hemoglobin Measures") 
		*graph save plots/pocsphb_hemoglobin.gph, replace // need graph to merge later
		*graph export plots/pocsphb_hemoglobin.png, width(4000) replace
		
	*******************************************************
	*CBC vs SpHb - comment out if you do not have CBC values
	*******************************************************
	****Scatter plot of  hemoglobinSpHb hemoglobinCBC
		 
		twoway (lfit hemoglobinSpHb hemoglobinCBC, lcolor(gray) lpattern(dash) lwidth(vthick)) /// line of fit code
		(function y=x, ra(hemoglobinCBC) clcolor(gs4)) /// diagonal line of unity
		(scatter hemoglobinSpHb hemoglobinCBC , mcolor(black) msize(vsmall)), /// make dots appear for scatter, y x axis
		legend(off) /// hide legend
		title("Scatter Plot", color(black)) ///
		ytitle("SpHb Hemoglobin") /// 
		xtitle("CBC Hemoglobin") /// 
		xline(11, lpattern(solid) lcolor(gray)) /// cutoff for Anemia - WHO
		yline(11, lpattern(solid) lcolor(gray)) /// ditto
		graphregion(color(white)) ylabel(, grid glcolor(gs14)) /// white background, light gray lines
		xlabel(0(5)15) ylabel(0(5)15) ///
		aspectratio(1) // force figure to be a 1x1 square, not a rectangle
		graph save plots/cbcspHb_scatterplot.gph, replace // need graph to merge later
		graph export plots/cbcspHb_scatterplot.png, width(4000) replace
		
		
	****Bland altman plot for hemoglobin measures
		***prep for figure
		gen mean_hem_cbc=(hemoglobinSpHb+hemoglobinCBC)/2 // this will be the x-axis
		gen diff_hem_cbc=hemoglobinSpHb-hemoglobinCBC // this will be y-axis
		sum diff_hem_cbc // this allows you to make a macro of the mean ("r(mean)") of the y axis variable
		global mean2=r(mean) // this saves the macro as mean1, to be called later
		global lowerCL2=r(mean) - 2*r(sd) // this saves a macro for the mean+2 times the SD ("r(sd)")
		global upperCL2=r(mean) + 2*r(sd)
		***make graph
		graph twoway scatter diff_hem_cbc mean_hem_cbc, ///
		legend(off) mcolor(black) ///
		ytitle("SpHb Minus CBC") /// 
		xtitle("Average of SpHb and CBC ") /// 
		title("Bland-Altman", color(black)) /// 
		yline($mean2, lpattern(shortdash) lcolor(gray)) /// calls the macro from above
		yline($lowerCL2, lpattern(dash) lcolor(gray)) /// ditto
		yline($upperCL2, lpattern(dash) lcolor(gray)) /// 
		graphregion(color(white)) ylabel(, grid glcolor(gs14)) /// white background
		aspectratio(1) 
		***save graph
		graph save plots/cbcsbHb_bland_altman.gph, replace
		graph export plots/cbcsbHb_bland_altman.png, width(4000) replace		
		
		graph combine plots/cbcspHb_scatterplot.gph plots/cbcsbHb_bland_altman.gph, ///
		graphregion(color(white)) ///
		title("Comparison of SpHb and CBC Hemoglobin Measures") //
		graph save plots/cbcspHb_hemoglobin.gph, replace 
		graph export plots/cbcspHb_hemoglobin.png, width(4000) replace
	
		*restore

		
************************************************
*Docx Output
************************************************
		clear 
		putdocx begin

		putdocx paragraph
		putdocx text ("ANC Hemoglobin Descriptive Statistics"), bold
			
		putdocx paragraph, halign(left)
		putdocx text ("Scatter Plot for Hemoglobin vs. Gestational Age by measurement method")
		putdocx image "plots/scatter_hb_gestage_14_feb.png"

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (all methods)")
		putdocx image plots/all_hemoglobin_14_Feb.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (all methods)")
		putdocx image plots/all_hemoglobin_tri1_14_feb.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (all methods)")
		putdocx image plots/all_hemoglobin_tri2_14_feb.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (CBC only)")
		putdocx image plots/cbc_hemoglobin.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (CBC only)")
		putdocx image plots/cbc_hemoglobin_tri1.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (CBC only)")
		putdocx image plots/cbc_hemoglobin_tri2.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (SpHb only)")
		putdocx image plots/SbHb_hemoglobin.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (SbHb only)")
		putdocx image plots/SbHb_hemoglobin_tri1.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (SbHb only)")
		putdocx image plots/SbHb_hemoglobin_tri2.png
		
		putdocx paragraph, halign(left)
		putdocx text ("Comparison of Same-day Hemoglobin Measures")
		*putdocx image cbcpoc_hemoglobin.png //comment out if you do not have cbc measures
		putdocx image plots/cbcsphb_hemoglobin.png // comment out if you do not have sphb values
		 
			 
		putdocx save "ReMAPP ANC Hemoglobin Figures_14_feb_2022.docx", replace 
 
			 
