/*Created: 28/10/2018
Last updated: 27/12/2018
Project: R&D Tax Incentive
For use with: SIRCA SPPR Database
Programming environment: STATA
Version: 15.1
Author: Sam Sherry
Objective: Import SPPR company table*/

/*Set location of working directory*/
clear all
cd "\stata\working"

/*Import the SPPR Company table*/
import delimited company.txt, clear
save sppr_company, replace

/*groupcoycode --> grouptcode in prices table*/
/*companycode --> tcode in prices table*/
/*tickercode --> ticker in prices table*/
/*tcode_3 --> first 3 characters of companycode, useful for linking with
other tables*/

/*Drop variables you don't need*/
drop abbreviatedcoyname securitytype homeexchange sircaindustryclasscode ///
sircasectorcode industrycode industrycodetoaug2002 subindustcode ///
gicsindustrycodetosept2002 gicssectorcodetosept2002 grptradedmonths ///
alteredlink delistreason relatedgcode familygcode fullname_10 abrvname_10 ///
listserial delistserial foreign minlistdate maxdelistdate

/*Format dates*/
generate list_date=date(listdate,"DMY"), after(listdate)
format %td list_date
generate delist_date=date(delistdate,"DMY"), after(delistdate)
format %td delist_date
drop listdate delistdate

/*Confirm no duplicate company codes*/
sort companycode
duplicates report companycode 

/*Trim*/
replace companycode=strtrim(companycode)
replace groupcoycode=strtrim(groupcoycode)
replace tcode_3=strtrim(tcode_3)
replace tickercode=strtrim(tickercode)
replace fullcoyname=strtrim(fullcoyname)
order groupcoycode companycode tcode_3 tickercode

/*Capitalise*/
replace companycode=strupper(companycode)
replace tcode_3=strupper(tcode_3)
replace tickercode=strupper(tickercode)

/*Drop firms delisted before 2004*/
drop if year(delist_date)<2004

/*Sort*/
sort tcode_3 list_date
save companycodes, replace

/*Export*/
export delimited companycodes.csv, replace
