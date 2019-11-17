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
vector posInterval;
integer comsChannel = -111111;
integer comsChannelListen;
integer forwardsMotion = TRUE;

SetupListener()
{   //sets up all the listeners 
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, ""); 
    llListenControl (comsChannelListen, TRUE); 
}//close setup listeners

DeliverMessage()
{   //deliver the message 
    llSay(0, "In the heart of the village, find that which does not belong, and you will find the way forwards. Now turn left as you leave, then north. I am sure the cartographer will help you.");
}

default
{
    on_rez (integer param)
    {
        llResetScript();//if rezzed reset the script
    }
    state_entry()
    {   //come here when the script starts up
        SetupListener(); //sets up the listeners
        timerCount = 0; //set timer count to 0
        alphaLevel = 0; //set the alpha level to 0 (invisible)
        forwardsMotion = TRUE;//sets forwards motoin to true as we move forwards first
        posInterval = llGetPos(); //sets the start position to the current possition
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alphaLevel]); //esures on startup the figure is invisible
        llSetTimerEvent(timerInterval); //starts a timer based on the interval in global settings
    }

    touch_start(integer any)
    {   //come here when the prim is touched
        DeliverMessage(); //if touched deliver the message
    }
    
    listen(integer channel, string name, key id, string message)
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {   //if the message is on the coms channel and the owners key is the same as this keys owner
            if (message == "Reverse")
            {   //come here if the message is reverse
                forwardsMotion = FALSE; //set motion direction to false
                timerCount = 0; //reset the timer count
                llSetTimerEvent(timerInterval); //sets the timer ot the interval in the global variables.
            }//close if message is reverse
        }//close if channels and owners match
    }//close listen
        
    timer()
    {
        ++timerCount;
        if (forwardsMotion)
        {   //do this if forwards motion is true
            alphaLevel += 0.05; //increase the alpha level
            posInterval -= <0,0.1,0>; //move forwards
        }//close forwards motion
        else
        {   //do this if forwards motion is false
            alphaLevel -= 0.05; //decrease the alpha level
            posInterval += <0,0.1,0>;//move backwards
        }//close forwards motoin
        llSetLinkPrimitiveParamsFast(1, [PRIM_POSITION, posInterval]); //sets the postion determined above
        llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_COLOR, ALL_SIDES, <1,1,1>, alphaLevel]); //sets the alpha level determined above
        if (timerCount >= 20)
        {   //come here if the timer reaches 20
            if (!forwardsMotion)llDie(); //if we are going backwards, show ever, remove the messenger
            else DeliverMessage();//this is only the end of the forwards bit, deliver the message
            llSetTimerEvent(0);//stop the timer. 
        }//close timer count is 20
    }//close timer
}//close state default