function mycountdown(mins,secs,endMssg)


if nargin < 2
    secs = 0;
end
secs = secs + rem(mins,1)*60;
mins = floor(mins);

if nargin < 3 || isempty(endMssg)
    endMssg = 'Speak now...';
end

countdownfig = figure('numbertitle','off','name','COUNTDOWN',...
    'color','w','menubar','none','toolbar','none',...
    'closerequestfcn',@cleanup);


edtbox = uicontrol('style','edit','string','STARTING','units','normalized','pos',[0.1 0.75 0.8 0.2],...
    'fontsize',40,'foregroundcolor','r');
timerobj = timer('timerfcn',@updateDisplay,'period',1,'executionmode','fixedrate');
secsElapsed = 0;
start(timerobj);

    function updateDisplay(varargin)
        secsElapsed = secsElapsed + 1;
        if secsElapsed > secs + mins*60
            set(edtbox,'string',endMssg);
%             tmp = get(0,'screensize');
%             set(countdownfig,'pos',[1 40 tmp(3) tmp(4)-80]);
            set(edtbox,'foregroundcolor',1-get(edtbox,'foregroundcolor')); %,'backgroundcolor',1-get(edtbox,'backgroundcolor')
        else
            set(edtbox,'string',...
                datestr([2003  10  24  12  mins  secs-secsElapsed],'MM:SS'));
        end
    end

    function cleanup(varargin)
        stop(timerobj);
        delete(timerobj);
        closereq;
    end
end