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
integer isActive; //if true its in use, when false item does nothing
integer comsChannel = -1433668630;
integer comsChannelListen;

SetUpListener()
{//sets the coms channel and the random menu channel then turns the listeners on.
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE);
}//close set up listeners

Teleport(key aviUUID)
{   //teleports the avi to the library
    vector librarayPos = <649, 632, 8000>;
    osTeleportAgent(aviUUID, librarayPos, ZERO_VECTOR);
}

PortalStatus(integer active)
{   //sets the visiblity of the portal based on the active status
    if (active) 
    {   //set visible
        isActive = TRUE;
        llSetLinkPrimitiveParams(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 1  ] );
    }
    else if (!active)
    {   //set invisible
        isActive = FALSE;
        llSetLinkPrimitiveParams(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0  ] );
    }
}

default
{
    changed (integer change)
    {   //if the region restarts or the item changes owner reset the script. 
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);//set item to volumetric
        PortalStatus(FALSE); //turn the portal off
        SetUpListener();//set up the listeners
        llRegionSay(comsChannel, "Reset"); //send rest to the table to force synced states
    }
    
    collision_start(integer total_number)
    {   //when something collides with us   
        integer detectedType = llDetectedType(0);
        if (isActive)
        {   //if the portal is active do this
            if (detectedType == 1 || detectedType == 3 || detectedType == 5)
            {   //only process avatars, no bots or physical objects
                key detectedUUID = llDetectedKey(0);
                key aviKey = llDetectedKey(0);
                if(aviKey != lastAvi) 
                {   //only come here if its not a duplicate hit from the last collider.
                    Teleport(detectedUUID); //teleports the avi
                    llRegionSay(comsChannel, "Reset"); //sends reset to the table
                    llResetScript();//resets the script
                }//close if if not the same avi as the last
            }//close if detected type is an avatar
        }
    }//close collissions
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {   //if message is heard on the coms channel and the item has the same owner process it
            if (message == "ActivatePortal") 
            {   //if the message is activate the portal
                PortalStatus(TRUE); //set active
                llSetTimerEvent(30);//set the timer running
            }
        }
    }
    
    timer()
    {   //timer expires, stop it running and reset the script.
        llSetTimerEvent(0);
        llResetScript();
    }
}