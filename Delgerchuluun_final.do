log using "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter\Delgerchuluun_final.log", replace

*==================================================================================================
						*The impact of migration on left behind spouses
								*Migration replication course
									  *Final assignment

								*Ankhbayar Delgerchuluun
								         *12211529
										 
										 *2022-08-22
*==================================================================================================

*******                            CONTENT of DO file 

*______                   1. Preparing and merging datasets 
*______                   2. Defining the new variable
*______                   3. Descriptive statistic and Figures 
*______                   4. Estimation
*______                   5. Heteregoneos effects 


** COMMENTS on the structure of do file
*all the comments about the commands is written just above the following command while the comment about the result of that command is found below the command 
*general comment about the data and estimation strategy start with (***_) this note 


                           * 1. Preparing and merging datasets 
                           * ---------------------------------
						
clear
*defining a working and data directory using Global macro
global datadir "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter\data\"
global workdir "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter\"


*defining the local macro which indicates survey wave years. it will be used to merge different waves and country household member datasets which countains the basic information of the household. 

***_2008 is excluded from the dataset which have inconsistent huge amount of missing value for the variable(_x21018) and it makes impossible to define the migration based on purpose of it

*Defining the local macro which will be used to append datasets over different waves 
local myear 2007 2010 2011 2013 2016 2017 

*In order to idenfy different waves from one another creating year and country variable before using the loop to append data sets. 
gen year=.
gen thailand=.

***_With the local macro I am using the loop function to append 14 datasets which consists of 6 waves across 2 countries. I saved the data in 2 different folders for each county, and the loop function visits two folders one by one and append datasets while creating following year and country variables before starting next iteration. 

foreach m of local myear{
     append using "$datadir\Thailand\mem_`m'.dta", force nonotes nolabel
	 * since some variables are saved in different format, an option of force is used. Nonotes and nolabel options allow me to do not copy value label defition and copy notes from datasets on disk. It will make log file more readable. 
	 replace year=`m' if year==.
	  replace thailand=1 if year==`m'
	 append using "$datadir\Vietnam\mem_`m'.dta", force nonotes nolabel
	 replace year=`m' if year==.
	 replace thailand=0 if thailand==. & year==`m'
}
****CHECK  THE NUMBER OF OBSERVATION BY HAND UPLOADING DATASETS ONE BY ONE 
*Defining the label 
 label define country_lb ///
	0 "Vietnam" ///
	1 "Thailand" ///
, replace
 label values  thailand country_lb
 
*Seeing the number of observation by survey waves and countries
tab year thailand
*we have 116,643 individual's information over 6 waves. 


***_Here I will append aggregated datasets of household income to merge it to previously appended datasets. In order to that I will use the preserve and restore commands. Within these commands, I will define data directories with global macro and loop data sets one by one with list of numbers. Because the data is saved as order of the waves instead of the conducted year. After the looping, I will save all the appended datasets. 
preserve
global tincome "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter\Data_TH\Aggregates_TH\Aggregates_TH\Aggregates_TH\Income_TH"

global vincome "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter\Data_VN\Aggregates_VN\Aggregates_VN\Aggregates_VN\Income_VN"
clear

*generating a new variablew which will be used to identify the year/waves later 
gen wave=.

