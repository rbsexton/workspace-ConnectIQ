These data fields calculate your 'Time in the Bank' or 'Time in Hand' during your ride.   The time is reported in minutes.

This calculator includes tables for the following closing times:

- ACP 90 Hour rules.   This calculator calculates control close times based upon the ACP 90 hour rules, as interpreted by RUSA.   It's applicable to all brevets sanctioned by RUSA.  
- Uniform 90-Hour time, as used by SIR
- RUSA Permanent time.   Similar to 90 hour ACP rules, but without the 'bonus minutes' that riders get on 200k and 400k events.  Supports RUSA rules for very long permanents ( 200k/day )
- PBP 80 Hour Rules for 2019.     
- PBP 84 Hour Rules for 2019.     
- PBP 90 Hour Rules for 2019.
- LEL 125 Hour Rules, 2022: 1540km.

The PBP calculators are based upon the timetables published by ACP.

You can find instructions on loading the app on the Garmin Site

*Instructions on how to switch are here*

# Supported Devices (as of 2022)
- All garmin device that support data fields.

# Improvements in 2.1.1 

Display time in hand in seconds, minutes + seconds, or Hours + Minutes 

The display now features a *Trend* indicator that shows when you are putting time in the bank. 

You can choose the rules from 

# How to use the app

Time in hand is the control closing time (for a control right where you are) minus your elapsed time.  Positive numbers mean you are ahead of schedule.   Example:  Halfway through a 200k, the calculator reports that you have 90 minutes in the bank.   Riding at the same pace, you can expect to finish the ride in 10.5 (13.5 - 3) hours.

The ACP-90 calculator implements the ACP rules with allowances for the extra finish time for 200k and 400k events (10 and 20 extra minutes, respectively).  

For best results, start the timer on your Garmin at the official start time for your ride.

*Warning!*  This calculator will give you misleading numbers on PBP!  Please use a PBP Specific
calculator for PBP.

## Adjusting for non-standard distances

The calculator uses distance and time.  It does not use routing information.  

When riding an event that is longer than a standard distance, you must make adjustments.  Example: on a 230k event, you must ride an additional 30km within the 13.5h time limit.   Per the rules, thats 2 hours of riding time (30km / 15km/h ).  You must finish the ride with 2 hours in hand, as displayed by the app.

This calculator doesn't implement the special rules for controls in the first 60km of the ride.

## Late and early starts

If you start your ride before or after the official ride time you must factor that in when using the calculator.  Example: If you start 5 minutes late you must finish with at least 5 minutes in the bank.   For events like PBP where your brevet card times may be earlier than your official departure time, start the garmin at your offical start time.

## Missed Turns

This calculator will misleadingly give you time credit for distance ridden off-route.   You can estimate the error using the technique described under non-standard distance. 

# How it works
The Calculator uses a table of controls.   For each control, the calculator knows how many minutes are allowed to arrive at the control, and the required minimum speeds from that control onwards. 

In mathematical terms, control closing time can be described as a piecewise linear graph.   The calculator can calculate the offical closing time for any distance and compare that with your elapsed time.

The tables in the apps are based upon google spreadsheets that you can see
here: <a href="https://docs.google.com/spreadsheets/d/14ysFNrUc_20SzWS6OVvjkP4j7RbKd-nPyg7SgSiM4ww/edit?usp=sharing">PBP 2019 Control Close times</a>

# No Warranties

As is usual, there are no warranties, express or implied.  If you're riding very close to the close times, you probably shouldn't be relying upon this app.

When in doubt, consult your brevet card!

