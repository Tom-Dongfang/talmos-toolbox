function tsHandles = imageToolbar(figureToEnhance)
% Insert toolbar for image manipulations in specified figure.
%
% Inserts a new toolbar with several image-centric tools that augment
% the standard Figure-window tools. If the figure menubar is active,
% no duplicate tools (zoom, pan) will be included in the imageToolbar.
% Includes icons to call useful image-centric apps; automatically
% activates impixelinfo; indicates which axes is current.
%
% TSHANDLES = IMAGETOOLBAR(FIGURETOENHANCE)
%
% INPUT:
%   figureToEnhance: The handle to any object in the figure you want to
%      enhance.(Optional; if not provided, it will use the output of
%      |imgcf|; a new figure will be created if imgcf returns empty.)
%
% OUTPUT:
%   tsHandles: A structure containing the handles of all added uicontrols,
%              pushtools, toggletools.
%
% % EXAMPLES:
% % Example 1: Create a figure, add an imageToolbar
% f = figure;
% imshow('peppers.png');
% title('Peppers');
% imageToolbar(f)
%
% % Example 2: Create a figure without a toolbar, then add an imageToolbar;
% %            Also, return a structure of handles.
% f = figure('toolbar','none');
% imshow('peppers.png');
% title('Peppers');
% hndls = imageToolbar(f);
%
% % Example 3: ImageToolbar on a figure with multiple image-containing
% %            axes:
% img1 = imread('cameraman.tif');
% img2 = imread('peppers.png');
% subplot(1,2,1);
% imshow(img1);
% title('Image 1');
% subplot(1,2,2);
% imshow(img2);
% title('Image 2');
% imageToolbar

%
% Brett Shoelson, PhD
% brett.shoelson@mathworks.com
% 05/16/2016
%
% See also: makeUI

% Copyright 2016 The MathWorks, Inc.

narginchk(0,1)
if nargin == 0
	figureToEnhance = imgcf;
	figure(figureToEnhance);
end

if ~ishandle(figureToEnhance)
	error('imageToolbar: Please provide the handle to a figure or image-containing axes.');
end

% Allow specification of any handle in the figure to be enhanced:
figureToEnhance = ancestor(figureToEnhance,'figure');
hasFigureToolbar = ~strcmp(figureToEnhance.ToolBar,'none');
hasImageToolbar = ~isempty(findall(figureToEnhance,...
	'tag','AutogeneratedImageToolbar'));

% Disallow duplicate toolstrips:
if hasImageToolbar
	beep
	disp('imageToolbar: This figure already contains an image toolstrip.')
	if nargout
		tsHandles = [];
	end
	return
end

% Create arrays of allImagesThisFigure, allAxesThisFigure
allImagesThisFigure = [];
allImageAxesThisFigure = [];
refreshAxesImages;

% Setup
IPTIconPath = fullfile(matlabroot,'toolbox','images','icons');
MATLABIconPath = fullfile(matlabroot,'toolbox','matlab','icons');
tbc = 240/255; %toolbar color, approximately
pushtoolIndex = 0;
toggletoolIndex = 0;

% UITOOLBAR
tsHandles.uitoolbars = uitoolbar(figureToEnhance,...
	'tag','AutogeneratedImageToolbar');
% ACKNOWLEDGEMENTS
[icon,map] = imread(fullfile(MATLABIconPath,'matlabicon.gif'));
icon = conditionIcon(icon,map,1,1);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'clickedCallback', @acknowledge,...
	'Tooltipstring', 'Acknowledgements');
% IMAGE INFO
icon = imread(fullfile(IPTIconPath,'icon_info.png'));
icon = conditionIcon(icon,[],2,0);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','INFO',...
	'clickedCallback', @getImageInfo,...
	'Tooltipstring', 'Show image metadata in Command Window');
% FILE OPEN/LOAD
icon = imread(fullfile(MATLABIconPath,'file_open.png'));
icon = conditionIcon(icon,[],2,0);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','loadImageTool',...
	'clickedCallback', @GetNewFile,...
	'Tooltipstring', 'Load new image into current axes');
% TOOLTIP SUPPRESSION
toggletoolIndex = toggletoolIndex + 1;
icon = imread('tooltipIcon2.png');
icon = conditionIcon(icon,[],2,1);
tsHandles.uitoggletools(toggletoolIndex) = uitoggletool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','toggleTooltips',...
	'clickedCallback', {@toggleTooltips,figureToEnhance},...
	'Tooltipstring', 'Toggle tooltips on or off');
