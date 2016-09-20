function beta = gmm_funcs(demand)
% Various GMM estimates. Basically a copy from the BLP project
%display('Simple Estimate')
%beta = opt1(demand)
alpha = [-1]';

display('Nested Estimate')
beta = opt2(demand, alpha)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function beta = opt1(demand)
    % Simple regression using fminunc
    W = inv(demand.Z' * demand.Z);
    beta = [.3,.3,.3]';
    options = optimoptions(@fminunc, 'Algorithm','quasi-newton', 'MaxIter',50);

    [beta,fval,exitflag] = fminunc(@(x)objective(x, demand), beta, options);

    function val = objective(beta, demand)
        xi = demand.y - demand.X*beta;
        xiZ = xi'*demand.Z;
        val = xiZ*W*xiZ';
    end
end

function alpha = opt2(demand, alpha)
    % Nested finding of alpha
    W = inv(demand.Z' * demand.Z);
    options = optimoptions(@fminunc, 'Algorithm','quasi-newton', 'MaxIter',50);

    [alpha,fval,exitflag] = fminunc(@(x)objective(x, demand), alpha, options);
    
    % Note that beta is estimated without instrumentation, as only price
    % (and later group share) variables are endogenous
    function val = objective(alpha, demand)
        X0 = demand.X(: , 2:end);
        beta = (X0' * X0)\ (X0' * (demand.y - demand.X(:, 1) * alpha));
        xi = demand.y - demand.X * [alpha; beta];
        
        xiZ = xi' * demand.Z;
        val = xiZ * W * xiZ';
    end
end

