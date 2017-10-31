%% Analyzing the STOP-SIGNAL for PD with DBS


%% Initial parameters

format shortG % setting the format of the numbers to shortG (to try avoid too many 1.0e+06 * 0.0000 cases)
Pdir = '/Users/au183362/Documents/MATLAB/VF_SS_DBS/behavioral/logfiles'; % "raw" file directory
Sdir = '/Users/au183362/Documents/MATLAB/VF_SS_DBS/behavioral/stop_signal'; % save file directory
subjs = 5:14; %subj-ids - don't forget to update "set_codes" if adding more subjects
suf = 'stop_signal_nogo';
txtsuf = 'logss_nogo_log.txt';
conds = 1:3;
blocks = {'.', '..', '...'};


settings = {'OFF','DORSAL','VENTRAL'};
set_codes = [3 1 1 1 1 1 1 1 1 1; 
    1 2 3 3 3 3 2 3 2 3;
    2 3 2 2 2 2 3 2 3 2]; % whether DORSAL (=1) or VENTRAL (=2) came first

u_codes = set_codes+1; % for the UPDRS scores

UPDRS = [17 10 9 2 20 11 9 13 14 11;
    19 25 28 25 30 27 35 19 30 24;
    46 8 10 3 16 6 8 7 13 11;
    18 8 3 1 17 6 15 1 3 9;
    15 8 1 2 15 9 8 5 5 8]; 

SS_UPDRS = UPDRS(2:4,:);
UPDRS_ord = zeros(size(UPDRS));
UPDRS_ord([1 5],:) = UPDRS([1 5],:);
for r = 2:4
    for u = 1:size(UPDRS_ord,2)
        UPDRS_ord(r,u) = SS_UPDRS(u_codes(:,u)==r,u);
    end
end

%% Read and analyse logfiles for DORSAL and VENTRAL

