clear all; 
close all; 
clc;

%% First lets consider how wage curve looks with exogenous alpha
% parameters
alpha = 0.5;      % Disutility of commute
q = 0.11;          % Job destruction rate
b = 0.02;          % Flow utility of unemployment
lambda = 0.28;     % Job offer arrival rate
r = 0.011;         % Discount rate

% Number of quadrature points
N_w = 50;  % for wage integration
N_tau = 20;  % for commute integration

% Get quadrature points and weights for wage and commute
[w_points, w_weights] = lgwt(N_w, 0, 5);  % wage points
[tau_points, tau_weights] = lgwt(N_tau, 0, 2);  % commute points

% Create mesh grid for quadrature points
[W, T] = meshgrid(w_points, tau_points);
[W_weights, T_weights] = meshgrid(w_weights, tau_weights);

% Wage distribution (log-normal)
mu_w = 2; sigma_w = 0.5;
H = @(w) normcdf(w, mu_w, sigma_w); % CDF of log wage
h = @(w) normpdf(w, mu_w, sigma_w); % PDF of log wage

% Utility function
u = @(w, tau) w - alpha * tau; % since w = log W

% Reservation log wage curve: phi(tau) = phi(0) + alpha * tau
% We need to solve phi(0) numerically

% Bellman equation for rU (phi(0)):
% rU = b + (lambda/(r+q)) * ∫∫ 1_{w - alpha*tau > rU} (w - alpha*tau - rU) dH(w, tau)

