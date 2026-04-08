function policyDef = load_policy_definition(filename)
% Load a policy definition from a small MATLAB input file.
% Using a .m file here keeps it easy to comment for demo purposes, instead of a json file like used for prosumer inputs.

if nargin < 1 || isempty(filename)
    error('A policy input filename must be provided.');
end

[folderPath, funcName, ext] = fileparts(filename);
if ~isempty(ext) && ~strcmpi(ext, '.m')
    error('Policy input file must be a MATLAB .m file: %s', filename);
end

if ~isempty(folderPath)
    addpath(folderPath);
end

if exist(funcName, 'file') ~= 2
    error('Policy input file not found: %s', filename);
end

policyDef = feval(funcName);

requiredFields = {'policy_name', 'rule_type', 'policy_notes'};
for k = 1:numel(requiredFields)
    if ~isfield(policyDef, requiredFields{k})
        error('Policy input file %s is missing field "%s".', filename, requiredFields{k});
    end
end

end