cd(Pdir)
for s = 1:length(subjs)
    count = 0;
    logs_txt = dir(sprintf('%04d*%s',subjs(s),txtsuf));
    logs_log = dir(sprintf('%04d*%s*log',subjs(s),suf));
    for l = length(logs_txt):-1:1
        cond(l) = str2double(logs_txt(l).name(10));
    end
    for c = 1:length(conds)
        if ~isempty(find(cond==c,1))
            for i = 1:length(find(cond==c))
                count = count+1;
                
                fid = fopen(logs_txt(count).name);
                txtcell = textscan(fid, '%f%f%f%f%f%f%f', 'headerlines', 1, 'delimiter', '\t', 'emptyvalue', Inf, 'collectoutput', 1);
                txt_a = txtcell{1};
                txt_b{c,i} = txt_a;
                frewind(fid);
                txt_header{c,i} = fgets(fid);
                fclose(fid);
                
                fid = fopen(logs_log(count).name);
                logcell = textscan(fid, '%s%f%s%s%f%f%f%f%f%f%f%s%f', 'headerlines', 5, 'delimiter', '\t', 'emptyvalue', Inf);
                log_a = logcell;
                log_b{c,i} = log_a;
                frewind(fid);
                for j = 1:3
                    blank = fgets(fid);
                end
                log_header = strsplit(fgetl(fid),'\t');
                fclose(fid);
                
                log_data = zeros(length(log_a{strcmp('Code',log_header)}),3);
                log_data(:,1) = str2double(log_a{strcmp('Code',log_header)});
                log_data(:,2) = log_a{strcmp('Time',log_header)};
                log_data(:,3) = log_a{strcmp('TTime',log_header)};
                log_c{c,i} = log_data;
                
                txt_SSD(c,i).raw = txt_a(txt_a(:,2)==11,[3 4 6])+100; % the delay printed in the log doesn't take the duration of the previous sound into account
                txt_SSD(c,i).mean = mean(txt_SSD(c,i).raw(:,1));
                txt_SSD(c,i).ca_meanRT = mean(txt_SSD(c,i).raw(txt_SSD(c,i).raw(:,2)==1,3));
                txt_signal(c,i).raw = txt_a(txt_a(:,2)==11,4);
                txt_signal(c,i).prob = sum(txt_signal(c,i).raw)/length(txt_signal(c,i).raw);
                txt_no_signal(c,i).raw = txt_a(txt_a(:,2)==10,5:6);
                txt_no_signal(c,i).response = txt_no_signal(c,i).raw(txt_no_signal(c,i).raw(:,1)==1,2);
                txt_no_signal(c,i).ca_meanRT = mean(txt_no_signal(c,i).response);
                txt_no_signal(c,i).correct = length(txt_no_signal(c,i).response)/length(txt_no_signal(c,i).raw);
                txt_no_signal(c,i).miss = sum(txt_no_signal(c,i).raw(:,1)==2)/length(txt_no_signal(c,i).response);
                txt_SSRT(c,i) = txt_no_signal(c,i).ca_meanRT-txt_SSD(c,i).mean;
                txt_nogo(c,i).raw = txt_a(txt_a(:,2)==12,[4 6]);
                txt_nogo(c,i).prob = sum(txt_nogo(c,i).raw(:,1))/size(txt_nogo(c,i).raw,1);
                
                log_SSD(c,i).raw = log_data(log_data(:,1)==11,3)/10; % adjusting for 1/10 millisekund notation
                log_SSD(c,i).mean = mean(log_SSD(c,i).raw);
                log_resp_idx = find(log_data(:,1)==1 | log_data(:,1)==2 | log_data(:,1)==3 | log_data(:,1)==4);
                log_resp_trials = log_data(log_resp_idx-1,1);
                log_signal(c,i).response = log_data(log_resp_idx(log_resp_trials==20 | log_resp_trials==11),:);
                log_signal(c,i).response(:,3) = log_signal(c,i).response(:,3)/10; % adjusting for 1/10 millisekund notation
                log_signal(c,i).response((log_signal(c,i).response(:,3) < 50),:) = []; % throwing out responses shorter than 50 ms
                log_signal(c,i).RT = mean(log_signal(c,i).response(:,3));
                log_no_signal(c,i).response = log_data(log_resp_idx(log_resp_trials==10),:);
                log_no_signal(c,i).response(:,3) = log_no_signal(c,i).response(:,3)/10; % adjusting for 1/10 millisekund notation
                log_no_signal(c,i).response((log_no_signal(c,i).response(:,3) < 50),:) = []; % throwing out responses shorter than 50 ms
                log_no_signal(c,i).RT = mean(log_no_signal(c,i).response(:,3));
                log_SSRT(c,i) = log_no_signal(c,i).RT - log_SSD(c,i).mean;
                
                clear txt_a log_a txtcell logcell log_data log_resp_idx log_resp_trials
            end
            all_txt_SSRT(s).(settings{set_codes(c,s)}) = mean(txt_SSRT(c,:)); 
            all_txt_SSD(s).(settings{set_codes(c,s)}) = mean([txt_SSD(c,:).mean]); 
            all_txt_signal(s).(settings{set_codes(c,s)}) = mean([txt_signal(c,:).prob]);
            all_txt_no_signal(s).(settings{set_codes(c,s)}) = mean([txt_no_signal(c,:).ca_meanRT]);
            all_txt_nogo(s).(settings{set_codes(c,s)}) = mean([txt_nogo(c,:).prob]);
            
            all_log_SSRT(s).(settings{set_codes(c,s)}) = mean(log_SSRT(c,:)); 
            all_log_SSD(s).(settings{set_codes(c,s)}) = mean([log_SSD(c,:).mean]); 
            all_log_signal(s).(settings{set_codes(c,s)}) = mean([log_signal(c,:).RT]);
            all_log_no_signal(s).(settings{set_codes(c,s)}) = mean([log_no_signal(c,:).RT]);
            
        elseif isempty(find(cond==c,1))
            
            all_txt_SSRT(s).(settings{set_codes(c,s)}) = NaN; 
            all_txt_SSD(s).(settings{set_codes(c,s)}) = NaN; 
            all_txt_signal(s).(settings{set_codes(c,s)}) = NaN;
            all_txt_no_signal(s).(settings{set_codes(c,s)}) = NaN;
            all_txt_nogo(s).(settings{set_codes(c,s)}) = NaN;
            
            all_log_SSRT(s).(settings{set_codes(c,s)}) = NaN;
            all_log_SSD(s).(settings{set_codes(c,s)}) = NaN; 
            all_log_signal(s).(settings{set_codes(c,s)}) = NaN;
            all_log_no_signal(s).(settings{set_codes(c,s)}) = NaN;
        end
    end
    save(fullfile(Sdir,sprintf('%04d_stop_signal.mat',subjs(s))), 'txt_b', 'log_b', 'log_c', 'txt_SSD', 'txt_signal', 'txt_no_signal', 'txt_SSRT', 'txt_nogo', ...
        'log_SSD', 'log_signal', 'log_no_signal', 'log_SSRT');   
    clear txt_b log_b log_c txt_SSD txt_signal txt_no_signal txt_SSRT txt_nogo log_SSD log_signal log_no_signal log_SSRT cond
