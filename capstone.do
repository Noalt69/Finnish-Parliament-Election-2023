*cd "YOUR-DIRECTORY-HERE"

import delimited "elected.csv", clear
keep if _n >= 2
save "data_elected.dta", replace

import delimited "Data_Capstone.csv", clear
keep if _n >= 2
save "data_capstone.dta", replace

merge 1:1 v1 v2 v3 using data_elected.dta

gen elected = 0
replace elected = 1 if _m==2 | _m==3

* Type formatting
//Candidate number should be type string because it's an 'unique' identifier in my POV

replace v40 = "600" if _n == 928 //this one was originally "Tekniikan Akateemiset (TEK) 600 e."

forvalues i = 1/42 {
	replace v`i' = subinstr(v`i', "'", "", .)
	replace v`i' = subinstr(v`i', ",", ".", .)
}
forvalues i = 10/25{
	//ta `var' if real(`var')==.
	destring v`i', replace ignore(" ")
}
local varlist "v28 v31 v34 v37 v40"
foreach var of local varlist {
	destring `var', replace ignore(" ")
}

* Renaming and dropping variables that contain unnecessary comments

rename v1 candidate_number
rename v2 first_name
rename v3 last_name
rename v4 title
rename v5 municipality
rename v6 party 
rename v7 arrival_day 
rename v8 date_modified
rename v9 support_group
rename v10 total_expenses
rename v11 newspaper
rename v12 radio
rename v13 TV
rename v14 info_network
rename v15 other_platform
rename v16 outdoor_ad
rename v17 purchases
rename v18 ad_design
rename v19 event
rename v20 acquisition_cost
rename v21 other_charges
rename v22 total_funding
rename v23 own_resources
rename v24 loans
rename v25 individual_support

gen ex_indi_min1500 = v26 == "X" // 2.3. Excludes any contribution from an individual of at least EUR 1500 ("x"). The same applies to variables below.
drop v26
drop v27 //unnecessary comments

rename v28 aid
gen ex_aid_min1500 = v29 == "X" 
drop v29 v30

rename v31 party_support
gen ex_partysupport_min1500 = v32 == "X"
drop v32 v33

rename v34 party_support_association
gen ex_supass_min1500 = v35 == "X"
drop v35 v36

rename v37 other_sources_support
gen ex_other_min1500 = v38 == "X"
drop v38 v39

rename v40 intermediated_aid
drop v41 v42

//Dropping redundant variables
drop title arrival_day municipality party date_modified support_group _m ex_indi_min1500 ex_aid_min1500 ex_partysupport_min1500 ex_supass_min1500 ex_other_min1500 aid other_sources_support own_resources party_support_association intermediated_aid loans individual_support acquisition_cost other_charges party_support ad_design

//Rearranging variables order
order total_funding, before(total_expenses)

save "master.dta", replace

use "master.dta", clear
*Total Fundings
logit elected total_funding
margin, dydx(total_funding)

probit elected total_funding
margin, dydx(total_funding)

*Advertising campaign
// Variables selection using AIC 
ssc install aic_model_selection
stepwise, pe(.8): logit elected newspaper radio TV info_network other_platform outdoor_ad purchases event 
aic_model_selection logit elected newspaper outdoor_ad purchases TV info_network radio event

//Correlation matrix heatplot
ssc install heatplot
ssc install palettes, replace
ssc install colrspace, replace
correlate elected total_funding newspaper radio TV info_network other_platform outdoor_ad purchases event
matrix cor_matrix_ad = r(C)
heatplot cor_matrix_ad, values(format(%4.3f)) legend(off) xlabel(, angle(30))

//Models
logit elected newspaper radio TV info_network outdoor_ad purchases event
vif, uncentered
margin, dydx(newspaper radio TV info_network outdoor_ad purchases event)

probit elected newspaper radio TV info_network outdoor_ad purchases event
margin, dydx(newspaper radio TV info_network outdoor_ad purchases event)