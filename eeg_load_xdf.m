% Import an XDF file from disk
% EEG = eeg_load_xdf(Filename, Options...)
%
% In:
%   Filename : name of the xdf file
%
%   Options... : list of name-value pairs for further options; the allowed names are as follows:
%                'streamname' : import only the first stream with the given name
%                               if specified, takes precedence over the streamtype argument
%
%                'streamtype' : import only the first stream with the given content type
%                                (default: 'EEG')
%
%                'effective_rate' : if true, use the effective sampling rate instead of the nominal
%                                   sampling rate (as declared by the device) (default: false)
%
%                'exclude_markerstreams' : can be a cell array of stream names to exclude from
%                                          use as marker streams (default: {})
%
% Out:
%   EEG              : imported EEGLAB data set
%   streams          : all XDF streams
%   EEGStreamInd     : index of first EEG stream
%   markerStreamInds : indicdes of marker streams
%
% Authors: Christian Kothe and Arnaud Delorme, Swartz Center for Computational Neuroscience, UCSD 2012-05-07

function [raw, streams, EEGStreamInd, markerStreamInds] = eeg_load_xdf(filename, varargin)

% parse arguments
args = finputcheck(varargin, {
    'streamname', 'string', {}, '';
    'streamtype', 'string', {}, 'EEG';
    'streams'   , 'cell'  , {}, {};
    'fuse_stream_names', 'cell', {}, {};
    'effective_rate', 'boolean', {}, false;
    'exclude_markerstreams', 'cell', {}, {}
    });
if ischar(args)
    error(args);
end

% first load the .xdf file
if isempty(args.streams)
    streams = load_xdf(filename);
else
    streams = args.streams;
end

% then pick the first stream that matches the criteria
if ~isempty(args.streamname)
    % select by name
    for s=1:length(streams)
        if isfield(streams{s}.info,'name') && strcmp(streams{s}.info.name,args.streamname)
            % found it
            stream = streams{s};
            break;
        end
    end
    if ~exist('stream','var')
        error(['The data contains no stream with the name "'  args.streamname '".']); end
elseif ~isempty(args.streamtype)
    % select by type
    for s=1:length(streams)
        if isfield(streams{s}.info,'type') && strcmp(streams{s}.info.type,args.streamtype)
            % found it
            stream = streams{s};
            break;
        end
    end
    if ~exist('stream','var')
        error(['The data contains no stream with the type "'  args.streamtype '".']); end
else
    error('You need to pass either the streamname or the streamtype argument.');
end
EEGStreamInd = s;

raw = eeg_import_sub(stream, args);
[raw.filepath,fname,fext] = fileparts(filename);
raw.filename = [fname fext];

