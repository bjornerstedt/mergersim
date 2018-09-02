function beta = gmm_funcs(demand)
% Various GMM estimates. Basically a copy from the BLP project
%display('Simple Estimate')
%beta = opt1(demand)
alpha = [-1]';

display('Nested Estimate')
beta = opt2(demand, alpha)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function alpha = opt2(demand, alpha)
    % Nested finding of alpha
    W = inv(demand.Z' * demand.Z);
    options = optimoptions(@fminunc, 'Algorithm', 'quasi-newton', 'MaxIter', 50);

    [alpha,fval,exitflag] = fminunc(@(x)objective(x, demand), alpha, options);
    xi = findResiduals(alpha);
    xiZ = bsxfun(@times,xi, demand.Z);
    W = inv(xiZ' * xiZ);
    [alpha,fval,exitflag] = fminunc(@(x)objective(x, demand), alpha, options);
 
    % Note that beta is estimated without instrumentation, as only price
    % (and later group share) variables are endogenous
    function val = objective(alpha, demand)
        xi = findResiduals(alpha);
        xiZ = xi' * demand.Z;
        val = xiZ * W * xiZ';
    end

    function xi = findResiduals(alpha)
        X0 = demand.X(: , 2:end);
        beta = (X0' * X0)\ (X0' * (demand.y - demand.X(:, 1) * alpha));
        xi = demand.y - demand.X * [alpha; beta];
    end
end

