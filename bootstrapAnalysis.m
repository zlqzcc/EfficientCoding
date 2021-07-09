%% Bootstrap (load data beforehand)
load('./NN2006/SUB5.mat');
load('./GaussFit/gauss_final_2.mat');

subject = subject5;
paraSub = paraSub5;
subjectIdx = 5;

[sumLL, fitResults] = weibullFit(subject);
[biasLC_data, biasHC_data, thLC_data, thHC_data] = extractPsychcurve(fitResults, false);

nBootstrap = 500;

allBiasLC = zeros([nBootstrap, size(biasLC_data)]);
allBiasHC = zeros([nBootstrap, size(biasHC_data)]);
allthLC   = zeros([nBootstrap, length(thLC_data)]);
allthHC   = zeros([nBootstrap, length(thHC_data)]);

parfor idx = 1:nBootstrap
    resampleData = resample(subject);
    [sumLL, fitResults] = weibullFit(resampleData);
    [biasLC, biasHC, thLC, thHC] = extractPsychcurve(fitResults, false);
    
    allBiasLC(idx, :, :) = biasLC;
    allBiasHC(idx, :, :) = biasHC;
    allthLC(idx, :) = thLC;
    allthHC(idx, :) = thHC;
end

%% Analysis & Plot
c0 = paraSub(1); c1 = paraSub(2); c2 = paraSub(3);
noiseLevel = paraSub(4:end);

refCrst   = [0.075, 0.5];
crstLevel = [0.05, 0.075, 0.1, 0.2, 0.4, 0.5, 0.8];
vProb     = [0.5, 1, 2, 4, 8, 12];
vRef      = [0.5, 1, 2, 4, 8, 12];

% Computing Prior Probability
domain    = -100 : 0.01 : 100;
priorUnm  = 1.0 ./ ((abs(domain) .^ c0) + c1) + c2;
nrmConst  = 1.0 / (trapz(domain, priorUnm));
prior = @(support) (1.0 ./ ((abs(support) .^ c0) + c1) + c2) * nrmConst;

figure; hold on;
addpath('./cbrewer/');
colormap = cbrewer('seq', 'Greys', 9);
colors = colormap(flip([9, 7, 6, 5, 3]), :);

plotBiasBayes(prior, noiseLevel, 0.075, colors);
plotWeibullLine(biasLC_data, allBiasLC, nBootstrap, colors);
xlabel('Speed V [deg/sec]'); ylabel('Matching Speed: $\frac{V_{1}}{V_{0}}$', 'Interpreter', 'latex');
xticks(log(vRef)); xticklabels(arrayfun(@num2str, vRef, 'UniformOutput', false));
title(sprintf('Subject %d Matching Speed - Low Contrast', subjectIdx));
ylim([0.2, 1.6]);

figure; hold on;
plotBiasBayes(prior, noiseLevel, 0.5, colors);
plotWeibullLine(biasHC_data, allBiasHC, nBootstrap, colors);
xlabel('Speed V [deg/sec]'); ylabel('Matching Speed: $\frac{V_{1}}{V_{0}}$', 'Interpreter', 'latex');
xticks(log(vRef)); xticklabels(arrayfun(@num2str, vRef, 'UniformOutput', false));
title(sprintf('Subject %d Matching Speed - High Contrast', subjectIdx));
ylim([0.6, 2.2]);

%% Threshold
figure; hold on;
% colors = get(gca,'colororder');

colormap = cbrewer('seq', 'Greys', 9);
colors = colormap([5, 9], :);

relative = false; sd = false; logSpace = true;
t1 = plotWeibullThres(thLC_data, allthLC, colors(1, :), relative, sd, logSpace);
plotThresBayes(prior, noiseLevel, 0.075, colors(1, :),  relative, logSpace);
t2 = plotWeibullThres(thHC_data, allthHC, colors(2, :), relative, sd, logSpace);
plotThresBayes(prior, noiseLevel, 0.5, colors(2, :),    relative, logSpace);

if relative
    yticklabels(arrayfun(@(x)num2str(x, '%.2f'), yticks, 'UniformOutput', false));
    ylabel('Weber Fraction');
elseif logSpace
    yticklabels(arrayfun(@(x)num2str(x, '%.2f'), exp(yticks), 'UniformOutput', false));
    ylabel('Threshold');
else
    ylim([0, 4]);
    ylabel('Threshold');
end

if (~logSpace) && (~relative)
    xlabel('Speed V [deg/sec]');
    xticks(vProb);
    xticklabels(arrayfun(@num2str, vProb, 'UniformOutput', false));
    legend([t1, t2], {'0.075', '0.5'});
    title(sprintf('Subject %d Threshold', subjectIdx));
else
    xlabel('Speed V [deg/sec]');
    xticks(log(vProb));
    xticklabels(arrayfun(@num2str, vProb, 'UniformOutput', false));
    legend([t1, t2], {'0.075', '0.5'});
    title(sprintf('Subject %d Threshold', subjectIdx));    
end
