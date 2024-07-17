% Define file paths
testFile = 'Pending File';
starlinkFile = 'TLE File';
outputFile = 'Processed File';
testFileID = fopen(testFile, 'r');
if testFileID == -1
    error('Cannot open test file');
end
satNames = {};
while ~feof(testFileID)
    line = strtrim(fgetl(testFileID));
    if ischar(line) && ~isempty(line)
        satNames{end+1} = line; 
    end
end
fclose(testFileID);
% Read the contents of starlink1.txt
starlinkFileID = fopen(starlinkFile, 'r');
if starlinkFileID == -1
    error('Cannot open starlink file');
end
starlinkData = textscan(starlinkFileID, '%s', 'Delimiter', '\n', 'Whitespace', '');
fclose(starlinkFileID);
starlinkData = starlinkData{1};
% Open the output file for writing
outputFileID = fopen(outputFile, 'w');
if outputID == -1
    error('Cannot open output file');
end
% Search for each satellite name in starlink1.txt and write the data to output file
for i = 1:length(satNames)
    satName = satNames{i};
    found = false;
    for j = 1:length(starlinkData)
        if strcmp(strtrim(starlinkData{j}), satName)
            found = true;
% Write the satellite name and the next two lines
            fprintf(outputFileID, '%s\n', starlinkData{j});
            if j+1 <= length(starlinkData)
                fprintf(outputFileID, '%s\n', starlinkData{j+1});
            end
            if j+2 <= length(starlinkData)
                fprintf(outputFileID, '%s\n', starlinkData{j+2});
            end
            break;
        end
    end
    if ~found
        warning('Satellite %s not found in starlink file', satName);
    end
end
% Close the output file
fclose(outputFileID);
disp('Process completed successfully.');
