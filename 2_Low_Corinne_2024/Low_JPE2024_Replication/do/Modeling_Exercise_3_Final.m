clear; 
close all;
clc;

%% Data import

data_men = readtable('census_men.csv');
data_women = readtable('census_women.csv');
childdist = readtable('kids4categories.csv');
addpath(fullfile(pwd,'m files'));

%% Parameters

% Income-leisure trade-off parameters (Men)

Y_max = 120000;         % Maximum male income (scaled)
T_max = 1;              % Maximum male leisure time
kappa = 1.2;            % Income-leisure trade-off curvature

% Using bounded logistic-style function to prevent explosive growth, as compared to exponential growth

alpha_min = 0.5;        % Minimum leisure valuation
alpha_max = 8.0;        % Maximum leisure valuation 
alpha_scale = 50000;    % Income scaling parameter 
alpha_steepness = 2.5;  % Steepness of transition

% Simulation parameters 

N = 400;                
a = 3;                  
eduN = 4;               

%% Functional forms

% Income-leisure trade-off function for men
leisure_time = @(y) T_max * max(0, min(1, (1 - (max(0, min(y, Y_max)) / Y_max).^kappa)));

% Female leisure valuation (bounded logistic function)
alpha_func = @(z) alpha_min + (alpha_max - alpha_min) ./ ...
    (1 + exp(-alpha_steepness * (z - alpha_scale) / alpha_scale));

%% Store results
n_years = 3;
years = [1970, 1990, 2010];
MatchOutput = zeros(n_years, eduN+1);
MatchOutput(:,1) = years';
Surplus = zeros(n_years, eduN+1);
Surplus(:,1) = years';
LeisureOutput = zeros(n_years, eduN+1);
LeisureOutput(:,1) = years';
detailed_results = cell(n_years, 1);


%% Simulation

tic % start timer

for i = 1:n_years
    
    year = years(i); 
    WomenToSampleFrom = data_women(data_women.year == year,:);
    MenToSampleFrom = data_men(data_men.year == year,:);
    WomenWeights = WomenToSampleFrom.perwt;
    MenWeights = MenToSampleFrom.perwt;
    Prob = childdist(childdist.year == year,:);
    
    temp_results = [];
    temp_leisure = [];
    
    for sim = 1:a
        
        fprintf('  Simulation %d/%d for year %d\n', sim, a, year);
        
        % Seed
        seed = sim*100+i;
        s = RandStream('mlfg6331_64','Seed',seed);
        MenSample = ecdfdraw(MenToSampleFrom.inctot_adj, N, 'linear', seed);
        WomenSample = zeros(N,2);
        
        g = zeros(eduN,1);
        for m=1:1:eduN
            g(m) = round(sum(WomenToSampleFrom.educ_cat==m)/numel(WomenToSampleFrom.educ_cat)*N, 0);
        end
        
        diff = sum(g) - N;
        if diff > 0
            g(1) = g(1) - diff;
        elseif diff < 0
            g(1) = g(1) - diff;
        end
        
        WomenSample(1:g(1),1) = 1;
        for n = 2:1:eduN
            WomenSample(sum(g(1:n-1))+1:sum(g(1:n)),1) = n;
        end
        
        for k = 1:1:eduN
            if k == 1
                WomenSample(1:g(1),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 1), g(1), 'linear', seed);
            else
                WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == k), g(k), 'linear', seed);
            end
        end
        
        WomenSample = array2table(WomenSample, 'VariableNames', {'educ_cat','inctot_adj'});
        MenSample = array2table(MenSample, 'VariableNames', {'inctot_adj'});
        
        [results, leisure_results] = matchsim_leisure_robust(WomenSample, MenSample, Prob, alpha_func, leisure_time);
        
        results_with_year = [repmat(year, N, 1), repmat(sim, N, 1), results];
        temp_results = [temp_results; results_with_year];
        
        leisure_with_year = [repmat(year, N, 1), repmat(sim, N, 1), leisure_results];
        temp_leisure = [temp_leisure; leisure_with_year];
    end
    
    for e = 1:eduN
        mask = temp_results(:,3) == e;
        if sum(mask) > 0
            MatchOutput(i, e+1) = mean(temp_results(mask, 5)); % Spousal income
            Surplus(i, e+1) = mean(temp_results(mask, 6));     % Surplus
            LeisureOutput(i, e+1) = mean(temp_leisure(mask, 5)); % Spousal leisure
        else
            MatchOutput(i, e+1) = NaN;
            Surplus(i, e+1) = NaN;
            LeisureOutput(i, e+1) = NaN;
        end
    end
    
    detailed_results{i} = struct('year', year, 'match_results', temp_results, ...
        'leisure_results', temp_leisure, 'parameters', ...
        struct('alpha_min', alpha_min, 'alpha_max', alpha_max, ...
               'alpha_scale', alpha_scale, 'alpha_steepness', alpha_steepness, ...
               'Y_max', Y_max, 'kappa', kappa));
