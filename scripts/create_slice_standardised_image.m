function create_slice_standardised_image(base_dir, id, type)
    data_dir = [base_dir '/Original/'];
    
    nm_file = [id '_' type '.nii.gz'];
    nm_file_out = strrep(nm_file, '.nii.gz', '-slice-standardised.nii.gz');

    nii_nm = load_untouch_nii(fullfile(data_dir, nm_file));
    
    nm_data = double(nii_nm.img);
    
    nm_data_out = standardise_slice_intensities(nm_data);
    
    nii_nm_out = nii_nm;
    nii_nm_out.img = nm_data_out;
    nii_nm_out.hdr.dime.bitpix = 32;
    nii_nm_out.hdr.dime.datatype = 16;
    nii_nm_out.hdr.dime.glmin = min(nii_nm_out.img(:));
    nii_nm_out.hdr.dime.glmax = max(nii_nm_out.img(:));

    save_untouch_nii(nii_nm_out, fullfile(data_dir, nm_file_out));
end

