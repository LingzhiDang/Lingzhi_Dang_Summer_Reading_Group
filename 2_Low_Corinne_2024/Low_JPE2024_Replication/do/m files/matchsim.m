% this function takes as input men and women with their incomes and
% computes the surplus matrix then runs the hungarian algorithm to get the
% stable match


function [output] = matchsim(WomenSample,MenSample,Prob)


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
    
    % fertility probabilities
    educ_cat = W(:,1);
    educ_cat = array2table(educ_cat,'VariableNames',{'educ_cat'});
    P = join(educ_cat,Prob);
    P =  P{:,:};
    
    % desired family size: everyone wants 4
    children = [1 2 3 4]';  
    D = randsample(children,N,true,[0 0 0 1]);    
    
    
    
%% SURPLUS MATRIX


    % define array
    S = zeros(N,Nm);
    
    for w=1:N   % loop through women
        for m=1:Nm % loop through men
            
            yz = W(w,2)+ M(m,1);
            S(w,m) = -yz; % single values
            a = 0;        % actual children start from 0
            d = D(w);     % desired family size of woman w
            while a ~= d+1
                S(w,m) = S(w,m) + P(w,a+4) * (  yz - (a/d)*(yz+1)/2  ) * (  (a/d) *  (yz-1)/2  );
                a = a+1;
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

    % woman's income
    Y_M_match(:,2) = W(:,3);    
    
    % spousal income + surplus
    for i=1:Nm
        Y_M_match(row(i),3) = M(i,2); % row(i) indicates col==i is matched with row == row(i)
        Y_M_match(row(i),4) = -S(row(i),i);
    end

    % spousal income
    output = Y_M_match;

end
