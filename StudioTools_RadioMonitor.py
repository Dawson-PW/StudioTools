######----IMPORTS------#########
from websocket_server import WebsocketServer

import pyaudio
import time
from math import log10
import audioop  
import socket
import struct
import traceback
import keyboard

################################


#This is the server that runs the analogue mixer mic live checker
#works uisng websockets
#this is the server - has to be hosted on the pc with the special line in connected to it.

######----VARIABLES----#####
micon_threshold = -54

######----FUNCTIONS----######

# Called for every client connecting (after handshake)
def new_client(client, server):
	print("New client connected and was given id %d" % client['id'])
	#server.send_message_to_all("Hey all, a new client has joined us")


# Called for every client disconnecting
def client_left(client, server):
	print("Client(%d) disconnected" % client['id'])


# Called when a client sends a message
def message_received(client, server, message):
	if len(message) > 200:
		message = message[:200]+'..'
	print("Client(%d) said: %s" % (client['id'], message))


hostname = socket.gethostname()
ip_address = socket.gethostbyname(hostname)

PORT=7890
server = WebsocketServer(host=ip_address, port = PORT)
server.set_fn_new_client(new_client)
server.set_fn_client_left(client_left)
server.set_fn_message_received(message_received)
server.run_forever(True)
#################################

p = pyaudio.PyAudio()

# List all the available audio input devices
print("Available audio input devices:")
for i in range(p.get_device_count()):
    device_info = p.get_device_info_by_index(i)
    if device_info.get('maxInputChannels'):
        print(f"{i}: {device_info.get('name')}")

# Let the user select an audio input device
DEVICE = int(input("Enter the number of the audio input device you want to use: "))

WIDTH = 2
RATE = int(p.get_device_info_by_index(DEVICE)['defaultSampleRate'])
rms = 1
print(p.get_device_info_by_index(DEVICE))

rms_values = []
def callback(in_data, frame_count, time_info, status):
    global rms
    rms = audioop.rms(in_data, WIDTH) / 32767
    rms_values.append(rms)
    return in_data, pyaudio.paContinue

stream = p.open(format=p.get_format_from_width(WIDTH),
                input_device_index=DEVICE,
                channels=1,
                rate=RATE,
                input=True,
                output=False,
                stream_callback=callback)

stream.start_stream()

mic_status = None
micarray =["blank"]
last_sent_time = time.time()

#CHECK FOR KEYPRESS FOR LIVE SIGN
#SHIFT+ALT+L is for LIVE ON
#SHIFT+ALT+K is for LIVE OFF

def kpress():
    print("You pressed k: live off")
    server.send_message_to_all("LIVE_OFF")

def lpress():
    print("You pressed l: live on")
    server.send_message_to_all("LIVE_ON")


keyboard.add_hotkey('shift+alt+k', kpress)
keyboard.add_hotkey('shift+alt+l', lpress)

while True:
    # Wait for a connection
    print('waiting for a connection')
    time.sleep(1)
    try:
        while stream.is_active(): 
            if len(rms_values) >= 17:  # 10 * 0.1s = 1s
                avg_rms = sum(rms_values) / len(rms_values)
                db = 20 * log10(avg_rms)
                if db > micon_threshold:
                    #print("MIC ON")
                    new_mic_status = 'MIC_ON'
                else:
                    new_mic_status = 'MIC_OFF'
                    #print("MIC OFF")
                if new_mic_status != mic_status or time.time() - last_sent_time >= 2:
                    mic_status = new_mic_status
                    last_sent_time = time.time()
                    print(mic_status)
                    #####SEND THE NEW STATUS OVER THE WEBSOCKET
                    server.send_message_to_all(mic_status)
                    
                rms_values = []  # reset the list for the next second
                #print(str(db))
    except Exception as e:
        print(traceback.format_exc())
    finally:
        # Clean up the connection
        print("ENDING")

stream.stop_stream()
stream.close()

p.terminate()


