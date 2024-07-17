% Define file paths
inputFile = 'Pending File';
outputFile = 'Processed File';
% Open the input file for reading
fileID = fopen(inputFile, 'r');
% Check if the file opened successfully
if fileID == -1
    error('Cannot open input file');
end
% Open the output file for writing
outputID = fopen(outputFile, 'w');
% Check if the file opened successfully
if outputID == -1
    error('Cannot open output file');
end
% Read and process each line in the input file
while ~feof(fileID)
    % Read a line from the file
    line = fgetl(fileID);  
    if ischar(line) % Ensure the line is valid
        % Split the line by spaces or tabs
        items = strsplit(strtrim(line), '\t'); % Ensure to trim whitespace    
        % Check if there are at least two items
        if length(items) >= 2
            % Write the second item to the output file
            fprintf(outputID, '%s\n', items{2});
        else
            % If there is no second item, write a warning
            fprintf(outputID, 'Line does not have a second item\n');
        end
    end
end
 % Close the files
fclose(fileID);
fclose(outputID);
disp('Process completed successfully.');
