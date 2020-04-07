function [ULEF,USLEF,knnIndex] = outlierULEF(Data, k, RNS)
    %outlierULEF Determines the ULEF outlier score given the Data and the
    %   number of neighbors k
    %
    %----------------------------------------------------------------------
    % BSD 3-Clause License
    %
    % Copyright (c) 2020, Jonas Wurst
    % All rights reserved.
    %----------------------------------------------------------------------
    
    graph1 = py.ULEFbase.ULEFbaseData(py.numpy.array(Data),int32(k+1),int32(RNS),'euclidean');
    Pdata = double(graph1{1});
    row = double(graph1{2})+1;
    col = double(graph1{3})+1;
    sigmas = double(graph1{4});
    rhos = double(graph1{5});
    knnIndex = double(graph1{6})+1;
    knnDist = double(graph1{7});
    P = sparse(row,col,Pdata, size(Data,1),size(Data,1));
    
    %% Get Score
    
    ULEF = zeros(1,size(Data,1));
    USLEF = zeros(1,size(Data,1));
    PSub = zeros(1,k);
    for iIN=1:size(Data,1)
        idx = knnIndex(iIN,2:k+1);
        % Get scores for incoming affinity of knns
        for jIN=1:numel(idx)
            dist = knnDist(iIN,jIN);
            if dist - rhos(idx(jIN)) <= 0.0
                PSub(jIN) = 1;
            else
                PSub(jIN) = exp(-((dist - rhos(idx(jIN))) / (sigmas(idx(jIN))))) ;
            end
        end
        PSubZws = PSub/log2(k);
        ULEF(iIN) = -sum((PSubZws/sum(PSubZws)).*log2((PSubZws)/sum(PSubZws))/log2(k),'omitnan')*sum(PSubZws*(log2(k))/k);
        
        PSubKnn = full(nonzeros(P(knnIndex(iIN,2:k+1),iIN)))/log2(k);
        USLEF(iIN) = -sum((PSubKnn/sum(PSubKnn)).*log2((PSubKnn)/sum(PSubKnn))/log2(k),'omitnan')*sum(PSubKnn*(log2(k))/k);
    end
end