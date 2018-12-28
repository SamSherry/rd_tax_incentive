/*Created: 5/12/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: ASX End of Day (EOD) database and SIRCA Core Research Data (CRD)
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Calculate long-run buy-and-hold returns using daily price data*/

/*Settings*/
pwd
cd "C:\Users\12219352\Documents\stata\working"
clear all

/*Import data from SIRCA CRD*/
import delimited pri_04_5.csv, varnames(nonames) clear
save pri_04_5, replace

import delimited pri_05_6.csv, varnames(nonames) clear
save pri_05_6, replace

import delimited pri_06_7.csv, varnames(nonames) clear
save pri_06_7, replace

import delimited pri_07_8.csv, varnames(nonames) clear
save pri_07_8, replace

import delimited pri_08_9.csv, varnames(nonames) clear
save pri_08_9, replace

import delimited pri_09_0.csv, varnames(nonames) clear
save pri_09_10, replace

import delimited pri_10_1.csv, varnames(nonames) clear
save pri_10_11, replace

import delimited pri_11_2.csv, varnames(nonames) clear
save pri_11_12, replace

import delimited pri_12_3.csv, varnames(nonames) clear
save pri_12_13, replace

import delimited pri_13_4.csv, varnames(nonames) clear
save pri_13_14, replace

/*Append data for each year into one file*/
use pri_04_5, clear
append using pri_05_6 pri_06_7 pri_07_8 pri_08_9 pri_09_10 pri_10_11 ///
pri_11_12 pri_12_13 pri_13_14, gen(_append)
table _append

/*Rename fields and drop variables not needed*/
rename v1 date
rename v2 stockcode
rename v3 ticker
rename v6 close
rename v9 dilfactor
rename v10 dilutions
rename v11 dilcode
rename v12 dilcode1
rename v13 dilfactor1
rename v16 dilcode2
rename v17 dilfactor2
drop _append v4 v5 v7 v8 v14 v15 v18 v19
save prices_crd, replace

/*Generate date variable*/
tostring date, replace
generate datevar=date(date,"YMD") 
format %td datevar
drop date
rename datevar date
order date
sort stockcode date
save prices_crd, replace

/*Summarize date variable. The time series should end on 31dec2013
(equivalent to 19723 in STATA)*/
summarize date
summarize date, format

/*Drop observations after 31 December 2013 (included in AEOD data*/
drop if date>19723
save prices_crd, replace

/*Import AEOD data*/
import delimited AEOD_All.csv, clear

/*Drop AEOD fields that are not in the CRD data file*/
drop date_ymd hightradefortheday lowtradefortheday volumetradedfortheday ///
valuetradedfortheday currdivamnt specialamnt frankedamnt frankedperc ///
forgncurramnt dividendcurrency coraxdescription coraxcomment listedshares

/*Rename variables to match CRD*/
rename stockidentifier ticker
rename lasttradefortheday close
rename dilutionfactor dilfactor
rename dilutionfactorcode dilcode
rename numberofdilutionevents dilutions
rename dividenddilutioncode dilcode2
rename dividenddilution dilfactor2
rename coraxdilutioncode dilcode1
rename coraxdilution dilfactor1

/*Generate date variable*/
gen datevar=date(date,"DMY"), after(date)
format %td datevar
drop date
rename datevar date
sort stockcode date
save prices_aeod, replace

/*Summarize date variable. The time series should start on 2jan2014
(equivalent to 19725 in STATA)*/
summarize date
summarize date, format

/*Drop observations before 2 January 2014 (included in CRD)*/
drop if date<19725

/*Rearrange variable order to match CRD*/
order date stockcode ticker close dilfactor dilutions dilcode ///
dilcode1 dilfactor1 dilcode2 dilfactor2
save prices_aeod, replace

/*Combine CRD with AEOD*/
use prices_crd, clear
append using prices_aeod, gen(_append)
tab _append
drop dilcode1 dilfactor1 dilcode2 dilfactor2 _append
order stockcode
sort stockcode date
save prices_all, replace

