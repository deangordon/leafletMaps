# Things I've done with Leaflet Maps
Simple cases of some techniques with leaflet and rgdal I've found really helpful.

This is based on data published by NISRA and data I've made up myself for the purpose of examples. The code produces interactive maps, in that you can zoom in and clicking on shapes will display more information. The attached code has commented examples of:

* Converting from one projection to another (Irish Grid to WGS84)
* Displaying dots on a map
* Display polygons on a map
* Counting the dots in each polygon
* Sub-setting the data displayed in the map
* Adding a colour-gradient to map features
* Controlling the layers on a map to ensure the correct layer is on top
* Adding a legend and bespoke attribution line

![screen-grab of interactive map](https://github.com/deangordon/leafletMaps/blob/master/sampleMap.JPG)

This image is deliberately sparse, as when showing data on a map I usually want to minimise what else is on the map, so this map does not show terrain or parks, which can get confusing. As it's amde with leaflet, it is really easy to choose maps for your purposes, including satellite images if you plan to zoom right in.
