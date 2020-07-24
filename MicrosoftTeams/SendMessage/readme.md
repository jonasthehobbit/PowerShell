# Description
This script usses a teams channel webhook to send a basic message card to a channel, this can be useful for things like SCCM where you need to notify a Team but prefer to move aware from email clutter.
# Usage
````powershell
SendChannelMessage.ps1 -webhook "insertWebhook" -body1 "some text you want to pass" -Body2 "some more text, maybe a variable from SCCM?"
````
# Notes
Change the messagetitle and messagebody variables to alter the message being sent and use the input params to enable input into your message.