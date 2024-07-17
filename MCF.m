function adjacency_matrix = createSatelliteLinks(filename)
    % Open the file
    fid = fopen(filename, 'r');
    if fid == -1
        error('Cannot open the file');
    end
    % Initialize variables to store satellite data
    clusters = containers.Map(); % Map to store satellites in each cluster
    cluster_heads = containers.Map(); % Map to store cluster head satellites
 
    % Read each line of the file
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
            cluster_head.altitude = 0; % Assuming cluster heads have no altitude information
            cluster_heads(cluster_name) = cluster_head;
        elseif numel(parts) == 4 && strncmp(strtrim(parts{1}), 'STARLINK-', 9)
            % Satellite information line
            satellite.name = strtrim(parts{1});
            satellite.latitude = str2double(parts{2});
            satellite.longitude = str2double(parts{3});
            satellite.altitude = str2double(parts{4});
            % Add the satellite to its respective cluster
            if isKey(clusters, cluster_name)
                clusters(cluster_name) = [clusters(cluster_name), satellite];
            end
        end
 % Read the next line
        tline = fgetl(fid);
    end
    % Close the file
    fclose(fid);
    % Extract all cluster names
    cluster_names = keys(clusters);
    % Initialize arrays to store coordinates of all satellites
    all_latitudes = [];
    all_longitudes = [];
    % Extract coordinates for plotting and adjacency matrix creation
    for k = 1:length(cluster_names)
        cluster_name = cluster_names{k};
        satellites = clusters(cluster_name);
        latitudes = [satellites.latitude];
        longitudes = [satellites.longitude];
        all_latitudes = [all_latitudes, latitudes];
        all_longitudes = [all_longitudes, longitudes];
    end
    % Initialize adjacency matrix and link count array
    num_satellites = length(all_latitudes);
    adjacency_matrix = zeros(num_satellites);
 
    % Create connections based on distance (up to 4 links per satellite)
    for i = 1:length(all_latitudes)
        idx_i = i;
        link_counts = sum(adjacency_matrix, 2); % Count current links for each satellite
        if link_counts(idx_i) < 4
            % Sort distances in ascending order
            dists = sqrt((all_latitudes(idx_i) - all_latitudes).^2 + (all_longitudes(idx_i) - all_longitudes).^2);
            [~, sorted_indices] = sort(dists);
count = link_counts(idx_i);
            for j = 1:length(all_latitudes)
                if count >= 4
                    break;
                end
                idx_j = sorted_indices(j);
                if idx_i ~= idx_j && adjacency_matrix(idx_i, idx_j) == 0 && adjacency_matrix(idx_j, idx_i) == 0
                    adjacency_matrix(idx_i, idx_j) = 1;
                    adjacency_matrix(idx_j, idx_i) = 1; % Assume undirected graph
                    count = count + 1;
                end
            end
        end
    end
end
