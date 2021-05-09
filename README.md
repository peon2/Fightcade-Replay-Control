# Fightcade-Replay-Control
A rough proof of concept for replay controls with current fcade lua functionality

Works best for games with smaller memory footprints due to a *heavy* reliance on savestates. e.g. ST runs well but 3s might not run as well. This is probably due to only being able to write savestates to disk rather than save them in RAM

Can desync, this is only a proof of concept so I haven't bothered to look for where that comes from, most likely this script rather than a fcade issue.


Fightcade can try to force the replay to sync up with the server, which will wreck the playback. However this seems to be inconsistent.

User input can only be read through input.get() which doesn't pick up pads or sticks or anything like that, just kb and mouse. That's fine for kb users anyway.

When the replay ends, regardless of where the fc is or what you're doing the replay ends. i.e. If a replay is 5 minutes long that's the longest it can run for no matter what.

Some definitions at the top of the .lua file that can be edited:
SAVESTATE_INTERVAL: frames between each state being saved, default 60 (try putting this higher for more memory games)
REWIND_KEY: Key used to jump back a savestate, default V
FORWARD_KEY: Key used to jump forward a savestate, default B
PAUSE_KEY: Key used to pause a replay, default N
P1_CONTROL_KEY: Key used to enable p1 control, default M

If I can clean this up/more fightcade support comes in I'll add this functionality to [my spectating script](https://github.com/peon2/fbneo-spectating)
