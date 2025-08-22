% This function computes empirical cdf from the raw data (such as income)
% N is the number of draws 
% method specifies interpolation method: 'linear',
% 'nearest','spline','cubic' etc. (see documentation for interp1)

function output = ecdfdraw(data,N,method,seed) 
   
    % Compute CDF from data
    [F,X] = ecdf(data);

    % Generate N uniformly distributed samples between 0 and 1.
    rng(seed);
    u = rand(N,1);
   
    % Map these to the points on the empirical CDF.
    output = interp1(F, X, u,method);

end