*Within loop, I will use append command to append it same as the previous loop which is used for household member datasets
foreach  i of numlist 1 3 5 6 7{
    * since some variables are saved in different format, an option of force is used. Nonotes and nolabel options allow me to do not copy value label defition and copy notes from datasets on disk. It will make log file more readable.  
     append using "$tincome\w`i'_hhinc.dta", force nonotes nolabel

	 *updating the previously generated the wave variable
	 replace wave=`i' if wave==.
	 append using "$vincome\w`i'_hhinc.dta", force nonotes nolabel
	 
	 *updating the previously generated the wave variable. 
	 replace wave=`i' if wave==.
	 *saving datasets in data directory which is defined in the very beginning of the do files
	 save "$datadir\hhinc.dta", replace
	 

}
 
*To see the result of the loop and become familiar with this datasets, de and tab commands are used. 
*de 
restore

*After restoring previous process and datasets which is produced appending all the household member datasets. I will merge the income datasets using the hhid. 
merge m:1 year hhid using "$datadir\hhinc.dta",force
*describe

***_Calculating and excluding the dead people using variable named _x21018, reason for leaving the house. The reason is explained in the report. 
codebook _x21018
gen dead=0
replace dead=1 if _x21018==1
* We can't match the missing variables because the question _x21018 is only asked for the household members who was not in the household. 
tab dead
*Excluding dead people from the dataset
keep if dead==0




                        *   2. Defining the new variable
                        *   ----------------------------
						
***2.1 Defining the unique individual identifier
*-----------------------------------------------
 						
***___Individual ID___						
***_Since I am working in the individual level datasets, I need to create unique ID for each member. So I concatenated hhid and household member id which is only unique for each questionnaire to create the unique id for each household member. I added 3 0 digits between two ID since they are just ordinal numbers and it creates duplication with high and low numbers. Since it requires some commands within gen command, I am using the egen command

egen idd=concat(hhid _x21001), punct(000)

*Concatenation produce only string variable; therfore, it will be transformed to a numeric variable with encode command.
encode idd, gen(rid)

*giving label to the variable 
label var rid "Individual identifier"

***_In order to define the datasets as a panel datasets, time and panel variable should be unique. To check this, I will use a banchof duplicate command

*checking whether there is duplication or not 
duplicates report rid year
*here are 42 surplis obervations and 64 observations are duplicated. In particular, 2 observations are recorded as twice, 20 observations are recorded as triple. 

*listing alll duplicated IDs
duplicates list rid year
* all the duplicated variables are in 2011
*hhid -1448 3011 id duplicated as an example
 
*creating a variable representing the number of duplicates for each observation.
duplicates tag rid year, gen(iddup) 

*dropping dupllicated observations
duplicates drop rid year, force
*42 obersavtions are deleted. Since it is very few observation, it does not affect further estimation

***_Conducting the small test to check rid which is created using concat function with hhid and mem_id. To do this, I will compare the several variables which is unique and time invariant within household and its members. Detailed explanation is in latex report. 
* these variables are birthyear, gender

*calculating bithyear for each individual
gen birthyear=0
foreach x of numlist 2007 2010 2011 2013 2016 2017 {
	 replace birthyear=`x'-_x21004 if year==`x'
	 replace birthyear=. if _x21004==.
}

*giving label to the variable 
label var birthyear "birthyear"

gen match=0 
sort hhid year

*replacing match variable for each individual saying that match variable equals to 1 if the next waves birthyear and gender of that particular people is equal to current wave. 
bysort rid: replace match=1 if _x21003[_n+1]==_x21003 & birthyear[_n+1]==birthyear

*replcaing the missing values
replace match=. if _x21003==.
replace match=. if birthyear==.
sort rid year
*br hhid year _x21001 _x21003 birthyear  match rid 

* we can check the performance of the match variable, If the rid variable captures the people with same gender and birthyear within a household, sum of match variable of a individual over all the waves(6) equals to 5 because the observations in first wave can't be captured by the match variable 
bysort rid: egen match_total=sum(match) if  _x21003!=. & birthyear!=.
bysort rid: egen rid_total=count(match) if  _x21003!=. & birthyear!=.
bysort rid: replace match_total=. if _x21003==.
gen diff_match=rid_total- match_total
tab diff_match
*the difference between two matches should be equal to 1 (6-5). 
* _x21003 has a substantial amount of missing value and  there is some case that birtyear of an individual changed by 1 year between waves. These characteristics lead to little bit change in diff_match variable. But after checking the variables mannually by browsing them, the rid variable is capturing the same individual successfully over the different waves. When calculating the birthyear difference for each individual over the time, there are 1 year difference for 4917 cases. This indicates, in 4917 cases, people's age was different by 1 year between different waves. This different might be triggered by the month difference when answering the age question in survey. 
* the difference between these two variable should be equal to 1 (6-5)
sort rid year
*Checking the how much difference of birthyear between waves. Birthyear should be equal. if there is just one year difference, it might be mismeasurement.
bysort rid: gen mismeasurement_age=birthyear[_n+1]-birthyear
su mismeasurement_age
tab mismeasurement_age
*there are 7447 cases where ages were one year lower in next year as well as 4917 cases one year higher in next year. Therefore it highly likely to be mismeasuremnt of age across the different waves. 

su diff_match
*seeing also histrogram. 
hist diff_match
sort rid year 

 

***2.2 Defining the main variables-Nuclear family, Migration
*-----------------------------------------------------------
 

***___NUCLEAR FAMILY___

***_The nuclear family is the family consists only mother, father, and children. I will restict the sample only to the nuclear families because labour force participation of other adult in family might affect the labour force decision of spouses. In order to this, I will use variable _x21005 which indicates relation to household head and I only keep HH head, its spouses and childrens
tab _x21005
*The variable which indicates whether households have other members than parents and children
 gen other_member=0
 replace other_member=1 if _x21005>4
 replace other_member=. if _x21005==.
*defining the label
 label define other_member_lb ///
	1 "other adult members with also grandchild and nephew" ///
	0 "with only parents and child", replace
*Assigning the label to the variable
 label values other_member other_member_lb
*giving label to the variable 
 label var other_member "Other member of the family"

*defining it for an entire household
 bysort year hhid: egen extended=max(other_member)
*if the household has any other member it would defined as extended family

 gen nuclear=0 
 
