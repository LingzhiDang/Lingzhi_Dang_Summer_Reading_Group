clear all; close all; clc;

% THIS VERSION:
% Create a random job search model where commute matters in the context of
% the paper Gender Differences in Job Search: Trading off comute against
% wage. Similar model to Van den Berg and Gorter 1997

% Parameters
alpha = 0.5;      % Disutility of commute
q = 0.1;          % Job destruction rate
b = 0.0;          % Flow utility of unemployment
lambda = 0.5;     % Job offer arrival rate
r = 0.05;         % Discount rate

% Commute distances (0 to 2 in steps of 0.1)
tau_grid = linspace(0,2,21);

% Wage distribution (log-normal for example)
mu_w = 2; sigma_w = 0.5;
w_grid = linspace(0, 5, 100); % log wages
H = @(w) normcdf(w, mu_w, sigma_w); % CDF of log wage
h = @(w) normpdf(w, mu_w, sigma_w); % PDF of log wage

% Utility function
u = @(w, tau) w - alpha * tau; % since w = log W

% Reservation log wage curve: phi(tau) = phi(0) + alpha * tau
% We need to solve for phi(0) numerically

% Bellman equation for rU (phi(0)):
% rU = b + (lambda/(r+q)) * ∫∫ 1_{w - alpha*tau > rU} (w - alpha*tau - rU) dH(w, tau)
% For simplicity, assume tau is fixed for now, or integrate over its distribution if needed


% Solve for phi(0) numerically for a given tau (e.g., tau = 0)
tau0 = 0;
phi0_guess = 1;
phi0 = fzero(@(phi0) bellman_phi0(phi0, alpha, q, b, lambda, r, w_grid, h, tau0), phi0_guess);

% Now get reservation wage for all tau
phi_tau = phi0 + alpha * tau_grid;

% Plot reservation wage curve
figure;
plot(tau_grid, phi_tau, 'LineWidth', 2);
xlabel('Commute distance (\tau)');
ylabel('Reservation log wage \phi(\tau)');
title('Reservation log wage curve');
grid on;


% Define function to solve for phi0
function F = bellman_phi0(phi0, alpha, q, b, lambda, r, w_grid, h, tau)
    integrand = @(w) (w - alpha*tau - phi0) .* (w - alpha*tau > phi0);
    integral_val = trapz(w_grid, integrand(w_grid) .* h(w_grid));
    F = phi0 - (b/r + (lambda/(r+q)) * integral_val);
end