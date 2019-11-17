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

SetupListener()
{   //setup the listeners
    integer comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE);//turn the listener on
}//close setup listener

DeliverMessage(key aviUUID)
{   //delivers the message 
    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Now that is music! You should visit the the chuch, if you are smart,  you will hear the sound of the universe");
}//close deliver message

default
{
    on_rez( integer start_param)
    {   //when rezed reset the script
        llResetScript();
    }//close on rez

    changed( integer change )
    {   //if the owner changes or the sim is reset, restart the script
        if (change & CHANGED_OWNER | CHANGED_REGION_START | CHANGED_REGION_RESTART) llResetScript();
    }//close changed

    state_entry()
    {
        SetupListener();// setup the listeners
    }

    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {   //if a message is heard on the coms channel and the sending object has the same owner
            list msgBits = llCSV2List(message); //turn message into list elements 
            key user = llList2Key(msgBits, 0);//user is the first element
            string instruction = llList2String(msgBits, 1);//instruction is the 2nd element
            if (instruction == "MusicStoreOwner") 
            {   //if insturction is music store owner, deliver the message
                DeliverMessage(user);//calls the method
            }//close if instruction matches
        }//close if menuu matches
    }//close lisen
}