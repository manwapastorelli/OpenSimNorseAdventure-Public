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

float timerInterval = 0.1;
integer timerCount;
float alphaLevel;
integer comsChannel = -1665905719;
integer comsChannelListen;
integer fadeIn = FALSE;
key aviUUID;
    
SetupListener()
{   //sets up all the listeners 
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, ""); 
    llListenControl (comsChannelListen, TRUE); 
}//close setup listeners

DeliverMessage()
{
    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "motions towards the spinning runes disc 'There is your reward'.");
}

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    on_rez( integer param)
    {
        llResetScript();
    }

    state_entry()
    {
        SetupListener();
        timerCount = 0;
        alphaLevel = 0;
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alphaLevel]);
    }

    listen(integer channel, string name, key id, string message)
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {
            list instructions = llCSV2List(message);
            string instruction = llList2String(instructions, 0);
            aviUUID = llList2Key(instructions, 1);
            if (instruction == "FadeOut")
            {
                fadeIn = FALSE;
                timerCount = 0;
                llSetTimerEvent(timerInterval);
            }

            else if (instruction == "FadeIn")
            {
                fadeIn = TRUE;
                timerCount = 0;
                llSetTimerEvent(timerInterval);
            }
        }
    }

    timer()
    {
        ++timerCount;
        if (fadeIn) alphaLevel += 0.05;
        else alphaLevel -= 0.05;
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alphaLevel]);
        if (timerCount >= 20)
        {
            llSetTimerEvent(0);
            if (!fadeIn)llResetScript();
            else DeliverMessage();
        }
    }
}