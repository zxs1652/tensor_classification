function tests = test_classification_nd
    tests = functiontests(localfunctions);
end

function test_cmda_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    
    parafac_structure = false;
    k = 2;
    
    [Xs, ys] = get_simple_data();
    nmodes = length(size(Xs{1}));
    
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) CMDA(Xs, ys, [], lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function [Xs, ys] = get_simple_data()
    p = 5;
    q = 7;
    r = 3;
    s = 5;
    nsamples = 200;
    [Xs, ys] = get_data(nsamples, [p, q, r, s]);
end

function project_matrices_verify_predictions(testCase, ...
    projection_learning_function, prediction_function, varargin)

    [Xs, ys] = get_simple_data();
    Xs_test = Xs;
    ys_test = ys;
    k = 2;
    nmodes = length(size(Xs{1}));
    
    lowerdims = repmat(k, 1, nmodes);
    
    Us = projection_learning_function(Xs, ys);
    
    predicted_probabilities = prediction_function(Xs, Xs_test, ys,...
        ys_test, lowerdims, Us);
    
    [~, predictions] = max(predicted_probabilities, [], 2);
    
    accuracy = mean(predictions == ys);
    
    verifyEqual(testCase, accuracy, 1, 'AbsTol', 1e-1)
end



%%%%%%%%%%%%%%%%%%


function test_parafac_lda_discrimination(testCase)
    import matlab.unittest.plugins.StopOnFailuresPlugin
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/manopt/', 'IncludeSubfolders', true));

    parafac_structure = true;
    k = 2;
    
    Xs = get_simple_data();
    
    nmodes = length(size(Xs{1}));
    
    lowerdims = repmat(k, 1, nmodes);
    
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) ManPDA(Xs, ys, lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_parafac_norms_ratio_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/manopt/', 'IncludeSubfolders', true));

    parafac_structure = true;
    k = 2;
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) ManPDA_normsratio(Xs, ys, lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_tucker_lda_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/manopt/', 'IncludeSubfolders', true));

    parafac_structure = false;
    k = 2;
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) ManTDA(Xs, ys, [k, k]), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_tucker_norms_ratio_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/manopt/', 'IncludeSubfolders', true));

    parafac_structure = false;
    k = 2;
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) ManTDA_normsratio(Xs, ys, [k, k]), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_dgtda_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    
    parafac_structure = false;
    k = 2;
    [Xs, ys] = get_simple_data();
    nmodes = length(size(Xs{1}));
    
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) DGTDA(Xs, ys, lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_dater_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    
    parafac_structure = false;
    k = 2;
    [Xs, ys] = get_simple_data();
    nmodes = length(size(Xs{1}));
    
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) DATER(Xs, ys, [], lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_datereig_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    
    parafac_structure = false;
    k = 2;
    [Xs, ys] = get_simple_data();
    nmodes = length(size(Xs{1}));
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) DATEReig(Xs, ys, [], lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end


function test_hoda_discrimination(testCase)
    import matlab.unittest.fixtures.PathFixture
    testCase.applyFixture(PathFixture('../', 'IncludeSubfolders', true));
    testCase.applyFixture(PathFixture('../../../../matlab_additions/02582nway_models/', 'IncludeSubfolders', true));
    
    parafac_structure = false;
    k = 2;
    [Xs, ys] = get_simple_data();
    nmodes = length(size(Xs{1}));
    lowerdims = repmat(k, 1, nmodes);
    
    project_matrices_verify_predictions(testCase, ...
    @(Xs, ys) HODA(Xs, ys, lowerdims), ...
    @(Xs, Xs_test, ys, ys_test, k, Us) ...
    project_and_predict(Xs, Xs_test, ys, ys_test, k, Us, parafac_structure))
end

