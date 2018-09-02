/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: mergersim.mata 235 2015-11-24 17:31:16Z d3687-mb $

***************************/
version 11.2

mata:

class VariableClass {
	string scalar marketvar // from xtset, set in init. Used for byable.
public:
	// Variables and functions for byable
	real scalar periods
	void setperiods()
	void period()
	void  createvariable(), getvariable(), check_variable()
protected:
	real matrix groupindex(), group_matrix(), selectIndex()
	string scalar periodvar 

private:
	real matrix index
	real matrix period
}

class Demand extends VariableClass {
	string estimate // Name of vector of estimates
	string variance
	real scalar valueshares // To indicate that shares are in value terms rather than quantity. 

	virtual real matrix share_jacobian()
	virtual void get_data()
	virtual void init()
	virtual void elasticities()
	virtual void parameters()
	virtual real scalar valueshares(), consumerSurplus()
	virtual real matrix demand(), quantity() // Transform to and from shares
private:
	virtual real matrix shares(), group_shares(), groupElasticities()
	void new() 
}

class LogitDemand extends Demand {
	real scalar alpha
	real scalar sigma1
	real scalar sigma2
	real scalar sigma3
	real matrix sigma
	real scalar ces
	real scalar nests
	string nest1
	string nest2
	string nest3
	string delta
	string marketsize
	string estimate // Name of vector of estimates
	string variance

	real scalar valueshares // To indicate that shares are in value terms rather than quantity. 
	// Dataset variables, common to both pre-merger and post-merger
	real matrix d // Utility
	real matrix mk // Marketsize
//private:	
	real matrix G // Group membership, each column a group with 1 if member
	real matrix H // Subgroup membership
	real matrix I // Subsubgroup membership
	real matrix GG // Group membership matrix
	real matrix HH // Subgroup membership matrix
	real matrix II // Subsubgroup membership matrix
	real matrix GH // Binary matrix of subgroup membership in group
	real matrix HI // Binary matrix of subgroup membership in group
public:
	virtual real scalar valueshares(), consumerSurplus()
	virtual void elasticities()
	virtual void parameters()
	virtual real matrix demand(), quantity() // Transform to and from shares
	virtual real matrix shares(), group_shares(), groupElasticities()
	virtual real matrix share_jacobian()
	virtual void get_data()
	virtual void init()
private:
	void new() 
}

class CesLogitDemand extends LogitDemand {
	virtual real matrix demand(), quantity()  
	virtual real matrix shares()
	virtual real scalar consumerSurplus()
	virtual real matrix share_jacobian()
}

// *******************************************

void Demand::new()
{
}

void LogitDemand::new()
{
	ces = 0
	nests = 0
}

/********************************************************************************/
// LogitDemand class

real scalar LogitDemand::valueshares()
{
	return(valueshares)
}

// Pass revenues to function for valueshares, otherwise quantity
real matrix LogitDemand::demand(real matrix Q, real matrix P)
{
	real matrix S
	S = Q :/ mk	
	return( S )
}

// Pass revenues to function for valueshares, otherwise quantity
real matrix CesLogitDemand::demand(real matrix Q, real matrix P)
{
	real matrix S
	S = Q :* P :/ mk 
	return( S )
}

real matrix LogitDemand::quantity(real matrix S, real matrix P)
{
	real matrix Q
	Q = S :* mk
	return( Q )
}

real matrix CesLogitDemand::quantity(real matrix S, real matrix P)
{
	real matrix Q
	Q = S :* mk :/ P
	return( Q )
}

