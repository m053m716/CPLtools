function fasst_estimate_source_parameters( in_xml_fname, binary_fname, out_xml_fname )
    fasst_executable_dir = 'C:/Program Files/fasst 2.1.0/bin';
    prog = [fasst_executable_dir '/model-estimation'];
    cmd = ['"' prog '" ' in_xml_fname ' ' binary_fname ' ' out_xml_fname];
    if system(cmd) ~= 0
        throw(MException('', ''))
    end
end
