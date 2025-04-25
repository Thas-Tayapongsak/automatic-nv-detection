%% demo
clc; clear all; close all;

%% load image
imgFolder = "NV_OCTImages";

imgNames = dir("NV_OCTImages\*.jpeg");

imgRaw = cell(1,numel(imgNames));

for i = 1:numel(imgNames)
    imgRaw{i} = imread(imgFolder + "\" + imgNames(i).name);
end

%% show raw images
% showImages(imgRaw,4,5,imgNames)
figure
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   imshow(imgRaw{i})
   title(imgNames(i).name)
end

%% remove white border
imgClean = cell(1,numel(imgRaw));
imgWhite = cell(1,numel(imgRaw));

for i = 1:numel(imgRaw)
    imgClean{i} = imgRaw{i};
    imgWhite{i} = imgRaw{i};

    %get white area
    imgWhite{i}(imgRaw{i} < 225) = 0;
    
    %remove non-border white
    imgWhite{i} = imcomplement(imfill(imcomplement(imgWhite{i}),'holes'));
    %imgWhite{i} = imopen(imgWhite{i},strel('disk',9));

    %replace white border with black
    imgClean{i}(imgWhite{i} > 0) = 0;
end

%% show clean images
% showImages(imgClean,4,5,imgNames)
figure
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   imshow(imgClean{i})
   title(imgNames(i).name)
end

%% noise filter
imgFiltered = cell(1,numel(imgClean));

for i = 1:numel(imgRaw)
    imgEq = imadjust(imgClean{i});
    %imgFiltered{i} = imgaussfilt(imgClean{i},1,"FilterSize",5); -> doesn't
    %remove noise in black regions
    imgMed  = medfilt2(imgEq, [4,4]);
    imgFiltered{i} = imgaussfilt(imgMed);
end

%% show filtered images
% showImages(imgFiltered,4,5,imgNames)
figure
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   imshow(imgFiltered{i})
   title(imgNames(i).name)
end

%% binarize
imgBin = cell(1,numel(imgFiltered));

for i = 1:numel(imgFiltered)
    imgBin{i} = imbinarize(imgFiltered{i});
end

%% show binarized images
% showImages(imgBin,4,5,imgNames)
figure
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   imshow(imgBin{i})
   title(imgNames(i).name)
end

%% fill
imgFilled = cell(1,numel(imgBin));

for i = 1:numel(imgBin)

    imgClose = imclose(imgBin{i},strel('disk',4));
    
    %imgClose = imgBin{i};
    
    [h w] = size(imgClose);

    [rows, columns] = find(imgClose);

    leftCol = min(columns);
    rightCol = max(columns);

    %pad to prepare for filling
    imgClose(:,1:leftCol) = 255; 
    imgClose(:,rightCol:w) = 255; 
    imgClose(1, :) = 0; % top padding
    imgClose(h, :) = 255; % bottom padding / set to 0 to not fill the bottom

    % fill floating white blobs, then fill black cavities & bottom part
    imgClose = imclose(imgClose,strel('disk',4)); 
    imgF = imfill(imcomplement(imfill(imcomplement(imgClose), 'holes')), 'holes');

    imgFilled{i} = imgF;
end

%% show filled images
% showImages(imgFilled,4,5,imgNames)
figure
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   imshow(imgFilled{i})
   title(imgNames(i).name)
end

%% Get GT images
imgGTFolder = "NV_GT";

imgGT = cell(1,numel(imgNames));

for i = 1:numel(imgNames)
    imgGT{i} = imread(imgGTFolder + "\LINE_ALBUM_Ground Truth_241120_" + int2str(i) + ".jpg");
end

%% Corner Detection: Using Harris Corner Detector
filterSize = 7;
minQuality = 0.4;
figTitle = strcat('filter size:', num2str(filterSize), ', min quality: ', num2str(minQuality));

% figure('Name', figTitle)
% tiledlayout(4,5)
% for i = 1:20
%    nexttile
%    enhancedImage = imgFilled{i};
%    corners = detectHarrisFeatures(enhancedImage,"FilterSize",filterSize,"MinQuality",minQuality);
%    imshow(imgGT{i})
%    hold on;
%    plot(corners.selectStrongest(10)); % Plot the 50 strongest corners
%    hold off;
%    %imshow(imgFilled{i})
%    title(strcat(num2str(corners.Count),' corners in ',imgNames(i).name));
% end

figure('Name', figTitle)
tiledlayout(2,2)
for i = [1,4,10,15]
   nexttile
   enhancedImage = imgFilled{i};
   corners = detectHarrisFeatures(enhancedImage,"FilterSize",filterSize,"MinQuality",minQuality);
   imshow(imgFilled{i})
   hold on;
   plot(corners.selectStrongest(10)); % Plot the 50 strongest corners
   hold off;
   %imshow(imgFilled{i})
   title(strcat(num2str(corners.Count),' corners in ',imgNames(i).name));
end

%% save figures
filterSize = 3;
minQuality = 0.2;

for s = 1:3
    for q = 2:7
        for i = 1:20
           figure()
           tiledlayout(1,1)
           enhancedImage = imgFilled{i};
           corners = detectHarrisFeatures(enhancedImage,"FilterSize",2*s+1,"MinQuality",q/10);
           imshow(imgGT{i})
           hold on;
           plot(corners.selectStrongest(10)); % Plot the 50 strongest corners
           hold off;
           saveas(gcf, "NV_eval\s" + num2str(2*s+1) + "\q" + num2str(q) + "\" + imgNames(i).name)
           close all force
        end
    end
end

% % Corner Detection: with KDE
% figure('Name', figTitle)
% tiledlayout(2,3)
% for i = 4:10%numel(imgBin)
%    nexttile
%    enhancedImage = imgFilled{i};
%    corners = detectHarrisFeatures(enhancedImage,"FilterSize",filterSize,"MinQuality",minQuality);
%    imshow(enhancedImage);
%    strongestCorners = corners.selectStrongest(10);
%    kdeCorners = corners;%.selectStrongest(50);
%    hold on;
%    plot(strongestCorners); % Plot the 50 strongest corners
%    [fp, xfp] = ksdensity(kdeCorners.Location(:,1),'Weights',kdeCorners.Metric);
%    [~, maxi]= max(fp);
%    xline(xfp(maxi),'-r',{'Highest','Prob'});
%    hold off;
%    imshow(imgFilled{i})
%    title(strcat(num2str(corners.Count),' corners in ',imgNames(i).name));
% end

% %% kde example
% [fp, xfp] = ksdensity(kdeCorners.Location(:,1),'Weights',kdeCorners.Metric);
% plot(xfp,fp)

%% Blob Detection: Using MSER (Maximally Stable Extremal Regions) feature detector
% doesn't detect anything :(
% figure
% tiledlayout(2,3)
% for i = 1:6%numel(imgBin)
%     nexttile
%     enhancedImage = imgFiltered{i};
%     mserRegions = detectMSERFeatures(enhancedImage, 'RegionAreaRange',[30 14000], 'ThresholdDelta', 4);
%     imshow(enhancedImage);
%     hold on;
%     plot(mserRegions, 'showPixelList', true, 'showEllipses', false);
%     hold off;
%     title(imgNames(i).name)
% end

%% functions

function showImages(imglist, width, height, imgNames)
    figure
    tiledlayout(width,height)
    for i = 1:numel(imglist)
       nexttile
       imshow(imglist{i})
       title(imgNames(i).name)
    end
end


