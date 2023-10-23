% Load base case parameters 
clc;
clear;
params;
define_constants;
nBus=mpc.bus(end,1);

% Executa o fluxo de potencia para obter perdas de energia iniciais e perfil de tensão  
iniResults=runpf(mpc,mpoption('verbose',0,'pf.alg','PQSUM','out.all',0));

iniLoss=sum(real(get_losses(iniResults)));

fprintf(" x1 | x2 | y1 | y2 | Losses(kW) | VDI | FO\n");
%Setup PSO parameters
nvars=nCap*2; % Número de variáveis ​​(2 * numero de bancos). Otimize a localização e o tamanho
lb=zeros(1,nvars); %Definir limite inferior
lb(1:nCap)=2; % O limite inferior da localização é 2, 1 é feederbus
lb(nCap+1:2*nCap)=CapMin; % Limite inferior do tamanho definido pelo usuário
ub=zeros(1,nvars); %%Definir limite superior
ub(1:nCap)=nBus; % O limite superior da localização é o último barramento (33 ou 69)
ub(nCap+1:2*nCap)=CapMax; % Limite superior do tamanho definido pelo usuário
% PSO Settings
% Visit <https://www.mathworks.com/help/gads/particleswarm.html> for more info
options = optimoptions('particleswarm','PlotFcn',@pswplotbestf);
obj_func=@(x)objectives(x,mpc,iniLoss,lossWeight,voltageWeight,PD,QD,VM,CapPf,CapWeight); %Chama FO 
rng default  % Para reprodutibilidade
[x,fval,exitflag,output] = particleswarm(obj_func,nvars,lb,ub,options);
x(1:nCap)=round(x(1:nCap)); % Aplicar condição de número inteiro para localização


% Coloque os Bancos com tamanho e localização ideais no sistema
for i=1:nCap
    mpc.bus(x(i),PD)=mpc.bus(i,PD)-x(nCap+i)*CapPf/1000; 
    mpc.bus(x(i),QD)=mpc.bus(i,QD)-x(nCap+i)*(sqrt(1-CapPf*CapPf))/1000;
end

% Runs power flow após dimensionamento e colocação ideais dos capacitores
results=runpf(mpc,mpoption('verbose',0,'pf.alg','PQSUM','out.all',0));

%Display results ********************************************************
display("Resultados ótimos encontrados : ");
display('Bus No     Size(kVar)');
display([x(1:nCap)', x(nCap+1:nvars)']);
fprintf("\n Losses before Cap placement (KW): %f",iniLoss*1000);
fprintf("\n Losses after Cap placement (KW): %f",sum(real(get_losses(results)))*1000);

%Plot results ********************************************************
figure(2);
plot(iniResults.bus(:,VM),'red');
hold on;
plot(results.bus(:,VM),'green');
hold off;
title('Perfil de tensão do sistema');
xlabel('Barras') ;
ylabel('Tensão [p.u]') ;
legend('Perfil de tensão inicial','Após alocação dos capacitores');

figure(3);
losses=[sum(real(get_losses(iniResults))); sum(real(get_losses(results)))]*1000;
legends=categorical({'Perdas iniciais', 'Após alocação dos capacitores'});
legends = reordercats(legends,{'Perdas iniciais', 'Após alocação dos capacitores'});
bar(legends,losses);
title('Perdas totais de potência ativa (kW)');

figure(4);
losses=[sum(imag(get_losses(iniResults))),sum(imag(get_losses(results)))]*1000;
legends=categorical({'Perdas iniciais', 'Após alocação dos Bancos'});
legends = reordercats(legends,{'Perdas iniciais', 'Após alocação dos Bancos'});
bar(legends,losses,'R');
title('Perdas totais de potência reativa (kVAR)');

fprintf("\n Compensação Reativa (R$/dia): %f",(iniLoss*1000 - sum(real(get_losses(results)))*1000)*0.950*30);
display('Custo Banco total');
display(5360*[x(nCap+1:nvars)']);
