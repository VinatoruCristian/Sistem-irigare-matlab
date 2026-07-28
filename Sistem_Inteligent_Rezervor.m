clear all; clc; close all;

%% 1. Configurare și Simulare
t_sim = 200; dt = 0.1; t = 0:dt:t_sim;
A1 = 5; A2 = 3; h_max = 5; Q_in_nom = 0.45;
h1 = zeros(size(t)); h2 = zeros(size(t));
stare_cod = zeros(size(t)); pomp_on_hist = zeros(size(t));
h1(1) = 2.8; h2(1) = 4.8;

for i = 1:length(t)
    % Senzori virtuali (Simulare mediu)
    temp = 25 + 15*sin(t(i)/50);
    consum = 0.2 + 0.12*sin(t(i)/20);
    scurgere = (t(i) > 80 && t(i) < 105) * 0.4;
    
    % Automat de stări (Logic discret - SDED)
    if scurgere > 0, stare = 3; % URGENTA
    elseif temp > 35, stare = 2; % ECONOMIC
    else, stare = 1; % NORMAL
    end
    
    % Control Pompă & Valve
    if stare == 3
        p_on = 0; r_act = 2; % Switch pe rezerva
    elseif stare == 2
        p_on = (h1(max(1,i-1)) < 1.5); r_act = 1; consum = consum * 0.6;
    else
        p_on = (h1(max(1,i-1)) < 3.0); r_act = 1;
    end
    
    % Integrare numerică (Model continuu)
    dh1 = (p_on*Q_in_nom - (r_act==1)*consum - scurgere - 0.002*temp)/A1;
    dh2 = (-(r_act==2)*consum)/A2;
    
    h1(i) = max(0, min(h_max, h1(max(1,i-1)) + dh1*dt));
    h2(i) = max(0, min(h_max, h2(max(1,i-1)) + dh2*dt));
    stare_cod(i) = stare; pomp_on_hist(i) = p_on;
end

%% 2. Vizualizare Avansată (Interfață Dashboard)
fig = figure('Color', [0.1 0.1 0.1], 'Position', [100 100 1100 800]); 

% Corecție: Folosim 'loose' în loc de 'relaxed'
tlo = tiledlayout(3,2, 'Padding', 'compact', 'TileSpacing', 'loose');

% --- GRAFIC PRINCIPAL: NIVEL REZERVOARE ---
nexttile([2 2]) 
hold on;

% Zone colorate pentru fundal (Limitele de siguranță)
fill([0 t_sim t_sim 0], [0 0 1 1], [1 0 0], 'EdgeColor', 'none', 'FaceAlpha', 0.1); % Zona de avarie (jos)
fill([0 t_sim t_sim 0], [4.5 4.5 5 5], [1 0 0], 'EdgeColor', 'none', 'FaceAlpha', 0.1); % Zona de overflow (sus)

% Plotare date
p1 = plot(t, h1, 'Color', [0 0.8 1], 'LineWidth', 3.5, 'DisplayName', 'Rezervor Principal');
p2 = plot(t, h2, 'Color', [1 0.6 0], 'LineWidth', 2, 'LineStyle', '--', 'DisplayName', 'Rezervor Rezervă');

% Linii de referință
yline(1, 'r--', 'Nivel Critic', 'LabelVerticalAlignment', 'bottom', 'Color', 'w');
yline(4.5, 'r--', 'Maxim', 'Color', 'w');

title('SISTEM INTELIGENT DE MONITORIZARE - REZERVOR INDUSTRIAL', 'Color', 'w', 'FontSize', 14);
ylabel('Nivel Apă (m)', 'Color', 'w'); grid on;
set(gca, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
legend('TextColor', 'w', 'Location', 'northeast');
ylim([0 h_max+0.2]);

% --- GRAFIC MODURI DE FUNCȚIONARE (STARE DISCRETĂ) ---
nexttile
area(t, stare_cod, 'FaceColor', [0.3 0.3 0.7], 'EdgeColor', 'c', 'FaceAlpha', 0.5);
yticks([1 2 3]); yticklabels({'NORMAL', 'ECO', 'AVARIE'});
title('STARE SISTEM (LOGICĂ DISCRETĂ)', 'Color', 'w');
set(gca, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
grid on;

% --- GRAFIC ACTIVITATE POMPĂ ---
nexttile
s = stairs(t, pomp_on_hist, 'LineWidth', 2, 'Color', [0.2 1 0.2]);
title('CONTROL POMPĂ (ACTIVITATE)', 'Color', 'w');
ylabel('OFF / ON', 'Color', 'w');
yticks([0 1]); yticklabels({'OPRIT', 'PORNIT'});
set(gca, 'Color', [0.15 0.15 0.15], 'XColor', 'w', 'YColor', 'w', 'GridColor', [0.3 0.3 0.3]);
ylim([-0.2 1.2]);
grid on;

% Adăugare Anotație de Alarmă dinamică
if any(scurgere > 0)
    annotation('textbox', [0.4 0.6 0.2 0.05], 'String', 'ALARMĂ: SCURGERE DETECTATĂ!', ...
        'Color', 'r', 'FontWeight', 'bold', 'HorizontalAlignment', 'center', 'BackgroundColor', 'w');
end