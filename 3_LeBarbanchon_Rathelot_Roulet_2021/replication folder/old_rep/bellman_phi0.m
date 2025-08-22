% % define function to solve for phi0
% function F = bellman_phi0(phi0, alpha, q, b, lambda, r, w_grid, h, tau)
% 
%     integrand = @(w) (w - alpha*tau - phi0) .* (w - alpha*tau > phi0);
% 
%     integral_val = trapz(w_grid, integrand(w_grid) .* h(w_grid));
% 
%     F = phi0 - (b/r + (lambda/(r+q)) * integral_val);
% 
% end

function [phi, reservation_wage, value_function] = bellman_model(phi0, alpha, q, b, lambda, r, w_grid, h, tau)
% BELLMAN_MODEL - Solves the Bellman equation for job search model
% Based on the Barbancdo, Rathelot & Roulet framework
%
% Inputs:
%   phi0   - Initial value function guess
%   alpha  - Discount parameter
%   q      - Job separation rate
%   b      - Unemployment benefit
%   lambda - Job arrival rate
%   r      - Interest rate
%   w_grid - Grid of wage values
%   h      - CDF/probability distribution over wages H(w,tau)
%   tau    - Time parameter
%
% Outputs:
%   phi           - Converged value function
%   reservation_wage - Reservation wage phi(tau)
%   value_function   - Final value function

    % Parameters for convergence
    max_iter = 1000;
    tol = 1e-6;
    
    % Initialize
    phi = phi0;
    phi_new = zeros(size(phi0));
    
    % Value function iteration
    for iter = 1:max_iter
        % Update value function using Bellman equation
        % rU = b + lambda * integral from reservation wage to infinity
        
        % Find reservation wage: rU = phi(tau) - alpha*tau
        % This gives us: rU = phi(0) - alpha*tau at tau=0, so rU = phi(0)
        rU = phi - alpha * tau;
        
        % Calculate the integral term
        % Integral of (w - alpha*tau - phi(0)) dH(w,tau) for w > reservation wage
        integral_term = 0;
        reservation_wage = phi - alpha * tau; % Current reservation wage
        
        for i = 1:length(w_grid)
            if w_grid(i) > reservation_wage
                % (w - alpha*tau - reservation_wage) * h(w,tau)
                integrand = (w_grid(i) - alpha*tau - reservation_wage) * h(i);
                integral_term = integral_term + integrand;
            end
        end
        
        % Bellman equation: rU = b + lambda * integral_term
        phi_new = b + (lambda/(r+q)) * integral_term + alpha * tau;
        
        % Check convergence
        if max(abs(phi_new - phi)) < tol
            fprintf('Converged after %d iterations\n', iter);
            break;
        end
        
        phi = phi_new;
    end
    
    if iter == max_iter
        warning('Maximum iterations reached without convergence');
    end
    
    % Calculate final reservation wage
    reservation_wage = phi - alpha * tau;
    
    % Calculate value function V(w,tau)
    value_function = zeros(size(w_grid));
    for i = 1:length(w_grid)
        if w_grid(i) >= reservation_wage
            % Accept job: V(w,tau) = (w - alpha*tau + q*U)/(r+q)
            value_function(i) = (w_grid(i) - alpha*tau + q*phi)/(r+q);
        else
            % Reject job: V(w,tau) = U (unemployment value)
            value_function(i) = phi;
        end
    end
    
    % Display results
    fprintf('Final reservation wage: %.4f\n', reservation_wage);
    fprintf('Unemployment value: %.4f\n', phi);
    
    % Plot results
    figure;
    subplot(2,1,1);
    plot(w_grid, value_function, 'b-', 'LineWidth', 2);
    hold on;
    plot([reservation_wage, reservation_wage], [min(value_function), max(value_function)], 'r--', 'LineWidth', 2);
    xlabel('Wage (w)');
    ylabel('Value Function V(w,\tau)');
    title('Value Function and Reservation Wage');
    legend('V(w,\tau)', 'Reservation Wage', 'Location', 'best');
    grid on;
    
    subplot(2,1,2);
    plot(w_grid, h, 'g-', 'LineWidth', 2);
    xlabel('Wage (w)');
    ylabel('Probability Density h(w)');
    title('Wage Distribution');
    grid on;
end

% Example usage and parameter setup
function example_usage()
    % Set parameters (example values)
    phi0 = 10;           % Initial guess for value function
    alpha = 0.05;        % Discount parameter
    q = 0.1;             % Job separation rate
    b = 5;               % Unemployment benefit
    lambda = 0.3;        % Job arrival rate
    r = 0.05;            % Interest rate
    tau = 0;             % Time parameter (set to 0 for steady state)
    
    % Create wage grid
    w_min = 0;
    w_max = 20;
    n_w = 100;
    w_grid = linspace(w_min, w_max, n_w);
    
    % Define wage distribution h(w,tau) - example: normal distribution
    mu_w = 8;            % Mean wage
    sigma_w = 2;         % Wage standard deviation
    h = normpdf(w_grid, mu_w, sigma_w);
    h = h / sum(h);      % Normalize to sum to 1 (discrete approximation)
    
    % Solve the model
    [phi, reservation_wage, value_function] = bellman_model(phi0, alpha, q, b, lambda, r, w_grid, h, tau);
    
    % Additional analysis
    fprintf('\nModel Parameters:\n');
    fprintf('Unemployment benefit (b): %.2f\n', b);
    fprintf('Job arrival rate (lambda): %.2f\n', lambda);
    fprintf('Job separation rate (q): %.2f\n', q);
    fprintf('Interest rate (r): %.2f\n', r);
    fprintf('Alpha parameter: %.2f\n', alpha);
    
    % Calculate acceptance probability
    accept_prob = sum(h(w_grid >= reservation_wage));
    fprintf('\nAcceptance probability: %.4f\n', accept_prob);
    fprintf('Expected wage conditional on acceptance: %.4f\n', ...
        sum(w_grid(w_grid >= reservation_wage) .* h(w_grid >= reservation_wage)) / accept_prob);
end

% Run example
example_usage();