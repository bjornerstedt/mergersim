
version 11
clear all
capture log close

use cars1


// 	PREPARATORY WORK

	// define panel to Stata
egen yearcountry=group(year country), label
xtset co yearcountry

	// define outside good
gen MSIZE=pop/4


// BASIC MERGER SIMULATIONS

	// STEP 1. initialize relevant parameters and estimate

mergersim init, nests(segment domestic) price(price) quantity(qu) marketsize(MSIZE) firm(firm)
xtreg M_ls price M_lsjh M_lshg horsepower fuel width height domestic year country2-country5, fe 	


	// STEP 2. Get ownership matrices and modify
	// Alternatively matrices owner and owner2 can be generated manually
	
mergersim market if year == 1998 & country == 3
mata:st_matrix("owner", mergersim_M.m[1].R)

mergersim simulate if year == 1998 & country == 3, seller(15) buyer(26) 
mata:st_matrix("owner2", mergersim_M.m[2].R)

	// STEP 3. Use ownership matrix to calculate pre-merger costs

//mergersim init, nests(segment domestic) price(price) quantity(qu) marketsize(MSIZE) firm(firm)
mergersim market if year == 1998 & country == 3 , ownershipmatrix(owner)

	// STEP 4. merger simulation: GM (seller=15) and VW (buyer=26) in Germany 1998

mergersim simulate if year == 1998 & country == 3, newownershipmatrix(owner2) ///
seller(15) buyer(26)  // buyer and seller are redundant
