%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Replication Files
% Author:   Corinne Low
% Paper:    The Human Capital - Reproductive Capital Tradeoff
%           in Marriage Market Matching (JPE 2023)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Required are the following data, functions and packages:
    
    % data files:
        % census_men.csv
        % census_women.csv
        % kids4categories.csv

    % functions:
        % Hungarian1.m
        % ecdfdraw.m
        % matchsim.m
        % matchsim_edu_endogenous.m

    % packages:
        % parsave (version 1.0.0.0 by J Weiss) (for parallelization)



%% Set Directory with data files and functions
%cd '/Users/adstr/Dropbox (Penn)/Reproductive capital/Streamlined/replication/do' 
cd 'C:\Users\dangl\Desktop\replication\Low, Corinne (2024)\Low_JPE2024_Replication\Low_JPE2024_Replication\do'
addpath './m files' % add path for functions

%% Fig 4
clear all;
close all;
clc;

%% Parameterization
gamma = 4;
phi = 2;
pi = 0.3;

%% delta surplus functions
delta_hm = @(y,lambda,rho) ...
                0.25 * pi * lambda * (2*y + 2*gamma - 2 + lambda) ...
                - 0.25 * rho * (y + gamma - 1)^2;
delta_hl = @(y,lambda,rho) ...
                0.25 * pi * (y + gamma + lambda - 1)^2 ...
                - 0.25 * (pi + rho) * (y + gamma - phi - 1)^2;
            
            
%% Measure of men
% low type:     measure 2.1
% medium type:  measure 2.1
% high type:    measure 1.8
% total measure:    6 


% cut off values for y_m
y0 = 0;
y1 = 1.8;
y2 = 2.1;
y3 = 3.9;
y4 = 4.2;
Y  = 6;


%% create matrices
nmax = 1000;
lambda_vec = linspace(1,3,nmax);
rho_vec = linspace(0,1-pi,nmax);
matchtype_mat = zeros(length(lambda_vec),length(rho_vec));


%% loop through values of lambda and rho
% check which conditions are met and
% fill matchtype_mat with corresponding code

% i is lambda, j is rho
for i=1:nmax
    for j=1:nmax
        %hm: change from M to H women.   hl: change from L to H women.

        %1 top: assortive matching richmen-Hwomen
        if      (delta_hm(Y,lambda_vec(1,i),rho_vec(1,j)) - delta_hm(y4,lambda_vec(1,i),rho_vec(1,j))) >= 0
            matchtype_mat(i,j) = 0;
        
        %2 
        %first line means case 1 fail. 
        %second line excludes the case where y2,y3 indifference to H women 
        elseif  (delta_hm(y4,lambda_vec(1,i),rho_vec(1,j)) - delta_hm(Y,lambda_vec(1,i),rho_vec(1,j)))  > 0 && ...
                (delta_hm(y3,lambda_vec(1,i),rho_vec(1,j)) - delta_hm(y2,lambda_vec(1,i),rho_vec(1,j))) > 0            
            matchtype_mat(i,j) = 1;
        
        %3 y3 want L and y2 want H women, so it is case 3
        elseif  (delta_hm(y2,lambda_vec(1,i),rho_vec(1,j)) - delta_hm(y3,lambda_vec(1,i),rho_vec(1,j))) >= 0 && ... 
                (delta_hl(y3,lambda_vec(1,i),rho_vec(1,j)) - delta_hl(y2,lambda_vec(1,i),rho_vec(1,j))) > 0 
            matchtype_mat(i,j) = 2;  
        %4    
        elseif  (delta_hl(y2,lambda_vec(1,i),rho_vec(1,j)) - delta_hl(y3,lambda_vec(1,i),rho_vec(1,j))) > 0 && ... 
                (delta_hl(y1,lambda_vec(1,i),rho_vec(1,j)) - delta_hl(0,lambda_vec(1,i),rho_vec(1,j))) > 0
            matchtype_mat(i,j) = 3;    
        %5 bottom    
        elseif  (delta_hl(y0,lambda_vec(1,i),rho_vec(1,j)) - delta_hl(y1,lambda_vec(1,i),rho_vec(1,j)))>= 0 
            matchtype_mat(i,j) = 4;    
            
        end
        
    end
   
end


%% graph
colormap(gray(5));

contourf(rho_vec,lambda_vec,matchtype_mat);
%title('Parameter Space and Matching Equilibrium')

str1 = {'Eqm 1:','match','with top','men'};
text(0.045,2.7,str1,'color','white','FontSize',16,'FontName','Times','HorizontalAlignment','center')

text(0.112,2.38,'---','Interpreter','latex','color','white','FontSize',16,'FontName','Times','HorizontalAlignment','left')

str2b = {'Eqm 2:','interior,','top'}
text(0.183,2.38,str2b,'color','white','FontSize',16,'FontName','Times','HorizontalAlignment','center')

str3 = {'Eqm 3:','middle'}
text(0.2,1.68,str3,'color','white','FontSize',16,'FontName','Times','HorizontalAlignment','center')

str4 = {'Eqm 4:','interior,','bottom'}
text(0.45,2.1,str4,'color','black','FontSize',16,'FontName','Times','HorizontalAlignment','center')

