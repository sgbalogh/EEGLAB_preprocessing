subject_list = {'A_NS707.002'};
eeglab
EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
numbins = 6;
bin = 1;
bin_epochs = struct();
eventlist_rows = length(EEG.EVENTLIST.eventinfo);
disp(eventlist_rows);
while bin <= numbins
initnum = 1;
todestroy = [];
    while initnum < eventlist_rows

    
    if EEG.EVENTLIST.eventinfo(initnum).bini == bin

        epoch = EEG.EVENTLIST.eventinfo(initnum).bepoch;
        todestroy(end+1) = epoch;
    
    end

    initnum = initnum + 1;

    end

strbin = num2str(bin);
strbin = ['bin' strbin];

bin_epochs = setfield(bin_epochs,strbin,todestroy);
disp(bin_epochs.(strbin));

%EEG = pop_select( EEG,'trial',[todestroy] );
%EEG.setname = ['laloooo_' bin];
%EEG= pop_saveset(EEG, 'filename', [bin 'heyoo_blist.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');

bin = bin + 1;

end
bin = 1;
while bin <= numbins
   
strbin = num2str(bin);
strbin = ['bin' strbin];

EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
EEG = pop_select( EEG,'trial',[bin_epochs.(strbin)] );
EEG.setname = [strbin '_all'];
EEG= pop_saveset(EEG, 'filename', [strbin '_all.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');

    bin = bin + 1;
end
%EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
%EEG = pop_select( EEG,'trial',[bin_epochs.bin1] );
%EEG.setname = ['laloooo_1' bin];
%EEG= pop_saveset(EEG, 'filename', [bin '111_heyoo_blist.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');
