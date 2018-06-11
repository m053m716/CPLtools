function fasst_writeRx( filename, Rx )
% Write Rx to a binary file 

    fid = fopen(filename, 'w');
    [bins, frames, chans, ~] = size(Rx);

    %% Write header
    % Number of dimensions
    fwrite(fid, 3, 'int');
    % Size in each dimension
    fwrite(fid, [chans*chans, bins, frames], 'int');

    %% Fold data
    data = zeros(frames*bins*chans*chans, 1);
    for k=1:frames
        for j=1:bins
            ind1 = (k-1)*bins*chans*chans + (j-1)*chans*chans;
            
            % Real diagonal elements
            for i=1:chans
                data(ind1+i) = real(Rx(j,k,i,i));
            end
            
            % Complex elements
            sum = 0;
            for i1=1:chans-1
                for i2=i1+1:chans
                    ind2 = ind1 + (i2-i1+sum)*2-1+chans;
                    data(ind2) = real(Rx(j,k,i1,i2));
                    data(ind2+1) = imag(Rx(j,k,i1,i2));
                end
                sum = sum+chans-i1;
            end
        end
    end
    
    %% Write data
    fwrite(fid, data, 'float');
    fclose(fid);
end