*it is the nuclear family if the extended family variable equals to 0 
 replace nuclear=1 if extended==0
 replace nuclear=. if extended==.
*defining the label
 label define nuclear_lb ///
	1 "Nuclear family" ///
	0 "Extended family", replace
*Assigning the label to the variable
 label values nuclear nuclear_lb
 *giving label to the variable 
 label var nuclear "Member of nuclear family"
 tab nuclear
*There are 57810 individuals, 50.1%, belong to nuclear famiily  
 
***___Migration___

***_The migrant is defined as the household member who wasn't in the household more than 180 days and went for purpose of job opportunity. Creating migration variable based on a variable named _x21016 indicating days staying in HH in the last 12 months and _x21018, reason leaving the household.
 codebook _x21016
*The reason for leaving the household variable(_x21018) is saved as text (_x21018t) in 2010 and 2011 year so I unite them to the _x21018 as replacing values of the variable. For simplicity, I only replce values that is required for my analysis. 
 replace _x21018=4 if _x21018t=="Job opportunity"  & year==2010
 replace _x21018=4 if _x21018t=="Job opportunity"  & year==2011
 replace _x21018=5 if  _x21018t=="Job Search" & year==2010
 replace _x21018=5 if  _x21018t=="Job Search" & year==2011
*generating migrant variable
 gen migrant=0
* replacing migrant with 1 if the household member was in the HH less than 180 days
 replace migrant=1 if _x21016<180 & _x21018==4
 replace migrant=1 if _x21016<180 & _x21018==5
 
*replacing missing variables based on missing variable of _x21016==
 replace migrant=. if _x21016==.
*defining the label 
 label define migrant_lb ///
	1 "Migrant" ///
	0 "Non-migrant", replace
*Assigning the label to the variable
 label values migrant migrant_lb
*giving label to the variable 
 label var migrant "Migrant"
 tab migrant

***___Labour force___
*I will exclude people who are student, Monk, joined the army, child below school age, unable to work-other reasons, unable to work because of disability, and missing values from Labour force. 
 gen labour_force=1
replace labour_force=0 if _x21014==10 | _x21014==14 |   _x21014==15  |  _x21014==11  |  _x21014==18 |  _x21014==16 | _x21014==17 |  _x21014>80
replace labour_force=. if _x21014==.
*defining the label 
label define labour_force_lb ///
	1 "labour_force" ///
	0 "Not labour_force" ///
, replace
*Assigning the label to the variable
 label values labour_force labour_force_lb
*giving label to the variable 
 label var labour_force "Labour force or not"
 tab labour_force
*66% of the individuals or 70116 are in labour force
 
***2.3 Defining the control variables
*-----------------------------------------------------------

***___Pre-school___
*generating the new variable with missing values PreSCHOOL. I will use the variable _x21014, Main occupation between 5/06 and 4/07
 gen pre_school=0
 replace pre_school=1 if _x21014==11 
 replace pre_school=.  if _x21014==.
*defining the label
 label define pre_school_lb ///
	1 "Pre-school" ///
	0 "Not pre-school", replace
 label values pre_school pre_school_lb
*giving label to the variable 
 label var pre_school "Pre-school children"
 tab pre_school

***___Elderly people___
*Identifying elderly people which is older than 60 yours old Household. I will use the variable _x21004, household member age (years)
 gen elderly=0
 replace elderly=1 if _x21004>59 
 replace elderly=. if _x21004==. 
*defining the label
 label define elderly_lb ///
	1 "Elderly" ///
	0 "Not elderly", replace
*Assigning the label to the variable
 label values elderly elderly_lb
*giving label to the variable 
 label var elderly "The person who is older than 60"
 tab elderly
 
***___Sick people___
*Identifying sick people claimed to be sick personally within questinnaire, in the question _x23003
 codebook _x23003
 gen sick=0
 replace sick=1 if _x23003==3 
 replace sick=. if _x23003==.
*defining the label
 label define sick_lb ///
	1 "Sick" ///
	0 "Not sick", replace
*Assigning the label to the variable
 label values sick sick_lb
*giving label to the variable 
 label var sick "The person who is sick"
 tab sick

***_Using bysort fucntion, I calculated following variables in household level 

*Calculating total the number of children below school age per household
 bysort hhid year: egen pre_school_number=sum(pre_school)
*giving the label to the variable 
 label var pre_school_number "The number of pre-school children in the houeshold"

*Calculating total the number of elderly  per household
 bysort hhid year: egen elderly_number=sum(elderly)
*giving the label to the variable 
 label var elderly_number "The number of elderly people in the houeshold"
 
*Calculating total the number of people who is sick per household
 bysort hhid year: egen sick_number=sum(sick)
*giving the label to the variable 
 label var elderly_number "The number of elderly people in the houeshold"
 
