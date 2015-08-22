%% CCSN EEGLAB/ERPLAB Pre-Processing Script
%% Version 1.0.1

% Created by Stephen Balogh (sbalogh@uchicago.edu) for
% the Center for Cognitive and Social Neuroscience,
% University of Chicago. Last updated 8/22/2015.

% This code is being tracked at:
% https://github.com/sgbalogh/EEGLAB_preprocessing

% Script based on a version by Carlos Cardenas-Iniguez
% (cardenas@uchicago.edu) from 7/22/2013.

% Adapted from ERPLab Scripting Guide Version 3.0
% please note changes below with date
% Script tested for use on Matlab R2014b
% Created using EEGLAB v13.4.4b, ERPLab version 5.0.0

% ------------------------------------------------
% Updates and revisions
%
% Modules to complete:
% 1.
% ------------------------------------------------

clear % Clear memory and the command window.
clc

%% Notes on multi-core processing (on acropolis.uchicago.edu with "torque" profile)
% If you want MATLAB to run multible versions of the below for-loop (most
% useful for running several ICA computations simultaneously), you can use
% the below command to distribute jobs to the MATLAB "workers". If you run this on the Social
% Science Division's acropolis supercomputer, then you will want to start
% the torque profile, which allows you up to 64 workers.
%
% NOTE: Make sure that when your script finishs you issue "matlabpool
% close"; this should be a part of this script, but you need to make sure
% that it is uncommented, otherwise your script will still allocate those
% workers and other users will not have access to them (you, or whoever has
% the acropolis account, will receive some angry e-mails from the
% SysAdmin).

%% Subject input list (always review):
subject_list = {'A_NS701.002' 'A_NS702.002' 'A_NS704.002' 'A_NS706.002' 'A_NS708.002' 'A_NS710.002' 'A_NS712.002' 'A_NS701.004' 'A_NS703.002' 'A_NS705.002' 'A_NS707.002' 'A_NS709.002' 'A_NS711.002' 'A_NS713.002'};
nsubj = length(subject_list); % Counts number of subjects in above array.

%% Input paths (always review):
home_path  = '/home/t-9balos/Documents/script_deploy_1'; % The full filepath to your home script directory ?? the directory that contains all sub-directories for input and output files.

bdf_name = 'ns_na_w49.txt'; % The name of your bin-descriptor file (BDF), which should reside in './helperfiles'.
chan_loc = 'GSN-HydroCel-129.sfp'; % The name of your channel location map, which should also reside in './helperfiles'.

input_raw = [home_path '/in_1_raw']; % Where your input EEG RAW files go,
input_set = [home_path '/in_2_set']; % ... and where your input EEGLAB SET files go.

%% Options (always review):
parallel_proc = 1; % Run this script in parallel on a MATLAB cluster? If set to 1, make sure that you change the main FOR-loop of this script into a PARFOR-loop. Therefore, change 'for s=1:nsubj' -> 'parfor s=1:nsubj'.
save_everything = 1; % Set the save_everything variable to 1 to save all of the intermediate files to the hard drive, 0 to save only the final stage.

starting_data = 'raw'; % Set to either 'raw' or 'set' for .RAW EEG data or .SET EEGLAB datasets, respectively.
epoch_begin_pre_onset = -300.0; % Period, in ms, before bin-linked event; the "baseline", pre-onset period of your trial epoch.
epoch_end_post_onset = 1000.0; % Amount of time, in trial epoch, after onset of bin-linked event. This (and previous) value may affect parameters of auto epoch rejection algorithms. Please review those parameters if you plan to use auto rejection.
resample_value = 250; % Target sampling rate if downsampling is performed.