str5 = {'Eqm 5:','bottom'}
text(0.62,1.3,str5,'color','black','FontSize',16,'FontName','Times','HorizontalAlignment','center')

ax=gca;
ax.FontName = 'Times';
ax.FontSize = 16;

xlabel('\delta_\pi','FontSize',20,'FontName','Times');
ylabel('\delta_\gamma','FontSize',20,'FontName','Times');
set(get(gca,'ylabel'),'rotation',0)

yticks([1 1.2 1.4 1.6 1.8 2 2.2 2.4 2.6 2.8 3]);

print('../gph/lambdaandrho','-depsc2'); % editable eps file


%% FIGURE A4
clear all;
close all;
clc;


%% Setup

% Options

optsfsolve = optimoptions('fsolve','Tolx',1e-10, 'Display','iter');
optsfzero = optimset('Tolx',1e-10, 'Display','iter');


% Parameterization
%global gamma phi pi
gamma = 4;
phi = 2;
pi = 0.3;


% Measure of women
G_yL_initial = 2.1;
G_yM_initial = 3.9; 
Y  = 6;


% rho and lambda
n = 1000; 
rho_vec = linspace(0,0.7,n);
lambda_vec = linspace(1,3,n);

eq_mat = zeros(n,n);        % fill in 1 in the i,j-th cell if the rho-lambda config supports EQ3
cstar_mat = zeros(n,n);     % fill in c* in the i,j-th cell if the rho-lambda config supports EQ3


% Define functions that are the same across EQ

% symbolic expressions
syms ym y1 y2 y3 y4 ystar ydstar lambda rho k1 k2 k3

% surplus function
s = @(ym,yw,pw) 0.25*pw*(ym+yw-1)^2;

% Delta HM and HL
delta_hm = @(y,lambda,rho) 0.25*pi*lambda*(2*y+2*gamma-2+lambda) ...
                          -0.25*rho*(y+gamma-1)^2;
delta_hl = @(y,lambda,rho) 0.25*pi*(y+gamma+lambda-1)^2 ...
                          -0.25*(pi+rho)*(y+gamma-phi-1)^2;
                                        
% Men's utility            
uL = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma-phi   )-2)+k3;
uM = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma       )-2)+k2;
uH = @(ym) 0.25*(pi    )*ym*(ym+2*(gamma+lambda)-2)+k1;

            
% Cost Distribution
% assume uniform distribution [0 C] 
C = 2*Y;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EQ 1: high men
syms ym y1 y2 y3 y4 ystar ydstar cstar lambda rho k1 k2 k3

% solve for constants in men's utility
k2 = solve(uL(y2)==uM(y2),k2);  % indifference condition
k1 = solve(uM(Y-G_yM_initial*cstar/C)==uH(Y-G_yM_initial*cstar/C),k1);  % indifference condition
    % indifference condition for y4 = Y - G(M)*cstar/C (Y minus those who
    % invest
k3 = 0;
k1 = subs(k1);  % re-compute k1 but with k3 being 0 now
k2 = subs(k2);  % re-compute k1 but with k3 being 0 now

% % update men's utility
uL = subs(uL(ym));
uM = subs(uM(ym));
uH = subs(uH(ym));

%% Female surplus shares

% surplus shares (ym should cancel out)
vL = simplify(s(ym,gamma-phi   ,pi+rho) - uL);
vM = simplify(s(ym,gamma       ,pi+rho) - uM);
vH = simplify(s(ym,gamma+lambda,pi    ) - uH);

% Difference in utility between medium and high type woman
y2 = G_yL_initial;
vM = matlabFunction(subs(vM),'Vars',[lambda rho]);  % turn from symbolic to argument of function
vH = matlabFunction(subs(vH),'Vars',[cstar lambda rho]);  % turn from symbolic to argument of function
delta_u_HM = @(cstar,lambda,rho) vH(cstar,lambda,rho) - vM(lambda,rho) + lambda;


%% loop through lambda and rhos

for i=1:length(rho_vec)
    for j=1:length(lambda_vec)

        rho = rho_vec(1,i);
        lambda = lambda_vec(1,j);

% find y4 or fixed point using c = delta_u_HM
initial = 1;
cstar = fsolve(@(cstar) (delta_u_HM(cstar,lambda,rho) - cstar), initial, optsfsolve); 
        % need to translate y4 into measure on the cost line      
cstar = min(max(0,cstar),C);

G_yH = (cstar/C)*G_yM_initial;
G_yM = G_yM_initial - G_yH; % update measure of medium type women (those who decide not to invest)     
y4_new = G_yL_initial + G_yM;

% check whether EQ conditions still hold
z =  delta_hm(Y,lambda,rho) - delta_hm(y4_new,lambda,rho); % should be positive


if z >= 0 && G_yH > 0 % if conditions are met but also need G_yH 
                      % to be larger than 0
                      % otherwise there will be no high type
                      % women
    eq_mat(i,j) = 1;
    cstar_mat(i,j) = cstar;
else
    eq_mat(i,j) = 0;
    cstar_mat(i,j) = missing;    
end

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EQ 2: interior high-medium men
syms ym y1 y2 y3 y4 cstar ystar ydstar lambda rho k1 k2 k3
uL = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma-phi   )-2)+k3;
uM = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma       )-2)+k2;
uH = @(ym) 0.25*(pi    )*ym*(ym+2*(gamma+lambda)-2)+k1;


