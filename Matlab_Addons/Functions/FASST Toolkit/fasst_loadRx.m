function Rx = fasst_loadRx( filename )
% Import Rx from a binary file to a MATLAB 4-D complex matrix

    %% Read binary file
    fid = fopen(filename);
    % header
    ndim = fread(fid, 1, 'int');
    siz = fread(fid, ndim, 'int');
    % data
    data = fread(fid, prod(siz), 'float');
    fclose(fid);

    %% Unfold data
    data = reshape(data, siz');
    chans = sqrt(siz(1));
    bins = siz(2);
    frames = siz(3);
    Rx = zeros(bins, frames, chans, chans);
    
    % Unfold real diag elements
    for i=1:chans
        Rx(:, :, i, i) = data(i, :, :);
    end
    
    % Unfold complex elements
    sum = 0;
    for i=1:chans-1
        for j=i+1:chans
            index = (j-i+sum)*2-1+chans;
            Rx(:, :, i, j) = data(index, :, :) + data(index+1, :, :)*1i;
            Rx(:, :, j, i) = conj(Rx(:, :, i, j));
        end
        sum = sum+chans-i;
    end
end
