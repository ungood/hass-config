# HVAC Package Specification

## Overview

Intelligent climate control system for 4 Daikin heat exchanger units with air quality integration, vacation mode, and adaptive scheduling with temperature prediction.

## Hardware Configuration

### HVAC Units (Faikin/MQTT)

- **Living Room** (`climate.faikin_living_mqtt_hvac`)
  - Ceiling unit with integrated air filter
  - Location: Main floor

- **Master Bedroom** (`climate.faikin_master_mqtt_hvac`)
  - Standard wall unit

- **Rec Room/Basement** (`climate.faikin_basement_mqtt_hvac`)
  - Standard wall unit

- **Guest Bedroom** (`climate.faikin_guest_mqtt_hvac`)
  - Ceiling unit with integrated air filter

### Unit Capabilities

- Available modes: Auto, Heat, Cool, Dry, Fan
- Independent on/off control per unit
- **Constraint**: All units that are ON must use the same mode
- Temperature control available in Auto, Heat, and Cool modes

### Sensors

- **PM2.5 Air Quality**: `sensor.main_floor_air_sensor_pm2_5` (AirGradient)
  - Used for calculating Air Quality Index (AQI)
  - Triggers ventilation mode when air quality degrades

## Operating Priorities

The system operates based on **strict priority rules** (higher priorities always override lower priorities):

### Priority 1: Air Quality Ventilation (HIGHEST)
**Trigger**: AQI >= 100 (calculated from PM2.5)

**Action**:
- Units with air filters (Living Room and Guest Bedroom) switch to **Fan mode**
- Fan mode is pure ventilation - no temperature control
- Other units may be turned off or set to match mode
- Overrides all other priorities including sleep mode

### Priority 2: Vacation Mode
**Trigger**: `input_boolean.vacation_mode` is ON

**Action**:
- All units set to **Auto mode** at configured awake temperature
- Maintains minimal climate control while house is unoccupied
- Overridden only by air quality issues

### Priority 3: Sleep Mode
**Trigger**: Current time within sleep hours AND vacation mode OFF AND AQI < 100

**Action**:
- All units set to **Cool mode** at sleep temperature (default 68°F)
- Pre-starts based on learned temperature adjustment time
- Applies to all 4 units uniformly

### Priority 4: Awake Mode (DEFAULT)
**Trigger**: Current time within awake hours AND vacation mode OFF AND AQI < 100

**Action**:
- All units set to **Auto mode** at awake temperature (default 72°F)
- Pre-starts based on learned temperature adjustment time
- Applies to all 4 units uniformly

## Configuration Inputs

### Required Input Booleans
- `input_boolean.hvac_automation_enabled`
  - Master on/off switch for entire automation
  - Default: OFF (require explicit activation)

- `input_boolean.vacation_mode`
  - Triggers vacation operating mode
  - Default: OFF

### Required Input Numbers

- `input_number.hvac_sleep_start_hour`
  - Hour to begin sleep mode (24-hour format)
  - Default: 22 (10:00 PM)
  - Range: 0-23

- `input_number.hvac_sleep_end_hour`
  - Hour to end sleep mode / begin awake mode (24-hour format)
  - Default: 7 (7:00 AM)
  - Range: 0-23

- `input_number.hvac_sleep_temperature`
  - Target temperature during sleep hours
  - Default: 68°F
  - Range: 60-80°F

- `input_number.hvac_awake_temperature`
  - Target temperature during awake hours
  - Default: 72°F
  - Range: 60-80°F

### Required Input Datetimes

- `input_datetime.hvac_sleep_start_time`
  - Precise sleep mode start time (hours and minutes)
  - Default: 22:00
  - Has date: false (time only)

- `input_datetime.hvac_sleep_end_time`
  - Precise sleep mode end time (hours and minutes)
  - Default: 07:00
  - Has date: false (time only)

## Temperature Learning System

### Purpose
Pre-start heating/cooling before scheduled mode transitions so target temperature is reached exactly at the scheduled time.

