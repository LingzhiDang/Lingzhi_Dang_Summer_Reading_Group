clear all; 
close all; 
clc;

%% Parameter

gamma_base = 4;     % Base income level
phi = 2;            % Base income difference
pi_base = 0.3;      % Base fertility probability

% Male income
Y_min = 0;
Y_max = 6;

g_H = 0.35;          % Measure of H-type women
g_L = 0.65;          % Measure of L-type women

% Cutoff values for matching analysis
y_cutoff_top = Y_max - g_H * (Y_max - Y_min);      % If H-types get top men: [y_cutoff_top, Y_max]
y_cutoff_bottom = Y_min + g_H * (Y_max - Y_min);   % If H-types get bottom men: [Y_min, y_cutoff_bottom]

%% Surplus function
% Two-type surplus difference function: Delta^{H-L}(y)
delta_hl_twotype = @(y, delta_gamma, delta_pi) ...
    0.25 * (-delta_pi) * y.^2 + ...
    0.5 * (pi_base * (gamma_base + delta_gamma - 1) - (pi_base + delta_pi) * (gamma_base - 1)) * y + ...
    0.25 * (pi_base * (gamma_base + delta_gamma - 1)^2 - (pi_base + delta_pi) * (gamma_base - 1)^2);

% Validate surplus function with test case
delta_gamma_test = 2.0;
delta_pi_test = 0.3;

% Calculate coefficients
a_test = -0.25 * delta_pi_test;
b_test = 0.5 * (pi_base * (gamma_base + delta_gamma_test - 1) - (pi_base + delta_pi_test) * (gamma_base - 1));
y_star_test = -b_test / (2 * a_test);

