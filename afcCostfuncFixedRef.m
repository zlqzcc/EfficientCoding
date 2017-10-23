function logll = afcCostfuncFixedRef(prior, refV, refNoise, testV, testNoise, response)

% AFCCOSTFUNCFIXEDREF Cost function for two-alternatice forced choice task  
%             with fixed reference stimulus and corresponding test stimulus.
%             Compute the log likelihood of the data. 

[refMean, refStd] = efficientEstimator(prior, refNoise, refV);

allTestMean = zeros(1, length(testV));
allTestStd  = zeros(1, length(testV));

for i = 1 : length(testV)
    [testMean, testStd] = efficientEstimator(prior, testNoise(i), testV(i));
    allTestMean(i) = testMean; allTestStd(i) = testStd;           
end

%SDT   P(Test > Ref) = 1/2 erfc(-D/2)
dPrimes = (allTestMean - refMean * ones(1, length(testV))) ./ ...
    (sqrt((allTestStd .^ 2 + refStd ^ 2 * ones(1, length(testV))) / 2));
probFaster = 0.5 * erfc(-0.5 * dPrimes);        

% Probability of the response 
probRes = probFaster .* response + (1 - probFaster) .* (1 - response);

% Avoid log(0) for numerical issuses
% Should consider remove outliers 
zeroThreshold = 1e-5;
probRes(probRes == 0) = zeroThreshold;

% Sum of the log likelihood
logll = sum(log(probRes));

end