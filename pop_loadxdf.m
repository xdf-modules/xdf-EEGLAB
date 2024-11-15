% pop_loadxdf() - Load an XDF file (*.xdf or *.xdfz).
%                 (pop out window if no arguments)
%
% Usage:
%   >> [EEG] = pop_loadxdf;
%   >> [EEG] = pop_loadxdf( filename, 'key', 'val', ...);
%
% Graphic interface:
%
%   "Stream name to import" - [edit box] specify name of stream to import; if nonempty, only the 
%                             stream with the given name will be imported (otherwise the stream type
%                             will be used to determine what stream to import)
%                             Command line equivalent in eeg_load_xdf: 'streamname'
%   "Stream type to import" - [edit box] specify content type of stream to import
%                             see http://code.google.com/p/xdf/wiki/MetaData (bottom) for content types
%                             Command line equivalent in eeg_load_xdf: 'streamtype'
%   "Exclude marker stream(s)" - [edit box] specify names of marker streams to skip; this is in 
%                                MATLAB cell array syntax, e.g. {'MyVideoMarkers','SyncStream001'}
%                                Command line equivalent in eeg_load_xdf: 'exclude_markerstreams'
%
% Inputs:
%   filename                   - file name
%
% Optional inputs:
%   'streamname'               - name of stream to import (if omitted, streamtype takes precedence)
%   'streamtype'               - type of stream to import (default: 'EEG')
%   'exclude_markerstreams'    - cell array of marker stream names that should be excluded from import
%   Same as eeg_load_xdf() function.
%
% Outputs:
%   [EEG]                       - EEGLAB data structure
%
% Note:
% This script is based on pop_loadcnt.m to make it compatible and easy to use in
% EEGLab.
%
% Author: Christian Kothe and Arnaud Delorme, Swartz Center for Computational Neuroscience, UCSD, 2012
%
% See also: eeglab(), eeg_load_xdf(), load_xdf()
%

%123456789012345678901234567890123456789012345678901234567890123456789012

% Copyright (C) 2012 Christian Kothe, ckothe@cusd.edu
%
% This program is free software; you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation; either version 2 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program; if not, write to the Free Software
% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA


function [EEG, command]=pop_loadxdf(filename, varargin);

command = '';
filepath = '';
EEG=[];

if nargin < 1

	% ask user
	[filename, filepath] = uigetfile('*.xdf;*.xdfz', 'Choose an XDF file -- pop_loadxdf()');
    drawnow;
	if filename == 0 return; end
    streams = load_xdf(filename);
    allStreamNames = cellfun(@(x)x.info.name, streams, 'UniformOutput',false);
    allStreamTypes = cellfun(@(x)x.info.type, streams, 'UniformOutput',false);
    
    indEEG     = strmatch('eeg', lower(allStreamTypes));
    indMarkers = strmatch('markers', lower(allStreamTypes));
    if isempty(indEEG)
        indType = 1;
    end
    markerOptions = allStreamNames(indMarkers);
    allStreamNames(indMarkers) = [];

    % reformat options
    allStreamNames = [ { 'No selection' } allStreamNames];
    if isempty(markerOptions), 
        markerOptions = 'No maker streams'; 
    else
        markerOptions = [ { 'No selection' } markerOptions ];
    end

	% popup window parameters
	% -----------------------
    uigeom     = { [1 1] [1 1] [1 1] [1 1] 1};
    uilist   = { { 'style' 'text' 'string' 'Primary stream name to import:' } ...
                 { 'style' 'popupmenu' 'string' allStreamNames } ...
                 { 'style' 'text' 'string' 'Or primary stream type to import:' } ...
                 { 'style' 'popupmenu' 'string' allStreamTypes 'value' indEEG } ...
                 { 'style' 'text' 'string' 'Additional streams to merge:' } ...
                 { 'style' 'listbox' 'string' allStreamNames 'value', 1, 'max', 2} ...
                 { 'style' 'text' 'string' 'Exclude marker streams(s):' } ...
                 { 'style' 'listbox' 'string' markerOptions 'value', 1, 'max', 2} ...0
                 { 'style' 'checkbox' 'string' 'Use effective sampling rates computed from time stamps' 'value' 1 } };

    geomvert = [ 1 1 1.8 1.8 1 ];
	result = inputgui('geometry', uigeom, 'uilist', uilist, 'geomvert', geomvert, 'helpcom', 'pophelp(''pop_loadxdf'')', 'title', 'Load an XDF file');
	if isempty( result ) return; end

	% decode parameters
	% -----------------
    options = {};
    if ~isempty(result{1}) && result{1} ~= 1 
        options = [options { 'streamname' allStreamNames{result{1}} } ]; 
    end
    if ~isempty(result{2}) && result{1} == 1
        options = [options { 'streamtype' allStreamTypes{result{2}} } ]; 
    end
    if ~isempty(result{3}) && ~isequal(result{3}, 1) 
        options = [options { 'fuse_stream_names'  allStreamNames( result{3} ) } ]; 
    end
    if ~isempty(result{4}) && ~isequal(result{4}, 1)
        options = [options { 'exclude_markerstreams' markerOptions( result{4} ) } ]; 
    end
    if result{5} == 1
        options = [options { 'effective_rate' true } ]; 
    end
else
    streams = {};
	options = varargin;
end

% load data
% ----------
if exist('filepath','var')
	fullFileName = sprintf('%s%s', filepath, filename);
else
	fullFileName = filename;
end

fprintf('Now importing...');
EEG = eeg_load_xdf( fullFileName, 'streams', streams, options{:});
fprintf('done.\n');

EEG = eeg_checkset(EEG);

if length(options) > 2
    command = sprintf('EEG = pop_loadxdf(''%s'', %s);',fullFileName, vararg2str(options));
else
    command = sprintf('EEG = pop_loadxdf(''%s'');',fullFileName);
end

