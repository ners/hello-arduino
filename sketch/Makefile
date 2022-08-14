BOARD ?= arduino:mbed_nano:nano33ble
#PORT ?= /dev/serial/usb-Arduino_Nano_33_BLE_1F5576BD69189856-if00
PORT ?= /dev/ttyACM0

compile:
	arduino-cli compile -b ${BOARD} sketch.ino

upload:
	arduino-cli upload -b ${BOARD} -p ${PORT} sketch.ino -v