*Calculating total number of migrants per household
 bysort hhid year: egen migrant_number=sum(migrant)
*giving the label to the variable 
 label var migrant_number"The number of migrant in the houeshold"

*Calculating household size
 bysort hhid year: egen hhsize=count(_x21001)
*giving the label to the variable 
 label var hhsize "Household size"

*Tagging households with the migrant from others 
 bysort hhid year: egen migrant_a=max(migrant)
*giving the label to the variable 
 label var migrant_a "The household with migrant"

*Calculating duration of migration per individual
 bysort rid: egen migrant_duration=sum(migrant)
*giving the label to the variable 
 label var migrant_duration "The years of migration"

*defining a pack of control variable named hh_comp using the global macro
 global hh_comp elderly_number pre_school_number sick_number


***___Educational level ___

***_The higher education indicates the education level above or equivalient to university degree
*generating the new variable with missing values
codebook _x22007
gen higher_educ=.
*Defining the higher education in Vietnam
replace higher_educ=1 if _x22007>64 &  _x22007<78
*Defining the higher education in Thailand
replace higher_educ=1 if _x22007>22 &  _x22007<50
replace higher_educ=0 if _x22007<23
replace higher_educ=0 if _x22007>30 & _x22007<63
*defining the label
 label define educ_lb ///
	1 "With higher education" ///
	0 "Without higher education", replace
*Assigning the label to the variable
 label values higher_educ educ_lb
*giving the label to the variable 
 label var higher_educ "The individual who has higher or equivalient than university"
 tab higher_educ
 
** agregating to household level 
*Calculating total the number of people who has the higher education  per household
bysort hhid year: egen higher_educ_number=sum(higher_educ)

***2.4 Defining dependent variables-Labour force participation
*-------------------------------------------------------------

***_ I defined the 5 different labour force participation based on the variable named _x21014, main occupation. 
****************These are 
*_________________________*permanent
*_________________________*Casual 
*_________________________*Self employed
*_________________________*Unemployed
*_________________________*Housewife
 
***___Permanent workers___
 
*permanent workers are permanently employed in non and agricultural, Government officals 
 gen permanent=0
 replace permanent=1 if _x21014==6 | _x21014==7 | _x21014==8 
 replace permanent=. if _x21014==.
*defining the label
 label define permanent_lb ///
	1 "permanent worker" ///
	0 "Not permanent worker", replace
*Assigning the label to the variable
 label values permanent permanent_lb
*giving the label to the variable 
 label var permanent  "Permanent worker"
 tab permanent
 
***___Casual workers ___ 
*Casual workers- casual off-farm labour in agg, casual labour in non-agg, and performing only occasional and light work 
  gen casual=0
replace casual=1 if _x21014==4 | _x21014==5 | _x21014==13
replace casual=. if _x21014==.
*defining the label
label define casual_lb ///
	1 "Casual worker" ///
	0 "Not casual worker", replace
*Assigning the label to the variable
 label values casual casual_lb
*giving the label to the variable 
 label var casual  "Casual worker"
 tab casual
 
***___Self employed___  
*self employed own agriculture, hunting, non-farm self employed 
  gen self_employed=0
replace self_employed=1 if _x21014==1 | _x21014==2 | _x21014==3
replace self_employed=. if _x21014==.
*defining the label
label define self_employed_lb ///
	1 "Self_employed" ///
	0 "Not self_employed", replace
*Assigning the label to the variable
 label values self_employed self_employed_lb
*giving the label to the variable 
 label var self_employed "Self-employed"
 tab self_employed
 
***___Unemployed___ 
 gen unemployed=0
 replace unemployed=1 if _x21014==12
 replace unemployed=. if _x21014==.
*defining the label
 label define unemployed_lb ///
	1 "Unemployed" ///
	0 "Not unemployed", replace
*Assigning the label to the variable
 label values unemployed unemployed_lb
*giving the label to the variable 
 label var unemployed "Unemployed"
 tab unemployed
 
 ***___Housewife___ 
gen housewife=0
replace housewife=1 if _x21014==9
replace housewife=. if _x21014==.
*defining the label
label define housewife_lb ///
	1 "housewife" ///
	0 "Not housewife", replace
*Assigning the label to the variable
 label values housewife housewife_lb
*giving the label to the variable 
 label var housewife "housewife"
*giving the label to the variable 
 label var housewife "Housewife"
 tab housewife
 global labour permanent casual farmer unemployed self_employed housewife


 ***___Farmer___ 
*People who works in agricultural sector
  gen farmer=0
replace farmer=1 if _x21014==1 | _x21014==2 | _x21014==4 | _x21014==6   
replace farmer=. if _x21014==.
*defining the farmer
label define farmer_lb ///
	1 "farmer" ///
	0 "Non farmer", replace