### Implementation Approach
- **Method**: Simple moving average
- Track time required to reach target temperature from various starting temperatures
- Calculate average adjustment time needed
- Start mode transitions early by the learned duration

### Data to Track

1. **Heating/Cooling Events**
   - Starting temperature
   - Target temperature
   - Time to reach target (±0.5°F)
   - Outside temperature (from Faikin sensors)
   - Mode used (Heat/Cool/Auto)

2. **Historical Data Storage**
   - Store last 30 successful temperature adjustments
   - Separate tracking for heating vs cooling
   - Calculate rolling average of adjustment times

3. **Pre-start Calculation**
   - Before sleep/awake transition, check current temperature
   - Estimate time needed based on temperature delta and historical averages
   - Start mode transition early by calculated duration (max 2 hours early)

### Learning Scenarios

**Example 1 - Sleep Mode:**
- Sleep scheduled for 22:00, target 68°F
- Current temp at 21:30 is 72°F (4° delta)
- System learned cooling 4° takes average of 25 minutes
- System starts cool mode at 21:35 to reach 68°F by 22:00

**Example 2 - Awake Mode:**
- Awake scheduled for 07:00, target 72°F
- Current temp at 06:00 is 65°F (7° delta)
- System learned heating 7° takes average of 45 minutes
- System starts heat/auto mode at 06:15 to reach 72°F by 07:00

## Air Quality Index (AQI) Calculation

### Formula
Convert PM2.5 (μg/m³) to AQI using EPA standard:

```
For PM2.5 range 0-12.0:   AQI = (50/12.0) × PM2.5
For PM2.5 range 12.1-35.4: AQI = ((100-51)/(35.4-12.1)) × (PM2.5-12.1) + 51
For PM2.5 range 35.5-55.4: AQI = ((150-101)/(55.4-35.5)) × (PM2.5-35.5) + 101
And so on...
```

### Threshold
- **AQI < 100**: Normal operation
- **AQI >= 100**: Trigger ventilation mode (fan mode on units with filters)

### Implementation
Create template sensor `sensor.main_floor_aqi` that calculates AQI from `sensor.main_floor_air_sensor_pm2_5`

## Mode Synchronization

### Rule
When multiple units are ON simultaneously, they MUST all use the same HVAC mode.

### Implementation Approach
- Determine desired mode based on priority rules
- If mode change required:
  1. Get list of currently ON units
  2. Set all ON units to new mode simultaneously
  3. Set appropriate temperature targets for mode

### Edge Cases
- If a unit fails to switch modes, log error and notify user
- If mode conflict detected, apply highest priority mode to all units
- Manual overrides temporarily disable automation (restore on next priority change)

## Package Structure

The HVAC package should include:

### 1. Template Sensors (`template.yaml` or in package)
- `sensor.main_floor_aqi` - AQI calculation from PM2.5
- `sensor.hvac_current_priority` - Which priority rule is active
- `sensor.hvac_target_mode` - What mode should be active
- `sensor.hvac_learning_heat_time` - Average time to heat
- `sensor.hvac_learning_cool_time` - Average time to cool

### 2. Input Helpers
- All input_boolean, input_number, and input_datetime entities listed above
- Created via UI or `configuration.yaml`

### 3. Automations
- Air quality monitoring and fan mode trigger
- Vacation mode activation
- Sleep mode scheduling with pre-start
- Awake mode scheduling with pre-start
- Mode synchronization across units
- Learning data collection

### 4. Scripts
- `script.hvac_set_all_units_mode` - Synchronize mode across active units
- `script.hvac_record_temperature_event` - Log learning data
- `script.hvac_calculate_prestart` - Determine early start time

### 5. Data Storage
- Use `input_text` or file-based storage for learning history
- Consider using AppDaemon or pyscript for complex learning calculations

## Future Enhancements (Out of Scope for v1)

- Per-room temperature targets
- Different schedules for different rooms
- Integration with weather forecasts
- Occupancy-based room-level control
- Energy usage tracking and optimization
- Smart recovery from manual overrides