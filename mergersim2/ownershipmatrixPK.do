
version 11
clear all
compile
use painkillers

local marketing marketing1

// ces
mergersim init, nests(form substance) ces price(Ptablets) revenue(PX1) marketsize(BL) firm(firm) 
quietly xtivreg2 M_ls `marketing' sw sm time month2-month12 (M_lp M_lsjh M_lshg = num* instrp* instrd*),fe //robust

	// STEP 2. Get ownership matrices and modify
	// Alternatively matrices owner and owner2 can be generated manually
	
mergersim market if year == 2008 & month == 12
mata:st_matrix("r(ownershipmatrix)", mergersim_M.m[1].R)
matrix owner = r(ownershipmatrix)

mergersim simulate if year == 2008 & month == 12, seller(1) buyer(2) 
mata:st_matrix("r(ownershipmatrix)", mergersim_M.m[2].R)
matrix owner2 = r(ownershipmatrix)

	// STEP 3. Use ownership matrix to calculate pre-merger costs

mergersim market if year == 2008 & month == 12 , ownershipmatrix(owner)

	// STEP 4. merger simulation: GM (seller=15) and VW (buyer=26) in Germany 1998

mergersim simulate if year == 2008 & month == 12, newownershipmatrix(owner2) ///
seller(1) buyer(2)  // buyer and seller specified for cost efficiencies 
