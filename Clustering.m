upSatFile = 'upSat File';
downSatFile = 'downSat File';
clusterUpFile = 'cluster_upSat File';
clusterDownFile = 'cluster_downSat File';
outputFile = 'satByCluster File';
upSatData = readtable(upSatFile, 'Delimiter', ' ', 'ReadVariableNames', false);
downSatData = readtable(downSatFile, 'Delimiter', ' ', 'ReadVariableNames', false);
clusterUpData = readtable(clusterUpFile, 'Delimiter', ' ', 'ReadVariableNames', false);
clusterDownData = readtable(clusterDownFile, 'Delimiter', ' ', 'ReadVariableNames', false);
satData = [upSatData; downSatData];
clusterData = [clusterUpData; clusterDownData];
 
fileID = fopen(outputFile, 'w');
 
for i = 1:height(clusterData)
    clusterHead = clusterData(i, :);
    clusterHeadName = clusterHead.Var1;
    clusterHeadLat = clusterHead.Var2;
    clusterHeadLon = clusterHead.Var3;
    clusterHeadAlt = clusterHead.Var4;
    fprintf(fileID, '%s %.6f %.6f %.3f\n', clusterHeadName{1}, clusterHeadLat, clusterHeadLon, clusterHeadAlt);
    clusterSatellites = {};
    for j = 1:height(satData)
        sat = satData(j, :);
        satName = sat.Var1;
        satLat = sat.Var2;
        satLon = sat.Var3;
        satAlt = sat.Var4;
        minDistance = inf;
        closestClusterIndex = 0;
 
        for k = 1:height(clusterData)
distance = sqrt((satLat - clusterHeadLat)^2 + (satLon - clusterHeadLon)^2);
            if distance < minDistance
                minDistance = distance;
                closestClusterIndex = k;
            end
        end
        if closestClusterIndex == i
            clusterSatellites{end+1} = sat;
        end
    end
    for k = 1:length(clusterSatellites)
        sat = clusterSatellites{k};
        satName = sat.Var1;
        satLat = sat.Var2;
        satLon = sat.Var3;
        satAlt = sat.Var4;
        fprintf(fileID, '  %s %.6f %.6f %.3f\n', satName{1}, satLat, satLon, satAlt);
    end
    fprintf(fileID, '\n'); 
end
fclose(fileID);
