****************************************************************
*Data Cleaning File for Anemia
*Last Updated: 12/08/2021 ALB
*Users: ALB and SGB
****************************************************************

****************************************************************
*Part 1: Compiling Final Dataset - Maternal
****************************************************************
/*In this section we are 
	1) selecting relavent variables from each form
	2) saving those forms as temporary files for final merge
	3) converting forms that may have multiple entries per participant into wide format
		-MNH04
		-MNH05
		-MNH06
		-MNH07
		-MNH08
		-MNH13
		-MNH17
		-MNH18
	
Data is downloaded from synapse servers as csv files with no labels. 

*Notes: Stata allows variable names no greater than 32 characters.
		Infant outcomes will be in a different dataset based on infant ID */

*Working Directory - should be updated by user
cd "C:\Farrukh_data\Anemia\data"
 
*Current date - will be used for duplicate filename
local today : display %tdCYND date(c(current_date), "DMY")

**********************
**MNH01 - Screening and Enrollment

import delimited using "MNH01_Nov_2021.csv", clear

rename *, upper
*CASEID AGE_18_IEORRES GEST_AGE_MOS_SCORRES ///
*FIRST_ANC_TODAY_YN ANC_PRSCHDAT ANC_PREENROLL_YN ANC_PREENROLL_N WEIGHT_PEPERF WEIGHT_PERES
*    ///
  *WEIGH_PREV_PERES HEIGHT_PEPERF HEIGHT_PERES HEIGHT_PREV_PERES 
*CON_SIGNATURE_PRYN
keep SUBJID CON_YN_DSDECOD SCRNID SCRN_OBSSTDAT AGE_IEORRES PC_IEORRES EXCL_YN_IEORRES ///
  KNOWN_DOBYN_SCORRES BRTHDAT ESTIMATED_AGE KNOWN_LMP_SCORRES LMP_SCDAT ///
 LMP_RELIABLEYN_SCORRES GEST_AGE_AVAILYN_SCORRES GEST_AGE_WKS_SCORRES   ///
 EDD_AVAILYN_SCORRES EDD_SCDAT RESIDE_CATCH_YN_SCORRES DELIVER_CATCH_YN_SCORRES ENR_MOTHER_VILLAGE_SCORRES ///
   
gen GEST_AGE_MOS_SCORRES= GEST_AGE_WKS_SCORRES/4 if GEST_AGE_WKS_SCORRES!= .

replace GEST_AGE_MOS_SCORRES= round(GEST_AGE_MOS_SCORRES)
replace GEST_AGE_WKS_SCORRES= round(GEST_AGE_WKS_SCORRES)
   
	*Labeling Variables
		label variable SCRN_OBSSTDAT 				"Screening Date"
		label variable AGE_IEORRES					"Is maternal age >= 15 years?"
		label variable PC_IEORRES					"Has pregnancy been confirmed?"
		label variable EXCL_YN_IEORRES				"Any other reason to exclude the mother from participating in this study?"
		*label variable AGE_18_IEORRES 				"Is the mother 18 years of age or older?"
		label variable SUBJID						"Subject ID"
		label variable KNOWN_DOBYN_SCORRES			"Is mother's exact date of birth known?"
		label variable BRTHDAT						"Mother's date of birth" //PHI
		label variable ESTIMATED_AGE 				"If mother's date of birth is unknown, estimate age in years"
		label variable KNOWN_LMP_SCORRES 			"Does the mother know the date of her last menstrual period (LMP)?"
		label variable LMP_SCDAT                    "Record date of mother's last menstrual period (LMP)"
		label variable LMP_RELIABLEYN_SCORRES 		"Is the date of LMP reliable?"
		label variable GEST_AGE_AVAILYN_SCORRES		"Is estimated GA available?"
		label variable GEST_AGE_WKS_SCORRES			"Estimated GA in weeks"
		label variable GEST_AGE_MOS_SCORRES			"Estimated GA in months"
		label variable EDD_AVAILYN_SCORRES			"Is EDD available?"
		label variable EDD_SCDAT					"Record EDD"
		label variable RESIDE_CATCH_YN_SCORRES		"Does the mother currently reside in the study catchment area?"
		label variable DELIVER_CATCH_YN_SCORRES		"Does the mother intend to deliver in the study catchment area?"
		label variable ENR_MOTHER_VILLAGE_SCORRES	"Village of residence"
		*label variable FIRST_ANC_TODAY_YN			"Will the first ANC visit for the study take place today?"
		*label variable ANC_PRSCHDAT					"Specify date of next ANC visit"
		*label variable ANC_PREENROLL_YN				"Did the mother attend any other ANC visits before enrollment?"
		*label variable ANC_PREENROLL_N				"Specify number of previous ANC visits"
		*label variable WEIGHT_PEPERF				"Is it feasible for study staff to measure participant's weight at this visit?"
		*label variable WEIGHT_PERES					"Record weight"
		*label variable WEIGH_PREV_PERES				"Record date of previous ANC visit when weight was recorded."
		*label variable HEIGHT_PEPERF				"Is it feasible for study staff to measure participant's height at this visit?"
		*label variable HEIGHT_PERES					"Record height"
		*label variable HEIGHT_PREV_PERES			"Record date of previous ANC visit when height was recorded"
		
	*create a variable for 1 PCM var	
		
		
	*renaming variables with M01 prefix
	foreach var of varlist _all {
	rename `var'  M01_`var'
	}
	
	*rename M01_CASEID CASEID
	rename M01_SUBJID SUBJID
	********************
	*checking duplicates
     *bysort CASEID:  gen dup = cond(_N==1,0,_n)
	 bysort SUBJID:  gen dup = cond(_N==1,0,_n)
	 

	duplicates report SUBJID
	ta dup
	
	 preserve // preserving previous data set
	 keep if dup>0
	 *keep CASEID M01_SCRN_OBSSTDAT dup
	 keep SUBJID M01_SCRN_OBSSTDAT dup
	 export excel using "ReMAPP_Duplicates_10_dec_2021.xlsx" , sheet("MNH01") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	**********************
	
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID== ""
	*generating flag variable for MNH01 
	gen FLAG_M01=1
	 
*Saving as temporary file for merge later
	tempfile mnh01
	*sort CASEID
	sort SUBJID
	save mnh01, replace
	 

*************************
**MNH02 - Sociodemographics 

import delimited using "MNH02_FINAL_with_RTI_feedback.csv", clear

rename *, upper
*CASEID PREGNANCY_ID
keep  /// 
	  SUBJID  MARITAL_SCORRES MARITAL_AGE CETHNIC SCHOOL_SCORRES EDU_LEVEL_SCORRES SCHOOL_YRS_SCORRES JOB_SCORRES ///
	 SMOKE_OECOCCUR 
	 
	 * in Ghana pd_birth_obsloctype_label
	 
	*label variables
	label variable MARITAL_SCORRES			"Marital status"
	label variable MARITAL_AGE				"Age at time of marriage"
	label variable CETHNIC					"Ethnicity"
	label variable SCHOOL_SCORRES 			"Ever attended school?"
	label variable EDU_LEVEL_SCORRES 		"Highest level of education completed"
	label variable SCHOOL_YRS_SCORRES		"Number of completed years of schooling"
	label variable JOB_SCORRES				"What is your main occupation? That is, what is the main kind of work you do to generate income?"
	label variable SMOKE_OECOCCUR			"Smoke cigarettes/cigars/pipe"
	*label variable PD_BIRTH_OHOLOC			"Where does the participant plan to give birth?"
	
	*renaming variables with M02 prefix
	foreach var of varlist _all {
	rename `var'  M02_`var'
	}
	
	*rename M02_CASEID CASEID
	rename M02_SUBJID SUBJID
	********************
	*checking duplicates
     *bysort CASEID:  gen dup = cond(_N==1,0,_n)
	 bysort SUBJID:  gen dup = cond(_N==1,0,_n)
	 
	 
	
	****/// No duplicates found in MNH_02
     duplicates report SUBJID
	 ta dup
	 
	 *preserve // preserving previous data set
	 *keep if dup>0
	 *keep CASEID dup
	 *keep SUBJID dup
	 *export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH02") firstrow(variables) sheetmodify
	 *restore // restoring old dataset
	**********************
	 
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID== ""
	*generating flag variable for MNH02 
	gen FLAG_M02=1
	 
	*Saving as temporary file for merge later
	tempfile mnh02
	*sort CASEID
	sort SUBJID
	save mnh02, replace

*************************
**MNH03a - Pregnancy History Overview

import delimited using "MNH03a_nov_2021.csv", clear

rename *, upper
*CASEID
keep SUBJID PREGNANCY_ID PH_VISDAT PH_PREV_RPORRES PH_PREVN_RPORRES ///
	PH_LIVE_RPORRES PH_OTH_RPORRES 
	
	*Labeling variables
	label variable PH_VISDAT		"Interview Date"
	label variable PH_PREV_RPORRES	"Ever pregnant"
	label variable PH_PREVN_RPORRES	"Total num of previous pregnancies"
	label variable PH_LIVE_RPORRES	"Number of live births" 
	label variable PH_OTH_RPORRES	"Number of pregnancies that ended in a stillbirth, a miscarriage, or an abortion"
	
	*renaming variables with M03a prefix
	foreach var of varlist _all {
	rename `var'  M03a_`var'
	}
	
	*rename M03a_CASEID CASEID
	rename M03a_SUBJID SUBJID
	********************
	*checking duplicates
     *bysort CASEID:  gen dup = cond(_N==1,0,_n)
	 bysort SUBJID:  gen dup = cond(_N==1,0,_n)
	 
	 duplicates report SUBJID
	 ta dup
	
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 *keep CASEID dup
	 keep SUBJID dup
	 export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH03a") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	**********************
	 
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID== ""
	*generating flag variable for MNH03a
	gen FLAG_M03a=1
	
	*Saving as temporary file for merge later
	tempfile mnh03a
	*sort CASEID
	sort SUBJID
	save mnh03a,replace

*************************
**MNH03b - Pregnancy History Detail