end
save(fullfile(Sdir,sprintf('%04d_to_%04d_stop_signal.mat',subjs(1),subjs(end))), 'all_txt_SSRT', 'all_txt_SSD', 'all_txt_signal', 'all_txt_no_signal', 'all_txt_nogo', ...
    'all_log_SSRT', 'all_log_SSD', 'all_log_signal', 'all_log_no_signal', 'UPDRS', 'UPDRS_ord', 'set_codes', 'u_codes');


figure, plot([all_txt_SSRT(:).DORSAL; all_txt_SSRT(:).VENTRAL; all_txt_SSRT(:).OFF]','o-','linewidth',1)
title(sprintf('[TXT] SSRT (n=%d)',length(subjs)))
figure, plot([all_txt_signal(:).DORSAL; all_txt_signal(:).VENTRAL; all_txt_signal(:).OFF]','o-','linewidth',1)
title(sprintf('[TXT] signal prob (n=%d)',length(subjs)))
figure, plot([all_txt_no_signal(:).DORSAL; all_txt_no_signal(:).VENTRAL; all_txt_no_signal(:).OFF]','o-','linewidth',1)
title(sprintf('[TXT] no_signal RT (n=%d)',length(subjs)))
figure, plot([all_txt_SSD(:).DORSAL; all_txt_SSD(:).VENTRAL; all_txt_SSD(:).OFF]','o-','linewidth',1)
title(sprintf('[TXT] stop delay (n=%d)',length(subjs)))
figure, plot([all_txt_nogo(:).DORSAL; all_txt_nogo(:).VENTRAL; all_txt_nogo(:).OFF]','o-','linewidth',1)
title(sprintf('[TXT] nogo prob (n=%d)',length(subjs)))


figure, plot([all_log_SSRT(:).DORSAL; all_log_SSRT(:).VENTRAL; all_log_SSRT(:).OFF]','o-','linewidth',1)
title(sprintf('[LOG] SSRT (n=%d)',length(subjs)))
legend('DORSAL','VENTRAL','OFF')
figure, plot([all_log_signal(:).DORSAL; all_log_signal(:).VENTRAL; all_log_signal(:).OFF]','o-','linewidth',1)
title(sprintf('[LOG] signal RT (n=%d)',length(subjs)))
figure, plot([all_log_no_signal(:).DORSAL; all_log_no_signal(:).VENTRAL; all_log_no_signal(:).OFF]','o-','linewidth',1)
title(sprintf('[LOG] no_signal RT (n=%d)',length(subjs)))
figure, plot([all_log_SSD(:).DORSAL; all_log_SSD(:).VENTRAL; all_log_SSD(:).OFF]','o-','linewidth',1)
title(sprintf('[LOG] stop delay (n=%d)',length(subjs)))



figure, plot(UPDRS_ord(2:4,subsub),'o-','linewidth',2,'color',[.5 .5 .5])
xlim([.5 3.5]), ylim([0 50])
set(gca,'xtick',[1 2 3])
set(gca,'xticklabel',{'OFF','DORSAL','VENTRAL'})
ylabel('UPDRS-III')
xlabel('DBS condition')
title('UPDRS-III (n=8)')
hold on, plot(mean(UPDRS_ord(2:4,subsub),2),'o-','linewidth',4,'color',[255/255 102/255 0/255])
set(gca,'fontsize',14)
set(gca,'ytick',0:10:50)
saveas(gcf,fullfile(Sdir,'figure','UPDRS_OFF_DORSAL_VENTRAL_n8.pdf'))

figure, plot([all_log_SSRT(subsub).OFF; all_log_SSRT(subsub).DORSAL; ... 
    all_log_SSRT(subsub).VENTRAL],'o-','linewidth',2,'color',[.5 .5 .5])
xlim([.5 3.5]), ylim([0 600])
set(gca,'xtick',[1 2 3])
set(gca,'xticklabel',{'OFF','DORSAL','VENTRAL'})
ylabel('SSRT (ms)')
xlabel('DBS condition')
title('SSRT (ms) (n=8)')
hold on, plot([mean([all_log_SSRT(subsub).OFF]) mean([all_log_SSRT(subsub).DORSAL]) ...
    mean([all_log_SSRT(subsub).VENTRAL])],'o-','linewidth',4,'color',[102/255 153/255 51/255])
set(gca,'fontsize',14)
saveas(gcf,fullfile(Sdir,'figure','SSRT_OFF_DORSAL_VENTRAL_n8.pdf'))

