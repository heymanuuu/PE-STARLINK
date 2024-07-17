c = 299792.458; 
uiApplication = actxGetRunningServer('STK11.Application');
root = uiApplication.Personality2;
scenario = root.CurrentScenario;
 
filename = "starlink1_links File";
fileID = fopen(filename, 'r');
linksData = textscan(fileID, '%s %s', 'Delimiter', ' ');
fclose(fileID);
 
outputFile = ' Delay File';
fileID_delay = fopen(outputFile, 'w');
 
for i = 1:length(linksData{1})
    sat1 = linksData{1}{i};
    sat2 = linksData{2}{i};
    
    positionCommand1 = sprintf('Position */Satellite/%s "22 Mar 2024 04:00:00.000"', sat1);
    position1 = root.ExecuteCommand(positionCommand1);
    positionInfo1 = strsplit(position1.Item(0));
    x1 = str2double(positionInfo1{7});
    y1 = str2double(positionInfo1{8});
    z1 = str2double(positionInfo1{9});
    
    positionCommand2 = sprintf('Position */Satellite/%s "22 Mar 2024 04:00:00.000"', sat2);
    position2 = root.ExecuteCommand(positionCommand2);
    positionInfo2 = strsplit(position2.Item(0));
    x2 = str2double(positionInfo2{7});
    y2 = str2double(positionInfo2{8});
    z2 = str2double(positionInfo2{9});
    
    distance = sqrt((x2 - x1)^2 + (y2 - y1)^2 + (z2 - z1)^2); 
    delay = (distance / c); 
 
    fprintf(fileID_delay, '%s %s %.2f\n', sat1, sat2, delay);
end
 
fclose(fileID_delay);
