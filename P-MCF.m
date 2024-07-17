% File path
filename = 'satByCluster File';
 
% Open file
fid = fopen(filename, 'r');
 
% Initialize variables to store satellite data
clusters = containers.Map(); % Map to store satellites in each cluster
cluster_heads = containers.Map(); % Map to store cluster head satellites
% Read each line in the file
tline = fgetl(fid);
while ischar(tline)
    % Split the line by spaces or tabs
    parts = strsplit(tline);
    
    % Check if it is a cluster head or satellite information
    if numel(parts) >= 4 && startsWith(strtrim(parts{1}), 'C')
        % Cluster head line
        cluster_name = strtrim(parts{1});
        clusters(cluster_name) = [];
        cluster_head.name = cluster_name;
        cluster_head.latitude = str2double(parts{2});
        cluster_head.longitude = str2double(parts{3});
        cluster_head.altitude = 0; % Assuming cluster head has no altitude information
        cluster_heads(cluster_name) = cluster_head;
    elseif numel(parts) == 4 && strncmp(strtrim(parts{1}), 'STARLINK-', 9)
        % Satellite information line
        satellite.name = strtrim(parts{1});
        satellite.latitude = str2double(parts{2});
        satellite.longitude = str2double(parts{3});
        satellite.altitude = str2double(parts{4});
        
        % Add satellite to its corresponding cluster
        if isKey(clusters, cluster_name)
            temp = clusters(cluster_name);
            temp = [temp, satellite];
            clusters(cluster_name) = temp;
        end
    end
    % Read the next line
    tline = fgetl(fid);
end
% Close file
fclose(fid);
% Extract names of all clusters
cluster_names = keys(clusters);
% Initialize arrays to store coordinates of all satellites
all_latitudes = [];
all_longitudes = [];
% Plot satellite positions in each cluster (different colors represent different clusters)
figure;
hold on;
color_order = lines(length(cluster_names)); % Generate different colors
legend_entries = cell(length(cluster_names), 1);
for k = 1:length(cluster_names)
    cluster_name = cluster_names{k};
    
    % Extract satellites in the current cluster
    satellites = clusters(cluster_name);
    
    % Extract latitudes and longitudes for plotting
    latitudes = [satellites.latitude];
    longitudes = [satellites.longitude];
    
    % Store coordinates of all satellites
    all_latitudes = [all_latitudes, latitudes];
    all_longitudes = [all_longitudes, longitudes];
    
    % Determine color for the current cluster
    if strcmp(cluster_name, 'C0009_00009') || strcmp(cluster_name, 'C0010_00010')
        color = [0, 1, 0]; % Green
    elseif strcmp(cluster_name, 'C0006_00006') || strcmp(cluster_name, 'C0007_00007')
        color = [1, 1, 0]; % Yellow
    else
        color = color_order(k,:);
    end
% Plot satellites in the current cluster (using unique color)
    scatter(longitudes, latitudes, 'filled', 'MarkerFaceColor', color);
    legend_entries{k} = ['Cluster ' cluster_name];
    % Plot cluster head satellite
    cluster_head = cluster_heads(cluster_name);
    scatter(cluster_head.longitude, cluster_head.latitude, 100, 's', 'MarkerEdgeColor', 'k', 'MarkerFaceColor', color, 'LineWidth', 1.5);
end
title('All satellite positions in the constellation');
xlabel('longitude');
ylabel('latitude');
grid on;
 
% Adjust legend position to be outside the plot
lgd = legend(legend_entries, 'Location', 'eastoutside', 'FontSize', 8);
hold off;
 
% Initialize arrays to include all satellites and cluster heads
all_satellites = [];
all_latitudes = [];
all_longitudes = [];
 
% Add cluster head satellites and cluster satellites to the total array
for k = 1:length(cluster_names)
    cluster_name = cluster_names{k};
    cluster_head = cluster_heads(cluster_name);
    all_satellites = [all_satellites, cluster_head];
    all_latitudes = [all_latitudes, cluster_head.latitude];
    all_longitudes = [all_longitudes, cluster_head.longitude];
    
    satellites = clusters(cluster_name);
    all_satellites = [all_satellites, satellites];
    latitudes = [satellites.latitude];
    longitudes = [satellites.longitude];
    all_latitudes = [all_latitudes, latitudes];
    all_longitudes = [all_longitudes, longitudes];
