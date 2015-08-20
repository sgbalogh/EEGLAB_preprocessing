% Created by Stephen Balogh (sbalogh@uchicago.edu)
% based on a version by Carlos Cardenas-Iniguez
% (cardenas@uchicago.edu) on 7/22/2013.

% Adapted from ERPLab Scripting Guide Version 3.0
% please note changes below with date
% Script tested for use on Matlab R2013b
% Created using EEGLAB v13.2.1, ERPLab version 4.0.2.3

% ------------------------------------------------
% Updates and revisions
%
%
% ------------------------------------------------

% Clear memory and the command window

clear

clc

%% Initiate multi-core processing (on acropolis.uchicago.edu with "torque" profile)
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

% matlabpool torque 2

%

%% This defines the list of subjects

subject_list = {'A_NS702.002' 'A_NS703.002' 'A_NS704.002' 'A_NS705.002'};

nsubj = length(subject_list);


%

% Processing options:
save_everything = 1; % Set the save_everything variable to 1 to save all of the intermediate files to the hard drive, 0 to save only final stage
calculate_ICA = 0; % Calculate ICA weights (performed on continuous data, before epoching)? NOTE: This is processor intensive! Consider running in parallel if more than one subject.
do_auto_epoch_rej = 1; % Use auto epoch rejection algorithms?
starting_data = 'raw'; % Set to either 'raw' or 'set' for .RAW EEG data or .SET EEGLAB datasets, respectively

% Input paths:
home_path  = '/Users/stephen/desktop/script_deploy';
bdf_name = 'ns_na_w49.txt'; % The BDF file should reside in './helperfiles'.
chan_loc = 'GSN-HydroCel-129.sfp';

input_raw = [home_path '/in_1_raw'];
input_set = [home_path '/in_2_set'];

% Output paths:
data_path = [home_path '/out_1_set']; %where you'll save the .set files
data_path_filt = [home_path '/out_2_filtered']; %where you'll save the _filt.set files
data_path_resample = [home_path '/out_3_resampled']; %where you'll save the resampled set files
data_path_chlocs = [home_path '/out_4_ch_locs']; %where you'll save the _chlocs.set files
data_path_ica = [home_path '/out_5_ICA_weights']; %where you'll save sets with ICA weights computed
data_path_epoched = [home_path '/out_6_epoched']; %where you'll save the _epoched.set files
data_path_eyecatch = [home_path '/out_6a_eyecatch']; %where you'll save the _epoched.set files
data_path_erej = [home_path '/out_7_auto_epoch_rej']; %where you'll save sets that have epochs marked for rejection
data_path_binepochs = [home_path '/out_8_bin_epochs']; %where you'll save sets that have epochs marked for rejection
data_path_bin_accepted = [home_path '/out_9_bin_accepted']; %where you'll save sets that have epochs marked for rejection
data_path_bin_rejected = [home_path '/out_10_bin_rejected']; %where you'll save sets that have epochs marked for rejection

data_path_erpset  = [home_path '/out_ERP_set']; %where you'll export ERP sets
data_path_erptext = [home_path '/out_ERP_text']; %where you'll export text versions of your ERP sets

