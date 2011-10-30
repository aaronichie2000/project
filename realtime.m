function realtime(varargin)
%%
% Error if an output argument is supplied.
if nargout > 0
   error('Too many output arguments.');
end

%%
% Based on the number of input arguments call the appropriate 
% local function.
switch nargin
case 0
   % Create the analog input object.
   data = localInitAI;

   % Create the  figure.
   data = localInitFig(data);
   hFig = data.handle.figure;
   
case 1
   error('The ADAPTORNAME, ID and CHANID must be specified.');
 end

%%
% Update the figure's UserData.
if ~isempty(hFig) && ishghandle(hFig),
   set(hFig,'UserData',data);
end

%%
% Update the analog input object's UserData.
if isvalid(data.ai)
   set(data.ai, 'UserData', data);
end

%% ***********************************************************************   
% Create the object
function data = localInitAI(varargin)

% Initialize variables.
data = [];

%%
% Either no input arguments or all three - ADAPTORNAME, ID and CHANNELID.
switch nargin
case 0
   adaptor = 'winsound';
   id = 0;
   chan = 1;
end
%%
% Channel 2 for sound card is not allowed.
if strcmpi(adaptor, 'winsound') && chan == 2
   warning('daq:demoai_fft:winsoundchan1','Channel 1 must be used for device Winsound.');
   chan = 1;
end

%%
% Object Configuration.
% Create an analog input object with one channel.
ai = analoginput(adaptor, id);
addchannel(ai, chan);

%%
% Configure the analog input object.
set(ai, 'SampleRate', 44100);

timePeriod = 0.1;

%%
% Configure the analog input object to trigger manually twice.
set(ai, 'SamplesPerTrigger', timePeriod*ai.sampleRate);
set(ai, 'TriggerRepeat', 1);
set(ai, 'TriggerType', 'manual');

%%
% Initialize callback parameters.  The TimerAction is initialized 
% after figure has been created.
set(ai, 'TimerPeriod', timePeriod);  
set(ai, 'BufferingConfig',[2048,20]);

%%
% Object Execution.
% Start the analog input object.
start(ai);
trigger(ai);

%%
% Obtain the available time and data.
[d,time] = getdata(ai, ai.SamplesPerTrigger);

%%
% Update the data structure.
data.ai = ai;
data.getdata = [d time];
% data.daqfft = [f mag];
data.handle = [];
%% ***********************************************************************   
% Create the display.
function data = localInitFig(data)

%%
% Initialize variables.
btnColor=get(0,'DefaultUIControlBackgroundColor');

%%
% Position the GUI in the middle of the screen
% screenUnits=get(0,'Units');
% set(0,'Units','pixels');
% screenSize=get(0,'ScreenSize');
% set(0,'Units',screenUnits);
% figWidth=600;
% figHeight=360;
% figPos=[(screenSize(3)-figWidth)/2 (screenSize(4)-figHeight)/2  ...
%       figWidth                    figHeight];

%%
% Create the figure window.
hFig=figure(...                    
   'Color'             ,btnColor                 ,...
   'IntegerHandle'     ,'off'                    ,...
   'DeleteFcn'         ,'demoai_fft(''close'',gcbf)',...
   'MenuBar'           ,'none'                   ,...
   'HandleVisibility'  ,'on'                     ,...
   'NumberTitle'       ,'off'                    ,...
   'Units'             ,'pixels'                 ,...
   'Visible'           ,'off'                     ...
   );

%%
% Create Data subplot.
hAxes(1) = axes(...
   'Position'          , [0.1300 0.5811 0.7750 0.3439],...
   'Parent'            , hFig,...
   'XLim'              , [0 get(data.ai, 'SamplesPerTrigger')],...
   'YLim'              , [-0.5 0.5]...
   );

%%
% Plot the data.
hLine(1) = plot(data.getdata(:,1));
% set(hAxes(1), 'XLim', [0 get(data.ai, 'SamplesPerTrigger')]);

%%
% Label the plot.
xlabel('Sample');
ylabel('Analog Input (Volts)');
title('Analog Data Acquisition');

%%
% Store the handles in the data matrix.
data.handle.figure = hFig;
data.handle.axes = hAxes;
data.handle.line = hLine;
%%
% Set the axes handlevisibility to off.
set(hAxes, 'HandleVisibility', 'off');

%%
% Store the data matrix and display figure.
 set(hFig,'Visible','on','UserData',data,'HandleVisibility', 'off');

%%
% Configure the callback to update the display.
set(data.ai, 'TimerFcn', @localfftShowData);


%% ***********************************************************************  
% Update the plot.
function localfftShowData(obj,~)

%%
% Get the handles.
data = obj.UserData;

hFig = data.handle.figure; %#ok<NASGU>
hAxes = data.handle.axes;
hLine = data.handle.line;

%%
% Execute a peekdata.
x = peekdata(obj, obj.SamplesPerTrigger);


%%
% Dynamically modify Analog axis as we go.
maxX=max(x);
minX=min(x);
yax1=get(hAxes(1),'YLim');
if minX<yax1(1),
   yax1(1)=minX;
end
if maxX>yax1(2),
   yax1(2)=maxX;
end
set(hAxes(1),'YLim',yax1)

%%
% Update the plots.
set(hLine(1), 'YData', x(:,1));
drawnow;
