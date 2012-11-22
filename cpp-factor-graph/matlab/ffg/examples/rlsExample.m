function rlsExample()
%AREXAMPLE example of autoregressive parameter estimation

    % loading stuff
    load('test_ar.mat');
    
    NOISE_U = INPUT_AR.noiseU;

    % basic kalman-filter nodes
    x_prev = EvidenceNode;          
    x_next = EvidenceNode; 
    y = EvidenceNode;      
    noise_U = EvidenceNode;
    noise_W = EvidenceNode;
    b = MultiplicationNode;
    A = EstimateMultiplicationNode;
    add_A_b = AddNode;   
    add_W_c = AddNode;
    
    equMult = EquMultNode;
    
    a_equ = EqualityNode;
    %% TODO: use strings/enums instead of plain integers
    a_equ.setType(2);
    a_prev = EvidenceNode;
    a_next = EvidenceNode;
    
    
    nwk = Network;
    nwk.addEdge(x_prev, A);
    nwk.addEdge(A, add_A_b);
    nwk.addEdge(noise_U, b);
    nwk.addEdge(b, add_A_b);
    nwk.addEdge(add_A_b, equMult);
    nwk.addEdge(x_next, equMult);
    
    nwk.addEdge(equMult, add_W_c);
    nwk.addEdge(noise_W, add_W_c);
    nwk.addEdge(add_W_c, y);
    
   
    nwk.addEdgeTagged(A, a_equ, 'estimated', '');
    nwk.addEdge(a_prev, a_equ);
    nwk.addEdge(a_equ, a_next);
           
    % RLS schedule
    schedule = {};
    
    schedule = [schedule, {x_prev, A}, {A, add_A_b}, {noise_U, b}, {b, add_A_b}, {add_A_b, equMult}];
    schedule = [schedule, {y, add_W_c}, {noise_W, add_W_c}, {add_W_c, equMult}];
    schedule = [schedule, {equMult, x_next}, {x_next, equMult}];
    schedule = [schedule, {equMult, add_A_b},  {add_A_b, A}];
    schedule = [schedule, {A, a_equ}, {a_prev, a_equ}, {a_equ, a_next}];

    nwk.setSchedule(schedule);
 
    % the parameters of the model
    % noise variances (not estimated in this example)
    REAL_varU = 0.1; 
    REAL_varW = 0.001;
    
     % the real coefficients
    REAL_A = [1.51, -1.08, 0.47, -0.23, 0.91, -1.30, 0.86, -0.32];
    M = length(REAL_A);

    mean_a = eye(1,M);    
    a_prev.receive(gaussMessage(mean_a, eye(M, M), 'PRECISION'));
    
    % number of observations 
    N_OBSERVATIONS = 10000;
 
    b.setMatrix(eye(M, 1));
    equMult.setMatrix(eye(M, 1)');
    
    % matrix for the observed noise W
    REAL_x = eye(1,M);

    % dummy message to start with
    msg = gaussMessage(REAL_x, eye(M, M) * REAL_varU, 'VARIANCE');
        
    % initial message for noise U (of unobserved x)
    noise_U.receive(gaussMessage(0, REAL_varU, 'VARIANCE'));
    % intitial message for the observation noise
    noise_W.receive(gaussMessage(0, REAL_varW, 'VARIANCE'));
    
    for i = 1:N_OBSERVATIONS
         x_new = REAL_A * REAL_x' + randn() * REAL_varU;
         REAL_x = [x_new, REAL_x(1:end-1)];
         observation = x_new + randn() * REAL_varW;
          
           matrix_A = vertcat(mean_a, horzcat(eye(M-1,M-1), zeros(M-1,1)));
            A.setMatrix(matrix_A);
%          data from the previous observation
          x_prev.receive(msg);
%          observing the data
          y.receive(gaussMessage(observation, 0, 'VARIANCE'));
  
%          doing the inference
          nwk.makeStep();         
%           
          msg = x_next.evidence();
          
         a_prev.receive(a_next.evidence());
    end

   REAL_A
   a_next.evidence().mean
     

end
