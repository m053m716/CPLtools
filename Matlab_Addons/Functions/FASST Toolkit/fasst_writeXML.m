function fasst_writeXML( xml_fname, data )
root = com.mathworks.xml.XMLUtils.createDocument('sources');

% Generate iterations element
if isfield(data, 'iterations')
    iterationsNode = root.createElement('iterations');
    iterationsNode.setTextContent(sprintf('%d', data.iterations));
    root.getDocumentElement.appendChild(iterationsNode);
end

% Generate tfr element
if isfield(data, 'tfr_type')
    tfr_typeNode = root.createElement('tfr_type');
    tfr_typeNode.setTextContent( data.tfr_type);
    root.getDocumentElement.appendChild(tfr_typeNode);
end

% Generate wlen element
wlenNode = root.createElement('wlen');
wlenNode.setTextContent(sprintf('%d', data.wlen));
root.getDocumentElement.appendChild(wlenNode);

% Generate nbin element
if isfield(data, 'nbin')
    nbinNode = root.createElement('nbin');
    nbinNode.setTextContent(sprintf('%d', data.nbin));
    root.getDocumentElement.appendChild(nbinNode);
end

% Generate source elements
if isfield(data, 'sources')
    for j = 1:size(data.sources,2)
        writeSource(data.sources{j}, root)
    end
end

% Write xml
xmlwrite(xml_fname, root)
end

function writeSource( source, root )
sourceNode = root.createElement('source');
root.getDocumentElement.appendChild(sourceNode);

% Source name
if isfield(source, 'name')
    sourceNode.setAttribute('name', source.name);
end

%% Wiener parameter
if isfield(source, 'wiener')
    writeWienerParameter(source.wiener, sourceNode, root);
end

% Mixing Parameter
if isfield(source, 'A')
    writeMixingParameter(source.A, sourceNode, root);
end

% Spectral power
writeSpectralPower(source, 'ex', sourceNode, root);
if isfield(source, 'Wft') || isfield(source, 'Uft') || isfield(source, 'Gft') || isfield(source, 'Hft')
    writeSpectralPower(source, 'ft', sourceNode, root);
end
end

function writeWienerParameter( wiener, sourceNode, root )
wienerNode = root.createElement('wiener');
sourceNode.appendChild(wienerNode);

if isfield(wiener, 'a')
    a = root.createElement('a');
    a.setTextContent(sprintf('%g', wiener.a));
    wienerNode.appendChild(a);
end

if isfield(wiener, 'b')
    b = root.createElement('b');
    b.setTextContent(sprintf('%g',wiener.b));
    wienerNode.appendChild(b);
end

if isfield(wiener, 'c1')
    c1 = root.createElement('c1');
    c1.setTextContent(sprintf('%g',wiener.c1));
    wienerNode.appendChild(c1);
end

if isfield(wiener, 'c2')
    c2 = root.createElement('c2');
    c2.setTextContent(sprintf('%g',wiener.c2));
    wienerNode.appendChild(c2);
end

if isfield(wiener, 'd')
    d = root.createElement('d');
    d.setTextContent(sprintf('%g',wiener.d));
    wienerNode.appendChild(d);
end
end

function writeMixingParameter( A, sourceNode, root )
matrixNode = root.createElement('A');
sourceNode.appendChild(matrixNode);

% Attributes
matrixNode.setAttribute('adaptability', A.adaptability);
matrixNode.setAttribute('mixing_type', A.mixingType);

% Ndims
ndims_node = root.createElement('ndims');
ndims_node.setTextContent(int2str(ndims(A.data)));
matrixNode.appendChild(ndims_node);

% Dimensions
for dim = size(A.data)
    dim_node = root.createElement('dim');
    dim_node.setTextContent(int2str(dim));
    matrixNode.appendChild(dim_node);
end

% Type
type_node = root.createElement('type');
if isreal(A.data)
    type_node.setTextContent('real');
else
    type_node.setTextContent('complex');
end
matrixNode.appendChild(type_node);

% Data
data_node = root.createElement('data');
if isreal(A.data)
    data_node.setTextContent(sprintf('%g ', A.data));
else
    data_node.setTextContent(sprintf('%g %g ', [real(A.data) imag(A.data)]));
end
matrixNode.appendChild(data_node);
end

function writeSpectralPower( source, suffix, sourceNode, root )
keys = cellstr(['W'; 'U'; 'G'; 'H']);
for i=1:size(keys)
    keys{i} = strcat(keys{i}, suffix);
end
dim = 0;
for i=1:size(keys)
    key = keys{i};
    if isfield(source, key)
        dim = size(getfield(getfield(source, key), 'data'), 1);
        break;
    end
end
for i=1:size(keys)
    key = keys{i};
    if isfield(source, key) && ~isempty(getfield(source, key))
        writeNonNegMatrix(getfield(source, key), key, sourceNode, root);
        dim = size(getfield(getfield(source, key), 'data'), 2);
    else
        identity.dim = dim;
        writeNonNegMatrix(identity, key, sourceNode, root);
    end
end
end

function writeNonNegMatrix( matrix, matrixName, sourceNode, root )
matrixNode = root.createElement(matrixName);
sourceNode.appendChild(matrixNode);

if isfield(matrix, 'adaptability') && isfield(matrix, 'data')
    % Attributes
    matrixNode.setAttribute('adaptability', matrix.adaptability);

    % Dimensions
    rows_node = root.createElement('rows');
    rows_node.setTextContent(sprintf('%d', size(matrix.data,1)));
    matrixNode.appendChild(rows_node);

    cols_node = root.createElement('cols');
    cols_node.setTextContent(sprintf('%d', size(matrix.data,2)));
    matrixNode.appendChild(cols_node);

    % Data
    data_node = root.createElement('data');
    s = '';
    for i=1:size(matrix.data, 2)
        s = [s, sprintf('%g ', matrix.data(:,i)), sprintf('\n')];
    end
    data_node.setTextContent(s);
    matrixNode.appendChild(data_node);

else
    matrixNode.setAttribute('adaptability', 'fixed');
    rows_node = root.createElement('rows');
    rows_node.setTextContent(sprintf('%d', matrix.dim));
    matrixNode.appendChild(rows_node);
    cols_node = root.createElement('cols');
    cols_node.setTextContent(sprintf('%d', matrix.dim));
    matrixNode.appendChild(cols_node);
    data_node = root.createElement('data');
    data_node.setTextContent('eye');
    matrixNode.appendChild(data_node);
end
end
