/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: mergersim_equilibrium.mata 220 2014-08-15 13:17:24Z d3687-mb $

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
	void equilibrium(), costestimate(), demand(), consumerSurplus()
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

	// Dataset variables
	real matrix q // shares
	real matrix p // prices
	real matrix p0 // Initial prices
	real matrix c // Costs

	real matrix s // shares
	real matrix R // ownership vector
	real matrix RR // ownership tranformation matrix with conduct
public:
	void find_costs(), get_demand()
	real matrix equilibrium()

	void get_data()
	void init(), parameters()
private:
	real matrix foc(), margins()
	real matrix fixed_point(), demand()
	real matrix newton(), jacobian()
	
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
}

void Market::find_costs(class Demand D)
{
	real matrix nc
	real matrix s
	s = D.demand(q, p)
	nc = p - lusolve( RR :* D.share_jacobian( s , p) , -s )
//	nc = p - cholsolve( -RR :* D.share_jacobian( s , p) , s )
	c[.] = nc
}

real matrix Market::foc(class Demand D, real matrix P)
{
	real matrix S
	S = D.shares( P )
	return( ( RR :* D.share_jacobian( S , P))*(P - c)+ S )
}

real matrix Market::margins(class Demand D, real matrix P)
{
	real matrix S
	S = D.shares( P )
	return( cholsolve( (-RR) :* (D.share_jacobian( S , P)) , S ) )
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
	real matrix r
	real matrix Rt, rs
	st_view(q, ., quantity, touse)
	st_view(p, ., price, touse)
	st_view(p0, ., initprice, touse)
	st_view(c, ., costs, touse)

	st_view(r, ., firm, touse)
	rs = groupindex(r)

	R = group_matrix(rs)	
	Rt = R'*R
	RR = editvalue(Rt, 0, conduct)	
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
