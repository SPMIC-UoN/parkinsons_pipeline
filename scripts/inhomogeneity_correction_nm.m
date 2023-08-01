function img_nm = inhomogeneity_correction_nm(img_nm, struc_prior_maps)   
    brainstem_prior_map = struc_prior_maps.l_peduncle_prior + ...
                          struc_prior_maps.r_peduncle_prior + ...
                          struc_prior_maps.l_midbrain_prior + ...
                          struc_prior_maps.r_midbrain_prior;
    
    background_thresh = compute_nm_background_threshold(img_nm);
    roi_indices = find((img_nm(:) > background_thresh) & (brainstem_prior_map(:) > 0));
    num_voxels = numel(roi_indices);
    
    design_matrix = zeros(num_voxels, 10);
    outcome_vector = zeros(num_voxels, 1);
    
    [loc_x, loc_y, loc_z] = ind2sub(size(img_nm), roi_indices);
    
    loc_x_demeaned = loc_x - mean(loc_x);
    loc_y_demeaned = loc_y - mean(loc_y);
    loc_z_demeaned = loc_z - mean(loc_z);
    
    for ind = 1:num_voxels
        x = loc_x_demeaned(ind);
        y = loc_y_demeaned(ind);
        z = loc_z_demeaned(ind);
        xx = x*x;
        xy = x*y;
        xz = x*z;
        yy = y*y;
        yz = y*z;
        zz = z*z;     
        w = 1 + brainstem_prior_map(loc_x(ind), loc_y(ind), loc_z(ind));
        design_matrix(ind,:) = w * [1 x y z xx xy xz yy yz zz];
        outcome_vector(ind) = w * log(img_nm(loc_x(ind), loc_y(ind), loc_z(ind)));
    end
    
    coeffs = regress(outcome_vector, design_matrix);
    
    for ind = 1:num_voxels
        x = loc_x_demeaned(ind);
        y = loc_y_demeaned(ind);
        z = loc_z_demeaned(ind);
        xx = x*x;
        xy = x*y;
        xz = x*z;
        yy = y*y;
        yz = y*z;
        zz = z*z;
        gain = [x y z xx xy xz yy yz zz] * coeffs(2:end);
        img_nm(loc_x(ind), loc_y(ind), loc_z(ind)) = exp(log(img_nm(loc_x(ind), loc_y(ind), loc_z(ind))) - gain);
    end
end