for s=1:nsubj %make this parfor s=1:nsubj if you want to run multi-core parallelized version
    
    
    
    fprintf('\n******\nProcessing subject %s\n******\n\n', subject_list{s});
    
    
    %%
    eeglab
    %%IMPORT DATA
    
    % Check to make sure the raw file exists
    
    %
    sname = [input_raw '/' subject_list{s} '.raw'];  %%check to make sure raw file exists for each subject in the directory specified
    if exist(sname, 'file')<=0
        fprintf('\n *** WARNING: %s does not exist *** \n', sname);
        fprintf('\n *** Skip all processing for this subject *** \n\n');
    else
        
        %
        
        % Load raw file;
        
        %
        
        fprintf('\n\n\n**** %s: Loading raw file ****\n\n\n', subject_list{s});
        
        EEG = pop_readegi([input_raw '/' subject_list{s} '.raw']);
        
        %EEG = pop_loadset([home_path subject_list{s} '.set']) %use this if
        %you are importting set files, not raw
        
        EEG.setname = [subject_list{s}]; % name for the dataset menu
        
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [subject_list{s} '.set'], 'filepath', data_path);
        end
        
        
        %
        
        
        
        %% Filter data - using high pass 0.1, remove dc, low pass at 30hz,
        % notch at 60hz
        
        %
        %
        fprintf('\n\n\n**** %s: High-pass filtering EEG at 0.1, Low-pass filtering at 30Hz, Notch at 60 Hz ****\n\n\n', subject_list{s});
        
        EEG  = pop_basicfilter( EEG,  1:128 , 'Cutoff',  60, 'Design', 'notch', 'Filter', 'PMnotch', 'Order',  180, 'RemoveDC', 'on' );
        
        EEG.setname = [subject_list{s} '_filt'];
        EEG = pop_basicfilter( EEG, 1:128, 'Cutoff', [0.1 30], 'Design', 'butter', 'Filter', 'bandpass', 'Order', 2, 'RemoveDC', 'on');
        
        EEG.setname = [subject_list{s} '_filt'];
        
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_filt);
        end
        
        %
        
        %% Downsample data to 250hz
        
        fprintf('\n\n\n**** %s: Downsampling to 250hz ****\n\n\n', subject_list{s});
        
        EEG = pop_resample( EEG, 250);
        EEG.setname = [subject_list{s} '_resam'];
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_resample);
        end
        %
        %%       % Add appropriate channel location information
        %
        %         %
        %
        %         %change this path to match where channel information file is for
        %         your setup (You can find this on the ERPLAB help site
        
        EEG=pop_chanedit(EEG, 'lookup',[home_path '/helperfiles/' chan_loc]);
        EEG.setname = [EEG.setname '_chlocs'];
        
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [EEG.setname '.set'], 'filepath', data_path_chlocs);
        end
        %         %
        %%      Create EVENTLIST and save (pop_editeventlist adds _elist suffix)
        
        fprintf('\n\n\n**** %s: Creating eventlist ****\n\n\n', subject_list{s});
        elist_path  = [home_path '/elist/']; %where you'll save the elist.txt files
        
        %IMPORTANT: Netstation requires the use of four-character
        %tags or codes. ERPLab is not able to process letter codes, and so
        %the code below will strip away the letters from the code. This may
        %not be ideal, in which case you will need to add numerical codes
        %to your data. You can do so using the Advanced EVENTLIST options.
        %The following commented line of code will work provided that you
        %provide a text list with the label--> code conversion
        %
        EEG  = pop_creabasiceventlist( EEG , 'AlphanumericCleaning', 'on', 'Eventlist', [elist_path subject_list{s} '_elist.txt'], 'Newboundary', { -99 }, 'Stringboundary', { 'boundary' }, 'Warning', 'on' );
        %       EEG  = pop_editeventlist( EEG , 'BoundaryNumeric', {255}, 'BoundaryString', { 'boundary' }, 'ExportEL', [elist_path subject_list{s} '_elist.txt'], 'List', '[LOCATION OF YOUR TEXT FILE WITH CODES HERE', 'SendEL2', 'EEG&Text', 'UpdateEEG', 'on' );
        
        EEG.setname = [EEG.setname '_elist'];
        
        if (save_everything)
            
            EEG = pop_saveset(EEG, 'filename', [subject_list{s} '_elist.set'], 'filepath', elist_path);
            
        end
        
        
        
        %% Use Binlister to sort the bins and save with _blist suffix
        
        % Remember to enter the correct path to your bin descriptor file
        % (BDF), in this case "ns_na_w49.txt"
        
        fprintf('\n\n\n**** %s: Running BinLister ****\n\n\n', subject_list{s});
        
        blist_path  = [home_path '/blist/']; %where you'll save the blist.txt files
        
        EEG  = pop_binlister( EEG , 'BDF', [home_path '/helperfiles/' bdf_name], 'ExportEL', [blist_path subject_list{s} '_blist.txt'], 'ImportEL', 'no', 'Saveas', 'on', 'SendEL2', 'EEG&Text', 'Warning', 'on' );
        EEG.setname = [subject_list{s} '_blist'];
        
        if (save_everything)
            
            EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_blist.set'], 'filepath', blist_path);
            %
        end
        
        
        %
        %% Compute ICA weights before extracting epochs
        if (calculate_ICA)
            fprintf('\n\n\n**** %s: Computing ICA Weights ****\n\n\n', subject_list{s});
            
            EEG = pop_runica( EEG , 'concatenate', 'off', 'extended', 1);
            
            if (save_everything)
                EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_ica.set'], 'filepath', data_path_ica);
            end
        end
        
        %% Use Measure Projection Toolbox functionality (EyeCatch) to identify and purge independent components associated with eyeblinks
        
        % Measure Projection Toolbox (http://sccn.ucsd.edu/wiki/MPT) must
        % be installed to make use of this tool. In the past, I have had
        % difficulty getting this to work properly in a parfor-loop, but no
        % problems with a regular for-loop (for single-core processing). It
        % is always possible to run this pre-processing script in a multi-core environment up until
        % this step, then run it as a for-loop from this step until the
        % end since ICA is the real rate-determining-step of this entire script
        
        %fprintf('\n\n\n**** %s: Determining eyeblink ICs and removing from dataset ****\n\n\n', subject_list{s});
        
        %eyeDetector = pr.eyeCatch;
        
        %[eyeIC similarity scalpmapObj] = eyeDetector.detectFromEEG(EEG); % detect eye ICs
        %eyeIC                          % display the IC numbers for eye ICs.
        %scalpmapObj.plot(eyeIC)        % plot eye ICs; this is only useful if you want to see displays of each component that is marked for rejection, which could clog up your UI if you are running many subjects
        
        %EEG = pop_subcomp( EEG, eyeIC, 0);
        
        %if
        %EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_ica.set'], 'filepath', data_path_icaeyerej);
        %end
        
        %%  Extracts bin-based epochs
        
        % Then save with _epoched suffix
        
        %
        
        fprintf('\n\n\n**** %s: Bin-based epoching ****\n\n\n', subject_list{s});
        
        EEG = pop_epochbin( EEG , [-300.0  1000.0],  'pre');
        
        EEG.setname= [subject_list{s} '_epoched'];
        
        if (save_everything)
            EEG = pop_saveset(EEG, 'filename', [subject_list{s} '_epoched.set'], 'filepath', data_path_epoched);
        end
        
        
        %%  Automatic epoch rejection
        
        % Then save with _erej suffix
        
        %
        if (do_auto_epoch_rej)
            fprintf('\n\n\n**** %s: Epoch rejection ****\n\n\n', subject_list{s});
            
            %extreme values
            EEG  = pop_artextval( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold', [ -100 100], 'Twindow', [ -252 996] );
            
            %moving window
            EEG  = pop_artmwppth( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold',  100, 'Twindow', [ -300 996], 'Windowsize',  300, 'Windowstep',  100 );
            
            %step like artifacts
            EEG  = pop_artstep( EEG , 'Channel',  1:128, 'Flag',  1, 'Review', 'on', 'Threshold',  100, 'Twindow', [ -300 996], 'Windowsize',  200, 'Windowstep',  50 );
            
            EEG.setname= [subject_list{s} '_erej'];
            
            if (save_everything)
                EEG = pop_saveset(EEG, 'filename', [subject_list{s} '_erej.set'], 'filepath', data_path_erej);
            end
        end
        
        
        %% Bin and epoch separation
        
        numbins = EEG.EVENTLIST.nbin; % Grabs total number of bins listed in EVENTLIST, drawing from your BDF
        bin_epochs = struct(); % Creates an empty 'bin_epochs' structure (visable from the MATLAB workspace) which will be populated with fields corresponding to accepted and rejected trials, per bin.
        eventlist_rows = length(EEG.EVENTLIST.eventinfo);
        disp(eventlist_rows);
        
        %EEG = pop_syncroartifacts(EEG, 2); % Synchronizes EVENTLIST and EEG.reject
        
        bin = 1; % Initial value for counter
        while bin <= numbins
            initnum = 1;
            marked_accept = [];
            marked_reject = [];
            while initnum <= eventlist_rows
                if (EEG.EVENTLIST.eventinfo(initnum).bini == bin)
                    epoch = EEG.EVENTLIST.eventinfo(initnum).bepoch;
                    if (EEG.EVENTLIST.eventinfo(initnum).flag == 0) % Lack of flag in EVENTLIST, 0, indicates epoch was not selected for rejection
                        marked_accept(end+1) = epoch;
                    elseif (EEG.EVENTLIST.eventinfo(initnum).flag == 1) % Presence of flag, 1, indicates epoch was selected for rejection
                        marked_reject(end+1) = epoch;
                    end
                end
                initnum = initnum + 1;
            end
            strbin = num2str(bin);
            strbinacc = ['bin' strbin '_accepted'];
            strbinrej = ['bin' strbin '_rejected'];
            bin_epochs = setfield(bin_epochs,strbinacc,marked_accept);
            bin_epochs = setfield(bin_epochs,strbinrej,marked_reject);
            disp(bin_epochs.(strbinacc));
            
            bin = bin + 1;
        end
        
        bin = 1; % Resets initial value for counter
        while bin <= numbins
            
            strbin = num2str(bin);
            strbinacc = ['bin' strbin '_accepted'];
            strbinrej = ['bin' strbin '_rejected'];
            
            if (bin_epochs.(strbinacc) ~= 0) % Saves version of dataset that contains only accepted epochs
                EEG = pop_loadset([home_path '/out_6_epoched/' subject_list{s} '_epoched.set']);
                EEG = pop_select( EEG,'trial',[bin_epochs.(strbinacc)] );
                EEG.setname = strbinacc;
                EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_' strbinacc '.set'], 'filepath', data_path_bin_accepted);
            end
            
            if (bin_epochs.(strbinrej) ~= 0) % Saves version of dataset that contains only rejected epochs
                EEG = pop_loadset([home_path '/out_6_epoched/' subject_list{s} '_epoched.set']);
                EEG = pop_select( EEG,'trial',[bin_epochs.(strbinrej)] );
                EEG.setname = strbinrej;
                EEG= pop_saveset(EEG, 'filename', [subject_list{s} '_' strbinrej '.set'], 'filepath', data_path_bin_rejected);
            end
            
            bin = bin + 1;
        end
        
        
        %% ERP set creation and export to text (universal)
        EEG = pop_loadset([home_path '/out_6_epoched/' subject_list{s} '_epoched.set']);
        ERP = pop_averager( EEG , 'Criterion', 'good', 'DSindex',1, 'Warning', 'off' );
        %ERP = pop_averager( EEG , 'Criterion', 'good', 'DSindex',1, 'Stdev', 'on', 'Warning', 'off' );
        
        ERP = pop_savemyerp(ERP, 'erpname', [subject_list{s}], 'filename', [subject_list{s} '.erp'], 'filepath', data_path_erpset, 'warning', 'off');
        ERP = pop_export2text( ERP, [data_path_erptext '/' subject_list{s} '.txt'],1, 'time', 'off', 'electrodes', 'on', 'transpose', 'off', 'precision',  4, 'timeunit',  0.001 );
        
    end % of else statement
    %eeglab rebuild
    
end % end of looping through all subjects
%

%matlabpool close

fprintf('\n\n\n**** FINISHED ****\n\n\n');

fprintf('\n\n\n**** FINAL OUTPUT FILES ARE NAMED _epoched %s: ****\n\n\n', data_path);