*Assigning the label to the variable
 label values farmer farmer_lb
*giving the label to the variable 
 label var farmer "Farmer"
 tab farmer
  ***___Emoloyment status___
 * In order to estimate the multinominal logit model we need to variable of employment status, categorical variable
 
 gen estatus=0
*Unemloyed 
 replace estatus=1 if _x21014==12
*Casual 
 replace estatus=2 if _x21014==4 | _x21014==5 | _x21014==13
*Self-employed 
 replace estatus=3 if _x21014==1 | _x21014==2 | _x21014==3
*Permanent
 replace estatus=4 if _x21014==6 | _x21014==7 | _x21014==8 
 replace estatus=. if _x21014==.
 
 label define estatus_lb ///
	0 "Housewife" ///
	1 "Unemployed" ///
	2 "Casual" ///
	3 "Self-employed" ///
	4 "Permanent", replace
*Assigning the label to the variable
 label values estatus estatus_lb
*giving the label to the variable 
 label var estatus "Employment status"
 tab estatus if labour_force==1
 *Currently houswife contains n0n-labour force individuals 
 
 
***2.4 Defining variables which will be used for hetergenous effect 
*------------------------------------------------------------------

 
***___Internal migration____
***_ I defined internal migration based on the variable named on _x21019, destination leaving HH  . if the household member is migrated to within the country, it is defined as internal migration.
 gen internal=. 
 replace internal=1 if _x21019<12 & migrant==1
 replace internal=0 if _x21019>12 & migrant==1 
*clarify the Vietnanese who migrated to Bangkok 
 replace internal=1 if _x21019==9 & thailand==0 
*clarify the Thai people who migrated to Hanoi
 replace internal=1 if _x21019==10 & thailand==1 
*clarify the Thai people who migrated to Ho chi minh City
 replace internal=1 if _x21019==10 & thailand==0 

*defining the label
 label define internal_lb ///
	1 "Internal" ///
	0 "International", replace
*Assigning the label to the variable
 label values internal internal_lb
*giving the label to the variable 
 label var internal "internal"
***___The internal and international migration-creating seperate variable 

gen internal_migrant=0
replace internal_migrant=1 if internal==1 
replace internal_migrant=. if migrant==. 
*defining the label
 label define internal_migrant_lb ///
	1 "Internally migrated" ///
	0 "Didn't migrate at all'" , replace
*Assigning the label to the variable
 label values internal_migrant internal_migrant_lb
*giving the label to the variable 
 label var internal_migrant "Internal migrant"
 tab internal_migrant
 
***___The international migration 

gen  international_migrant=0
replace international_migrant=1 if internal ==0 
replace international_migrant=. if migrant==. 
*defining the label
 label define international_migrant_lb ///
	1 "Internationally migrated" ///
	0 "Didn't migrate at all" , replace
*Assigning the label to the variable
 label values international_migrant international_migrant_lb
*giving the label to the variable 
 label var international_migrant "International migrant"
 tab international_migrant
 
***___Female____
 tab _x21003
 tab _x21003, nolabel
 gen female=.
 replace female=1 if _x21003==2 & _x21003!=.
 replace female=0  if _x21003==1
*defining the label 
 label define female_lb ///
	1 "Female" ///
	0 "Male", replace
*Assigning the label to the variable
 label values female female_lb
*giving the label to the variable 
 label var female "female"
 
***___Households with low remmitances____and its mean

 su P_x10080, detail
 *capturing the mean from result of the su command
 scalar mean_rem= r(mean)
 gen below_rem=0
 replace below_rem=1 if P_x10080<mean_rem
 replace below_rem=. if P_x10080==.
*defining the label
 label define below_rem_lb ///
	1 "Household with remitances below the average" ///
	0 "Household with remitances above the average" , replace
*Assigning the label to the variable
 label values below_rem below_rem_lb
*giving the label to the variable 
 label var below_rem "Household with below meann remittances"
 tab below_rem

***___Household dependent on agriculture

*Since it is difficult to idenfy the aggricultural dependence based on employment status which is so diverse, I split the households based on their their depence on income from crop production. If the income from the crop production constitutes more than half of the household annual income, the household will defined as aggriculturally dependent country
 codebook P_x10084 _x10100P 
 su P_x10084
*defining the share of income from crop production, land rent, and livestock in total income 
 gen share_agg=(P_x10084+P_x10083+P_x10085)/_x10100P  if P_x10084!=.

 gen agg_dependent=0
 replace agg_dependent=1 if share_agg>0.50 
 replace agg_dependent=. if _x10100P==.
*defining the label
 label define agg_dependent_lb ///
	1 "Household that is agriculturally dependent" ///
	0 "Household that is not agriculturally dependent" , replace
*Assigning the label to the variable
 label values agg_dependent agg_dependent_lb
