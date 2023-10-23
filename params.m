% SET THE PARAMETERS YOU WANT TO OPTIMIZE.
nCap=1; % Número de Bancos a ser colocado no sistema
mpc=loadcase('case69');% arquivo de caso matpower para fluxo de energia ('case33' para sistema de 33 barramentos 'case69' para sistema de 69 barramentos)
CapMax = 2;  %Potência máxima de Banco de capacitores a ser colocada no sistema (kVar)
CapMin = 1;  %Potência minima de Banco de capacitores a ser colocada no sistema (kVar)
CapPf = 0; % Fator de potência
%Cbank = 5.36 * Qbank - 112.02; %(Função Custo capacitores)

% %PSO Parameters ( Se quiser especificar o número de particulas )
swarmSize=5000; % Num of particles in the swarm; 'SwarmSize',swarmSize

%Objective Function Parameters
%+CapWeight*Capobjective%
voltageWeight=0.8; % Voltage weight  
lossWeight=0.2; % Loss weight 
CapWeight=0.1; %(Tamanho do banco de capacitor)