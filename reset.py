import serial
import time
import os

port=os.getenv('SERIAL', default='/dev/ttyACM0')
print('Opening serial port ' + port)
com=serial.Serial(port, 1200, dsrdtr=True)
com.dtr=True
com.write('0000'.encode())
time.sleep(2)
com.dtr=False
time.sleep(2)
com.close()