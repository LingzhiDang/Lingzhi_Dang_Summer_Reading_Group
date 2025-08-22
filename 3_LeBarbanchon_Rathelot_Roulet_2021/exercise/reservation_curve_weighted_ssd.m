% Define the function used to compute sum of squared distances below reservation curve
function ssd = reservation_curve_weighted_ssd(alpha, phi_star, tau_star, w, tau, p)
    phi_curve = phi_star + alpha * (tau - tau_star);
    below = w < phi_curve;
    ssd = sum(p(below) .* (phi_curve(below) - w(below)).^2);
end