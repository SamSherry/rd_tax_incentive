/*Created: 11/11/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: SIRCA Australian Company Announcements (ACA) Library
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Extract dates of R&D tax incentive related announcements*/

/*Settings*/
cd "\stata\working"
clear all

/*Import event dates from Excel (based on quarter end date)*/
clear all
import excel "20181226 R&D rebates before transforming.xlsx", ///
sheet("REBATE_CURRENT_QTR") firstrow
rename TICKER ticker
rename GRPCODE grpcode
rename QTR_END date_qtrend
drop COMPANY B_DATE FULLPATH REBATE_CURRENT_QTR H
tostring date_qtrend, replace
gen date=date(date_qtrend,"YMD")
format %td date
drop date_qtrend
drop if year(date)<2008
drop if year(date)>2015
sort grpcode date
duplicates report grpcode date
duplicates drop grpcode date, force
gen event_date=1
save 5B_event_dates, replace

/*Generate event numbers for firms with multiple events in the time series*/
by grpcode: gen evnum=_n
by grpcode: gen num_events=_N
drop ticker
save 5B_event_dates, replace

/*Extract event dates to merge with non-claimers file*/
use 5B_event_dates, clear
sort date
drop grpcode evnum num_events
duplicates drop date, force
save event_dates, replace
