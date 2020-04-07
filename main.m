% MAIN
%
% In this script, 5 toy datasets are used to show the abilities of the
% ULEF outlier score. Here, the base version is used, hence no previous
% information of the distance calcaultions are used.
%
% Attention: Execution may take very long, based on the number of nPoints
%
%----------------------------------------------------------------------
% BSD 3-Clause License
%
% Copyright (c) 2020, Jonas Wurst
% All rights reserved.
%----------------------------------------------------------------------


clear all ; close all; clc; clear classes

mod = py.importlib.import_module('ULEFbase');
py.importlib.reload(mod);

if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end


tStart = tic;
k = 15;


RNS = 42;
rng(RNS);

% Number of x and y grid cells --> number of cells total = nPoints^2
% Results in Examples are generated with 100
nPoints = 10;
intervalStretch = 1/8;


%% Data Gneration
% Circle
ang = linspace(0,2*pi,100);
r = 3 + 0.2*randn(1,100);
D{1}(:,1) = r.*cos(ang);
D{1}(:,2) = r.*sin(ang);

ang = linspace(0,2*pi,100);
r = 1.4 + 0.2*randn(1,100);
D{1}(101:200,1) = r.*cos(ang);
D{1}(101:200,2) = r.*sin(ang);


% Moon
D{2}(:,1) = -9+18*rand(1,100);
D{2}(:,2) = 0.2*(D{2}(:,1)').^2 -12 + 0.5*randn(1,100);
D{2}(:,1) = D{2}(:,1) -5;

D{2}(101:200,1) = -9+18*rand(1,100);
D{2}(101:200,2) = -0.2*(D{2}(101:200,1)').^2 +12 + 0.5*randn(1,100);
D{2}(101:200,1) = D{2}(101:200,1) +5;


% 3 different sized Blobs
D{3}(:,1) = 2*randn(1,100);
D{3}(:,2) = 2*randn(1,100);

D{3}(101:200,1) = 5+0.5*randn(1,100);
D{3}(101:200,2) = 0.5*randn(1,100);

D{3}(201:300,1) = -0.5+0.85*randn(1,100);
D{3}(201:300,2) = -6+0.85*randn(1,100);

% 3 same sized Blobs
D{4}(:,1) = 0.5*randn(1,100);
D{4}(:,2) = 0.5*randn(1,100);

D{4}(101:200,1) = 0.5*randn(1,100);
D{4}(101:200,2) = -3+0.5*randn(1,100);

D{4}(201:300,1) = -8+0.5*randn(1,100);
D{4}(201:300,2) = -5+0.5*randn(1,100);

% 3 Line Blobs
D{5}(:,1) = randn(1,100);
D{5}(:,2) = -D{5}(:,1)'+0.5*randn(1,100);
D{5}(:,1) =  D{5}(:,1)-1;

D{5}(101:200,1) =  randn(1,100);
D{5}(101:200,2) = -D{5}(101:200,1)'+0.5*randn(1,100)+3;
D{5}(101:200,1) =  D{5}(101:200,1);

D{5}(201:300,1) =  randn(1,100);
D{5}(201:300,2) = -D{5}(201:300,1)'+0.5*randn(1,100)-1;
D{5}(201:300,1) =  D{5}(201:300,1)+6;


%% Data Processing
for i=5:5
    DataBase = D{i};
    minData = min(DataBase);
    maxData = max(DataBase);
    intervalMin = minData - (maxData - minData)*intervalStretch;
    intervalMax = maxData + (maxData - minData)*intervalStretch;
    
    intervalStepsX = linspace(intervalMin(1),intervalMax(1),nPoints);
    intervalStepsY = linspace(intervalMin(2),intervalMax(2),nPoints);
    [meshX{i},meshY{i}] = meshgrid(intervalStepsX,intervalStepsY);
    
    parfor j=1:nPoints
        ULEFvect = [];
        for l=1:nPoints
            Data = DataBase;
            DataPoint = [intervalStepsX(j),intervalStepsY(l)];
            Data(end+1,:) = DataPoint;
            [ULEFzws, ~, ~] = outlierULEF(Data,k,RNS);
            ULEFvect(l) = ULEFzws(end);
        end
        ULEF(:,j) = ULEFvect;
    end
    figure
    contourf(meshX{i},meshY{i},ULEF)
    hold on
    scatter(D{i}(:,1),D{i}(:,2),20,'r','filled')
    pause(0.1)
end


