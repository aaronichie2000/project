function [segments, fs] = silenceRemove(wavFileName,t)

% Check if the given wav file exists:
% fp = fopen(wavFileName, 'rb');
% if (fp<0)
% 	fprintf('The file %s has not been found!\n', wavFileName);
% 	return;
% end 
% fclose(fp);

% Check if .wav extension exists:
% if  (strcmpi(wavFileName(end-3:end),'.wav'))
%     % read the wav file name:
      [x,fs] = wavread(wavFileName);
% else
%     fprintf('Unknown file type!\n');
%     return;
% end


% Convert mono to stereo
if (size(x, 2)==2)
	x = mean(x')';
end

% Window length and step (in seconds):
win = 0.050;
step = 0.050;

%--------------------------------------------------------------------%
%  THRESHOLD ESTIMATION
%--------------------------------------------------------------------%

Weight = 5; % used in the threshold estimation method

% Compute short-time energy and spectral centroid of the signal:
Eor = ShortTimeEnergy(x, win*fs, step*fs);
Cor = SpectralCentroid(x, win*fs, step*fs, fs);

%--------------------------------------------------------------------------
% Apply median filtering in the feature sequences (twice), using 5 windows:
% (i.e., 250 mseconds)
%--------------------------------------------------------------------------
E = medfilt1(Eor, 5); E = medfilt1(E, 5);
C = medfilt1(Cor, 5); C = medfilt1(C, 5);

% Get the average values of the smoothed feature sequences:
E_mean = mean(E);
Z_mean = mean(C);

% Find energy threshold:
[HistE, X_E] = hist(E, round(length(E) / 10));  % histogram computation
[MaximaE, countMaximaE] = findMaxima(HistE, 3); % find the local maxima of the histogram
if (size(MaximaE,2)>=2) % if at least two local maxima have been found in the histogram:
    T_E = (Weight*X_E(MaximaE(1,1))+X_E(MaximaE(1,2))) / (Weight+1); % ... then compute the threshold as the weighted average between the two first histogram's local maxima.
else
    T_E = E_mean / 2;
end

% Find spectral centroid threshold:
[HistC, X_C] = hist(C, round(length(C) / 10));
[MaximaC, countMaximaC] = findMaxima(HistC, 3);
if (size(MaximaC,2)>=2)
    T_C = (Weight*X_C(MaximaC(1,1))+X_C(MaximaC(1,2))) / (Weight+1);
else
    T_C = Z_mean / 2;
end

% Thresholding:
Flags1 = (E>=T_E);
Flags2 = (C>=T_C);
flags = Flags1 & Flags2;

if (nargin==2) % plot results:
	clf;
	subplot(3,1,1); plot(Eor, 'g'); hold on; plot(E, 'c'); legend({'Short time energy (original)', 'Short time energy (filtered)'});
    L = line([0 length(E)],[T_E T_E]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);
    axis([0 length(Eor) min(Eor) max(Eor)]);
	
    subplot(3,1,2); plot(Cor, 'g'); hold on; plot(C, 'c'); legend({'Spectral Centroid (original)', 'Spectral Centroid (filtered)'});    
	L = line([0 length(C)],[T_C T_C]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);   
    axis([0 length(Cor) min(Cor) max(Cor)]);
end


%---------------------------------------------------------------------%
%  SPEECH SEGMENTS DETECTION
%---------------------------------------------------------------------%
count = 1;
WIN = 5;
Limits = [];
while (count < length(flags)) % while there are windows to be processed:
	% initilize:
	curX = [];	
	countTemp = 1;
	% while flags=1:
	while ((flags(count)==1) && (count < length(flags)))
		if (countTemp==1) % if this is the first of the current speech segment:
			Limit1 = round((count-WIN)*step*fs)+1; % set start limit:
			if (Limit1<1)	
                Limit1 = 1; 
            end        
		end	
		count = count + 1; 		% increase overall counter
		countTemp = countTemp + 1;	% increase counter of the CURRENT speech segment
	end

	if (countTemp>1) % if at least one segment has been found in the current loop:
		Limit2 = round((count+WIN)*step*fs);			% set end counter
		if (Limit2>length(x))
            Limit2 = length(x);
        end
        
        Limits(end+1, 1) = Limit1;
        Limits(end,   2) = Limit2;
    end
	count = count + 1; % increase overall counter
end

%---------------------------------------------------------------------%
%                       POST - PROCESS      
%---------------------------------------------------------------------%

% A. MERGE OVERLAPPING SEGMENTS:
RUN = 1;
while (RUN==1)
    RUN = 0;
    for (i=1:size(Limits,1)-1)                  % for each segment
        if (Limits(i,2)>=Limits(i+1,1))
            RUN = 1;
            Limits(i,2) = Limits(i+1,2);
            Limits(i+1,:) = [];
            break;
        end
    end
end


% B. Get final segments:
segments = {};
for i=1:size(Limits,1)
    segments{end+1} = x(Limits(i,1):Limits(i,2)); 
end

if (nargin==2) 
    subplot(3,1,3);
    
    % Plot results and play segments:
    time = 0:1/fs:(length(x)-1) / fs;
    for i=1:length(segments)
        hold off;
        P1 = plot(time, x); set(P1, 'Color', [0.7 0.7 0.7]);    
        hold on;
        for j=1:length(segments)
            if (i~=j)
                timeTemp = Limits(j,1)/fs:1/fs:Limits(j,2)/fs;
                P = plot(timeTemp, segments{j});
                set(P, 'Color', [0.4 0.1 0.1]);
            end
        end
        timeTemp = Limits(i,1)/fs:1/fs:Limits(i,2)/fs;
        P = plot(timeTemp, segments{i});
        set(P, 'Color', [0.9 0.0 0.0]);
        axis([0 time(end) min(x) max(x)]);
        sound(segments{i}, fs);
        
        clc;
        fprintf('Playing segment %d of %d. Press any key to continue...', i, length(segments));
        pause
    end
    clc
    hold off;
    P1 = plot(time, x); set(P1, 'Color', [0.7 0.7 0.7]);    
    hold on;    
    for (i=1:length(segments))
        for (j=1:length(segments))
            if (i~=j)
                timeTemp = Limits(j,1)/fs:1/fs:Limits(j,2)/fs;
                P = plot(timeTemp, segments{j});
                set(P, 'Color', [0.4 0.1 0.1]);
            end
        end
        axis([0 time(end) min(x) max(x)]);
    end
end

%-------------------------------------------------------------------------%
%          Calculate the short time energy of the signal
%-------------------------------------------------------------------------%
function E = ShortTimeEnergy(signal, windowLength,step);
signal = signal / max(max(signal));
curPos = 1;
L = length(signal);
numOfFrames = floor((L-windowLength)/step) + 1;
%H = hamming(windowLength);
E = zeros(numOfFrames,1);
for i=1:numOfFrames
    window = (signal(curPos:curPos+windowLength-1));
    E(i) = (1/(windowLength)) * sum(abs(window.^2));
    curPos = curPos + step;
end


%-------------------------------------------------------------------------%
%          Calculate the Spectral centroid of the signal
%-------------------------------------------------------------------------%
function C = SpectralCentroid(signal,windowLength, step, fs)
signal = signal / max(abs(signal));
curPos = 1;
L = length(signal);
numOfFrames = floor((L-windowLength)/step) + 1;
H = hamming(windowLength);
m = ((fs/(2*windowLength))*[1:windowLength])';
C = zeros(numOfFrames,1);
for i=1:numOfFrames
    window = H.*(signal(curPos:curPos+windowLength-1));    
    FFT = (abs(fft(window,2*windowLength)));
    FFT = FFT(1:windowLength);  
    FFT = FFT / max(FFT);
    C(i) = sum(m.*FFT)/sum(FFT);
    if (sum(window.^2)<0.010)
        C(i) = 0.0;
    end
    curPos = curPos + step;
end
C = C / (fs/2);

%--------------------------------------------------------------------------------
% find the maxmumm energy of the signal and use as a threshold through histogram.
%--------------------------------------------------------------------------------
function [Maxima, countMaxima] = findMaxima(f, step)
countMaxima = 0;
for i=1:length(f)-step-1 % for each element of the sequence:
    if (i>step)
        if (( mean(f(i-step:i-1))< f(i)) && ( mean(f(i+1:i+step))< f(i)))  
            % IF the current element is larger than its neighbors (2*step window)
            % --> keep maximum:
            countMaxima = countMaxima + 1;
            Maxima(1,countMaxima) = i;
            Maxima(2,countMaxima) = f(i);
        end
    else
        if (( mean(f(1:i))<= f(i)) && ( mean(f(i+1:i+step))< f(i)))  
            % IF the current element is larger than its neighbors (2*step window)
            % --> keep maximum:
            countMaxima = countMaxima + 1;
            Maxima(1,countMaxima) = i;
            Maxima(2,countMaxima) = f(i);
        end
        
    end
end

%
% STEP 2: post process maxima:
%

MaximaNew = [];
countNewMaxima = 0;
i = 0;
while (i<countMaxima)
    % get current maximum:
    i = i + 1;
    curMaxima = Maxima(1,i);
    curMavVal = Maxima(2,i);
    
    tempMax = Maxima(1,i);
    tempVals = Maxima(2,i);
    
    % search for "neighbourh maxima":
    while ((i<countMaxima) && ( Maxima(1,i+1) - tempMax(end) < step / 2))
        i = i + 1;
        tempMax(end+1) = Maxima(1,i);
        tempVals(end+1) = Maxima(2,i);
    end
    
   
    % find the maximum value and index from the tempVals array:
    %MI = findCentroid(tempMax, tempVals); MM = tempVals(MI);
    
    [MM, MI] = max(tempVals);
        
    if (MM>0.02*mean(f)) % if the current maximum is "large" enough:
        countNewMaxima = countNewMaxima + 1;   % add maxima
        % keep the maximum of all maxima in the region:
        MaximaNew(1,countNewMaxima) = tempMax(MI); 
        MaximaNew(2,countNewMaxima) = f(MaximaNew(1,countNewMaxima));
    end        
    tempMax = [];
    tempVals = [];
end

Maxima = MaximaNew;
countMaxima = countNewMaxima;