% Create parameter grids (Low's Fig 4)
nmax = 1000;
delta_gamma_vec = linspace(1, 3, nmax);  % Income premium range                                   
delta_pi_vec = linspace(0, 0.7, nmax);   % Fertility disadvantages range                                   
matchtype_mat = zeros(length(delta_gamma_vec), length(delta_pi_vec));

%% Equilibrium
% Loop through parameter values (as in Low)
for i = 1:nmax
    for j = 1:nmax
        delta_gamma = delta_gamma_vec(i);
        delta_pi = delta_pi_vec(j);
        
        % Calculate surplus differences at critical points
        delta_richest = delta_hl_twotype(Y_max, delta_gamma, delta_pi);
        delta_poorest = delta_hl_twotype(Y_min, delta_gamma, delta_pi);
        delta_marginal_top = delta_hl_twotype(y_cutoff_top, delta_gamma, delta_pi);
        delta_marginal_bottom = delta_hl_twotype(y_cutoff_bottom, delta_gamma, delta_pi);
        
        % Equilibrium classification
        condition1_assortative = (delta_richest - delta_marginal_top) >= 0;
        condition2_reverse = (delta_poorest - delta_marginal_bottom) >= 0;
        
        if condition1_assortative
            matchtype_mat(i,j) = 1;     % Eqm 1: Assortative (top)
        elseif condition2_reverse
            matchtype_mat(i,j) = 3;     % Eqm 3: Reverse assortative (bottom)
        else
            matchtype_mat(i,j) = 2;     % Eqm 2: Non-monotonic (middle)
        end
     end
end


%% Replicating Fig 4 in the paper with only 2 type of women now

figure(1);
set(gcf, 'Position', [100, 100, 800, 600]);
colormap(gray(5));
contourf(delta_pi_vec, delta_gamma_vec, matchtype_mat, [1 2 3]);

str1 = {'Eqm 1:', 'Assortative'};
text(0.06, 2.7, str1, 'color', 'white', 'FontSize', 14, 'FontName', 'Times', 'HorizontalAlignment', 'center');

str2 = {'Eqm 2:', 'Non-monotonic'};
text(0.15, 2.0, str2, 'color', 'black', 'FontSize', 14, 'FontName', 'Times', 'HorizontalAlignment', 'center');

str3 = {'Eqm 3:', 'Reverse', 'Assortative'};
text(0.55, 1.4, str3, 'color', 'black', 'FontSize', 14, 'FontName', 'Times', 'HorizontalAlignment', 'center');

unique_types = unique(matchtype_mat(:));
ax = gca;
ax.FontName = 'Times';
ax.FontSize = 16;
xlabel('$\delta_\pi$', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
ylabel('$\delta_\gamma$', 'FontSize', 20, 'FontName', 'Times', 'Interpreter','latex');
set(get(gca,'ylabel'), 'rotation', 0);

yticks([1 1.2 1.4 1.6 1.8 2 2.2 2.4 2.6 2.8 3]);

%% Parameter combination

test_cases = [
    0.03, 2.7;   
    0.15, 2.2;   
    0.45, 1.3;   
];

for k = 1:size(test_cases, 1)
    delta_pi_test = test_cases(k, 1);
    delta_gamma_test = test_cases(k, 2);
    
    % Calculate surplus differences
    delta_richest_test = delta_hl_twotype(Y_max, delta_gamma_test, delta_pi_test);
    delta_marginal_top_test = delta_hl_twotype(y_cutoff_top, delta_gamma_test, delta_pi_test);
    delta_poorest_test = delta_hl_twotype(Y_min, delta_gamma_test, delta_pi_test);
    delta_marginal_bottom_test = delta_hl_twotype(y_cutoff_bottom, delta_gamma_test, delta_pi_test);
    
    % Find closest grid point
    [~, i_idx] = min(abs(delta_gamma_vec - delta_gamma_test));
    [~, j_idx] = min(abs(delta_pi_vec - delta_pi_test));
    
    equilibrium_code = matchtype_mat(i_idx, j_idx);
    
    switch equilibrium_code
        case 1
            eq_name = 'Assortative (Eqm 1)';
        case 2
            eq_name = 'Non-Monotonic (Eqm 2)';
        case 3
            eq_name = 'Reverse Assortative (Eqm 3)';
        otherwise
            eq_name = 'Other';
    end
end


%% Surplus difference

% Define parameter combinations to loop through 
param_combinations = [
    2.5, 0.05;   
    2.2, 0.15;   
    1.8, 0.25;   
    1.3, 0.45;   
];

colors = [
    0, 0, 0;          
    0, 0, 0;     
    0, 0, 0;     
    0, 0, 0;     
];

line_styles = {'-', '--', ':', '-.'};

equilibrium_names = {'', '', '', ''};  

y_grid = linspace(Y_min, Y_max, 1000);

% Figure 2: Multiple surplus difference curves
figure(2);
set(gcf, 'Position', [150, 150, 1000, 700]);

% Loop through parameter combinations
for k = 1:size(param_combinations, 1)
    delta_gamma_k = param_combinations(k, 1);
    delta_pi_k = param_combinations(k, 2);
    
    % Calculate surplus difference for this parameter combination
    delta_k = delta_hl_twotype(y_grid, delta_gamma_k, delta_pi_k);
    
    % Find peak location
    a_coeff_k = -0.25 * delta_pi_k;
    b_coeff_k = 0.5 * (pi_base * (gamma_base + delta_gamma_k - 1) - (pi_base + delta_pi_k) * (gamma_base - 1));
    y_star_k = -b_coeff_k / (2 * a_coeff_k);
    
    % Determine equilibrium type by checking stability conditions 
    delta_richest_k = delta_hl_twotype(Y_max, delta_gamma_k, delta_pi_k);
    delta_marginal_top_k = delta_hl_twotype(y_cutoff_top, delta_gamma_k, delta_pi_k);
    delta_poorest_k = delta_hl_twotype(Y_min, delta_gamma_k, delta_pi_k);
    delta_marginal_bottom_k = delta_hl_twotype(y_cutoff_bottom, delta_gamma_k, delta_pi_k);
    
    if (delta_richest_k - delta_marginal_top_k) >= 0
        eq_type = 'Assortative';
    elseif (delta_poorest_k - delta_marginal_bottom_k) >= 0
        eq_type = 'Reverse Assortative';
    else
        eq_type = 'Non-Monotonic';
    end
    
    equilibrium_names{k} = eq_type;
    
    subplot(2, 2, k);
    plot(y_grid, delta_k, 'LineWidth', 2.5, 'Color', colors(k, :));
    hold on;
    plot(y_star_k, delta_hl_twotype(y_star_k, delta_gamma_k, delta_pi_k), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red');
    plot(Y_max, delta_richest_k, 'bs', 'MarkerSize', 8, 'MarkerFaceColor', 'blue');
    plot(y_cutoff_top, delta_marginal_top_k, 'gs', 'MarkerSize', 8, 'MarkerFaceColor', 'green');
    yline(0, '--', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
    xline(y_cutoff_top, ':', 'Color', [0.7, 0.7, 0.7], 'LineWidth', 1);
    xlabel('Male Income $y$', 'FontSize', 12, 'Interpreter', 'latex');
    ylabel('$\Delta^{H-L}(y)$', 'FontSize', 12, 'Interpreter', 'latex');
    title_str = sprintf('$\\delta_{\\gamma} = %.1f$, $\\delta_{\\pi} = %.2f$ (%s)', delta_gamma_k, delta_pi_k, eq_type);
    title(title_str, 'FontSize', 11, 'Interpreter', 'latex'); 
    grid off;
    
    if k == 1
        legend({'$\Delta^{H-L}(y)$', 'Peak $y^*$', 'Richest', 'Marginal'}, 'FontSize', 9, 'Location', 'best', 'Interpreter', 'latex');
    end
end

% Figure 3: All curves together
figure(3);
set(gcf, 'Position', [200, 200, 800, 700]);

legend_entries = {};
for k = 1:size(param_combinations, 1)
    delta_gamma_k = param_combinations(k, 1);
    delta_pi_k = param_combinations(k, 2);    
    delta_k = delta_hl_twotype(y_grid, delta_gamma_k, delta_pi_k);
    plot(y_grid, delta_k, 'LineWidth', 2.5, 'Color', colors(k, :), 'LineStyle', line_styles{k});
    hold on;    
    legend_entries{k} = sprintf('$\\delta_{\\gamma} = %.1f$, $\\delta_{\\pi} = %.2f$ (%s)', ...
        delta_gamma_k, delta_pi_k, equilibrium_names{k});
end
yline(0, '--', 'Color', [0.5, 0.5, 0.5], 'LineWidth', 1);
xlabel('Male Income $y$', 'FontSize', 14, 'Interpreter','latex');
ylabel('Surplus Advantage $\Delta^{H-L}(y)$', 'FontSize', 14, 'Interpreter','latex');
% title('Surplus Difference Functions: Parameter Comparison', 'FontSize', 16);
legend(legend_entries, 'FontSize', 10, 'Location', 'southoutside', 'Interpreter','latex');

grid off;