% ZOOM/PAN (As Necessary)
if ~hasFigureToolbar
	% Create zoom object
	zoomObj = zoom(figureToEnhance);
	% ZOOM IN
	icon = imread(fullfile(MATLABIconPath,'tool_zoom_in.png'));
	icon = conditionIcon(icon,[],2,0);
	toggletoolIndex = toggletoolIndex + 1;
	tsHandles.uitoggletools(toggletoolIndex) = uitoggletool(tsHandles.uitoolbars,...
		'CData', icon,...
		'tag','zoomIn',...
		'clickedCallback', {@zoomFig,zoomObj,'in'},...
		'Tooltipstring', 'Zoom in',...
		'separator', 'on');
	% ZOOM OUT
	icon = imread(fullfile(MATLABIconPath,'tool_zoom_out.png'));
	icon = conditionIcon(icon,[],2,0);
	toggletoolIndex = toggletoolIndex + 1;
	tsHandles.uitoggletools(toggletoolIndex) = uitoggletool(tsHandles.uitoolbars,...
		'CData', icon,...
		'tag','zoomOut',...
		'clickedCallback', {@zoomFig,zoomObj,'out'},...
		'Tooltipstring', 'Zoom out');
	% PAN
	[icon,map] = imread(fullfile(IPTIconPath,'tool_hand.png'));
	icon = conditionIcon(icon,map,1,[]);
	toggletoolIndex = toggletoolIndex + 1;
	tsHandles.uitoggletools(toggletoolIndex) = uitoggletool(tsHandles.uitoolbars,...
		'CData', icon,...
		'ClickedCallback', 'pan',...
		'tooltipstring', 'Toggle panning');
end %ZOOM/PAN

% IMDISTLINE (Add/Remove)
% Add
[icon,map] = imread(fullfile(IPTIconPath,'distance_tool.gif'));
icon = conditionIcon(icon,map,1,[]);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon, ...
	'clickedCallback', 'imdistline(imgca);',...
	'Tooltipstring', 'Add IMDISTLINE Tool',...
	'separator', 'on');
% Remove
icon = imcomplement(icon);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon, ...
	'clickedCallback', 'delete(findall(ancestor(gcbo,''figure''),''tag'',''imline''))',...
	'Tooltipstring', 'Clear IMDISTLINE Tool(s)');

% MARKPOINTS (Add/Remove)
% Add
icon = ones(11);
icon([1:3, 9:13, 21:23, 33, 89, 99:101, 109:113, 119:121]) = 0;
icon(6, :) = 0;icon(:, 6) = 0;
icon2 = label2rgb(icon, tbc*ones(3), [0 0 1]);
icon2 = imresize(icon2,16/11,'nearest');
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon2, ...
	'clickedCallback',@callMarkImagePoints,...
	'Tooltipstring', 'Manually count objects');
% Remove
icon2 = label2rgb(~icon, tbc*ones(3), [0 0 1]);
icon2 = imresize(icon2,16/11,'nearest');
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon2, ...
	'clickedCallback', 'delete(findall(ancestor(gcbo,''figure''),''tag'',''impoint''))',...
	'Tooltipstring', 'Clear counting marks');

% IMTOOL MODULES
% impixelregion
icon = imread(fullfile(IPTIconPath,'pixel_region.png'));
icon = conditionIcon(icon,[],2,0);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','impixelregiontool',...
	'clickedCallback', 'impixelregion(imgca)',...
	'Tooltipstring', 'impixelregion tool');

%%% UITOOLS
% Crop
icon = im2double(imread(fullfile(IPTIconPath,'crop_tool.png')));
icon = conditionIcon(icon,[],2,0);
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','Freehand Region',...
	'separator', 'on',...
	'clickedCallback', @cropImage,...
	'Tooltipstring', 'Crop Image');
% Rotate Left
icon = imread('RotateL_small.png');
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'clickedCallback', {@rotateImage,+90},...
	'tooltipstring', 'Rotate Left',...
	'separator', 'on');
% Rotate Right
icon = imread('RotateR_small.png');
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'clickedCallback', {@rotateImage,-90},...
	'tooltipstring', 'Rotate Right');
% APPS
% imageSegmenter
icon = im2double(imread(fullfile(IPTIconPath,'imageSegmenter_AppIcon_16.png')));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','ImageSegmenter',...
	'separator', 'on',...
	'clickedCallback', @callImageSegmenter,...
	'Tooltipstring', 'Call imageSegmenter');