/*Clean up data*/
/*Remove ".ASX" from tickers*/
replace ticker=subinstr(ticker,".ASX"," ",.)
/*Remove leading and trailing blanks and convert to uppercase*/
replace ticker=strtrim(ticker) 
replace ticker=strupper(ticker)
/*Drop observations with missing stock code*/
drop if stockcode==.
/*Drop observations that are not FPO shares*/
/*Secondary issues: Options (4th letter O); Rights (4th letter R)*/
/*Special conditions: Deferred settlement (4th letter D);
Instalment receipts or other (4th letter C)*/
/*Interest rate securities: Unsecured note H; Convertible note G;
Preference share P*/
/*Derivative markets: Exchange traded options X;
Warrants - I, J, W, V, U, F*/
gen len_ticker=strlen(ticker)
tab len_ticker
drop if len_ticker>3
drop len_ticker
/*Drop NEW shares*/
drop if stockcode>1000000 
/*Recode observations where dilfactor is -1 or 0*/
replace dilfactor=1 if dilfactor==-1
replace dilfactor=1 if dilfactor==0
summ dilfactor
drop dilutions dilcode
/*Check for duplicates*/
/*By stockcode and date - should not be any duplicates*/
sort stockcode date
duplicates report stockcode date
/*By ticker and date*/
sort ticker date
duplicates report ticker date
/*Sort by ticker, date and close*/
sort ticker date close
duplicates tag ticker date, gen(dup)
by ticker date: gen num=_n if dup==1
/*Where there are duplicates, delete the observation where there is no
closing price*/
drop if num==2 & dup>0
drop dup num
duplicates report ticker date
save prices_all, replace

/*Map tickers to group codes from SPPR database*/
/*Create ltdmo variable for merging with SPPR prices table*/
use prices_all, clear
gen ltdmo=mofd(date)
format %tm ltdmo
sort ticker ltdmo date
save prices_all, replace

/*Merge with group codes*/
use monthly_tickers_sppr, clear
merge 1:m ticker ltdmo using prices_all
keep if _merge==3
drop _merge
sort grpcode date
/*Check for duplicates by grpcode and date*/
duplicates report grpcode date
save prices_grpcodes, replace

/*Merge with 5B firm list*/
use 5B_firmlist_for_merging, clear
merge 1:m grpcode using prices_grpcodes
keep if _merge==3
drop _merge
sort grpcode date
save prices_grpcodes, replace

/*CLAIMERS*/
/*Merge with claimer dummy file*/
use claimers, clear
duplicates report grpcode
merge 1:m grpcode using prices_grpcodes
drop _merge
drop if claimer==.
save prices_claimers, replace

/*Set as panel data*/
use prices_claimers, clear
encode grpcode, gen(newcode)
order newcode
sort newcode date
duplicates report newcode date
xtset newcode date

/*Forward fill missing prices*/
bysort newcode: carryforward close, replace
summarize
tsfill
bysort newcode: carryforward ticker grpcode claimer app5B ///
stockcode close, replace
replace dilfactor=1 if dilfactor==.
replace ltdmo=mofd(date) if ltdmo==.
summarize
sort newcode date
save prices_claimers, replace

/*Dilutions*/
use prices_claimers, clear
sort newcode date
by newcode: gen datenum=_n
by newcode: gen cumdilfactor=dilfactor if datenum==1
by newcode: replace cumdilfactor=dilfactor*cumdilfactor[_n-1] if datenum!=1
gen adjprice=close/cumdilfactor
drop datenum
save prices_claimers, replace

/*Import event dates*/
/*Prepare for merging*/
use prices_claimers, clear
sort grpcode date
duplicates report grpcode date
save prices_claimers, replace

/*Merge*/
merge 1:1 grpcode date using 5B_event_dates
sort grpcode date
/* _merge=1 represents non-event days; _merge=3 represents event days*/
drop if _merge==2
drop _merge
replace event_date=0 if event_date==.
save prices_claimers, replace

/*Extract month end prices*/
use prices_claimers, clear
gen evday_price=adjprice if event_date==1
gen evday=date if event_date==1
format %td evday

/*Copy event day and event day price to other observations in the same month*/
rename ltdmo month
sort newcode month
by newcode month: egen max_evday_price=max(evday_price)
by newcode month: egen max_evday=max(evday)
format %td max_evday
drop evday evday_price
rename max_evday evday
rename max_evday_price evday_price

