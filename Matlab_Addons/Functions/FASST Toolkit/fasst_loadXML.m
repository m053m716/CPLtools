function data = fasst_loadXML( filename )
% Import data from an XML file

%% Read XML file
domnode = xmlread(filename);

% Read wlen
data.wlen = str2num(domnode.getElementsByTagName('wlen').item(0).getTextContent);

% Read iterations
if ~isempty(domnode.getElementsByTagName('iterations').item(0))
    data.iterations = str2num(domnode.getElementsByTagName('iterations').item(0).getTextContent);
end

% Read tfr_type
if ~isempty(domnode.getElementsByTagName('tfr_type').item(0))
    data.tfr_type = char(domnode.getElementsByTagName('tfr_type').item(0).getTextContent);
end

% Read sources
J = domnode.getElementsByTagName('source').getLength;

for j=1:J
    src = domnode.getElementsByTagName('source').item(j-1);

    % Read source name
    data.sources{j}.name = char(src.getAttribute('name'));

    % Read Wiener parameter
    if ~isempty(src.getElementsByTagName('wiener').item(0))
        data.sources{j}.wiener = readWienerParameter(src.getElementsByTagName('wiener').item(0));
    end

    % Read mixing parameter
    if ~isempty(src.getElementsByTagName('A').item(0))
        data.sources{j}.A = readMixingParameter(src.getElementsByTagName('A').item(0));
    end

    % Read nonnegative matrices
    data.sources{j}.Wex = readNonNegMatrix(src.getElementsByTagName('Wex').item(0));
    data.sources{j}.Uex = readNonNegMatrix(src.getElementsByTagName('Uex').item(0));
    data.sources{j}.Gex = readNonNegMatrix(src.getElementsByTagName('Gex').item(0));
    data.sources{j}.Hex = readNonNegMatrix(src.getElementsByTagName('Hex').item(0));
    if ~isempty(src.getElementsByTagName('Wft').item(0))
        data.sources{j}.Wft = readNonNegMatrix(src.getElementsByTagName('Wft').item(0));
        data.sources{j}.Uft = readNonNegMatrix(src.getElementsByTagName('Uft').item(0));
        data.sources{j}.Gft = readNonNegMatrix(src.getElementsByTagName('Gft').item(0));
        data.sources{j}.Hft = readNonNegMatrix(src.getElementsByTagName('Hft').item(0));
    end
end
end

function wiener = readWienerParameter( node )

wiener.a  = str2num(node.getElementsByTagName('a').item(0).getTextContent);
wiener.b  = str2num(node.getElementsByTagName('b').item(0).getTextContent);
wiener.c1 = str2num(node.getElementsByTagName('c1').item(0).getTextContent);
wiener.c2 = str2num(node.getElementsByTagName('c2').item(0).getTextContent);
wiener.d  = str2num(node.getElementsByTagName('d').item(0).getTextContent);

end

function A = readMixingParameter( node )
% Import A from a mixing parameter XML node

A.adaptability = char(node.getAttribute('adaptability'));
A.mixingType = char(node.getAttribute('mixing_type'));

% Dimensions
ndims = str2num(node.getElementsByTagName('ndims').item(0).getTextContent);
dim = zeros(1, ndims);
for i=0:ndims-1
    dim(i+1) = str2num(node.getElementsByTagName('dim').item(i).getTextContent);
end

% Type
type = node.getElementsByTagName('type').item(0).getTextContent;

% Read data
data = char(node.getElementsByTagName('data').item(0).getTextContent);
% Trim and split the string
data = char(regexp(strtrim(data), ' ', 'split'));
% Convert to num
data = str2num(data);

if type == 'complex'
    % Reshape and convert to complex
    A.data = complex(zeros(dim));
    s = dim(1)*dim(2);
    d = [dim(1) dim(2)];
    for i=1:dim(3)
        inf = 2*s*(i-1)+1;
        sup = s*(2*i-1);
        real_part = reshape(data(inf:sup), d);

        inf = s*(2*i-1)+1;
        sup = 2*s*i;
        imag_part = reshape(data(inf:sup), d)*1j;

        A.data(:,:,i) = real_part + imag_part;
    end
else
    % Reshape
    A.data = reshape(data,dim);
end
end

function mat = readNonNegMatrix( node )
% Import matrix from a nonnegative matrix XML node

% Attributes
mat.adaptability = char(node.getAttribute('adaptability'));

% Dimensions
rows = str2double(node.getElementsByTagName('rows').item(0).getTextContent);
cols = str2double(node.getElementsByTagName('cols').item(0).getTextContent);

% Read data
data = char(node.getElementsByTagName('data').item(0).getTextContent);
if strcmp(data, 'eye')
    mat = [];
    return;
end
data = regexp(strtrim(data), '\n', 'split');
data = regexp(strtrim(data), ' ', 'split');
mat.data = zeros(rows,cols);
for i=1:cols
    mat.data(:,i) = str2num(char(data{i}));
end
end
