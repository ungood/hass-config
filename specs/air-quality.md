# Air Quality Management Specification

## Overview

This specification defines automated air quality management for the home using AirGradient sensors and dedicated air filter fans. The system monitors particulate matter (PM2.5, PM10) and volatile organic compounds (VOC) on each floor and automatically controls air filtration to maintain healthy air quality levels.

### Goals

- Maintain air quality below healthy thresholds automatically
- Operate independently per floor based on local sensor readings
- Prevent rapid fan cycling with hysteresis timing
- Respect sleep schedule to avoid noise during sleep hours
- Minimize noise and energy usage while ensuring air quality

### Floors Covered

- **Upstairs (Main Floor)**: Living areas, bedrooms, kitchen
- **Basement**: Rec room, laundry, garage access

## System Components

### Air Quality Sensors

Each floor has one AirGradient sensor providing real-time air quality metrics:

- **Upstairs**: Located on main floor covering living areas, bedrooms, and kitchen
- **Basement**: Located in basement covering rec room, laundry, and garage access

**Sensor Capabilities:**
- PM2.5 measurement (particulate matter ≤ 2.5 micrometers)
- PM10 measurement (particulate matter ≤ 10 micrometers)
- VOC Index (volatile organic compound index, scale 0-500)
- Real-time monitoring with continuous updates

### Air Filter Fans

Each floor has one dedicated air filter fan capable of removing PM2.5, PM10, and VOCs:

- **Upstairs filter**: Serves main floor
- **Basement filter**: Serves basement floor

**Fan Capabilities:**
- Binary control only (on/off, no variable speed control)
- When enabled, operates at fixed speed until disabled
- Can be manually controlled by user
- Can be automated based on air quality readings

## Air Quality Thresholds

The system uses the following thresholds to determine when filtration is needed:

| Metric | Threshold | Unit | Rationale |
|--------|-----------|------|-----------|
| PM2.5 | 2.0 | ug/m3 | WHO air quality guideline (24-hour mean: 15 ug/m3; keeping well below) |
| PM10 | 2.0 | ug/m3 | Conservative threshold (WHO guideline: 45 ug/m3; keeping well below) |
| VOC Index | 100 | index | Index value where air quality begins to degrade from "excellent" |

### Air Quality States

- **GOOD**: All three metrics are at or below their thresholds
- **POOR**: One or more metrics exceed their threshold

## Automation Logic

### Design Pattern

The system uses **two independent automations per floor**:
1. **Turn ON automation**: Triggers when air quality becomes poor
2. **Turn OFF automation**: Triggers when air quality returns to good

This separation allows for different timing requirements (hysteresis) for each action.

### Floor Independence

Each floor operates completely independently:
- Upstairs automation only monitors upstairs sensors and controls upstairs fan
- Basement automation only monitors basement sensors and controls basement fan
- No coordination between floors

### Hysteresis (Anti-Cycling)

To prevent rapid on/off cycling:

**Turn ON Behavior:**
- Wait for ANY threshold to be exceeded for 1 minute continuously
- If levels drop below threshold before 1 minute, cancel the turn-on action
- Once triggered, turn on the fan immediately

**Turn OFF Behavior:**
- Wait for ALL thresholds to return to good for 5 minutes continuously
- If any level exceeds threshold during the 5 minutes, reset the timer
- Once triggered, turn off the fan immediately

### Triggers

#### Turn ON Triggers (per floor)

The air filter should turn on when ANY of the following air quality thresholds are exceeded continuously for 1 minute:

1. PM2.5 exceeds 2.0 ug/m3
2. PM10 exceeds 2.0 ug/m3
3. VOC Index exceeds 100

**Timing**: The 1-minute delay prevents brief spikes from triggering filtration unnecessarily.

#### Turn OFF Triggers (per floor)

The air filter should turn off when ALL of the following conditions are met continuously for 5 minutes:

- PM2.5 is at or below 2.0 ug/m3
- PM10 is at or below 2.0 ug/m3
- VOC Index is at or below 100
- Filter is currently running
- Filter was turned on by automation (not manually)

**Timing**: The 5-minute delay ensures air quality is stable before stopping filtration and prevents rapid cycling.

**Note**: Filters that were manually turned on will NOT automatically turn off. See Manual Override section for details.

### Conditions

The turn-on automation should only execute when:

