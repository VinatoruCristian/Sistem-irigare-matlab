clc; clear; close all;

%% 1. CONFIGURARE PARAMETRI (Sistem Dinamic)
pasi_timp = 250;           % Durata simulării
setpoint_umiditate = 55;   % Tinta (55%)
u = 40;                    % Umiditate inițială (%)
nivel_apa = 100;           % Rezervor inițial (%)
temp = 25;                 % Temperatura inițială (°C)

% Coeficienți PID (Acordați pentru stabilitate)
Kp = 1.6;  % Proporțional
Ki = 0.07; % Integral
Kd = 0.4;  % Derivativ

% Variabile interne controler
eroare_acumulata = 0;
ultima_eroare = 0;

% Vectori pentru analiză post-simulare
log_u = zeros(1, pasi_timp);
log_debit = zeros(1, pasi_timp);
log_apa = zeros(1, pasi_timp);

%% 2. SETUP INTERFAȚĂ GRAFICĂ (Live Dashboard)
fig = figure('Color', [0.1 0.1 0.1], 'Name', 'Smart Irrigation - Digital Twin', 'NumberTitle', 'off');
ax = axes('Color', [0 0 0], 'XColor', 'w', 'YColor', 'w', 'NextPlot', 'add');
grid on; set(ax, 'GridColor', [0.3 0.3 0.3]);
hold on;

% Obiecte grafice animate
h_umiditate = animatedline('Color', [0 1 1], 'LineWidth', 2, 'DisplayName', 'Umiditate Sol (%)');
h_sp = yline(setpoint_umiditate, '--r', 'SetPoint 55%', 'LineWidth', 1.5, 'LabelVerticalAlignment', 'bottom');
h_txt = text(10, 95, '', 'Color', 'w', 'FontSize', 11, 'FontWeight', 'bold', 'Interpreter', 'none');

title('Monitorizare Real-Time: Sistem Irigare Hibrid', 'Color', 'w', 'FontSize', 14);
ylabel('Procent (%)', 'Color', 'w');
xlabel('Timp (Secunde)', 'Color', 'w');
xlim([0 pasi_timp]); ylim([0 100]);
legend(h_umiditate, 'TextColor', 'w', 'Location', 'northeast');

fprintf('=== START SIMULARE SISTEM HIBRID ===\n');

%% 3. BUCLA DE CONTROL ȘI SIMULARE (Main Engine)
for t = 1:pasi_timp
    
    % --- EVENIMENT DISCRET: Caniculă (Perturbație externă) ---
    if t > 100 && t < 180
        temp = 38 + randn(); % Creștere temperatură
        rata_uscare = 1.2 + randn()*0.15; % Solul se usucă mult mai repede
    else
        temp = 25 + sin(t/10)*3; % Ciclu normal
        rata_uscare = 0.4 + randn()*0.05;
    end

    % --- CONTROLLER PID (Calcul Debit) ---
    eroare = setpoint_umiditate - u;
    eroare_acumulata = eroare_acumulata + eroare;
    derivata = eroare - ultima_eroare;
    
    debit = (Kp * eroare) + (Ki * eroare_acumulata) * 0.1 + (Kd * derivata);
    
    % --- EVENIMENT DISCRET: Siguranță (Hard Constraints) ---
    if nivel_apa < 10
        debit = 0; % Stop pompă (Protecție rezervor gol)
        status_msg = 'AVARIE: REZERVOR GOL!';
        color_msg = [1 0 0]; % Roșu
    elseif u < 30
        status_msg = 'STARE: IRIGARE CRITICĂ';
        color_msg = [1 0.5 0]; % Portocaliu
    elseif debit > 0.5
        status_msg = sprintf('STARE: IRIGARE ACTIVĂ (Debit: %.1f)', debit);
        color_msg = [0 1 0]; % Verde
    else
        status_msg = 'STARE: MONITORIZARE NOMINALĂ';
        color_msg = [0 0.8 1]; % Cyan
    end
    
    % Limitare fizică debit pompă (0 - 7 unități/sec)
    debit = max(0, min(7, debit));

    % --- DINAMICA SISTEMULUI (Fizica procesului) ---
    u = u + debit - rata_uscare;
    nivel_apa = nivel_apa - (debit * 0.25);
    
    % Constrângeri realiste (0-100%)
    u = max(0, min(100, u));
    nivel_apa = max(0, nivel_apa);
    
    % Salvare date pentru grafic final
    log_u(t) = u;
    log_debit(t) = debit;
    log_apa(t) = nivel_apa;
    ultima_eroare = eroare;

    % --- UPDATE INTERFAȚĂ (Live) ---
    addpoints(h_umiditate, t, u);
    set(h_txt, 'String', status_msg, 'Color', color_msg);
    
    % Forțează desenarea cadrului curent
    drawnow limitrate;
    pause(0.03); % Viteza de animație
end

%% 4. ANALIZA POST-SIMULARE (Element de nota 10)
mse_val = mean((log_u - setpoint_umiditate).^2);
fprintf('\n--- RAPORT PERFORMANȚĂ ---\n');
fprintf('Eroare Medie Pătratică (MSE): %.4f\n', mse_val);
fprintf('Consum Total Apă: %.1f unități\n', 100 - nivel_apa);

% Afișare fereastră secundară cu Analiza de Debit și Resurse
figure('Name', 'Analiza Resurse', 'Color', 'w');
subplot(2,1,1);
area(log_debit, 'FaceColor', [0.3 0.6 1], 'FaceAlpha', 0.5);
title('Efortul de Control (Debitul Pompei)'); ylabel('Debit'); grid on;

subplot(2,1,2);
plot(log_apa, 'k', 'LineWidth', 2);
title('Epuizarea Resursei de Apă'); ylabel('Nivel Rezervor (%)');
xlabel('Timp'); grid on;