real matrix LogitDemand::share_jacobian(real matrix S, real matrix P)
{
	real matrix Sg
	real matrix Sgh
	real matrix f1, f2, f3, f4, f5 // Naming as in new_features.pdf
	real matrix DD

	
	if(nests == 0) {	
		f1 = diag(S)
		f2 =  - S*S' 
		return( - alpha*( f1 + f2 )  )
	} 
	else if(nests == 1) {
		f1 = 1/(1 - sigma[1])*diag(S)
		f2 = - sigma[1]/(1 - sigma[1])*GG :* ((S :/ (GG*S) )*S')
		f3 =  - S*S' 
		return( - alpha*( f1 + f2 + f3 )  )
	}
	else if(nests == 2) {
		f1 = 1/(1 - sigma[1])*diag(S)
		f2 =  - (1/(1 - sigma[1]) - 1/(1 - sigma[2]))*HH :* ((S :/ (HH*S) )*S')	
		f3 = - sigma[2]/(1 - sigma[2])*GG :* ((S :/ (GG*S) )*S')
		f4 =  - S*S' 
		return( - alpha*( f1 + f2 + f3 + f4 )  )
	}
	else if(nests == 3) {
		f1 = 1/(1 - sigma[1])*diag(S)
		f2 =  - (1/(1 - sigma[1]) - 1/(1 - sigma[2]))*II :* ((S :/ (II*S) )*S')	
		f3 =  - (1/(1 - sigma[2]) - 1/(1 - sigma[3]))*HH :* ((S :/ (HH*S) )*S')	
		f4 = - sigma[3]/(1 - sigma[3])*GG :* ((S :/ (GG*S) )*S')
		f5 =  - S*S' 
		return( - alpha*( f1 + f2 + f3 + f4 + f5 )  )
	}
}

// note that the premultiplied diagonal matrix with prices in ces cancels out in the FOC
real matrix CesLogitDemand::share_jacobian(real matrix S, real matrix P)
{
	return( ( super.share_jacobian( S, P) :- diag(S) )  * diag(1:/P) )
}

real matrix LogitDemand::shares(real matrix P)
{
	real matrix s
	real delta
	real ij, i
	real matrix ig, ih, ii
	real matrix igs, ihs, iis
	delta = d - alpha*P // d is delta without price effect
	if(nests == 1) {
		ij = exp(delta :/ (1-sigma[1]))
		igs = G*ij
		ig = G'*igs
		i = sum(igs :^(1-sigma[1]))
		s = ij :* (ig :^ (-sigma[1])) / (1+i)
	} else if(nests == 2) {
		ij = exp(delta :/ (1-sigma[1]))
		ihs = H*ij
		ih = H'*ihs
		
		igs = GH* (ihs :^ ((1-sigma[1])/(1-sigma[2])) )	
		ig = G'*igs
		i = sum(igs :^(1-sigma[2]))

		s = ij :* (ih :^ ((sigma[2]-sigma[1])/(1-sigma[2])) ) :* (ig :^ (-sigma[2])) / (1+i)
	} else if(nests == 3) {
		ij = exp(delta :/ (1-sigma[1]))
		iis = I*ij
		ii = I'*iis
		
		ihs = HI* (iis :^ ((1-sigma[1])/(1-sigma[2])) )	
		ih = H'*ihs
		
		igs = GH* (ihs :^ ((1-sigma[2])/(1-sigma[3])) )	
		ig = G'*igs
		i = sum(igs :^(1-sigma[3]))

		s = ij :* (ii :^ ((sigma[2]-sigma[1])/(1-sigma[2])) ) :* (ih :^ ((sigma[3]-sigma[2])/(1-sigma[3])) ) :* (ig :^ (-sigma[3])) / (1+i)
	} else {
		ij = exp(delta )
		i = sum(ij)
		s = ij / (1+i)
	} 
	return(s)
}

real matrix LogitDemand::groupElasticities(real matrix P, real matrix group)
{
	real matrix A, elas, S, D
	A = group_matrix(group)
	S = shares(P)
	D = share_jacobian(S, P)
	elas = A*diag(P) * D'* A' * diag( 1 :/(A*S) ) 
	st_matrix("r(indelasticities)", diag(P)  * D' *diag( 1 :/ S ))
	return(elas)
}

real scalar LogitDemand::consumerSurplus(real matrix P)
{
	real matrix s
	real delta
	real i

	real ev
	real matrix ig
	real matrix igs
	delta = d - alpha*P // d is delta without price effect
	if(nests == 2) {
		real matrix ighs
		real matrix evv
		ev=exp(delta :/ (1-sigma[1]))
		ighs = (H*ev)
		evv = ighs :^ ((1-sigma[1])/(1-sigma[2]))
		igs = (GH*evv)	
		i = sum(igs :^(1-sigma[2]))

	} else if(nests == 1) {
		ev=exp(delta :/ (1-sigma[1]))
		igs = (G*ev) 
		i = sum(igs :^(1-sigma[1]))
	} else {
		ev=exp(delta )
		i = sum(ev)
	} 
	return(log(1 + i)/alpha * mk[1])
}

real matrix CesLogitDemand::shares(real matrix P)
{
		return(super.shares(log(P)))
}

real scalar CesLogitDemand::consumerSurplus(real matrix P)
{
		return(super.consumerSurplus(log(P)))
}

void LogitDemand::get_data(string scalar touse)
{
	real matrix e
	real matrix groupvars
	real matrix g
	st_view(d, ., delta, touse)
	st_view(mk, ., marketsize, touse)
	e = st_matrix(estimate)
//	if( alpha == .) {
		alpha = - e[1] // Note negation of alpha
		if( nests == 1 ) {
			sigma = (sigma1)
		} else if( nests == 2 ) {
			sigma = (sigma1, sigma2)
		} else if( nests == 3 ) {
			sigma = (sigma1, sigma2, sigma3)
		} 
//	} else 
//		assert(e != .)
	if( nests > 0 ) {
		sigma = e[|2\.|]
		real matrix gr
		st_view(groupvars, ., (nest1, nest2, nest3), touse)
		gr = groupindex(groupvars)
		g = gr[.,1]
		G = group_matrix(g)
		GG = G'*G
	}	
	if(nests > 1) {
		g = gr[.,2]
		H = group_matrix(g)
		HH = H'*H
		GH = (G*H') :> 0
	}
	if(nests > 2) {
		g = gr[.,3]
		I = group_matrix(g)
		II = I'*I
		HI = (H*I') :> 0
	}
	
}

void LogitDemand::init()
{
	check_variable(delta, "delta")	
	if(nests >= 1) {
		check_variable(nest1, "nest1")	
	}
	if(nests >= 2) {
		check_variable(nest2, "nest2")	
	}
	if(nests == 3) {
		check_variable(nest3, "nest3")	
	}
	check_variable(marketsize, "marketsize")
}

void LogitDemand::parameters()
{
	st_global("r(delta)", delta)
	st_global("r(nest1)", nest1)
	st_global("r(nest2)", nest2)
	st_global("r(nest3)", nest3)
	st_numscalar("r(nestlevel)", nests)
	st_global("r(marketsize)", marketsize)
	st_numscalar("r(ces)", ces)
	st_numscalar("r(valueshares)", valueshares)
	st_numscalar("r(alpha)", -alpha)
	st_numscalar("r(sigma1)", sigma1)
	st_numscalar("r(sigma2)", sigma2)
	st_numscalar("r(sigma3)", sigma3)
}

end