*giving the label to the variable 
 label var agg_dependent "Household that is agriculturally dependent"
 tab agg_dependent
 
***___Difference across income
 
*I split the datasets based on income to check hetergenous effect. The people who have income more than 75th percentile are defined as rich. 

*Defining the 75th percentile of the income. 
 su _x10100P, detail
*capturing the 75th percentile from result of the su command
 scalar rich=r(p75)
 
 gen rich_people=0
 replace rich_people=1 if _x10100P>10681 & _x10100P!=.
 replace rich_people=. if _x10100P==.
*defining the label
 label define rich_people_lb ///
	1 "Household with income above 75th percentile" ///
	0 "Household with income below 75th percentile" , replace
*Assigning the label to the variable
 label values rich_people rich_people_lb
*giving the label to the variable 
 label var rich_people "Household with income above 75th percentile"
 tab rich_people
 
***___The duration of migration
*Here I will define longer migration which is longer than 2 years based on migration duration which is previously defined
 codebook migrant_duration
 su migrant_duration
 scalar mean_migrant_duration=r(mean)
 gen longer_migration=.
 replace longer_migration=1 if migrant_duration>=2
 replace longer_migration=0 if migrant_duration<2
 replace longer_migration=. if migrant_duration==.
*defining the label
 label define longer_migration_lb ///
	1 "Migration longer than 2 years" ///
	0 "Migration shorter than 2 years" , replace
*Assigning the label to the variable
 label values longer_migration longer_migration_lb
*giving the label to the variable 
 label var longer_migration "Migration longer than 2 years"
 tab longer_migration

***__Calculating Return

*Calculating the return using the feature of the difference function. I am substracting the migrant year from its previous year. If the result is a negative(0-1), it indicates that person returned to home.

*Since dif command only works with consecutive years, I generated fake and consectuive years to just calculate return variable. These consecutive years will also be used to build graphs later
gen year1=year
replace year1=2008 if year1==2010
replace year1=2009 if year1==2011
replace year1=2010 if year1==2013
replace year1=2011 if year1==2016
replace year1=2012 if year1==2017
*defining the datasets 

xtset rid year1
*sorting
sort rid year1

*differntiating migration which is binary variable across made up consecutive years 
gen dif1_migrant=d1.migrant
*generating return variable
gen return=.
*If the household member was migrated in the last year and come back current year, dif1_migrant variable get the negative value after substracting previous year from current year. 
replace return=1 if dif1_migrant<0 
replace return=0 if dif1_migrant>=0 

*defining the label
 label define return_lb ///
	1 "Return" ///
	0 "No" , replace
*Assigning the label to the variable
 label values return return_lb
*giving the label to the variable 
 label var return  "Returned to their home" 
 tab international_migrant
tab return
                        *   3. Descriptive statistic and Figures
                        *   ------------------------------------
 
***3.1 Table A.1- Descriptive statistics
*----------------------------------------------
keep if labour_force==1
*Calculating descriptive statistics for vaiables in household level
preserve 
duplicates drop hhid year, force
*summing the remittances from absent household member and friends
 gen remittances=P_x10080+P_x10081
*Categorizing by the nuclear and extended family
tabstat migrant_number $hh_comp higher_educ_number _x10100P remittances P_x10084 P_x10085   P_x10087  P_x10088 hhsize , by(nuclear) statistics( mean sd n max min ) save
*reminding the result of the table
return list
*saving the results as matrix
matrix result=r(StatTotal)
matrix result1=r(Stat1)
matrix result2=r(Stat2)
* Calling related excel and creating new sheet
putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(hhid-by-nuclear) modify
*Specifing the cell in the sheet and format of it
putexcel A1=matrix(result), names nformat(number_d2)
putexcel A10="Extended family"
putexcel A12=matrix(result1), names nformat(number_d2)
putexcel A20="Nuclear family" 
putexcel A21=matrix(result2), names nformat(number_d2)
putexcel save

*Categorizing by whether household has migrant or not
tabstat migrant_number $hh_comp higher_educ_number _x10100P remittances P_x10084 P_x10085   P_x10087  P_x10088 hhsize , by(migrant_a) statistics( mean sd n max min) save
*reminding the result of the table
return list
*saving the results as matrix
matrix result3=r(StatTotal)
matrix result4=r(Stat1)
matrix result5=r(Stat2)
* Calling related excel and creating new sheet
putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(hhid-by-migrant) modify
*Specifing the cell in the sheet and format of it
putexcel A1=matrix(result3), names nformat(number_d2)
putexcel A10= "Non-migrant"
putexcel A11=matrix(result4), names nformat(number_d2)
putexcel A20="Migrant"
putexcel A21=matrix(result5), names nformat(number_d2)
putexcel save
restore 
*Calculating descriptive statistics for vaiables in individual level
tabstat migrant $labour higher_educ , by(nuclear) statistics( mean sd n max min ) save
*reminding the result of the table
return list
*saving the results as matrix
matrix result6=r(StatTotal)
matrix result7=r(Stat1)
matrix result8=r(Stat2)
*Calling related excel and creating new sheet
putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(general) modify
*Specifing the cell in the sheet and format of it
putexcel A1=matrix(result6), names nformat(number_d2)
putexcel A10="Extended family"
putexcel A11=matrix(result7), names nformat(number_d2)
putexcel A20="Nuclear family"
putexcel A21=matrix(result8), names nformat(number_d2)
putexcel save

