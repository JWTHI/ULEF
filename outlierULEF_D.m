function [ ULEF,rhos,sigmas] = outlierULEF_D(knnDists, knnIndex, Data, k, RNS, D, rhos, sigmas, knnIndexOld, ULEFold)
    %OUTLIERULEF_D Determines the ULEF score for changed data points.
    %   Only the last data point is considered for possible changes.
    %   If the last data point was in the neighborhood of other points,
    %   they are recalculated as well. 
    %
    %----------------------------------------------------------------------
    % BSD 3-Clause License
    %
    % Copyright (c) 2020, Jonas Wurst
    % All rights reserved.
    %----------------------------------------------------------------------
    
    if isempty(sigmas) && isempty(rhos)
        graph1 = py.ULEFbase.ULEFbase(py.numpy.array(Data),int32(k+1),int32(RNS),'euclidean',py.numpy.array(knnIndex-1),py.numpy.array(knnDists));
        Pdata = double(graph1{1});
        row = double(graph1{2})+1;
        col = double(graph1{3})+1;
        sigmas = double(graph1{4});
        rhos = double(graph1{5});
        knnIndex = double(graph1{6})+1;
        knnDist = double(graph1{7});
    else
        %Check where the old outlier was in the knn of an other data point
        recalc = any(knnIndexOld(1:end-1,:)==size(knnIndexOld,1),2);
        
        %Check if the current outlier is in the knnn of a data point
        recalc = recalc | any(knnIndex(1:end-1,2:k+1)==size(knnIndexOld,1),2);
        
        recalc = [recalc;true];
        
        refVect = 1:numel(recalc);
        recalcIdx = refVect(recalc);
        reducedDists = knnDists(recalcIdx,:);
        if size(reducedDists,1)==1
            reducedDists = [reducedDists;reducedDists];
        end
        pythonOutput = py.ULEFbase.smooth_knn_dist(py.numpy.array(reducedDists), double(k+1));
        sigmasOut = double(pythonOutput{1});
        rhosOut = double(pythonOutput{2});
        if numel(recalcIdx)==1
            sigmas(recalcIdx)=sigmasOut(1);
            rhos(recalcIdx) = rhosOut(1);
        else
            sigmas(recalcIdx)=sigmasOut;
            rhos(recalcIdx) = rhosOut;
        end
        ULEF = ULEFold;
        
        recalc2 = any(knnIndex(:,1:k+1)==recalcIdx(1),2);
        if numel(recalcIdx)>=2
            for i=2:numel(recalcIdx)
                recalc2 = recalc2 | any(knnIndex(:,1:k+1)==recalcIdx(i),2);
            end
        end
    end
    %% Get Score
    recalcIdx2 = 1:size(D,1);
    for iIN=recalcIdx2
        idx = knnIndex(iIN,2:k+1);
        % Get scores for incoming affinity of knns
        for jIN=1:numel(idx)
            if D(iIN,idx(jIN)) - rhos(idx(jIN)) <= 0.0
                PSub(iIN,jIN) = 1;
            else
                PSub(iIN,jIN) = exp(-((D(iIN,idx(jIN)) - rhos(idx(jIN))) / (sigmas(idx(jIN))))) ;
            end
        end
    end
    PSubZws = PSub/log2(k);
    
    for iIN=recalcIdx2
        ULEF(iIN) = -sum((PSubZws(iIN,:)/sum(PSubZws(iIN,:))).*log2((PSubZws(iIN,:))/sum(PSubZws(iIN,:)))/log2(k),'omitnan')*sum(PSubZws(iIN,:)*(log2(k))/k);
    end
end