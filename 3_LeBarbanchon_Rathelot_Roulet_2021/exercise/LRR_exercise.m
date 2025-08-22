clear all; close all; clc;

%% Exercise 
% Baseline parameters (from the paper)
alpha_men = 0.121;     
alpha_women = 0.148;   
q_base = 0.11;       % Job destruction rate 
b_base = 0.02;       % Flow utility of unemployment 
lambda_base = 0.28;  % Job offer arrival rate 
r = 0.011;           % Discount rate

% Number of quadrature points
N_w = 50; % for wage integration
N_tau = 20; % for commute integration

% Get quadrature points and weights for wage and commute
[w_points, w_weights] = lgwt(N_w, 0, 5); % wage points
[tau_points, tau_weights] = lgwt(N_tau, 0, 2); % commute points

% Wage distribution (log-normal)
mu_w = 2; sigma_w = 0.5;
h = @(w) normpdf(w, mu_w, sigma_w); % pdf of log wage

%% Parameter
lambda_values = [0.1, 0.4, 0.8];
b_values = [0, 0.05, 0.1];
q_values = [0.03, 0.20, 0.30];

%% Solve baseline case for both men and women
tau0 = 0;
phi0_guess = 1;

% Men's baseline reservation curve
phi0_men = fzero(@(phi0) bellman_phi0(phi0, alpha_men, q_base, b_base, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
phi_tau_men_base = phi0_men + alpha_men * tau_points;

% Women's baseline reservation curve
phi0_women = fzero(@(phi0) bellman_phi0(phi0, alpha_women, q_base, b_base, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
phi_tau_women_base = phi0_women + alpha_women * tau_points;

%% FIGURE 1: Lambda (Job Offer Arrival Rate) Effects
figure('Position', [100, 100, 1400, 600]);

% Men - Lambda effects
subplot(1,2,1);
hold on;
plot(tau_points, phi_tau_men_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (\\lambda=%.2f)', lambda_base));

line_styles = {'--', ':', '-.'};
colors = {'b', 'r', 'g'};
for i = 1:length(lambda_values)
    lambda_curr = lambda_values(i);
    phi0_men_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_men, q_base, b_base, lambda_curr, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_men_curr = phi0_men_curr + alpha_men * tau_points;
    plot(tau_points, phi_tau_men_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('\\lambda=%.1f', lambda_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('MEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

% Women - Lambda effects
subplot(1,2,2);
hold on;
plot(tau_points, phi_tau_women_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (\\lambda=%.2f)', lambda_base));

for i = 1:length(lambda_values)
    lambda_curr = lambda_values(i);
    phi0_women_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_women, q_base, b_base, lambda_curr, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_women_curr = phi0_women_curr + alpha_women * tau_points;
    plot(tau_points, phi_tau_women_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('\\lambda=%.1f', lambda_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('WOMEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

sgtitle('Effect of Job Offer Arrival Rate (\lambda)', 'FontSize', 16, 'FontWeight', 'bold');

%% FIGURE 2: Flow Utility of Unemployment (b) Effects
figure('Position', [200, 200, 1400, 600]);

% Men - Flow utility effects
subplot(1,2,1);
hold on;
plot(tau_points, phi_tau_men_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (b=%.2f)', b_base));

for i = 1:length(b_values)
    b_curr = b_values(i);
    phi0_men_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_men, q_base, b_curr, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_men_curr = phi0_men_curr + alpha_men * tau_points;
    plot(tau_points, phi_tau_men_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('b=%.2f', b_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('MEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

% Women - Flow utility effects
subplot(1,2,2);
hold on;
plot(tau_points, phi_tau_women_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (b=%.2f)', b_base));

for i = 1:length(b_values)
    b_curr = b_values(i);
    phi0_women_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_women, q_base, b_curr, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_women_curr = phi0_women_curr + alpha_women * tau_points;
    plot(tau_points, phi_tau_women_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('b=%.2f', b_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('WOMEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

sgtitle('Effect of Flow Utility of Unemployment (b)', 'FontSize', 16, 'FontWeight', 'bold');

%% FIGURE 3: Job Destruction Rate (q) Effects
figure('Position', [300, 300, 1400, 600]);

% Men - Job destruction rate effects
subplot(1,2,1);
hold on;
plot(tau_points, phi_tau_men_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (q=%.2f)', q_base));

for i = 1:length(q_values)
    q_curr = q_values(i);
    phi0_men_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_men, q_curr, b_base, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_men_curr = phi0_men_curr + alpha_men * tau_points;
    plot(tau_points, phi_tau_men_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('q=%.2f', q_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('MEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

% Women - Job destruction rate effects
subplot(1,2,2);
hold on;
plot(tau_points, phi_tau_women_base, 'k-', 'LineWidth', 4, 'DisplayName', sprintf('Baseline (q=%.2f)', q_base));

for i = 1:length(q_values)
    q_curr = q_values(i);
    phi0_women_curr = fzero(@(phi0) bellman_phi0(phi0, alpha_women, q_curr, b_base, lambda_base, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
    phi_tau_women_curr = phi0_women_curr + alpha_women * tau_points;
    plot(tau_points, phi_tau_women_curr, [colors{i} line_styles{i}], 'LineWidth', 3, 'DisplayName', sprintf('q=%.2f', q_curr));
end

xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('WOMEN', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

sgtitle('Effect of Job Destruction Rate (q)', 'FontSize', 16, 'FontWeight', 'bold');

%% FIGURE 4: Direct Gender Comparison
figure('Position', [400, 400, 800, 600]);
hold on;
plot(tau_points, phi_tau_men_base, 'b-', 'LineWidth', 5, 'DisplayName', sprintf('Men (\\alpha=%.2f)', alpha_men));
plot(tau_points, phi_tau_women_base, 'r-', 'LineWidth', 5, 'DisplayName', sprintf('Women (\\alpha=%.2f)', alpha_women));
xlabel('Commute distance (\tau)', 'FontSize', 14);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 14);
title('Baseline Gender Comparison: Reservation Wage Curves', 'FontSize', 16, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 13);
grid on;
set(gca, 'FontSize', 12);

%% ADDITIONAL ANALYSIS: Simultaneous q increase and lambda decrease
% Similar approach 
% Define new parameters for the shock
q_shock = 0.20;      % increased job destruction rate (from 0.11 baseline)
lambda_shock = 0.10; % decreased job offer arrival rate (from 0.28 baseline)

% Solve new reservation wage curves with both shocks for men
phi0_men_shock = fzero(@(phi0) bellman_phi0(phi0, alpha_men, q_shock, b_base, lambda_shock, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
phi_tau_men_shock = phi0_men_shock + alpha_men * tau_points;

% Solve new reservation wage curves with both shocks for women
phi0_women_shock = fzero(@(phi0) bellman_phi0(phi0, alpha_women, q_shock, b_base, lambda_shock, r, w_points, w_weights, tau_points, tau_weights, h, tau0), phi0_guess);
phi_tau_women_shock = phi0_women_shock + alpha_women * tau_points;

%% FIGURE 5: Baseline vs Shock Comparison for Men
figure('Position', [500, 500, 800, 600]);
hold on;
plot(tau_points, phi_tau_men_base, 'b-', 'LineWidth', 4, 'DisplayName', sprintf('Men Baseline (q=%.2f, \\lambda=%.2f)', q_base, lambda_base));
plot(tau_points, phi_tau_men_shock, 'r--', 'LineWidth', 3, 'DisplayName', sprintf('Men Shock (q=%.2f, \\lambda=%.2f)', q_shock, lambda_shock));
xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title(sprintf('MEN: Baseline vs Simultaneous Shock (\\alpha=%.3f)', alpha_men), 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

%% FIGURE 6: Baseline vs Shock Comparison for Women
figure('Position', [600, 600, 800, 600]);
hold on;
plot(tau_points, phi_tau_women_base, 'b-', 'LineWidth', 4, 'DisplayName', sprintf('Women Baseline (q=%.2f, \\lambda=%.2f)', q_base, lambda_base));
plot(tau_points, phi_tau_women_shock, 'r--', 'LineWidth', 3, 'DisplayName', sprintf('Women Shock (q=%.2f, \\lambda=%.2f)', q_shock, lambda_shock));
xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title(sprintf('WOMEN: Baseline vs Simultaneous Shock (\\alpha=%.3f)', alpha_women), 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);

%% FIGURE 7: Direct Comparison of Shock Effects by Gender
figure('Position', [700, 700, 800, 600]);
hold on;
plot(tau_points, phi_tau_men_base, 'b-', 'LineWidth', 3, 'DisplayName', 'Men Baseline');
plot(tau_points, phi_tau_men_shock, 'b--', 'LineWidth', 3, 'DisplayName', 'Men Shock');
plot(tau_points, phi_tau_women_base, 'r-', 'LineWidth', 3, 'DisplayName', 'Women Baseline');
plot(tau_points, phi_tau_women_shock, 'r--', 'LineWidth', 3, 'DisplayName', 'Women Shock');
xlabel('Commute distance (\tau)', 'FontSize', 12);
ylabel('Reservation log wage \phi(\tau)', 'FontSize', 12);
title('Gender Comparison: Baseline vs Simultaneous Shock Effects', 'FontSize', 14, 'FontWeight', 'bold');
legend('Location', 'northwest', 'FontSize', 11);
grid on;
set(gca, 'FontSize', 11);