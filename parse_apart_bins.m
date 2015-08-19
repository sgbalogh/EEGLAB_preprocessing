subject_list = {'A_NS707.002'};
eeglab
EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');

numbins = EEG.EVENTLIST.nbin;

bin = 1;
bin_epochs = struct();
eventlist_rows = length(EEG.EVENTLIST.eventinfo);
disp(eventlist_rows);

%EEG = pop_syncroartifacts(EEG, 2);

while bin <= numbins
initnum = 1;
marked_accept = [];
marked_reject = [];
    while initnum <= eventlist_rows

    if EEG.EVENTLIST.eventinfo(initnum).bini == bin
        epoch = EEG.EVENTLIST.eventinfo(initnum).bepoch;
        if EEG.EVENTLIST.eventinfo(initnum).flag == 0
        marked_accept(end+1) = epoch;
        elseif EEG.EVENTLIST.eventinfo(initnum).flag == 1
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

bin = 1;
while bin <= numbins
   
strbin = num2str(bin);
strbinacc = ['bin' strbin '_accepted'];
strbinrej = ['bin' strbin '_rejected'];

EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
if bin_epochs.(strbinacc) ~= 0
    EEG = pop_select( EEG,'trial',[bin_epochs.(strbinacc)] );
    EEG.setname = strbinacc;
    EEG= pop_saveset(EEG, 'filename', [strbinacc '.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');
end

EEG = pop_loadset('/Users/stephen/Desktop/neuro/trynow.set');
if bin_epochs.(strbinrej) ~= 0
    EEG = pop_select( EEG,'trial',[bin_epochs.(strbinrej)] );
    EEG.setname = strbinrej;
    EEG= pop_saveset(EEG, 'filename', [strbinrej '.set'], 'filepath', '/Users/stephen/Desktop/neuro/new/');
end

bin = bin + 1;
end