import delimited using "MNH03b_Nov_2021.csv", clear

rename *, upper
*CASEID LOSS2_STILL_RPORRES
keep SUBJID PREGNANCY_ID PH_BS_RPORRES PH_METH LB_LENGTH_RPORRES BW_RPYN LOSS_ABORT_RPORRES LB_WEIGHT_RPORRES ///
	PH2_BS_RPORRES PH2_METH  LOSS2_ABORT_RPORRES LB2_LENGTH_RPORRES ///
	BW2_RPYN LB2_WEIGHT_RPORRES PH3_BS_RPORRES PH3_METH LOSS3_STILL_RPORRES LOSS3_ABORT_RPORRES LB3_LENGTH_RPORRES ///
	BW3_RPYN LB3_WEIGHT_RPORRES LB_DEATH_CAT_AGE LB2_DEATH_CAT_AGE LB3_DEATH_CAT_AGE  ///
	LB_DEATH_DAYS_AGE LB_DEATH_MOS_AGE LB2_DEATH_DAYS_AGE LB2_DEATH_MOS_AGE	LB3_DEATH_DAYS_AGE LB3_DEATH_MOS_AGE ///
	
	
	*Label variables
	label variable PH_BS_RPORRES 		"Pregnancy outcome of previous pregnancy?"
	label variable PH_METH				"Delivery method of previous pregnancy"
	label variable LB_LENGTH_RPORRES	"Gestational age (GA) at time of delivery of previous pregnancy"
	label variable BW_RPYN				"Is birthweight known from previous pregnancy?"
	label variable LOSS_ABORT_RPORRES	"Gestational age (GA) at the time that the pregnancy ended of previous pregnancy"
	label variable LB_WEIGHT_RPORRES	"Birthweight of previous pregnancy"
	label variable PH2_BS_RPORRES		"Pregnancy outcome of previous pregnacy"
	label variable PH2_METH				"Delivery method of previous pregnancy"
	*label variable LOSS2_STILL_RPORRES	"Gestational age (GA) at the time that the pregnancy ended of previous pregnancy"
	label variable LOSS2_ABORT_RPORRES	"Gestational age (GA) at the time that the pregnancy ended of previous pregnancy"
	label variable LB2_LENGTH_RPORRES	"Gestational age (GA) at time of delivery of previous pregnancy"
	label variable BW2_RPYN  			"Is birthweight known from previous pregnancy"
	label variable LB2_WEIGHT_RPORRES	"Birthweight from previous pregnancy"
	label variable PH3_BS_RPORRES		"Pregnancy outcome of previous pregnacy"
	label variable PH3_METH				"Delivery method of previous pregnancy"
	label variable LOSS3_STILL_RPORRES	"Gestational age (GA) at the time that the pregnancy ended of previous pregnancy"
	label variable LOSS3_ABORT_RPORRES	"Gestational age (GA) at the time that the pregnancy ended of previous pregnancy"
	label variable LB3_LENGTH_RPORRES	"Gestational age (GA) at time of delivery of previous pregnancy"
	label variable BW3_RPYN				"Is birthweight known from previous pregnancy"
	label variable LB3_WEIGHT_RPORRES	"Birthweight from previous pregnancy"
	label variable LB_DEATH_CAT_AGE		"How old was child when he/she died?"
	label variable LB2_DEATH_CAT_AGE	"How old was child when he/she died?"
	label variable LB3_DEATH_CAT_AGE	"How old was child when he/she died?"
	label variable LB_DEATH_DAYS_AGE	"Specify age of death in days"
	label variable LB_DEATH_MOS_AGE		"Specify age of death in completed months"
	label variable LB2_DEATH_DAYS_AGE	"Specify age of death in days"
	label variable LB2_DEATH_MOS_AGE	"Specify age of death in completed months"
	label variable LB3_DEATH_DAYS_AGE	"Specify age of death in days"
	label variable LB3_DEATH_MOS_AGE	"Specify age of death in completed months"
	
	*renaming variables with M03b prefix
	foreach var of varlist _all {
	rename `var'  M03b_`var'
	}
	
	*rename M03b_CASEID CASEID
	rename M03b_SUBJID SUBJID
	********************
	*checking duplicates
     *bysort CASEID:  gen dup = cond(_N==1,0,_n)
	 bysort SUBJID:  gen dup = cond(_N==1,0,_n)
	 
	 duplicates report SUBJID
	 ta dup
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 *keep CASEID dup
	 keep SUBJID dup
	 export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH03b") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	**********************
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID== ""
	
	*generating flag variable for MNH03b
	gen FLAG_M03b=1
	
	*Saving as temporary file for merge later
	tempfile mnh03b
	*sort CASEID
	sort SUBJID 
	save mnh03b,replace

**********************	 
**MNH04 - ANC visits 
import delimited using "MNH04_Nov_2021.csv", clear 

rename *, upper
*CASEID 
keep SUBJID PREGNANCY_ID OBSSTDAT ANC_VISIT_N ANC_N_1 PATIENT_DSDECOD DTHDAT PRG_DSDECOD ///
	PRG_DSSTDAT PRG_DSSTERM PIH_MHOCCUR PIH_MHSTDAT PIH_MHTERM  HIV_MHOCCUR ///
	SYPH_MHOCCUR MALARIA_EVER_MHOCCUR DX_OTHR_PG_MHOCCUR DX_OTHR_LAST_VISIT_MHOCCUR ///
	FOLIC_ACID_CMOCCUR IRON_CMOCCUR CALCIUM_CMOCCUR ///
	MICRONUTRIENT_CMOCCUR ANTHELMINTHIC_CMOCCUR ///
	APH_RPORRES CARDIAC_EVER_MHOCCUR GEST_DIAB_RPORRES HTN_EVER_MHOCCUR LOWBIRTHWT_RPORRES ///
	MACROSOMIA_RPORRES OLIGOHYDRAMNIOS_RPORRES PREMATURE_RUPTURE_RPORRES PRETERM_RPORRES ///
	UNPL_CESARIAN_PROCCUR DIABETES_EVER_MHOCCUR PPH_RPORRES PREECLAMPSIA_RPORRES
	
	*Labeling variables
	label variable OBSSTDAT							"Date of visit"
	label variable ANC_VISIT_N						"Timing of visit"
	label variable ANC_N_1							"Is this the first ANC visit after enrollment?"
	label variable PATIENT_DSDECOD					"Vital status at time of planned visit" 
	label variable DTHDAT							"Patient date of death"
	label variable PRG_DSDECOD						"Pregnancy status at time of visit"
	label variable PRG_DSSTDAT						"Date of fetal loss" 
	label variable PRG_DSSTERM						"Specify reason for undetermined"
	label variable PIH_MHOCCUR						"Pregnancy-induced hypertension (PIH)?"
	label variable PIH_MHSTDAT 						"Date of PIH diagnosis"
	label variable PIH_MHTERM						"Specify type of PIH"
	label variable HIV_MHOCCUR						"HIV?"
	label variable SYPH_MHOCCUR						"Syphilis"
	label variable MALARIA_EVER_MHOCCUR				"Malaria?"
	label variable DX_OTHR_PG_MHOCCUR				"Diagnosed with any other conditions or illnesses since you became pregnant?"
	label variable DX_OTHR_LAST_VISIT_MHOCCUR		"Diagnosed with any other conditions or illnesses since the last study visit?"
	label variable FOLIC_ACID_CMOCCUR				"Folic acid?"
	label variable IRON_CMOCCUR						"Iron?"
	label variable CALCIUM_CMOCCUR					"Calcium?"
	label variable MICRONUTRIENT_CMOCCUR 			"Multiple micronutrient (MM) supplements?"
	label variable ANTHELMINTHIC_CMOCCUR 			"Anthelminthic treatment?" 
	label variable APH_RPORRES						"During previous pregnancies, did you experience antepartum hemorrhage?"
	label variable CARDIAC_EVER_MHOCCUR				"Cardiac disease?"
	label variable GEST_DIAB_RPORRES				"Gestational diabetes?"
	label variable HTN_EVER_MHOCCUR					"Chronic Hypertension?"
	label variable LOWBIRTHWT_RPORRES				"Low birth weight (less than 2500 g)?"
	label variable MACROSOMIA_RPORRES				"Macrosomia (birth weight greater than 4000 g)?"
	label variable OLIGOHYDRAMNIOS_RPORRES			"Oligohydramnios (too little amniotic fluid)?"
	label variable PREECLAMPSIA_RPORRES				"Preeclampsia/eclampsia"
	label variable PREMATURE_RUPTURE_RPORRES		"Premature rupture of membranes (before labor began)?"
	label variable PRETERM_RPORRES					"Preterm delivery (delivery occuring between 20-37 weeks GA)?"
	label variable UNPL_CESARIAN_PROCCUR			"Unplanned Cesarean delivery?"
	label variable DIABETES_EVER_MHOCCUR			"Diabetes mellitus (pre-existing/chronic diabetes)?"
	label variable PPH_RPORRES						"During previous pregnancies, did you experience postpartum hemorrhage?"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(OBSSTDAT, "MDY") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	*sort CASEID visit_date
	sort SUBJID visit_date
	*bysort CASEID (visit_date): gen anc_visit_num=_n 
	bysort SUBJID (visit_date): gen anc_visit_num=_n
	*bysort CASEID (visit_date): gen anc_visit_tot=_N //total number of anc visits
	bysort SUBJID (visit_date): gen anc_visit_tot=_N //total number of anc visits
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 
	
	 
	 *bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 bysort SUBJID visit_date: gen dup=cond(_N==1,0,_n)
	  duplicates report SUBJID
	  ta dup
	  
	 preserve // preserving previous data set
	
	 keep if dup>0
	 *keep CASEID visit_date dup
	 keep SUBJID visit_date dup
	 export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx" , sheet("MNH04") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID==""
	*reshaping dataset from long to wide
	reshape wide visit_date PREGNANCY_ID OBSSTDAT ANC_VISIT_N ANC_N_1 PATIENT_DSDECOD DTHDAT PRG_DSDECOD ///
	PRG_DSSTDAT PRG_DSSTERM PIH_MHOCCUR PIH_MHSTDAT PIH_MHTERM  HIV_MHOCCUR ///
	SYPH_MHOCCUR MALARIA_EVER_MHOCCUR DX_OTHR_PG_MHOCCUR DX_OTHR_LAST_VISIT_MHOCCUR ///
	FOLIC_ACID_CMOCCUR IRON_CMOCCUR CALCIUM_CMOCCUR ///
	MICRONUTRIENT_CMOCCUR ANTHELMINTHIC_CMOCCUR ///
	APH_RPORRES CARDIAC_EVER_MHOCCUR GEST_DIAB_RPORRES HTN_EVER_MHOCCUR LOWBIRTHWT_RPORRES ///
	MACROSOMIA_RPORRES OLIGOHYDRAMNIOS_RPORRES PREMATURE_RUPTURE_RPORRES PRETERM_RPORRES ///
	UNPL_CESARIAN_PROCCUR DIABETES_EVER_MHOCCUR PPH_RPORRES PREECLAMPSIA_RPORRES, i(SUBJID)  j(anc_visit_num)  // not sure if this is the right way to call all variables

	*adding back variable label to wide dataset 
	foreach s in OBSSTDAT ANC_VISIT_N ANC_N_1 PATIENT_DSDECOD DTHDAT PRG_DSDECOD ///
	PRG_DSSTDAT PRG_DSSTERM PIH_MHOCCUR PIH_MHSTDAT PIH_MHTERM  HIV_MHOCCUR ///
	SYPH_MHOCCUR MALARIA_EVER_MHOCCUR DX_OTHR_PG_MHOCCUR DX_OTHR_LAST_VISIT_MHOCCUR ///
	FOLIC_ACID_CMOCCUR IRON_CMOCCUR CALCIUM_CMOCCUR ///
	MICRONUTRIENT_CMOCCUR ANTHELMINTHIC_CMOCCUR ///
	APH_RPORRES CARDIAC_EVER_MHOCCUR GEST_DIAB_RPORRES HTN_EVER_MHOCCUR LOWBIRTHWT_RPORRES ///
	MACROSOMIA_RPORRES OLIGOHYDRAMNIOS_RPORRES PREMATURE_RUPTURE_RPORRES PRETERM_RPORRES ///
	UNPL_CESARIAN_PROCCUR DIABETES_EVER_MHOCCUR PPH_RPORRES PREECLAMPSIA_RPORRES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M04 prefix (besides CASEID/SUBJID)
	foreach var of varlist _all {
	rename `var'  M04_`var'
	}
	
	*rename M04_CASEID CASEID
	rename M04_SUBJID SUBJID
	
	*generating flag variable for MNH04 
	gen FLAG_M04=1
	
	*Saving as temporary file for merge later
	tempfile mnh04
	*sort CASEID
	sort SUBJID
	save mnh04,replace

