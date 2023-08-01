function struc_posterior_maps = compute_posteriors(img, struc_prior_maps)
    %warning('off', 'stats:gmdistribution:FailedToConvergeReps');

    background_prior_map = struc_prior_maps.background_prior;
    l_sn_prior_map = struc_prior_maps.l_sn_prior;
    r_sn_prior_map = struc_prior_maps.r_sn_prior;
    l_peduncle_prior_map = struc_prior_maps.l_peduncle_prior;
    r_peduncle_prior_map = struc_prior_maps.r_peduncle_prior;
    l_midbrain_prior_map = struc_prior_maps.l_midbrain_prior;
    r_midbrain_prior_map = struc_prior_maps.r_midbrain_prior;
    
    img_size = size(img);
    max_iterations = 20;
    roi_voxels = (background_prior_map(:) + ...
                  l_sn_prior_map(:) + ...
                  r_sn_prior_map(:) + ...
                  l_peduncle_prior_map(:) + ...
                  r_peduncle_prior_map(:) + ...
                  l_midbrain_prior_map(:) + ...
                  r_midbrain_prior_map(:) > 0.9) & (img(:) > 0);

    img_data = img(roi_voxels);
    
    background_prior_prob = background_prior_map(roi_voxels);
    l_sn_prior_prob = l_sn_prior_map(roi_voxels);
    r_sn_prior_prob = r_sn_prior_map(roi_voxels);
    l_peduncle_prior_prob = l_peduncle_prior_map(roi_voxels);
    r_peduncle_prior_prob = r_peduncle_prior_map(roi_voxels);
    l_midbrain_prior_prob = l_midbrain_prior_map(roi_voxels);
    r_midbrain_prior_prob = r_midbrain_prior_map(roi_voxels);
    
    scores_background = background_prior_prob;
    scores_l_sn = l_sn_prior_prob;
    scores_r_sn = r_sn_prior_prob;
    scores_l_peduncle = l_peduncle_prior_prob;
    scores_r_peduncle = r_peduncle_prior_prob;
    scores_l_midbrain = l_midbrain_prior_prob;
    scores_r_midbrain = r_midbrain_prior_prob;
    
    background_voxels = (scores_background > scores_l_sn) & (scores_background > scores_r_sn) & (scores_background > scores_l_peduncle) & (scores_background > scores_r_peduncle) & (scores_background > scores_l_midbrain) & (scores_background > scores_r_midbrain);
    l_sn_voxels = (scores_l_sn > scores_background) & (scores_l_sn > scores_r_sn) & (scores_l_sn > scores_l_peduncle) & (scores_l_sn > scores_r_peduncle) & (scores_l_sn > scores_l_midbrain) & (scores_l_sn > scores_r_midbrain);
    r_sn_voxels = (scores_r_sn > scores_background) & (scores_r_sn > scores_l_sn) & (scores_r_sn > scores_l_peduncle) & (scores_r_sn > scores_r_peduncle) & (scores_r_sn > scores_l_midbrain) & (scores_r_sn > scores_r_midbrain);
    l_peduncle_voxels = (scores_l_peduncle > scores_background) & (scores_l_peduncle > scores_l_sn) & (scores_l_peduncle > scores_r_sn) & (scores_l_peduncle > scores_r_peduncle) & (scores_l_peduncle > scores_l_midbrain) & (scores_l_peduncle > scores_r_midbrain);
    r_peduncle_voxels = (scores_r_peduncle > scores_background) & (scores_r_peduncle > scores_l_sn) & (scores_r_peduncle > scores_r_sn) & (scores_r_peduncle > scores_l_peduncle) & (scores_r_peduncle > scores_l_midbrain) & (scores_r_peduncle > scores_r_midbrain);
    l_midbrain_voxels = (scores_l_midbrain > scores_background) & (scores_l_midbrain > scores_l_sn) & (scores_l_midbrain > scores_r_sn) & (scores_l_midbrain > scores_l_peduncle) & (scores_l_midbrain > scores_r_peduncle) & (scores_l_midbrain > scores_r_midbrain);
    r_midbrain_voxels = (scores_r_midbrain > scores_background) & (scores_r_midbrain > scores_l_sn) & (scores_r_midbrain > scores_r_sn) & (scores_r_midbrain > scores_l_peduncle) & (scores_r_midbrain > scores_r_peduncle) & (scores_r_midbrain > scores_l_midbrain);
    
    for i = 1:max_iterations
        data_background = img_data(background_voxels);
        data_l_sn = img_data(l_sn_voxels);
        data_r_sn = img_data(r_sn_voxels);
        data_l_peduncle = img_data(l_peduncle_voxels);
        data_r_peduncle = img_data(r_peduncle_voxels);
        data_l_midbrain = img_data(l_peduncle_voxels);
        data_r_midbrain = img_data(r_peduncle_voxels);
        
        pd_background = fitgmdist(data_background, 3, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_l_sn = fitgmdist(data_l_sn, 2, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_r_sn = fitgmdist(data_r_sn, 2, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_l_peduncle = fitgmdist(data_l_peduncle, 1, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_r_peduncle = fitgmdist(data_r_peduncle, 1, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_l_midbrain = fitgmdist(data_l_midbrain, 1, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_r_midbrain = fitgmdist(data_r_midbrain, 1, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        
        scores_background = pdf(pd_background, img_data) .* background_prior_prob;
        scores_l_sn = pdf(pd_l_sn, img_data) .* l_sn_prior_prob;
        scores_r_sn = pdf(pd_r_sn, img_data) .* r_sn_prior_prob;
        scores_l_peduncle = pdf(pd_l_peduncle, img_data) .* l_peduncle_prior_prob;
        scores_r_peduncle = pdf(pd_r_peduncle, img_data) .* r_peduncle_prior_prob;
        scores_l_midbrain = pdf(pd_l_midbrain, img_data) .* l_midbrain_prior_prob;
        scores_r_midbrain = pdf(pd_r_midbrain, img_data) .* r_midbrain_prior_prob;

        background_voxels_new = (scores_background > scores_l_sn) & (scores_background > scores_r_sn) & (scores_background > scores_l_peduncle) & (scores_background > scores_r_peduncle) & (scores_background > scores_l_midbrain) & (scores_background > scores_r_midbrain);
        l_sn_voxels_new = (scores_l_sn > scores_background) & (scores_l_sn > scores_r_sn) & (scores_l_sn > scores_l_peduncle) & (scores_l_sn > scores_r_peduncle) & (scores_l_sn > scores_l_midbrain) & (scores_l_sn > scores_r_midbrain);
        r_sn_voxels_new = (scores_r_sn > scores_background) & (scores_r_sn > scores_l_sn) & (scores_r_sn > scores_l_peduncle) & (scores_r_sn > scores_r_peduncle) & (scores_r_sn > scores_l_midbrain) & (scores_r_sn > scores_r_midbrain);
        l_peduncle_voxels_new = (scores_l_peduncle > scores_background) & (scores_l_peduncle > scores_l_sn) & (scores_l_peduncle > scores_r_sn) & (scores_l_peduncle > scores_r_peduncle) & (scores_l_peduncle > scores_l_midbrain) & (scores_l_peduncle > scores_r_midbrain);
        r_peduncle_voxels_new = (scores_r_peduncle > scores_background) & (scores_r_peduncle > scores_l_sn) & (scores_r_peduncle > scores_r_sn) & (scores_r_peduncle > scores_l_peduncle) & (scores_r_peduncle > scores_l_midbrain) & (scores_r_peduncle > scores_r_midbrain);
        l_midbrain_voxels_new = (scores_l_midbrain > scores_background) & (scores_l_midbrain > scores_l_sn) & (scores_l_midbrain > scores_r_sn) & (scores_l_midbrain > scores_l_peduncle) & (scores_l_midbrain > scores_r_peduncle) & (scores_l_midbrain > scores_r_midbrain);
        r_midbrain_voxels_new = (scores_r_midbrain > scores_background) & (scores_r_midbrain > scores_l_sn) & (scores_r_midbrain > scores_r_sn) & (scores_r_midbrain > scores_l_peduncle) & (scores_r_midbrain > scores_r_peduncle) & (scores_r_midbrain > scores_l_midbrain);
    
        diff_background = sum(background_voxels ~= background_voxels_new);
        diff_l_sn = sum(l_sn_voxels ~= l_sn_voxels_new);
        diff_r_sn = sum(r_sn_voxels ~= r_sn_voxels_new);
        diff_l_peduncle = sum(l_peduncle_voxels ~= l_peduncle_voxels_new);
        diff_r_peduncle = sum(r_peduncle_voxels ~= r_peduncle_voxels_new);
        diff_l_midbrain = sum(l_midbrain_voxels ~= l_midbrain_voxels_new);
        diff_r_midbrain = sum(r_midbrain_voxels ~= r_midbrain_voxels_new);
        
        if (diff_background + diff_l_sn + diff_r_sn + diff_l_peduncle + diff_r_peduncle + diff_l_midbrain + diff_r_midbrain) <= floor(0.001 * sum(roi_voxels))
            break;
        else
            background_voxels = background_voxels_new;
            l_sn_voxels = l_sn_voxels_new;
            r_sn_voxels = r_sn_voxels_new;
            l_peduncle_voxels = l_peduncle_voxels_new;
            r_peduncle_voxels = r_peduncle_voxels_new;
            l_midbrain_voxels = l_midbrain_voxels_new;
            r_midbrain_voxels = r_midbrain_voxels_new;
        end
    end
    
    norm_factor = scores_background + scores_l_sn + scores_r_sn + scores_l_peduncle + scores_r_peduncle + scores_l_midbrain + scores_r_midbrain + eps;
    
    struc_posterior_maps.background_posterior = zeros(img_size);
    struc_posterior_maps.background_posterior(roi_voxels) = scores_background ./ norm_factor;
    struc_posterior_maps.l_sn_posterior = zeros(img_size);
    struc_posterior_maps.l_sn_posterior(roi_voxels) = scores_l_sn ./ norm_factor;
    struc_posterior_maps.r_sn_posterior = zeros(img_size);
    struc_posterior_maps.r_sn_posterior(roi_voxels) = scores_r_sn ./ norm_factor;
    struc_posterior_maps.l_peduncle_posterior = zeros(img_size);
    struc_posterior_maps.l_peduncle_posterior(roi_voxels) = scores_l_peduncle ./ norm_factor;
    struc_posterior_maps.r_peduncle_posterior = zeros(img_size);
    struc_posterior_maps.r_peduncle_posterior(roi_voxels) = scores_r_peduncle ./ norm_factor;
    struc_posterior_maps.l_midbrain_posterior = zeros(img_size);
    struc_posterior_maps.l_midbrain_posterior(roi_voxels) = scores_l_midbrain ./ norm_factor;
    struc_posterior_maps.r_midbrain_posterior = zeros(img_size);
    struc_posterior_maps.r_midbrain_posterior(roi_voxels) = scores_r_midbrain ./ norm_factor;
    
    %warning('on', 'stats:gmdistribution:FailedToConvergeReps');
end