/*Set up event month variable*/
by newcode month: egen evmonth=max(event_date)

/*Keep month end price*/
gsort newcode month -date
duplicates drop newcode month, force
drop date
sort newcode month

/*Set as panel data set*/
duplicates report newcode month
xtset newcode month
/*Tidy up*/
drop evnum num_events evday evday_price
save monthly_prices_claimers, replace

/*Calculate monthly returns*/
sort newcode month
by newcode: gen monthnum=_n
by newcode: gen bhar=adjprice[_n]/adjprice[_n-1]
/*Calculate monthly buy-and-hold returns for months t+1 through t+60*/
foreach i of numlist 1/60 {
	by newcode: gen bhar_`i'=adjprice[_n+`i']/adjprice[_n]
}
save monthly_prices_claimers, replace

/*Keep sample of event months*/
use monthly_prices_claimers, clear
sort newcode month
keep if evmonth==1
save ev_months_claimers, replace

/*NON-CLAIMERS*/
/*Merge with claimer dummy file*/
use claimers, clear
duplicates report grpcode
merge 1:m grpcode using prices_grpcodes
/*Drop claimers*/
drop if _merge==3
drop _merge
replace claimer=0 if claimer==.
drop if close==0
summarize
save prices_nonclaimers, replace

/*Set as panel data*/
use prices_nonclaimers, clear
encode grpcode, gen(newcode)
order newcode
sort newcode date
duplicates report newcode date
xtset newcode date

/*Forward fill missing prices*/
bysort newcode: carryforward close, replace
summarize
drop if close==.
tsfill
bysort newcode: carryforward ticker grpcode app5B stockcode close, replace
replace claimer=0 if claimer==.
replace dilfactor=1 if dilfactor==.
replace ltdmo=mofd(date) if ltdmo==.
summarize
sort newcode date
save prices_nonclaimers, replace

/*Dilutions*/
use prices_nonclaimers, clear
sort newcode date
by newcode: gen datenum=_n
by newcode: gen cumdilfactor=dilfactor if datenum==1
by newcode: replace cumdilfactor=dilfactor*cumdilfactor[_n-1] if datenum!=1
gen adjprice=close/cumdilfactor
drop datenum
save prices_nonclaimers, replace

/*Import event dates*/
/*Prepare for merging*/
use prices_nonclaimers, clear
sort date
save prices_nonclaimers, replace

/*Merge*/
use event_dates, clear
merge 1:m date using prices_nonclaimers
drop _merge
replace event_date=0 if event_date==.
sort newcode date
save prices_nonclaimers, replace

/*Extract month end prices*/
use prices_nonclaimers, clear
gen evday_price=adjprice if event_date==1
gen evday=date if event_date==1
format %td evday

/*Copy event day and event day price to other observations in the same month*/
rename ltdmo month
sort newcode month
by newcode month: egen max_evday_price=max(evday_price)
by newcode month: egen max_evday=max(evday)
format %td max_evday
drop evday evday_price
rename max_evday evday
rename max_evday_price evday_price

/*Set up event month variable*/
by newcode month: egen evmonth=max(event_date)

/*Keep month end price*/
gsort newcode month -date
duplicates drop newcode month, force
drop date
sort newcode month

/*Set as panel data set*/
duplicates report newcode month
xtset newcode month
/*Tidy up*/
drop dilfactor cumdilfactor evday_price evday
save monthly_prices_nonclaimers, replace

/*Calculate monthly returns*/
sort newcode month
by newcode: gen monthnum=_n
by newcode: gen bhar=adjprice[_n]/adjprice[_n-1]
/* Calculate monthly buy-and-hold returns for months t+1 through t+60*/
foreach i of numlist 1/60 {
	by newcode: gen bhar_`i'=adjprice[_n+`i']/adjprice[_n]
}
sort newcode month
save monthly_prices_nonclaimers, replace

/*Keep sample of event months*/
use monthly_prices_nonclaimers, clear
keep if evmonth==1
save ev_months_nonclaimers, replace

/* T-Tests*/

/* Matching on size and MTB*/

/* Need ewmkt from SPPR file - market index*/
