% MAIN_SCENARIO_ROUTE
%
% With this script, the infrastructure images along a road are tested with
% respect to their ULEF outlier score in comparison to a base dataset,
% which represents a highway drive
%
%----------------------------------------------------------------------
% BSD 3-Clause License
%
% Copyright (c) 2020, Jonas Wurst
% All rights reserved.
%----------------------------------------------------------------------

clear all ; close all; clc; clear classes

% Include the python code
mod = py.importlib.import_module('ULEFbase');
py.importlib.reload(mod);
if count(py.sys.path,'') == 0
    insert(py.sys.path,int32(0),'');
end

RNS = 42;
rng(RNS);
k = 15;

%%
BaseFolder = 'Data\MUC_B300_n\';

% First load all images of the base dataset
DataFull = [];
listing = dir(fullfile([BaseFolder],'*.png'));
for j = 1:size(listing,1)
    I = imread([BaseFolder,listing(j).name]);
    if ndims(I)==3
        I = rgb2gray(I);
    end
    DataFull(j,:) = double(I(:))/255;
end

DataBase = DataFull;


%%

BaseFolder = 'Data\A9_THI_Residential\';

% Then load all the images of the outlier dataset
DataFull = [];
listing = dir(fullfile([BaseFolder],'*.png'));
for j = 1:size(listing,1)
    I = imread([BaseFolder,num2str(j),'.png']);
    if ndims(I)==3
        I = rgb2gray(I);
    end
    DataFull(j,:) = double(I(:))/255;
end
DataSetOutlier = DataFull;

%% Caclualte the outlier scores for all data points in the outlier data set

D =[];
DataLeftOut = [];
idxLeftOut = [];
idxBaseAdd = [];
rankingVector =[];

% Run over all outliers
for iOuts =1 : size(DataSetOutlier,1)
    tic
    disp(['Outlier ',num2str(iOuts),' of ',num2str(size(DataSetOutlier,1))])
    
    % Append the iOuts-th outlier to the end of the base dataset
    Data =  [DataBase;DataSetOutlier(iOuts,:)];
    
    % Get the NEW nearest neighbors distance and indcies (only for the points where somthing changed)
    [knnDistsPre, knnIndexPre, D] = outlierPreProcess_D(Data,min(k+1,size(Data,1)),D,size(Data,1));
    knnDists = knnDistsPre(:,2:end);
    knnIndex = knnIndexPre(:,1:end);
    rhos =[];
    sigmas =[];
    knnIndexOld =[];
    ULEF = [];
    
    % Get the NEW outlier scores (only for the points where somthing changed)
    trueOutliersINvec = size(Data,1);
    [ULEF, rhos, sigmas] = outlierULEF_D(knnDistsPre(:,1:k+1), knnIndexPre(:,1:k+1), Data,k,RNS,D, rhos,sigmas, knnIndexOld,ULEF);
    
    knnIndexOld = knnIndexPre(:,2:k+1);
   
    rankingVector(end+1) = (ULEF(end)- min(ULEF(1:end-1)))/(max(ULEF(1:end-1))-min(ULEF(1:end-1)));
    toc
end

%% Plot
picBBox = [48.74724751595803,11.41427993774414,48.7750280789073,11.486034393310547];

ratio = (2593/1523);
color = 1-min(1,60*(rankingVector));

green = [0,100,0]/100;
red = [100,0,0]/100;

g2r(1,:) = linspace(green(1),red(1),100);
g2r(2,:) = linspace(green(2),red(2),100);
g2r(3,:) = linspace(green(3),red(3),100);

NInBetween = 10;
pointInBetween = [];
colorInBetween = [];

mapImage = gray(256);
mapOutlier = g2r';

I = imread('Data\map.png');
load('Data\positions.mat')

% Generate the figure
figure('units','normalized','outerposition',[0 0 1 1])
h1 = axes;
pbaspect([ratio 1 1])
axis off
hold on

% Plot the background image
image('CData',fliplr(flipud(ind2rgb(I,mapImage))),'XData',[picBBox(4) picBBox(2)],'YData',[picBBox(1) picBBox(3)])


% Plot the acutal centers of the images
colormap(g2r')
scatter(NodePos(1:end-1,3),NodePos(1:end-1,2),30,color*100,'Parent',h1,'filled')

% Generate 100 inbetween points per point pair for a smoother plotting
for i=1:numel(color)-1
    colorInBetween = linspace(color(i),color(i+1),NInBetween);
    I2 = squeeze(mapOutlier(ceil(colorInBetween*100+eps()),:));
    pointInBetween(:,1) = linspace(NodePos(i,3),NodePos(i+1,3),NInBetween+1);
    pointInBetween(:,2) = linspace(NodePos(i,2),NodePos(i+1,2),NInBetween+1);
    for j=1:NInBetween
        plot(pointInBetween(j:j+1,1),pointInBetween(j:j+1,2),'Color',I2(j,:),'LineWidth',3)
    end
end

