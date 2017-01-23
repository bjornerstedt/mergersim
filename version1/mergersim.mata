/***************************

MERGER SIMULATION PACKAGE FOR STATA
Jonas Björnerstedt and Frank Verboven

$Id: mergersim.mata 220 2014-08-15 13:17:24Z d3687-mb $

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
	real matrix groupindex(), group_matrix()
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
	virtual real matrix shares(), group_shares()
	void new() 
}

class LogitDemand extends Demand {
	real scalar alpha
	real scalar sigma1
	real scalar sigma2
	real matrix sigma
	real scalar ces
	real scalar nests
	string nest1
	string nest2
	string delta
	string marketsize
	string estimate // Name of vector of estimates
	string variance

	real scalar valueshares // To indicate that shares are in value terms rather than quantity. 
	// Dataset variables, common to both pre-merger and post-merger
	real matrix d // Utility
	real matrix mk // Marketsize
private:	
	real matrix G // Group membership, each column a group with 1 if member
	real matrix GH // Subgroup membership
	real matrix GG // Group membership matrix
	real matrix GHGH // Subgroup membership matrix
	real matrix GN // Binary matrix of subgroup membership in group
public:
	virtual real scalar valueshares(), consumerSurplus()
	virtual void elasticities()
	virtual void parameters()
	virtual real matrix demand(), quantity() // Transform to and from shares
	virtual real matrix shares(), group_shares()
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
	real matrix gr_effect
	real matrix own_effect
	real matrix other_effect
	real matrix DD

	other_effect =  - S*S' 
	
	if(nests == 0) {	
		own_effect = diag(S)
		return( - alpha*( own_effect + other_effect )  )
	} else {
		Sg = GG*S
		own_effect = 1/(1 - sigma[1])*diag(S)
		if(nests == 2) {
			gr_effect = - sigma[2]/(1 - sigma[2])*GG :* ((S :/ Sg)*S')
			Sgh = GHGH*S
			gr_effect = gr_effect - (1/(1 - sigma[1]) - 1/(1 - sigma[2]))*GHGH :* ((S :/ Sgh)*S')	
		} else {
			gr_effect = - sigma[1]/(1 - sigma[1])*GG :* ((S :/ Sg)*S')
		} 
		return( - alpha*( own_effect + gr_effect + other_effect )  )
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
	real i

	real ev
	real matrix ig
	real matrix igs
	delta = d - alpha*P // d is delta without price effect
	if(nests == 2) {
		real matrix igh
		real matrix ighs
		real matrix evv
		ev=exp(delta :/ (1-sigma[1]))
		ighs = (GH*ev)
		igh = GH'*ighs
		evv = ighs :^ ((1-sigma[1])/(1-sigma[2]))
		igs = (GN*evv)	
		ig = G'*igs
		i = sum(igs :^(1-sigma[2]))

		s = ev :* (igh :^ ((sigma[2]-sigma[1])/(1-sigma[2])) ) :* (ig :^ (-sigma[2])) / (1+i)
	} else if(nests == 1) {
		ev=exp(delta :/ (1-sigma[1]))
		igs = (G*ev) 
		ig = G'*igs
		i = sum(igs :^(1-sigma[1]))
		s = ev :* (ig :^ (-sigma[1])) / (1+i)
	} else {
		ev=exp(delta )
		i = sum(ev)
		s = ev / (1+i)
	} 
	return(s)
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
		ighs = (GH*ev)
		evv = ighs :^ ((1-sigma[1])/(1-sigma[2]))
		igs = (GN*evv)	
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
	real matrix g2
	st_view(d, ., delta, touse)
	st_view(mk, ., marketsize, touse)
	e = st_matrix(estimate)
	if( alpha == .) {
		alpha = - e[1] // Note negation of alpha
		if( nests == 1 ) {
			sigma = (sigma1)
		} else if( nests == 2 ) {
			sigma = (sigma1, sigma2)
		} 
	} else 
		assert(e != .)
	if( nests > 0 ) {
		sigma = e[|2\.|]
		real matrix gr
		st_view(groupvars, ., (nest1, nest2), touse)
		gr = groupindex(groupvars)
		g = gr[.,1]
		G = group_matrix(g)
		GG = G'*G

		if(nests == 2) {
			g2 = gr[.,2]
			GH = group_matrix(g2)
			GHGH = GH'*GH
			GN = (G*GH') :> 0
		}
	}	
}

void LogitDemand::init()
{
	check_variable(delta, "delta")	
	if(nests >= 1) {
		check_variable(nest1, "nest1")	
	}
	if(nests == 2) {
		check_variable(nest2, "nest2")	
	}
	check_variable(marketsize, "marketsize")
}

void LogitDemand::parameters()
{
	st_global("r(delta)", delta)
	st_global("r(nest1)", nest1)
	st_global("r(nest2)", nest2)
	st_numscalar("r(nestlevel)", nests)
	st_global("r(marketsize)", marketsize)
	st_numscalar("r(ces)", ces)
	st_numscalar("r(valueshares)", valueshares)
	st_numscalar("r(alpha)", -alpha)
	st_numscalar("r(sigma1)", sigma1)
	st_numscalar("r(sigma2)", sigma2)
}

end
