
// Project: RadioStudioMonitor 
// Created: 2021-02-09

// show all errors
SetErrorMode(2)

// set window properties
SetWindowTitle( "RadioStudioMonitor_TABLET_REMOTE" )
SetWindowSize( 1280, 720, 0 )
SetWindowAllowResize( 1 ) // allow the user to resize the window

// set display properties
SetVirtualResolution( 1280, 720 ) // doesn't have to match the window
SetOrientationAllowed( 1, 1, 1, 1 ) // allow both portrait and landscape on mobile devices
SetSyncRate( 30, 0 ) // 30fps instead of 60 to save battery
SetScissor( 0,0,0,0 ) // use the maximum available screen space, no black borders
UseNewDefaultFonts( 1 ) // since version 2.0.22 we can use nicer default fonts

printy as string
tempa as string
ctime as string
seconds as string

ctime2 as string
seconds2 as string

LoadFont(1,"Lato-Bold.ttf")

CreateText(1,"00:00:00")
SetTextFont(1,1)
SetTextSize(1,90)
SetTextPosition(1,640,625)
SetTextAlignment(1,1)
SetTextColor(1,255,0,0,255)

//ON AIR
LoadImage(84,"ON_AIR_OFF.png")
LoadImage(85,"ON_AIR_ON.png")
LoadImage(86,"ON_AIR_SEMI.png")

//MIC LIVE
LoadImage(80,"MIC_LIVE_OFF.png")
LoadImage(81,"MIC_LIVE_ON.png")

//BANS (BROADCAST ALERT NETWORK SYSTEM)
//LoadImage(82,"BANS_OFF.png")
//LoadImage(83,"BANS_ON.png")

CreateSprite(80,80)
CreateSprite(81,81)
//CreateSprite(82,82)
//CreateSprite(83,83)
createsprite(84,84)
CreateSprite(85,85)
CreateSprite(86,86)

//ON AIR
SetSpritePosition(84,55,130)
SetSpritePosition(85,55,130)
SetSpritePosition(86,55,130)

//MIC LIVE
SetSpritePosition(80,55,380)
SetSpritePosition(81,55,380)

//BANS
//SetSpritePosition(82,55,475)
//SetSpritePosition(83,55,475)

bansstat=0

SetSpriteVisible(81,0)

SetSpriteVisible(85,0)
SetSpriteVisible(86,0)


//TEXT CREATE
CreateText(2,"ENTER IP ADDRESS OF HOST")
SetTextAlignment(2,1)
SetTextSize(2,40)
SetTextPosition(2,512,184)
sync()

//IP INPUT
resetip:
StartTextInput("")
do
	sync()
	if GetTextInputCompleted()=1
		ipaddress$=GetTextInput()
		exit
	endif
	if GetTextInputCancelled()=1
		SetTextVisible(6,0)
		goto resetip
loop

sync()

//NETWORK SETUP AND JOIN
joinnet:
networkId = JoinNetwork(ipaddress$,57938,"REMOTE")
DeleteText(2)
sync()


reset:
ctime=GetCurrentTime()
seconds=Right(ctime,2)
secondsint=val(seconds)
sync()

do
ctime2=GetCurrentTime()
seconds2=Right(ctime2,2)
secondsint2=val(seconds2)

SetTextString(1,ctime2)	

if secondsint2>secondsint
	goto reset
elseif secondsint2=00 
	secondsint=00
	goto reset
endif


a=GetNetworkMessage(networkId)
if a>0
	messagey2$=GetNetworkMessageString(a)
	DeleteNetworkMessage(a)
	//print(messagey2$)
	
	if messagey2$="MIC_ON" then gosub mic_on
	if messagey2$="MIC_OFF" then gosub mic_off
	
	if messagey2$="ON_AIR_ON" then gosub on_air_on
	if messagey2$="ON_AIR_OFF" then gosub on_air_off
	if messagey2$="ON_AIR_SEMI" then gosub on_air_semi
	sync()
endif

c = GetNetworkNumClients(networkId)
if c < 1 then goto joinnet

//if bansstat>0 then gosub bans_on
Sync()
loop

mic_on:
SetSpriteVisible(80,0)
SetSpriteVisible(81,1)
return

mic_off:
SetSpriteVisible(81,0)
SetSpriteVisible(80,1)
return




on_air_on:
SetSpriteVisible(84,0)
SetSpriteVisible(86,0)
SetSpriteVisible(85,1)
return

on_air_semi:
SetSpriteVisible(84,0)
SetSpriteVisible(85,0)
SetSpriteVisible(86,1)
return

on_air_off:
SetSpriteVisible(86,0)
SetSpriteVisible(85,0)
SetSpriteVisible(84,1)
return


remstart
if bansstat=0
	SetSpriteVisible(83,1)
	SetSpriteVisible(82,0)
	bansstat=1
	sleep(170)
elseif bansstat=1
	SetSpriteVisible(83,0)
	SetSpriteVisible(82,1)
	bansstat=0
	sleep(170)
endif
return
remend

