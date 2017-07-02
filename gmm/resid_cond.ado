program resid_cond 
	version 13
	syntax varlist if, at(name)
	quietly {
		tempvar xb xb2 epsilon eta costs cond costpars condpar
		local epsilon : word 1 of `varlist'
		local eta : word 2 of `varlist'

		matrix score double `xb' = `at' `if', eq(#1)
		replace `epsilon' = M_ls - `xb' `if'

		* With conduct
		* The first parameter of the second equation is conduct variable
		* Can for example be set to 1 in a period of collusion, allowing the
		* estimation of conduct relative to outside the period (which then has cond=0).
		*
		* Split second set of parameters into conduct and cost parameters:
		matrix `costpars' = `at'[1,"#2:"]
		matrix `condpar' = `costpars'[1, 1..1]
		matrix `costpars' = `costpars'[1, 2...]
		matrix score double `cond' = `condpar' `if'

		* Function to get calculated costs (here put in the variable `costs').
		* The params option takes the complete vector of parameters, with the
		* assumption that the first parameters will be alpha and sigmas.
		* If conductparams is specified the per period conduct in it will be used.
		.M.get_costs `costs', params(`at') conductparams(`cond')

		matrix score double `xb2' = `costpars' `if'
		replace `eta' = `costs' - `xb2' `if'
	}
end
