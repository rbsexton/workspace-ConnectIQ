# Running from the prompt.


export CIQ_SDK="$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-7.4.3-2024-12-11-90ec25e45/"

export PATH=$PATH:`cat $HOME/Library/Application\ Support/Garmin/ConnectIQ/current-sdk.cfg`/bin



connectiq

java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "/Users/robert/Library/Application Support/Garmin/ConnectIQ/Sdks/connectiq-sdk-mac-6.2.1-2023-06-26-124cb49c5/bin/monkeybrains.jar" -o bin/RandoCalcV4.prg -f /Users/robert/projects/workspace-ConnectIQ/RandoCalcV4/monkey.jungle --unit-test  -y /Users/robert/eclipse201903/developer_key.der -d edge540 -w

monkeyc -d  edge540  -f monkey.jungle -o bin/hand_build.prg -y /Users/robert/eclipse201903/developer_key.der 


# Localization and Strings 

Each language has a strings.xml file.   Example:

```
    <string id="ACP90">ACP90</string>
    <string id="PBP90">PBP90</string>
```
This information is used by the properties.xml file.   There is no default value for any strings.   They must be supplied.