% solve for constants in men's utility
k2 = solve(uL(y2)==uM(y2),k2);  % indifference condition
k1 = solve(uM(ystar)==uH(ystar),k1);  % indifference condition
k3 = 0;
k1 = subs(k1);  % re-compute k1 but with k3 being 0 now
k2 = subs(k2);  % re-compute k1 but with k3 being 0 now

% update men's utility
uL = subs(uL(ym));
uM = subs(uM(ym));
uH = subs(uH(ym));

% Female surplus shares
% surplus shares (ym should cancel out)
vL = simplify(s(ym,gamma-phi   ,pi+rho) - uL);
vM = simplify(s(ym,gamma       ,pi+rho) - uM);
vH = simplify(s(ym,gamma+lambda,pi    ) - uH);

% Difference in utility between medium and high type woman
y2 = G_yL_initial;
    % express y* in terms of c* using EQ condition that delta HM is the same
eqns = [delta_hm(ystar,lambda,rho)==delta_hm(ystar+cstar/C*G_yM_initial,lambda,rho)]
ystar = solve(eqns,ystar);

vM = matlabFunction(subs(vM),'Vars',[lambda rho]);  % turn from symbolic to argument of function
vH = matlabFunction(subs(vH),'Vars',[cstar lambda rho]);  % turn from symbolic to argument of function
delta_u_HM = @(cstar,lambda,rho) vH(cstar,lambda,rho) - vM(lambda,rho) + lambda;


% find cstar for all rho-lambda
for i=2:length(rho_vec)
    for j=1:length(lambda_vec)

        rho = rho_vec(1,i);
        lambda = lambda_vec(1,j);

 
% find ystar or fixed point using c = delta_u_HM
initial = 1;
cstar = fsolve(@(cstar) (delta_u_HM(cstar,lambda,rho) - cstar), initial, optsfsolve);      
cstar = min(max(0,cstar),C);

G_yH = (cstar/C)*G_yM_initial;
G_yM = G_yM_initial - G_yH; % update measure of medium type women (those who decide not to invest)     
ystar_new = G_yL_initial + G_yM;
y3_new = y2 + G_yH;
y4_new = y2 + G_yM;

% check whether EQ conditions still hold
z1 = delta_hm(y4_new,lambda,rho) - delta_hm(Y,lambda,rho) % should be positive
z2 = delta_hm(y3_new,lambda,rho) - delta_hm(y2,lambda,rho) % should be positive


if z1 >= 0 && z2 >= 0 && G_yH > 0 % if conditions are met but also need G_yH 
                      % to be larger than 0
                      % otherwise there will be no high type
                      % women
    eq_mat(i,j) = 2;
    cstar_mat(i,j) = cstar;
   
end

    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EQ 3: medium men

syms ym y1 y2 y3 y4 ystar ydstar cstar lambda rho k1 k2 k3
uL = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma-phi   )-2)+k3;
uM = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma       )-2)+k2;
uH = @(ym) 0.25*(pi    )*ym*(ym+2*(gamma+lambda)-2)+k1;

% solve for constants in men's utility
k1 = solve(uL(y2)==uH(y2),k1);  % indifference condition
k2 = solve(uM(y2+cstar/C*G_yM_initial)==uH(y2+cstar/C*G_yM_initial),k2);  % indifference condition
k3 = 0;
k1 = subs(k1);  % re-compute k1 but with k3 being 0 now
k2 = subs(k2);  % re-compute k1 but with k3 being 0 now

% update men's utility
uL = subs(uL(ym));
uM = subs(uM(ym));
uH = subs(uH(ym));


% Female surplus shares
% surplus shares (ym should cancel out)
vL = simplify(s(ym,gamma-phi   ,pi+rho) - uL);
vM = simplify(s(ym,gamma       ,pi+rho) - uM);
vH = simplify(s(ym,gamma+lambda,pi    ) - uH);


% Difference in utility between medium and high type woman
y2 = G_yL_initial;
vM = matlabFunction(subs(vM),'Vars',[cstar lambda rho]);  % turn from symbolic to argument of function
vH = matlabFunction(subs(vH),'Vars',[lambda rho]);  % turn from symbolic to argument of function
delta_u_HM = @(cstar,lambda,rho) vH(lambda,rho) - vM(cstar,lambda,rho) + lambda;


%% find cstar

for i=1:length(rho_vec)
    for j=1:length(lambda_vec)

        rho = rho_vec(1,i);
        lambda = lambda_vec(1,j);

 
% find y3 or fixed point using c = delta_u_HM
initial = 1;
cstar = fsolve(@(cstar) (delta_u_HM(cstar,lambda,rho) - cstar), initial, optsfsolve); 
    % solve for c* s.t. c* = vH - vM + lambda     
cstar = min(max(0,cstar),C);


