function struc_posterior_maps = compute_posteriors(img, struc_prior_maps)
    %warning('off', 'stats:gmdistribution:FailedToConvergeReps');

    background_prior_map = struc_prior_maps.background_prior;
    brainstem_prior_map = struc_prior_maps.brainstem_prior;
    l_sn_prior_map = struc_prior_maps.l_sn_prior;
    r_sn_prior_map = struc_prior_maps.r_sn_prior;
    
    img_size = size(img);
    max_iterations = 20;

    roi_voxels = (background_prior_map(:) + brainstem_prior_map(:) + l_sn_prior_map(:) + r_sn_prior_map(:) > 0.999) & (img(:) > 0);

    img_data = img(roi_voxels);
    
    background_prior_prob = background_prior_map(roi_voxels);
    brainstem_prior_prob = brainstem_prior_map(roi_voxels);
    l_sn_prior_prob = l_sn_prior_map(roi_voxels);
    r_sn_prior_prob = r_sn_prior_map(roi_voxels);
    
    scores_background = background_prior_prob;
    scores_brainstem = brainstem_prior_prob;
    scores_l_sn = l_sn_prior_prob;
    scores_r_sn = r_sn_prior_prob;
    
    background_voxels = (scores_background > scores_brainstem) & (scores_background > scores_l_sn) & (scores_background > scores_r_sn);
    brainstem_voxels = (scores_brainstem > scores_background) & (scores_brainstem > scores_l_sn) & (scores_brainstem > scores_r_sn);
    l_sn_voxels = (scores_l_sn > scores_background) & (scores_l_sn > scores_brainstem) & (scores_l_sn > scores_r_sn);
    r_sn_voxels = (scores_r_sn > scores_background) & (scores_r_sn > scores_brainstem) & (scores_r_sn > scores_l_sn);
    
    for i = 1:max_iterations
        data_background = img_data(background_voxels);
        data_brainstem = img_data(brainstem_voxels);
        data_l_sn = img_data(l_sn_voxels);
        data_r_sn = img_data(r_sn_voxels);
        
        pd_background = fitgmdist(data_background, 3, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_brainstem = fitgmdist(data_brainstem, 1, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_l_sn = fitgmdist(data_l_sn, 2, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        pd_r_sn = fitgmdist(data_r_sn, 2, 'Replicates', 10, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 750));
        
        scores_background = pdf(pd_background, img_data) .* background_prior_prob;
        scores_brainstem = pdf(pd_brainstem, img_data) .* brainstem_prior_prob;
        scores_l_sn = pdf(pd_l_sn, img_data) .* l_sn_prior_prob;
        scores_r_sn = pdf(pd_r_sn, img_data) .* r_sn_prior_prob;

        background_voxels_new = (scores_background > scores_brainstem) & (scores_background > scores_l_sn) & (scores_background > scores_r_sn);
        brainstem_voxels_new = (scores_brainstem > scores_background) & (scores_brainstem > scores_l_sn) & (scores_brainstem > scores_r_sn);
        l_sn_voxels_new = (scores_l_sn > scores_background) & (scores_l_sn > scores_brainstem) & (scores_l_sn > scores_r_sn);
        r_sn_voxels_new = (scores_r_sn > scores_background) & (scores_r_sn > scores_brainstem) & (scores_r_sn > scores_l_sn);

        diff_background = sum(background_voxels ~= background_voxels_new);
        diff_brainstem = sum(brainstem_voxels ~= brainstem_voxels_new);
        diff_l_sn = sum(l_sn_voxels ~= l_sn_voxels_new);
        diff_r_sn = sum(r_sn_voxels ~= r_sn_voxels_new);

        if (diff_background + diff_brainstem + diff_l_sn + diff_r_sn) <= floor(0.001 * sum(roi_voxels))
            break;
        else
            background_voxels = background_voxels_new;
            brainstem_voxels = brainstem_voxels_new;
            l_sn_voxels = l_sn_voxels_new;
            r_sn_voxels = r_sn_voxels_new;
        end
    end
    
    norm_factor = scores_background + scores_brainstem + scores_l_sn + scores_r_sn + eps;
    
    struc_posterior_maps.background_posterior = zeros(img_size);
    struc_posterior_maps.background_posterior(roi_voxels) = scores_background ./ norm_factor;
    struc_posterior_maps.brainstem_posterior = zeros(img_size);
    struc_posterior_maps.brainstem_posterior(roi_voxels) = scores_brainstem ./ norm_factor;
    struc_posterior_maps.l_sn_posterior = zeros(img_size);
    struc_posterior_maps.l_sn_posterior(roi_voxels) = scores_l_sn ./ norm_factor;
    struc_posterior_maps.r_sn_posterior = zeros(img_size);
    struc_posterior_maps.r_sn_posterior(roi_voxels) = scores_r_sn ./ norm_factor;
    
    %warning('on', 'stats:gmdistribution:FailedToConvergeReps');
end