% segmentImage (BDS)
icon = im2double(imread(fullfile(IPTIconPath,'Refine_24px.png')));
icon = max(0,min(1,imresize(icon,16/size(icon,1),'nearest')));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','segmentImage',...
	'clickedCallback', @callSegmentImage,...
	'Tooltipstring', 'Call segmentImage');
% colorThresholder
icon = im2double(imread(fullfile(IPTIconPath,'color_thresholder_16.png')));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','ImageSegmenter',...
	'clickedCallback', @callColorThresholder,...
	'Tooltipstring', 'Call colorThresholder');
% imageMorphology (BDS)
icon = im2double(imread(fullfile(IPTIconPath,'Morphology_24.png')));
icon = max(0,min(1,imresize(icon,16/size(icon,1),'nearest')));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','ImageMorphology',...
	'clickedCallback', @callImageMorphology,...
	'Tooltipstring', 'Call imageMorphology');
% imageRegionAnalyzer
icon = im2double(imread(fullfile(IPTIconPath,'ImageRegionAnalyzer_AppIcon_16px.png')));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','ImageRegionAnalyzer',...
	'clickedCallback', @callImageRegionAnalyzer,...
	'Tooltipstring', 'Call imageRegionAnalyzer');
% circleFinder
icon = imread(fullfile(IPTIconPath,'STRELDISK_24.png'));
icon = imresize(icon,16/size(icon,1));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','circleFinder',...
	'clickedCallback', @callCircleFinder,...
	'Tooltipstring', 'Call circleFinder');
% imageAdjuster (BDS)
[icon,map] = imread(fullfile(MATLABIconPath,'plotpicker-bar.gif'));
icon = conditionIcon(icon,map,1,[],[]);
%icon = imresize(icon,16/size(icon,1));
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','imageAdjuster',...
	'clickedCallback', @callImageAdjuster,...
	'Tooltipstring', 'Call imageAdjuster');
% ExploreRGB (BDS)
icon = im2double(imread(fullfile(IPTIconPath,'NewColorSpace_24px.png')));
icon = max(0,min(1,imresize(icon,16/size(icon,1),'nearest')));
icon(icon==0) = NaN;
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','ExploreRGB',...
	'clickedCallback', @callExploreRGB,...
	'Tooltipstring', 'Call ExploreRGB');
