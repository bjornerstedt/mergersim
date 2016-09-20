program J_resid_nested
	version 13
	syntax varlist if, at(name) regressors(varlist)
*	quietly {
		tempvar xb delta e
		local epsilon : word 1 of `varlist'		
		* Local matrix `at' contains alpha parameter
	*	matlist `at'
		gen `delta' = M_ls - _Ptablets * `at'[1,1] `if'
		* Regress M_ls on other regressors
		quietly reg `delta' `regressors', nocons
		predict double `e', residuals
		quietly replace `epsilon' = `e'
	*	replace test = `delta'
		
*	}
end
/*
program J_resid_nested
	version 13
	syntax varlist if, at(name) // regressors(varlist)
	quietly {
		tempvar xb delta epsilon e
		local epsilon : word 1 of `varlist'		
		
		matrix score double `xb' = `at' `if', eq(#1)
		gen `delta' = M_ls - `xb' `if'
		reg `delta' sw sm time marketing1 month2-month12
		capture drop `epsilon'
		predict double `e', residuals
		replace `epsilon' = `e'
	}
end
*/
