function fasst_compute_mixture_covariance_matrix( audio_fname, xml_fname, binary_fname )
    fasst_executable_dir = 'C:/Program Files/fasst 2.1.0/bin';
    prog = [fasst_executable_dir '/comp-rx'];
    cmd = ['"' prog '" ' audio_fname ' ' xml_fname ' ' binary_fname];
    if system(cmd) ~= 0
        throw(MException('', ''))
    end
end
