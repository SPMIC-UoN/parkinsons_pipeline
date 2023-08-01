function thresh = compute_nm_background_threshold(nm_data)
    initial_bin = 4;

    nm_data = nm_data(:);
    
    nonzero_mask = (nm_data > 0);
    
    [N,E] = histcounts(nm_data(nonzero_mask), 25);
    [~, max_idx] = max(N(initial_bin:end));
    edge_idx = initial_bin + max_idx - 1; 
    thresh = 0.5 * E(edge_idx);
end

