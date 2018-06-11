function s = code2type(code)
%% given event code, return string 'epocs', 'snips', or 'streams',

% Tank event types (tsqEventHeader.type)
EVTYPE_UNKNOWN	= hex2dec('00000000');
EVTYPE_STRON	= hex2dec('00000101');
EVTYPE_STROFF	= hex2dec('00000102');
EVTYPE_SCALAR	= hex2dec('00000201');
EVTYPE_STREAM	= hex2dec('00008101');
EVTYPE_SNIP		= hex2dec('00008201');
EVTYPE_MARK		= hex2dec('00008801');
EVTYPE_HASDATA	= hex2dec('00008000');
EVTYPE_UCF		= hex2dec('00000010');
EVTYPE_PHANTOM	= hex2dec('00000020');
EVTYPE_MASK		= hex2dec('0000FF0F');
EVTYPE_INVALID_MASK	= hex2dec('FFFF0000');

strobeTypes = [EVTYPE_STRON EVTYPE_STROFF EVTYPE_SCALAR] ; % TODO: add all epoc/scalar data types
snipTypes = [EVTYPE_SNIP];

if ismember(code, strobeTypes)
    s = 'epocs';
elseif ismember(code, snipTypes)
    s = 'snips';
elseif bitand(code, EVTYPE_MASK) == EVTYPE_STREAM
    s = 'streams';
else
    s = 'unknown';
end

end