filter_data = 1; % By default, high pass .1, low 30 Hz, notch at 60 Hz.
resample_data = 1; % Downsample to value set above?
add_chlocs = 1; % Attach channel location map to dataset? Required for ICA.
make_eventlist = 1; % Produce EVENTLIST and save to file (necessary for binlister).
do_binlister = 1; % Associates events in continuous data with bins specified in your bin-descriptor file (BDF).
compute_ICA = 1; % Run continuous data through ICA? This is very processor intensive, and should be run in parallel if possible.
use_eyecatch = 0; % Requires that Measure Projection Toolbox is installed and configured in your MATLAB environment. This section is inactivated by default.
extract_epochs = 1; % Creates epochs based on events that are placed into bins.
auto_epoch_rej = 1; % Uses algorithms for automatically detecting epochs with artifacts, and marks them for rejection.
bin_sorting = 1; % Sorts dataset into derivative datasets by bin, accepted trials, and rejected trials.
calculate_ERP = 1; % Calculates an ERP from the input dataset; if your conditions are split across multiple datasets, you may want to create ERP sets manually (so as to specify multiple inputs).

%% Output paths (no changes needed):
data_path = [home_path '/out_1_set']; % Where you'll save the .SET files, if converting from .RAW.
data_path_filt = [home_path '/out_2_filtered']; % Where you'll save files after filtering,
data_path_resample = [home_path '/out_3_resampled']; % ... after downsampling,
data_path_chlocs = [home_path '/out_4_ch_locs']; % ... after adding channel location map to the dataset,
data_path_ica = [home_path '/out_5_ICA_weights']; % ... after computing ICA weights,
data_path_epoched = [home_path '/out_6_epoched']; % ... after extracting epochs,
data_path_eyecatch = [home_path '/out_6a_eyecatch']; % ... after using the EYECatch algorithm to detect artifactual components,
data_path_erej = [home_path '/out_7_auto_epoch_rej']; % ... after the auto epoch rejection algorithm,
data_path_bin_epochs = [home_path '/out_8_bin_epochs']; % ... after the bin-sorter separates trials by bin (condition),
data_path_bin_accepted = [home_path '/out_9_bin_accepted']; % ... after the bin-sorter concatenates all accepted epochs (by bin),
data_path_bin_rejected = [home_path '/out_10_bin_rejected']; % ... and after the bin-sorter concatenates all rejected epochs (by bin).

data_path_elist = [home_path '/out_elist']; % Site of export for EVENTLIST,
data_path_blist = [home_path '/out_blist']; % ... for BINLIST,
data_path_erpset = [home_path '/out_ERP_set']; % ... for ERP set,
data_path_erptext = [home_path '/out_ERP_text']; % ... and for text version of ERP set.

if (parallel_proc) % Initializes MATLAB workers on UChicago SSD's Acropolis cluster, 'torque' profile, capped at 64 workers.
    if (nsubj <= 64)
        matlabpool('torque', nsubj); % Always make sure to release your workers after processing, with 'matlabpool close'.
    elseif (nsubj > 64);
        matlabpool('torque', 64);
    end
end