% merge streams
% -------------
if ~isempty(args.fuse_stream_names)
    % select by name
    allStreamNames = cellfun(@(x)x.info.name, streams, 'UniformOutput',false);
    for s=1:length(args.fuse_stream_names)
        indStream = strmatch(args.fuse_stream_names{s}, allStreamNames, 'exact');
        if isempty(indStream)
            error('Cannot find stream named "%s"', args.fuse_stream_names{s})
        end
        raw2 = eeg_import_sub(streams{indStream}, args);
        fprintf('Merging stream "%s"\n', args.fuse_stream_names{s});

        % Ensure the two streams have the same timestamps
        % Interpolate data2 to match timestamps1
        clear data2_interpolated;
        raw2_interpolated = zeros(length(raw.timestamps), size(raw2.data, 1));
        for c = 1:size(raw2.data, 1)
            data2_interpolated(:, c) = interp1(raw2.timestamps, double(raw2.data(c, :)), raw.timestamps, 'linear');
        end
        raw.data = [ raw.data; data2_interpolated' ];

        % merge channels
        % --------------
        if ~isempty(raw.chanlocs) || ~isempty(raw2.chanlocs)
            if isempty(raw.chanlocs) || isempty(fieldnames(raw.chanlocs))
                for iChan = 1:raw.nbchan
                    raw.chanlocs(iChan).labels = [ 'E' num2str(iChan) ];
                end
            end
            if isempty(raw2.chanlocs)
                for iChan = 1:raw2.nbchan
                    raw.chanlocs(iChan+raw1.nbchan).labels = [ 'E' num2str(iChan+raw1.nbchan) ];
                end
            end
            fields = fieldnames(raw2.chanlocs);
            for iChan = 1:length(raw2.chanlocs)
                for iField = 1:length(fields)
                    raw.chanlocs(raw.nbchan+iChan).(fields{iField}) = raw2.chanlocs(iChan).(fields{iField});
                end
            end
        end
        raw.nbchan = size(raw.data,1);
        
    end
end
raw.event = []; % remove LSL synchronisation events
raw = rmfield(raw, 'timestamps');

% events...
event = [];
markerStreamInds = [];
for s=1:length(streams)
    if (strcmp(streams{s}.info.type,'Markers') || strcmp(streams{s}.info.type,'Events')) && ~ismember(streams{s}.info.name,args.exclude_markerstreams)
        try
            s_events = struct('type', '', 'latency', [], 'duration', num2cell(ones(1, length(streams{s}.time_stamps))));
            for e=1:length(streams{s}.time_stamps)
                if iscell(streams{s}.time_series)
                    s_events(e).type = streams{s}.time_series{e};
                else
                    s_events(e).type = num2str(streams{s}.time_series(e));
                end
                [~, s_events(e).latency] = min(abs(stream.time_stamps - streams{s}.time_stamps(e)));
            end
            event = [event, s_events]; %#ok<AGROW>
            markerStreamInds = [markerStreamInds s];
        catch err
            disp(['Could not interpret event stream named "' streams{s}.info.name '": ' err.message]);
        end
    end
end
raw.event = event;

% etc...
raw.etc.desc = stream.info.desc;
raw.etc.info = rmfield(stream.info,'desc');

% ----------
% import EEG
% ----------
function raw = eeg_import_sub(stream, args)
raw = eeg_emptyset;
raw.data = stream.time_series;
raw.timestamps = stream.time_stamps;
[raw.nbchan,raw.pnts,raw.trials] = size(raw.data);
if args.effective_rate && isfield(stream.info, 'effective_srate') && ...
        isfinite(stream.info.effective_srate) && stream.info.effective_srate>0
    raw.srate = stream.info.effective_srate;
else
    raw.srate = str2num(stream.info.nominal_srate); %#ok<ST2NM>
end
raw.xmin = 0;
raw.xmax = (raw.pnts-1)/raw.srate;

if ~isempty(args.fuse_stream_names)
    % import ping times as events
    initialTime = str2double(stream.info.first_timestamp)*raw.srate;
    latencies = cellfun(@(x)str2double(x.time)*raw.srate - initialTime, stream.info.clock_offsets.offset, 'UniformOutput',false);
    raw.event = struct('type', 'sync', 'latency', latencies);
    raw.event(end) = []; % often out of bounds
end

% chanlocs...
chanlocs = struct();
try
    if ~iscell(stream.info.desc.channels.channel)
        warning('Channel structure not a cell array (likely a g.tek writer compatibility issue; Using hack to import channel info)');
    end
    for c=1:length(stream.info.desc.channels.channel)
        if iscell(stream.info.desc.channels.channel)
            chn = stream.info.desc.channels.channel{c};
        else
            chn = stream.info.desc.channels.channel(c);
        end
        if isfield(chn,'label')
            chanlocs(c).labels = chn.label; end
        if isfield(chn,'type') && strcmpi(chn.type, 'EEG')
            chanlocs(c).type = chn.type;
        end
        try
            chanlocs(c).X = str2double(chn.location.X)/1000;
            chanlocs(c).Y = str2double(chn.location.Y)/1000;
            chanlocs(c).Z = str2double(chn.location.Z)/1000;
            [chanlocs(c).sph_theta,chanlocs(c).sph_phi,chanlocs(c).sph_radius] = cart2sph(chanlocs(c).X,chanlocs(c).Y,chanlocs(c).Z);
            [chanlocs(c).theta,chanlocs(c).radius] = cart2pol(chanlocs(c).X,chanlocs(c).Y);
        catch
            [chanlocs(c).X,chanlocs(c).Y,chanlocs(c).Z,chanlocs(c).sph_theta,chanlocs(c).sph_phi,chanlocs(c).sph_radius,chanlocs(c).theta,chanlocs(c).radius] = deal([]);
        end
        chanlocs(c).urchan = c;
        chanlocs(c).ref = '';
    end
    raw.chaninfo.nosedir = '+Y';
    if length(chanlocs) > size(raw.data,1) && isfield(chanlocs, 'type')
        types = { chanlocs.type };
        types = cellfun(@num2str, types, 'uniformoutput', false);
        inds = strmatch(lower(args.streamtype), lower(types), 'exact');
        if ~isempty(inds)
            chanlocs = chanlocs(inds);
        else
            inds = strmatch('eeg', lower(types), 'exact');
            if ~isempty(inds)
                chanlocs = chanlocs(inds);
            end
        end
    end
catch e
    disp(['Could not import chanlocs: ' e.message]);
end
raw.chanlocs = chanlocs;

try
    raw.chaninfo.labelscheme = stream.info.desc.cap.labelscheme;
catch
end