***********************************************
**MNH05 - Maternal Anthropometry 
import delimited using "MNH05_nov_2021.csv", clear

rename *, upper
*CASEID
keep SUBJID ANT_PEDAT ANT_VISIT_N WEIGHT_PEPERF WEIGHT_PERES HEIGHT_PEPERF HEIGHT_PERES MUAC_PEPERF MUAC_PERES 
*ANT_VISIT_N
 
 *Labeling Variables
	label variable ANT_PEDAT	"Date of anthropometric assessment"
	label variable ANT_VISIT_N	"Indicate visit when the anthropometric measurements were collected."
	label variable WEIGHT_PEPERF "Was the woman's weight measured?"
	label variable WEIGHT_PERES	 "Record weight"
	label variable HEIGHT_PEPERF "Was the woman's height measured?"
	label variable HEIGHT_PERES	 "Record height"
	label variable MUAC_PEPERF	"Was Mid-Upper Arm Circumference measured?"
	label variable MUAC_PERES	"Record MUAC"
	
	*ANT_VISIT_N not in dataset 
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	strdate ANT_PEDAT ,s("dmy") y(2050) f(%dDmCY)
	format %td ANT_PEDAT

	gen visit_date= ANT_PEDAT //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	*sort CASEID visit_date
	sort SUBJID visit_date
	*bysort CASEID (visit_date): gen ant_visit_num=_n 
	bysort SUBJID (visit_date): gen ant_visit_num=_n 
	*bysort CASEID (visit_date): gen ant_visit_tot=_N //total number of anc visits
	bysort SUBJID (visit_date): gen ant_visit_tot=_N //total number of anc visits
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 *bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 bysort SUBJID visit_date: gen dup=cond(_N==1,0,_n)
	 
	 ************no duplicates found
	 
	 duplicates report SUBJID
	 ta dup
	 *preserve // preserving previous data set
	
	 *keep if dup>0
	 *keep CASEID visit_date dup
	 *keep SUBJID visit_date dup
	 *export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH05") firstrow(variables) sheetmodify
	 *restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID==""
	
	*reshaping dataset from long to wide
	*reshape wide visit_date ANT_PEDAT WEIGHT_PEPERF WEIGHT_PERES HEIGHT_PEPERF ///
	*HEIGHT_PERES MUAC_PEPERF MUAC_PERES, i(SUBJID)  j(ant_visit_num) 
    
	***** ANT_VISIT_N is also not constant with SUBJID 
	reshape wide ANT_VISIT_N visit_date ANT_PEDAT WEIGHT_PEPERF  WEIGHT_PERES HEIGHT_PEPERF HEIGHT_PERES MUAC_PEPERF MUAC_PERES , i(SUBJID) j(ant_visit_num)
	
	*adding back variable label to wide dataset 
	foreach s in ANT_PEDAT WEIGHT_PEPERF WEIGHT_PERES HEIGHT_PEPERF ///
	HEIGHT_PERES MUAC_PEPERF MUAC_PERES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}

	*renaming variables with M05 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M05_`var'
	}
	
	*rename M05_CASEID CASEID
	rename M05_SUBJID SUBJID
	
	*generating flag variable for MNH05 
	gen FLAG_M05=1
	
	*Saving as temporary file for merge later
	tempfile mnh05
	*sort CASEID
	sort SUBJID
	save mnh05,replace
	
	
***********************************************
**MNH06 - Ultrasound ANC
import delimited using "MNH06_Nov_2021.csv", clear

rename *, upper
*CASEID
keep SUBJID US_OHOSTDAT ANC_N_VISIT CRL1_FAORRES ///
	CRL2_FAORRES CRL3_FAORRES CRL_MEAN_FAORRES  BPD_FAORRES ///
	HC_FAORRES AC_FAORRES FL_FAORRES US_GA_WEEKS_AGE US_GA_DAYS_AGE ///
	US_EDD_BRTHDAT SINGLE_FAORRES NOT_SINGLE_FAORRES ///
	ABRUPTION_FAORRES PREVIA_FAORRES
	
	*CAL_GA_WEEKS_AGE CAL_GA_DAYS_AGE CAL_EDD_BRTHDAT
 
 *Labeling Variables
	label variable US_OHOSTDAT			"Date of ultrasound (US)"
	label variable ANC_N_VISIT			"Indicate the ANC visit when this form was completed"
	label variable CRL1_FAORRES			"Record the 1st available crown-rump length measurement"
	label variable CRL2_FAORRES			"Record the 2nd available crown-rump length measurement"	
	label variable CRL3_FAORRES			"Record the 3rd available crown-rump length measurement" 
	label variable CRL_MEAN_FAORRES		"Average crown-rump length measurement"
	label variable BPD_FAORRES			"Record biparietal diameter measurement"
	label variable HC_FAORRES			"Record head circumference measurement"
	label variable AC_FAORRES			"Record abdominal circumference measurement"
	label variable FL_FAORRES			"Record femur length measurement"
	label variable US_GA_WEEKS_AGE		"Gestational age by US (weeks)"
	label variable US_GA_DAYS_AGE		"Gestational age by US (days)"
	label variable US_EDD_BRTHDAT		"EDD by US"
	label variable SINGLE_FAORRES		"Is this a single uterine gestation?"
	label variable NOT_SINGLE_FAORRES 	"Specify # of fetuses visualized"
	label variable ABRUPTION_FAORRES  	"Is there evidence of placental abruption"
	label variable PREVIA_FAORRES		"Is there evidence of placenta previa"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(US_OHOSTDAT, "MDY") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	*sort CASEID visit_date
	sort SUBJID visit_date
	*bysort CASEID (visit_date): gen us_visit_num=_n 
	bysort SUBJID (visit_date): gen us_visit_num=_n
	*bysort CASEID (visit_date): gen us_visit_tot=_N //total number of anc visits
	bysort SUBJID (visit_date): gen us_visit_tot=_N //total number of anc visits

	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 
	 
	 *bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 bysort SUBJID visit_date: gen dup=cond(_N==1,0,_n)
	 
	 duplicates report SUBJID
	 ta dup
	 preserve // preserving previous data set
	
	 keep if dup>0
	 *keep CASEID visit_date dup
	 keep SUBJID visit_date dup
	 export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH06") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	*drop if CASEID==""
	drop if SUBJID==""

	*reshaping dataset from long to wide
	reshape wide visit_date US_OHOSTDAT ANC_N_VISIT CRL1_FAORRES ///
	CRL2_FAORRES CRL3_FAORRES CRL_MEAN_FAORRES  BPD_FAORRES ///
	HC_FAORRES AC_FAORRES FL_FAORRES US_GA_WEEKS_AGE US_GA_DAYS_AGE ///
	US_EDD_BRTHDAT SINGLE_FAORRES NOT_SINGLE_FAORRES ///
	ABRUPTION_FAORRES PREVIA_FAORRES, i(SUBJID)  j(us_visit_num) 

	
	*adding back variable label to wide dataset 
	foreach s in visit_date SUBJID US_OHOSTDAT ANC_N_VISIT CRL1_FAORRES ///
	CRL2_FAORRES CRL3_FAORRES CRL_MEAN_FAORRES  BPD_FAORRES ///
	HC_FAORRES AC_FAORRES FL_FAORRES US_GA_WEEKS_AGE US_GA_DAYS_AGE ///
	US_EDD_BRTHDAT SINGLE_FAORRES NOT_SINGLE_FAORRES ///
	ABRUPTION_FAORRES PREVIA_FAORRES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M06 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M06_`var'
	}
	
	*rename M06_CASEID CASEID
	rename M06_SUBJID SUBJID
	
	*generating flag variable for MNH06 
	gen FLAG_M06=1
	
	*Saving as temporary file for merge later
	tempfile mnh06
	*sort CASEID
	sort SUBJID
	save mnh06, replace
	
