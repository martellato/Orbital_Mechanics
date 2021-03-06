function interplanetary_trajectory()
    %% Calculates the interplanetary COE, ejection angle, & hyperbolic excess velocities
    %
    % Jeremy Penn
    % 11 November 2017
    %
    % Revision  11/11/2017
    %           12/11/2017 - added calculation of dv and beta angles
    %           19/11/2017 - improved date functionality
    %
    % function interplanetary_trajectory()
    %
    % Purpose:  This function calculates the interplanety trajectory orbit
    %           as well as delta-v and ejection/capture angles.
    %
    % Required: planet_sv.m, lambert.m, coe_from_rv.m, planet_select.m,
    %            date_after_transfer.m
    %
    
    %% constants
    mu = 132.71e9;  % [km^3/s^2]
    
    %% inputs
    planet1 = input('Input the departing planet:\n','s');
    planet1 = lower(planet1);
    
    planet2 = input('Input the target planet:\n','s');
    planet2 = lower(planet2);
    
    date1 = input('Input the departure date (dd/mm/yyyy):\n','s');
    time1 = input('Input the departure time (HH:MM:SS):\n','s');
    days  = input('Input the length of the transfer orbit (days, use fractions if necessary):\n');
    split1 = strsplit(date1, '/');
    
    d1 = str2double(split1{1});
    m1 = str2double(split1{2});
    y1 = str2double(split1{3});
    
    split_t1 = strsplit(time1, ':');
    
    hr1 = str2double(split_t1{1});
    min1 = str2double(split_t1{2});
    sec1 = str2double(split_t1{3});
    
    UT1 = hr1 + min1/60 + sec1/3600;
    
    r_d = input('Input the perigee radius of the parking orbit (km):\n ');
    e_d = input('Input the eccentricity of the parking orbit:\n ');
    
    r_a = input('Input the perigee radius of the capture orbit (km):\n ');
    e_a = input('Input the eccentricity of the capture orbit:\n ');
    
    date_vec_i = date_after_transfer('no', d1, m1, y1, hr1, min1, sec1, days);
    UT2 = date_vec_i(4) + date_vec_i(5)/60 + date_vec_i(6)/3600;
    
    %% calculate the state vector of planet 1 at departure
    [R1, V1, jd1] = planet_sv(planet1, d1, m1, y1, UT1);
    
    %% calculate the state vector of planet 2 at arrival
    [R2, V2, jd2] = planet_sv(planet2, date_vec_i(3), date_vec_i(2), date_vec_i(1), UT2);
    
    %% calculate the flight time
    t12 = jd2 - jd1;
    t12 = t12 * 86400; %convert days to seconds
    
    %% solve lambert's problem for the velocities at departure & arrival
    [vd, va] = lambert(R1, R2, t12, 1e-8, mu);
    
    %% calculate the hyperbolic excess velocities at departure & arrival
    V_inf_D = vd - V1;
    V_inf_A = va - V2;
    
    speed_inf_D = norm(V_inf_D);
    speed_inf_A = norm(V_inf_A);
    
    %% calculate the coe of the transfer orbit
    [h, e, inc, W, w, theta] = coe_from_rv(R1, vd, mu);
    a = (h^2/mu)*(1/(1-e^2));
    
    inc = mod(inc, 360);
    W = mod(W, 360);
    w = mod(w, 360);
    theta = mod(theta, 360);
    
    %% calculate the ejection angle
    
    % gather the grav param and radius of the two bodies
    data_d = planet_select(planet1);
    data_a = planet_select(planet2);
    
    mu_d   = data_d(9);
    Rd     = data_d(1);
    
    mu_a   = data_a(9);
    Ra     = data_a(1);
    
    rd = Rd + r_d;
    e_h = 1 + rd*speed_inf_D^2 / mu_d; % ecc of hyperbolic ejection traj
    
    beta_d = acos(1/e_h)*180/pi;
    beta_d = mod(beta_d, 360);
    
    ra = Ra + r_a;
    e_h_a = 1 + ra*speed_inf_A^2 / mu_a; % ecc of hyperbolic capture traj
    
    beta_a = acos(1/e_h_a)*180/pi;
    beta_a = mod(beta_a, 360);
    
    %% calculate the delta-v of injection and capture
    v_d_p = sqrt( speed_inf_D^2 + 2*mu_d/rd );
    v_d_c = sqrt( (mu_d/rd) * (1 + e_d));
    
    delta_vd = v_d_p - v_d_c;
    
    v_a_p = sqrt( speed_inf_A^2 + 2*mu_a/ra );
    v_a_c = sqrt( (mu_a/ra) * (1 + e_a));
    
    delta_va = v_a_p - v_a_c;
    
    %% plot the transfer orbit
    [ha,ea,ia,Wa,wa,th_a] = coe_from_rv(R2, V2, mu);
    theta_plot = linspace(0,th_a*pi/180);
    r = h^2/mu .* (1 ./ (1 + e* cos(theta_plot)));
    
    polarplot(theta_plot,r);
    title('Interplanetary Orbital Trajectory')
    text(theta_plot(1), r(1), 'o departure','color','black','FontWeight','bold');
    text(theta_plot(end), r(end), 'o arrival','color','black','FontWeight','bold');
    
    %% print the results
    
    planet_d = replace(planet1,planet1(1),upper(planet1(1)));
    planet_a = replace(planet2,planet2(1),upper(planet2(1)));
    
    date_vec_d = [y1, m1, d1, hr1, min1, sec1];
    date_d_str = datestr(date_vec_d,'dd/mm/yyyy at HH:MM:SS UT');
    %date_vec   = [y2, m2, d2, hr2, min2, sec2];
    date_a_str = datestr(date_vec_i,'dd/mm/yyyy at HH:MM:SS UT');
    
    clc;
    
    fprintf('\n\n---------------------------------------------------------------\n')
    dda = sprintf('The state vector for %s on %s: \n',planet_d, date_d_str);
    fprintf(dda)
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t r_d = %.4e*i + %.4e*j + %.4e*k [km]\n',R1)
    fprintf('\t v_d = %.4f*i + %.4f*j + %.4f*k [km/s]\n',V1)
    
    fprintf('---------------------------------------------------------------\n')
    ada = sprintf('The state vector for %s on %s: \n', planet_a,date_a_str);
    fprintf(ada)
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t r_a = %.4e*i + %.4e*j + %.4e*k [km]\n',R2)
    fprintf('\t v_a = %.4f*i + %.4f*j + %.4f*k [km/s]\n',V2)
    
    fprintf('---------------------------------------------------------------\n')
    fprintf('The orbital elements of the transfer trajectory: \n')
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t h    = %.4e [km^2/s]\n',h)
    fprintf('\t e    = %.4f\n',e)
    fprintf('\t i    = %.4f [deg]\n',inc)
    fprintf('\t W    = %.4f [deg]\n',W)
    fprintf('\t w    = %.4f [deg]\n',w)
    fprintf('\t th_d = %.4f [deg]\n',theta)
    fprintf('\t a    = %.4e [km]\n',a)
    
    fprintf('---------------------------------------------------------------\n')
    fprintf('The transfer elements: \n')
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t t       = %.2f [days]\n',t12/86400);
    fprintf('\t V_inf_D = %.4f*i + %.4f*j + %.4f*k [km/s]\n',V_inf_D);
    fprintf('\t speed_d = %.4f [km/s]\n',speed_inf_D);
    fprintf('\t V_inf_A = %.4f*i + %.4f*j + %.4f*k [km/s]\n',V_inf_A);
    fprintf('\t speed_a = %.4f [km/s]\n',speed_inf_A);
    date_arrive = datestr(date_vec_i,'dd/mm/yyyy at HH:MM:SS UT');
    da = sprintf('\t The spacecraft will arrive at %s on %s\n', planet_a, date_arrive);
    fprintf(da)
    
    fprintf('---------------------------------------------------------------\n')
    fprintf('The injection elements: \n')
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t beta    = %.4f [deg]\n', beta_d);
    fprintf('\t delta-v = %.4f [km/s]\n', delta_vd)
    
    fprintf('---------------------------------------------------------------\n')
    fprintf('The capture elements: \n')
    fprintf('---------------------------------------------------------------\n')
    fprintf('\t beta    = %.4f [deg]\n', beta_a);
    fprintf('\t delta-v = %.4f [km/s]\n', delta_va)
end