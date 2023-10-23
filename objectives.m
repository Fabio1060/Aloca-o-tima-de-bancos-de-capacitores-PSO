function y = objectives(x,mpc,iniLoss,lossWeight,voltageWeight,PD,QD,VM,CapPf,Capobjective,params)  
%Definir os Objetivos do sistema
    nCap=numel(x)/2;
    x(1:nCap)=round(x(1:nCap)); %Aplicar condição inteira para colocação dos bancos
    % Posicione o capacitor com tamanho e localização ótimos no sistema.
    for i=1:nCap
        mpc.bus(x(i),PD)=mpc.bus(i,PD)-x(nCap+i)*CapPf/1000; %Comunicação com o MATPOWER
        mpc.bus(x(i),QD)=mpc.bus(i,QD)-x(nCap+i)*(sqrt(1-CapPf*CapPf))/1000;   
    end

    % Run power flow após dimensionamento e colocação ideais de Cap
    results=runpf(mpc,mpoption('verbose',0,'pf.alg','PQSUM','out.all',0));

    % Função Objetivo
  
    % Calcule o erro quadrático médio para magnitude de 1 pu
    vmag=results.bus(:,VM);% Magnitude da tensão de todas as barras
    vmag=vmag-1; %Calcular erro para todas as barras
    vmag=vmag.*vmag; %Quadrado do erro
    vobjective=sum(vmag)/numel(vmag);% Obtenha o erro quadrático médio (Índice de desvio de tensão)

    %Calcular as perdas de potencia ativa
    loss=sum(real(get_losses(results)));
    lobjective=loss/iniLoss;%Razão de perdas com Bancos/ Perdas sem bancos (Índice de perdas)
    Capobjective = 5.36*(iniLoss-loss)-112.02; % Função do custo do banco de capacitores
    
    % Calcular função objetiva combinando desvio de tensão e índice de perdas
    CapWeight = 0.1;
    y=lossWeight*lobjective+voltageWeight*vobjective+CapWeight*Capobjective;
    fprintf("%f |",x); 
    fprintf("%f |", lobjective*iniLoss*1000);
    fprintf("%f |", vobjective);
    fprintf("%f\n", y);
    
end