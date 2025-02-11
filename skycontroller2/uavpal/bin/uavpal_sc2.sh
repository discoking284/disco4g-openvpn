#!/bin/sh

# functions
change_led_color()
{
	case "$1" in
	off)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	red)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x01\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	green)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	blue)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	magenta)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x01\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	white)
		echo -n -e "\x00\x00\x00\x00\x00\x00\x00\x00\x11\x00\x00\x00\x01\x00\x00\x00\x00"\
"\x00\x00\x00\x00\x00\x00\x00\x11\x00\x01\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"\
"\x11\x00\x02\x00\x01\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00" > /dev/input/event1
	;;
	*)
	esac
}

led_flash()
{
	if [ "$led_flash_pid" -gt "0" ]; then kill -9 $led_flash_pid; fi
	(while true; do
		i=2
		while [ "$i" -le "$#" ]; do
			eval "arg=\${$i}"
			change_led_color $arg
			usleep $(($1 * 100000))
			i=$((i + 1))
		done
	done) &
	led_flash_pid=$!
}

# send SIGKILL to parent and children processes
kill9_pid_tree()
{
	# kill all children processes
	ps l | grep -oE "[0-9]+[ \t]+$1[ \t]" | grep -oE "^[0-9]+" | while read -r line; do
			if [ "$line" -gt "0" ]; then kill -9 $line; fi
		done
	# then, kill the parent process
	kill -9 $1
}

# background listener for power button - needed for the time when mppd is paused - mppd will be reachtivated immediately to pick up the shutdown event
power_btn_listener()
{
	if [ "$pow_pid" -eq "0" ]; then
		ulogger -s -t uavpal_sc2 "... starting the power button listener"
		if [ "$platform" == "mpp" ]; then
			(evtest /dev/input/event0 | grep -m 1 -e "type 1 (EV_KEY), code 295 (BTN_BASE2), value 1" | while read; do
				ulogger -s -t uavpal_sc2 "... power button press event detected while mppd is paused - resuming mppd to pick up the event"
				killall -SIGCONT mppd
			done) &
			pow_pid=$!
		else
			(evtest /dev/input/event0 | grep -m 1 -e "type 1 (EV_KEY), code 116 (KEY_POWER), value 1" | while read; do
				ulogger -s -t uavpal_sc2 "... power button press event detected while mppd is paused - rebooting system"
				reboot
			done) &
			pow_pid=$!
		fi

	fi
}

conf_read()
{
	result=$(head -1 /data/lib/ftp/uavpal/conf/${1})
	echo "$result" |tr -d '\r\n' |tr -d '\n'
}

main()
{
	# variables
	wifi_connection_attempts=5
	wifi_connection_timeout_seconds=10
	wifi_dhcp_timeout_seconds=10
	zerotier_iface_timeout_seconds=8
	drone_zt_ping_retry=20
	settings_double_press_seconds=2
	led_flash_pid=0
	pow_pid=0

	ulogger -s -t uavpal_sc2 "=== Loading uavpal softmod $(head -1 /data/lib/ftp/uavpal/version.txt |tr -d '\r\n' |tr -d '\n') ==="
	# set tmp files values (cheap workaround for local variable scope issue in while loops)
	echo wifi >/tmp/mode
	echo 0 >/tmp/button_prev_timestamp

	# set platform, mpp=Skycontroller 2, mpp2=Skycontroller 2P
	platform=$(grep 'ro.parrot.build.product' /etc/build.prop | cut -d'=' -f 2)
	controller_fw_version=$(grep 'ro.parrot.build.uid' /etc/build.prop | cut -d '-' -f 3)
	ulogger -s -t uavpal_sc2 "... detected Skycontroller 2 (platform ${platform}), firmware version ${controller_fw_version}"

	# background pinging of drone, change LED to blue if ping ok - needed to override green LED after a successful mppd reconnect
	(while true; do
		if ping -c 1 192.168.42.1 >/dev/null 2>&1; then
			if [ "$platform" == "mpp" ]; then
				mpp_bb_cli on 3
			else
				change_led_color blue
			fi
		fi
		sleep 1
	done) &

	# wait for mppd to be idle (to absorb the power button press from a cold start)
	until [ "$(ulogcat -d |grep mppd |grep "state=IDLE" |wc -l)" -gt "0" ]; do sleep 1; done

	if [ "$platform" == "mpp" ]; then
		input_dev_settings="/dev/input/event0"
	else
		input_dev_settings="/dev/input/event1"
	fi
	while true; do
		# wait for Settings button event
		while true; do
			evtest ${input_dev_settings} | grep -m 1 -e "type 1 (EV_KEY), code 288 (BTN_TRIGGER), value 1" | while read; do
				date "+%s" >/tmp/button_timestamp
			done
			button_prev_timestamp=$(cat /tmp/button_prev_timestamp)
			button_timestamp=$(cat /tmp/button_timestamp)
			if [ "$(($button_timestamp-$button_prev_timestamp))" -lt "$settings_double_press_seconds" ]; then
				ulogger -s -t uavpal_sc2 "... settings button double press event detected"
				break # break out of loop
			fi
			cp /tmp/button_timestamp /tmp/button_prev_timestamp
		done
		if [ "$(cat /tmp/mode)" == "lte" ]; then
			switch_to_wifi
		else
			switch_to_lte
		fi
	done
}

