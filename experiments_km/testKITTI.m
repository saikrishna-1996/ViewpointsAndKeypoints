
% We're intereseted only in the 'car' class
class = 'car';

% Turn off Matlab warnings
warning('off', 'all');

% Declare global variables
globals;

% % Initialize the network for viewpoint prediction
% initViewpointNet;


%% Parameters for KITTI (test data)

% ID of the sequence to be processed
sequenceNum = 2;
% ID of the first image to process (in the sequence specified)
startImageId = 90;
% ID of the last image to process (in the sequence specified)
endImageId = 110;
% ID of the car to track
carId = 0;
% Mode ('manual', or 'auto'). Specifies if the user will input the bounding
% box or if they have to be picked up from the ground truth.
bboxMode = 'manual';

% Creating a list of images to process
imageList = startImageId:endImageId;

% Base directory (containing KITTI data)
kittiBaseDir = fullfile(basedir, 'data', 'KITTI');
% Root directory containing KITTI images (for training sequences)
kittiImageDir = fullfile(kittiBaseDir, sprintf('image_02/%04d', sequenceNum));

% Create an array to store the predictions
yawPreds = zeros(size(imageList));

% Predict pose for each image
for i = 1:length(imageList)
    
    % Generate the file path for the current image to be processed
    imgFile = fullfile(kittiImageDir, sprintf('%06d.png',imageList(i)));
    % Load the image
    img = imread(imgFile);
    
    if strcmp(bboxMode, 'manual')
        % Display the image, and wait for the user to draw a bounding box
        % around the object of interest
        imshow(img);
        r = imrect;
        position = wait(r);
        bbox = single([position(1), position(2), position(1)+position(3), position(2)+position(4)]);
    end
    
    dataStruct.bbox = bbox;
    dataStruct.fileName = imgFile;
    dataStruct.labels = single(pascalClassIndex(class));
    
    % Run the network on one image
    featVec = runNetOnce(cnn_model, dataStruct);
    
    % Get pose from the feature vector
    yaw = getPoseFromFeat(featVec);
    % Display the prediction
    disp(yaw);
    % Store the prediction
    yawPreds(i) = yaw;
    
end


% seqName = 'Seq00';
% imgName = '000006.png';
% 
% img = imread(fullfile(kittiBaseDir, seqName, imgName));
% % For image 0
% % bbox = single([295, 165, 454, 290]);
% 
% 
% imshow(img);
% r = imrect;
% position = wait(r);
% bbox = single([position(1), position(2), position(1)+position(3), position(2)+position(4)]);
% % imshow(img);
% % hold on;
% % rectangle('Position', [295, 165, (454-295), (290-165)]);
% 
% % Create a data structure to hold relevant parameters
% dataStruct.bbox = bbox;
% dataStruct.fileName = fullfile(kittiBaseDir, seqName, imgName);
% dataStruct.labels = single(pascalClassIndex(class));
% 
% % Run the network on one image
% featVec = runNetOnce(cnn_model, dataStruct);


%% Get pose from the feature vector

% yaw = getPoseFromFeat(featVec);



































