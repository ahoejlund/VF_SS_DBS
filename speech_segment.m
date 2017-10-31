function out = speech_segment(input)

%% Identifying speech sections in verbal fluency recordings

% VF_SS_DBS
% 2017-08-24
out = [];

Pdir = '/Users/au183362/Documents/MATLAB/VF_SS_DBS/behavioral/VF_responses/';

subjs = {'0005_FZU', '0006_VAZ', '0008_ATW', '0009_2QT', '0010_VJD', '0011_1I1'};

letters = {{'S','P','M','tools'}, {'F','B','L','anim'}, {'K','T','D','fruits'}};

conds = {'OFF','DORSAL','VENTRAL'};

cond_seqs = [2 1 3; % 0005
    1 2 3; % 0006
    1 2 3; % 0008
    1 3 2; % 0009
    1 3 2; % 0010
    1 2 3]; % 0011
cond_seq = cond_seqs(input(1),:);

letter_seqs = [1 2 3; % 0005
    1 3 2; % 0006
    2 3 1; % 0008
    3 1 2; % 0009
    3 2 1; % 0010
    1 2 3]; % 0011
letter_seq = letter_seqs(input(1),:);

subj = subjs{input(1)};
Wdir = fullfile(Pdir, subj, 'responses');

for c = 1:length(conds)
    for l = 1:length(letters{letter_seq(c)})
        cond = sprintf('%s_%s%s%s',conds{cond_seq(c)},letters{letter_seq(c)}{1:3}); % 'F'='FBL_animals'; 'K'='KTD_fruits'; 'S'='SPM_tools'; 'V'='VENTRAL; 'D'='DORSAL'; 'O'='OFF'
        letter = letters{letter_seq(c)}{l};
        vf_files = dir(fullfile(Wdir,'*.wav'));
        for i = length(vf_files):-1:1
            reg = regexp(vf_files(i).name, '-\d{14,14}');
            vf_dates(i,:) = vf_files(i).name(reg+1:reg+14);
        end
        [~, idx] = sortrows(vf_dates);
        letter_idx = idx(1+(c-1)*4:4+(c-1)*4);
        filename = vf_files(letter_idx(l)).name;
        
        Sdir = fullfile(Pdir,subj,cond,sprintf('%s_pre',letter));
        if ~exist(Sdir,'dir')
            mkdir(Sdir)
        end
        
        % load (denoised) audiofile
        [y, fs] = audioread(fullfile(Wdir,filename));
        if size(y,2) == 2
            y = y(:,1);
        end
        
        % filter
        n = 2; % filter order
        highp = 30; % highpass cutoff
        
        % threshold
        thr = 0.7; % threshold set to 1/2 standard deviation
        speech_dur = floor(0.200*fs); % setting minimum speech duration to 200 ms
        gaps_dur = floor([0.100*fs 0.050*fs 0.100*fs 0.100*fs 0.050*fs 0.050*fs]); % setting minimum gap duration to 50 ms
        
        %% load audio, process the file, and plot it
        
        % highpass
        [b,a] = butter(n,highp/(fs/2),'high');
        yfilt = filter(b,a,y);
        
        % normalize (using z-scoring)
        % yfiltz = zscore(yfilt);
        yfiltz = [1; zscore(yfilt); 1];
        
        % threshold in order to identify speech onsets (and offsets)
        ythresh = abs(yfiltz)>thr;
        ythreshidx = find(ythresh); % get the timing indices of all speech (aka. sound) segments
        ydiffs = diff(ythreshidx); % get the durations between these timings
        ydiffsidx = find(ydiffs>gaps_dur(input(1))); % filter in all gaps longer than 50 ms (which we then regard as a genuine pause)    
        offsetidx = ythreshidx(ydiffs>gaps_dur(input(1))); % get the timing of the onsets of these pauses (aka. onset of speech segments)
        onsetidx = ythreshidx(ydiffsidx+1); % due to the nature of the selection process the index of pause-onset+1 will be the offset of the pause, and hence the onset of the next speech segment

        onsetidx_clean = [onsetidx(diff([onsetidx(1:end-1) offsetidx(2:end)],1,2)>speech_dur); onsetidx(end)]; % by comparing speech onset and offset (offset by 1 compared to each other), we get the duration of the speech segments - any segments shorter than 200 ms should be discarded
        offsetidx_clean = [offsetidx(1); offsetidx(find((diff([onsetidx(1:end-1) offsetidx(2:end)],1,2)>speech_dur))+1)]; % and we thus discard both onset and offset for that pseudo-speech-segment
        