***********************************************
**MNH07 - ANC Labs
import delimited using "MNH07_Nov_2021.csv", clear

rename *, upper
*CASEID
keep SUBJID VISIT_OBSSTDAT ANC_N_VISIT CBC_SPCPERF CBC_HB_LBORRES	///
	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_SPCPERF HB_POC_LBORRES	///
	HB_POC_LAST_LBORRES	HB_POC_CHANGE_LBORRES HBA1C_LBORRES FERRITIN_LBORRES ///
	HIV_LBORRES	MALARIA_LBORRES	HEPB_SPCPERF HEPB_LBPERF HEPB_LBORRES HEPC_SPCPERF	///
	HEPC_LBPERF	HEPC_LBORRES UA_SPCPERF UA_PROT_LBPERF ///
	UA_PROT_LBORRES	
 
 *Labeling Variables
	label variable VISIT_OBSSTDAT 			"Date of specimen collection"
	label variable ANC_N_VISIT				"Indicate ANC visit when specimens were collected"
	label variable CBC_SPCPERF				"Was a specimen collected to perform a Complete Blood Count panel?"
	*label variable CBC_LBTEST				"Indicate available CBC results" // multiple response 
	label variable CBC_HB_LBORRES			"Hemoglobin (Hb) result"
	label variable CBC_HCT_LBORRES			"Hematocrit (HCT) result"
	label variable CBC_PLATE_LBORRES 		"Platelets count"
	label variable HB_POC_SPCPERF			"Was a specimen collected for point-of-care hemoglobin (Hb) testing?"
	label variable HB_POC_LBORRES			"Hb result"
	label variable HB_POC_LAST_LBORRES		"Hemoglobin result at last visit"
	label variable HB_POC_CHANGE_LBORRES	"Change in Hemoglobin Hb since last visit"
	label variable HBA1C_LBORRES			"Hemoglobin A1C (HbA1c) test results"
	label variable FERRITIN_LBORRES			"Ferritin result"
	label variable HIV_LBORRES				"HIV result"
	label variable MALARIA_LBORRES			"Malaria test results"
	label variable HEPB_SPCPERF				"Was a specimen collected to perform Hepatitis B test (HBsAG)?"
	label variable HEPB_LBPERF				"Are Hepatitis B test results available (HBsAG)?"
	label variable HEPB_LBORRES				"Hepatitis B test results"
	label variable HEPC_SPCPERF				"Was a specimen collected to perform Hepatitis C (HCV) test?"
	label variable HEPC_LBPERF				"Are Hepatitis C (HCV) test results available?"
	label variable HEPC_LBORRES				"Hepatitis C test results"
	label variable UA_SPCPERF				"Was a specimen collected for any type of urinalysis testing?"
	*label variable UA_LBTEST				"Type of urinalysis test(s) to be performed?" // multiple response
	label variable UA_PROT_LBPERF			"Is proteinuria result available?"
	label variable UA_PROT_LBORRES			"Proteinuria result"
 
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
 
	*format date
	gen visit_date=date(VISIT_OBSSTDAT, "MDY") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	*sort CASEID visit_date
	sort SUBJID visit_date
	*bysort CASEID (visit_date): gen lab_visit_num=_n 
	bysort SUBJID (visit_date): gen lab_visit_num=_n
	*bysort CASEID (visit_date): gen lab_visit_tot=_N //total number of anc visits
    bysort SUBJID (visit_date): gen lab_visit_tot=_N //total number of anc visits
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort SUBJID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 **********No duplicates found
	 
	 duplicates report SUBJID
	 ta dup
	 
	 *preserve // preserving previous data set
	
	 *eep if dup>0
	 *keep SUBJID visit_date dup
	 *export excel using "ReMAPP_Duplicates_18_nov_2021"  , sheet("MNH07") firstrow(variables) sheetmodify
	 *restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if SUBJID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date VISIT_OBSSTDAT ANC_N_VISIT CBC_SPCPERF CBC_HB_LBORRES	///
	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_SPCPERF HB_POC_LBORRES	///
	HB_POC_LAST_LBORRES	HB_POC_CHANGE_LBORRES HBA1C_LBORRES FERRITIN_LBORRES ///
	HIV_LBORRES	MALARIA_LBORRES	HEPB_SPCPERF HEPB_LBPERF HEPB_LBORRES HEPC_SPCPERF	///
	HEPC_LBPERF	HEPC_LBORRES UA_SPCPERF UA_PROT_LBPERF ///
	UA_PROT_LBORRES, i(SUBJID)  j(lab_visit_num) 

	*adding back variable label to wide dataset 
	foreach s in VISIT_OBSSTDAT ANC_N_VISIT CBC_SPCPERF CBC_HB_LBORRES	///
	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_SPCPERF HB_POC_LBORRES	///
	HB_POC_LAST_LBORRES	HB_POC_CHANGE_LBORRES HBA1C_LBORRES FERRITIN_LBORRES ///
	HIV_LBORRES	MALARIA_LBORRES	HEPB_SPCPERF HEPB_LBPERF HEPB_LBORRES HEPC_SPCPERF	///
	HEPC_LBPERF	HEPC_LBORRES UA_SPCPERF	 UA_PROT_LBPERF ///
	UA_PROT_LBORRES	 {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M07 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M07_`var'
	}
	
	rename M07_SUBJID SUBJID
	
	*generating flag variable for MNH07
	gen FLAG_M07=1
	
	*Saving as temporary file for merge later
	tempfile mnh07
	sort SUBJID
	save mnh07, replace

***********************************************
**MNH08 - Diagnostic ANC
import delimited using "MNH08_Nov_2021.csv", clear

rename *, upper

keep SUBJID DIAGNOSTIC_VSDAT ANC_VISIT_N BP1_SYS_VSORRES BP1_DIA_VSORRES ///
BP2_SYS_VSORRES BP2_DIA_VSORRES BP3_SYS_VSORRES BP3_DIA_VSORRES BPAVG_SYS_VSORRES ///
BPAVG_DIA_VSORRES SPHB_LBORRES
 
 *Labeling Variables
	label variable DIAGNOSTIC_VSDAT	 	"Date of Diagnostic Testing"
	label variable ANC_VISIT_N	     	"Indicate visit when the diagnostic measurements were collected."
	label variable BP1_SYS_VSORRES	 	"Systolic blood pressure (1st measurement)"
	label variable BP1_DIA_VSORRES	 	"Diastolic blood pressure (1st measurement)"
	label variable BP2_SYS_VSORRES	 	"Systolic blood pressure (2nd measurement)"
	label variable BP2_DIA_VSORRES	 	"Diastolic blood pressure (2nd measurement"
	label variable BP3_SYS_VSORRES	 	"Systolic blood pressure (3rd measurement)"
	label variable BP3_DIA_VSORRES	 	"Diastolic blood pressure (3rd measurement)"
	label variable BPAVG_SYS_VSORRES	"Average systolic BP"
	label variable BPAVG_DIA_VSORRES	"Average diastolic BP"
	label variable SPHB_LBORRES		    "SpHb result"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(DIAGNOSTIC_VSDAT, "MDY") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	sort SUBJID visit_date
	bysort SUBJID (visit_date): gen bp_visit_num=_n 
	bysort SUBJID (visit_date): gen bp_visit_tot=_N //total number of anc visits
	
	
	********************
	*checking duplicates - this will be caseid and visit date as we expect duplicates of subjectid
	 bysort SUBJID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 *****No duplicates found
	 
	 duplicates report SUBJID
	 ta dup
	 
	 *preserve // preserving previous data set
	
	 *keep if dup>0
	 *keep SUBJID visit_date dup
	 *export excel using "ReMAPP_Duplicates_18_nov_2021.xlsx"  , sheet("MNH08") firstrow(variables) sheetmodify
	 *restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if SUBJID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date DIAGNOSTIC_VSDAT ANC_VISIT_N BP1_SYS_VSORRES BP1_DIA_VSORRES ///
	BP2_SYS_VSORRES BP2_DIA_VSORRES BP3_SYS_VSORRES BP3_DIA_VSORRES BPAVG_SYS_VSORRES ///
	BPAVG_DIA_VSORRES SPHB_LBORRES, i(SUBJID)  j(bp_visit_num)  

	*adding back variable label to wide dataset 
	foreach s in DIAGNOSTIC_VSDAT ANC_VISIT_N BP1_SYS_VSORRES BP1_DIA_VSORRES ///
	BP2_SYS_VSORRES BP2_DIA_VSORRES BP3_SYS_VSORRES BP3_DIA_VSORRES BPAVG_SYS_VSORRES ///
	BPAVG_DIA_VSORRES SPHB_LBORRES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M08 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M08_`var'
	}
	
	rename M08_SUBJID SUBJID
	
	*generating flag variable for MNH08 
	gen FLAG_M08=1
	
	*Saving as temporary file for merge later
	tempfile mnh08
	sort SUBJID
	save mnh08, replace 
	
*********************************************************
**MNH11 - labor and delivery 

import delimited using "MNH11.csv", clear

rename *, upper

