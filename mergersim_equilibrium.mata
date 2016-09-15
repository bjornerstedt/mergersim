/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: mergersim_equilibrium.mata 235 2015-11-24 17:31:16Z d3687-mb $

***************************/
version 11.2

mata:

class Merger extends VariableClass {
	class Market matrix m
	string scalar bootresults
private:
	void new()

public:
	void init()
	void equilibrium(), costestimate(), demand(), consumerSurplus(), upp()
	void groupElasticities()
}

class SolverParam {
	real scalar method
	real scalar maxit
	real scalar sensitivity
	real scalar firstit //  Number of fixed_point iterations before Newton method in combined.
	real scalar dampen
	real scalar dampenIfNecessary
	real scalar prediction	
	real scalar h_epsilon

	void new(), init()
}

class Solver extends VariableClass {
	static class SolverParam scalar param
}

class Market extends Solver {
	real scalar conduct
	// Varnames
	string firm
	string price
	string quantity 
	string costs
	string initprice
	string conductparams
	string ownershipmatrix

	// Dataset variables
	real matrix q // shares
	real matrix p // prices
	real matrix p0 // Initial prices
	real matrix c // Costs

	real matrix s // shares
	real matrix R // ownership tranformation matrix with conduct
	real matrix r // ownership matrix
	real matrix Ds // demand jacobian, used repeatedly in upp calculations
public:
	void find_costs(), get_demand()
	real matrix equilibrium(), upp()

	void get_data()
	void init(), parameters()
private:
	real matrix foc(), margins()
	real matrix fixed_point(), demand()
	real matrix newton(), jacobian(), solvenl()
	
private:
	void new()
}

void Merger::new()
{
	m = Market(5) // 10 markets allowed by default
}

void Merger::init()
{
	m[1].marketvar = marketvar
	m[2].marketvar = marketvar
}

void Merger::equilibrium(class Demand scalar D, string scalar touse, real sim)
{
	D.marketvar = marketvar // What is this?
	real scalar i
	real matrix it
	real matrix iterations
	real scalar convergence
	D.init()
	setperiods(touse)
	iterations = J(periods, 1, 0)
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[sim].get_data(periodvar)
		
		it = m[sim].equilibrium(D)
		
		iterations[i] = it[1]
		convergence = convergence & it[2]
	}
	st_numscalar("r(convergence)", convergence)
	st_numscalar("r(iterations)", mean(iterations))
	st_numscalar("r(maxiterations)", max(iterations))	
	st_numscalar("r(maxit)", m[sim].param.maxit)
	st_numscalar("r(markets)", periods)
	st_numscalar("r(products)", rows(m[sim].p))
}

void Merger::costestimate(class Demand scalar D, string scalar touse, real sim)
{
	D.marketvar = marketvar // What is this?
	real scalar i
	setperiods(touse)
	D.init()
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[sim].get_data(periodvar)
		m[sim].find_costs( D) 
	}
}

void Merger::upp(class Demand scalar D, string scalar touse, real sim, 
real buyer, real seller, real e1, real e2)
{
	D.marketvar = marketvar // What is this?
	real matrix avupp, upp, upp12, upp21, fpp
	real matrix s, Ds, r, f1, f2, Ds11, Ds22, Ds12, Ds21, p, c, dp
	real scalar i
	setperiods(touse)
	D.init()
	avupp = J(4, 2, 0)
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[1].get_data(periodvar)
		m[sim].get_data(periodvar)
		r = m[1].r
		c = m[1].c
		p = m[1].p0
		s = D.demand(m[1].q, p)
		Ds = D.share_jacobian( s , p)
		f1 = selectIndex(r, buyer)
		f2 = selectIndex(r, seller)
		fpp = m[sim].c + lusolve( m[sim].R :* Ds , -s ) -  p
		//fpp = m[1].c +  m[sim].margins(D, p ) -  p
		Ds11 = Ds[f1, f1]
		Ds12 = Ds[f1, f2]
		Ds21 = Ds[f2, f1]
		Ds22 = Ds[f2, f2]
		upp = ( mean( -e1*c[f1] - luinv(Ds11)*Ds12*(p[f2] - c[f2]) ),
				mean( -e2*c[f2] - luinv(Ds22)*Ds21*(p[f1] - c[f1]) ) )
		upp = (upp \ (mean( -e1*c[f1] - luinv(Ds11)*Ds12*(p[f2] - (1-e2)*c[f2]) ),
				mean( -e2*c[f2] - luinv(Ds22)*Ds21*(p[f1] - (1-e1)*c[f1]) ) ))
		upp = (upp \ (mean(fpp[f1]), mean(fpp[f2])) )
		dp = m[sim].p -  m[1].p
		upp = (upp \ (mean(dp[f1]), mean(dp[f2])) )
		avupp = avupp + upp/periods
	}
	st_matrix("r(upp)", avupp)
	st_matrixcolstripe("r(upp)", ("", "firm1" \ "", "firm2")) 
	st_matrixrowstripe("r(upp)", ("", "UPP" \ "", "UPPS" \ "", "FP" \ "", "Simulation")) 
}

