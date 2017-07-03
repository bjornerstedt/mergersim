
clear all
* quietly compile
import delimited simdata.csv, clear
xtset productid marketid
gen ms = 1
* Select nested or simple logit
mergersim init, price(p) nests(type) quantity(q) marketsize(ms) firm(firm)

//  demeaned price has underscore, non-demeaned is needed for cost calc.
local price _`r(pricevar)'
clonevar `price' = `r(pricevar)'


local endog `r(loggroupshares)'
local exog  x
* Instrument w is needed in order for the GMM estimation to be the same as the
* demand estimation, as the GMM estimation uses all exogenous variabes as instruments
* and w is a cost variable.

local instr nprod_* w

* Shares sh are needed for single product firm calcs
* gen sh = q

* fe and gmm estimates
di "xtivreg2 M_ls `exog' ( `price' `endog' = `instr'), fe"
xtivreg2 M_ls `exog' ( `price' `endog' = `instr'), fe
xtivreg2 M_ls `exog' ( `price' `endog' = `instr'), fe gmm robust

***************************************************************
* Demean vars:
tempvar mv
quietly {
foreach var of varlist M_ls  `price' `endog' `exog' `instr' {
	egen `mv' = mean(`var'), by(productid)
	replace `var' = `var' - `mv'
	drop `mv'
}
}

* After demeaning, ivreg2 gives same result as xtivreg2
ivreg2 M_ls `exog' ( `price' `endog' = `instr')

* Here is the difference, TSLS and GMM give different results:
ivregress 2sls M_ls `exog' ( `price' `endog' = `instr') , nocons
ivregress gmm M_ls `exog' ( `price' `endog' = `instr') , nocons

* reg M_ls  `price' `endog' `exog'

*gmm (M_ls - {xb: `price' `endog' `exog' } ), instruments(`instr' `exog' ,  noconstant)

timer on 1

****************************************************************
* Get all parameters in M_ls:varname format:
foreach var in  `price' `endog' `exog' {
	local params `params' d:`var'
}
di "`params'"

/*
gmm resid, nequations(1) parameters(`params') ///
instruments(`instr' `exog' , noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(robust) from(`price' -1)
*/

* TSLS result:
gmm resid_nested, nequations(1) parameters(d:`price') regressors(`endog' `exog' ) ///
instruments(`instr' `exog' , noconstant) twostep ///
winitial(identity) wmatrix(unadjusted) from(`price' -1)  price(`price')

tempvar delta
matrix est = e(b)
gen `delta' = M_ls - `price' * est[1,1]
reg `delta' `endog' `exog'

* GMM result:
gmm resid_nested, nequations(1) parameters(d:`price') regressors(`endog' `exog' ) ///
instruments(`instr' `exog' , noconstant) twostep ///
winitial(unadjusted) wmatrix(robust) from(`price' -1) vce(robust)  price(`price')

tempvar delta
matrix est = e(b)
gen `delta' = M_ls - `price' * est[1,1]
reg `delta' `endog' `exog'

exit

* FE estimation of costs, with time as only parameter.
* To estimate with single product firms, include price and share options:

gmm resid_mk, nequations(2) parameters(`params' c:time) ///
instruments(`instr' `exog' date, noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(unadjusted) from(`price' -1) // price(`price') share(sh) panel(product)

timer off 1
timer list

asdf
* The following command can take 30 minutes

timer on 2

* Estimating with conduct parameter in collperiod, without FE in costs:
gen collperiod = (year < 2004)

gmm resid_cond, nequations(2) parameters(`params' c:collperiod c:date c:_cons) ///
instruments(`instr' `exog' date, noconstant) twostep ///
winitial(unadjusted, independent) wmatrix(unadjusted) from(`price' -1)

timer off 2
timer list
