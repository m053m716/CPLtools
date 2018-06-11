function dl = driveletter

% Handle -nofloppy flag, or lack thereof.
startletter = 'c';
retRow = 1;

% Initialize return cell array
ret = {}; %cell(numel(double(startletter):double('e')),1);

% Look for single-letter drives, starting at a: or c: as appropriate
for i = double(startletter):double('e')
    if exist(['' i ':\'], 'dir') == 7
        ret{retRow,1} = upper([i ':\']); %#ok<AGROW>
        retRow = retRow + 1;
    end
end

for i = 1:length(ret)
    d = dir(ret{i});
    test = strcmp({d(:).name},'Recorded_Data')';
    if any(test)
        dl = ret{i};
    end
end