void Merger::demand(class Demand scalar D, string scalar touse, real sim)
{
	D.marketvar = marketvar // What is this?
	real scalar i
	real matrix s
	real matrix p
	setperiods(touse)
	D.init()
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[sim].get_data(periodvar)
		m[sim].get_demand(D)
	}
}

void Merger::groupElasticities(class Demand scalar D, string scalar touse, string groupvar)
{
	D.marketvar = marketvar // What is this?
	real scalar i
	real matrix egroups
	real matrix elas, avelas
	st_view(egroups, ., groupvar, touse)
	setperiods(touse)
	D.init()
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[1].get_data(periodvar)
		elas = D.groupElasticities(m[1].p, egroups)
		if(i==1) {
			avelas = elas/periods
		} else {
			avelas = avelas + elas/periods
		}
	}
	st_matrix("r(groupelasticities)", avelas)
}

void Merger::consumerSurplus(class Demand scalar D, string scalar touse, real sim)
{
	D.marketvar = marketvar // What is this?
	real scalar i, cs1, cs2
	real matrix s
	real matrix p
	setperiods(touse)
	D.init()
	for(i=1; i<= periods; i++ ) {
		period(i)
		D.get_data(periodvar)
		m[1].get_data(periodvar)
		m[sim].get_data(periodvar)
		cs1 = D.consumerSurplus(m[1].p) 
		cs2 = D.consumerSurplus(m[sim].p) 
	}
	st_numscalar("r(cs)", cs2 - cs1) // Returns last cs in last period. Average or matrix for multiple.
}

/********************************************************************************/
// Market class

void Market::new()
{
	conduct = 0
	firm = ""
	ownershipmatrix = ""
	conductparams = ""
}

void Market::find_costs(class Demand D)
{
	real matrix nc
	real matrix s
	s = D.demand(q, p)
	nc = p - lusolve( R :* D.share_jacobian( s , p) , -s )
//	nc = p - cholsolve( -R :* D.share_jacobian( s , p) , s )
	c[.] = nc
}

real matrix Market::foc(class Demand D, real matrix P)
{
	real matrix S
	S = D.shares( P )
	return( ( R :* D.share_jacobian( S , P))*(P - c)+ S )
}

real matrix Market::margins(class Demand D, real matrix P)
{
	real matrix S
	S = D.shares( P )
	return( cholsolve( (-R) :* (D.share_jacobian( S , P)) , S ) )
}

void Market::get_demand(class Demand D)
{
	real matrix ns
	ns = D.shares( p)
	q[.] = D.quantity(ns, p)
}

void Market::init()
{
	check_variable(firm, "firm")	
	check_variable(price, "price")
	check_variable(costs, "costs")
	check_variable(initprice, "initprice")
	check_variable(quantity, "quantity")
}

