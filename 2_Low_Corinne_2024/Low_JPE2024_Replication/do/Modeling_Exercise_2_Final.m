clear all;
close all; 
clc;

% First simulation: cost [0,15], uniform distribution
% Second simulation: cost [-10,20], normal distribution (5, 5^2)
% Third simulation: cost [-25,35], normal distribution (5,10^2)

%% Data import

data_men = readtable('census_men.csv');
data_women = readtable('census_women.csv');
childdist = readtable('kids4categories.csv');
addpath(fullfile(pwd,'m files'));

%% Parameters and array initialization
N = 400;  
a = 3;    % Reduced from 5
eduN = 4; % number of education categories
SimResults = [];

%% Main simulation
tic      % Loop timer
for i = 1:3
    year = i*20 + 1950;
    
    % split the data into vectors
    WomenToSampleFrom = data_women(data_women.year == year,:);
    MenToSampleFrom = data_men(data_men.year == year,:);
    WomenWeights = WomenToSampleFrom.perwt;
    MenWeights = MenToSampleFrom.perwt;
    Prob = childdist(childdist.year == year,:);
 
    % cost of investment 
    % Low's range was [-10, 20]
    cost_mean = 5;                                             % Mean 
    cost_std = 10;                                             % Standard deviation 
    cmin = cost_mean - 3*cost_std;                             % = 5 - 15 = -10
    cmax = cost_mean + 3*cost_std;                             % = 5 + 15 = 20
        
    % simulate matches 
    for sim = 1:a                

        % seed 
        seed = sim*100+i;
        s = RandStream('mlfg6331_64','Seed',seed);     
        
        % sample with ecdf draw function from Low's replication code
        MenSample = ecdfdraw(MenToSampleFrom.inctot_adj,N,'linear',seed);
        WomenSample = zeros(N,2); 
        
        g = zeros(eduN,1);
        for m=1:1:eduN
            g(m) = round(sum(WomenToSampleFrom.educ_cat==m)/numel(WomenToSampleFrom.educ_cat)* N,0);
        end
        
        diff = sum(g) - N;
        if diff > 0 
            g(1) = g(1) - diff; 
        elseif diff < 0 
            g(1) = g(1) - diff;
        end
        
        % type: 1st column of W (1,2,3) - no highly educated initially
        WomenSample(1:g(1),1) = 1;
        for n = 2:1:eduN
            WomenSample(sum(g(1:n-1))+1:sum(g(1:n)),1) = n;
        end
        WomenSample(WomenSample(:,1)==4,1) = 3;
        
        % income: 2nd column of W - match empirical distribution
        for k = 1:1:eduN     
            if k == 1
                WomenSample(1:g(1),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 1),g(1),'linear',seed);
            elseif k == 4 % draw from college-educated for those who are actually highly educated
                WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 3),g(k),'linear',seed);
            else 
                WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == k),g(k),'linear',seed);
            end
        end    
        
        % from array to table
        WomenSample = array2table(WomenSample,'VariableNames',{'educ_cat','inctot_adj'});
        MenSample = array2table(MenSample,'VariableNames',{'inctot_adj'});
       
        % potential income for college-educated if they get highly educated based on percentile
        INC_edu3 = WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat==3);
        pct_edu3 = prctile(INC_edu3,[1:100])';
        INC_edu4 = WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat==4);
        pct_edu4 = prctile(INC_edu4,[1:100])';  
        pct = [pct_edu3 pct_edu4];
        
        % call surplus-maximizing matching algorithm
        tmp = matchsim_edu_endogenous(WomenSample,MenSample,pct,Prob,cmin,cmax);
        
        % stack all matching results
        output = [repmat(year,N,1) repmat(sim,N,1) tmp];
        SimResults = [SimResults; output];  % Append results
        
        % Show progress
        fprintf('Completed. Elapsed time: %.1f seconds\n', toc);
    end
end      

fprintf('\nTotal simulation time: %.1f seconds\n', toc); % keep track of total simulation time


%% format results

R = array2table(SimResults,'VariableNames',{'year','sim','educ_cat','inctot_adj_edu3','inctot_adj_edu4',...
    'inctot_adj_sp','surplus','highly_edu_decision'});

% Save results
save('simulation_results_backup.mat', 'R');

% Load the saved simulation data

loaded_data = load("simulation_results_backup.mat");

R = loaded_data.R;
head(R)

%% Means

MatchOutput = zeros(3,eduN+1);
MatchOutput(:,1) = [1970;1990;2010];
Surplus = zeros(3,eduN+1);
Surplus(:,1) = [1970;1990;2010];
Output_edu = zeros(3,3);
Output_edu(:,1) = [1970,1990,2010];

i=1;
for y=1970:20:2010
    
    for e=1:eduN       
        if e==eduN  % For highly educated (e==4), use highly_edu_decision
            MatchOutput(i,e+1) = mean(R.inctot_adj_sp(R.year == y & R.highly_edu_decision == 1));
            Surplus(i,e+1) = mean(R.surplus(R.year == y & R.highly_edu_decision == 1));
        else
            MatchOutput(i,e+1) = mean(R.inctot_adj_sp(R.year == y & R.educ_cat == e));
            Surplus(i,e+1) = mean(R.surplus(R.year == y & R.educ_cat == e));
        end      
    end
  
    % fraction highly edu
    Output_edu(i,2) = mean(R.highly_edu_decision(R.year == y));
    % actual percentage from data
    data_edu = data_women.educ_cat(data_women.year == y); 
    Output_edu(i,3) = sum(data_edu == 4)/size(data_edu,1);
    
    i=i+1;   
end

%% Graph Spousal Income 

figure
plot(MatchOutput(:,1),MatchOutput(:,5),'-','LineWidth',1,'color',[0 0 0]);
xlabel('Census Year','FontSize',12)
xticks([1970 1990 2010]) 
ylabel('Spousal Income, 1999 USDs','FontSize',12)
yticks([30000 45000 60000 75000 90000 105000 120000 135000 150000]) 
ytick = get(gca, 'ytick');
yticklabel = strread(sprintf('%,.0f;', ytick), '%s', 'delimiter', ';')
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
set(gca,'fontname','times') 


%% Graph Investment in Education 

figure
clf;
plot(Output_edu(:,1), Output_edu(:,2), '-', 'LineWidth', 2, 'Color', [0 0 0]);
hold on 
plot(Output_edu(:,1), Output_edu(:,2), '-', 'LineWidth', 1, 'Color', [0 0 0]);
plot(Output_edu(:,1), Output_edu(:,3), ':', 'LineWidth', 1, 'Color', [0.5 0.5 0.5]);
hold off
xlabel('Census Year', 'FontSize', 14, 'FontName', 'Times');
ylabel('Fraction Highly Educated', 'FontSize', 14, 'FontName', 'Times');
xticks([1970 1990 2010]);
xlim([1970 2010]);
ylim_auto = ylim;
if max(Output_edu(:,2:3), [], 'all') < 0.15
    ylim([0 0.2]);  
else
    ylim([0 max(Output_edu(:,2:3), [], 'all') * 1.1]);  
end
legend('', 'Simulation', 'Data', 'FontSize', 12, 'Location', 'northwest', 'FontName', 'Times');
set(gca, 'FontName', 'Times', 'FontSize', 12);
title('');
figure(gcf);