*Calculating descriptive statistics for vaiables in individual level
tabstat migrant $labour higher_educ , by(female) statistics( mean sd n max min ) save
*reminding the result of the table
return list
*saving the results as matrix
matrix result9=r(StatTotal)
matrix result10=r(Stat1)
matrix result11=r(Stat2)
*Calling related excel and creating new sheet
putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(general-female) modify
*Specifing the cell in the sheet and format of it
putexcel A1=matrix(result9), names nformat(number_d2)
putexcel A10="Male"
putexcel A11=matrix(result10), names nformat(number_d2)
putexcel A20="Female"
putexcel A21=matrix(result11), names nformat(number_d2)
putexcel save
		
***3.2 Figure 1- Labout force participation by type
*--------------------------------------------------

*keeping only labour forces and nuclear families

keep if nuclear==1
preserve 

* I will use consectuive years for labelling x axis and remove the gaps between vars for example between 2011 and 2013 and 2007 and 2008 has different gap therefore we will first use consectuive year1 which we created to calculate return 


*Reducing dataset to year as with mean of other variables
collapse (mean) permanent casual  self_employed unemployed  housewife migrant ///
			,by(year1)	
* we also have to calculate accumalative 
gen rbar_2=self_employed+permanent
gen rbar_3=self_employed+permanent+casual
gen rbar_4=self_employed+permanent+casual+housewife
gen rbar_5=self_employed+permanent+casual+housewife+unemployed

*Building stacked bar graph
twoway bar self_employed year1 , color(gs1) barw(0.85)|| rbar self_employed rbar_2 year1, color(gs4) barw(0.85) || rbar rbar_2  rbar_3  year1, color(gs7) barw(0.85)|| rbar  rbar_3  rbar_4  year1, color(gs11) barw(0.85) || rbar  rbar_4  rbar_5  year1,   color(gs14) barw(0.85) || line migrant year1, msymbol(O)  legend(rows(2)  size(small) label(1 "Self-employed" ) label(2 "permanent" ) label(3 "Casual" ) label(4 "Housewife" ) label(5 "Unemployed" ) label(6 "Migrant" )) ytitle("Labour force participation", size(medium))  graphregion(fcolor(white) lcolor(none)) xtitle("") xlabel(2007 "2007" 2008 "2010" 2009 "2011" 2010 "2013" 2011  "2016" 2012 "2017", noticks) ylabel(0 0.2 0.4 0.6 0.8, format(%9.2f)) plotregion(margin(b=0))

*saving the graph to export to the excel
 graph export figure1.png, replace

* Calling related excel and creating new sheet
 putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(figure1) replace
*Specifing the cell in the sheet
 putexcel b2=picture(figure1.png)
 putexcel save
 restore
 tab estatus
 *unique hhid

***3.3 Figure 2- Structure of household income
*--------------------------------------------------

*checking the incomes
 su P_x10080 P_x10081 P_x10083 P_x10084 P_x10085 P_x10086 P_x10087 P_x10088 P_x10092 P_x10093 P_x10094  P_x10097
*summing the remittances from absent household member and friends
 gen remittances=P_x10080+P_x10081
*giving the label to the variable 
 label var remittances "Remittances from both the absent household member and friends"
*I selected major income sources so now need to define the other incoems as substracting from total income
 gen income1=P_x10084+P_x10087+P_x10085+P_x10088+remittance
 gen other=_x10100P-income1
*giving the label to the variable 
 label var remittances "Remittances from both the absent household member and friends"
 su income _x10100P  
 su _x10100P 
 
*building pie chart
 graph pie   remittances P_x10084 P_x10085   P_x10087  P_x10088  other, plabel(1 "Remittances", color(white))  plabel(2 "Crop production", color(white)) plabel(3 "Livestock", color(white)) plabel( 4 "Off farm employment", color(white)) plabel( 5 "Non-farm self-employment", color(black)) plabel( 6 "Other", color(white)) legend(off) pie(1, color(gs1)) pie(2, color(gs4)) pie(3, color(gs7)) pie(4, color(gs11)) pie(5, color(gs14)) pie(6, color(gs18)) title() graphregion(fcolor(white) lcolor(none))
