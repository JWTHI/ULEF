function [knnDists, knnIndex,D] = outlierPreProcess_D(Data,k,Dold,idxNew)
if isempty(Dold)
    D = squareform(pdist(Data));
else
    D = Dold;
    newDist = pdist2(Data,Data(idxNew,:));
    D(idxNew,:) = newDist;
    D(:,idxNew) = newDist;
end

[knnDists, knnIndex] = mink(D,k+1,2);
end