import pyaudio
import time
from math import log10
import audioop  
import socket
import struct
import traceback

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

# Create a TCP/IP socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
server_address = ('localhost', 1238)
sock.bind(server_address)
sock.listen(1)

mic_status = None
last_sent_time = time.time()

while True:
    # Wait for a connection
    print('waiting for a connection')
    connection, client_address = sock.accept()
    try:
        print('connection from', client_address)
        while stream.is_active(): 
            if len(rms_values) >= 17:  # 10 * 0.1s = 1s
                avg_rms = sum(rms_values) / len(rms_values)
                db = 20 * log10(avg_rms)
                if db > -54:
                    print("MIC ON")
                    new_mic_status = 'MIC_ON'
                else:
                    new_mic_status = 'MIC_OFF'
                    print("MIC OFF")
                if new_mic_status != mic_status or time.time() - last_sent_time >= 2:
                    mic_status = new_mic_status
                    last_sent_time = time.time()
                    # Send the length of the string and the string itself
                    connection.sendall(struct.pack('<I', len(mic_status)) + mic_status.encode())
                rms_values = []  # reset the list for the next second
                print(str(db))
    except Exception as e:
        print(traceback.format_exc())
    finally:
        # Clean up the connection
        connection.close()
    time.sleep(0.1)

stream.stop_stream()
stream.close()

p.terminate()
