function pros = load_prosumer_table(cfg)
% Load prosumer data from the configured JSON input file.
% This keeps the scenario definition outside the solver code.

inputData = read_input_data(cfg.input_file);

if ~isfield(inputData, 'prosumers') || isempty(inputData.prosumers)
    error('Input file %s does not contain any prosumer data.', cfg.input_file);
end

src = inputData.prosumers;
requiredFields = {'id','bus','hasStorage','L_scale','Gsol_scale','Gwind_scale', ...
    'shiftL','shiftSol','shiftWind','Emax','PchMax','PdisMax','ell','r'};

% Keep the file check explicit so bad inputs fail early.
for f = 1:numel(requiredFields)
    if ~isfield(src, requiredFields{f})
        error('Input file %s is missing prosumer field "%s".', cfg.input_file, requiredFields{f});
    end
end

% IDs, bus assignments, and storage flags.
pros.i = reshape([src.id], [], 1);
pros.bus = reshape([src.bus], [], 1);
pros.hasStorage = logical(reshape([src.hasStorage], [], 1));

% Shape scales.
pros.L_scale = reshape([src.L_scale], [], 1);
pros.Gsol_scale = reshape([src.Gsol_scale], [], 1);
pros.Gwind_scale = reshape([src.Gwind_scale], [], 1);

% Circular hour shifts.
pros.shiftL = reshape([src.shiftL], [], 1);
pros.shiftSol = reshape([src.shiftSol], [], 1);
pros.shiftWind = reshape([src.shiftWind], [], 1);

% Storage sizes and charge/discharge limits.
pros.Emax = reshape([src.Emax], [], 1);
pros.PchMax = reshape([src.PchMax], [], 1);
pros.PdisMax = reshape([src.PdisMax], [], 1);

% Loss factors and retail benchmark rates.
pros.ell = reshape([src.ell], [], 1);
pros.r = reshape([src.r], [], 1);

if isfield(inputData, 'system') && isfield(inputData.system, 'num_buses')
    busesInFile = inputData.system.num_buses;
    if numel(unique(pros.bus)) ~= busesInFile
        error('Input file %s is inconsistent: system.num_buses does not match prosumer bus assignments.', cfg.input_file);
    end
end

end
