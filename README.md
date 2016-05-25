## Seattle Collision Data

This repository contains a short Matlab script I wrote in my spare time that gets car collision data from data.seattle.gov, then filters them to peak travel times for 2015 and combines these with temperature data at the time of collision (also from data.seatttle.gov). All that is required to run this is a relatively recent version of Matlab and a user-specific app-token wich can be gotten for free from the data.seattle.gov website.

### Graphics

#### Spatial Domain
Google map showing the spatial domain of the analysis as a shaded box: 
![alt text][map]

[map]: https://github.com/superflyben/collision_data/blob/master/images/data_domain.PNG "Map of data domain"

#### Collision Locations
Matlab graphic showing collision location as blue dots in lat-long coordinates

#### Collision Histogram
Matlab graphic showing the number of collisions as a function of road temperature
