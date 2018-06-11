function offset = isoffset(code)
EVTYPE_STROFF	= hex2dec('00000102');
offset = (code == EVTYPE_STROFF);
end