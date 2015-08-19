clear
clc

subject_list = {'A_NS707.002'};
eeglab

EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');

numbins = EEG.EVENTLIST.nbin; % Grabs total number of bins listed in EVENTLIST, drawing from your BDF
bin_epochs = struct(); % Creates an empty 'bin_epochs' structure (visable from the MATLAB workspace) which will be populated with fields corresponding to accepted and rejected trials, per bin.
eventlist_rows = length(EEG.EVENTLIST.eventinfo);
disp(eventlist_rows);

EEG = pop_syncroartifacts(EEG, 2, 'script'); % Synchronizes EVENTLIST and EEG.reject

bin = 1; % Initial value for counter
while bin <= numbins
    initnum = 1;
    marked_accept = [];
    marked_reject = [];
    while initnum <= eventlist_rows
        if EEG.EVENTLIST.eventinfo(initnum).bini == bin
            epoch = EEG.EVENTLIST.eventinfo(initnum).bepoch;
            if EEG.EVENTLIST.eventinfo(initnum).flag == 0 % Lack of flag in EVENTLIST, 0, indicates epoch was not selected for rejection
                marked_accept(end+1) = epoch;
            elseif EEG.EVENTLIST.eventinfo(initnum).flag == 1 % Presence of flag, 1, indicates epoch was selected for rejection
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
    
    if bin_epochs.(strbinacc) ~= 0 % Saves version of dataset that contains only accepted epochs
        EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
        EEG = pop_select( EEG,'trial',[bin_epochs.(strbinacc)] );
        EEG.setname = strbinacc;
        EEG= pop_saveset(EEG, 'filename', [strbinacc '.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');
    end
    
    if bin_epochs.(strbinrej) ~= 0 % Saves version of dataset that contains only rejected epochs
        EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
        EEG = pop_select( EEG,'trial',[bin_epochs.(strbinrej)] );
        EEG.setname = strbinrej;
        EEG= pop_saveset(EEG, 'filename', [strbinrej '.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');
    end
    
    bin = bin + 1;
end
