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

integer comsChannel = -111111;
integer comsChannelListen;
list allowedAvis;//list of allowed avi's
key lastAvi;

SetupListener()
{   //sets up listeners
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE); //turns on listeners for main menu channel
}//close setup listeners

ChkAviHasAccess(key detectedUUID)
{   //checks to see if the avi has access and responds accordingly
    if (~llListFindList(allowedAvis, (list)detectedUUID))
    {   //come here if the avi is on the allowed list
        vector  Yggdrasil = <573.19977, 619.73291, 1919.80420>; //define asgard position
        osTeleportAgent(detectedUUID, Yggdrasil, ZERO_VECTOR); //teleprot avi to asgard
        llSetTimerEvent(3600); //set a timer event for an hour or restart it if already running
    }//close if avi has access
    else 
    {   //come here if the avi does not have access
        llRegionSayTo(detectedUUID, PUBLIC_CHANNEL, "The gods already shook their head at you, do you think you can defy the gods? It looks like you have more to do or you took so long they want you to do it again.");
        vector muspelheim = <142.26549, 116.76708, 5000.24609>; //define mupelheim position
        osTeleportAgent(detectedUUID, muspelheim, ZERO_VECTOR); //teleport agent to muspelheim landing
    }//close if avi does not have access
}//close check if avi has access

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        SetupListener();//setup the listeners
        osVolumeDetect(TRUE);
    }
    collision_start(integer total_number)
    {   //come here when things collide with this item
        //its volumetric so only avi's and pyysical objects can
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0); //get the avi of the avi who walked through the object
            if (detectedUUID != lastAvi)
            {   //don't process the same avi twice!
                lastAvi = detectedUUID;//make this new avi the last avi
                ChkAviHasAccess(detectedUUID); //pass uuid to check has access method
            }//close if current avi is not the same as the last one detected colliding. 
        }//close if detected type is an avatar
    }//close collissions

    listen( integer channel, string name, key id, string message )
    {
        //llOwnerSay("Debug: Listen Event Triggered");
        if (channel == comsChannel && llGetOwner() == llGetOwnerKey(id))
        {   //come here if the channel is the coms cahnnel and the owner is of the sending object is the same as this object. 
            list instructions = llCSV2List(message);
            string instruction = llList2String(instructions, 0);
            key aviUUID = llList2Key(instructions, 1);
            if (instruction == "GrantAccess")
            {   //if we are being told to give an avi access
                if (!(~llListFindList(allowedAvis, (list)aviUUID)))
                {   //if the avi is not already on the allowed list add them
                    allowedAvis += aviUUID; //add the avi to the list
                }//close if not on the list already
            }//close instruction is grant acess
        }//close if channel is correct and so is the owner of the object
    }//close listen

    timer()
    {   //if the timer runs out the portal is reset to preserve sim resources
        llResetScript(); //reset the script
    }//close timer
}//close state default