/*
BSD 3-Clause License
Copyright (c) 2019, Sara Payne (Manwa Pastorelli in virtual worlds)
All rights reserved.
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:
1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.
3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.
THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

key lastAvi;
integer comsChannel = -111111;
integer comsChannelListen;
integer isActive = FALSE; //if true its in use, when false item does nothing

SendTakeOffMessage()
{
    string toSend = "TardisTakeOff";   //message to the tardis and rez ball
    llRegionSay(comsChannel, toSend); //sends the message
}

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE);
}//close set up listeners

default
{     
    changed (integer change)
    {   //reset if the sim restarts or the owner changes
        if (change & (CHANGED_REGION_START | CHANGED_REGION_RESTART | CHANGED_OWNER)) llResetScript();
    }
    
    state_entry()
    {
        SetUpListeners(); //sets up the listeners
        osVolumeDetect(TRUE); //makes the item volumetric
    }
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        key aviKey = llDetectedKey(0);
        if (isActive)
        {   //if the item is active come here. Should only be active when the tardis is rezzed. 
            if (detectedType == 1 || detectedType == 3 || detectedType == 5)
            {   //only process avatars, no bots or physical objects
                if(aviKey != lastAvi)
                {   //come here if this is not a repeated detection of the same avi as last time. 
                    string itemName = "Blackout Hud";//defines the name of the hud to attach. 
                    osForceAttachToOtherAvatarFromInventory(aviKey, itemName, ATTACH_HUD_CENTER_2); 
                    //force attach the hud from in ventory
                    lastAvi = aviKey; //records this avi as the last avi seen
                    SendTakeOffMessage();//sends a message to the tardis and tp ball
                    isActive = FALSE; //makes this item once again inactive
                    llSetTimerEvent(20);
                }//close if not a double entry by the same avi
            }//close if detected type is an avatar
        }//close if active
    }//close collissions
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {   //come here if the message comes from an object with the same owner on the comsChannel
            if (message == "StartTardisEntryModern") isActive = TRUE; 
            else if (message == "StopTardisEntryModern") isActive = FALSE;
        }
    }
     
    timer()
    {   //should only need the reset script here really, working around occassional but in OS where the reset doesn't seam to happen. 
        isActive = FALSE;
        llSetTimerEvent(0);
        llResetScript();
    }
}