keep CASEID MAT_LD_OHOSTDAT ANC_TOT_VISTS GEST_DIAB_MHOCCUR ANEMIA_MHOCCUR  ///
	HB_LBPERF HB_LBORRES MALARIA_MHOCCUR HIV_MHOCCUR TB_MHOCCUR HEPB_MHOCCUR SYPH_MHOCCUR ///	
	LABOR_MHSTDAT INDUCED_PROCCUR MULTI_BIRTH_FAORRES INFANTS_FAORRES ///
	INF_1_DSSTDAT INF_1_DELIVERY_PRROUTE INF_1_DSTERM ///
	INF_2_DSSTDAT INF_2_DELIVERY_PRROUTE INF_2_DSTERM ///
	PI_HTN_POST_MHOCCUR RUPT_UTERUS_CEOCCUR	APH_CEOCCUR	PPH_CEOCCUR	PPH_ESTIMATE_FASTAT	   ///
	PPH_ESTIMATE_FAORRES PPH_TRNSFSN_PROCCUR MAT_DSTERM	TRANSFER_OHOLOC	TRANSFER_OHOENDAT  ///
	DEST_DISCHARGE_OHOLOC MAT_DEATH_DTHDAT MAT_DEATH_DSSTTIM MAT_DEATH_DDORRES	
	
	*MAT_LD_OHOSTDAT - different in Ghana - in Ghana: mat_ld_obsloc.type_label
	*inf_3_* and inf_4_ not in ghana
	
	

