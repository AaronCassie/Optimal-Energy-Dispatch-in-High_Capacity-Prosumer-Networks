function data = read_input_data(filename)
% Read the project input JSON file.
% Keeping this in one helper makes input errors easier to trace.

if nargin < 1 || isempty(filename)
    error('An input filename must be provided.');
end

if ~isfile(filename)
    error('Input file not found: %s', filename);
end

% Read raw text first, then  decode once.
raw = fileread(filename);
data = jsondecode(raw);

end
