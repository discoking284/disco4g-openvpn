## About Disco4g-openvpn

Fork of the great [Disco4G mod](https://github.com/uavpal/disco4g) to allow an OpenVPN self hosted alternative to ZeroTier for the bridge between Disco and Skycontroller.

In this Example we will use an OpenWRT router running OpenVPN server.\
Full instructions are below and here is a video showing the whole process.

** I have not yet tested in flight but Freeflight connection and video stream appears to work without issue
** Test at your own risk

[![Youtube video](https://i.postimg.cc/8c7L2dPQ/thumbail2.png)](https://www.youtube.com/watch?v=HrJRTCvexbM)
&nbsp;

## Installation (OpenWRT router used for example - 22.x and above)

### OpenWRT Router / OpenVPN Server setup:

* Download and extract the mod from Github - https://codeload.github.com/discoking284/disco4g-openvpn/zip/refs/heads/master

* Using an OpenWRT router. Ensure devices are working OK and can connect to the Internet.

* SSH into your OpenWRT router.
  
      opkg update
      opkg install luci-app-openvpn openvpn-easy-rsa openvpn-openssl nano ddns-scripts-noip luci-app-ddns
  
  Restart the router.
  &nbsp;

* Ensure you know the IP / Hostname of your home connection. You will either need a static IP address or a dynamic DNS hostname if your IP address changes.\
  [www.noip.com](http://www.noip.com) offer a hostname as a free service, create an account and choose a hostname. Then follow the video instructions below to make OpenWRT router update the hostname with your latest IP address. This will then allow you to be able to access your Home connection from a hostname e.g host1.ddns.net<br>
  
  [OpenWRT - How to VPN into your Home network from anywhere using OpenVPN | Roadwarrior - YouTube](https://youtu.be/FnvP7dOmy9w?feature=shared&t=202)<br><br>
  ![](https://i.postimg.cc/L6nV5zZP/image.png)
  &nbsp;

* Client config directory set up - Specific OpenVPN configs for the Disco and Sky Controller.\
  SSH into the router again.
  
      mkdir /etc/openvpn/ccd
      cd /etc/openvpn/ccd
  
  The below names are important, these are related to the names of the OpenVPN client certificates when they are generated.\
  My provided included example certificates have the names Client_Disco and Client_SkyController
  
      nano Client_Disco
  
  Copy and Paste the below, then CTRL+S and CTRL+X to save and quit.
  
      iroute 192.168.42.0 255.255.255.0
      push 'route 192.168.52.0 255.255.255.0'
  
  ![](https://i.postimg.cc/0jcdg7Pn/image.png)
  &nbsp;
  
      nano Client_SkyController
  
  Copy and Paste the below, then CTRL+S and CTRL+X to save and quit.
  
      push 'route 192.168.52.0 255.255.255.0'
      push 'route 192.168.42.0 255.255.255.0'
  
  &nbsp;

* Add the OpenVPN Server Config\
  SSH into the router.
  
      > /etc/config/openvpn
      nano /etc/config/openvpn
  
  \## Paste the below then CTRL+S and CTRL+X to save.
  
      config openvpn 'VPN_Tun_Server'
          option cipher 'AES-128-GCM'
          option client_config_dir '/etc/openvpn/ccd'
          option client_to_client '1'
          option comp_lzo 'no'
          option dev 'tun0'
          option duplicate_cn '1'
          option enabled '1'
          option ifconfig_pool_persist '/etc/openvpn/ipp.txt'
          option keepalive '10 60'
          option mode 'server'
          option mssfix '1420'
          option persist_key '1'
          option persist_tun '1'
          option port '7506'
          option proto 'udp'
          option remote_cert_tls 'client'
          option reneg_sec '0'
          option route '192.168.42.0 255.255.255.0'
          option server '10.42.0.0 255.255.255.0'
          option topology 'subnet'
          option verb '3'
          option ca '/etc/openvpn/ca.crt'
          option dh '/etc/openvpn/dh.pem'                
          option cert '/etc/openvpn/Server.crt'
          option key '/etc/openvpn/Server.key'

&nbsp;

* Access the OpenWRT router e.g http://192.168.1.1

* Access System > System and ensure the Time and Date is correct.

* Click Network > Interfaces > Devices tab.
  ![](https://i.postimg.cc/Fs5FL15W/image.png)
  
  &nbsp;

* Click 'Add Device Configuration'.\
  Device Type > Bridge device\
  Tick 'Bring up empty bridge'.\
  Click Save.\
  Click Save & Apply.\
  &nbsp;

* Click Interfaces tab.\
  Click 'Add new Interface'\
  Name > LAN_DISCO\
  Protocol > Static address\
  Device > Bridge - br-lan-disco\
  Click Create Interface.\
  IPV4 address > 192.168.52.1\
  Netmask > 255.255.255.0\
  Click DHCP Server tab.\
  Click Set UP DHCP Server.\
  Click Save.\
  Click Save & Apply.\
  &nbsp;

* Click Network > Firewall\
  Click Add.\
  Name > lan_disco\
  Covered Networks > LAN_DISCO\
  Allow Forward to destination zone > WAN\
  Click Save.\
  Click Save & Apply.\
  &nbsp;

* Click Traffic Rules tab.\
  Click Add.\
  Name > OpenVPN\
  Source Zone > WAN\
  Destination Zone > Device (Input)\
  Destination Port > 7500-7510\
  Click Save.\
  Click Save & Apply.\
  &nbsp;

* Click Network > Interfaces.\
  Click LAN_DISCO > Edit\
  Click Firewall Settings tab\
  Select LAN_DISCO firewall.\
  Click Save > Save & Apply.\
  &nbsp;

* Click VPN > OpenVPN\
  Click Edit for VPN_Tun_Server\
  &nbsp;
  Upload the example OpenVPN files for ca, dh, cert, key in the openvpn_certificate_example directory.
  ![](https://i.postimg.cc/W32sWTkP/image.png)
  &nbsp;
  
  ################################################################################
  
  ** For security I would advise to create your own certificates. To create your own follow the video link guide below.\
  Remember to generate two client certificates Client_Disco and Client_SkyController.
  
  &nbsp;
  **ONLY IF** using your own certificates, you need to open the generated ca.crt , client.crt / client.key files for Disco and Sky Controller, then copy the three sections to the openvpn.conf files for Disco and Sky Controller.
  
  &nbsp;
  -----BEGIN CERTIFICATE-----\
  MIIDYzCCAkugAwIBAgIQF/TkguH+..........\
  -----END CERTIFICATE-----
  
  &nbsp;
  disco/uavpal/conf/openvpn.conf\
  skycontroller2/uavpal/conf/openvpn.conf\
  
  [OpenWRT - How to VPN into your Home network from anywhere using OpenVPN | Roadwarrior - YouTube](https://youtu.be/FnvP7dOmy9w?feature=shared&t=275)
  
  &nbsp;
  
  ################################################################################
  
  &nbsp;
  
    Select the uploaded files to the correct fields ca , dh, cert, key
  
  &nbsp;
    ![](https://i.postimg.cc/59rMvwnJ/image.png)
  
  &nbsp;
  
  Click Save & Apply\
  Click VPN > OpenVPN\
  Click Start to enable the OpenVPN server.\
  ![](https://i.postimg.cc/y6RzmD5S/image.png)
  &nbsp;
- Click Network > Firewall\
  Click lan_disco > Edit\
  Click 'Advanced Settings' tab\
  Covered Devices - Select tun0\
  ![](https://i.postimg.cc/YSyTB74F/image.png)
  &nbsp;
  
  Click Save.\
  Click Save & Apply.
  &nbsp;

### Disco / Sky Controller Installation:

* OpenVPN Mod Configuration
  disco/uavpal/conf/apn - Edit and insert the name of your Mobile Data APN e.g three.co.uk\
  disco/uavpal/conf/openvpn.conf - Edit and replace **myhost.ddns.net** with your IP or hostname\
  skycontroller2/uavpal/conf/openvpn.conf - Edit and replace **myhost.ddns.net** with your IP or hostname\
  skycontroller2/uavpal/conf/ssid - Edit and replace with the name of your mobile devices Hotspot name.\
  skycontroller2/uavpal/conf/wpa- Edit and replace with the name of your mobile devices Hotspot password.

* If you have previously installed the Disco4g mod, we will first uninstall to clean up.

* Ensure Disco and Sky Controller are powered up.

* Connect PC to Disco via Wi-Fi.\
  Uninstall / Cleanup - Transfer disco4g-openvpn mod folder to the Disco (read the original mods install procedure to familiarize yourself)\
  FTP 192.168.42.1 - Transfer folder to /internal_000
  
      telnet 192.168.42.1
      
      mv /data/ftp/internal_000/disco4g-* /tmp/disco4g
      chmod +x /tmp/disco4g/*/*_uninstall.sh
      /tmp/disco4g/disco/disco_uninstall.sh
      /tmp/disco4g/skycontroller2/skycontroller2_uninstall.sh
      rm -r /tmp/disco4g

* Install - Transfer disco4g-openvpn mod folder to the Disco\
  Connect PC to Disco via Wi-Fi.\
  FTP 192.168.42.1 - Transfer folder again to /internal_000
  
      telnet 192.168.42.1
      mv /data/ftp/internal_000/disco4g-* /tmp/disco4g
      chmod +x /tmp/disco4g/*/*_install.sh
      /tmp/disco4g/disco/disco_install.sh
      /tmp/disco4g/skycontroller2/skycontroller2_install.sh
      reboot

* Reboot both Disco and Sky Controller.

* Disable main Wi-Fi on Mobile Device to ensure on Mobile Data connection.

* Enable Wi-Fi Hotspot on Mobile Device. Ensure SSID and Password are correct.

* Once Sky Controller is connected to Disco via Wi-fi. Switch to 4G, double pressing the Settings button.

* Check OpenWRT Logs for Disco and Sky Controller connections.
  Status tab > System Logs.

* Test 4G Mod.

### Troubleshooting:

* **SkyController - ADB Shell**
  Install ADB on PC, Attach USB hub to SkyController USB, Attach USB Ethernet
  Attach cable from PC to SkyController USB Ethernet
  Set the PC Ethernet IP to 192.168.53.10
  Open Command Prompt.
  
      adb connect 192.168.53.1:9050
      adb shell

* **Logs**\
  Disco & Sky Controller when accessing via telnet and adb
  
      ulogcat | grep uavpal
      
      cat /tmp/openvpn.log

################################################################################

&nbsp;
&nbsp;
![UAVPAL Logo](https://uavpal.com/img/uavpal-logo-cut-461px.png)

# Parrot Disco over 4G/LTE (softmod)

## About

Disco4G is a software modification (softmod) for the Parrot Disco drone. Instead of the built-in regular Wi-Fi, it allows to use a 4G/LTE cellular/mobile network connection to link Skycontroller 2 to the Disco. Control/telemetry and live video stream are routed through the 4G/LTE connection. In other words, range limit becomes your imagination! Ok, to be fair, it's still limited by the battery capacity :stuck_out_tongue_winking_eye:

[![Youtube video](https://uavpal.com/img/yt_thumbail_github.png)](https://www.youtube.com/watch?v=e9Xl3tTwReQ)
![Disco4G softmod](https://image.ibb.co/eP6A3c/disco4glte.jpg)

Pros:

- Range limit is no longer dependent on Wi-Fi signal
- Low hardware cost (around US$ 40.-)
- All stock hardware can be used (standard Parrot Skycontroller 2 with FreeFlight Pro App)
- Return-to-home (RTH) is auto-initiated in case of connection loss
- Allows independent real-time GPS tracking via [Glympse](https://www.glympse.com/get-glympse-app/)
- Easy initiation of 4G/LTE connection via Skycontroller 2 button
- Can be used for manually controlled flights as well as flight plans
- :boom: Videos and photos can be recorded to a [microSD card inside the 4G modem](#sdcard)

Cons:

- Dependent on [4G/LTE mobile network coverage](https://en.wikipedia.org/wiki/List_of_countries_by_4G_LTE_penetration) 
- Might incur mobile data cost (dependent on your mobile network operator)
- [Slightly higher latency](https://uavpal.com/disco/faq#latency) as compared to Wi-Fi

## Community

[![UAVPAL Slack Workspace](https://uavpal.com/img/slack.png)](https://uavpal.com/slack)

Instructions too technical? Having trouble installing the softmod? Questions on what hardware to order? Want to meet the developers? Interested in other mods (batteries, LEDs, etc.)? Interested to meet like-minded people? Having a great idea and want to let us know?\
We have a great and very active community on Slack, come [join us](https://uavpal.com/slack)!

## Why?

- The Parrot Disco's stock Wi-Fi loses video signal way before the specified 2 km.
- Because we can :grin:

## How does it work?

![High-level connection diagram](https://uavpal.com/img/disco4g_highlevel_diagram_end2end_v2.png)

In simple terms, the Wi-Fi connection is hijacked and routed via a tethering device (e.g. mobile phone) through a 4G/LTE cellular/mobile network to the Disco. As tethering device, any modern mobile phone can be used (iOS: "Personal Hotspot" or Android: "Portable WLAN hotspot").
The Disco requires a 4G/LTE USB modem to be able to send and receive data via cellular/mobile networks.

![USB Modem inside Disco's canopy](https://preview.ibb.co/g5rgNS/modem_in_disco.jpg)

Initiation of the 4G/LTE connection (and switch back to Wi-Fi) can be done by simply pressing the Settings button twice on Skycontroller 2.

![Settings Button on Skycontroller 2](https://image.ibb.co/iBWcgn/settingsbutton.jpg)

The "Power" LED on Skycontroller 2 will change to solid blue once the 4G/LTE connection to the Disco is established.

[![Skycontroller 2 with blue LED](https://image.ibb.co/f5Uz97/SC2_small_blue.jpg)](https://www.youtube.com/watch?v=SEz70ClCetM)

Once up in the air, everything works in the same manner as with the stock Wi-Fi connection, e.g. flight plans, return-to-home (auto-initiated in case of connection loss), etc.

The mobile device running FreeFlight Pro (the one connected to Skycontroller 2 via USB) can even be the same as the mobile tethering device/phone.

[ZeroTier](https://zerotier.com) is a free online service, which we use to manage and encrypt the connection between the Disco and Skycontroller 2. ZeroTier will find the fastest and shortest connection (e.g. by doing NAT traversal) to give you the best possible performance, regardless of the mobile operator's network topology.

Additionally, [Glympse](https://www.glympse.com/get-glympse-app/), a free App for iOS/Android, allows independent real-time GPS tracking and shows [detailed telemetry data](https://uavpal.com/disco/faq#whyglympse) (signal strength, altitude, speed, compass, battery and latency) of the Disco via 4G/LTE. This can be particularly useful to recover the Disco in the unfortunate event of a crash or flyaway.

![Glympse App showing Disco's location](https://uavpal.com/img/glympse_disco.jpg)

<a name="sdcard">The latest (optional) feature of our softmod is the video and photo recording to a microSD card inside the 4G modem.
![E3372h 4G USB modem with microSD card](https://uavpal.com/img/E3372_microSD.png)

This gives you

- More storage space available than the built-in 32 GB: great for longer flights or multiple flights where videos cannot be transferred to a PC immediately.
- No more long transfer time required from the Disco to a PC (usually done via USB cable or Wi-Fi).
- Saves battery power (and reduces charging cycles long-term) as videos don't have to be transferred on a battery-powered CHUCK.
- The microSD card can be unplugged after the flight and plugged into a PC - the pilot can watch the video immediately without having to transfer anything first.

:point_right: More infos in [this FAQ entry](https://uavpal.com/disco/faq#sdcard)

## Requirements

*Hardware:*

- [Parrot Disco](https://www.parrot.com/us/drones/parrot-disco) / [Parrot Disco-Pro AG](https://www.parrot.com/business-solutions-us/parrot-professional/parrot-disco-pro-ag) with firmware 1.4.1 to 1.7.1 <details><summary>**Buy now!**</summary>
   [Order fom Amazon ~US$850.00](https://amzn.to/3JzeUHN)
  
  </details>

- Skycontroller 2 (silver joysticks) with firmware 1.0.7 - 1.0.9\
  or

- Skycontroller 2P (black joysticks) with firmware 1.0.3 - 1.0.5

- [Huawei E3372 4G USB modem](https://consumer.huawei.com/en/mobile-broadband/e3372/specs/) or [compatible](https://github.com/uavpal/disco4g/wiki/FAQ#othermodems) and [SIM card](https://uavpal.com/disco/wiki/Known-Working-Mobile-Carriers-and-Settings) <details><summary>**Buy now!**</summary>
   Huawei E3372h-153 (Europe, Asia, Middle East, Africa)\
  
          [Order from AliExpress ~US$36.00](http://s.click.aliexpress.com/e/gIswgqG)\
          [Order from Amazon ~US$42.00](https://amzn.to/2WyTdDv)\
  
   &nbsp;  
   Huawei E3372h-510 (USA, Latin America, Caribbean)\
  
          [Order from AliExpress ~US$50.00](http://s.click.aliexpress.com/e/HJ13fU8)\
          [Order from Amazon ~US$39.00](https://amzn.to/2KCPJsr)
  
  </details>

![Huawei E3372h Modem](https://uavpal.com/img/e3372-modem.jpg)

:warning: **Note**: there are different Huawei E3372 models available - please read [this FAQ entry](https://github.com/uavpal/disco4g/wiki/FAQ#e3372models) before buying to ensure your mobile network operator is supported.

:warning: **Note**: the newer E3372h-**320** model does not work with the softmod currently. Some sellers on Amazon advertise the E3372h-320 as E3372h-153! 

- USB OTG cable (Micro USB 2.0 Male to USB 2.0 Female, ca. 15 cm, angle cable) <details><summary>**Buy now!**</summary>
   [Order from AliExpress ~US$2.00](http://s.click.aliexpress.com/e/caih4r5I) (choose "direction up")\
   [Order fom Amazon ~US$14.00](https://amzn.to/2I4SSzC) (choose 15 cm)
  
  </details>

![USB OTG Cable for Parrot Disco](https://uavpal.com/img/usbotg_cable_disco.jpg)

- Antennas (2x CRC9) for the modem (optional)
- Mobile device/phone with Wi-Fi tethering and [SIM card](https://uavpal.com/disco/wiki/Known-Working-Mobile-Carriers-and-Settings) (for best performance, use the same operator as the USB modem's SIM card). Most recent iOS and Android devices work fine.
- PC with Wi-Fi (one-time, required for initial installation)

*Software:*

- FreeFlight Pro App on iOS or Android (can be the same device providing Wi-Fi tethering)
- Zerotier account (free)
- Glympse App for independent real-time GPS tracking (optional) - free Glympse Developer account required

## Installation

Please see Wiki article [Installation](https://github.com/uavpal/disco4g/wiki/Installation).

## How to fly on 4G/LTE? (User Manual)

Please see Wiki article [How to fly on 4G/LTE? (User Manual)](https://github.com/uavpal/disco4g/wiki/How-to-fly-on-4G-LTE-(User-Manual)).

## FAQ

Please see Wiki article [FAQ](https://github.com/uavpal/disco4g/wiki/FAQ).

## Is it really free? Are you crazy?

Yes and yes! This softmod has been developed over countless of days and nights by RC hobbyists and technology enthusiasts with zero commercial intention.
Anyone can download our code for free and transform his/her Disco into a 4G/LTE enabled fixed-wing drone by following the instructions provided.

_However_, we highly appreciate [feedback and active contribution](#contactcontribute) to improve and maintain this project.

![Shut up and take my money!](http://image.ibb.co/cLw9SS/shut_up_and_take_my_money.jpg)

If you insist, feel free to donate any amount you like. We will mainly use donations to acquire new hardware to be able to support a wider range of options (such as more 4G/LTE USB Modems).

[![Donate using Paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.com/cgi-bin/webscr?cmd=_donations&business=GY3BTZPLPBB2W&lc=US&item_name=UAVPAL&cn=Add%20special%20instructions%3A&no_shipping=1&currency_code=USD&bn=PP-DonationsBF:btn_donateCC_LG.gif:NonHosted)

## Contact/Contribute

Join our [UAVPAL Slack workspace](https://uavpal.com/slack) or check out the [issue section](https://github.com/uavpal/disco4g/issues) here on GitHub.\
Email: <img valign="bottom" src="https://image.ibb.co/mK4krx/uavpalmail2.png"> (please do not use email for issues/troubleshooting help. Join our Slack community instead!)

## Special Thanks to

- Parrot - for building this beautiful bird, as well as for promoting and supporting Free and Open-Source Software
- ZeroTier - awesome product and excellent support
- Glympse - great app and outstanding API
- Andres Toomsalu
- AussieGus
- Brian
- Carlo
- [Dustin Dunnill](https://www.youtube.com/channel/UCVQWy-DTLpRqnuA17WZkjRQ)
- John Dreadwing
- [Joris Dirks](https://djoris.nl)
- Josh Mason
- [Justin](https://www.youtube.com/channel/UCFkujOXRZb2Az8fUeD5tiMA)
- Phil
- Sarah Davis
- Tim Vu

## Disclaimer

This is still an EXPERIMENTAL modification! Mod and fly your Disco at YOUR OWN RISK!!!