G_yH = (cstar/C)*G_yM_initial;
G_yM = G_yM_initial - G_yH; % update measure of medium type women (those who decide not to invest)     
y3_new = y2 + G_yH;


% check whether EQ conditions still hold
z1 =  delta_hm(y2,lambda,rho) - delta_hm(y3_new,lambda,rho); % should be positive
z2 =  delta_hl(y3_new,lambda,rho) - delta_hl(y2,lambda,rho); % should be positive


if z1 >= 0 && z2 >= 0 && cstar > 0 % if conditions are met but also need G_yH 
                                  % to be larger than 0
                                  % otherwise there will be no high type
                                  % women
    eq_mat(i,j) = 3;
    cstar_mat(i,j) = cstar;
  
end

    end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EQ 4: interior low-medium men

syms ym y1 y2 y3 y4 ystar ydstar cstar lambda rho k1 k2 k3
uL = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma-phi   )-2)+k3;
uM = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma       )-2)+k2;
uH = @(ym) 0.25*(pi    )*ym*(ym+2*(gamma+lambda)-2)+k1;

% solve for constants in men's utility
k1 = solve(uL(ystar)==uH(ystar),k1);  % indifference condition
k2 = solve(uL(Y-(C-cstar)/C*G_yM_initial)==uM(Y-(C-cstar)/C*G_yM_initial),k2);  % indifference condition
k3 = 0;
k2 = subs(k2);  % re-compute k2 but with k3 being 0 now
k1 = subs(k1);  % re-compute k1 but with k3 being 0 now

% update men's utility
uL = subs(uL(ym));
uM = subs(uM(ym));
uH = subs(uH(ym));


% Female surplus shares
% surplus shares (ym should cancel out)
vL = simplify(s(ym,gamma-phi   ,pi+rho) - uL);
vM = simplify(s(ym,gamma       ,pi+rho) - uM);
vH = simplify(s(ym,gamma+lambda,pi    ) - uH);


% Difference in utility between medium and high type woman
eqns = [delta_hl(ystar,lambda,rho)==delta_hl(ystar+cstar/C*G_yM_initial,lambda,rho)]
ystar = solve(eqns,ystar);

vM = matlabFunction(subs(vM),'Vars',[cstar rho]);  % turn from symbolic to argument of function
vH = matlabFunction(subs(vH),'Vars',[cstar lambda rho]);  % turn from symbolic to argument of function
delta_u_HM = @(cstar,lambda,rho) vH(cstar,lambda,rho) - vM(cstar,rho) + lambda;


%% find cstar for all rho-lambda
for i=2:length(rho_vec) 
    for j=1:length(lambda_vec)
                 
        rho = rho_vec(1,i);
        lambda = lambda_vec(1,j);

        
% find cstar or fixed point using c = delta_u_HM
initial = 1;              
cstar = fsolve(@(cstar) (delta_u_HM(cstar,lambda,rho) - cstar), initial, optsfsolve); 
cstar = min(max(0,cstar),C);

G_yH = (cstar/C)*G_yM_initial;
G_yM = G_yM_initial - G_yH; % update measure of medium type women (those who decide not to invest) 
y1_new = G_yH;
y2_new = G_yL_initial;
y3_new = y2_new + G_yH;


% check whether EQ conditions still hold
z1 = delta_hl(y2_new,lambda,rho) - delta_hl(y3_new,lambda,rho) % should be positive
z2 = delta_hl(y1_new,lambda,rho) - delta_hl(0,lambda,rho) % should be positive


if z1 >= 0 && z2 >= 0 && G_yH > 0 % if conditions are met but also need G_yH 
                      % to be larger than 0
                      % otherwise there will be no high type
                      % women
    eq_mat(i,j) = 4;
    cstar_mat(i,j) = cstar;
end

    end
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EQ 5: low men

syms ym y1 y2 y3 y4 cstar ystar ydstar lambda rho k1 k2 k3
uL = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma-phi   )-2)+k3;
uM = @(ym) 0.25*(pi+rho)*ym*(ym+2*(gamma       )-2)+k2;
uH = @(ym) 0.25*(pi    )*ym*(ym+2*(gamma+lambda)-2)+k1;

% solve for constants in men's utility
k3 = solve(uL(cstar/C*G_yM_initial)==uH(cstar/C*G_yM_initial),k3);  % indifference condition
    % corresponds to y1
k2 = solve(uL(cstar/C*G_yM_initial + G_yL_initial)==uM(cstar/C*G_yM_initial + G_yL_initial),k2);  % indifference condition
    % corresponds to y3
k1 = 0;
k2 = subs(k2);  % re-compute k1 but with k3 being 0 now
k3 = subs(k3);  % re-compute k1 but with k3 being 0 now

% update men's utility
uL = subs(uL(ym));
uM = subs(uM(ym));
uH = subs(uH(ym));

%% Female surplus shares

% surplus shares (ym should cancel out)
vL = simplify(s(ym,gamma-phi   ,pi+rho) - uL);
vM = simplify(s(ym,gamma       ,pi+rho) - uM);
vH = simplify(s(ym,gamma+lambda,pi    ) - uH);

