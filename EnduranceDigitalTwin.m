close all
clear all
%% 1. configuration
WINDOW_PACE = 10;          % seconds voor moving average
WINDOW_GLUC = 30;          % seconds voor moving average

%% 2. reading data
filename = '.csv';
%filename= '.csv';
data = readtable(filename, 'PreserveVariableNames', true);
% select variables
time_str = data{:, 2}; 
distance = data{:, 3}; 
glucose_level = data{:, 5}; 
N = height(data);

% change time to minutes
time_min = minutes(time_str); 

%% 3. arrays pre-alloceren
pace = NaN(N, 1);
trend_glucose_level = NaN(N, 1);

%% 4. pre-processing loop
for i = 1:N
    % --- pace calculation
    if i > WINDOW_PACE
        delta_t_min = time_min(i) - time_min(i - WINDOW_PACE);
        delta_d_km = distance(i) - distance(i - WINDOW_PACE);
        
        if delta_d_km > 0.001
            pace(i) = delta_t_min / delta_d_km;
        else
            pace(i) = NaN; % break
        end
    end

    % --- glucose trend calculation
    if i > WINDOW_GLUC
        dt = time_min(i) - time_min(i - WINDOW_GLUC);
        dg = glucose_level(i) - glucose_level(i - WINDOW_GLUC);
        trend_glucose_level(i) = dg / dt;
    end
end

first_pace = pace(WINDOW_PACE + 1);
pace(1:WINDOW_PACE) = first_pace;

%% 5. DT coach & visionary
coach_state = zeros(N, 1);       
glucose_needed = NaN(N, 1);

% threshold settings
THRESHOLD = 100;                 % mg/dL
OUTLIER_LIMIT = -10;             % mg/dL/min
TOTAL_PLANNED_MIN = time_min(end); 

%% 5. DT logic   
cooldown_timer = 0;
COOLDOWN_PERIOD = 10;

for k = 1:N
    % counting down
    if cooldown_timer > 0
        cooldown_timer = cooldown_timer - 1;
        coach_state(k) = 0;
        
    % --- coach
    elseif k > 10
        recent_gluc = glucose_level(k-9:k);
        
        % check for 15 seconds under threshold for outlier 
        if all(recent_gluc < THRESHOLD) && trend_glucose_level(k) < 0 && trend_glucose_level(k) > OUTLIER_LIMIT
            
            coach_state(k) = 1;       % under threshold
            cooldown_timer = COOLDOWN_PERIOD; % 
            
        else
            coach_state(k) = 0;
        end
    end

    % --- visionary
    if ~isnan(trend_glucose_level(k)) && trend_glucose_level(k) < 0
        
        % amount of glucose needed for finish
        rest_tijd = max(0, TOTAL_PLANNED_MIN - time_min(k));
        
        % how much glucose is needed in grams
        glucose_needed(k) = abs(trend_glucose_level(k) * rest_tijd * 0.1) + (10 / pace(k));
    end
end

%% 6. export file
final_table = table(time_str, distance, glucose_level, pace, trend_glucose_level,coach_state, glucose_needed);
final_table2 = fillmissing(final_table, 'constant', 0, 'DataVariables', @isnumeric);
writetable(final_table2, '.csv');
