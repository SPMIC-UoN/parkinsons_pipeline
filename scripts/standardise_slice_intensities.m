function img_data = standardise_slice_intensities(img_data)
    num_slices = size(img_data, 3);
    num_voxels_per_slice = numel(img_data(:,:,1));

    [~,e] = histcounts(img_data(:), 25);
    out_voxels = (img_data < e(2));
    
    % find second data slice
    s_init = 1;
    while sum(sum(out_voxels(:,:,s_init))) >= 0.7 * num_voxels_per_slice
        s_init = s_init + 1;
    end
    s_init = s_init + 1;
    
    for s = s_init:2:num_slices-1
        curr_slice = img_data(:,:,s);
        prev_slice = img_data(:,:,s-1);
        next_slice = img_data(:,:,s+1);
        roi_curr = ~out_voxels(:,:,s);
        roi_prev = ~out_voxels(:,:,s-1);
        roi_next = ~out_voxels(:,:,s+1);
        w_prev = median(prev_slice(roi_prev)) / median(curr_slice(roi_curr));
        w_next = median(next_slice(roi_next)) / median(curr_slice(roi_curr));
        w = (w_prev + w_next) / 2;  
        if isnan(w)
            w = 1;
        end
        img_data(:,:,s) = w .* img_data(:,:,s);
    end
end