% Difference in utility between medium and high type woman
vM = matlabFunction(subs(vM),'Vars',[cstar lambda rho]);  % turn from symbolic to argument of function
vH = matlabFunction(subs(vH),'Vars',[lambda rho]);  % turn from symbolic to argument of function
delta_u_HM = @(cstar,lambda,rho) vH(lambda,rho) - vM(cstar,lambda,rho) + lambda;



%% find cstar for all rho-lambda
for i=1:length(rho_vec)
    for j=1:length(lambda_vec)

        rho = rho_vec(1,i);
        lambda = lambda_vec(1,j);

 
% find y1 or fixed point using c = delta_u_HM
initial = 1;
cstar = fsolve(@(cstar) (delta_u_HM(cstar,lambda,rho) - cstar), initial, optsfsolve);     
cstar = min(max(0,cstar),C);

G_yH = (cstar/C)*G_yM_initial;
G_yM = G_yM_initial - G_yH; % update measure of medium type women (those who decide not to invest)     
y1_new = G_yH;


% check whether EQ conditions still hold
z =  delta_hl(0,lambda,rho) - delta_hl(y1_new,lambda,rho); % should be positive


if z >= 0 && y1_new > 0 % if conditions are met but also need G_yH 
                      % to be larger than 0
                      % otherwise there will be no high type
                      % women
    eq_mat(i,j) = 5;
    cstar_mat(i,j) = cstar;
end

    end
end





%% create figures

lambda_mat = repmat(lambda_vec,n,1);
rho_mat = repmat(transpose(rho_vec),1,n);

cstar_max = nanmax(cstar_mat,[],'all'); % get maxmimum cstar
cstar_max_share = round(cstar_max*100/C,0);
cstar_min = nanmin(cstar_mat,[],'all'); % get minimum cstar
cstar_min_share = round(cstar_min*100/C,0);

%%
colormap(flipud(gray))

contourf(rho_mat,lambda_mat,cstar_mat,500,'LineStyle','none')
hold on
contour(rho_mat,lambda_mat,eq_mat,10,'black')
hold off

str1 = {'Eqm 1:','match','with top','men'};
text(0.045,2.7,str1,'color','white','FontSize',14,'FontName','Times','HorizontalAlignment','center')

text(0.124,2.556,'---','Interpreter','latex','color','white','FontSize',14,'FontName','Times','HorizontalAlignment','left')

str2b = {'Eqm 2:','interior,','top'}
text(0.19,2.557,str2b,'color','white','FontSize',14,'FontName','Times','HorizontalAlignment','center')

str3 = {'Eqm 3:','middle'}
text(0.224,1.88,str3,'color','black','FontSize',14,'FontName','Times','HorizontalAlignment','center')

str4 = {'Eqm 4:','interior,','bottom'}
text(0.537,2.47,str4,'color','black','FontSize',14,'FontName','Times','HorizontalAlignment','center')

str5 = {'No investment:','assortative','matching','between low and','medium types'}
text(0.59,1.4,str5,'color','black','FontSize',14,'FontName','Times','HorizontalAlignment','center')

ax = gca;
ax.FontName = 'Times';
ax.FontSize = 14;

xlabel('\delta_\pi','FontSize',20,'FontName','Times');
ylabel('\delta_\gamma','FontSize',20,'FontName','Times');
set(get(gca,'ylabel'),'rotation',0);

yticks([1 1.2 1.4 1.6 1.8 2 2.2 2.4 2.6 2.8 3]);


cb = colorbar('Ticks',2.3,...
        'TickLabels',{'Legend: percent of medium-type women who invest'},...
        'FontSize',14,...
        'TickLength',0,...
        'Location','northoutside');   
title(cb,num2str(cstar_min_share,'%g%%'), ...
    'FontSize',14,['' ...
    'FontName'],'Times', ...
    'Position',[5 -0.01], ...
    'HorizontalAlignment','left')
set(cb.XLabel,{'String','Rotation','Position','HorizontalAlignment','Color','FontSize'}, ...
    {num2str(cstar_max_share,'%g%%'),0,[6.24 -0.01],'left','White',14})

print('../gph/schoolinvestment_matching','-depsc2'); % editable eps file




%% SPOUSAL INCOME
clear;
close all;
clc;

%% IMPORT DATA
data = readtable('../dta/census_graph3.csv');
dataplot = data{:,:}; 

%% PLOT
figure
plot(dataplot(dataplot(:,2)==4,1),dataplot(dataplot(:,2)==4,3),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12)
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Spousal Income, 1999 USDs','FontSize',12)
yticks([30000 45000 60000 75000 90000]) 
ytick = get(gca, 'ytick');
yticklabel =strread(sprintf('%.0f;', ytick), '%s', 'delimiter', ';')
set(gca,'yticklabel', ytick,'fontname','Serif','FontSize',12)
axis([1960 2010 20000 100000])
title('')

hold on 
plot(dataplot(dataplot(:,2)==3,1),dataplot(dataplot(:,2)==3,3),'--','LineWidth',1,'color',[0 0 0]);
hold off

