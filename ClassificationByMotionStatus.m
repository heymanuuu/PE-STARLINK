uiApplication = actxGetRunningServer('STK11.Application');
root = uiApplication.Personality2;
scenario = root.CurrentScenario;
 
filename = 'E:\STK11\STKFile\satBysPos.txt';
fileID = fopen(filename, 'r');
satData = textscan(fileID, '%s %f %f %f', 'Delimiter', ' ');
fclose(fileID);
fileID_up = fopen('E:\STK11\STKFile\upSat.txt', 'w');
fileID_down = fopen('E:\STK11\STKFile\downSat.txt', 'w');
 
for i = 1:length(satData{1})
    satName = satData{1}{i};
    latitude = satData{2}(i);
    longitude = satData{3}(i);
    altitude = satData{4}(i);
    positionCommand = sprintf('Position */Satellite/%s "22 Mar 2024 04:00:00.000"', satName);
    position = root.ExecuteCommand(positionCommand);
    positionInfo = strsplit(position.Item(0));
    
    latitudeRate = str2double(positionInfo{4});
    
    line = sprintf('%s %.6f %.6f %.3f', satName, latitude, longitude, altitude);
    
    if latitudeRate > 0
        fprintf(fileID_up, '%s\n', line);
    else
        fprintf(fileID_down, '%s\n', line);
    end
end
 
fclose(fileID_up);
fclose(fileID_down);

