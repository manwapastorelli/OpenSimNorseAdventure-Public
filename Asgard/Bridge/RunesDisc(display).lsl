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
integer isActive = FALSE;
list currentAvatars;

SetupListener()
{   //sets up the listen handle and turns the listener on
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, ""); //defines the listen handle
    llListenControl(comsChannelListen, TRUE); //turns the listener on
}//close setup listener

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        SetupListener(); //what the method name says :)
        llTargetOmega(<0,0.1,0>,TWO_PI,1.0); //sets the disc rotating
        llSetLinkAlpha(LINK_SET, 0.0, ALL_SIDES); //set invisible
        isActive = FALSE;// start turned off
        currentAvatars = []; //start with an empty list
    }
    
    touch_start(integer count)
    {   //come here when the disd is clicked
        key aviUUID = llDetectedKey(0);
        integer aviIndex = llListFindList(currentAvatars, (list)aviUUID);
        if (!isActive)
        {   // come here if the item is not currently active. 
            llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "This item is supposed to currently be invisible. If this is an accidental click please ignore this message. If you tried to cheat... ha you were caught red handed! If however this item was visible please report this to your admin. This object is owned by: " + llKey2Name(llGetOwner()));
        }//close if the item is not active. 
        else 
        {   //come here if the item is active
            if (aviIndex != -1)
            {   //come here if the user is on the users list
                string itemToGive = "Asgard Runes Translation Disc (Carry)";
                key user = llDetectedKey(0);
                float distance;
                list avidetails = llGetObjectDetails(user, [OBJECT_POS]);
                vector userPos = llList2Vector(avidetails, 0);
                distance = llVecDist( llGetPos(), userPos);//get the distance between the user and the disc
                if (distance < 30) 
                {   //come here if the avi is reasonably close to the disc
                    llGiveInventory(user, itemToGive); //give them a copy of the runes disc
                    currentAvatars = llDeleteSubList(currentAvatars, aviIndex, aviIndex);//remove this avi from the current users 
                    if (llGetListLength(currentAvatars) == 0) 
                    {
                        llRegionSay(comsChannel, "FadeOut");
                        llResetScript();  //if no more avi's are in the current list reset
                    }
                }//close if distrance less than 30m
                else llRegionSayTo(user, 0, "sorry you are to far away to use this item"); 
            }//close if user is on the users list
            else if  (aviIndex == -1)
            {   //come here if the disc is active, but the user clicking has not rezzed sifs book 
                llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Sorry, this item is activated for someone else, you have another stage to complete first. Enjoy your search.");
            }
        }//close if item is active        
    }//close touch start

    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel)
        {   //come here if the channel matches the coms channel and the message is sifs message
            list instructions = llCSV2List(message);
            string instruction = llList2String(instructions,0);
            key aviUUID = llList2Key(instructions, 1);
            isActive = TRUE; //turn on
            llSetLinkAlpha(LINK_SET, 1.0, ALL_SIDES);//make visible
            llSetTimerEvent(300); //5 min timer
            if (!(~llListFindList(currentAvatars, (list)aviUUID))) 
            {   //come here if the avi is not already on the list of current avatars
                currentAvatars += aviUUID; //if this avtar is not already on the current avatars list add them
                llRegionSay(comsChannel, "FadeIn" + "," + (string)aviUUID);
            }//close if user not on the list
        } //close if channel is the coms channel
    }//close listen

    timer()
    {   //come here if the timer runs out
        integer index; 
        for (index = 0; index < llGetListLength(currentAvatars); ++index)
        {   //loop through all avis in the list and deliver a message
            llRegionSayTo(llList2Key(currentAvatars, index), PUBLIC_CHANNEL, "This runes disc has timed out, you will need to rez your book again to activate it");
        }//close loop
        llRegionSay(comsChannel, "FadeOut");
        llResetScript();//resets the script
    } //close timer
}//close state default