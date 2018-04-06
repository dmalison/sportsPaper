clear all
set more off

*** LOAD WAVE 1 DATA ***
{
use IMONTH IYEAR AID BIO_SEX ///
H1GI1M H1GI1Y H1GI4 H1GI6* H1GI20 /// 
H1DA* ///
H1GH59A H1GH59B ///
H1HR7* H1HR8* ///
H1NM1 H1NM4 ///
H1NF1 H1NF4 ///
H1RM1 ///
H1RF1 ///
H1MP1-H1MP4 ///
H1FP1-H1FP6 ///
H1WP8 H1WP10 H1WP14 H1WP17* H1WP18*///
H1PR3 H1PR6 H1PR7 H1PR8 ///
S44A* ///
PA55 ///
PC19A_P PC19B_O PC23 PC25 PC26 PC27 PC28 ///
AH_PVT ///
using "~/data/Add_Health/ICPSR_21600/DS0001/21600-0001-Data.dta" 
}
*** GENERATE WAVE 1 COVARIATES ***
{
gen female = (BIO_SEX == 2) if BIO_SEX < 6

gen birthweight = PC19A_P*16 if PC19A_P < 98
replace birthweight = birthweight + PC19B_O if PC19B_O < 98 // in ounces
replace birthweight = birthweight*.0283495 // convert to kilograms

gen birthweight_z = . // construct z score

replace birthweight_z = ((birthweight/3.530203168)^1.815151075 - 1)/(1.815151075*0.152385273) if female == 0
replace birthweight_z = ((birthweight/3.39918645 )^1.509187507 - 1)/(1.509187507*0.142106724) if female == 1

gen age = (IYEAR * 12 + IMONTH - (H1GI1Y*12 + H1GI1M)) if H1GI1Y < 96 & H1GI1M < 96
gen age_1 = age/12

replace age = 241 if age > 241

merge m:1 BIO_SEX age using "~/data/CDC_biostatistics/statage.dta", keep(match master) nogen

gen height_1 = H1GH59A * 12 if H1GH59A < 96 
replace height_1 = height_1 + H1GH59B if H1GH59B < 96
replace height_1 = height_1 * 2.54 // convert to centimeters

gen height_1_z = ((height_1/M)^L - 1)/(L*S)

drop age M L S

gen race = .

replace race = 1 if H1GI6A == 1 & H1GI6B == 0 & H1GI6C == 0 & H1GI6D == 0 & H1GI6E == 0 & H1GI4 == 0
replace race = 2 if H1GI6A == 0 & H1GI6B == 1 & H1GI6C == 0 & H1GI6D == 0 & H1GI6E == 0 & H1GI4 == 0
replace race = 3 if H1GI4 == 1
replace race = 4 if ((H1GI6A == 1 & H1GI6B == 1) | H1GI6C == 1 | H1GI6D == 1 | H1GI6E == 1) & H1GI4 == 0

egen sports_1 = rowmax(S44A18-S44A29)

gen grade = H1GI20 if H1GI20 <= 12

gen broken = (H1NM1 != 7 | H1NF1 != 7)

gen educ_m = H1RM1 if H1RM1 < 12
replace educ_m = H1NM4 if educ_m == . & H1NM4 < 12

recode educ_m (1/3 = 1) (4 = 2) (5/7 = 3) (8/11 = 4)

gen educ_f = H1RF1 if H1RF1 < 12
replace educ_f = H1NF4 if educ_f == . & H1NF4 < 12

recode educ_f (1/3 = 1) (4 = 2) (5/7 = 3) (8/11 = 4)

gen hhsize = .8

foreach var of varlist H1HR7* H1HR8* {

	replace hhsize = hhsize + .5 if `var' > 18 & `var' < 996
	replace hhsize = hhsize + .3 if `var' <= 18 & `var' < 996

}

gen lpercapita = ln(PA55 / hhsize) if PA55 != 9996

drop hhsize

local i_cat5 = 1 

local vars /// Which sentence best describes you?
H1MP1 /// How much hair is under your arms now?
H1MP2 /// How thick is the hair on your face?
H1MP3 /// Is your voice lower now than it was when you were in grade school?
H1MP4 /// How advanced is your physical development compared to other boys your age? 
	
foreach var of local vars {

	gen puberty_M_`i_cat5' = .
	replace puberty_M_`i_cat5' = `var'  if `var' > 0 & `var' < 6 
	local i_cat5 = `i_cat5' + 1 
	
}

egen puberty_M = rowmean(puberty_M_*)

local vars1 female-lpercapita puberty_M

keep BIO_SEX AID `vars1'
}
*** LOAD WAVE 2 DATA ***
{
merge 1:1 AID  ///
using "~/data/Add_Health/ICPSR_21600/DS0005/21600-0005-Data.dta", ///
keepusing( ///
IMONTH2 IYEAR2 ///
H2GI1M H2GI1Y ///
H2GH52F H2GH52I ///
) nogen
}

gen age = (IYEAR2 * 12 + IMONTH2 - (H2GI1Y*12 + H2GI1M)) if H2GI1Y < 96 & H2GI1M < 96
gen age_2 = age/12

replace age = 241 if age > 241

merge m:1 BIO_SEX age using "~/data/CDC_biostatistics/statage.dta", keep(match master) nogen

gen height_2 = H2GH52F * 12 if H2GH52F < 96
replace height_2 = height_2 + H2GH52I if H2GH52I < 96
replace height_2 = height_2 * 2.54 // convert to centimeters

gen height_2_z = ((height_2/M)^L - 1)/(L*S)

drop age M L S

local vars2 age_2 height_2 height_2_z

keep AID BIO_SEX `vars1' `vars2'

*** LOAD WAVE 3 DATA ***
{
merge 1:1 AID  ///
using "~/data/Add_Health/ICPSR_21600/DS0008/21600-0008-Data.dta", ///
keepusing( ///
IMONTH3 IYEAR3 ///
H3OD1M H3OD1Y ///
H3HGT_F H3HGT_I ///
) nogen
}

gen age = (IYEAR3 * 12 + IMONTH3 - (H3OD1Y*12 + H3OD1M)) if H3OD1Y < . & H3OD1M < .
gen age_3 = age/12

replace age = 241 if age > 241

merge m:1 BIO_SEX age using "~/data/CDC_biostatistics/statage.dta", keep(match master) nogen

gen height_3 = H3HGT_F * 12 if H3HGT_F < 96 
replace height_3 = height_3 + H3HGT_I if H3HGT_I < 96
replace height_3 = height_3 * 2.54 // convert to centimeters

gen height_3_z = ((height_3/M)^L - 1)/(L*S)

drop age M L S



reg height_1_z birthweight_z c.age_1 i.race  i.educ_f i.educ_m lpercapita
reg height_2_z height_1_z c.age_1 i.race  i.educ_f i.educ_m lpercapita i.sports


reg puberty_M c.age_1#c.age_1 age_1 i.race i.race i.educ_f i.educ_m lpercapita

probit sport_1 pct_1 height c.age_1#c.age_1 age_1 i.race i.race i.educ_f i.educ_m lpercapita

reg sports_1 pct_1 height_3 age_1 i.female i.race i.grade i.educ_f i.educ_m i.broken lpercapita
reg otherEC_1 height age_1 i.female i.race i.grade i.educ_f i.educ_m i.broken lpercapita

reg height_1_z age_1 c.age_1#c.age_1 i.female i.female#c.age_1 i.female#c.age_1#c.age_1 i.race lpercapita
reg height_2_z age_2 c.age_2#c.age_2 i.female i.female#c.age_1 i.female#c.age_1#c.age_1 i.race lpercapita

gen pct_1 = height_1/height_3

gen growth = (height_2 - height_1)

reg pct_1 

/height_3

gen change_1 = height_1_z - birthweight_z

saveold "~/data/Fragile_Families/extract/extract.dta", version(12) replace



 

