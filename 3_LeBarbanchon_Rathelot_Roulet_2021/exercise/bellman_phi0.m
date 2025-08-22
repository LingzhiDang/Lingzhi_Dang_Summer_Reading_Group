% define the function used to solve phi0
function F = bellman_phi0(phi0, alpha, q, b, lambda, r, w_points, w_weights, tau_points, tau_weights, h, tau)
    % Create grid for quadrature points
    [W, T] = meshgrid(w_points, tau_points);
    [W_weights, T_weights] = meshgrid(w_weights, tau_weights);
    
    % Calculate integrand term
    integrand = (W - alpha*T - phi0) .* (W - alpha*T > phi0);
    
    % approximate integral using Gaussian quadrature
    integral_val = sum(sum(integrand .* h(W) .* W_weights .* T_weights));
    
    F = phi0 - (b + (lambda/(r+q)) * integral_val);
end
