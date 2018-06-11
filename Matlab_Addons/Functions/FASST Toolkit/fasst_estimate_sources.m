function fasst_estimate_sources( audio_fname, xml_fname, output_dirname )
    if ~exist(output_dirname, 'dir')
        mkdir([output_dirname]);
    end
    fasst_executable_dir = 'C:/Program Files/fasst 2.1.0/bin';
    prog = [fasst_executable_dir '/source-estimation'];
    cmd = ['"' prog '" ' audio_fname ' ' xml_fname, ' ', output_dirname];
    if system(cmd) ~= 0
        throw(MException('', ''))
    end
end

