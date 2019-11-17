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


list currentAvis; //list of avi's who have recently read the whole book
integer comsChannel = -111111; //sets the channel number
integer comsChannelListen; //handle for the listen event

SetupListener()
{   //sets up the listener for the coms channel and turns it on
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE);
}//close setup listener

HideFloor()
{   //makes the floor invisible and phantom
    llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_COLOR, ALL_SIDES, <1,1,1>, 0.0,  PRIM_PHANTOM, TRUE]);
}//close hide floor

ShowFloor()
{   //makes the floor visible and solid
    llSetLinkPrimitiveParamsFast(LINK_SET, [ PRIM_COLOR, ALL_SIDES, <1,1,1>, 1.0,  PRIM_PHANTOM, FALSE]);
}//close show floor

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {   //runs when script first starts
        SetupListener();
        ShowFloor();
        currentAvis = [];
    }//close state entry
    
    sensor( integer num_detected )
    {   //avi's detected in range
        integer aviIndex = 0;
        integer aviWithAccess = FALSE;
        while (!aviWithAccess && aviIndex < num_detected)
        {   //if any avi's detected have access set value to true, else leave false
            key detectedUUID = llDetectedKey(aviIndex);
            if(~llListFindList(currentAvis, (list)detectedUUID))
            {   //come here if the detected avi on in the list of current avis
                aviWithAccess = TRUE; //set to true and break the loop
            }//close if found on list.
            ++aviIndex;
        }
        if (aviWithAccess) HideFloor(); //we have an avi with access nearby, hide the floor
        else ShowFloor(); //avi's are in range, and there are people on the access list but non of them currently have access. 
    }//close sensor

    no_sensor()
    {   //no avi's nearby show the floor again
        ShowFloor();
    }//close no sensor

    listen(integer channel, string name, key id, string message)
    {
        if (channel == comsChannel)
        {   //come here if the channel matches the story book
            list details = llCSV2List(message);
            string instruction = llList2String(details, 0);
            key aviUUID = llList2Key(details, 1);
            if (instruction == "ActivateStairs")
            {   //message matches the message from the story book
                llSensorRepeat("", NULL_KEY, AGENT, 3.5, PI, 3); //sets the sensor running
                llSetTimerEvent(600);//sets a timer for 10 mins
                if (!(~llListFindList(currentAvis, aviUUID)))
                {   //if the avi is not already on the list add them
                    currentAvis += aviUUID;
                }//close if not on the list
            }//close if message matches story book
            else if (instruction == "RemoveAvi" && llGetOwnerKey(id) == llGetOwner())
            {   //remove avi instruction from the portal prim. 
                integer currentAvisIndex = llListFindList(currentAvis, (list)aviUUID);
                if (currentAvisIndex != -1)
                {   //if this avi's uuid is in the current avis list remove it
                    currentAvis = llDeleteSubList(currentAvis, currentAvisIndex, currentAvisIndex);
                    if (llGetListLength(currentAvis) == 0) llResetScript(); //if the list is now empty reset the script
                }//close if uuid is found in the current avi's list         
            }//close if instruction is remove avi
        }//close if channel is coms channel
    }//close listen

    timer()
    {   //if the time has expired reset the scripts
        llResetScript();
    }//closer timer
}//close default state