// regress-costs.do
//

version 10

if "$CES" == "" {
	// Defaults if globals like CES have not been defined elsewhere
	global CES 1 
	global level 2 // Set to 3 to get subsubgroup estimate
	global yd 0 // Set yd to 1 to get year dummies	
	global sel2f3s 1 // Select 2 forms 3 substances 
	global nochildren 0 // Use only adult forms
}

//use ../painkillers9508, clear
use ../painkillers9511prel, clear

// Normalize some variables

	gen PX1 = PX/1000000
	gen Xtablets1 = Xtablets/1000000

// Create control variables in delta

	drop if product ==.
	// Duplicate products
	drop if product ==39 & year ==2005 & Ptablets ==. 
	gen time = ym(year, month)
	format time %tmCCYY-NN
	xtset product time, monthly

	
	tab year, gen(year)
	tab month, gen(month)

	gen marketing1 = marketing/1000000
	gen sw = 1000*sickwomen/popwomen
	gen sm = 1000*sickmen/popmen



// Define the price and quantity variable

	egen Pmean = mean(Ptablets), by(product)
	gen Pdemeaned = (Ptablets/Pmean) 
	gen Xdemeaned = PX/Pdemeaned

	gen P = Ptablets		// alternatives Ptablets or Pddd or Pnormal or Pdemeaned
	gen X = Xtablets		// alternatives Xtablets or Xddd or Xnormal or Xdemeaned

	gen lP = log(P)

if $CES==0 {
	replace P = P/(cpi/100) // Do this in all cases to get costs in real terms
}

// Select out nonpositives

	drop if X<=0
	drop if PX1 == 0
// Select sample

if $nochildren {	
	keep if child ==0
}
if $sel2f3s {	
	keep if form==2|form==7
	keep if substance==1|substance==3|substance==5
}

if 0 {	
	egen prtotPX = sum(PX1), by(product)
	keep if prtotPX > 100
}	

if 0 {
	egen mPX1 = mean(PX1), by(product)
	gen test = PX1/mPX1
	sum test,d
	drop if test<0.1		// drop products at end or start of cycle
}
compress
save test, replace
	
