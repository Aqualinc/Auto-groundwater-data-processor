# Auto-groundwater-data-processor
Software tools to automagically process large numbers of groundwater level time series data

This page provides a general description of what everything does.
![This link provides details on how to use it](https://github.com/Aqualinc/Auto-groundwater-data-processor/wiki/Auto-groundwater-data-processor-operation)

tools include:
- barometric pressure correction (completed)
- offset correction for sensor level (completed)
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

## Data logger drift correction to manual dips
It is assumed that the data loggers drift over time. To correct for this drift, the logger measurements are regularly compared to manual measurements and adjusted if there is a difference.
There are many ways of doing this.
The approach taken here is described below.

1. The logged measurement is found (after compensation for air pressure and offset for sensor depth) that was recorded at the time closest to the manual measurement time, but within 10 minutes. This is rounded to the nearest centremetre, to allign its precision with the manual measurement.
2. If a difference between the rounded values is found, then the difference between the manual and the full precision logger value is taken as the offset to be applied at that time.
3. Steps 1 and 2 are repeated for all manual measurements.
4. Logged values between manual observations are offset by linear interpolation of the bounding offsets, based on the time.
5. Logged values after the last manual measurement are offset by linear extrapolation of the long term drift.
6. The latest drift offset and the change in drift over time is provided as part of the quality reporting.

## Data quality review and reporting
Unforeseen issues will occur with the data collection and processing. Through incluson of automatic quality reviewing provides a mechanism to flag when manual review of the data may be required.

