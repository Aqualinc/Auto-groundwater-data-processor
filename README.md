# Auto-groundwater-data-processor
Software tools to automagically process large numbers of groundwater level time series data

This page provides a general description of what everything does.

[This link provides details on how to use it](https://github.com/Aqualinc/Auto-groundwater-data-processor/wiki/Auto-groundwater-data-processor-operation)

tools include:
- barometric pressure correction (completed)
- offset correction for sensor level (completed)
- comparson of manual dips to logged depths (completed)
- data logger drift correction to manual dips (yet to implement)
- data quality review and reporting (yet to implement)

## Barometric pressure correction
The groundwater level sensors measure pressure. They are fit within each well at a fixed depth within the groundwater. The sensor's pressure measurement is a result of the change in depth of the groundwater, and the change in air pressure. The air pressure variations need to be subtracted to provide the pressure variations associated with just the groundwater variation.
There are three sensors in the network that are not in water, so they measure air pressure only. The data from these sensors are used to correct the groundwater sensors.

## Offset correction for sensor level
The groundwater level format requested by Environment Canterbury is the number of metres above the measuring point. An artesian well will be a positive number, groundwater levels below the measuring points are to be a negative number. The arrangement of the sensor, the groundwater level and the measuring point is shown in the figure below.

![USGS Techniques of Water-Resources Investigations 8-A3 Figure 41](https://pubs.usgs.gov/twri/twri8a3/images/fig41.gif)

*Sensor, water level and measuring point diagram. From Figure 14 of USGS Techniques of Water-Resources Investigations 8-A3*

The height above the measuring point (as requested by Environment Canterbury) is the equivalent of a negative "depth to water below measurement point" in the above diagram. The sensor data, following correction for air-pressure variations, provide a measure of the depth of water above the sensor, shown as the "submergence depth" in the above diagram. Conversion from that measurement to a negative distance from the surface requires subtracting of the sensor "hanging depth" from the submergence pressure:

*Groundwater level above measuring point = submergence pressure - hanging depth*
## Comparson of manual dips to logged depths
The manual measurements obtained at the begining and end of a downloaded time series are compared to the logged depths.
A table is prepared that details the difference between the measurements. This was prepared to enable investigation of where corrections may need to be applied.
## Comparison of logged levels before and after the previous download
The logged level immediately before a download is compared to the logged level immediately after and the difference reported. Large differences indicate the downloading may have affeted the logged levels. This check enables identification of sites for further investigation.
