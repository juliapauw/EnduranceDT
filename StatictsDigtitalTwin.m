clear all
close all
%% 1. loading data
% load current data
C_run = readtable('Digital_Twin_Final_swapped1.csv'); 
glucose_level = C_run.glucose_level;
pace = C_run.pace;
trend_glucose_level = C_run.trend_glucose_level;
glucose_needed=C_run.glucose_needed;
distance=C_run.distance;

% from seconds to minutes
time=C_run.time_str;
time_min=minutes(time);

% load past data
P_run = readtable('Digital_Twin_Final_random1.csv');
P_glucose_level = P_run.glucose_level;
P_pace=P_run.pace;

%% 2. select variables
N = length(glucose_level);       
future_pace = NaN(N, 1);
future_trend_glucose_level = NaN(N, 1);
future_glucose_needed = NaN(N, 1);
TOTAL_SESSION_TIME = time_min(end);

%% 3. statics loop
for k = 1:N
    % combine past data with post data
    if k <= length(P_pace) && ~isnan(P_pace(k))
        basis_pace = (pace(k) + P_pace(k)) / 2; % can add a factor here
    else
        basis_pace = pace(k);
    end
    
    % calculation of future
    future_pace(k) = basis_pace * 0.90; 
    
    if ~isnan(trend_glucose_level(k))
        intensiteit_ratio = pace(k) / future_pace(k); 
        future_trend_glucose_level(k) = trend_glucose_level(k) * intensiteit_ratio;
        
        % calculation of glucose needed in future
        if future_trend_glucose_level(k) < 0
            rest_time_value = (TOTAL_SESSION_TIME - time_min(k));
            rest_time = max(0, rest_time_value);
            
            future_glucose_needed(k) = abs(future_trend_glucose_level(k) * rest_time * 0.1) + (10 / future_pace(k));
        else
            future_glucose_needed(k) = 0;
        end
    else
        future_trend_glucose_level(k) = NaN;
        future_glucose_needed(k) = NaN;
    end
end

 %% 6. export file
final_table = table(time_min, distance, glucose_level, pace, trend_glucose_level, glucose_needed,P_glucose_level, P_pace, future_pace, future_trend_glucose_level, future_glucose_needed);
final_table2 = fillmissing(final_table, 'constant', 0, 'DataVariables', @isnumeric);

writetable(final_table2, 'Digital_Twin_Stats_Export4.csv');