*saving the graph to export to the excel
 graph export figure2.png, replace 
* Calling related excel and creating new sheet
 putexcel set "$workdir\Delgerchuluun_figure_and_data.xlsx", sheet(figure2) modify
*Specifing the cell in the sheet
 putexcel b2=picture(figure2.png)
 putexcel save
 
							*  	4. ESTIMATION
							*   -------------
							
***4.1 Defining data set
*-----------------------

*Defining dataset
 xtset rid year
 xtdescribe 

keep if nuclear==1
tab year thailand 


***4.2 Fixed effect multinominal logit model 
*------------------------------------------- 	 

  *Package for femlogit model
 *ssc install st0362.pkg
 
*Creating year dummies because femlogit command doesn't support i.year command.
tab year, gen(year2)

adopath
 
 sysdir set PLUS "C:\Users\a.delgerchuluun\ado\personal/"
femlogit estatus migrant $hh_comp higher_educ_number _x10100P year21 year22 year23 year24 year25 year26 , baseoutcome(3)
est store femlogit1
est restore femlogit1
outreg2 using femlogit1, tex

***4.3 Estimation of xtlogit model 
*---------------------------------

***_In order to make it simple, I will use the Loop to evaluate the xtlogit model for all five employment status and save the results to Latex file. 

cd "\\ug-uyst-ba-cifs.student.uni-goettingen.de\home\users\a.delgerchuluun\Eigene Dateien\Migration_Final_chapter"
xtlogit `a' migrant i.year, fe i(hhid) or
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant i.year, fe i(hhid) or
   est store est_basic_`a'
    est restore est_basic_`a'
    outreg2 using basic, eform ///
	append label tex alpha(0.01,0.05,0.10) nocons ///
	bdec(4) bfmt(f) sdec(4) sfmt(f) ///	 
   keep(migrant) addtext(Country FE, YES, Year FE, YES, Controls, NO)
	 
}
*without odds ratio
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant i.year, fe i(hhid) 
 
	 
}
*****_____________________Basic_re __________________

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant i.year, or
   est store est_basic_`a'
    est restore est_basic_`a'
    outreg2 using  basic_rdd, eform ///
	append label tex alpha(0.01,0.05,0.10) nocons ///
	bdec(4) bfmt(f) sdec(4) sfmt(f) ///	 
   keep(migrant) addtext(Country FE, NO, Year FE, YES, Controls, NO)
	 
}

*****_____________________Basic with control  __________________
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant $hh_comp higher_educ_number _x10100P i.year, fe i(hhid) or
   est store est_const_`a'
    est restore est_const_`a'
    outreg2 using basic_const, eform ///
	append label tex alpha(0.01,0.05,0.10) nocons ///
	bdec(4) bfmt(f) sdec(4) sfmt(f) ///	 
   keep(migrant) addtext(Country FE, YES, Year FE, YES, Controls, YES)
	 
}


                             * 5. Heteregoneos effects 
							 *________________________
							 
***_I won't save the result of the following estimation to external file since it is not included into the report.
*I will check the hetergenous effect by following variables
*_________________________*Aggricultural dependence
*_________________________*Amount of remittances
*_________________________*Amount of income
*_________________________*Gender
*_________________________*Migration duration	
*_________________________*Internal and international migration


							 
**_Effect of agricultural activity
tab agg_dependent
su share_agg
foreach a in "permanent" "casual" "self_employed" "unemployed"   "housewife" {
	xtlogit `a' migrant i.year if agg_dependent==1, fe i(hhid) nocnsreport or

}
foreach a in "permanent" "casual" "self_employed" "unemployed"   "housewife" {
	xtlogit `a' migrant i.year if agg_dependent==0, fe i(hhid) or

}

**_Effect of remittances
tab below_rem
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if below_rem==1, fe i(hhid) or
    
}
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if below_rem==0, fe i(hhid) or
    
}

**_Effect of income
tab rich_people
*rich people above the 75th percentile
foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if rich_people==1, fe i(hhid) or
    
}

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if rich_people==0, fe i(hhid) or
    
}
**_Effect of gender
tab female 

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if female==1, fe i(hhid) or
    
}

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if female==0, fe i(hhid) or

}

**_Effect of migration duration


foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant  i.year if longer_migration==1 , fe i(hhid) or
    
}

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' migrant i.year if longer_migration==0, fe i(hhid) or
    
}

*international and internal migration

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' internal_migrant i.year , fe i(hhid) or
    
}

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' international_migrant i.year, fe i(hhid) or
    
}

*Effect of return

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	xtlogit `a' return i.year , fe i(hhid) or
    
}

*Probability linear model

foreach a in "permanent" "casual" "self_employed" "unemployed" "housewife" {
	areg `a' migrant i.year ,absorb(hhid)
    
}

log close 