% OTHER
% expandAxes
[icon,map] = imread(fullfile(MATLABIconPath,'pagesicon.gif'));
icon = ind2rgb(icon,map);
icon(icon==1) = NaN;
pushtoolIndex = pushtoolIndex + 1;
tsHandles.uipushtools(pushtoolIndex) = uipushtool(tsHandles.uitoolbars,...
	'CData', icon,...
	'tag','''Expand Axes'' on/off',...
	'separator', 'on',...
	'clickedCallback', @toggleExpandAxes,...
	'Tooltipstring', 'Toggle expandAxes');

if ~isempty(allImagesThisFigure)
	impixelinfo;
end

% % Initialize highlighting of current axes:
currentAxesChanged;
% % Trigger highlighting update on axes change
addlistener(figureToEnhance,...
	'CurrentAxes','PostSet',...
	@(~,~) currentAxesChanged());
% % Clear unwanted output
if ~nargout
	clear('tsHandles');
end

	function acknowledge(varargin)
		message = {'imageToolbar was created in MATLAB�';
			'by Brett Shoelson, PhD';
			'brett.shoelson@mathworks.com';
			'Comments/Suggestions welcome!'};
		disp(char(message))
	end %acknowledge

	function callCircleFinder(varargin)
		if ~hasImage
			return
		end
		if exist('circleFinder.m','file') == 2
			thisImg = getimage(imgca(figureToEnhance));
			circleFinder(thisImg);
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/34365-circle-finder','circleFinder');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %callCircleFinder

	function callColorThresholder(varargin)
		if ~hasImage
			return
		end
		thisImg = getimage(imgca(figureToEnhance));
		if size(thisImg,3) == 3 %isrgb
			colorThresholder(thisImg);
		else
			beep
			disp('ColorThresholder operates on color images!')
		end
	end %callColorThresholder

	function callExploreRGB(varargin)
		if ~hasImage
			return
		end
		if exist('exploreRGB.m','file') == 2
			thisImg = getimage(imgca(figureToEnhance));
			if size(thisImg,3) == 3 %isrgb
				ExploreRGB(thisImg);
			else
				beep
				try
					disp('Current image is not RGB; generating RGB image from figure''s colormap.');
					thisImg = ind2rgb(thisImg,get(gcf,'colormap'));
					ExploreRGB(thisImg);
				catch
					disp('Unable to open this image in ExploreRGB; ExploreRGB operates on color (RGB) images!')
				end
			end
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/19706-explorergb','exploreRGB');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %callExploreRGB

	function callImageAdjuster(varargin)
		if ~hasImage
			return
		end
		if exist('ImageAdjuster.m','file') == 2
			thisImg = getimage(imgca(figureToEnhance));
			ImageAdjuster(thisImg);
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/955-imageadjuster','imageAdjuster');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %callImageAdjuster

	function callImageMorphology(varargin)
		if ~hasImage
			return
		end
		if exist('imageMorphology.m','file') == 2
			thisImg = getimage(imgca(figureToEnhance));
			imageMorphology(thisImg);
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/23697-image-morphology','imageMorphology');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %callImageMorphology

	function callImageRegionAnalyzer(varargin)
		if ~hasImage
			return
		end
		thisImg = getimage(imgca(figureToEnhance));
		if islogical(thisImg)
			imageRegionAnalyzer(thisImg);
		else
			beep
			disp('ImageRegionAnalyzer operates on binary images!')
		end
	end %callImageMorphology

	function callImageSegmenter(varargin)
		if ~hasImage
			return
		end
		thisImg = getimage(imgca(figureToEnhance));
		if ~islogical(thisImg)
			imageSegmenter(thisImg);
		else
			beep
			disp('Image is already binary!')
		end
	end %callImageSegmenter

	function callMarkImagePoints(varargin)
		if ~hasImage
			return
		end
		% Shipping markImagePoints with the file; it is significantly
		% different from FEX version ('markPoints')
		%if exist('markImagePoints.m','file') == 2
			markImagePoints(imgca);
		%else
		%	hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/48859-segment-images-interactively--and-generate-matlab-code','segmentImage');
		%	beep;
		%	fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		%end
	end %callMarkImagePoints

	function callSegmentImage(varargin)
		if ~hasImage
			return
		end
		if exist('segmentImage.m','file') == 2
			thisImg = getimage(imgca(figureToEnhance));
			segmentImage(thisImg);
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/48859-segment-images-interactively--and-generate-matlab-code','segmentImage');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %callSegmentImage

	function icon = conditionIcon(icon,map,type,setToNaN,varargin)
		switch type
			case 1
				icon = ind2rgb(icon,map);
			case 2
				icon = im2double(icon);
			case 3
		end
		if ~isempty(setToNaN)
			icon(icon==setToNaN) = NaN;
		end
	end %conditionIcon

	function hyperlnk = createHyperlink(URL,label)
		hyperlnk = ['<a href="matlab: web(''',URL,''')">' label '</a>'];
	end %createHyperlink

	function cropImage(varargin)
		[isGood,thisImgHndl] = hasImage;
		if ~isGood || isempty(thisImgHndl)
			return
		end
		expandedIsOn = isExpanded;
		currTitle = get(get(imgca,'Title'),'String');
		title('Drag to Crop; double-click to finish');
		thisImg = imcrop;%(thisImg);
		% imshow instead of set(...cdata) because imcrop deletes the
		% image handle!
		imshow(thisImg);
		title(currTitle,'interpreter','none');
		currentAxesChanged;
		refreshAxesImages;
		if expandedIsOn
			resetExpandOn
		end
	end %cropImage

	function currentAxesChanged(varargin)
		set(allImageAxesThisFigure,...
			'xcolor',[0 0.75 0],...
			'ycolor',[0 0.75 0],...
			'xtick',[],...
			'ytick',[],...
			'linewidth',2,...
			'visible','off');
		if isempty(get(figureToEnhance,'CurrentAxes'))
			% (This avoids the creation of a new axes if the figure
			% was closed!)
			return
		end
		% Highlight active axes:
		set(imgca,...
			'visible','on')
	end %currentAxesChanged

	function getImageInfo(varargin)
		if ~hasImage
			return
		end
		thisImg = getimage(imgca(figureToEnhance)); %#ok
		whos thisImg;
	end %getImageInfo

	function GetNewFile(varargin)
		[newImg,~,newFname,~,userCanceled] = getNewImage(false);
		if userCanceled
			return
		else
			thisImg = newImg;
			fname = newFname;
		end
		% imshow instead of set(...cdata) because imcrop deletes the
		% image handle!
		expandedIsOn = isExpanded;
		imshow(thisImg);
		title(fname,'interpreter','none');
		refreshAxesImages;
		if expandedIsOn
			resetExpandOn
		end
		currentAxesChanged;
	end %GetNewFile

	function [tf,thisImgHndl] = hasImage(varargin)
		tf = ~isempty(imhandles(gcf));
		if ~tf
			disp('Please display an image in the active figure to use this option.')
			thisImgHndl = [];
			return
		end
		thisImgHndl = imhandles(imgca(figureToEnhance));
		if numel(thisImgHndl) > 1
			beep;
			disp('Ambiguous Command: Image axis contains multiple images');
		end
	end %hasImage

	function tf = isExpanded(varargin)
		tmp = get(allImageAxesThisFigure(1),...
			'ButtonDownFcn');
		tf = ~isempty(tmp) && ...
			all([numel(tmp)==3,...
			isstruct(tmp{2}),...
			isfield(tmp{2},'oldfig')]);
	end %isExpanded

	function refreshAxesImages(varargin)
		allImagesThisFigure = imhandles(figureToEnhance);
		allImageAxesThisFigure = get(allImagesThisFigure,'parent');
		if iscell(allImageAxesThisFigure)
			allImageAxesThisFigure = [allImageAxesThisFigure{:}];
		elseif isempty(allImageAxesThisFigure)
			imshow('coins.png');
			title('coins.png');
			allImageAxesThisFigure = imgca;
		end
	end %refreshAxesImages

	function resetExpandOn(varargin)
		%Reset
		set(allImageAxesThisFigure,...
			'ButtonDownFcn','');
		set(allImagesThisFigure,...
			'ButtonDownFcn','');
		toggleExpandAxes;
	end %resetExpandOn

	function rotateImage(varargin)
		[isGood,thisImgHndl] = hasImage;
		if ~isGood || isempty(thisImgHndl)
			return
		end
		expandedIsOn = isExpanded;
		currTitle = get(get(imgca,'Title'),'String');
		thisImg = getimage(imgca(figureToEnhance));
		thisImg = imrotate(thisImg,varargin{3});
		imshow(thisImg);
		title(currTitle,'interpreter','none');
		currentAxesChanged;
		refreshAxesImages;
		if expandedIsOn
			resetExpandOn
		end
	end %rotateImage

	function toggleExpandAxes(varargin)
		if exist('expandAxes.m','file') == 2
			tmp = get(allImageAxesThisFigure(1),...
				'ButtonDownFcn');
			expandedIsOn = ~isempty(tmp) && ...
				all([numel(tmp)==3,...
				isstruct(tmp{2}),...
				isfield(tmp{2},'oldfig')]);
			if expandedIsOn
				set(allImageAxesThisFigure,...
					'ButtonDownFcn','');
				set(allImagesThisFigure,...
					'ButtonDownFcn','');
				disp('expandAxes is OFF!')
			else
				expandAxes(allImageAxesThisFigure);
				disp('expandAxes is ON!')
			end
		else
			hyperlnk = createHyperlink('http://www.mathworks.com/matlabcentral/fileexchange/18291-expandaxes-hndls-rotenable-','expandAxes');
			beep;
			fprintf('NOTE: Requires %s.\nPlease download and install it, and try again!)\n',hyperlnk);
		end
	end %toggleExpandAxes

	function zoomFig(~,~,zoomObject,direction)
		% zoomFig: Control zoom in/out via external buttons
		zoomInButton = findobj(zoomObject.FigureHandle,'tag','zoomIn');
		zoomOutButton = findobj(zoomObject.FigureHandle,'tag','zoomOut');
		set([zoomInButton,zoomOutButton],'state','off')
		if strcmp(zoomObject.Enable,'on') && strcmp(zoomObject.Direction,direction)
			zoomObject.Enable = 'off';
		else
			zoomObject.Direction = direction;
			if strcmp(direction,'in')
				zoomInButton.State = 'on';
			elseif strcmp(direction,'out')
				zoomOutButton.State = 'on';
			end
			zoomObject.Enable = 'on';
		end
	end %zoomFig

end %imageToolbar