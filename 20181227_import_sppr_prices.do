/*Created: 27/12/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: SIRCA SPPR Database
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Import SPPR prices table*/

/*Set location of working directory*/
cd "\stata\working"
clear all

/*Import the SPPR Prices table*/
import delimited prices.txt, clear
save sppr_prices, replace

/*Extract company codes for merging with daily price data*/
/*grouptcode --> groupcoycode in company table*/
/*tcode --> companycode in company table*/
/*ticker --> tickercode in company table*/
/*first 3 characters of tcode --> tcode_3 in company table*/
use sppr_prices, clear
keep grouptcode tcode lasttradingdate ltdyr ltdmo pastgics ticker
sort tcode ltdyr ltdmo
rename ltdyr year
rename ltdmo month
gen date=date(lasttradingdate,"DMY")
format %td date
gen ltdmo=mofd(date)
format %tm ltdmo
drop if year(date)<2004 /*Can change this line depending on sample period*/
drop lasttradingdate year month
/*Trim leading and trailing blanks*/
replace grouptcode=strtrim(grouptcode)
replace tcode=strtrim(tcode)
replace ticker=strtrim(ticker)
/*Convert tickers to uppercase*/
replace tcode=strupper(tcode)
replace ticker=strupper(ticker)
/*Drop observations that are not FPO shares*/
gen len_tcode=strlen(tcode)
gen tcode_suffix=substr(tcode,4,.)
tab tcode_suffix
destring tcode_suffix, generate(tcode_segment) force
tab tcode_segment
drop if len_tcode>3 & tcode_segment==.
drop len_tcode tcode_suffix tcode_segment
/*Generate tcode_3 variable for linking to other tables*/
sort tcode ltdmo
gen tcode_3=substr(tcode,1,3)
drop date ticker
order tcode_3 tcode grouptcode ltdmo
sort tcode_3 ltdmo
duplicates report tcode_3 ltdmo
drop tcode pastgics
rename tcode_3 ticker
rename grouptcode grpcode
sort ticker ltdmo
save monthly_tickers_sppr, replace
