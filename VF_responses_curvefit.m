function out = vf_responses_curvefit(input)

%% Analysis of VF verbal responses
% Using least squares curve fitting for an exponential function:
% n(t) = c * (1 - e^(-mt) (see Vonberg et al., 2016)
% to estimate c and m, where c is the asymptote ("cappacity of an assumed
% supply") and m is the rate of growth to c - and n(t) is the number of
% words produced at time t.

% One may also consult Ehlen et al. (2015) Psychon Bull Rev for a
% generalization of this exponential function to allow for more varied
% instances of free recall (e.g. reinforced with repetition).

out = [];

conds = {'OFF', 'DORSAL', 'VENTRAL'};
letters = {{'S','P','M','tools'}, {'F','B','L','anim'}, {'K','T','D','fruits'}};
subjs = {'0005_FZU', '0006_VAZ', '0008_ATW', '0009_2QT', '0010_VJD', '0011_1I1'};
ID = subjs{input(1)};

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

Pdir = fullfile('/Users/au183362/Documents/MATLAB/VF_SS_DBS/behavioral/VF_responses/',ID);
filepth = fullfile(Pdir,'segments');
figurepth = fullfile(Pdir,'figures');
analysispth = fullfile(Pdir,'analysis');
megpth = fullfile('/Users/au183362/Documents/MATLAB/VF_SS_DBS/MEG/VF/preproc/', ID);

if ~exist(figurepth,'dir')
    mkdir(figurepth)
end
if ~exist(analysispth,'dir')
    mkdir(analysispth)
end
if ~exist(megpth,'dir')
    mkdir(megpth)
end

fig = figure('position',[40 100 1600 900]);
figloop = 1;

for i = 1%:length(cond_seq)
    for j = 1:2%:length(letters{letter_seq(i)})
        a{i,j} = load(fullfile(filepth,sprintf('%s_%s.mat', conds{cond_seq(i)}, letters{letter_seq(i)}{j})));
        data = [];
        data = a{i,j}.segments;
        
        xdata = data(1,2:end-1); % only using the time points of actual word utterances (not the "artificial" endpoints, i.e. 0 and 60.600)
        ydata = 1:length(data)-2; % and thus the index of number of words produced should only pertain to the actual words produced, i.e. not counting the two endpoints
        
        x0 = [0,0.00001]; % lsqcurvefit apparently can't work with [0,0] as origin, so we use a non-zero value for y that's "practically" 0 in comparison with the 1+ integers of y
        
        fun = @(x,xdata)x(1)*(1-exp(-x(2)*xdata)); % n(t) = c * (1 - e^(-mt)
        
        x = lsqcurvefit(fun,x0,xdata,ydata); % estimates the two values of x, i.e. c and m in ref to the abovementioned equation
        
        % the slope-difference algorithm (see Gruenewald & Lockhead 1980)
        xdiffs = diff(xdata);
        
        xclus = 1./xdiffs-diff(fun(x,xdata))./xdiffs; % 1./xdiffs gives us the observed rate of change (y2-y1)/(x2-x1); and for the predicted values, we get the fitted y-values for the xdata and calculate (y2-y1)/(x2-x1), as well
        xclusidx = xclus > 0; % if the observed "slope" is higher than the predicted one > within cluster, and vice-versa > between clusters
        
        % plotting
        timelin = linspace(data(1,1),data(1,end));
        subplot(3,4,figloop), h = plot(xdata, ydata, 'ko', timelin, fun(x, timelin), 'b-', 'linewidth', 3);
        hold on, hh = plot(xdata([false xclusidx]), ydata([false xclusidx]), 'r+', 'linewidth', 2); % the slope difference algorithm 
        if figloop == 4 || figloop == 8
            legend('observed','predicted','clusters','location','southeast')
        else
            legend('observed','predicted','clusters','location','northwest')
        end
        set(gca,'fontsize',16)
        xlim([0 60])
        ylim([0 20])
        title(sprintf('%s - %s', conds{cond_seq(i)}, letters{letter_seq(i)}{j}))
        
        clus_trl = [data(2,find(xclusidx)+1); data(1,find(xclusidx)+2)]';
        switch_trl = [data(2,find(~xclusidx)+1); data(1,find(~xclusidx)+2)]';
        
        save(fullfile(analysispth,sprintf('%s_%s.mat',conds{cond_seq(i)},letters{letter_seq(i)}{j})), 'data','xdata','ydata','x0','fun','x','xdiffs','xclus', 'xclusidx')
        save(fullfile(megpth,sprintf('%s_%s_trl.mat',conds{cond_seq(i)},letters{letter_seq(i)}{j})), 'clus_trl', 'switch_trl')
        
        figloop = figloop + 1;        
    end
end

set(fig,'Units','Points');
pos = get(fig,'Position');
set(fig,'PaperPositionMode','Auto', 'PaperUnits','Points', 'PaperSize',[pos(3), pos(4)])
% saveas(gcf, fullfile(figurepth,sprintf('%s_all.pdf',ID)))
print(fig, fullfile(figurepth,sprintf('%s_all',ID)), '-dpdf', '-r0')

%%