hold on 
plot(dataplot(dataplot(:,2)==2,1),dataplot(dataplot(:,2)==2,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

hold on 
plot(dataplot(dataplot(:,2)==1,1),dataplot(dataplot(:,2)==1,3),'-.','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

legend('Highly educated','College educated','Some college','HS grad or less',...
    'Location','southoutside','Orientation','horizontal','NumColumns',2,'FontSize',12)

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/census-spousalincome3.png')
print('../gph/census-spousalincome3','-depsc2'); % editable eps file

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% EXOGENOUS EDUCATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
close all;
clc;


%% IMPORT DATA
    
% import data
data_men = readtable('../dta/census_men.csv');
data_women = readtable('../dta/census_women.csv');
childdist = readtable('../dta/kids4categories.csv');


    
%% PARAMETERS AND ARRAYS

% number of draws
N = 800; 
% number of simulations per year
a = 5; 
% discount factor
beta = 0.08;
% number of education categories
eduN = 4;

% empty array for simulation results
SimResults = zeros(N*a*6,4);
MatchOutput = zeros(6,eduN+1); % 6 rows for each year


%% SIMULATION

tic
for i = 1:6 % loop over years

    year = i*10 + 1950;
    
    MatchOutput(i,1) = year;
    
    % filter data for that year
        WomenToSampleFrom = data_women(data_women.year == year,:);
        MenToSampleFrom = data_men(data_men.year == year,:);
        WomenWeights = WomenToSampleFrom.perwt;
        MenWeights = MenToSampleFrom.perwt;
        Prob = childdist(childdist.year == year,:);
    
    % simulate matches    
    
    for sim = 1:a        
        
        % seed 
        seed = sim*100+i;
        s = RandStream('mlfg6331_64','Seed',seed);     
        
        % sample with ECDF
        MenSample = ecdfdraw(MenToSampleFrom.inctot_adj,N,'linear',seed);
        WomenSample = zeros(N,2); 
        
           % relative size - match empirical distribution
           g = zeros(eduN,1);
           for m=1:1:eduN
                g(m) = round(sum(WomenToSampleFrom.educ_cat==m)/numel(WomenToSampleFrom.educ_cat)* N,0);
           end
           % make sure we have size N
           diff = sum(g) - N;
           if diff > 0 
               g(1) = g(1) - diff; 
           elseif diff < 0
               g(1) = g(1) - diff;
           end
           % type: 1st column of W (1,2,3 or 4)
            WomenSample(1:g(1),1)        = 1;
            for n = 2:1:eduN
                WomenSample(sum(g(1:n-1))+1:sum(g(1:n)),1)  = n;
            end
            % income: 2nd column of W - match empirical distribution
            for k = 1:1:eduN       
                if k == 1
                    WomenSample(1:g(1),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 1),g(1),'linear',seed);
                else 
                    WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2)  = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == k),g(k),'linear',seed);
                end
            end    
            % from array to table
            WomenSample = array2table(WomenSample,'VariableNames',{'educ_cat','inctot_adj'});
            MenSample = array2table(MenSample,'VariableNames',{'inctot_adj'});
            
        % call surplus-maximizing matching algorithm
        fprintf('Running year %d\n and simulation iteration %d\n',year,sim)
        tmp = matchsim(WomenSample,MenSample,Prob);
        
        % stack all matching results
        row = (i-1)*a*N + (sim-1)*N + 1;
        fprintf('Filling in results starting from row %d\n',row)
        SimResults(row:row+N-1,1) = year;  
        SimResults(row:row+N-1,2) = sim;  
        SimResults(row:row+N-1,3:2+size(tmp,2)) = tmp;  
    end
    
    
end
toc

%% label results
SimResults_table = array2table(SimResults,'VariableNames',{'year','sim','educ_cat','inctot_adj','inctot_adj_sp','surplus'});


%% Means
Surplus = zeros(6,eduN+1);
Surplus(:,1) = [1960;1970;1980;1990;2000;2010];
MatchOutput = zeros(6,eduN+1);
MatchOutput(:,1) = [1960;1970;1980;1990;2000;2010];


i=1;
for y=1960:10:2010
    for e=1:eduN       
        MatchOutput(i,e+1) = mean(SimResults_table.inctot_adj_sp(SimResults_table.year == y & SimResults_table.educ_cat == e));
        Surplus(i,e+1) = mean(SimResults_table.surplus(SimResults_table.year == y & SimResults_table.educ_cat == e));
    end
 i=i+1;   
end


%% Graph Spousal Income


figure
plot(MatchOutput(:,1),MatchOutput(:,5),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12)
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Spousal Income, 1999 USDs','FontSize',12)
yticks([30000 45000 60000 75000 90000 105000]) 
ytick = get(gca, 'ytick');
yticklabel = strread(sprintf('%,.0f;', ytick), '%s', 'delimiter', ';')
axis([1960 2010 20000 120000])
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

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/sim-weighted-edu-exo-inctot-INCOME.png'); % png file
print('../gph/sim-weighted-edu-exo-inctot-INCOME','-depsc2'); % editable eps file



%% Graph Surplus

figure
plot(Surplus(:,1),Surplus(:,5),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12)
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Mean Surplus','FontSize',12)
set(gca,'fontname','Serif','FontSize',12)
title('')

