/*Created: 5/11/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: SIRCA Australian Company Announcements (ACA) Library
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Calculate R&D tax rebate variables*/

/*Set location of working directory*/
cd "\stata\working"
clear all

/*REBATE_CURRENT_QTR*/
/*Import R&D rebate data for each quarter*/
clear
import excel "20181226 R&D rebates before transforming.xlsx", ///
sheet("REBATE_CURRENT_QTR") firstrow
drop FULLPATH H
rename COMPANY company
rename TICKER ticker
rename GRPCODE grpcode
rename B_DATE date_5B
rename QTR_END date_qtrend
rename REBATE_CURRENT_QTR rebate_qtr

/*Convert date variables to STATA date format*/
tostring date_5B date_qtrend, replace
gen datevar=date(date_5B,"YMD"),after(date_5B)
format %td datevar
drop date_5B
rename datevar date_5B
gen datevar=date(date_qtrend,"YMD"),after(date_qtrend)
format %td datevar
drop date_qtrend
rename datevar date_qtrend

/*Check for duplicates*/
sort company date_qtrend
duplicates report company date_qtrend
duplicates tag company date_qtrend, gen(dup)
duplicates drop company date_qtrend, force
drop dup

/*Create variables for year and month of the event month
(event month = last month of the quarter the R&D refund was received)*/
gen year = year(date_qtrend), after(date_qtrend)
gen month = month(date_qtrend), after(date_qtrend)

/*Keep firms between 2008 and 2015*/
drop if year<2008 | year>2015

/*Sort and save*/
sort grpcode year month
save rebate_qtr, replace

/*Calculate total rebate received for the year*/
bysort grpcode year: egen rebate=sum(rebate_qtr)
duplicates report grpcode year
duplicates drop grpcode year, force
drop date_5B date_qtrend month rebate_qtr
sort grpcode year
save rebate_qtr, replace

/*Create CLAIMER dummy*/
use rebate_qtr, clear
sort grpcode year
drop company rebate year
duplicates drop grpcode, force
generate claimer=1
sort grpcode
save claimers, replace

/*Construct NEW and SWITCH dummies*/
use rebate_qtr, clear
sort grpcode year
encode grpcode, generate(tcode)
order grpcode tcode year
sort tcode year
xtset tcode year, yearly
keep tcode grpcode year rebate
save create_dummies, replace

use create_dummies, clear
reshape wide rebate, i(tcode grpcode) j(year)
rename rebate* y*
save create_dummies, replace

use create_dummies, clear
replace y2008=0 if y2008==.
replace y2009=0 if y2009==.
replace y2010=0 if y2010==.
replace y2011=0 if y2011==.
gen sum_pre_2012=(y2008+y2009+y2010+y2011)

replace y2012=0 if y2012==.
replace y2013=0 if y2013==.
replace y2014=0 if y2014==.
replace y2015=0 if y2015==.
gen sum_post_2012=(y2012+y2013+y2014+y2015)

/*Old regime firms*/
gen existing=1 if sum_pre_2012>0 & sum_post_2012>0
replace existing=0 if existing==.

/*New regime firms*/
gen new=1 if sum_post_2012>0 & sum_pre_2012==0
replace new=0 if new==.
summarize
save create_dummies, replace

/*Repeat claimers*/
use rebate_qtr, clear
sort grpcode year
encode grpcode, generate(tcode)
order grpcode tcode year
sort tcode year
xtset tcode year, yearly
keep tcode grpcode year rebate
by tcode: gen count=_N
gen repeat_claimer=1 if count>1
replace repeat_claimer=0 if repeat_claimer==.
drop rebate count year tcode
sort grpcode
duplicates drop grpcode, force
summarize
save repeat_claimers, replace

/*Merge dummies*/
use claimers, clear
sort grpcode
save claimers, replace

use create_dummies, clear
keep grpcode new existing
sort grpcode
save dummies, replace
merge 1:1 grpcode using claimers
drop _merge
save dummies, replace
merge 1:1 grpcode using repeat_claimers
drop _merge
summarize
sort grpcode
save dummies, replace
