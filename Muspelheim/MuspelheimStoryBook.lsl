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

SetUpListeners()
{   //sets up all the listeners 
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, ""); 
    llListenControl (comsChannelListen, TRUE); 
}//close setup listeners

StartTranslation()
{
    llSetLinkAlpha(4, 1, ALL_SIDES);
    llSetLinkPrimitiveParamsFast(4, [PRIM_OMEGA, <0,1,0>,TWO_PI,1.0] );
    llSay(PUBLIC_CHANNEL, "During Ragnarok, the fire giant Surt, arrives from Muspelheim which is the realm of heat and fire with a flaming sword to slay the gods and burn the world");
    llSay(PUBLIC_CHANNEL, "a short distance away the movement of rock can be heard, the the splosh of something landing in the lava");
}

LayPath()
{
    integer rezzerChannel = -111111;
    llRegionSay(comsChannel, "WalkWaySensorOn");
    string toRezName = "WalkWay0";
    string toSay = "RezSingleItem" + "," + toRezName;
    llRegionSay(rezzerChannel, toSay);
    llSetTimerEvent(30);
}

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        llSetLinkAlpha(4, 0, ALL_SIDES);
        llSetLinkPrimitiveParamsFast(4, [PRIM_OMEGA, <0,0,0>,TWO_PI,1.0] );
        SetUpListeners();
    }

    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel && message == "StarTranslation") 
        {
            StartTranslation();
            LayPath();
        }
    }

    timer()
    {
        llResetScript();
    }
}