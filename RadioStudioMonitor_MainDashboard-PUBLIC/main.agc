
// Project: RadioStudioMonitor 
// Created: 2021-02-09

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle( "RadioStudioMonitor_PC" )
SetWindowSize( 1024, 768, 0 )
SetWindowAllowResize( 1 ) // allow the user to resize the window

// set display properties
SetVirtualResolution( 1024, 768 ) // doesn't have to match the window
SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
SetSyncRate( 30, 0 ) // 30fps instead of 60 to save battery
SetScissor( 0,0,0,0 ) // use the maximum available screen space, no black borders
UseNewDefaultFonts( 1 ) // since version 2.0.22 we can use nicer default fonts

SetClearColor(25,25,25)

ONAIR_STAT=0
MICLIVE_STAT=0

printy as string
tempa as string
ctime as string
seconds as string

msgcontent as string

ctime2 as string
seconds2 as string

LoadFont(1,"Lato-Bold.ttf")

CreateText(1,"00:00:00")
SetTextFont(1,1)
SetTextSize(1,110)
SetTextPosition(1,320,350)
SetTextAlignment(1,1)
SetTextColor(1,255,0,0,255)

for a = 0 to 59
	tempa="TIME/"+str(a)+".png"
	LoadImage(a+1,tempa)
	CreateSprite(a+1,a+1)
	//sync()
	SetSpriteVisible(a+1,0)
next a
sync()

//ON AIR
LoadImage(84,"ONAIR_GRAY.png")
LoadImage(85,"ONAIR_ACTIVE.png")
LoadImage(86,"ONAIR_STANDBY.png")

//MIC LIVE
LoadImage(80,"MICLIVE_GRAY.png")
LoadImage(81,"MICLIVE_ACTIVE.png")

CreateSprite(80,80)
CreateSprite(81,81)
createsprite(84,84)
CreateSprite(85,85)
CreateSprite(86,86)

//ON AIR
SetSpritePosition(84,650,200)
SetSpritePosition(85,650,200)
SetSpritePosition(86,650,200)

//MIC LIVE
SetSpritePosition(80,650,440)
SetSpritePosition(81,650,440)



SetSpriteVisible(81,0)


SetSpriteVisible(85,0)
SetSpriteVisible(86,0)

CreateText(5,"9")
SetTextColor(5,255,255,255,50)

ResetTimer()

recievedstring AS string

//TEXT
CreateText(6,"ENTER IP ADDRESS OF MIC INPUT CONNECTOR"+chr(10)+"(USE 127.0.0.1 FOR SAME PC)")
SetTextAlignment(6,1)
SetTextSize(6,40)
SetTextPosition(6,512,124)
sync()

//IP INPUT
resetip:
SetTextVisible(6,1)
StartTextInput("127.0.0.1")
do
	sync()
	if GetTextInputCompleted()=1
		ipaddress2$=GetTextInput()
		exit
	endif
	if GetTextInputCancelled()=1 then goto resetip
loop

sync()

reconnect:

ConnectSocket(11,ipaddress2$,1238,6000)

//SetTextString(5,str(GetSocketConnected(11)))

//remstart
do
	print("PRESS ESCAPE TO END PROGRAM AT ANY TIME DURING CONNECTING PROCESS")
	if GetSocketConnected(11)=0
		print("CONNECTING...")
		if GetRawKeyPressed(27)=1 then end
		sync()
	elseif GetSocketConnected(11)=-1
		print("FAILED TO CONNECT TO MIC INPUT CONNECTOR. RETRYING")
		sync()
		sleep(2000)
		DeleteSocket(11)
		goto reconnect
		//end
	elseif GetSocketConnected(11)=1
		SetTextVisible(6,0)
		exit
	else
		print(str(GetSocketConnected(11)))
		sync()
	endif
	
	if GetRawKeyPressed(27)=1 then end
loop
//remend

// host a network called StudioMonitor and give this machine the client name Host
networkId = HostNetwork("STUDIO_MONITOR", "SERVER", 57938)

a=0
lines=0

//Altalog = OpenToRead("ALTACAST_LOG\log.log")

//remstart
do
createtext(2,"SETTING UP...")
settextsize(2,170)
SetTextPosition(2,512,100)
SetTextAlignment(2,1)
print("setting up")
sync()
if networkId > 0 and IsNetworkActive(networkId)
	SetTextVisible(2,0)
	sync()
	exit
else
	print("WAITING...")
	sync()
endif
loop
//remend

reset:
ctime=GetCurrentTime()
seconds=Right(ctime,2)
secondsint=val(seconds)

SetSpriteVisible(secondsint+1,1)
sync()

do
ctime2=GetCurrentTime()
seconds2=Right(ctime2,2)
secondsint2=val(seconds2)

SetTextString(1,ctime2)	

if secondsint2>secondsint
	SetSpriteVisible(secondsint+1,0)
	goto reset