*Labeling Variables
	label variable MAT_LD_OHOSTDAT			"Date of admission for delivery"
	*label variable MAT_LD_OHOLOC			"Delivery location"
	label variable ANC_TOT_VISTS			"Total number of ANC visits during this pregnancy"
	*label variable PI_HTN_MHOCCUR			"Was mother diagnosed with any of the following types of gestational/pregnancy-induced hypertension (PIH)?" - multiple observations
	*label variable PI_HTN_SRCE				"Data source" - check box
	*label variable PI_HTN_PROCCUR			"Did the mother receive any of the following treatments for PIH?" - multiple observations
	label variable GEST_DIAB_MHOCCUR 		"Was mother diagnosed with gestational diabetes?"
	*label variable GEST_DIAB_SRCE			"Data source" - check box
	label variable ANEMIA_MHOCCUR			"Was mother diagnosed with anemia?"
	*label variable ANEMIA_SRCE				"Data source of anemia diagnosis" - check box
	label variable HB_LBPERF				"Is hemoglobin at time of anemia diagnosis available?"
	label variable HB_LBORRES				"Record hemoglobin"
	label variable MALARIA_MHOCCUR			"Was mother diagnosed with malaria?"
	label variable HIV_MHOCCUR				"Was mother diagnosed with HIV?"
	label variable TB_MHOCCUR				"Was mother diagnosed with TB?"
	label variable HEPB_MHOCCUR				"Was mother diagnosed with Hepatitis B (HBV)?"
	label variable SYPH_MHOCCUR				"Was mother diagnosed with syphilis?"
	*label variable INFECT_CEOCCUR			"Did mother have any other signs/symptoms of infection?" - check box
	*label variable ORG_FAIL_MHOCCUR		"Did the mother experience any type of organ failure?" - check box
	label variable LABOR_MHSTDAT			"Date of labor onset"
	label variable INDUCED_PROCCUR			"Was labor induced?"
	label variable MULTI_BIRTH_FAORRES		"Was this a multiple birth?"
	label variable INFANTS_FAORRES			"Specify number of infants"
	label variable INF_1_DSSTDAT			"Date of delivery"
	label variable INF_1_DELIVERY_PRROUTE	"Delivery method"
	label variable INF_1_DSTERM				"Birth outcome"
	label variable INF_2_DSSTDAT			"Date of delivery"
	label variable INF_2_DELIVERY_PRROUTE	"Delivery method"
	label variable INF_2_DSTERM				"Birth outcome"
	*label variable INF_3_DSSTDAT			"Date of delivery"
	*label variable INF_3_DELIVERY_PRROUTE	"Delivery method"
	*label variable INF_3_DSTERM				"Birth outcome"
	*label variable INF_4_DSSTDAT			"Date of delivery"
	*label variable INF_4_DELIVERY_PRROUTE	"Delivery method"
	*label variable INF_4_DSTERM				"Birth outcome"
	label variable PI_HTN_POST_MHOCCUR		"Did mother develop pregnancy-induced hypertension after admission for L&D?"
	*label variable PI_HTN_POST_CMOCCUR		"Were any of the the following medications provided to treat PIH?" - check box
	label variable RUPT_UTERUS_CEOCCUR		"Did mother experience a ruptured uterus (repaired/hysterectomy)?"
	label variable APH_CEOCCUR				"Did mother experience antepartum hemorrhage (APH)?"
	*label variable APH_FAORRES				"Select complications that contributed to APH" - check box
	label variable PPH_CEOCCUR				"Did mother experience postpartum hemorrhage (PPH)?"
	*label variable PPH_FAORRES				"Select complications that contributed to PPH." - check box
	label variable PPH_ESTIMATE_FASTAT		"Is estimated blood loss available?"
	label variable PPH_ESTIMATE_FAORRES		"Estimated blood loss"
	label variable PPH_TRNSFSN_PROCCUR	    "Did mother have a transfusion?"
	*label variable POST_DEL_SS_CEOCCUR	    "Did the mother have any of the following signs of complication during or after delivery?" - check box
	*label variable POST_DEL_INF_CEOCCUR	"Was the mother diagnosed with any of the following infections during or after delivery?" - check box
	label variable MAT_DSTERM				"Mother's status after delivery"
	label variable TRANSFER_OHOLOC			"Where was mother transferred for higher-level care?"
	label variable TRANSFER_OHOENDAT		"Date of discharge from delivery facility"
	label variable DEST_DISCHARGE_OHOLOC	"Planned destination after discharge"
	label variable MAT_DEATH_DTHDAT			"Date of death"
	label variable MAT_DEATH_DSSTTIM		"Time of death"
	label variable MAT_DEATH_DDORRES		"Primary cause of death"

	
	********************
	*checking duplicates
     bysort CASEID:  gen dup = cond(_N==1,0,_n)
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID MAT_LD_OHOSTDAT dup
	 export excel using "ReMAPP Duplicates `today'.xlsx"  , sheet("MNH11") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	**********************
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*renaming variables with M11 prefix
	foreach var of varlist _all {
	rename `var'  M11_`var'
	}
	
	rename M11_CASEID CASEID
	
	*generating flag variable for MNH11 
	gen FLAG_M11=1
	
	*Saving as temporary file for merge later
	tempfile mnh11
	sort CASEID
	save `mnh11'

**************************************************
*MNH13 - "Maternal PNC Clinical Status"

	import delimited using "MNH13.csv", clear

	rename *, upper
	
	keep CASEID VISIT_OBSSTDAT PNC_N_VISIT PATIENT_DSDECOD POC_HB_VSSTAT POC_HB_VSORRES	///
	MALARIA_MHOCCUR HIV_MHOCCUR PULM_EDEMA_MHOCCUR PULM_EDEMA_MHSTDAT STROKE_MHOCCUR    ///	
	STROKE_MHSTDAT CARE_OHOYN HOSP_LAST_VISIT_OHOOCCUR MATERNAL_DSDECOD MAT_DEATH_DTHDAT ///
	MAT_DDORRES BIRTH_COMP_DDORRES INFECTION_DDORRES OTHR_DDORRES 
	
	
	*Label Variables
	label variable VISIT_OBSSTDAT			"Interview date"
	label variable PNC_N_VISIT				"Timing of visit"
	label variable PATIENT_DSDECOD			"Maternal status at the time of visit"
	label variable POC_HB_VSSTAT			"Was point-of-care hemoglobin measured during this study visit?"
	label variable POC_HB_VSORRES			"Hb result"
	*label variable POST_DEL_INF_MHOCCUR	"Was the mother diagnosed with any of the following infections?" - check box
	label variable MALARIA_MHOCCUR			"Was mother diagnosed with malaria?"
	label variable HIV_MHOCCUR				"Was mother diagnosed with HIV?"
	*label variable BIRTH_COMPL_MHTERM		"Was the mother diagnosed with any of the following birth complications?" - check box
	*label variable ORG_FAIL_MHOCCUR		"Did the mother experience any type of organ failure?" - check box
	label variable PULM_EDEMA_MHOCCUR		"Was mother diagnosed with pulmonary edema?"
	label variable PULM_EDEMA_MHSTDAT		"Date of diagnosis"
	label variable STROKE_MHOCCUR			"Was mother diagnosed with stroke?"
	label variable STROKE_MHSTDAT			"Date of diagnosis"
	label variable CARE_OHOYN				"Did the mother receive care for an unexpected medical issue since the last study visit?"
	label variable HOSP_LAST_VISIT_OHOOCCUR	"Was the mother hospitalized for this illness or medical issue?"
	label variable MATERNAL_DSDECOD			"What was mother's end-of-visit status?"
	label variable MAT_DEATH_DTHDAT			"Date of death"
	label variable MAT_DDORRES				"Primary cause of death"
	label variable BIRTH_COMP_DDORRES		"Specify birth complication"
	label variable INFECTION_DDORRES		"Specify type of infection"
	label variable OTHR_DDORRES				"Other primary cause of death?"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(VISIT_OBSSTDAT, "YMD") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	sort CASEID visit_date
	bysort CASEID (visit_date): gen pnc_visit_num=_n 
	bysort CASEID (visit_date): gen pnc_visit_tot=_N //total number of anc visits
	
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID visit_date dup
	 export excel using "ReMAPP Duplicates `today'.xlsx"  , sheet("MNH13") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date VISIT_OBSSTDAT PNC_N_VISIT PATIENT_DSDECOD POC_HB_VSSTAT POC_HB_VSORRES	///
	MALARIA_MHOCCUR HIV_MHOCCUR PULM_EDEMA_MHOCCUR PULM_EDEMA_MHSTDAT STROKE_MHOCCUR    ///	
	STROKE_MHSTDAT CARE_OHOYN HOSP_LAST_VISIT_OHOOCCUR MATERNAL_DSDECOD MAT_DEATH_DTHDAT ///
	MAT_DDORRES BIRTH_COMP_DDORRES INFECTION_DDORRES OTHR_DDORRES  , i(CASEID)  j(pnc_visit_num)  

	*adding back variable label to wide dataset 
	foreach s in VISIT_OBSSTDAT PNC_N_VISIT PATIENT_DSDECOD POC_HB_VSSTAT POC_HB_VSORRES	///
	MALARIA_MHOCCUR HIV_MHOCCUR PULM_EDEMA_MHOCCUR PULM_EDEMA_MHSTDAT STROKE_MHOCCUR    ///	
	STROKE_MHSTDAT CARE_OHOYN HOSP_LAST_VISIT_OHOOCCUR MATERNAL_DSDECOD MAT_DEATH_DTHDAT ///
	MAT_DDORRES BIRTH_COMP_DDORRES INFECTION_DDORRES OTHR_DDORRES   {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M13 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M13_`var'
	}
	
	rename M13_CASEID CASEID
	
	*generating flag variable for MNH13 
	gen FLAG_M13=1
	
	*Saving as temporary file for merge later
	tempfile mnh13
	sort CASEID
	save `mnh13'

	
**************************************************
*MNH14 - "Maternal PNC Labs"

	import delimited using "MNH14.csv", clear

	rename *, upper
	
	keep CASEID VISIT_OBSSTDAT HB_POC_SPCPERF HB_POC_LBPERF HB_POC_LBORRES
	
	*Label variable
	label variable VISIT_OBSSTDAT	"Date of specimen collection"
	label variable HB_POC_SPCPERF	"Was a specimen collected for hemoglobin (Hb) testing?"
	label variable HB_POC_LBPERF	"Are Hb results available?"
	label variable HB_POC_LBORRES	"Hb result"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(VISIT_OBSSTDAT, "YMD") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	sort CASEID visit_date
	bysort CASEID (visit_date): gen pnc_lab_visit_num=_n 
	bysort CASEID (visit_date): gen pnc_lab_visit_tot=_N //total number of anc visits
	
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID visit_date dup
	 export excel using "ReMAPP Duplicates `today'.xlsx"  , sheet("MNH14") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date VISIT_OBSSTDAT HB_POC_SPCPERF HB_POC_LBPERF HB_POC_LBORRES, i(CASEID)  j(pnc_lab_visit_num)  
	
	*adding back variable label to wide dataset 
	foreach s in visit_date VISIT_OBSSTDAT HB_POC_SPCPERF HB_POC_LBPERF HB_POC_LBORRES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	
	*renaming variables with M14 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M14_`var'
	}
	
	rename M14_CASEID CASEID
	
	*generating flag variable for MNH13 
	gen FLAG_M14=1
	
	*Saving as temporary file for merge later
	tempfile mnh14
	sort CASEID
	save `mnh14'


***********************************************
**MNH17 - unplanned ANC care

import delimited using "MNH17.csv", clear

	rename *, upper

	keep CASEID OBSSTDAT UNPLANNED_VISDAT CARE_OHOLOC MAT_ARRIVAL_DSTERM BP_VSSTAT	BP_SYS_VSORRES	BP_DIA_VSORRES	///
	BP_GT120_VSSTAT	BP_GT120_SYS_VSORRES BP_GT120_DIA_VSORRES BP_GT90_VSSTAT BP_GT90_SYS_VSORRES BP_GT90_DIA_VSORRES	///
	ULTRASOUND_PROCCUR	ULTRASOUND_PRSTDAT ULTRASOUND_FAORRES US_GA_WKS_AGE US_GA_DAYS_AGE CBC_SPCPERF CBC_LBDAT	///
	CBC_HB_LBORRES	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_LBPERF	HB_POC_LBMETHOD	HB_POC_LBTSTDAT	HB_POC_LBORRES UA_SPCPERF	///
	UA_DIP_LBTSTDAT	UA_DIP_LBORRES	UA_PROT_LBORRES	CREAT_LBPERF CREAT_LBDAT CREAT_LBORRESU	CREAT_MGDL_LBORRES CREAT_UMOLL_LBORRES	///
	HEPB_SPCPERF HEPB_LBORRES HEPC_SPCPERF HEPC_LBORRES	PRIMARY_MHTERM EARLY_LOSS_MHTERM  PREG_DSTERM PREG_FAORRES	///
	VISIT_FAORRES ADMIT_DSTERM	
	
	*ULTRASOUND_DOC_DSDECOD - not in ghana dataset
	*DTHDAT_YN - not in ghana dataset
	*DTHDAT - not in Ghana dataset - death not recorded in MNH17.

*Label Variable
	label variable OBSSTDAT					"Date of data collection"
	label variable UNPLANNED_VISDAT			"Specify date"
	label variable CARE_OHOLOC				"Location of unplanned visit"
	label variable MAT_ARRIVAL_DSTERM		"Maternal status upon arrival for unplanned care"
	label variable BP_VSSTAT				"Was blood pressure (BP) documented while receiving unplanned care?"
	label variable BP_SYS_VSORRES			"Systolic BP"
	label variable BP_DIA_VSORRES			"Diastolic BP"
	label variable BP_GT120_VSSTAT			"Were any additional BP measurements with systolic >120 mm Hg documented while receiving unplanned care?"
	label variable BP_GT120_SYS_VSORRES		"Systolic BP"
	label variable BP_GT120_DIA_VSORRES		"Diastolic BP"
	label variable BP_GT90_VSSTAT			"Were any additional BP measurements with diastolic > 90 mm Hg documented while receiving unplanned care?"
	label variable BP_GT90_SYS_VSORRES		"Systolic BP"
	label variable BP_GT90_DIA_VSORRES		"Diastolic BP"
	label variable ULTRASOUND_PROCCUR		"Was an ultrasound exam performed while receiving unplanned care?"
	label variable ULTRASOUND_PRSTDAT		"Specify date of ultrasound"
	label variable ULTRASOUND_FAORRES		"Ultrasound results"
	*label variable ULTRASOUND_DOC_DSDECOD	"Do the ultrasound results include documentation of gestational age?"
	label variable US_GA_WKS_AGE			"GA in weeks"
	label variable US_GA_DAYS_AGE			"GA in days"
	label variable CBC_SPCPERF				"Was complete blood count (CBC) test conducted while receiving unplanned care?"
	label variable CBC_LBDAT				"Specify CBC date"
	*label variable CBC_LBTEST				"Indicate CBC results available in the facility-based or participant-held records." - check box
	label variable CBC_HB_LBORRES			"Hemoglobin (Hb) result"
	label variable CBC_HCT_LBORRES			"Hematocrit (HCT) result"
	label variable CBC_PLATE_LBORRES		"Platelets count"
	label variable HB_POC_LBPERF			"Was hemoglobin measured by hemocue, Masimo, or any other point-of-care method while receiving unplanned care?"
	label variable HB_POC_LBMETHOD			"Specify type of machine used for Hb testing."
	label variable HB_POC_LBTSTDAT			"Hb test date"
	label variable HB_POC_LBORRES			"Hb result"
	label variable UA_SPCPERF				"Was any type of urinalysis performed while receiving unplanned care?"
	label variable UA_DIP_LBTSTDAT			"Urinalysis test date"
	*label variable UA_LBTEST				"Type of urinalysis test(s) results available" - check box
	label variable UA_DIP_LBORRES			"Bacteriuria result"
	label variable UA_PROT_LBORRES			"Proteinuria result"
	label variable CREAT_LBPERF				"Was serum creatinine measured while receiving unplanned care?"
	label variable CREAT_LBDAT				"Serum creatinine test date"
	label variable CREAT_LBORRESU			"Specify serum creatinine measurement unit"
	label variable CREAT_MGDL_LBORRES		"Serum creatinine test results"
	label variable CREAT_UMOLL_LBORRES		"Serum creatinine test results"
	label variable HEPB_SPCPERF				"Was mother tested for Hepatitis B test (HBsAG) while receiving unplanned care?"
	label variable HEPB_LBORRES				"Hepatitis B test results"
	label variable HEPC_SPCPERF				"Was mother tested for Hepatitis C (HCV) while receiving unplanned care?"
	label variable HEPC_LBORRES				"HCV test result"
	label variable PRIMARY_MHTERM			"Specify primary diagnosis documented in the record while receiving unplanned care."
	label variable EARLY_LOSS_MHTERM		"Specify type of early pregnancy loss"
	*label variable INFECTION_MHTERM		"Specify type of infection" - check box
	*label variable HTN_MHTERM				"Specify type of hypertensive disorder" - check box
	*label variable LD_COMPL_MHTERM			"Specify type of labor and delivery complication" - check box
	*label variable DX_OTHR_MHTERM			"Specify other medical condition" - checkbox
	label variable PREG_DSTERM				"What was mother's pregnancy status at completion of unplanned care at this location?"
	label variable PREG_FAORRES				"Specify pregnancy outcome"
	label variable VISIT_FAORRES			"What was the outcome of the unplanned care at this location?"
	*label variable DTHDAT_YN				"Is date of death known?"
	*label variable DTHDAT					"Date of death"
	label variable ADMIT_DSTERM				"If admitted, status at time of form completion"
	
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
	
	*format date
	gen visit_date=date(OBSSTDAT, "YMD") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	sort CASEID visit_date
	bysort CASEID (visit_date): gen ancu_visit_num=_n 
	bysort CASEID (visit_date): gen ancu_visit_tot=_N //total number of anc visits
	
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID visit_date dup
	 export excel using "ReMAPP Duplicates `today'.xlsx" , sheet("MNH17") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date OBSSTDAT UNPLANNED_VISDAT CARE_OHOLOC MAT_ARRIVAL_DSTERM BP_VSSTAT	BP_SYS_VSORRES	BP_DIA_VSORRES	///
	BP_GT120_VSSTAT	BP_GT120_SYS_VSORRES BP_GT120_DIA_VSORRES BP_GT90_VSSTAT BP_GT90_SYS_VSORRES BP_GT90_DIA_VSORRES	///
	ULTRASOUND_PROCCUR	ULTRASOUND_PRSTDAT ULTRASOUND_FAORRES US_GA_WKS_AGE US_GA_DAYS_AGE CBC_SPCPERF CBC_LBDAT	///
	CBC_HB_LBORRES	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_LBPERF	HB_POC_LBMETHOD	HB_POC_LBTSTDAT	HB_POC_LBORRES UA_SPCPERF	///
	UA_DIP_LBTSTDAT	UA_DIP_LBORRES	UA_PROT_LBORRES	CREAT_LBPERF CREAT_LBDAT CREAT_LBORRESU	CREAT_MGDL_LBORRES CREAT_UMOLL_LBORRES	///
	HEPB_SPCPERF HEPB_LBORRES HEPC_SPCPERF HEPC_LBORRES	PRIMARY_MHTERM EARLY_LOSS_MHTERM  PREG_DSTERM PREG_FAORRES	///
	VISIT_FAORRES ADMIT_DSTERM	, i(CASEID)  j(ancu_visit_num)  

	*adding back variable label to wide dataset 
	foreach s in OBSSTDAT UNPLANNED_VISDAT CARE_OHOLOC MAT_ARRIVAL_DSTERM BP_VSSTAT	BP_SYS_VSORRES	BP_DIA_VSORRES	///
	BP_GT120_VSSTAT	BP_GT120_SYS_VSORRES BP_GT120_DIA_VSORRES BP_GT90_VSSTAT BP_GT90_SYS_VSORRES BP_GT90_DIA_VSORRES	///
	ULTRASOUND_PROCCUR	ULTRASOUND_PRSTDAT ULTRASOUND_FAORRES US_GA_WKS_AGE US_GA_DAYS_AGE CBC_SPCPERF CBC_LBDAT	///
	CBC_HB_LBORRES	CBC_HCT_LBORRES	CBC_PLATE_LBORRES HB_POC_LBPERF	HB_POC_LBMETHOD	HB_POC_LBTSTDAT	HB_POC_LBORRES UA_SPCPERF	///
	UA_DIP_LBTSTDAT	UA_DIP_LBORRES	UA_PROT_LBORRES	CREAT_LBPERF CREAT_LBDAT CREAT_LBORRESU	CREAT_MGDL_LBORRES CREAT_UMOLL_LBORRES	///
	HEPB_SPCPERF HEPB_LBORRES HEPC_SPCPERF HEPC_LBORRES	PRIMARY_MHTERM EARLY_LOSS_MHTERM  PREG_DSTERM PREG_FAORRES	///
	VISIT_FAORRES ADMIT_DSTERM	 {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}
	
	*renaming variables with M17 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M17_`var'
	}
	
	rename M17_CASEID CASEID
	
	*generating flag variable for MNH17 
	gen FLAG_M17=1
	
	*Saving as temporary file for merge later
	tempfile mnh17
	sort CASEID
	save `mnh17'
	
	
********************************************
**MNH18 - unplanned maternal pnc

import delimited using "MNH18.csv", clear

	rename *, upper
	
	keep CASEID OBSSTDAT ADMIT_DSTERM MAT_ARRIVAL_DSTERM PRIMARY_MHTERM ///
		 VISIT_FAORRES CBC_SPCPERF CBC_LBDAT CBC_HB_LBORRES CBC_HCT_LBORRES ///
		 HB_POC_LBPERF HB_POC_LBMETHOD HB_POC_LBTSTDAT HB_POC_LBORRES
		 
		 *DTHDAT not in Ghana dataset
		 
	*Label Variables  
		label variable OBSSTDAT				"Date of data collection"
		label variable ADMIT_DSTERM			"If admitted, status at time of form completion"
		*label variable BIRTH_COMPL_MHTERM	"Specify type of birth complication" - check box
		*label variable DTHDAT				"Date of death"
	    *label variable INFECTION_MHTERM	"Specify type of infection" - check box
		label variable MAT_ARRIVAL_DSTERM	"Maternal status upon arrival for unplanned care"
		label variable PRIMARY_MHTERM		"Specify primary diagnosis documented in the record while receiving unplanned care."
		label variable VISIT_FAORRES		"What was the outcome of the unplanned care at this location?"
		label variable CBC_SPCPERF			"Was complete blood count (CBC) test conducted while receiving unplanned care?"
		label variable CBC_LBDAT			"Specify CBC date"
		*label variable CBC_LBTEST	        "Indicate CBC results available in the facility-based or participant-held records." - check box
		label variable CBC_HB_LBORRES		"Hemoglobin (Hb) result"
		label variable CBC_HCT_LBORRES		"Hematocrit (HCT) result"
		label variable HB_POC_LBPERF		"Was hemoglobin measured by hemocue, Masimo, or any other point-of-care?"
		label variable HB_POC_LBMETHOD		"Specify type of machine used for Hb testing."
		label variable HB_POC_LBTSTDAT		"Hb test date"
		label variable HB_POC_LBORRES		"Hb result" 
		*label variable ORGAN_FAIL_MHTERM	"Specify type of organ failure" - check box
		*label variable DX_OTHR_MHTERM		"Specify other medical condition" - check box
		
	*saving labels
	foreach v of varlist _all {
    local lbl`v' "`: var label `v''"
}
		
	*format date
	gen visit_date=date(OBSSTDAT, "YMD") //need to look at what date format is actually
	format visit_date %d
	
	*creating visit number based on date
	sort CASEID visit_date
	bysort CASEID (visit_date): gen pncu_visit_num=_n 
	bysort CASEID (visit_date): gen pncu_visit_tot=_N //total number of anc visits
	
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort CASEID visit_date: gen dup=cond(_N==1,0,_n) 
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID visit_date dup
	 export excel using "ReMAPP Duplicates `today'.xlsx" , sheet("MNH18") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*reshaping dataset from long to wide
	reshape wide visit_date OBSSTDAT ADMIT_DSTERM MAT_ARRIVAL_DSTERM PRIMARY_MHTERM ///
		 VISIT_FAORRES CBC_SPCPERF CBC_LBDAT CBC_HB_LBORRES CBC_HCT_LBORRES ///
		 HB_POC_LBPERF HB_POC_LBMETHOD HB_POC_LBTSTDAT HB_POC_LBORRES, i(CASEID)  j(pncu_visit_num)  // not sure if this is the right way to call all variables

		 
	*adding back variable label to wide dataset 
	foreach s in visit_date OBSSTDAT ADMIT_DSTERM MAT_ARRIVAL_DSTERM PRIMARY_MHTERM ///
		 VISIT_FAORRES CBC_SPCPERF CBC_LBDAT CBC_HB_LBORRES CBC_HCT_LBORRES ///
		 HB_POC_LBPERF HB_POC_LBMETHOD HB_POC_LBTSTDAT HB_POC_LBORRES {
    foreach v of var `s'* {
        label var `v' "`lbl`s''"
    }
}	 
		 
	*renaming variables with M18 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M18_`var'
	}
	
	rename M18_CASEID CASEID
	
	*generating flag variable for MNH18 
	gen FLAG_M18=1
	
	*Saving as temporary file for merge later
	tempfile mnh18
	sort CASEID
	save `mnh18'
	
*****************************
*MNH25

import delimited using "MNH25.csv", clear

	rename *, upper
	
	keep CASEID CLOSE_DSDECOD CLOSE_DSSTDAT
	
	*Label Variable
	label variable CLOSE_DSSTDAT "Date of close out"
	label variable CLOSE_DSDECOD "Record the primary reaosn for close-out"
	
	********************
	*checking duplicates - this will be subjectid and visit date as we expect duplicates of subjectid
	 bysort CASEID: gen dup=cond(_N==1,0,_n) 
	 
	 preserve // preserving previous data set
	
	 keep if dup>0
	 keep CASEID CLOSE_DSSTDAT dup
	 export excel using "ReMAPP Duplicates `today'.xlsx" , sheet("MNH25") firstrow(variables) sheetmodify
	 restore // restoring old dataset
	********************** 
	
	*keeping only 1 observation per ID per visit
	keep if dup<=1 // this should keep all those that don't have duplicates and 1 copy of ID with duplicate visit. 
	drop dup
	drop if CASEID==""
	
	*renaming variables with M25 prefix (besides CASEID)
	foreach var of varlist _all {
	rename `var'  M25_`var'
	}
	
	rename M25_CASEID CASEID
	
	*generating flag variable for MNH25 
	gen FLAG_M25=1
	
	*Saving as temporary file for merge later
	tempfile mnh25
	sort CASEID
	save `mnh25'
	
*************************************************
*Merging all forms into single dataset 

	use mnh01, clear 
	
	merge 1:1 SUBJID using mnh02 
		ren _merge mer02
		
	merge 1:1 SUBJID using mnh03a 
	    ren _merge mer03a 
		
	merge 1:1 SUBJID using mnh03b 
		ren _merge mer3b
	    
	merge 1:1 SUBJID using mnh04 
		ren _merge mer04
        
	merge 1:1 SUBJID using mnh05 
		ren _merge mer05
		
	merge 1:1 SUBJID using mnh06 
	     ren _merge mer06 
		 
	merge 1:1 SUBJID using mnh07 
		ren _merge mer07
        
	merge 1:1 SUBJID using mnh08 
		ren _merge mer08

	
	merge 1:1 CASEID using `mnh11' 
		drop _merge
		
	merge 1:1 CASEID using `mnh13' 
		drop _merge
		
	merge 1:1 CASEID using `mnh14' 
		drop _merge
		
	merge 1:1 CASEID using `mnh17' 
		drop _merge
		
	merge 1:1 CASEID using `mnh18' 
		drop _merge
		
	merge 1:1 CASEID using `mnh25' 
		drop _merge

*************************************************
*Part 2: Data Cleaning
*************************************************

***************dropping the IDs who did not fill consent

keep if M01_CON_YN_DSDECOD== 1

duplicates report SUBJID


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
	
gen edd_for_missing= M01_EDD_SCDAT if M01_ESTIMATED_EDD_SCDAT== .
format edd_for_missing %d
gen lmp_for_missing= edd_for_missing - 280
format lmp_for_missing %d
gen gest_age_missing= M01_SCRN_OBSSTDAT - lmp_for_missing

gen gest_age_missing1= M01_SCRN_OBSSTDAT - lmp_for_missing

gen gest_age_week =  gest_age_missing/7 
replace gest_age_week=  round(gest_age_week)

gen gest_age_month =  gest_age_missing/30 
replace gest_age_month=  round(gest_age_month)

replace M01_GEST_AGE_WKS_SCORRES= gest_age_week if  M01_GEST_AGE_WKS_SCORRES== .

replace M01_GEST_AGE_MOS_SCORRES= gest_age_month if  M01_GEST_AGE_MOS_SCORRES== .

 
			
*calculating LMP for all participants
gen lmp_cal=.
replace lmp_cal=M01_LMP_SCDAT if(M01_LMP_SCDAT!=.)
replace lmp_cal=M01_SCRN_OBSSTDAT-(M01_GEST_AGE_WKS_SCORRES*7) if(M01_LMP_SCDAT==. & M01_GEST_AGE_MOS_SCORRES ==. )
replace lmp_cal=M01_SCRN_OBSSTDAT-(M01_GEST_AGE_MOS_SCORRES*30.5) if (M01_LMP_SCDAT==. & M01_GEST_AGE_WKS_SCORRES==.)
format lmp_cal %d

*calculating gestage at enrollment for all participants
	*in days
	gen gestage_days_enroll=.
	replace gestage_days_enroll=(M01_SCRN_OBSSTDAT-lmp_cal)
	
	*in trimesters
	gen tri_enroll=.
	replace tri_enroll=1 if(gestage_days_enroll<=91)
	replace tri_enroll=2 if(gestage_days_enroll>91 & gestage_days_enroll<=182)
	replace tri_enroll=3 if(gestage_days_enroll>182 & gestage_days_enroll<=300)

*summarizing gestational age at enrollment
	summ gestage_days_enroll
	tab tri_enroll

 *list CASEID M01_SCRN_OBSSTDAT M01_LMP_SCDAT M01_GEST_AGE_WKS_SCORRES M01_GEST_AGE_MOS_SCORRES lmp_cal gestage_days_enroll if gestage_days_enroll>280

 
*************************************************
*Part 3: Data Checks
*************************************************
 
		 ***Checking Hemoglobin and Gestational Age
		 *******************************************************
		 *reformating data to be long again
		 keep SUBJID M07_visit_date1 M07_visit_date2 M07_visit_date3 M07_visit_date4 M07_CBC_HB_LBORRES1 M07_CBC_HB_LBORRES2 M07_CBC_HB_LBORRES3 M07_CBC_HB_LBORRES4 M07_HB_POC_LBORRES1 M07_HB_POC_LBORRES2 M07_HB_POC_LBORRES3 M07_HB_POC_LBORRES4 M07_lab_visit_tot M08_visit_date1 M08_visit_date2 M08_visit_date3 M08_visit_date4 M08_visit_date5 M08_visit_date6 M08_visit_date7 M08_visit_date8 M08_visit_date9 M08_visit_date10 M08_visit_date11 M08_visit_date12 M08_visit_date13 M08_SPHB_LBORRES1 M08_SPHB_LBORRES2 M08_SPHB_LBORRES3 M08_SPHB_LBORRES4 M08_SPHB_LBORRES5 M08_SPHB_LBORRES6 M08_SPHB_LBORRES7 M08_SPHB_LBORRES8 M08_SPHB_LBORRES9 M08_SPHB_LBORRES10 M08_SPHB_LBORRES11 M08_SPHB_LBORRES12 M08_SPHB_LBORRES13 ///
		 lmp_cal 

		 reshape long M07_visit_date M07_CBC_HB_LBORRES M07_HB_POC_LBORRES M08_visit_date M08_SPHB_LBORRES, i(SUBJID) j(visit_num)  
		 
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
			keep SUBJID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile cbc
			sort SUBJID
			save cbc,replace
			
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
			keep SUBJID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile poc
			sort SUBJID
			save poc, replace
			
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
			keep SUBJID visit_date hemoglobin hem_type lmp_cal
		 
			*Saving as temporary file for append 
			tempfile sphb
			sort SUBJID
			save sphb, replace
			
			restore
			
		****Appending Datasets 
		use cbc, clear 
			
			append using poc 
			append using sphb

		*****Creating Variables
			 *average number of hemoglobin measure per patient 
				bysort SUBJID: gen hem_num=_n 
				bysort SUBJID: gen hem_tot=_N //total number of hemoglobin measures 
				
			 *creating gestational age at visit 
			format visit_date %td
			
			gen gestage=visit_date-lmp_cal
			 
			list if gestage>300 & gestage!=.
			
			replace gestage=. if(gestage>300 & gestage!=.) //9 values changed
			 
			 
				*trimester
				gen tri_lab=.
				replace tri_lab=1 if(gestage<=91)& (gestage!= .)
				replace tri_lab=2 if(gestage>91 & gestage<=182) & (gestage!=.)
				replace tri_lab=3 if(gestage>182 & gestage<=300) & (gestage!= .)
				

			*Anemia 
				*CDC definition
				gen anemia_CDC = .
				replace anemia_CDC=0 if(hemoglobin>=11 & (tri_lab==1 | tri_lab==3) & hemoglobin!=.)
				replace anemia_CDC=0 if(hemoglobin>=10.5 & tri_lab==2 & hemoglobin!=.)
				replace anemia_CDC=1 if(hemoglobin<11 & tri_lab==1)
				replace anemia_CDC=1 if(hemoglobin<10.5 & tri_lab==2)
				replace anemia_CDC=1 if(hemoglobin<11.0 & tri_lab==3)
				
				*WHO
				gen anemia_WHO=.
				replace anemia_WHO=0 if(hemoglobin>=11 & hemoglobin!=.)
				replace anemia_WHO=1 if(hemoglobin<11)
				replace anemia_WHO=2 if(hemoglobin<10)
				replace anemia_WHO=3 if(hemoglobin<7)
				
					*labeling values
						label define who1 0 "Normal Hemoglobin" 1 "Mild Anemia" 2 "Moderate Anemia" 3 "Severe Anemia"
						label values anemia_WHO who1

		******************************************************************	
		*****Code for Log File
		******************************************************************
			capture log close 
			log using "ReMAPP_ANC_Hemoglobin_part_2_14_dec_2021_SUBJID.txt", text  replace
			
			**************checking error in gest age

			
			 list  SUBJID gestage if gestage< 0
			
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
		 twoway (scatter hemoglobin gestage if hem_type=="CBC", color(green)) ///
			 (scatter hemoglobin gestage if hem_type=="POC", color(blue)) ///
			 (scatter hemoglobin gestage if hem_type=="SpHb", color(red)), ///
			 legend(order (1 "CBC" 2 "POC" 3 "SpHb")) xtitle("Gestational Age (days)") ///
			 ytitle("Hemoglobin (g/dL)") title("Scatter Plot of Hemoglobin vs. Gestational Age")
			 graph export scatter_hb_gestage.png, replace 
			
			
			**All Observatons - CBC, POC, SpHb methods
			*histogram
			histogram hemoglobin 
				graph export all_hemoglobin.png,replace  
			
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(0.5) color(green)) ///
			   (histogram hemoglobin  if tri_lab==2, width(0.5) color(blue)) ///
			   (histogram hemoglobin if tri_lab==3, width(0.5) color(red)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				graph export all_hemoglobin_tri1.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
				graph export all_hemoglobin_tri2.png, replace
			 
			**Only CBC
			preserve 
			keep if hem_type=="CBC"
			*histogram - CBC Only
			histogram hemoglobin 
				graph export cbc_hemoglobin.png, replace
			
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(0.5) color(green)) ///
			   (histogram hemoglobin  if tri_lab==2, width(0.5) color(blue)) ///
			   (histogram hemoglobin if tri_lab==3, width(0.5) color(red)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
				graph export cbc_hemoglobin_tri1.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
				graph export cbc_hemoglobin_tri2.png, replace 
			 
			 restore 
			 
			**Only POC
			preserve 
			keep if hem_type=="POC"
			
			*histogram - POC Only
			histogram hemoglobin 
				graph export poc_hemoglobin.png, replace
				
			*histogram by trimester - same graph
			twoway (histogram hemoglobin if tri_lab==1, width(1) color(green)) ///
			   (histogram hemoglobin  if tri_lab==2, width(1) color(blue)) ///
			   (histogram hemoglobin if tri_lab==3, width(1) color(red)), ///
			  legend(order(1 "Trimester 1" 2 "Trimester 2" 3 "Trimester 3" )) 
					graph export poc_hemoglobin_tri1.png, replace 
			  
			 *histrogram by trimester - different graphs
			 twoway histogram hemoglobin, by(tri_lab) 
					graph export poc_hemoglobin_tri2.png, replace  
			
			 restore 

			 
		************************************************
		*Docx Output
		************************************************
		clear 
		putdocx begin

		putdocx paragraph
		putdocx text ("ANC Hemoglobin Descriptive Statistics"), bold
			
		putdocx paragraph, halign(left)
		putdocx text ("Scatter Plot for Hemoglobin vs. Gestational Age by measurement method")
		putdocx image "scatter_hb_gestage.png"

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (all methods)")
		putdocx image all_hemoglobin.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (all methods)")
		putdocx image all_hemoglobin_tri1.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (all methods)")
		putdocx image all_hemoglobin_tri2.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (CBC only)")
		putdocx image cbc_hemoglobin.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (CBC only)")
		putdocx image cbc_hemoglobin_tri1.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (CBC only)")
		putdocx image cbc_hemoglobin_tri2.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels (POC only)")
		putdocx image poc_hemoglobin.png

		putdocx paragraph, halign(left)
		putdocx text ("Histogram of Hemoglobin Levels by trimester (POC only)")
		putdocx image poc_hemoglobin_tri1.png
		putdocx text ("Histogram of Hemoglobin Levels by trimester (POC only)")
		putdocx image poc_hemoglobin_tri2.png
			 
			 putdocx save "ReMAPP ANC Hemoglobin Figures_13_dec_2021.docx", replace 

			
 