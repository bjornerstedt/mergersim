program J_resid_mk
	version 13
	syntax varlist if, at(name) [price(varname) share(varname) panel(varname)]
	quietly {
		tempvar xb xb2 epsilon eta costs costpars costs2 mv
		local epsilon : word 1 of `varlist'		
		local eta : word 2 of `varlist'	
		
		matrix score double `xb' = `at' `if', eq(#1)
		replace `epsilon' = M_ls - `xb' `if'
		
		if "`price'" != "" {
			* If price and share options are set a simple unnested calc:
			local alpha = `at'[1, 1]
			gen `costs' = `price' + 1 / (`alpha'*(1 - `share') )
		}
		else {
			.M.get_costs `costs', params(`at') conductparams(`cond')
		}
		* FE demeaning of costs
		if "`panel'" != "" {
			egen `mv'=mean(`costs'), by(`panel')
			replace `costs' = `costs' - `mv'
		}		
		matrix score double `xb2' = `at' `if', eq(#2)
		replace `eta' = `costs' - `xb2' `if'
	}
*	sum `costs' `costs2'
*	matlist M_demand_b
end