1. **Outside of sleep schedule**
   - Rationale: Fan noise may disturb sleep; fans should not automatically turn on during sleep hours
   - Sleep hours to be defined (e.g., 10 PM to 7 AM)

2. **Fan is not already on**
   - Rationale: Prevents re-triggering automation for a fan that is already running (either from previous automation or manual control)

### Actions

#### Turn ON
When triggered and conditions are met, enable the air filter for the respective floor.

#### Turn OFF
When triggered and conditions are met, disable the air filter for the respective floor.

## Dependencies

### Sleep Schedule

A sleep schedule must be defined to determine when fans should not automatically turn on:

**Purpose**: Prevent fans from automatically turning on during sleep hours to avoid noise disturbance

**Requirements:**
- Define sleep hours (e.g., 10 PM to 7 AM)
- Could be a fixed schedule or use a schedule helper
- Future enhancement: Could integrate with presence detection or bedtime routines

**Key characteristic**: During sleep hours, fans will not automatically turn on

### Automation Control Helpers

Two input boolean helpers must be created to track whether fans are in automation control mode:

**Purpose**: Distinguish between automation-controlled fans (which auto turn-off) and manually-controlled fans (which don't)

**Requirements:**
- Create `input_boolean.upstairs_filter_auto_mode`
- Create `input_boolean.basement_filter_auto_mode`
- Set to `on` when automation turns on the fan
- Set to `off` when user manually turns on the fan
- Turn-off automation only executes when the respective helper is `on`

### Filter Change Tracking

Each air filter fan should track runtime to alert when filter replacement is needed:

**Requirements:**
- Track total runtime hours for each filter
- Create a persistent notification when filter requires changing
- Filter change threshold to be defined (e.g., after 720 hours / 30 days of runtime)
- Notification should remain until dismissed by user
- Runtime counter should reset when user dismisses the notification (indicating filter has been changed)

**Implementation suggestion**: Use a counter helper or history stats sensor to track runtime

## Automation Summary

### Required Automations

The system requires the following automations:

#### Air Quality Control

1. **Upstairs Air Filter - Turn ON**
   - Trigger: Any upstairs air quality metric exceeds threshold for 1 minute
   - Condition: Outside of sleep schedule AND fan is not already on
   - Action: Enable upstairs air filter and mark as "automation-controlled"

2. **Upstairs Air Filter - Turn OFF**
   - Trigger: All upstairs air quality metrics below threshold for 5 minutes continuously
   - Condition: Fan is running AND fan was turned on by automation (not manually)
   - Action: Disable upstairs air filter

3. **Basement Air Filter - Turn ON**
   - Trigger: Any basement air quality metric exceeds threshold for 1 minute
   - Condition: Outside of sleep schedule AND fan is not already on
   - Action: Enable basement air filter and mark as "automation-controlled"

4. **Basement Air Filter - Turn OFF**
   - Trigger: All basement air quality metrics below threshold for 5 minutes continuously
   - Condition: Fan is running AND fan was turned on by automation (not manually)
   - Action: Disable basement air filter

5. **All Filters - Turn OFF at Sleep Schedule**
   - Trigger: Sleep schedule starts
   - Condition: None
   - Action: Disable both upstairs and basement air filters

#### Filter Maintenance

6. **Upstairs Filter - Change Notification**
   - Trigger: Upstairs filter runtime exceeds threshold (e.g., 720 hours)
   - Condition: None
   - Action: Create persistent notification requesting filter change

7. **Basement Filter - Change Notification**
   - Trigger: Basement filter runtime exceeds threshold (e.g., 720 hours)
   - Condition: None
   - Action: Create persistent notification requesting filter change

**Note**: Each notification should include an action to dismiss and reset the runtime counter.

**Implementation Note**: To distinguish between automation-controlled and manually-controlled fans, use an input boolean helper for each fan (e.g., `input_boolean.upstairs_filter_auto_mode`). Set to `on` when automation turns on the fan, and to `off` when user manually controls it.

## Edge Cases & Considerations

### 1. Manual Override

**Scenario**: User manually turns fan on or off

**Behavior:**
- **Manual turn-on**: Fan remains on and will NOT automatically turn off when air quality improves. Fan only turns off when:
  - Sleep schedule starts (all fans turn off at beginning of sleep hours)
  - User manually turns it off
- **Manual turn-off during poor air quality**: Fan remains off during sleep hours. Outside sleep hours, automation will turn it back on after 1 minute if air quality is still poor
- **Automation turn-on**: Fan automatically turns off after air quality remains good for 5 minutes continuously

**Rationale**: This allows users to run filters continuously if desired (e.g., during parties, cleaning, or other activities) without the automation interfering, while still providing automatic turn-off when the automation triggered the fan.

### 2. Sensor Unavailable

**Scenario**: Sensor becomes unavailable or reports null/unknown state

**Expected Behavior**:
- If sensor goes offline while fan is OFF: Fan should not turn on (safe default)
- If sensor goes offline while fan is ON: Fan should not turn off (safe default - keeps filtering)

**Future Enhancement**: Could add notification when sensors become unavailable

### 3. Sleep Schedule Transitions

**Scenario**: Sleep schedule starts or ends while automation is waiting or fan is running

**Expected Behavior**:
- **Sleep schedule starts**: All fans should turn off immediately, regardless of air quality
- **Sleep schedule ends**: Automations resume normal operation; if air quality is poor, fans will turn on after 1 minute
- If sleep schedule starts while automation is waiting (during 1-minute delay to turn on), the pending action should be cancelled

### 4. Both Sensors Show Poor Air Quality Simultaneously

**Scenario**: Event affecting whole house (cooking, cleaning products, etc.)

**Expected Behavior**: Both floors will turn on their fans independently
- Each floor responds to local conditions
- No coordination needed
- Both fans may run simultaneously

### 5. Threshold Oscillation

**Scenario**: Sensor readings oscillate around threshold value

**Mitigation**:
- 1-minute delay for turn-on prevents brief spikes from triggering fan
- 5-minute delay for turn-off ensures air quality is stable before stopping filtration
- Hysteresis naturally handles minor fluctuations

### 6. Multiple Triggers While Fan Running

**Scenario**: Fan is already on, and turn-on automation triggers again

**Expected Behavior**: Enabling an already-enabled fan should be harmless (no-op)
- No negative effects
- Automation remains idempotent

### 7. Power Outage or Home Assistant Restart

**Scenario**: System restarts while fan is running

**Expected Behavior**:
- After restart, automations should evaluate current conditions
- If air quality is poor, automation should turn fan back on (after 1 minute)
- If air quality is good and fan is running, automation should turn fan off (after 5 minutes)

**Self-correction**: System should self-correct within 1-6 minutes of restart

## Testing Scenarios

### Test 1: Normal Turn-On Sequence

**Setup**: Air quality is good, fan is off, no scenes active

**Procedure**:
1. Increase PM2.5 above 2.0 ug/m3 (e.g., by generating particulates near sensor)
2. Wait 30 seconds - verify fan does NOT turn on
3. Keep PM2.5 elevated for full 60 seconds
4. Verify fan turns on after 1 minute

**Expected Result**: Fan turns on after 1 minute of continuous poor air quality

### Test 2: Automation Turn-Off

**Setup**: Fan was turned on by automation, air quality becomes good

**Procedure**:
1. Allow automation to turn on fan (via poor air quality)
2. Improve air quality - ensure all metrics drop below thresholds
3. Wait 3 minutes - verify fan does NOT turn off
4. Keep all metrics below thresholds for full 5 minutes
5. Verify fan turns off after 5 minutes

**Expected Result**: Fan turns off after 5 minutes of continuous good air quality when it was turned on by automation

### Test 3: Trigger Cancellation (Turn-On)

**Setup**: Air quality is good, fan is off

**Procedure**:
1. Increase PM2.5 above 2.0
2. Wait 30 seconds
3. Reduce PM2.5 below 2.0 (before 1 minute elapses)
4. Wait additional 60 seconds

**Expected Result**: Fan never turns on (trigger was cancelled)

### Test 4: Duplicate Turn-On Prevention

**Setup**: Fan is already running due to poor air quality

**Procedure**:
1. Fan is on (triggered by automation)
2. Air quality remains poor
3. Verify automation does not re-trigger

**Expected Result**: Automation recognizes fan is already on and does not trigger again (idempotent behavior)

### Test 5: Sleep Schedule Prevents Turn-On

**Setup**: PM2.5 is elevated above 2.0 for more than 1 minute during sleep hours

**Procedure**:
1. Ensure sleep schedule is active
2. Increase PM2.5 above 2.0
3. Wait 2 minutes with elevated PM2.5

**Expected Result**: Fan does not turn on while sleep schedule is active

### Test 6: Sleep Schedule Turns Off Fans

**Setup**: Fan is running, sleep schedule starts

**Procedure**:
1. Manually turn on fan or trigger via air quality
2. Wait for sleep schedule to start

**Expected Result**: Fan turns off immediately when sleep schedule starts, regardless of air quality

### Test 7: Manual Turn-On - No Auto Turn-Off

**Setup**: User manually turns on fan

**Procedure**:
1. Outside of sleep hours, manually turn on fan
2. Wait for air quality to return to good levels (or ensure it's already good)
3. Wait 10+ minutes with good air quality
4. Verify fan remains on (no automatic turn-off)
5. Wait for sleep schedule to start
6. Verify fan turns off when sleep schedule starts

**Expected Result**:
- Fan remains on even with good air quality for 10+ minutes
- Fan does NOT turn off due to good air quality (only sleep schedule turns it off)
- Fan turns off when sleep schedule starts

### Test 8: Floor Independence

**Setup**: Create poor air quality condition on only one floor

**Procedure**:
1. Elevate PM2.5 on upstairs only
2. Keep basement air quality good
3. Wait 1+ minutes

**Expected Result**: Only upstairs fan turns on; basement fan remains off

### Test 9: Multiple Threshold Exceedances - Auto Turn-Off

**Setup**: Elevate multiple metrics simultaneously, allow automation to turn on fan

**Procedure**:
1. Increase both PM2.5 and VOC Index above thresholds
2. Wait 1+ minute - verify fan turns on (automation-controlled)
3. Reduce only PM2.5 below threshold (VOC still elevated)
4. Wait 6+ minutes - verify fan does NOT turn off (VOC still high)
5. Reduce VOC below threshold
6. Wait 3 minutes - verify fan does NOT turn off yet
7. Keep all metrics below threshold for full 5 minutes
8. Verify fan turns off

**Expected Result**:
- Fan turns on after 1 minute (when any metric was high)
- Fan remains on while any metric is elevated
- Fan remains on for 3 minutes after all metrics drop (hysteresis)
- Fan turns off after all metrics below threshold for 5 continuous minutes

### Test 10: Filter Change Notification

**Setup**: Filter runtime approaches or exceeds threshold

**Procedure**:
1. Ensure filter runtime tracking is working
2. Allow filter to run until threshold is reached (or simulate runtime)
3. Verify persistent notification is created
4. Dismiss notification
5. Verify runtime counter resets

**Expected Result**:
- Notification appears when runtime threshold is reached
- Notification persists until dismissed
- Runtime counter resets when notification is dismissed

## Future Enhancements

These are potential improvements not included in the initial specification:

1. **Notification System**: Alert users when sensors go offline or when fans run for extended periods
2. **Adaptive Thresholds**: Adjust thresholds based on outdoor air quality or seasonal variations
3. **Smart Scene Integration**: Automatically activate sleeping scene based on bedtime routines
4. **Fan Runtime Statistics**: Track and report fan runtime for maintenance scheduling
5. **Multi-Speed Control**: If fans are upgraded to support variable speeds, adjust fan speed based on severity of air quality issue
6. **Whole-House Coordination**: If air quality is poor throughout house, coordinate with HVAC system
7. **Predictive Activation**: Learn patterns (e.g., cooking times) and pre-emptively activate filtration
8. **Integration with Weather**: Adjust thresholds or disable outdoor air intake during poor outdoor air quality days

## Success Criteria

The implementation will be considered successful when:

1. All seven automations are created and enabled
2. Sleep schedule is defined and functional
3. Input boolean helpers created to track automation vs manual control mode
4. Filter runtime tracking is implemented for both filters
5. All test scenarios pass successfully
6. Fans automatically turn on when air quality is poor (outside sleep hours)
7. Fans automatically turn off when air quality improves (if they were turned on by automation)
8. Manually-turned-on fans do NOT automatically turn off (only at sleep schedule)
9. Fans turn off when sleep schedule starts
10. Each floor operates independently
11. Filter change notifications appear and reset correctly
12. No unintended behavior during edge cases
13. Configuration validates successfully
