## Motion Matching

Motion Matching is a gestural input technique that requires users to track a moving target; a physical or digital target, as displayed by a product or system. Rather than performing a pre-defined sequence of movements from memory (a gesture), users need only to keep matching the (chosen) target’s movements. This project developed three interactive lamps based on the WaveTrace implementation [1]. Using an 9-DOF Inertial Measurement Unit (IMU) embedded in an Android Smartwatch, and RGBW LED strips, these lamps can display ‘general’ purpose lighting - which can be altered using the Motion Matching technique by following one of the coloured targets.

---

## User Study Demos

One folder contains source code for our initial Android app to measure and send movement data to our program. This is an older version, and we advice to look at the Android Standalone Wear app to use in your project. Note that this requires an Android Wear 2 watch. The User Study Demos also include the Processing sketches to rebuild our 4 screen-based demos - that each integrate motion matching interaction differently.

---

## Interactive Lamps

Our interactive lamp designs are operating as follows (feel free to adapt): Each lamp contains one ESP8266 – a Wi-Fi enabled microcontroller programmed with the Arduino IDE [2], that is listening to a Raspberry PI 3.0 (or computer) on a local network. The Raspberry PI runs a Java Application in Processing [3]. The user wears an Android smartwatch (Huawai Watch 2 in our setup), running Android Wear 2.0 or higher. The version is of importance, as since 2.0 the smart watch no longer requires a companion phone to communicate over Wi-Fi. Here, the watch sends the orientation of the user’s hand (using Android's built-in orientation sensor) more than 150 times a second over the Wi-Fi connection (using an UDP protocol). The function of the Raspberry PI is threefold: it receives and stores all user movements that have been send by the Android Smartwatch; it continuously sends commands to each of the lamps (over Wi-Fi) to ensure their correct state; and lastly it continuously runs a simulation of all connected lamps, and correlates the simulation with the incoming movement data, and changes any states upon successful interaction. The lamps have only one microcontroller, though share the 'data' signal using interconnected wires (except for the wall-lamp).

## Required
1. Assembled Interactive Lamps (at least one)
2. Raspberry PI (3.0) or PC/Laptop that can run the Processing Sketch
3. Wi-Fi enabled Router (with static IP's set for all devices, see below)
4. Android Wear 2.0 Watch (e.g. a Huawai Watch 2. Purpose: it should be able to connect to the WiFi without phone (so no middle-man)

## Static IP Addresses
Alternatively, choose IP addresses and alter the Processing, Arduino and Android Code. We have yet to implement the system with DHCP. Currently set IP addresses are:

- Wall lamp: 192.168.1.202
- Standing lamp: 192.168.1.202
- Ceiling lamp: 192.168.1.203
- Raspberry PI / Laptop: 192.168.1.150

## Setup for the Demo
1. Assemble the lamps.
2. Position and connect all devices to the power strip - do not power the powerstrip, yet.
3. Turn on the power strip. Give all devices some time (say 2 minutes). Debug: RED fading LEDS: no Wi-Fi. Blue fading LEDS: no Raspberry messages are being received.
4. Once the Raspberry PI is booted, it should start up the Processing sketch. Once it is running, turn on/off the lamps you are demo-ing. They should display their states.
5. Check the Android Watch and make sure it has a Wi-Fi connection. It can take a while, the watch it not too compliant. If needed, turn the watch off and on.
6. Click the lower hardware button on the Huawai watch - this will start the app (if set as 'hardware button app'). Choose which wrist the user is carrying the watch using the presented buttons on the app. The lamps should now display the targets.
7. To deselect a light, point the watch downwards.
8. Enjoy!
9. Ps. click the top hardware button to close the watch app.

---

## Elaborate Setup the hardware for the demo

![Scheme](/Interactive%20Lights/Images/Illustrations-03.png)
> Figure: The Android smartwatch – running a custom app for Android Wear 2.0 – continuously sends ‘yaw’ and ‘pitch’ data (i.e. movement data) to the Raspberry PI over Wi-Fi. The raspberry continuously simulates the lights and states, and send the appropriate LED settings at 40Hz over Wi-Fi to the individual lights, which will set the LEDs accordingly. The Raspberry PI correlates the incoming movement data and act upon interaction by changing the simulated states, which in turn is communicated to the lights.

1. Use a dedicated router for a local network
2. Change the SSID and PASS in the code to your router (ESP only work on 2.4 GHz networks).
    - Ensure static IP adresses for all three lamps and the Raspberry PI / server computer
    - Alter the Processing code to match the Lamp IP adresses
    - Alter the Android Wear code to alter the Raspberry/Server IP adress
3. Prepare Android Watch with Android Wear 2.0 (developer mode) and install and run the Android app.
4. There is no feedback whether UDP messages are received by either party (they only listen), thus check the Android and Processing Console if data is received, or interactions are registered.
5. Plug the lamps into a power socket.
    - RED glow? The Wi-Fi network cannot be found.
    - BLUE glow? Connected to Wi-Fi but no instrutions received in the pas seconds
    - Normal Light? Working!
6. You should now be able to interact with the Lights. For Demo purposes, currently after a fixed time without any correlation any lamp is deselected. See the Processing code (where all the magic happens) for fine-tuning.
7. The Android Watch only sends motions data. The lamps only receive instructions. The Processing on the Raspberry / Server computer does all the calculations and simualations. Look there for tweaking and such.

Current Implementations of Interactions:
![Interactions](/Interactive%20Lights/Images/Illustrations-06.png)
> Figure: If no particular light has been selected, all lights show their ‘initial’ target. Each target that is displayed differs in phase which allows for distinction based on movement. For clarity, only one module of the standing (middle) and ceiling light (right) is shown. Take note that by design, the standing light (middle) has a ‘virtual’ mirrored target for each of its displayed targets, as the light can be seen from both sides. The system will thus respond to both the shown movement and mirrored movement of those targets. 

Wall Light | Standing Light | Ceiling Light
---------- | -------------- | --------------
Two target moving in opposite direction allow the user to alter the angle of projection by following the clockwise green target (increasing) or the counter-clockwise red target (decreasing). | In total three possible targets can be shown, allowing the user to alter the mode, by following a (counter)clockwise green target (turning all lights on), an oscillating target in the top half (reading mode – light is projected downwards) or in the bottom half (atmospheric mode – light is projected upwards). | Two target moving in opposite direction allow the user to alter the colour temperature by following the clockwise green target (colder) or the counter-clockwise red target (warmer).


---
## Install Notes:
The Processing software is run at boot by adding
`/usr/local/bin/processing-java --sketch=/home/pi/Desktop/<app name> --present`
to the
`~/.config/lxsession/LXDE-pi/autostart`
file.

## References
[1] David Verweij, Augusto Esteves, Vassilis Javed Khan, and Saskia Bakker. 2017. WaveTrace: Motion Matching Input using Wrist-Worn Motion Sensors. In CHI ’17 Extended Abstracts on Human Factors in Computing Systems (CHI EA ’17). ACM, Denver, CO, USA. DOI: http://dx.doi.org/10.1145/3027063.3053161

[2] https://www.arduino.cc/en/Main/Software