end

toc

%% Save results

save_filename = 'leisure_model_results.mat';
save(save_filename, 'MatchOutput', 'LeisureOutput', 'Surplus', 'detailed_results', ...
     'years', 'alpha_min', 'alpha_max', 'alpha_scale', 'alpha_steepness', ...
     'Y_max', 'kappa', 'N', 'a');
data = load('leisure_model_results.mat');
LeisureOutput = data.LeisureOutput;
MatchOutput = data.MatchOutput;
Surplus = data.Surplus;

%% Figure: Spousal Income Evolution

figure
plot(MatchOutput(:,1),MatchOutput(:,5),'-','LineWidth',1,'color',[0 0 0]);
xlabel('Census Year','FontSize',12)
xticks([1970 1990 2010]) 
ylabel('Spousal Income, 1999 USDs','FontSize',12)
yticks([30000 45000 60000 75000 90000 105000 120000 135000 150000]) 
ytick = get(gca, 'ytick');
axis([1970 2010 20000 130000])
set(gca,'yticklabel', ytick,'fontname','Serif','FontSize',12)
title('')
hold on 
plot(MatchOutput(:,1),MatchOutput(:,4),'--','LineWidth',1,'color',[0 0 0]);
hold off
hold on 
plot(MatchOutput(:,1),MatchOutput(:,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off
hold on 
plot(MatchOutput(:,1),MatchOutput(:,2),'-.','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off
legend('Highly educated','College educated','Some college','HS grad or less',...
    'Location','southoutside','Orientation','horizontal','NumColumns',2,'FontSize',12)
set(gca,'fontname','Serif')

%% Figure: Spousal Leisure Evolution

figure
plot(LeisureOutput(:,1),LeisureOutput(:,5),'-','LineWidth',1,'color',[0 0 0]);
xlabel('Census Year','FontSize',12)
xticks([1970 1990 2010]) 
ylabel('Spousal Leisure Time','FontSize',12)
axis([1970 2010 0.3 0.9])
set(gca,'fontname','Serif','FontSize',12)
title('')
hold on 
plot(LeisureOutput(:,1),LeisureOutput(:,4),'--','LineWidth',1,'color',[0 0 0]);
hold off
hold on 
plot(LeisureOutput(:,1),LeisureOutput(:,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off
hold on 
plot(LeisureOutput(:,1),LeisureOutput(:,2),'-.','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off
legend('Highly educated','College educated','Some college','HS grad or less',...
    'Location','southoutside','Orientation','horizontal','NumColumns',2,'FontSize',12)

%% Figure: Female Leisure Valuation Function

figure
z_range = linspace(15000, 120000, 200);
alpha_values = alpha_func(z_range);
plot(z_range/1000, alpha_values, '-', 'LineWidth', 1, 'color', [0 0 0]);
xlabel('Female Income (thousands, 1999 USD)', 'FontSize', 12);
ylabel('Leisure Valuation $\alpha(z)$', 'FontSize', 12, 'Interpreter','latex', 'FontName','Times New Roman');
% title('Female Leisure Valuation Function', 'FontSize', 12);
set(gca,'fontname','Serif','FontSize',12)

%% Figure: Male Income-Leisure Trade-Off

figure
y_range = linspace(0, Y_max, 200);
t_values = leisure_time(y_range);
plot(y_range/1000, t_values, '-', 'LineWidth', 1, 'color', [0 0 0]);
xlabel('Male Income (thousands, 1999 USD)', 'FontSize', 12);
ylabel('Male Leisure Time', 'FontSize', 12);
% title('Male Income-Leisure Trade-off', 'FontSize', 12);
set(gca,'fontname','Serif','FontSize',12)

%% Figure: Cross-Year Comparison

figure
plot(1:eduN, MatchOutput(1, 2:end)/1000, '-', 'LineWidth', 1, 'color', [0 0 0]);
hold on
plot(1:eduN, MatchOutput(2, 2:end)/1000, '--', 'LineWidth', 1, 'color', [0 0 0]);
hold off
hold on
plot(1:eduN, MatchOutput(3, 2:end)/1000, ':', 'LineWidth', 1, 'color', [0.5 0.5 0.5]);
hold off
xlabel('Wife''s Education Level', 'FontSize', 12);
ylabel('Spousal Income (thousands USD)', 'FontSize', 12);
% title('Income Evolution by Education', 'FontSize', 12);
xticks(1:eduN);
xticklabels({'≤ HS', 'Some Coll.', 'College', 'Graduate'});
legend({'1970', '1990', '2010'}, 'Location', 'southoutside', 'FontSize', 12, 'NumColumns', 3);
set(gca,'fontname','Serif','FontSize',12)

%% Figure: Theoretical Mechanism Components

figure
test_incomes = linspace(20000, 120000, 50);
test_leisure = leisure_time(test_incomes);
test_alpha = alpha_func(test_incomes);
subplot(2,1,1)
plot(test_incomes/1000, test_leisure, '-', 'LineWidth', 1, 'color', [0 0 0]);
xlabel('Income (thousands USD)', 'FontSize', 12);
ylabel('Male Leisure Time', 'FontSize', 12);
% title('Male Leisure vs Income', 'FontSize', 12);
set(gca,'fontname','Serif','FontSize',12)

subplot(2,1,2)
plot(test_incomes/1000, test_alpha, '-', 'LineWidth', 1, 'color', [0 0 0]);
xlabel('Income (thousands USD)', 'FontSize', 12);
ylabel('Female Leisure Valuation', 'FontSize', 12);
% title('Female Valuation vs Income', 'FontSize', 12);
set(gca,'fontname','Serif','FontSize',12)

function [output, leisure_output] = matchsim_leisure_robust(WomenSample, MenSample, Prob, alpha_func, leisure_time)
    
    % Parameters (following Low's structure)
    N = size(WomenSample, 1);
    beta = 0.08;
    tmax_men = 25;
    tmax_women = 20;
    
    % Men - NPV calculation + leisure with bounds checking
    flow = MenSample.inctot_adj;
    
    % Filter out problematic income values
    flow = max(flow, 0); % Remove negative incomes
    flow(flow > 200000) = 200000; % Cap extreme values
    
    npv = 0;
    for t = 0:1:tmax_men
        npv = npv + flow ./ ((1+beta)^t);
    end
    
    % Array for men's characteristics
    Nm = N;
    M = zeros(Nm, 3);
    M(:, 1) = npv;
    M(:, 2) = flow;
    M(:, 3) = leisure_time(flow); % Apply robust leisure function
    
    % Verify leisure bounds
    M(:, 3) = max(0, min(1, M(:, 3))); % Enforce [0,1] bounds
    
    fprintf('    Men leisure range: %.3f to %.3f (robust)\n', min(M(:,3)), max(M(:,3)));
    
    % Women - NPV calculation
    flow = WomenSample.inctot_adj;
    flow = max(flow, 0); % Remove negative incomes
    
    npv = zeros(N, 1);
    for t = 0:1:tmax_women
        npv = npv + flow ./ ((1+beta)^t);
    end
    
    % Array for women
    W = zeros(N, 3);
    W(:, 1) = WomenSample.educ_cat;
    W(:, 2) = npv;
    W(:, 3) = flow;
    
    % Alpha values with robust function
    alpha_vals = alpha_func(W(:,3));
    fprintf('    Women alpha range: %.3f to %.3f (robust)\n', min(alpha_vals), max(alpha_vals));
    
    % Fertility probabilities (following Low)
    educ_cat = W(:, 1);
    educ_cat = array2table(educ_cat, 'VariableNames', {'educ_cat'});
    P = join(educ_cat, Prob);
    P = P{:, :};
    
    % Desired family size
    children = [1 2 3 4]';
    D = randsample(children, N, true, [0 0 0 1]);
    
    % Surplus matrix
    S = zeros(N, Nm);
    for w = 1:N
        for m = 1:Nm
            yz = W(w, 2) + M(m, 1);
            S(w, m) = -yz; % Single values
            
            % Original Low surplus from children
            a = 0;
            d = D(w);
            while a ~= d+1
                child_surplus = P(w, a+4) * (yz - (a/d)*(yz+1)/2) * ((a/d) * (yz-1)/2);
                S(w, m) = S(w, m) + child_surplus;
                a = a+1;
            end
            
            % ROBUST leisure preference component
            woman_income = W(w, 3);
            man_leisure = M(m, 3);
            woman_alpha = alpha_func(woman_income);
            
            % Scaled leisure value (balanced to match income effects)
            leisure_value = woman_alpha * man_leisure * 30000; % Reduced scaling
            
            S(w, m) = S(w, m) + leisure_value;
            S(w, m) = -S(w, m); % Hungarian minimizes
        end
    end
    
    % Matching
    [X, TotalSurplus] = Hungarian1(S);
    [row, col] = find(X);
    
    % Output
    Y_M_match = zeros(N, 4);
    Leisure_match = zeros(N, 3);
    
    Y_M_match(:, 1) = W(:, 1);  % Education
    Y_M_match(:, 2) = W(:, 3);  % Woman's income
    Leisure_match(:, 1) = W(:, 1);
    Leisure_match(:, 2) = W(:, 3);
    
    for i = 1:Nm
        Y_M_match(row(i), 3) = M(i, 2);  % Spousal income
        Y_M_match(row(i), 4) = -S(row(i), i);  % Surplus
        Leisure_match(row(i), 3) = M(i, 3);  % Spousal leisure
    end
    
    output = Y_M_match;
    leisure_output = Leisure_match;
end