parfor s=1:nsubj % NOTE: make this 'parfor s=1:nsubj' if you want to run a multi-core parallelized version, and 'for s=1:nsubj' otherwise.
    
    fprintf('\n******\nProcessing subject %s\n******\n\n', subject_list{s});
    
    %% Start EEGLAB
    eeglab
    %% Import data
    % Check to make sure that either a raw or set file exists
    
    sname_raw = [input_raw '/' subject_list{s} '.raw'];
    sname_set = [input_set '/' subject_list{s} '.set'];
    
    if (exist(sname_raw, 'file')<=0 && exist(sname_set, 'file')<=0)
        fprintf('\n *** WARNING: %s or .set does not exist *** \n', sname_raw);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else
        
        %% Load RAW or SET file
        
        if (strcmp(starting_data,'raw'))
            fprintf('\n\n\n**** %s: Loading RAW file ****\n\n\n', subject_list{s});
            EEG = pop_readegi([input_raw '/' subject_list{s} '.raw']);
            EEG.setname = [subject_list{s}]; % name for the dataset menu
            
        elseif (strcmp(starting_data,'set'))
            fprintf('\n\n\n**** %s: Loading SET file ****\n\n\n', subject_list{s});
            EEG = pop_loadset([input_set '/' subject_list{s} '.set']); 
        end
        
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [subject_list{s} '.set'], 'filepath', data_path);
        end
        
        last_file_altered = [data_path '/' subject_list{s} '.set']; % Used to keep track of most recently saved file, in case subsequent actions are switched off.
        
        %% Filter data
        % Default: high pass 0.1 Hz, remove DC-bias, low pass at 30 Hz, notch at 60 Hz
        
        if (filter_data)
            fprintf('\n\n\n**** %s: Filtering EEG data ****\n\n\n', subject_list{s});
            
            EEG  = pop_basicfilter( EEG,  1:128 , 'Cutoff',  60, 'Design', 'notch', 'Filter', 'PMnotch', 'Order',  180, 'RemoveDC', 'on' );
            EEG.setname = [subject_list{s} '_filt'];
            EEG = pop_basicfilter( EEG, 1:128, 'Cutoff', [0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
            EEG.setname = [subject_list{s} '_filt'];
            
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_filt);
            end
            last_file_altered = [data_path_filt '/' EEG.setname '.set'];
        end
        %
        
        %% Downsample data
        if (resample_data)
            fprintf('\n\n\n**** %s: Downsampling to %d Hz ****\n\n\n', subject_list{s}, resample_value);
            
            EEG = pop_resample( EEG, resample_value);
            EEG.setname = [subject_list{s} '_resam'];
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_resample);
            end
            last_file_altered = [data_path_resample '/' EEG.setname '.set'];
        end
        %
        %% Add appropriate channel location information
        
        if (add_chlocs)
            EEG=pop_chanedit(EEG, 'lookup',[home_path '/helperfiles/' chan_loc]);
            EEG.setname = [EEG.setname '_chlocs'];
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_chlocs);
            end
            last_file_altered = [data_path_chlocs '/' EEG.setname '.set'];
        end
        
        %
        %% Create EVENTLIST and save (pop_editeventlist adds _elist suffix)
        
        if (make_eventlist)
            fprintf('\n\n\n**** %s: Creating eventlist ****\n\n\n', subject_list{s});
            
            %IMPORTANT: Netstation requires the use of four-character
            %tags or codes. ERPLab is not able to process letter codes, and so
            %the code below will strip away the letters from the code. This may
            %not be ideal, in which case you will need to add numerical codes
            %to your data. You can do so using the Advanced EVENTLIST options.
            %The following commented line of code will work provided that you
            %provide a text list with the label--> code conversion
            
            EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'Eventlist', [data_path_elist '/' subject_list{s} '_elist.txt'], 'Newboundary', { -99 }, 'Stringboundary', { 'boundary' }, 'Warning', 'on' );
            %EEG  = pop_editeventlist( EEG , 'BoundaryNumeric', {255}, 'BoundaryString', { 'boundary' }, 'ExportEL', [elist_path subject_list{s} '_elist.txt'], 'List', '[LOCATION OF YOUR TEXT FILE WITH CODES HERE', 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on' );
            EEG.setname = [EEG.setname '_elist'];
        end
        
        %% Use Binlister to sort the bins and save with _blist suffix
        if (do_binlister)
            fprintf('\n\n\n**** %s: Running Bin Lister ****\n\n\n', subject_list{s});
            
            EEG  = pop_binlister( EEG , 'BDF', [home_path '/helperfiles/' bdf_name], 'ExportEL', [data_path_blist '/' subject_list{s} '_blist.txt'], 'ImportEL', 'no', 'Saveas', 'on', 'SendEL2', 'EEG&Text', 'Warning', 'on' );
            EEG.setname = [subject_list{s} '_blist'];
        end
        %
        %% Compute ICA weights before extracting epochs
        if (compute_ICA)
            fprintf('\n\n\n**** %s: Computing ICA Weights ****\n\n\n', subject_list{s});
            
            EEG = pop_runica( EEG , 'concatenate', 'off', 'extended', 1);
            if (save_everything)
                EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_ica.set'], 'filepath', data_path_ica);
            end
            last_file_altered = [data_path_ica '/' subject_list{s} '_ica.set'];
        end
        
        %% Use Measure Projection Toolbox functionality (EyeCatch) to identify and purge independent components associated with eyeblinks
        
        % Measure Projection Toolbox (http://sccn.ucsd.edu/wiki/MPT) must
        % be installed to make use of this tool. In the past, I have had
        % difficulty getting this to work properly in a parfor-loop, but no
        % problems with a regular for-loop (for single-core processing). It
        % is always possible to run this pre-processing script in a multi-core environment up until
        % this step, then run it as a for-loop from this step until the
        % end since ICA is the real rate-determining-step of this entire script
        if (use_eyecatch)
            %fprintf('\n\n\n**** %s: Determining eyeblink ICs and removing from dataset ****\n\n\n', subject_list{s});
            
            %eyeDetector = pr.eyeCatch;
            %[eyeIC, similarity scalpmapObj] = eyeDetector.detectFromEEG(EEG); % detect eye ICs
            %eyeIC                          % display the IC numbers for eye ICs.
            %scalpmapObj.plot(eyeIC)        % plot eye ICs; this is only
            %useful if you want to see displays of each component that is marked for rejection, which could clog up your UI if you are running many subjects.
            %EEG = pop_subcomp( EEG, eyeIC, 0);
            %if
            %    EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_ica_er.set'], 'filepath', data_path_icaeyerej);
            %end
            %last_file_altered = [data_path_icaeyerej '/' subject_list{s} '_ica_er.set'];
        end
        
        %%  Extracts bin-based epochs
        
        if (extract_epochs)
            fprintf('\n\n\n**** %s: Bin-based epoching ****\n\n\n', subject_list{s});
            
            EEG = pop_epochbin( EEG , [epoch_begin_pre_onset epoch_end_post_onset],  'pre'); % Extracts epochs using times specified in script options (top).
            EEG.setname= [subject_list{s} '_epoched'];
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [subject_list{s} '_epoched.set'], 'filepath', data_path_epoched);
            end
            last_file_altered = [data_path_epoched '/' subject_list{s} '_epoched.set'];
        end
        
        %%  Automatic epoch rejection
        
        if (auto_epoch_rej)
            fprintf('\n\n\n**** %s: Epoch rejection ****\n\n\n', subject_list{s});
            
            % Extreme Values
            EEG  = pop_artextval( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold', [ -100 100], 'Twindow', [ -252 996] );
            % Moving Window
            EEG  = pop_artmwppth( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold',  100, 'Twindow', [ -300 996], 'Windowsize',  300, 'Windowstep',  100 );
            % Step-like Artifacts
            EEG  = pop_artstep( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold',  100, 'Twindow', [ -300 996], 'Windowsize',  200, 'Windowstep',  50 );
            EEG.setname= [subject_list{s} '_erej'];
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [subject_list{s} '_erej.set'], 'filepath', data_path_erej);
            end
            last_file_altered = [data_path_erej '/' subject_list{s} '_erej.set'];
        end
        
        %% Bin and epoch separation
        
        if (bin_sorting)
            numbins = EEG.EVENTLIST.nbin; % Grabs total number of bins listed in EVENTLIST, drawing from your BDF
            bin_epochs = struct(); % Creates an empty 'bin_epochs' structure (visable from the MATLAB workspace) which will be populated with fields corresponding to accepted and rejected trials, per bin.
            eventlist_rows = length(EEG.EVENTLIST.eventinfo);
            disp(eventlist_rows);
            
            %EEG = pop_syncroartifacts(EEG, 2); % Synchronizes EVENTLIST and EEG.reject
            
            bin = 1; % Initial value for counter
            while bin <= numbins
                initnum = 1;
                all_epochs = [];
                marked_accept = [];
                marked_reject = [];
                while initnum <= eventlist_rows
                    if (EEG.EVENTLIST.eventinfo(initnum).bini == bin)
                        epoch = EEG.EVENTLIST.eventinfo(initnum).bepoch;
                        all_epochs(end+1) = epoch;
                        if (EEG.EVENTLIST.eventinfo(initnum).flag == 0) % Lack of flag in EVENTLIST, 0, indicates epoch was not selected for rejection.
                            marked_accept(end+1) = epoch;
                        elseif (EEG.EVENTLIST.eventinfo(initnum).flag == 1) % Presence of flag, 1, indicates epoch was selected for rejection.
                            marked_reject(end+1) = epoch;
                        end
                    end
                    initnum = initnum + 1;
                end
                strbin = num2str(bin);
                strbinall = ['bin' strbin '_all_epochs'];
                strbinacc = ['bin' strbin '_accepted'];
                strbinrej = ['bin' strbin '_rejected'];
                bin_epochs = setfield(bin_epochs,strbinall,all_epochs);
                bin_epochs = setfield(bin_epochs,strbinacc,marked_accept);
                bin_epochs = setfield(bin_epochs,strbinrej,marked_reject);
                disp(bin_epochs.(strbinacc));
                bin = bin + 1;
            end
            
            bin = 1; % Resets initial value for counter
            while bin <= numbins
                strbin = num2str(bin);
                strbinall = ['bin' strbin '_all_epochs'];
                strbinacc = ['bin' strbin '_accepted'];
                strbinrej = ['bin' strbin '_rejected'];
                if (bin_epochs.(strbinall) ~= 0) % Saves versions of dataset that contains all epochs, separated by bins.
                    EEG = pop_loadset(last_file_altered);
                    EEG = pop_select( EEG,'trial',[bin_epochs.(strbinall)] );
                    EEG.setname = strbinall;
                    EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_bin' strbin '_all.set'], 'filepath', data_path_bin_epochs);
                end
                if (bin_epochs.(strbinacc) ~= 0) % Saves version of dataset that contains only accepted epochs, separated by bins.
                    EEG = pop_loadset(last_file_altered);
                    EEG = pop_select( EEG,'trial',[bin_epochs.(strbinacc)] );
                    EEG.setname = strbinacc;
                    EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_' strbinacc '.set'], 'filepath', data_path_bin_accepted);
                end
                if (bin_epochs.(strbinrej) ~= 0) % Saves version of dataset that contains only rejected epochs, separated by bins.
                    EEG = pop_loadset(last_file_altered);
                    EEG = pop_select( EEG,'trial',[bin_epochs.(strbinrej)] );
                    EEG.setname = strbinrej;
                    EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_' strbinrej '.set'], 'filepath', data_path_bin_rejected);
                end
                bin = bin + 1;
            end
        end
        
        %% ERP set creation and export to text (universal)
        if (calculate_ERP)
            EEG = pop_loadset(last_file_altered);
            ERP = pop_averager( EEG , 'Criterion', 'good', 'DSindex',1, 'Warning', 'off' );
            %ERP = pop_averager( EEG , 'Criterion', 'good', 'DSindex',1, 'Stdev', 'on', 'Warning', 'off' );
            ERP = pop_savemyerp(ERP, 'erpname', [subject_list{s}], 'filename', [subject_list{s} '.erp'], 'filepath', data_path_erpset, 'warning', 'off');
            %ERP = pop_export2text( ERP, [data_path_erptext '/' subject_list{s} '.txt'],1, 'time', 'off', 'electrodes', 'on', 'transpose', 'off', 'precision',  4, 'timeunit',  0.001 );
            %ERP = pop_loaderp( 'filename', [subject_list{s} '.erp'], 'filepath', data_path_erpset );
            %ERP = pop_export2text( ERP, [data_path_erptext '/' subject_list{s} '.txt'],  1:numbins, 'electrodes', 'on', 'precision',  4, 'time', 'on', 'timeunit',  0.001 );
        end
        
    end % ...of else statement
    %eeglab rebuild
    
end % End of looping through all subjects.

matlabpool close % Release MATLAB workers.

fprintf('\n\n\n**** FINISHED ****\n\n\n');
fprintf('\n\n\n**** FINAL OUTPUT FILES ARE NAMED _epoched %s: ****\n\n\n', data_path);
