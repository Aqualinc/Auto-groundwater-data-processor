# Auto-groundwater-data-processor
Software tools to automagically process large numbers of groundwater level time series data

tools include:
- barometric pressure correction
- offset correction for sensor level
- data logger drift correction to manual dips
- data quality review and reporting

## Data logger drift correction to manual dips
It is assumed that the data loggers drift over time. To correct for this drift, the logger measurements are regularly compared to manual measurements and adjusted if there is a difference.
There are many ways of doing this.
The approach taken here is described below.
The logged measurement is found (after compensation for air pressure and offset for sensor depth) that was recorded at the time closest to the manual measurement time, but within 10 minutes. This is rounded to the nearest centremetre, to allign its precision with the manual measurement.
If a difference between the rounded values is found, then the difference between the manual and the full precision logger value is taken as the offset to be applied at that time.
This is repeated for all manual measurements.
For logged values in between the manual observations, the offset is taken as a linear interpolation from the bounding offsets, based on the time.
For logged measurements after the last manual measurement, the lesser of the long term drift or the latest drift is applied.
The latest drift offset and the change in drift over time is provided as part of the quality reporting.
