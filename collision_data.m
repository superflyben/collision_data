%Script to access data from data.seattle.gov and display result

%% Get collision data

%Resource and application specs
end_point = 'https://data.seattle.gov/resource/v7k9-7dn4.json';
app_token = ''; %<Enter app token here>

%Get the full dataset (will handle filtering and merging with Matlab)
%NOTE: Must read the data in 500-record chunks because anything larger
%      produces unexpected results, possibly having to do with
%      data.seattle.gov (as errors were not encountered in other websites
%      when reading bigger chunks with the same command).

%Set length of data set from online metadata
chunk_size = 500;

%Set records initially to chunk_size to begin while loop
num_rows = chunk_size;
%Initiate storage variable and counter
%NOTE: Initiate storage as empty cell array, but empty matrix also works
sdot_wreck_raw = {};    
counter = 1;

%Use while loop to read in all available records
%Alternatively, could use for-loop and known database size
while num_rows==chunk_size
    full_url =...
        [end_point ...
         '?$limit=' num2str(chunk_size) ...
         '&$offset=' num2str((counter-1)*chunk_size)...
         '&$$app_token=' app_token];
    %Use built-in Matlab function, webread, to parse json file into cell
    %array of structures
    local_chunk = webread(full_url);
    %Add current block to storage variable
    sdot_wreck_raw = [sdot_wreck_raw;local_chunk];
    %Display some output
    fprintf('Object ID of last record read: %s\n',...
             local_chunk{end}.objectid)
    %Test if full chunk read in
    if numel(local_chunk)==chunk_size
        %Increment counter
        counter = counter + 1;
    else
        break
    end
end

%% Convert data from structure to matrix
%Create new collision data array containing only ID, time and location

%Create new cell array of structures containing only records that have
%uniform fields (for fields of interest). Goal is to produce a variable
%suitable for vectorized operations
sdot_wreck_trim = {};
for i=1:numel(sdot_wreck_raw)
    if isfield(sdot_wreck_raw{i},'objectid') &&...
            isfield(sdot_wreck_raw{i},'incdttm') &&...
            isfield(sdot_wreck_raw{i}.shape,'latitude') &&...
            isfield(sdot_wreck_raw{i}.shape,'longitude')
        %Then add the field contents to the trimmed array
        %--> Put contents directly into vectors to save additional steps
        sdot_wreck_trim{end+1,1}.objectid = ...
            str2num(sdot_wreck_raw{i}.objectid);
        sdot_wreck_trim{end,1}.incdttm = ...
            datenum(sdot_wreck_raw{i}.incdttm);
        sdot_wreck_trim{end,1}.lat = ...
            str2num(sdot_wreck_raw{i}.shape.latitude);
        sdot_wreck_trim{end,1}.long = ...
            str2num(sdot_wreck_raw{i}.shape.longitude);
    end
end

%Convert trimmed cell array of structures to single structure with the
%same number of records
sdot_wreck_trim = cell2mat(sdot_wreck_trim);

%finally Convert structure fields to vectors for easier manipulation
num = [sdot_wreck_trim.objectid]';
sday = [sdot_wreck_trim.incdttm]';
lat = [sdot_wreck_trim.lat]';
long = [sdot_wreck_trim.long]';

%% Reduce collision data based on certain crieteria
%load collision_data.mat    %Only works if data were prviously saved
%Calculate fractional day
fday = datenum(sday) - floor(datenum(sday));

%Data must meet the following conditions:
% 1. 2015 only
% 2. full date and time stamp (taken care of by looking for non-zero
%    fractional days in step 3)
% 3. peak traffic times (7-10 and 15-19)
keep_idx = (sday>=datenum(2015,1,1) & sday<=datenum(2015,12,31)) & ...
           ((fday>=7/24 & fday<=10/24) | (fday>=15/24 & fday<=19/24));
       
num = num(keep_idx);
sday = sday(keep_idx);
lat = lat(keep_idx);
long = long(keep_idx);

%Show geographic location of collisions meeting these criteria
figure; plot(long,lat,'.')
xlabel('Longitude')
ylabel('Latitude')
title('Automobile Collisions in Seattle Area')

%% Get road temperature data
%End result is a temperatue data point for each collision.

for i=1:numel(sday)
    %Construct SoQL command to get only temperatures within 1 minute of
    %collision time
    t1 = sday(i) - (1/3600/24);
    t1_str = [datestr(t1,29) 'T' datestr(t1,13)];
    t2 = sday(i) + (1/3600/24);
    t2_str = [datestr(t2,29) 'T' datestr(t2,13)];
    rt_call = ['https://data.seattle.gov/resource/ivtm-938t.json'...
              '?$where=datetime between '...
              '''' t1_str ''' and ''' t2_str ''''...
              '&$$app_token=' app_token];
    rt = webread(rt_call);
    %Average temperature over all sites (use 'omitnan' option if need be)
    %--> Is it possible to vectorize this?
    for k=1:length(rt)
        rt_mat(k,1) = str2num(rt(k).roadsurfacetemperature);
    end
    %Calculate mean for 2 minute block
    temp_mean(i) = mean(rt_mat);
    if mod(i,100)==0; fprintf('Record #: %d\n',i); end
end

%Show results as histogram
%NOTE: takeaway is that see an unusual peak at higher temps
histogram(road_temp)
xlabel('Road Temperature (\circF)')
ylabel('Number of Collisions')
title({'Unexpected peak in number of collisions',...
       'in upper end of temperature range'})
