function [] = createKNetTrainFile()
% PASCALKPSMULTICLASSTRAINVALCREATE  Generates the text file that is output
% to the data layer of the keypoint network.


% Declare global variables
globals;


% We're interested only in the 'car' class, as of now. Load keypoints for
% the 'car' class.
load('data/segkps/car');
class = 'car';
classInd = 7;

% Load the train/val split for pascal
load(fullfile(cachedir,'pascalTrainValIds.mat'));

% Dimensions of the heatmap to be used for multi-scale response fusion
dims = params.heatMapDims;
% Threshold on the heatmap (???)
probThresh = params.heatMapThresh;

% Iterate over each keypoint annotation
numSamples = length(keypoints.voc_image_id);
txtFile = fullfile(finetuneKpsDir, 'KNetTrainFile.txt');
fid = fopen(txtFile, 'w+');
temp = [];
count = 0;
for i = 1:numSamples
    % Load the image
    img = imread(fullfile(pascalImagesDir, [keypoints.voc_image_id{i}, '.jpg']));
    % Get the bounding box corresponding to the left wheel center (the
    % first keypoint)
    curKeypoint = squeeze(keypoints.coords(i,:,:));
    leftWheel = curKeypoint(1,:);
    % Reject samples that have NaN for the left wheel
    if isnan(leftWheel(1)) || isnan(leftWheel(2))
        continue
    end
    % Load the 'cands' struct for the current detection. It contains more
    % information on occlusion, difficulty, etc.
    cands = load(fullfile(rcnnKpsPascalDataDir, keypoints.voc_image_id{i}));
    % if sum(cands.difficult) > 30
    %     continue
    % end
    % Get all 'good' indices, i.e., indices that contain cars, and that are
    % not occluded, truncated, or difficult
    goodInds = ismember(cands.boxClass, classInd);
    goodInds = goodInds & ~cands.difficult;
    
    % Sample a 32-by-32 window around the keypoint
    x1 = leftWheel(1) - 15;
    x2 = leftWheel(1) + 16;
    y1 = leftWheel(2) - 15;
    y2 = leftWheel(2) + 16;
    % Ensure that the window does not go outside the image
    outsideFlag = false;
    imsize = size(img);
    if x1 < 0
        x1 = 0;
        outsideFlag = true;
    end
    if y1 < 0 
        y1 = 0;
        outsideFlag = true;
    end
    if x2 > imsize(2)
        x1 = imsize(2);
        outsideFlag = true;
    end
    if y2 > imsize(1)
        y2 = imsize(1);
        outsideFlag = true;
    end
    % Resize the final image to 32-by-32
    % imgNew = imresize(img, [32, 32]);
    if outsideFlag
        continue
    end
    
    imgNew = img(y1:y2, x1:x2, :);
    
    if size(imgNew,1) == 32 && size(imgNew,2) == 32
        count = count + 1;
    end
    
    imgLocation = [basedir, 'cachedir/KNetTrainFiles/train32/', keypoints.voc_image_id{i}];
    imwrite(img, imgLocation, 'jpg');
    fprintf(fid, '%s %f,%f 0,0,0,0,0 0\n', imgLocation, 
    
end


%% Generating window files


% % Generate only training and validation data
% sets = {'Train','Val'};
% 
% % For each set (train/val)
% for s=1:length(sets)
%     % Get the current set
%     set = sets{s};
%     % If occluded samples are not to be excluded, ensure that another
%     % element 'Occluded' is added to the name of the generated text file.
%     if(~params.excludeOccluded)
%         set = [set 'Occluded'];
%     end
%     % Display a status message.
%     disp(['Generating data for ' set]);
%     % Create a text file
%     txtFile = fullfile(finetuneKpsDir, [set num2str(dims(1)) '.txt']);
%     % Open the text file for writing
%     fid = fopen(txtFile,'w+');
%     % Get the list of filenames for files in the current set
%     fnames = fnamesSets{s};
%     % Sequence number of the current file being processed
%     count = 0;
%     % For each file in the current set
%     for j=1:length(fnames)
%         % Get the file name
%         id = fnames{j};
%         % If the corresponding mat file does not exist, continue
%         if(~exist(fullfile(rcnnKpsPascalDataDir,[id '.mat']),'file'))
%             continue;
%         end
%         % Load the mat file
%         cands = load(fullfile(rcnnKpsPascalDataDir,id));
%         % Get good indices (indices whose values can be written out)
%         goodInds = ismember(cands.boxClass,classInds);
%         % Exclude samples that would not prove useful for training
%         if(params.excludeOccluded)
%             goodInds = goodInds & ~cands.occluded & ~cands.truncated & ~cands.difficult ;
%         else
%              goodInds = goodInds & ~cands.difficult;
%         end
%         
%         % Class label
%         cands.boxClass = cands.boxClass(goodInds);
%         % Keypoint annotations
%         cands.kps = cands.kps(goodInds);
%         % Bounding boxes
%         cands.bbox = cands.bbox(goodInds,:);
%         % Overlap ratio
%         cands.overlap = cands.overlap(goodInds,:);
%         
%         % Number of possible candidates
%         numposcands = size(cands.bbox,1);
%         numcands = numposcands;
%         % If no candidates exist, continue
%         if(numcands == 0)
%             continue;
%         end
%         
%         % If candidates exist, begin writing them to file
%         
%         % Increment the sequence number
%         count=count+1;
%         % Absolute path to the image file
%         imgFile = fullfile(pascalImagesDir, [id '.jpg']);
%         % Dimensions of the image
%         imsize = cands.imsize;
%         % Write out image metadata to the file
%         % sequence number, abs path to img file, num channels, num rows,
%         % numcols, totalKps*heatmapRows*heatmapCols, number of candidates
%         fprintf(fid,'# %d\n%s\n%d\n%d\n%d\n%d\n%d\n',count-1,imgFile,3,imsize(1),imsize(2),totalKps*dims(1)*dims(2),numcands);
%         % For each possible candidate
%         for n = 1:numposcands
%             % Normalize keypoint coordinates
%             [kpNum, kpCoords] = normalizeKps(cands.kps{n},cands.bbox(n,:),dims);
%             [kpNum,kpCoords,kpVal] = gaussianKps(kpNum,kpCoords,dims,probThresh);
%             kpNum = kpNum + kpIndexStart(cands.boxClass(n));
%             fprintf(fid,'%d %.3f %d %d %d %d %d %d %d',cands.boxClass(n),cands.overlap(n),cands.bbox(n,1),cands.bbox(n,2),cands.bbox(n,3),cands.bbox(n,4),numel(kpNum),kpIndexStart(cands.boxClass(n))*dims(1)*dims(2),kpIndexStart(cands.boxClass(n))*dims(1)*dims(2)+kpNums(cands.boxClass(n))*dims(1)*dims(2)-1);
%             for k=1:numel(kpNum)
%                 %print array index as 1d location
%                 kpInd = (kpNum(k)-1)*dims(1)*dims(2) + (kpCoords(k,2)-1)*dims(1) + (kpCoords(k,1)-1);
%                 flipKpInd = (flipKps(kpNum(k))-1)*dims(1)*dims(2)+ (kpCoords(k,2)-1)*dims(1)+ (dims(1) - kpCoords(k,1));
%                 fprintf(fid,' %d %d %.2f',kpInd, flipKpInd, kpVal(k));
%                 %print array index as [kpNum,x,y]
%                 %fprintf(fid,' %d %d %d',kpNum(k),kpCoords(k,1),kpCoords(k,2));
%             end
%             %if(numel(kpNum)==0)
%             %    disp('oops');
%             %end
%             fprintf(fid,'\n');           
%          end
%     end
%     disp(count);
% end

end