end
% Create distance-based connection topology (each satellite connects to neighboring satellites within the same cluster)
num_satellites = length(all_latitudes);
adjacency_matrix = zeros(num_satellites, num_satellites);


% Create connection relationships
for k = 1:length(cluster_names)
    cluster_name = cluster_names{k};
    
    % Extract satellites in the current cluster
    satellites = clusters(cluster_name);
    
    % Extract latitudes and longitudes for distance calculation
    latitudes = [satellites.latitude];
    longitudes = [satellites.longitude];
    
    % Find the cluster head satellite
    cluster_head = cluster_heads(cluster_name);
    
    % Find the index of the cluster head satellite in all_latitudes and all_longitudes
    idx_cluster_head = find(all_latitudes == cluster_head.latitude & all_longitudes == cluster_head.longitude);
    
    % Calculate distances between satellites and create connections
    dists = zeros(length(latitudes));
    for i = 1:length(latitudes)
        for j = 1:length(latitudes)
            if i ~= j
                dists(i, j) = sqrt((latitudes(i) - latitudes(j))^2 + (longitudes(i) - longitudes(j))^2);
            else
                dists(i, j) = inf; % Set self-distance to infinity
            end
        end
    end
    
    % Prim's algorithm to generate minimum spanning tree
    [mst, ~] = prim_mst(dists);
% Update adjacency matrix based on minimum spanning tree connections
    for i = 1:length(latitudes)
        for j = 1:length(latitudes)
            if mst(i, j) == 1
                idx1 = find(all_latitudes == latitudes(i) & all_longitudes == longitudes(i));
                idx2 = find(all_latitudes == latitudes(j) & all_longitudes == longitudes(j));
                adjacency_matrix(idx1, idx2) = 1;
                adjacency_matrix(idx2, idx1) = 1; 
            end
        end
    end
    % Connect cluster head satellite to the nearest satellite
    dists_head_to_sats = zeros(1, length(latitudes));
    for i = 1:length(latitudes)
        dists_head_to_sats(i) = sqrt((cluster_head.latitude - latitudes(i))^2 + (cluster_head.longitude - longitudes(i))^2);
    end
    [~, idx_nearest_satellite] = min(dists_head_to_sats);
    idx_nearest_satellite = find(all_latitudes == latitudes(idx_nearest_satellite) & all_longitudes == longitudes(idx_nearest_satellite));
    adjacency_matrix(idx_cluster_head, idx_nearest_satellite) = 1;
    adjacency_matrix(idx_nearest_satellite, idx_cluster_head) = 1; % Assume undirected graph
end
% Plot adjacency matrix
figure;
imagesc(adjacency_matrix);
title('Adjacency matrix of all satellites');
xlabel('Satellite index');
ylabel('Satellite index');
colorbar;
axis equal tight;
% Plot connections between satellites
figure;
gplot(adjacency_matrix, [all_longitudes' all_latitudes'], '-o');
title('Links between satellites');
xlabel('longitude');
ylabel('latitude');
grid on;
% Prim's algorithm function
function [MST, totalWeight] = prim_mst(graph)
    n = size(graph, 1);
    MST = zeros(n);
    visited = false(1, n);
    visited(1) = true;
    numVisited = 1;
    totalWeight = 0;
 
    while numVisited < n
        minWeight = inf;
        minFrom = 0;
        minTo = 0;
 
        for from = 1:n
            if visited(from)
                for to = 1:n
                    if ~visited(to) && graph(from, to) < minWeight
                        minWeight = graph(from, to);
                        minFrom = from;
                        minTo = to;
                    end
                end
            end
        end
 
        MST(minFrom, minTo) = 1;
        MST(minTo, minFrom) = 1;
        visited(minTo) = true;
        totalWeight = totalWeight + minWeight;
        numVisited = numVisited + 1;
    end
end
