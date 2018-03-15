load('./AllFitRes/weibullFitAll.mat');
load('./AllFitRes/BayesianFitAll1.mat');

subIdx = 1;
allPara = [paraSub1; paraSub2; paraSub3; paraSub4; paraSub5];
paraSub = allPara(subIdx, :);

c0 = paraSub(1); c1 = paraSub(2); c2 = paraSub(3);
noiseLevel = paraSub(4:end);
plotResults(c0, c1, c2, noiseLevel, weibullFit1, 'Subject1: ');

function plotResults(c0, c1, c2, noiseLevel, weibullPara, titleText)

refCrst    = [0.075, 0.5];
crstLevel  = [0.05, 0.075, 0.1, 0.2, 0.4, 0.5, 0.8];
vProb      = [0.5, 1, 2, 4, 8, 12];

domain    = -100 : 0.01 : 100; 
priorUnm  = 1.0 ./ (c1 * (abs(domain) .^ c0) + c2);
nrmConst  = 1.0 / (trapz(domain, priorUnm));
prior = @(support) (1 ./ (c1 * (abs(support) .^ c0) + c2)) * nrmConst; 

% Shape of Prior 
figure; priorSupport = (0 : 0.01 : 15);
plot(log(priorSupport), log(prior(priorSupport)), 'LineWidth', 2);
title(strcat(titleText, 'Prior'));
xlabel('log V'); ylabel('log P(V)');

% Matching Speed
plotMatchSpeed(0.075); 
plotMatchSpeed(0.5);

% Threshold
figure; hold on; grid on;
plotThreshold(0.075, true);
plotThreshold(0.5, true);
title(strcat(titleText, 'Relative Threshold'));

    function plotMatchSpeed(refCrstLevel)
        vRef = 0.5 : 0.1 : 12; baseNoise = noiseLevel(crstLevel == refCrstLevel);
        estVRef = @(vRef) efficientEstimator(prior, baseNoise, vRef);
        estiVRef = arrayfun(estVRef, vRef);

        figure; hold on; grid on;
        colors = get(gca,'colororder');
        testCrst = [0.05, 0.1, 0.2, 0.4, 0.8];
        
        % Plot matching speed computed from Bayesian fit
        for i = 1 : length(testCrst)
            vTest = 0.05 : 0.005 : 24; baseNoise = noiseLevel(crstLevel == testCrst(i));
            estVTest = @(vTest) efficientEstimator(prior, baseNoise, vTest);
            estiVTest = arrayfun(estVTest, vTest);

            sigma = 0.01; vTestMatch = zeros(1, length(vRef));            
            for j = 1 : length(vRef)
                targetEst = estiVRef(j);
                vTestMatch(j) = mean(vTest(estiVTest > targetEst - sigma & estiVTest < targetEst + sigma));
            end
            plot(log(vRef), vTestMatch ./ vRef, 'LineWidth', 2); 
        end        
        
        % Plot matching speed computed from Weibull fit
        vRef = [0.5, 1, 2, 4, 8, 12]; 
        for i = 1 : length(testCrst)
            vMatch = zeros(1, length(vRef)); 
            for j = 1 : length(vRef)
                para = weibullPara(refCrst == refCrstLevel, vProb == vRef(j), crstLevel == testCrst(i), :);
                
                candV = 0 : 0.001 : vRef(j) + 10;  
                targetProb = 0.5; delta = 0.01;
                probCorrect = wblcdf(candV, para(1), para(2));
                
                vMatch(j) = mean(candV(probCorrect > targetProb - delta & probCorrect < targetProb + delta));
            end
            plot(log(vRef), vMatch ./ vRef, '--o', 'Color', colors(i, :));
        end
        
        title(strcat(titleText, 'Matching Speed'));
        xlabel('log V'); ylabel('Matching Speed: $\frac{V_{1}}{V_{0}}$', 'Interpreter', 'latex');
        xticks(log(vRef)); xticklabels(arrayfun(@num2str, vRef, 'UniformOutput', false));
        
    end

    function plotThreshold(refCrstLevel, relative)
        targetDPrime = 0.955; sigma = 0.005;
        vRef = 0.5 : 0.2 : 12; baseNoise = noiseLevel(crstLevel == refCrstLevel);
        thresholdV = zeros(1, length(vRef));
                
        for i = 1 : length(vRef)
            [meanRef, stdRef] = efficientEstimator(prior, baseNoise, vRef(i));
            
            deltaL = 0; deltaH = 20;
            deltaEst = (deltaL + deltaH) / 2;
            [meanTest, stdTest] = efficientEstimator(prior, baseNoise, vRef(i) + deltaEst);
            dPrime = (meanTest - meanRef) / sqrt((stdTest ^ 2 + stdRef ^ 2) / 2);
            
            while(dPrime < targetDPrime - sigma || dPrime > targetDPrime + sigma)
                if dPrime > targetDPrime
                   deltaH = deltaEst; 
                else
                   deltaL = deltaEst;
                end
                
                deltaEst = (deltaL + deltaH) / 2;
                [meanTest, stdTest] = efficientEstimator(prior, baseNoise, vRef(i) + deltaEst);
                dPrime = (meanTest - meanRef) / sqrt((stdTest ^ 2 + stdRef ^ 2) / 2);                        
            end
            thresholdV(i) = deltaEst;
        end
        
        if relative
            plot(log(vRef), thresholdV ./ vRef, 'LineWidth', 2);
        else
            plot(log(vRef), log(thresholdV), 'LineWidth', 2);
        end
        
        thresholdV = zeros(1, length(vProb));
        targetC = 0.75; sigma = 0.001;
        
        for x = 1 : length(vProb)
            para = weibullPara(refCrst == refCrstLevel, vProb == vProb(x), crstLevel == refCrstLevel, :);
            deltaV = 0 : 0.0001 : 10; testV = vProb(x) + deltaV; 
            probC = wblcdf(testV, para(1), para(2));
            
            thresholdV(x) = mean(deltaV(probC > targetC - sigma & probC < targetC + sigma));
        end
        
        if relative
            plot(log(vProb), thresholdV ./ vProb, '--o');
            ylabel('Relative Threshold');
        else
            plot(log(vProb), log(thresholdV), '--o');
            ylabel('Absolute Threshold');
        end
                
        xlabel('log V');         
        xticks(log(vProb)); 
        xticklabels(arrayfun(@num2str, vProb, 'UniformOutput', false));                
    end
end



