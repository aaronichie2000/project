%--------------------------------------------------------------------------
%         WRITTEN BY AARON NICHIE AS PART OF FINAL YEAR PROJECT
%--------------------------------------------------------------------------
%%
function varargout = Voice_Recognition_Interface(varargin)
global signal RECT s_plot   %global variable to hold voice data
global recording_duration   %value to be shown text box
global mfcc_file R_fs           %to hold mfcc after processing to keep original
global wav_file
global filt_signal
%VOICE_RECOGNITION_INTERFACE M-file for Voice_Recognition_Interface.fig
%      VOICE_RECOGNITION_INTERFACE, by itself, creates a new VOICE_RECOGNITION_INTERFACE or raises the existing
%      singleton*.
%
%      H = VOICE_RECOGNITION_INTERFACE returns the handle to a new VOICE_RECOGNITION_INTERFACE or the handle to
%      the existing singleton*.
%
%      VOICE_RECOGNITION_INTERFACE('Property','Value',...) creates a new VOICE_RECOGNITION_INTERFACE using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to Voice_Recognition_Interface_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      VOICE_RECOGNITION_INTERFACE('CALLBACK') and VOICE_RECOGNITION_INTERFACE('CALLBACK',hObject,...) call the
%      local function named CALLBACK in VOICE_RECOGNITION_INTERFACE.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Voice_Recognition_Interface

% Last Modified by GUIDE v2.5 03-Nov-2011 11:33:21

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Voice_Recognition_Interface_OpeningFcn, ...
                   'gui_OutputFcn',  @Voice_Recognition_Interface_OutputFcn, ...
                   'gui_LayoutFcn',  [], ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
   gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

end
% End initialization code - DO NOT EDIT

%%
% --- Executes just before Voice_Recognition_Interface is made visible.
function Voice_Recognition_Interface_OpeningFcn(hObject, eventdata, handles, varargin)
global recording_duration

recording_duration=1;
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for Voice_Recognition_Interface
handles.output = hObject;

%(1)-----------------------------------------------
handles.adaptor = 'winsound';
handles.id      = 0;
handles.chan    = 1;

handles.samplesPerTrigger = 1024;
handles.sampleRate = 44100;
handles.numTraces = 10;   % number of traces to show in the waterfall.
handles.cycleTime = .9;   % Proportional to the amount of time spent per
                          %  visualization on CycleAll setting.
                          
                          
