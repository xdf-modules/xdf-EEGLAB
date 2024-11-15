% load the file using MATLAB
EEG = eeg_load_xdf('sub-P2222_ses-S001_task-CUNY_face_run-001_mobi.xdf', 'fusestreamnames', {'Tobii'}, 'effective_rate', true);

filePython = 'merged_data.mat';
if ~exist(filePython)
    error('Run the python program first "validate_stream_merging.py" outside of MATLAB')
end
tmp = load('-mat', filePython);
tmp.data = tmp.data';

% plot the results
% eegplot(tmp.data', 'srate', EEG.srate);
% pop_eegplot(EEG)

% check for differences
offset = 201676;
offset = 4106;
offset = 195540;
range = offset-5:offset+5;
fprintf(' ----  %d\n ', offset)
tmp.data(130:135, range)
EEG.data(130:135, range)
EEG.data(130:135, range)-tmp.data(130:135, range)

res = abs((EEG.data(:,1:offset-10)-tmp.data(:,1:offset-10))./EEG.data(:,1:offset-10));
res(isinf(res(:))) = NaN;
% 

% print distance
fprintf('Mean difference is %1.10f %%\n', nanmean(nanmean(res))*100);
fprintf('Max  difference is %1.10f %%\n', nanmax(nanmax(res))*100);

if 0
    % print localized region
    figure;  plot(EEG.data(132,offset-100:offset+100), 'b');
    hold on; plot(tmp.data(132,offset-100:offset+100), 'r');
    
    figure;  plot(EEG.data(132,offset-100:end), 'b');
end