%         if strcmp('0010_VJD',subj) && c == 2 && l == 4
%             extrathresh = find(ythresh(onsetidx_clean(12):offsetidx_clean(13)));
%             extradiffs = diff(extrathresh);
%             idxextra = find(extradiffs>0.015*fs);
%             if ~isempty(idxextra)
%                 onsetidx_clean = [onsetidx_clean(1:12,:); onsetidx_clean(12)+extrathresh(idxextra); onsetidx_clean(12+1:end,:)];
%                 offsetidx_clean = [offsetidx_clean(1:13,:); offsetidx_clean(13)+extrathresh(idxextra+1); offsetidx_clean(13+1:end,:)];
%             end
%         end
        
        
        figure, plot(yfiltz)
        
        hold on, bar(onsetidx_clean,ones(length(onsetidx_clean),1),0.2,'r')
        hold on, bar(offsetidx_clean,ones(length(offsetidx_clean),1),0.2,'c')
        hold on, plot(onsetidx(diff([onsetidx(1:end-1) offsetidx(2:end)],1,2)<speech_dur),ones(length(onsetidx(diff([onsetidx(1:end-1) offsetidx(2:end)],1,2)<speech_dur)),1),'ro')
        title(sprintf('%s - %s (%s) - #words: %d; #reject: %d', subj(1:4), letter, conds{cond_seq(c)}, length(onsetidx_clean)-1, length(onsetidx)-length(onsetidx_clean)))
        ylim([-2 2])
        xlim([-30000 2700000])
        set(gca,'xticklabel',num2cell(round(get(gca,'xtick')./fs)))
        set(gcf,'PaperOrientation','landscape')
        set(gcf,'PaperUnits','normalized')
        set(gcf,'PaperPosition',[0 0 1 1])
        saveas(gcf,fullfile(Sdir,sprintf('%s_full.pdf',letter)),'pdf')
        
        
        %% Create two textfiles with onsets and offsets for both pauses and speech segments
        
        % SPEECH
        cd(Sdir)
        fid = fopen(sprintf('speech_%s_%s_%s.txt',subj,cond,letter),'w');
        fprintf(fid,'%s,%s,%s\n',subj,cond,letter);
        fprintf(fid,'%s,%s,%s\n','word#','onset','offset');
        for i = 1:length(onsetidx_clean)-1
            fprintf(fid,'%d,%0.4f,%0.4f\n', i, onsetidx_clean(i)/fs, offsetidx_clean(i+1)/fs);
        end
        fclose(fid);
        
        % PAUSES
        cd(Sdir)
        fid = fopen(sprintf('pauses_%s_%s_%s.txt',subj,cond,letter),'w');
        fprintf(fid,'%s,%s,%s\n',subj,cond,letter);
        fprintf(fid,'%s,%s,%s\n','pause#','onset','offset');
        for i = 1:length(offsetidx_clean)
            fprintf(fid,'%d,%0.4f,%0.4f\n', i, offsetidx_clean(i)/fs, onsetidx_clean(i)/fs); % offsets are pause onsets, and onsets are pause offsets
        end
        fclose(fid);
        
        
        %% Create sound bites for each word (and number them)
        
        for i = 1:length(onsetidx_clean)-1
            audiowrite(fullfile(Sdir,sprintf('%s_%d.wav',letter,i)),repmat(y(onsetidx_clean(i)-speech_dur:offsetidx_clean(i+1)+speech_dur),1,2),fs);
        end
        audiowrite(fullfile(Sdir,sprintf('%s_%s_%s.wav',subj,conds{cond_seq(c)},letter)),repmat(y,1,2),fs);
        
        %% Create individual figures for all pauses and speech segments
        
        %SPEECH
        figure,
        count = 0;
        for i = 1:length(onsetidx_clean)-1
            count = count + 1;
            if length(onsetidx_clean)-1>30
                subplot(5,8,count)
            else
                subplot(5,6,count)
            end
            plot(yfiltz(onsetidx_clean(i)-gaps_dur(input(1)):offsetidx_clean(i+1)+gaps_dur(input(1))));
            %     hold on, bar(onsetidx_clean(i)-onsetidx_clean(i),5,0.5,'r')
            %     hold on, bar(offsetidx_clean(i+1)-onsetidx_clean(i),5,0.5,'c')
            if count == 1
                title(sprintf('%s - %s', subj(1:4), letter))
            else
                title(sprintf('word %d', i))
            end
            ylim([-10 10])
            xlim([-5000 85000])
            set(gca,'xticklabel',round(get(gca,'xtick')./fs,1))
        end
        % set(gca,'xticklabel',num2cell(round(get(gca,'xtick')./fs)))
        set(gcf,'PaperOrientation','landscape')
        set(gcf,'PaperUnits','normalized')
        set(gcf,'PaperPosition',[0 0 1 1])
        saveas(gcf,fullfile(Sdir,sprintf('%s_all_words.pdf',letter)),'pdf')
        
        %%
        
        %PAUSES
        figure,
        count = 0;
        for i = 1:length(offsetidx_clean)
            count = count + 1;
            if length(offsetidx_clean)>30
                subplot(5,8,count)
            else
                subplot(5,6,count)
            end
            plot(yfiltz(offsetidx_clean(i):onsetidx_clean(i)));
            %     hold on, bar(onsetidx_clean(i)-onsetidx_clean(i),5,0.5,'r')
            %     hold on, bar(offsetidx_clean(i+1)-onsetidx_clean(i),5,0.5,'c')
            if count == 1
                title(sprintf('%s - %s', subj(1:4), letter))
            else
                title(sprintf('pause %d', i))
            end
            ylim([-1 1])
            xlim([-2*fs 15*fs])
            set(gca,'xticklabel',round(get(gca,'xtick')./fs,1))
        end
        set(gcf,'PaperOrientation','landscape')
        set(gcf,'PaperUnits','normalized')
        set(gcf,'PaperPosition',[0 0 1 1])
        saveas(gcf,fullfile(Sdir,sprintf('%s_all_pauses.pdf',letter)),'pdf')
        close all
    end    
end

