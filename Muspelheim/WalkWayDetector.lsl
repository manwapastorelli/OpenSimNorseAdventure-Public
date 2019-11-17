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

//multiple walk way prims use this same script. 

list currentAvis;
integer comsChannel = -111111;
integer comsChannelListen;
//key detectedUUID;
integer active = FALSE; //bool decides if detection is on or off

SetupListener()
{
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE); //turns on listeners for main menu channel
}

integer GetTail ()
{
    string detectorName = llGetObjectName();
    integer dashIndex = llSubStringIndex(detectorName, "-");
    string strTail = llGetSubString(detectorName, dashIndex+1, -1);
    integer intTail = (integer)strTail;
    return intTail;
}

RezNextPiece()
{
    integer rezzerChannel = -111111;
    integer intTail = GetTail();
    integer newTail = intTail+1;
    string toRezName = "WalkWay" + newTail;
    string toSay = "RezSingleItem" + "," + toRezName;
    llRegionSay(rezzerChannel, toSay);
}

DeRezCurrentPiece()
{
    integer rezzerChannel = -111111;
    string tail = (string)(GetTail());
    string toDeRezName = "WalkWay" + tail;
    string toSay = "DeRezIndividualItem" + "," + toDeRezName;
    llRegionSay(rezzerChannel, toSay);
}

NotifyPortal(key aviUUID)
{
    string toSay = (string)aviUUID + "," + llGetObjectName();
    llRegionSay(comsChannel, toSay);
}

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    
    state_entry()
    {
        osVolumeDetect(TRUE);
        SetupListener();
    }
   
    collision_start(integer total_number)
    {
        if (active)
        {
            integer detectedType = llDetectedType(0);
            if (detectedType == 1 || detectedType == 3 || detectedType == 5)
            {   //only process avatars, no bots or physical objects
                key detectedUUID = llDetectedKey(0);
                if(!(~llListFindList(currentAvis, (list)detectedUUID)))
                {   //only process if a bot fo this avatar doesn't exist already
                    currentAvis += detectedUUID;
                    NotifyPortal(detectedUUID);
                    llSensorRepeat( "", "", AGENT, 4, PI, 5);//sets a sensor running
                    RezNextPiece();
                }//close if bot for avi doesn't exist
            }//close if detected type is an avatar
        }//close if active
    }//close collissions
    
    no_sensor()
    {   // no one around, remove walk way
        llSensorRemove();
        currentAvis = [];
        DeRezCurrentPiece();
        active = FALSE;
    }//close no sensor

    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {
            if (message == "WalkWaySensorOn") active = TRUE;
            else if (message == "WalkWaySensorOff") active = FALSE;
        }
    }
}