void Market::get_data(string scalar touse)
{
	real matrix rv
	real matrix rt, rs, cparams
	real scalar pconduct
	st_view(q, ., quantity, touse)
	st_view(p, ., price, touse)
	st_view(p0, ., initprice, touse)
	st_view(c, ., costs, touse)
	if(conductparams != "" ) {
		cparams = st_data( ., conductparams, touse)
		if(cparams != . ) 
			pconduct = cparams[1]
	} else 
		pconduct = conduct
		
	if(strlen(ownershipmatrix) == 0) {
		r = st_data( ., firm, touse)
		rs = groupindex(r)
		rt = group_matrix(rs)
		R = editvalue(rt'*rt, 0, pconduct)	
	} else {
		R = st_matrix(ownershipmatrix)
	}
}

void Market::parameters()
{
	st_global("r(firm)", firm)
	st_global("r(costs)", costs)
}

/**************************************************************************************************/
//                                     Functions to find equilibrium

real matrix Market::equilibrium(class Demand D)
{	
	real matrix it
	if(param.method == 1) {
		it = fixed_point(D, param.maxit) 
		if( !it[2] & param.dampenIfNecessary ) {
			param.dampen = param.dampen / 2
			it = fixed_point(D, param.maxit) 
		}
		if( param.dampen == 1) {
			st_global("r(method)", "Fixed point")
		} else {
			st_global("r(method)", "Dampened Fixed point")
		}
	} else if(param.method == 2) {
		it = fixed_point(D, 1)
		it = newton(D, param.maxit)
		st_global("r(method)", "Newton")
	} else if(param.method == 3) {
		it = fixed_point(D, param.firstit)
		if( !it[2]) {
			it = newton(D, param.maxit)
		}
		st_global("r(method)", "Fixed point / Newton")
	} else if(param.method == 4) {
		it = fixed_point(D, param.maxit) 
		st_global("r(method)", "Undampened fixed point")
	} else if(param.method == 5) {
		it = solvenl(D, param.maxit) 
		st_global("r(method)", "Stata solver")
	} else {
		display("Unknown method")
		_error(99)
	} 
	q[.] = D.quantity(s, p)
	return(it)
}

real Market::fixed_point(class Demand demand, real maxit)
{	
	real matrix P
	real matrix S
	real matrix Q
	real matrix Pn
	real matrix diff
	real dist 
	real i
	real distance 
	real convergence
	convergence = 1 
	P = p0		
	dist = param.sensitivity + 1
	i = 0
	diff = 0
	while(i++ < maxit & dist > param.sensitivity)
	{
		// for linear logit set Q=S, for CES logit set Q=S:/P xxx
		Pn = c + margins(demand, P)
		if(max(Pn) == .) {
			i = maxit + 1
			convergence = 0
			st_global("r(convergenceproblem)", "Could not invert the share Jacobian." )
			break
		}
		diff = Pn - P
		dist = cross(diff, diff)
		if( min(P) < 0 ) {
			convergence = 0
			st_global("r(convergenceproblem)", "Negative prices in price vector" )
			break
		}			
		P = param.dampen*Pn + (1 - param.dampen)*P
	}
	if(i > maxit ) {
		st_global("r(convergenceproblem)", "Max number of iterations exceeded." )
		convergence = 0
		i--
	}
	S = demand.shares( P ) // This function should be called demand
	diff = cross(S, S)
	if(diff < param.sensitivity ) {
		st_global("r(convergenceproblem)", "Zero shares." )
		convergence = 0
	}
	if( min(P) < 0 | min(S) < 0  ) {
		st_global("r(convergenceproblem)", "Negative prices or shares." )
		convergence = 0
	}
	// st_numscalar("r(maxpricediff)", max(abs(diff)) )
	p[.] = P[.]
	s = S[.]
	return((i,convergence))
}

void function fp(real colvector p, real colvector pn, class LogitDemand demand, real matrix c, real matrix R )
{
	real matrix S
	S = demand.shares( p )
	pn = c + cholsolve( (-R) :* (demand.share_jacobian( S , p)) , S ) 
	pn
	if(max(pn) ==.) error("cholsolve did not find a solution")
}

void function root(real colvector p, real colvector diff, class LogitDemand demand, real matrix c, real matrix R )
{
	real matrix S
	S = demand.shares( p )
	diff = -p + c + cholsolve( (-R) :* (demand.share_jacobian( S , p)) , S ) 
	if(max(diff) == .) error("cholsolve did not find a solution")
}

real Market::solvenl(class Demand demand, real maxit)
{	
	real matrix P
	real matrix S
	real matrix Q
	real matrix Pn
	real matrix diff
	real dist 
	real i
	real distance 
	real convergence
	convergence = 1 
	P = p0		
	dist = param.sensitivity + 1
	transmorphic solver
	solver = solvenl_init()
	if(1) {
	//	solvenl_init_technique(solver, "newtonraphson")
		solvenl_init_technique(solver, "broydenpowell")
		solvenl_init_evaluator(solver, &root())
		solvenl_init_type(solver, "zero")
	} else {
		solvenl_init_technique(solver, "gaussseidel")
	//	solvenl_init_technique(solver, "dampedgaussseidel")
		solvenl_init_damping(solver, 0.1)
		solvenl_init_evaluator(solver, &fp())
		solvenl_init_type(solver, "fixedpoint")
	}
	solvenl_init_numeq(solver, length(p0))
	solvenl_init_startingvals(solver, p0)
	solvenl_init_iter_log(solver, "on")
	solvenl_init_narguments(solver, 3)
	solvenl_init_argument(solver, 1, demand)
	solvenl_init_argument(solver, 2, c)
	solvenl_init_argument(solver, 3, R)
	P = solvenl_solve(solver)
/*	
	
	if(i > maxit ) {
		st_global("r(convergenceproblem)", "Max number of iterations exceeded." )
		convergence = 0
		i--
	}
	*/
	S = demand.shares( P ) // This function should be called demand
	if( min(P) < 0 | min(S) < 0  ) {
		st_global("r(convergenceproblem)", "Negative prices or shares." )
		convergence = 0
	}
	// st_numscalar("r(maxpricediff)", max(abs(diff)) )
	p[.] = P[.]
	s = S[.]
	return((1,convergence))
}

real Market::newton(class Demand demand, real maxit)
{	
	real matrix P
	real dist
	real i
	real matrix Pn
	real l
	real matrix diff
	real matrix mat
	real matrix S
	real convergence
	convergence = 1 
	st_global("r(convergenceproblem)", "" )
	
	P = p0	
	dist = 1 
	i = 0
	diff = 0
	while(i++ < maxit & dist > param.sensitivity) // Should be dist > param.sensitivity*(1 + abs(xn) )
	{
		mat =  jacobian(demand, P) 
		Pn = P - lusolve(mat, foc(demand, P) )
		if(max(Pn) == .) {
			i = maxit + 1
			convergence = 0
			st_global("r(convergenceproblem)", "The Newton method could not invert the Jacobian." )
			break
		}
		diff = Pn - P
		dist = cross(diff, diff)
		if( min(Pn) < 0 ) {
			l = -min(Pn :/ (Pn-P))
			P = l*Pn + (1-l)*P
			if( min(P) < 0 ) {
				convergence = 0
				st_global("r(convergenceproblem)", "Negative prices in price vector" )
				break
			}			
		} else {
			P = Pn
		}
	}
	if(i > maxit ) {
		st_global("r(convergenceproblem)", "Exceeded max number of iterations." )
		convergence = 0
		i--
	}
	st_numscalar("r(maxpricediff)", max(abs(diff)) )
	diff = foc(demand, P)
	st_numscalar("r(fixedpointdiff)", cross(diff, diff) )	

	S = demand.shares( P )
	diff = cross(S, S)
	if(diff < param.sensitivity ) {
		st_global("r(convergenceproblem)", "Zero shares." )
		convergence = 0
	}
	if( min(P) < 0 | min(S) < 0  ) {
		st_global("r(convergenceproblem)", "Negative prices or shares." )
		convergence = 0
	}
	
	p[.] = P[.]
	s = S[.]
	return((i,convergence))
}

real matrix Market::jacobian(class Demand D, real matrix x)
{
	real h
	real scalar r
	real scalar i
	real matrix result
	real matrix ep
	r = rows(x)
	ep = J(r,1, param.h_epsilon)
	h = diag(rowmax( (ep, abs(x) :* param.h_epsilon) ) ) 
	result = J(r, r, 0)
	for(i=1; i<= r; i++ ) {
		result[.,i] = (foc(D, x + h[.,i]) - foc(D, x)):/h[i,i]
	}
	return( result )
}

/********************************************************************************/
// Variable class

void VariableClass::setperiods(string scalar touse)
{
	real matrix t
	real matrix sample
	string scalar indexvar
	real scalar i
	real scalar tprev
	
	indexvar = st_tempname()
	periodvar = st_tempname() // Note that periodvar is a Merger global.
	(void) st_addvar("int", (indexvar), 0)
	(void) st_addvar("int", (periodvar), 0)	
	st_view(index, ., (indexvar)) // index class variable
	st_view(period, ., (periodvar)) // index class variable, opened but not used here
	if(marketvar != "" ) { // marketvar class variable  
		stata("sort "+marketvar ) // Sort is needed to do per period.
	} 
	st_view(t, ., (marketvar))
	if( length(touse) ) {
		st_view(sample, ., (touse))
	} else {
		sample = st_addvar("int", st_tempname(), 1)
	}
	real scalar j
	j=0
	tprev =.
	for(i=1; i<= rows(index); i++ ) {
		if(sample[i] & t[i] != tprev) {
			tprev = t[i]
			j++
		}
		index[i] = sample[i] * j
	}
	periods = j
}

void VariableClass::period(real scalar current)
{
	real matrix x
	x = (index :== current)
	period[.] = x[.]
}

void VariableClass::getvariable(real matrix m, string scalar name, string scalar touse)
{
	st_view(m, ., tokens(name), touse)
	assert(m != .)
}

void VariableClass::createvariable(string scalar name)
{
	string varname
	varname = tokens(name)
	if( _st_varindex(varname) == . ) {
		(void) st_addvar("double", (varname))
	}
}

void VariableClass::check_variable(string scalar variable, string scalar varname)
{
	if(variable == .) {
		display("ERROR: Variable "+varname+" is missing")
		assert(0)
	}
	if(!length(variable)) {
		display("ERROR: Variable "+varname+" has not been set")
		assert(0)
	}
	if(_st_varindex(variable) == .) {
		display("ERROR: Variable "+varname+" does not exist:"+variable)
		assert(0)
	}
}

// Transform column vector with group id to matrix with 1 if is in group column
real matrix VariableClass::group_matrix(real matrix A)
{
	real matrix B
	real i
	B = J(rows(A),max(A), 0)
	for(i=1; i<=rows(A); i++) {
		B[i,A[i]] = 1
	}
	return(B')
}

// create matrix with indeces from boolean matrix xxx
real matrix VariableClass::selectIndex(real matrix r, real scalar m) 
{
	real matrix ind, members
	members = (r :== m)
	ind = uniqrows( members :* range(1,length(members),1))
	return(ind[2..length(ind)])
}

// renumber column vector consecutively
real matrix VariableClass::groupindex(real matrix q) 
{
	real matrix p, r, newindex
	real matrix prev, inr, sortorder
	real scalar i, j, isnew
	sortorder = J(1, cols(q), .)
	for(i=1; i<=cols(q); i++) {
		sortorder[i] = i
	}
	p = order(q, sortorder )
	r = q[p,.]
	newindex = J(rows(r), cols(r), .)
	prev = J(1, cols(r), .)
	inr = J(1, cols(r), 0)
	for(i=1; i<=rows(r); i++) {
		isnew = 0
		for(j=1; j<=cols(r); j++) {
			if(isnew | r[i,j] != prev[j]) {
				prev[j] = r[i,j]
				inr[j] = inr[j] + 1
				isnew = 1
			} 
			newindex[i,j] = inr[j]
		}
	}
	return(newindex[invorder(p),.])
}

void SolverParam::new()
{
	init()
}

void SolverParam::init()
{
	method = 2
	maxit = 1000
	sensitivity = 10^-8
	prediction = 0
	firstit = 1 
	dampen = 1
	dampenIfNecessary = 1
	h_epsilon = 10^-6 
}

end