% solve phi(0) for tau = 0
tau0 = 0;
phi0_guess = 1;
phi0 = fzero(@(phi0) bellman_phi0(phi0, alpha, q, b, lambda, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);

% get reservation wage for all tau
phi_tau = phi0 + alpha * tau_points;

% plot reservation wage curve
figure;
plot(tau_points, phi_tau, 'LineWidth', 2);
xlabel('Commute distance (\tau)');
ylabel('Reservation log wage \phi(\tau)');
title('Reservation log wage curve');
grid on;


% for completeness, calculate the average commute and log wage in next job
% prob of accepting job offer = p
    % Reservation wage threshold for each tau
    phi_tau_grid = phi0 + alpha * T;
    
    % Indicator for acceptance: w > phi(0) + alpha * tau
    accept = W > phi_tau_grid;
    
    % Joint PDF (assuming independence)
    joint_pdf = h(W) .* (1/length(tau_points)); % uniform over tau_points
    
    % Probability of accepting a job offer (p)
    p = sum(sum(accept .* joint_pdf .* W_weights .* T_weights));

% expected tau among accepted offers
numerator_tau = sum(sum(T .* accept .* joint_pdf .* W_weights .* T_weights));
E_tau_n = numerator_tau / p;

% expected w among accepted offers
numerator_w = sum(sum(W .* accept .* joint_pdf .* W_weights .* T_weights));
E_w_n = numerator_w / p;

fprintf('Probability of accepting a job offer (p): %.4f\n', p);
fprintf('Average commute in next job E(tau^n): %.4f\n', E_tau_n);
fprintf('Average log-wage in next job E(w^n): %.4f\n', E_w_n);


%% For identifying and estimating the commute valuation - alpha
% Simulation of data

    % Simulate observed reservation bundle for men and women
    w_star_men = 2.7; tau_star_men = 1.2;  % observed reservation bundle for men
    w_star_women = 2.5; tau_star_women = 1.1;  % observed reservation bundle for women (from descriptive that women have lower tau)
    p_above = 0.80;  % probability of job offers being above the reservation curve
    alpha_men = 0.4;     % true alpha for men
    alpha_women = 0.58;  % true alpha for women
    
    n = 200;
    rng(19);
    
    % for simplicity, lets hard code the probability pi
    p_men = ones(n,1);  % equal weights for all points
    p_women = ones(n,1);  % equal weights for all points
    
    % Men: less sensitive to commute (lower alpha)
    tau_men = tau_star_men + 0.50*randn(n,1); % around reservation commute
    % Generate wages with most points above the reservation curve
    w_curve_men = w_star_men + alpha_men * (tau_men - tau_star_men);  % reservation wage curve
    w_men = w_curve_men + 0.3*randn(n,1);  % add noise around the curve
    % Ensure p_above fraction of points are above the curve
    below_curve = w_men < w_curve_men;
    n_below = sum(below_curve);
    if n_below/n > (1-p_above)
        % If too many points are below, shift some of them up
        % Keep at least 5% of points below for estimation
        n_to_shift = max(0, n_below - round(n * 0.05));
        if n_to_shift > 0
            below_indices = find(below_curve);
            shift_indices = below_indices(randperm(n_below, n_to_shift));
            w_men(shift_indices) = w_curve_men(shift_indices) + 0.5*rand(n_to_shift,1);
        end
    end
    
    % Women: more sensitive to commute (higher alpha)
    tau_women = tau_star_women + 0.4*randn(n,1); % lower commutes, less spread
    % Generate wages with most points above the reservation curve
    w_curve_women = w_star_women + alpha_women * (tau_women - tau_star_women);  % reservation wage curve
    w_women = w_curve_women + 0.5*randn(n,1);  % add noise around the curve
    % Ensure p_above fraction of points are above the curve
    below_curve = w_women < w_curve_women;
    n_below = sum(below_curve);
    if n_below/n > (1-p_above)
        % If too many points are below, shift some of them up
        % Keep at least 5% of points below for estimation
        n_to_shift = max(0, n_below - round(n * 0.05));
        if n_to_shift > 0
            below_indices = find(below_curve);
            shift_indices = below_indices(randperm(n_below, n_to_shift));
            w_women(shift_indices) = w_curve_women(shift_indices) + 0.5*rand(n_to_shift,1);
        end
    end

% Estimation of alpha
% Grid of alpha values to try
alpha_grid = linspace(0, 3, 100);

% For men: find alpha that minimizes sum of squared distances below the curve
% that passes through (tau_star_men, w_star_men)
ssd_men = arrayfun(@(a) reservation_curve_weighted_ssd(a, w_star_men, tau_star_men, w_men, tau_men, p_men), alpha_grid);
[~, idx_men] = min(ssd_men);
alpha_hat_men = alpha_grid(idx_men);

% For women: find alpha that minimizes sum of squared distances below the curve
% that passes through (tau_star_women, w_star_women)
ssd_women = arrayfun(@(a) reservation_curve_weighted_ssd(a, w_star_women, tau_star_women, w_women, tau_women, p_women), alpha_grid);
[~, idx_women] = min(ssd_women);
alpha_hat_women = alpha_grid(idx_women);

fprintf('True alpha for men: %.2f, Estimated alpha for men: %.2f\n', alpha_men, alpha_hat_men);
fprintf('True alpha for women: %.2f, Estimated alpha for women: %.2f\n', alpha_women, alpha_hat_women);

% Calculate which points are below the estimated reservation curves
% For men
w_curve_men = w_star_men + alpha_hat_men * (tau_men - tau_star_men);
below_curve_men = w_men < w_curve_men;

% For women
w_curve_women = w_star_women + alpha_hat_women * (tau_women - tau_star_women);
below_curve_women = w_women < w_curve_women;

% Plot
figure; hold on;
scatter(tau_men(below_curve_men), w_men(below_curve_men), 60, 'b', 'filled'); % points below the curve in darker colors
scatter(tau_women(below_curve_women), w_women(below_curve_women), 60, 'r', 'filled');
scatter(tau_men(~below_curve_men), w_men(~below_curve_men), 60, [0.7 0.7 1], 'filled'); % points above the curve in lighter colors
scatter(tau_women(~below_curve_women), w_women(~below_curve_women), 60, [1 0.7 0.7], 'filled');
xlabel('\tau (commute)'); ylabel('w (log wage)');
legend('Men (below curve)','Women (below curve)','Men (above curve)','Women (above curve)');
title('Simulated accepted job offers');

% Plot fitted reservation curves
tau_plot = linspace(0,1.5,100);
% Calculate reservation wage curves that pass through the observed bundles
phi_men = w_star_men + alpha_hat_men * (tau_plot - tau_star_men);
phi_women = w_star_women + alpha_hat_women * (tau_plot - tau_star_women);

figure; hold on;
scatter(tau_men, w_men, 60, 'b', 'filled');
scatter(tau_women, w_women, 60, 'r', 'filled');
plot(tau_plot, phi_men, 'b-', 'LineWidth', 2);
plot(tau_plot, phi_women, 'r-', 'LineWidth', 2);
xlabel('\tau (commute)'); ylabel('w (log wage)');
xlim([0 max(tau_plot)]);
legend('Men','Women','Men reservation curve','Women reservation curve');
title('Estimated reservation wage curves');
grid on; 

