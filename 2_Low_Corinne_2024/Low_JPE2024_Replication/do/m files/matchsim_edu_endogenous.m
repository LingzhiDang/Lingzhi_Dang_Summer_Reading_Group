% this function takes as inputs a Mx3 matrix:
% first column is woman's education group, second is her income, third is
% spousal income
% 2nd input is a 3x1 matrix with fecundity prob per education type
% N is the number of draws
% output is a 3x1 matrix with mean spousal income for each of the three
% education groups

function [output] = matchsim_edu_endogenous(WomenSample,MenSample,pct,Prob,cmin,cmax)



%% PARAMETERS 
    N = size(WomenSample,1);
    beta = 0.08;
    tmax_men = 25;
    tmax_women = 20;
    
    
    
%% MEN - draw 1 type
    
    % NPV t from 0 to 25
    flow = MenSample.inctot_adj;
    npv = 0; 
    for t=0:1:tmax_men
         npv =  npv + flow ./ ((1+beta)^t);
    end 
    
    % array for men's income
    Nm = N;
    M = zeros(Nm,2);    
    M(:,1) = npv;
    M(:,2) = flow;
    
        
    
%% WOMEN 
    
    % NPV t from 0 to 20 
    flow = WomenSample.inctot_adj;
    npv = zeros(N,1);
    for t=0:1:tmax_women
          npv =  npv + flow ./ ((1+beta)^t);
    end
    
    % array for women's income and fecundity
    W = zeros(N,3);
    W(:,1) = WomenSample.educ_cat;    
    W(:,2) = npv;
    W(:,3) = flow;
   
   
    % income for college-educated if they get highly educated
    % compute percentiles from input data
    pct_edu3 = pct(:,1);
    pct_edu4 = pct(:,2);  
    
    rank_edu3 =zeros(N,1);
    for i=1:N
        searchvalue = W(i,3);
        j=1;
        while pct_edu3(j) < searchvalue && j < 100
            j=j+1;
        end
        rank_edu3(i) = j;
    end
    W_edu4_potential = pct_edu4(rank_edu3);
    flow = W(:,3);
    flow(W(:,1)==3) = W_edu4_potential(W(:,1)==3); % only replace for college-educated
    npv = zeros(N,1);
    for t=0:1:tmax_women
          npv =  npv + flow ./ ((1+beta)^t);
    end      
    W(:,4) = npv;
    W(:,5) = flow;   

    
    % fertility probabilities
    educ_cat = W(:,1);
    educ_cat = array2table(educ_cat,'VariableNames',{'educ_cat'});
    P = join(educ_cat,Prob);
    P_edu3 =  P{:,:};
    P_edu4 = P_edu3;
    P_edu4_mat = [Prob.nochild(Prob.educ_cat==4) Prob.onechild(Prob.educ_cat==4) Prob.twochild(Prob.educ_cat==4) Prob.threechild(Prob.educ_cat==4) Prob.fourchild(Prob.educ_cat==4)  ];    
    size_edu3 = sum(WomenSample.educ_cat == 3);
    P_edu4_mat = repelem(P_edu4_mat,[size_edu3],1);   
    P_edu4(P_edu4(:,1)==3,4:8) = P_edu4_mat ; % prob for highly educated   
    
    % desired family size: everyone wants 4
    children = [1 2 3 4]';  
    D = randsample(children,N,true,[0 0 0 1]);  

   


%% cost of investment
    
    %from uniform distribution
    cmin = cmin * 10^10;
    cmax = cmax * 10^10;
    cost =  zeros(N,1);
    %only college-educated have a cost
    %less than college cannot invest
    cost_draws = linspace(cmin,cmax,sum(WomenSample.educ_cat == 3));
    cost(N-sum(WomenSample.educ_cat == 3)+1:N) = cost_draws;
    
    
    
       
%% SURPLUS MATRIX
    
    % define array
    S = zeros(N,Nm);
    highly_educated_decision = zeros(N,Nm);
    for w=1:N
        for m=1:Nm
            
            yz_edu3 = W(w,2)+ M(m,1);
            yz_edu4 = W(w,4)+ M(m,1);
            
            S_edu3 = -yz_edu3; % single values
            S_edu4 = -yz_edu4; % single values
            
            a = 0;        % actual children start from 0
            d = D(w);     % desired family size of woman w
            while a ~= d+1
                % surplus if college-educated 
                S_edu3 = S_edu3 + P_edu3(w,a+4) * (  yz_edu3 - (a/d)*(yz_edu3+1)/2  ) * (  (a/d) *  (yz_edu3-1)/2  );
                S_edu4 = S_edu4 + P_edu4(w,a+4) * (  yz_edu4 - (a/d)*(yz_edu4+1)/2  ) * (  (a/d) *  (yz_edu4-1)/2  );
                a = a+1;
            end
            S_edu4 = S_edu4 - cost(w); % cost of going from college to highly educated
            S(w,m) = max(S_edu3,S_edu4); 
            if S_edu3 >= S_edu4
                highly_educated_decision(w,m) = 0;
            else
                highly_educated_decision(w,m) = 1;
            end
            S(w,m) = -S(w,m); % Hungarian algorithm computes minimum COST
        end
    end
   
    
    
%% SURPLUS MAXIMIZING MATCHING

    [X,TotalSurplus] = Hungarian1(S);
    [row,col] = find(X);


    
%% MEAN SPOUSAL INCOME BY TYPE OF WOMAN
    
    % save spousal income for each woman
    Y_M_match = zeros(N,4);
    
    % education group 
    Y_M_match(:,1) = W(:,1);

    % woman's income if college-educated
    Y_M_match(:,2) = W(:,3);    
    
    % woman's income if highly-educated
    Y_M_match(:,3) = W(:,5);     
    
    % spousal income + surplus + education decision
    for i=1:Nm
        Y_M_match(row(i),4) = M(i,2); % row(i) indicates col==i is matched with row == row(i)
        Y_M_match(row(i),5) = -S(row(i),i);
        Y_M_match(row(i),6) = highly_educated_decision(row(i),i);
    end
      
    output = Y_M_match;
end