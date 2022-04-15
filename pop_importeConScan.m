function EEG = pop_importeConScan(filename,filepath)
% pop_importeConScan() - loads eConScan .bdf files into EEGLAB
%
% Usage:
%   >> EEG = pop_importeConScan();
%   >> EEG = pop_importeConScan( filename, filepath );
%
% Inputs:
%   filename - [string] one *.bdf file,
%               [cell]  more than one *.bdf files;
%   filepath - [string] file path;
%
% Outputs:
%   EEG      - EEGLAB data structure
%
% Examples:
%   Load one .bdf file:
%     >> filepath = 'C:\eConScan_import1.0\sample_data';
%     >> EEG = pop_importeConScan( 'data.bdf', filepath );
%
%   Load more than one.bdf files:
%     >> filepath = 'C:\eConScan_import1.0\sample_data';
%     >> EEG = pop_importeConScan( {'data.bdf', 'data2.bdf'}, filepath );
%
% Author: Zhaoxu Liu, liuzhaoxuchn@163.com
% github: https://github.com/SeerLikeJazz/eConScan_import.git
%
% This program is free software; you can redistribute it and/or modify it under
% the terms of the GNU General Public License as published by the Free Software
% Foundation; either version 3 of the License, or (at your option) any later
% version.
%
% This program is distributed in the hope that it will be useful, but WITHOUT
% ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
% FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License along with
% this program; if not, see <https://www.gnu.org/licenses/>.



%% Process fileName(s)
if nargin < 1    
    [filename, filepath] = uigetfile('*.bdf', 'Choose a .bdf file -- pop_importeConScan()','MultiSelect', 'on'); 
    drawnow;
    if ~iscell(filename)
        filename = {filename};
    end
    for i = 1:length(filename)
        files{1,i} = fullfile(filepath,filename{1,i});
    end    
elseif  nargin == 1
    disp('wrong input');
else  
    if ~iscell(filename)
        filename = {filename};
    end
    for i = 1:length(filename)
        files{1,i} = fullfile(filepath,filename{1,i});
    end    
end
    
if isempty(filename) 
    disp('no files given');
    return;
end

%% read file header
datafilelength = length(files);
nTrials = 0;
datapnts = zeros(1, datafilelength);
HDR =cell(1,datafilelength);
for i = 1:datafilelength
    hdr = read_bdf(files{1,i});
    nTrials = nTrials + hdr.nTrials;
    datapnts(1,i) = hdr.nSamples;
    HDR{1,i} = hdr;
end
srate = HDR{1,1}.Fs;

%% Process events to store
Event = struct('type',[],'latency',[]);
N = 0;
for j = 1:datafilelength
    hdrEvt = read_bdf(files{1,j});
    evt = hdrEvt.event;
    evt = cell2mat(evt);
    event = struct('type',[],'latency',[]);
    if isstruct(evt)
        for i = 1:size(evt,2)
            event(i).type = evt(i).eventvalue;
            event(i).latency = round(evt(i).offset_in_sec*srate);
        end
    end

    if ~isempty([event(:).latency])
        for k = 1:length(event)
                N = N+1;
                Event(N).type = evt(k).eventvalue;
                if j>1
                Event(N).latency = round(evt(k).offset_in_sec*srate)+sum(datapnts(1:j-1));
                else
                 Event(N).latency = round(evt(k).offset_in_sec*srate);   
                end
        end
    end
    
    if j < datafilelength
        eventBoundary = struct('type','boundary','latency',sum(datapnts(1:j))+1); % relative ending
        N = N+1;
        Event(N) = eventBoundary;
    end   

end
boundaries = findboundaries(Event);
if boundaries(end)> sum(datapnts)
    Event(end) = [];
end

%% organize EEG struct
EEG = eeg_emptyset;
EEG.srate = srate;
EEG.trials = nTrials;
EEG.ref = 'common';
chaninfo.plotrad = [];
chaninfo.shrink = [];
chaninfo.nosedir = '+X';
chaninfo.icachansind = [];
EEG.chaninfo = chaninfo;
patientInfo = strsplit(hdr.orig.PID);
patientName = strtrim(patientInfo{4});
if ~strcmpi(patientName,'X')
    EEG.setname = [EEG.setname ' ' patientName ];     
end

begsample = 1;
endsample = sum(datapnts);
chanidx = 1:hdr.nChans; 

EEG.chanlocs =  hdr.chanlocs(chanidx);
EEG.nbchan = length(chanidx);
EEG.pnts = endsample-begsample+1;
EEG.xmax = EEG.pnts/EEG.srate;
EEG.times = (1:EEG.pnts)*1000/EEG.srate; 

%% save data & event
EEG.event=Event;%event写入
 
if datafilelength == 1
    dat = read_bdf(files{1,1}, HDR{1,1}, begsample, endsample, chanidx);
else
    for k = 1:datafilelength
        disp(['(' num2str(k) '/' num2str(datafilelength) '):' files{1,k}]);
        newbegsample = 1;newendsample = datapnts(k);
        Data{k} = read_bdf(files{1,k},HDR{1,k},newbegsample,newendsample,chanidx);
    end
    dat = cat(2,Data{:});
end 

EEG.data = dat;

%% Verify output
EEG = eeg_checkset(EEG, 'eventconsistency');
EEG = eeg_checkset(EEG, 'makeur'); %EEG.urevent
EEG = eeg_checkset(EEG);


function boundaries = findboundaries(event)
if isfield(event, 'type') & isfield(event, 'latency') & cellfun('isclass', {event.type}, 'char')
    % Boundary event indices
    boundaries = strmatch('boundary', {event.type});
    % Boundary event latencies
    boundaries = [event(boundaries).latency];
    % Shift boundary events to epoch onset
    boundaries = fix(boundaries + 0.5);
    % Remove duplicate boundary events
    boundaries = unique(boundaries);
    % Epoch onset at first sample?
    if isempty(boundaries) || boundaries(1) ~= 1
        boundaries = [1 boundaries];
    end
else
    boundaries = 1;
end


