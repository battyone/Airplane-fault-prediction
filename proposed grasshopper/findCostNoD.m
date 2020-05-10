function [cost,cellWeights,x] = findCostNoD(individual,normData,targets,...
    trainLen,initLen,inSize,outSize,leakyMat,resMat,spectMat,resConMat,regMat,inScaleMat)

%
% FindCostMSEfor cuckoo serach old
leaky = leakyMat(individual(1));
resSize = resMat(individual(2));
spectralRad = spectMat(individual(3));
resConn = resConMat(individual(4));
reg = regMat(individual(5));




resWeights =  sprand(resSize,resSize,resConn);%-0.5;

resWghtsMask = (resWeights~=0);

resWeights(resWghtsMask) = (resWeights(resWghtsMask)*2-1);


opt.disp = 0;
rhoW = abs(eigs(resWeights ,1,'LM',opt));

value = 25;
while  isnan(rhoW)
    rhoW = abs(eigs(resWeights ,1,'LM','SubspaceDimension',value));
    value = value + 3;
end

resWeights  = resWeights .* (spectralRad/rhoW);

inputWeights = rand(resSize,1+inSize)*2 -1;

%inputWeight scaling

numCols = inSize + 1;

for i = 1: numCols
    presentMatrix = inputWeights(:,i);
    esvd = svds(presentMatrix,1);
    index = individual(5+i);
    presentMatrix = presentMatrix .* (inScaleMat(index)/esvd);
    inputWeights(:,i) =  presentMatrix;
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

newTrainLen = round(trainLen*0.7);
validLen =  round(trainLen*0.3);

reservAct = zeros(1+inSize+resSize,newTrainLen-initLen);

x = zeros(resSize,1); %initial instance of reservoir states

savingTheExs = zeros(resSize, newTrainLen);

for t = 1:newTrainLen
    u = normData(t,:)';
    x = (1-leaky)*x + leaky*tanh(inputWeights*[1;u] + resWeights*x );
    savingTheExs(:,t) = x;
    if t > initLen
        reservAct(:,t-initLen) = [1;u;x];
    end
end



%Wout finding
yTarget = targets(initLen+1:newTrainLen);

outputWeights = ((reservAct*reservAct' + reg*eye(1+inSize+resSize)) \ (reservAct*yTarget))';
%outputWeights = yTarget'*pinv(reservAct);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Test for trainLen
%yPredicted = outputWeights* reservAct;
%yReal = targets(initLen+1:newTrainLen);
%squareErrors = (yReal-yPredicted').^2;
%rmseTrain = sqrt(sum(squareErrors)/length(yPredicted));


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%for valid

yPredicted = zeros(validLen,outSize);


for t = 1:validLen %
    u = normData(t+newTrainLen,:)';
    x = (1-leaky)*x + leaky*tanh(inputWeights*[1;u] + resWeights*x);
    ySmall =  outputWeights*[1;u;x];
    yPredicted(t) = ySmall;
end




yReal = targets(newTrainLen+1:newTrainLen + validLen);
squareErrors = (yReal-yPredicted).^2;
%rmseValid = sqrt(sum(squareErrors)/length(yPredicted));

mseValid = sum(squareErrors)/length(yPredicted);
%cost = rmseTrain + abs(rmseTrain-rmseValid);


%cost = rmseValid + evs;

cost = mseValid;


cellWeights = cell(1,3);

cellWeights{1} = inputWeights;
cellWeights{2} = resWeights;
cellWeights{3} = outputWeights;
end