elseif secondsint2=00 
	secondsint=00
	SetSpriteVisible(60,0)
	goto reset
endif

if GetRawKeyState(27)=1 then end

if GetRawKeyPressed(77)=1 then gosub mic_on //mic 
if GetRawKeyPressed(77)=1 
	if GetRawKeyState(16)=1 then gosub mic_off //mic 
endif

if GetRawKeyPressed(79)=1 then gosub on_air_on //on air
if GetRawKeyPressed(79)=1 
	if GetRawKeyState(17)=1 then gosub on_air_semi //on air
endif
if GetRawKeyPressed(79)=1 
	if GetRawKeyState(16)=1 then gosub on_air_off //on air
endif

if getsocketconnected(11)<>1 then goto reconnect


////////////////////////////////////////
//CHECK ALTACAST LOG
//if val(GetCurrentTime())-oldtime>5
remstart
do
	Altafile$ = ReadLine(Altalog)
	a=a+1
	if Altafile$="" 
		lines=a
		exit
	endif

	delimittemp$=GetStringToken(Altafile$,": ",7)

	if delimittemp$="Connected" then gosub on_air_on //on air
	if delimittemp$="Disconnected" then gosub on_air_off //on air

	//oldtime=val(GetCurrentTime())	
loop
remend
//endif
/////////////////////////////////////

/////////another part of loop that checks if mic on or off signal received
//remstart
if GetSocketBytesAvailable(11)>1
	recievedstring=GetSocketString(11)
	//print("RECIEVED222= "+str(recievedstring))
	
	if recievedstring="MIC_ON"
		gosub mic_on
	endif
	
	if recievedstring="MIC_OFF"
		gosub mic_off
	endif
	
endif
//remend
recievedstring = ""



/////////////////
if Timer() > 10
	//check and rebroadcast if anything is on
	if ONAIR_STAT=1
		messageidy=CreateNetworkMessage()
		AddNetworkMessageString(messageidy,"ON_AIR_ON")
		SendNetworkMessage(networkId,0,messageidy)
		DeleteNetworkMessage(messageidy)
	endif
		
	if ONAIR_STAT=0.5
		messageidy=CreateNetworkMessage()
		AddNetworkMessageString(messageidy,"ON_AIR_SEMI")
		SendNetworkMessage(networkId,0,messageidy)
		DeleteNetworkMessage(messageidy)
	endif

	if ONAIR_STAT=0
		messageidy=CreateNetworkMessage()
		AddNetworkMessageString(messageidy,"ON_AIR_OFF")
		SendNetworkMessage(networkId,0,messageidy)
		DeleteNetworkMessage(messageidy)
	endif
		
	if MICLIVE_STAT=1
		messageidy=CreateNetworkMessage()
		AddNetworkMessageString(messageidy,"MIC_ON")
		SendNetworkMessage(networkId,0,messageidy)
		DeleteNetworkMessage(messageidy)
	endif

	if MICLIVE_STAT=0
		messageidy=CreateNetworkMessage()
		AddNetworkMessageString(messageidy,"MIC_OFF")
		SendNetworkMessage(networkId,0,messageidy)
		DeleteNetworkMessage(messageidy)
	endif
	
	ResetTimer()
endif
	
            
sync()
loop

mic_on:

MICLIVE_STAT=1

SetSpriteVisible(80,0)
SetSpriteVisible(81,1)

messageidy=CreateNetworkMessage()
AddNetworkMessageString(messageidy,"MIC_ON")
SendNetworkMessage(networkId,0,messageidy)
return

mic_off:

MICLIVE_STAT=0

SetSpriteVisible(81,0)
SetSpriteVisible(80,1)

messageidy=CreateNetworkMessage()
AddNetworkMessageString(messageidy,"MIC_OFF")
SendNetworkMessage(networkId,0,messageidy)
return

////////////////////////////
on_air_on:

ONAIR_STAT=1

SetSpriteVisible(84,0)
SetSpriteVisible(86,0)
SetSpriteVisible(85,1)

messageidy=CreateNetworkMessage()
AddNetworkMessageString(messageidy,"ON_AIR_ON")
SendNetworkMessage(networkId,0,messageidy)
return

on_air_semi:

ONAIR_STAT=0.5
SetSpriteVisible(84,0)
SetSpriteVisible(85,0)
SetSpriteVisible(86,1)

messageidy=CreateNetworkMessage()
AddNetworkMessageString(messageidy,"ON_AIR_SEMI")
SendNetworkMessage(networkId,0,messageidy)
return

on_air_off:

ONAIR_STAT=0
SetSpriteVisible(85,0)
SetSpriteVisible(86,0)
SetSpriteVisible(84,1)

messageidy=CreateNetworkMessage()
AddNetworkMessageString(messageidy,"ON_AIR_OFF")
SendNetworkMessage(networkId,0,messageidy)
return

//////////////////////////////
