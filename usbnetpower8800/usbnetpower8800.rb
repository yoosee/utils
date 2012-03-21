#!/usr/bin/env ruby

# Copyright (C) 2012 Yoshinori Ikarashi http://yoosee.net
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
# http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# code is ported from python implementation:
# http://code.google.com/p/usbnetpower8800/source/browse/trunk/usbnetpower8800.py

## ** original comment **
# This is a simple command-line tool for controlling the "USB Net Power 8800"
# from Linux (etc.) using Ruby and libusb-ruby.  It shows up under lsusb as:
#
#     ID 067b:2303 Prolific Technology, Inc. PL2303 Serial Port
#
# But, from what I can tell, none of the serial port features are ever used,
# and all you really need is one USB control transfer for reading the current
# state, and another for setting it.
#
# The device is basically a box with a USB port and a switchable power outlet.
# It has the unfortunate property that disconnecting it from USB immediately
# kills the power, which reduces its usefulness.
## ** end original comment **

require 'usb'

class UsbNetPower8800
  VENDOR_ID = 0x067b
  PRODUCT_ID = 0x2303

  TIMEOUT = 5000

  def initialize
    @device = nil
    begin 
      target_device = USB.devices.select do |d|
        d.idVendor == VENDOR_ID && d.idProduct == PRODUCT_ID
      end
      @device = target_device[0].open
    rescue
      STDERR.puts "Device open failed: #{$!}"
    end
  end

  def power?
    # Return True if the power is currently switched on.
    # USB::DevHandle#usb_control_msg(requesttype, request, value, index, bytes, timeout)
    # currently not working well
    ret = @device.usb_control_msg(0xc0, 0x01, 0x0081, 0x0000, "", TIMEOUT)
    return true if ret == 0xa0
    return false
  end

  def power(on)
    code = 0x20 # turn off
    code = 0xa0 if on # turn on
    ret = @device.usb_control_msg(0x40, 0x01, 0x0001, code, "", TIMEOUT)
  end
end

if __FILE__ == $0 
  usbnetpower8800 = UsbNetPower8800.new
  case ARGV[0]
  when 'on'
    usbnetpower8800.power(true)
  when 'off'
    usbnetpower8800.power(false)
  when 'stat'
    if usbnetpower8800.power? 
      "Power: on" 
    else 
      "Power: off" 
    end
  else
    puts "usage: usbnetpower8800.rb [on|off|stat]"
  end
end
