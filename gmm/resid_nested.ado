program resid_nested
	version 13
	syntax varlist if, at(name) regressors(varlist) price(varname)
*	quietly {
		tempvar xb delta e
		* varlist contains name of variable to return residuals in:
		local epsilon : word 1 of `varlist'
		* Local matrix `at' contains alpha parameter
		gen `delta' = M_ls - `price' * `at'[1,1] `if'
		* Regress M_ls on other regressors
		quietly reg `delta' `regressors', nocons
		predict double `e', residuals
		* Put result in return variable `epsilon':
		quietly replace `epsilon' = `e'

*	}
end
