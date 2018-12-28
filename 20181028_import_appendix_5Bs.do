/*Created: 28/10/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: SIRCA Australian Company Announcements (ACA) Library
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Import list of firms that file Appendix 5B reports
and map to group codes from SPPR database*/

/*Set location of working directory*/
cd "C:\Users\12219352\Documents\stata\working"
clear all

/*Import Appendix 5B header list*/
clear
import excel "Appendix_5B_Sample.xlsx", sheet("Headers") firstrow case(lower)
format %td date
rename company ticker
sort ticker date
duplicates report ticker date
duplicates tag ticker date, gen(dup)
duplicates drop ticker date, force
drop dup
drop time pages categories pricesensitive day headline
/*Drop observations before 2008 and after 2015*/
drop if year<2008
drop if year>2015
save appendix_5Bs_all, replace
/*Sort descending by ticker and date*/
gsort ticker -date
/*Keep the latest 5B release date for each firm*/
duplicates drop ticker, force
save 5B_firmlist_all, replace
export delimited using 5B_firmlist_all.csv, replace

/*Merge with company file*/
use 5B_firmlist_all, clear
drop year month
rename ticker tcode_3
rename date last_5B_date
sort tcode_3
merge 1:m tcode_3 using companycodes 
keep if _merge==3
save companycodes_5B, replace

/*Part 1*/
use companycodes_5B, clear
keep if last_5B_date>=list_date & last_5B_date<=delist_date & delist_date!=.
duplicates report tcode_3
duplicates tag tcode_3, gen(dup)
drop if strlen(companycode)>4 & dup>0
drop dup _merge
duplicates report tcode_3
keep tcode_3 groupcoycode last_5B_date fullcoyname list_date delist_date ///
gicsindustrycode
rename tcode_3 ticker
rename groupcoycode grpcode
sort ticker
save grpcodes_pt1, replace

/*Part 2*/
use companycodes_5B, clear
keep if last_5B_date>=list_date & delist_date==.
duplicates report tcode_3
duplicates tag tcode_3, gen(dup)
drop if strlen(groupcoycode)>4 & dup>0
duplicates report tcode_3
drop dup _merge
keep tcode_3 groupcoycode last_5B_date fullcoyname list_date ///
delist_date gicsindustrycode
rename tcode_3 ticker
rename groupcoycode grpcode
sort ticker
save grpcodes_pt2, replace

/*Combine Parts 1 & 2*/
use grpcodes_pt1, clear
append using grpcodes_pt2
sort ticker grpcode last_5B_date
duplicates report ticker grpcode
duplicates report ticker
duplicates tag ticker, gen(dup)
drop if strlen(grpcode)>4 & dup>0
drop dup
sort grpcode list_date
save app_5B_groupcoycodes, replace
export delimited app_5B_groupcoycodes.csv, replace

/*Prepare for merging*/
use app_5B_groupcoycodes, clear
gen app5B=1
sort grpcode
duplicates report grpcode
duplicates drop grpcode, force
keep grpcode app5B
save 5B_firmlist_for_merging, replace
