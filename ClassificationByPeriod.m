file_path = "Pending File";
fid = fopen(file_path, 'r');
unique_values = {};
value_counts = containers.Map;
 while ~feof(fid)
    line = fgetl(fid);
    data = strsplit(line);
    if length(data) >= 3
        value = data{3};
        if ~any(strcmp(unique_values, value))
            unique_values{end+1} = value;
            value_counts(value) = 1;           
        else
            value_counts(value) = value_counts(value) + 1;
        end
    end
end
keys = unique_values;
for i = 1:length(keys)
    key = keys{i};
    disp(['Period is ', key, ' mins ', num2str(value_counts(key))]);
end
num_unique_values = length(unique_values);
disp(['If the period of satellites in the same orbit is the same, there are a total of ', num2str(num_unique_values), ' different orbits ']);
fclose(fid);
