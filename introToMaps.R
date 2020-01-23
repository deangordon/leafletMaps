library(tidyverse)
library(leaflet)
library(rgdal)
library(htmlwidgets)

#### Create points in NI to plot on map ####

### Points on a map
# Create random points
set.seed(1)
xcors <- runif(500,189000,367000)
ycors <- runif(500,310000,453000)
id <- 1:500

# put into data.frame
df <- cbind.data.frame(id, xcors, ycors)

# turn into spatial data.frame
coordinates(df) <- ~xcors + ycors
# Declare the type of projection for Irish grid coordinates
df@proj4string <- CRS("+proj=tmerc +lat_0=53.5 +lon_0=-8 +k=1.000035 +x_0=200000 +y_0=250000 +ellps=mod_airy +towgs84=482.5,-130.6,564.6,-1.042,-0.214,-0.631,8.15 +units=m +no_defs")

# Convert to WGS84 projection, as used by leaflet
df2 <- spTransform(df, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))

#### plot points on map ####
# (I like my maps to open in a web browser rather than in R. Depedning on network 
# firewalls, this is usually the safer option to get things working)
options("viewer" = function(url, ...) utils::browseURL(url))

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addMarkers(data = df2)

### plot Polygons ####
# Download NI Super Output Areas from https://www.nisra.gov.uk/support/geography/northern-ireland-super-output-areas
# as an ESRI Shapefile

# Read in the shape file (no need to specify layer as this file only contains one)
shapeData <- readOGR("R//niGeo")
# convert projection to WGS84, as used by leaflet
shapeData2 <- spTransform(shapeData, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))

# Plot polygons on map
leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addPolygons(data = shapeData2, popup = ~SOA_LABEL)

#### Geography Questions ####
# How many points fall into each SOA?

# over function will count how many points lie in each polygon
perSoa <- over(df2, shapeData2)
dfWithSoa <- cbind.data.frame(df2, perSoa)

dfWithSoa %>% 
  select(SOA_LABEL) %>% 
  table() %>% 
  as.data.frame() %>% 
  arrange(desc(Freq)) %>%
  head()

# How many are not in NI?
dfWithSoa %>% 
  filter(is.na(SOA_CODE)) %>% 
  nrow()

#### Subsetting data to display on map ####
# That seems like a lot, let's look at where they are on the map
# subset works by taking a vector, matrix or dataframe (including a spatialDataFrame)
# and a TRUE/FALSE vector indicating which lines should be retained
df3 <- subset(df2, is.na(dfWithSoa$SOA_CODE))

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addPolygons(data = shapeData2, popup = ~SOA_LABEL) %>%
  addMarkers(data = df3)

## Now to change some of the map settings:
# let's deal with points inside NI
df3 <- subset(df2, !is.na(dfWithSoa$SOA_CODE))

# replace markers with circles, add popup so that if you click on a circle it tells you the id

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addPolygons(data = shapeData2, popup = ~SOA_LABEL) %>%
  addCircles(data = df3, color = "yellow", popup = ~as.character(id))

# Remove some random SOAs, and the points inside them
# runif is "random uniform distribution", with arguments number of points, minimum and maximum values, see ?runif
# The code "row.names(shapeData) %in% as.integer(runif(400, 1,890))" creates a TRUE/FALSE vector
shapeData3 <- subset(shapeData2, row.names(shapeData) %in% as.integer(runif(400, 1,890)))
st_simplify
perSoa <- over(df2, shapeData3)
dfWithSoa <- cbind.data.frame(df2, perSoa)
df3 <- subset(df2, !is.na(dfWithSoa$SOA_CODE))

leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addPolygons(data = shapeData3, popup = ~SOA_LABEL) %>%
  addCircles(data = df3, color = "yellow", popup = ~as.character(id))

#### Map formatting and layers ####

# Now let's take control of the layers in the map:
# I have chosed a background map that contains no placenames, and a separate
# provider tile that only contains placenames, allowing me to put the placenames
# above everything else on the map
leaflet() %>%
  addMapPane("level1", zIndex = 410) %>%      # Level 1: bottom
  addMapPane("level2", zIndex = 420) %>%      # Level 2: middle 1
  addMapPane("level3", zIndex = 425) %>%      # Level 3: middle 2
  addMapPane("level4", zIndex = 430) %>%      # Level 4: top
  addProviderTiles(providers$Stamen.TonerBackground,
                   options = pathOptions(pane = "level1")) %>%
  addProviderTiles(providers$CartoDB.PositronOnlyLabels,
                   options = pathOptions(pane = "level4")) %>%
  addPolygons(data = shapeData3, popup = ~SOA_LABEL,
              opacity = 1, fillOpacity = 0.1,
              options = pathOptions(pane = "level2")) %>%
  addCircles(data = df3, color = "yellow", popup = ~as.character(id),
             radius = 50,
             options = pathOptions(pane = "level3"))

m
  
# Add color scaling and legend
# (this is a continuous scale, passing through each of the colours listed)
# Colour codes from http://colorbrewer2.org/
colNum <- colorNumeric(c('#fff7ec','#fee8c8','#fdd49e','#fdbb84','#fc8d59','#ef6548','#d7301f','#b30000','#7f0000'),
                       1:100)

# Note I have also replaced the default attribution with a bespoke one:
# This consists of setting a leaflet option at the top and then using addControl
# with an appropriate class name (this is a CSS attribute, for those familiar)

leaflet(options = leafletOptions(attributionControl=FALSE)) %>%
  addMapPane("level1", zIndex = 410) %>%      # Level 1: bottom
  addMapPane("level2", zIndex = 420) %>%      # Level 2: middle 1
  addMapPane("level3", zIndex = 425) %>%      # Level 3: middle 2
  addMapPane("level4", zIndex = 430) %>%      # Level 4: top
  addProviderTiles(providers$Stamen.TonerBackground,
                   options = pathOptions(pane = "level1")) %>%
  addProviderTiles(providers$CartoDB.PositronOnlyLabels,
                   options = pathOptions(pane = "level4")) %>%
  addPolygons(data = shapeData3, popup = ~SOA_LABEL,
              opacity = 1, fillOpacity = 0.1,
              options = pathOptions(pane = "level2")) %>%
  addCircles(data = df3, color = ~colNum(id/5), popup = ~paste0(as.character(id/5),"%"),
             radius = 50, 
             options = pathOptions(pane = "level3")) %>%
  addLegend("topleft", pal = colNum, values = 1:100,
            title = "id of points, treated as if they were percentages",
            labFormat = labelFormat(suffix = "%"),
            opacity = 0.6) %>%
  addControl("<i>Leaflet | Map tiles by Stamen Design, CC BY 3.0 and © CartoDB - Map data © OpenStreetMap, © Dean Gordon</i>", "bottomright", className = "leaflet-control-attribution")

#### Now create an html map that can be saved as an HTML file and shared without users needing
# any software installed. The shapefile for SOAs is very big, so I'm using a settlement file 

shapeData <- readOGR("R\\SDL15-ESRI_format")
shapeData2 <- spTransform(shapeData, CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))

colfac <- colorFactor(c('#7fc97f','#beaed4','#fdc086','#ffff99','#386cb0','#f0027f','#bf5b17','#666666'), c("A","B","C","D","E","F","G","H"))

ni <- leaflet() %>%
  addProviderTiles(providers$OpenStreetMap) %>%
  addPolygons(data = shapeData2, popup = ~paste0(Name, ", Band: ",Band, ", Usually Resident Population (2011 Census): ",format(UR_ex, big.mark = ",")), color = ~colfac(Band))

saveWidget(ni, "niSettlements.html")