hold on 
plot(Surplus(:,1),Surplus(:,4),'--','LineWidth',1,'color',[0 0 0]);
hold off

hold on 
plot(Surplus(:,1),Surplus(:,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

hold on 
plot(Surplus(:,1),Surplus(:,2),'-.','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

legend('Highly educated','College educated','Some college','HS grad or less',...
        'Location','southoutside','Orientation','horizontal','NumColumns',2,'FontSize',12)

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/sim-weighted-edu-exo-surplus.png'); % png file
print('../gph/sim-weighted-edu-exo-surplus','-depsc2'); % editable eps file



%% Marriage Rates with Shocks

% Parameterization
N = 800;    % # individuals
sim = 5;    % # simulations
eduN = 4;   % # education levels

% draw shocks  
mu = 30*(10^10);
sigma = 15^10; 
rng(1);
e = evrnd(mu,sigma,[N,1]);  % Type-1 extreme value
histogram(e,'FaceColor',[0.5 0.5 0.5])
set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/histogram-shock.png')
print('../gph/histogram-shock','-depsc2'); % editable eps file

% array
M = SimResults_table{:,:};
M = [M  zeros(size(M,1),2)];

% loop over years and simulations
i = 1;
for y = 1960:10:2010
    
    for s = 1:sim 
        
        % seed
        seed = i*10+s;
        
        % row index
        idx = (i-1)*sim*N + (s-1)*N + 1;
        fprintf('Filling in results starting from row %d\n',idx)
        
        % draw shocks
        rng(seed);
        e = evrnd(mu,sigma,[N,1]);
        
        % new surplus
        M(idx:idx+N-1,7) = M(idx:idx+N-1,6) + e;
        
        
    end
    
    i = i+1;

end

% marriage decision
M(M(:,7)>0,8) = 1;
M(M(:,7)<0,8) = 0;


%% Get means of marriage decisions

MarriageDecisions = zeros(6,eduN+1);
MarriageDecisions(:,1) = [1960;1970;1980;1990;2000;2010];

i=1;
for y=1960:10:2010
    for e=1:eduN       
        MarriageDecisions(i,e+1) = mean(M(M(:,1)==y & M(:,3)==e,8));
    end
 i=i+1;   
end




%% Graph Marriage Rates

figure
plot(MarriageDecisions(:,1),MarriageDecisions(:,5),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12,'fontname','Serif')
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Fraction Married','FontSize',12,'fontname','Serif')
%yticks([0 0.2 0.4 0.6 0.8 1]) 
%ytick = get(gca, 'ytick');
%yticklabel = strread(sprintf('%,.0f;', ytick), '%s', 'delimiter', ';')
set(gca,'fontname','Serif','FontSize',12)
title('')

hold on 
plot(MarriageDecisions(:,1),MarriageDecisions(:,4),'--','LineWidth',1,'color',[0 0 0]);
hold off

hold on 
plot(MarriageDecisions(:,1),MarriageDecisions(:,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

hold on 
plot(MarriageDecisions(:,1),MarriageDecisions(:,2),'-.','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off

legend('Highly educated','College educated','Some college','HS grad or less',...
    'Location','southoutside','Orientation','horizontal','NumColumns',2,'FontSize',12,'fontname','Serif')

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/sim-edu-exo-shock-married.png'); % png file
print('../gph/sim-edu-exo-shock-married','-depsc2'); % editable eps file



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% ENDOGENOUS EDUCATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clear;
close all;
clc;

%% IMPORT DATA
    
% import data
data_men = readtable('../dta/census_men.csv');
data_women = readtable('../dta/census_women.csv');
childdist = readtable('../dta/kids4categories.csv');

    
%% PARAMETERS AND ARRAYS

% number of draws
N = 800;
% number of simulations per year
a = 5; 
% discount factor
beta = 0.08;
% number of education categories
eduN = 4;

% empty array for simulation results
SimResults = zeros(N,8,6,a);


%% SIMULATION WITH PARALLELIZATION
%Takes a century to run
for  i = 1:6

    year = i*10 + 1950;
    
    % filter data for that year
        WomenToSampleFrom = data_women(data_women.year == year,:);
        MenToSampleFrom = data_men(data_men.year == year,:);
        WomenWeights = WomenToSampleFrom.perwt;
        MenWeights = MenToSampleFrom.perwt;
        Prob = childdist(childdist.year == year,:);

    % cost of investment
        cmin = -10;
        cmax = 20;
        
    % simulate matches    
    parfor sim = 1:a        
        
        % seed 
        seed = sim*100+i;
        s = RandStream('mlfg6331_64','Seed',seed);     
        
        % sample with ECDF
        MenSample = ecdfdraw(MenToSampleFrom.inctot_adj,N,'linear',seed);
        WomenSample = zeros(N,2); 
        
           % relative size - match empirical distribution
           g = zeros(eduN,1);
           for m=1:1:eduN
                g(m) = round(sum(WomenToSampleFrom.educ_cat==m)/numel(WomenToSampleFrom.educ_cat)* N,0);
           end
           % make sure we have size N
           diff = sum(g) - N;
           if diff > 0 
               g(1) = g(1) - diff; 
           elseif diff < 0
               g(1) = g(1) - diff;
           end
           % type: 1st column of W (1,2,3) - no highly educated
            WomenSample(1:g(1),1)        = 1;
            for n = 2:1:eduN
                WomenSample(sum(g(1:n-1))+1:sum(g(1:n)),1)  = n;
            end
            WomenSample(WomenSample(:,1)==4,1) = 3;
            % income: 2nd column of W - match empirical distribution
            for k = 1:1:eduN     
                if k == 1
                    WomenSample(1:g(1),2) = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 1),g(1),'linear',seed);
                elseif k == 4 % draw from college-educated for those who are actually highly educated
                    WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2)  = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == 3),g(k),'linear',seed);
                else 
                    WomenSample(sum(g(1:k-1))+1:sum(g(1:k)),2)  = ecdfdraw(WomenToSampleFrom.inctot_adj(WomenToSampleFrom.educ_cat == k),g(k),'linear',seed);
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
        fprintf('Running year %d\n and simulation iteration %d\n',year,sim)
        tmp = matchsim_edu_endogenous(WomenSample,MenSample,pct,Prob,cmin,cmax);

        
        % stack all matching results
        row = (i-1)*a*N + (sim-1)*N + 1;
        fprintf('Filling in results starting from row %d\n',row) 
        output = [repmat(year,N,1) repmat(sim,N,1) tmp];
        SimResults(:,:,i,sim) = output;
        parsave(sprintf('m files/temp/output-%d-%d.mat',i,sim),output);
    end


end      

%% compile output files

clear A

for i=1:6
    for j=1:5
        fprintf('m files/temp/output-%d-%d.mat',i,j)
        
        if i==1 & j==1 
                A = importdata(sprintf('m files/temp/output-%d-%d.mat',i,j));
        else
                B = importdata(sprintf('m files/temp/output-%d-%d.mat',i,j));
                A = cat(1,A,B);
        end

    end
end

%% format results
R = array2table(A,'VariableNames',{'year','sim','educ_cat','inctot_adj_edu3','inctot_adj_edu4',...
    'inctot_adj_sp','surplus','highly_edu_decision'});


%% Means
MatchOutput = zeros(6,eduN+1);
MatchOutput(:,1) = [1960;1970;1980;1990;2000;2010];
Surplus = zeros(6,eduN+1);
Surplus(:,1) = [1960;1970;1980;1990;2000;2010];
Output_edu = zeros(6,3);
Output_edu(:,1) = [1960;1970;1980;1990;2000;2010];


i=1;
for y=1960:10:2010
    
    for e=1:eduN       
        if e==eduN 
            MatchOutput(i,e+1) = mean(R.inctot_adj_sp(R.year == y & R.highly_edu_decision == 1 ));
        else
            MatchOutput(i,e+1) = mean(R.inctot_adj_sp(R.year == y & R.educ_cat == e));
        end

        Surplus(i,e+1) = mean(R.surplus(R.year == y & R.educ_cat == e));        
    end
    
    % fraction highly edu
    Output_edu(i,2) = mean(R.highly_edu_decision(R.year == y));
    % actual percentage
    data_edu = data_women.educ_cat(data_women.year == y); 
    Output_edu(i,3) = sum(data_edu == 4)/size(data_edu,1);
    
 i=i+1;   
end




%% Graph Spousal Income 

figure
plot(MatchOutput(:,1),MatchOutput(:,5),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12)
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Spousal Income, 1999 USDs','FontSize',12)
yticks([30000 45000 60000 75000 90000 105000 120000 135000]) 
ytick = get(gca, 'ytick');
yticklabel = strread(sprintf('%,.0f;', ytick), '%s', 'delimiter', ';')
axis([1960 2010 20000 140000])
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

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/sim-weighted-edu-endo-inctot-INCOME.png'); % png file
print('../gph/sim-weighted-edu-endo-inctot-INCOME','-depsc2'); % editable eps file


%% Graph Investment in Education

figure
plot(Output_edu(:,1),Output_edu(:,2),'-','LineWidth',1,'color',[0 0 0]);

xlabel('Census Year','FontSize',12,'fontname','Serif')
xticks([1960 1970 1980 1990 2000 2010]) 
ylabel('Fraction Highly Educated','FontSize',12,'fontname','Serif')
yticks([0  0.1  0.2]) 
ytick = get(gca, 'ytick');
yticklabel = strread(sprintf('%,.0f;', ytick), '%s', 'delimiter', ';')
set(gca,'yticklabel', ytick,'fontname','Serif','FontSize',12)
title('')

hold on 
plot(Output_edu(:,1),Output_edu(:,3),':','LineWidth',1,'color',[0.5 0.5 0.5]);
hold off


legend('Simulation','Data','FontSize',12,'Location','southoutside','NumColumns',2,'FontSize',12,'fontname','Serif')

set(gca,'fontname','times')  % Set font to times
saveas(gcf,'../gph/sim-weighted-edu-endo-inctot-EDUCATION.png'); % png file
print('../gph/sim-weighted-edu-endo-inctot-EDUCATION','-depsc2'); % editable eps file