axes(handles.realtimeaxis);
handles.hLine1 = plot(zeros(1,handles.samplesPerTrigger)'); 
set(handles.hLine1,'Color', [.1 .1 0.5]);
set(handles.realtimeaxis,'Color',[235/255 255/255 235/255])
set(handles.realtimeaxis,'XGrid','on','YGrid','on');
t=title('Time Domain Signal','Color',[.05 .05 .25],'FontWeight','Bold','FontSize',9);
xlabel('Time (s)','FontSize',8);
ylabel('Voltage (V)','FontSize',8);

ai=localSetupAI(handles);
handles.ai = ai;
%---------------------------------------------------------------------
% Update handles structure
guidata(hObject, handles);

%(2)--------------------------------------------------------------------
localStartAI(ai);
%------------------------------------------------------
end

% UIWAIT makes Voice_Recognition_Interface wait for user response (see UIRESUME)
% uiwait(handles.figure1);

%%
%(3)---------------------------
function localStartAI(ai)
start(ai);
trigger(ai);
end

%-------------------------------
%%
%(4)-------------------------------------------------------------------------------------------
function ai=localSetupAI(handles)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% ++++ S E T U P   T H E   A N A L O G   I N P U T ++++
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Object Configuration.
% Create an analog input object with one channel.
ai = analoginput(handles.adaptor, handles.id);
addchannel(ai, handles.chan);

% Configure the callback to update the display.
set(ai, 'TimerFcn', @localfftShowData);

% Configure the analog input object.
set(ai, 'SampleRate', handles.sampleRate);
set(ai, 'SamplesPerTrigger', handles.samplesPerTrigger);
set(ai, 'TriggerRepeat', 1);
set(ai, 'TriggerType', 'manual');

% Initialize callback parameters.  The TimerAction is initialized 
% after figure has been created.
set(ai, 'TimerPeriod', 0.01);  
set(ai, 'BufferingConfig',[handles.samplesPerTrigger*2,20]);

% Initialize time and frequency plots with lines of y=0

d=zeros(1,handles.samplesPerTrigger);
time = 1:handles.samplesPerTrigger;
f=1:handles.samplesPerTrigger/2;
mag=zeros(1,handles.samplesPerTrigger/2);

% Store state information in the analog input objects UserData area.
data.storedFFTsIndex = 1;
data.plotSurf        = 0;
data.ai              = ai;
data.getdata         = [d time];
data.handle          = [];
data.figureHandles   = handles;
data.view            = [103 10];
data.rotateStep      = 4;
data.counter         = 0;

% Set the object's UserData to data.
set(data.ai, 'UserData', data);
end
%--------------------------------------------------------------------------------------------------------------
%%
% --- Outputs from this function are returned to the command line.
function varargout = Voice_Recognition_Interface_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

set(handles.textstatus,'string','WELCOME')

set(gcf,'CloseRequestFcn',@interface_closefcn)
% set(gcbf,'DeleteFcn',@delete_fcn)
end

function interface_closefcn(src,evnt)
selection = questdlg('Want to QUIT??','Confirmation',...
      'Yes','No','Yes'); 
   switch selection, 
      case 'Yes',
%          save('');    to be implemented to save b4 close interface
         delete(gcf)
      case 'No'
      return 
   end
end

% function delete_fcn(obj,event)
% interfaceHandle=Voice_Recognition_Interface;
% handles=guidata(interfaceHandle);
% localStopAI(handles.ai);
% end

%%
%-----------------------------------------------------------------%
%---         use slider to set maximum recording time             %
%-----------------------------------------------------------------%
% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
%global sliderVal
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider
sliderVal=get(hObject,'Value');
sliderDis_to_box=['Recording set to ' num2str(sliderVal) ' (sec)'];
                                                                                        %forsamp=num2str(sliderVal);
set(handles.sliderIndicator,'string',sliderDis_to_box)
                                                                                        %set(handles.textstatus,'string',forsamp)
end

% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
set(hObject,'Min',1,'Max',6)
set(hObject,'Value',2)

end

%%
%------------------------  get data from mic ----------------------
% --- Executes on button press in record_button.
function record_button_Callback(hObject, eventdata, handles)
global signal R_fs                                                                                     %R_samp_len=str2num(get(handles.textstatus,'string'));
global filt_signal
R_fs=16000;             % may consider globalizing 
R_samp_len=get(handles.slider1,'Value');
% hObject    handle to record_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
try
    ai=init_sound(R_fs,R_samp_len);
    R_fs = get(ai, 'SampleRate'); % to ensure cases that actual rate might not match desired
catch
    msgbox('no microphone detected','Microphone','error')
    return                          % terminate where there is no mic
end

nogo=0;         % logic to control loop

while not(nogo)
%------------------------------------------------
% countdown initialization function handles nested down 
%------------------------------------------------
secs = 5;
mins=0;
secs = secs + rem(mins,1)*60;
mins = floor(mins);

endMssg = 'Speak now...';
timerobj = timer('timerfcn',@updateDisplay,'period',1,'executionmode','fixedrate');
secsElapsed = 0;
start(timerobj);
%------------------------------------------------
 
      
   
    pause(5);    % wait for 5 sec for user
    set(handles.textstatus,'string','Speak now...');
    start(ai);
    try
        
        data =getdata(ai);
        nogo=1;
    catch
        set(handles.textstatus,'string','try again');
        disp('Time elapsed... Try again')
        stop(ai);
        stop(timerobj);
    end
end

delete(ai)
stop(timerobj);
delete(timerobj);


%-------------------  normalize data to 99% of max  -----------------

signal = 0.99*data/max(abs(data));
%z_data = data;              % make a copy of data for later usage


[segments R_fs]=silenceRemove(data);   %----- remove silence --and segments--signal-------%
signal=segments{1};                    %----- pick first segment----%
filt_signal=noise_filter(signal);      %----- filter the voice segment -%
feature=melcepst(filt_signal,R_fs);

set(handles.textstatus,'String','Done')

%---------- time object deleted --------------------------- 
% stop(timerobj);
% delete(timerobj);
% ----------------------------------
% enabling the play button 
set(handles.play_button,'enable','on');

% enabling save button
set(handles.save_button,'enable','on');

%-----------------------------------------------
%  time domain display
%-----------------------------------------------
axes(handles.time_domain_plot)
sig_plot

guidata(hObject, handles);                           %update handles
                        

%--------------------------------------
% frequency domain display
%---------------------------------------
% fft_pts=2048;                                     % num of fourier points
% %spec = 'wideband'
% spec = 'narrowband';                             %----------------------
% wideband_time = 4e-3;                            % consider to globalize
% narrowband_time = 25e-3;                         %----------------------
%     % Sampling rate dependent on window width 
% if strcmp(spec,'narrowband')
%     window_width=round(R_fs*narrowband_time);
%     step_size=round(window_width/8);
% elseif strcmp(spec,'wideband')
%     window_width = round(R_fs*wideband_time);
%     step_size = round(window_width/2);
% end
%      %------- calculate the spectrum --------------
% X = specgram(signal,fft_pts,1,hamming(window_width),window_width-step_size);
% X=abs(X);
% 
% y_len = size(X,1);  % for num of rows       %----------------------
% f = (0:y_len-1)*R_fs/y_len/2;                 % frequency axis vector
% f=f/1000;        % converting freq to kHz   %----------------------
% 
% x_len = size(X,2);  %for num of columns    
% t = ((window_width-1)/2:step_size:(x_len-1)*step_size+(window_width-1)/2)/R_fs;
%                 %------ display on GUI --------
% log_data=-log10(X+0.0001);
% axes(handles.frequency_domain_plot)
% plot(t,X);
% title('Spectral Distribution of Voice signal');
% xlabel('Frequency (Hz)');
% ylabel('Amplitude');
% guidata(hObject, handles);                   %updates the handles
% set(gca,'YDir','normal')

 %---------------------------display in image ------------------
% figure
% imagesc(t,f,log_data), xlabel('Distribution'), ylabel('Distribution');


guidata(hObject, handles);

%-----------------------------------------------------------
%handles for the time implemented here bcos of nesting error
%-----------------------------------------------------------

  function updateDisplay(varargin)
        secsElapsed = secsElapsed + 1;
        if secsElapsed > secs + mins*60
            set(handles.textstatus,'string',endMssg);
            set(handles.textstatus,'foregroundcolor',1-get(handles.textstatus,'foregroundcolor')); %,'backgroundcolor',1-get(edtbox,'backgroundcolor')
        else
            set(handles.textstatus,'string',...
                datestr([2003  10  24  12  mins  secs-secsElapsed],'MM:SS'));
        end
  end

end
%%
%---------------------------- RECORDING SUBFUNCTION ---------------------------
% It initializes mic input for the voice fs=sampling rate samp_len= time to
% record in seconds
function ai = init_sound(fs,samp_len)
v = ver;        %matlab and simulink version
name = {v.Name};  %name of version toolbox
ind = find(strcmp(name,'MATLAB'));
if isempty(ind)
	ind = find(strcmp(name,'MATLAB Toolbox'));
end

v_num = str2num(v(ind).Version);

ai = analoginput('winsound');
addchannel(ai, 1);
if (v_num == 6.1) | (v_num == 6.5)
	set(ai, 'StandardSampleRates', 'Off');
end
set(ai, 'SampleRate', fs);
actual_fs = get(ai, 'SampleRate');
set(ai, 'TriggerType', 'software');
set(ai, 'TriggerRepeat', 0);                
set(ai, 'TriggerCondition', 'Rising'); 
set(ai, 'TriggerConditionValue', 0.01);
set(ai, 'TriggerChannel', ai.Channel(1)); 
set(ai, 'TriggerDelay', -0.1);
set(ai, 'TriggerDelayUnits', 'seconds');
set(ai, 'SamplesPerTrigger', actual_fs*samp_len+1);
set(ai, 'TimeOut', 10);
%--------------------------------------------------------------------
end
%%
%--------------------------------------------------------------------

% --- Executes on button press in play_button.
function play_button_Callback(hObject, eventdata, handles)
global signal
global R_fs
% hObject    handle to play_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if ~isempty(signal)                   % if error try use length(signal) ~=0
    sound(signal,R_fs)
end
set(handles.textstatus,'String','Now playing')
% --- Executes on button press in load_button.
end
%---------------------------------------------------------------------
%%
function load_button_Callback(hObject, eventdata, handles)
global signal
global wav_file R_fs
global filt_signal
% hObject    handle to load_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[filename, pathname] = uigetfile('*.wav','select wav file');
  if filename== 0
        errordlg('ERROR! Select a file !!!');
        return;
  elseif ~strcmpi(filename(end-3:end),'.wav')
      errordlg('ERROR: Bad file format. must be .wav');
      return;
  end
  
  wav_file = [pathname filename];
  if ~exist('wav_file')                           %check for file existence
      errordlg('ERROR! File not found...');
      help pw;
      return;
  end
signal = wavread(wav_file);                    %replaced with the nxt line so that signal can pass through the noise remove function
[segments R_fs]=silenceRemove(signal);        %remove silence % assign segments
signal=segments{1};
filt_signal=noise_filter(signal);
set(handles.textstatus,'string',wav_file,'FontSize',16);
axes(handles.time_domain_plot)
sig_plot;
set(handles.play_button,'enable','on')
set(handles.save_button,'enable','on')
guidata(hObject, handles);
end
%---------------------------------------------------------------------
%%
% --- Executes on button press in save_button.
function save_button_Callback(hObject, eventdata, handles)
global R_fs
% hObject    handle to save_button (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global signal
[filename,pathname] = uiputfile('*.wav','save data in wav form');
if filename ~=0
    wavwrite(signal,R_fs,[pathname filename])
end
end
%%
%---------------------------------------------------------------------
% functions without callbacks
%---------------------------------------------------------------------
function sig_plot()
global signal
samp_len = length(signal)/16000;
delta_t = 1/16000;
t=0:delta_t:(samp_len-delta_t);
plot(t,signal);
title('time domain display of voice sampled at FS=16000')
xlabel('time (sec)');
ylabel('Amplitude');
end
%--------------------------------------------------------------------
%--------------------------------------------------------------------
%(5)
function localfftShowData(obj,event)

if (get(obj,'SamplesAvailable') >= obj.SamplesPerTrigger)
	
	% Get the handles.
	data = obj.UserData;
	
	handles = data.figureHandles;
    
	% Execute a peekdata.
	x = peekdata(obj, obj.SamplesPerTrigger);
    
    
	% Dynamically modify Analog axis as we go.
	maxX=max(x);
	minX=min(x);
   
	yax1=get(handles.realtimeaxis,'YLim');
    yax1(1)=minX - 0.1; % need to subtract a value to make sure yax(1) never equals yax(2)
	yax1(2)=maxX + 0.1;
    
%     if minX<yax1(1),
%         yax1(1)=minX;
%     end
%     if maxX>yax1(2),
%         yax1(2)=maxX;
%     end 	
    set(handles.realtimeaxis,'YLim',yax1)
 	set(handles.realtimeaxis,'XLim',[0 (obj.SamplesPerTrigger-1)/obj.SampleRate])
		
	% Update the line plots.
	set(handles.hLine1,'XData', (0:(obj.SamplesPerTrigger-1))/obj.SampleRate, 'YData', x(:,1));
	
	set(data.ai, 'UserData', data);
	drawnow;
end
end


% --- Executes on button press in all_exit.
function all_exit_Callback(hObject, eventdata, handles)
% hObject    handle to all_exit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
localStopai(handles.ai);
closereq;
end

function localStopai(ai)
stop(ai);
delete(ai);
end