switch_to_lte()
{
	echo lte >/tmp/mode
	ulogger -s -t uavpal_sc2 "=== Switching to LTE ==="
	ulogger -s -t uavpal_sc2 "... indicating switch-over to LTE for 1 seconds (LED flashing blue/white)"
	if [ "$platform" == "mpp" ]; then
		mpp_bb_cli blink 7 3 200 20
	else
		led_flash 1 blue white
	fi
	sleep 1
	ulogger -s -t uavpal_sc2 "... changing LED to flashing magenta"
	if [ "$platform" == "mpp" ]; then
		mpp_bb_cli blink 6 0 1000 50
	else
		led_flash 5 magenta off
	fi
	ulogger -s -t uavpal_sc2 "... pausing process mppd"
	killall -SIGSTOP mppd

	# listen for a power button event
	power_btn_listener

	if [ "$platform" == "mpp" ]; then
		ulogger -s -t uavpal_sc2 "... pausing process wifid (mpp platform only)"
		killall -SIGSTOP wifid
		ulogger -s -t uavpal_sc2 "... launching process wifid-uavpal in the background (mpp platform only)"
		WIFID_DRIVER=bcmdriver /usr/bin/wifid --mode STA --ip 192.168.42.3 --suffix uavpal &
		wifid_suffix="--suffix uavpal"
	else
		wifid_suffix=""
	fi

	for p in `seq 1 $wifi_connection_attempts`; do
		ulogger -s -t uavpal_sc2 "... connecting to mobile Wi-Fi hotspot \"$(conf_read ssid)\" (try $p of $wifi_connection_attempts)"
		wifid-cli ${wifid_suffix} connect "$(conf_read ssid)" 0 "$(conf_read wpa)"

		for q in `seq 1 $wifi_connection_timeout_seconds`; do
			wifi_connection_status=`wifid-cli ${wifid_suffix} status 2>&1 |grep state |awk '{print $3}'`
			if [ "$wifi_connection_status" = "connected" ]; then
				ulogger -s -t uavpal_sc2 "... Wi-Fi successfully connected"
				break 2 # break out of both for loops
			fi
			sleep 1
		done
		if [ "$p" -eq "$wifi_connection_attempts" ]; then
			ulogger -s -t uavpal_sc2 "... $wifi_connection_attempts unsuccessful Wi-Fi connection attempts reached - switching back to Wi-Fi"
			kill9_pid_tree $pow_pid
			pow_pid=0
			switch_to_wifi
			return # back to main()
		fi
	done

	ulogger -s -t uavpal_sc2 "... requesting IP address via DHCP from mobile Wi-Fi hotspot"
	udhcpc -i wlan0 -f >/dev/null 2>&1 &

	for p in `seq 1 $wifi_dhcp_timeout_seconds`
	do
		wifi_dhcp_ip=`ifconfig wlan0 |grep inet |awk '{print $2}' |grep -v '192.168.42' |wc -l`
		if [ "$wifi_dhcp_ip" = "1" ]; then
			ulogger -s -t uavpal_sc2 "... IP address successfully obtained from DHCP via Wi-Fi"
			break # break out of loop
		fi
		sleep 1
		if [ "$p" -eq "$wifi_dhcp_timeout_seconds" ]; then
			ulogger -s -t uavpal_sc2 "... no IP received via DHCP after $wifi_dhcp_timeout_seconds seconds - switching back to Wi-Fi"
			kill9_pid_tree $pow_pid
			pow_pid=0
			switch_to_wifi
			return # back to main()
		fi
	done

	ulogger -s -t uavpal_sc2 "... changing LED to flashing blue"
	if [ "$platform" == "mpp" ]; then
		mpp_bb_cli blink 3 0 1000 50
	else
		led_flash 5 blue off
	fi

	ulogger -s -t uavpal_sc2 "... removing default route (in case USB Ethernet is attached)"
	route del default dev eth0 >/dev/null 2>&1

	if [ "$platform" == "mpp" ]; then
		ulogger -s -t uavpal_sc2 "... terminating process wifid-uavpal (mpp platform only)"
		kill -9 `ps |grep wifid |grep suffix |awk '{print $1}'`
	fi

	ulogger -s -t uavpal_sc2 "... starting OpenVPN daemon"
	date -s "01 DEC 2023 18:00:00"
	ulogger -s -t uavpal_drone "... setting date/time using ntp"
	ntpd -n -d -q -p 0.debian.pool.ntp.org -p 1.debian.pool.ntp.org -p 2.debian.pool.ntp.org -p 3.debian.pool.ntp.org
	
	ulogger -s -t uavpal_sc2 "... starting OpenVPN daemon"
	/data/lib/ftp/uavpal/bin/openvpn /data/lib/openvpn/openvpn.conf > /tmp/openvpn.log 2>&1 &
	
	for p in `seq 1 $zerotier_iface_timeout_seconds`; do
    # Check OpenVPN log for successful connection
    if grep -q "Initialization Sequence Completed" /tmp/openvpn.log; then
        ulogger -s -t uavpal_sc2 "... OpenVPN connection established successfully"
        # Retrieve the interface name (e.g., tun0) used by OpenVPN
        vpn_interface=$(ifconfig | grep -oE '^tun[0-9]+' | head -n 1)
        echo $vpn_interface >/tmp/vpn_interface
        break # Exit the loop as the VPN is connected
    fi
		sleep 1
		if [ "$p" -eq "$zerotier_iface_timeout_seconds" ]; then
			ulogger -s -t uavpal_sc2 "... Unable to connect to OpenVPN within $zerotier_iface_timeout_seconds seconds - switching back to Wi-Fi"
			kill9_pid_tree $pow_pid
			pow_pid=0
			switch_to_wifi
			return # back to main()
		fi
	done
	for p in `seq 1 $drone_zt_ping_retry`; do
		ulogger -s -t uavpal_sc2 "... trying to ping drone via 4G/LTE through OpenVPN (try $p of $drone_zt_ping_retry)"
		if ping -c 1 192.168.42.1 >/dev/null 2>&1; then
			ulogger -s -t uavpal_sc2 "... successfully received ping echo from drone via OpenVPN over 4G/LTE"
			break # break out of loop
		fi
		if [ "$p" -eq "$drone_zt_ping_retry" ]; then
			ulogger -s -t uavpal_sc2 "... could not ping drone via OpenVPN over 4G/LTE in $drone_zt_ping_retry attempts - switching back to Wi-Fi"
			kill9_pid_tree $pow_pid
			pow_pid=0
			switch_to_wifi
			return # back to main()
		fi
	done

	if [ "$platform" == "mpp2" ]; then
		ulogger -s -t uavpal_sc2 "... pausing process wifid (mpp2 platform only)"
		killall -SIGSTOP wifid
		kill -9 $led_flash_pid # stop blinking blue
		led_flash_pid=0
	fi

	kill9_pid_tree $pow_pid
	pow_pid=0

	ulogger -s -t uavpal_sc2 "... resuming process mppd"
	killall -SIGCONT mppd

	ulogger -s -t uavpal_sc2 "*** idle on LTE ***"
}


switch_to_wifi()
{
	echo wifi >/tmp/mode
	ulogger -s -t uavpal_sc2 "=== Switching to Wi-Fi ==="
	ulogger -s -t uavpal_sc2 "... indicating switch-over to Wi-Fi for 1 seconds (LED flashing green/white)"
	if [ "$platform" == "mpp" ]; then
		mpp_bb_cli blink 7 4 200 20
		sleep 1
	else
		led_flash 1 green white
		sleep 1
		kill -9 $led_flash_pid # stop blinking green white
		led_flash_pid=0
	fi

	ulogger -s -t uavpal_sc2 "... resuming process mppd (should already be resumed though)"
	killall -SIGCONT mppd
	ulogger -s -t uavpal_sc2 "... restarting process wifid"
	killall -9 wifid
	ulogger -s -t uavpal_sc2 "... terminating processes required for LTE"
	killall openvpn
	killall udhcpc
	ulogger -s -t uavpal_sc2 "*** idle on Wi-Fi (or at least trying to connect) ***"
}

main "$@"
