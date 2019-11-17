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
integer recordLink;
integer timerCount;
key user;

SetupListener()
{   //setup listeners
    integer comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE);
}//close setup listeners

ProcessMessage(key id, string message)
{   //process provided message and uuid
    if (message == "PlayRecord") 
    {   //come here if message is play record
        user = llGetOwnerKey(id); //get thekey of the records owner
        llRegionSayTo(id, comsChannel, "die"); //send die message to the record
        PlayRecord();// play the record
    }  //play record message
}//close process message

PlayRecord()
{   //plays the sound tracks and sets the spinning record visible
    llSetLinkPrimitiveParams(recordLink, [PRIM_OMEGA, <0,-1,0>,TWO_PI,1.0, PRIM_COLOR, ALL_SIDES, <1,1,1>, 1  ] );//set record visible and spinning
    llSay(PUBLIC_CHANNEL, "The sound of music fills the store");//message in chat incase people have their speakers off
    llPlaySound("carmina burana 1", 1);//plays the sound track
    timerCount = 0;//sets timer count to 0
    llSetTimerEvent(10);//starts a 10s timer (length of the track)
}

GetLinks()
{   //loops through the links and find the record link
    integer linkIndex;
    for (linkIndex = 2; linkIndex <= llGetNumberOfPrims(); ++linkIndex)
    {   //loop through all links in the linkset
        string linkName = llGetLinkName(linkIndex);//get the name of this link
        if (llGetLinkName(linkIndex) == "vynil_record") 
        {   //come here if the name is vinil record
            recordLink = linkIndex; //record the index
        }    //close if name matches
    }//close loop through inventory
}//close get links


default
{
    on_rez( integer start_param)
    {   //reset the script when rezzed
        llResetScript();
    }//close on rez

    changed( integer change )
    {   //reset the script if the sim is restarted or the owner changes
        if (change & CHANGED_OWNER | CHANGED_REGION_RESTART | CHANGED_REGION_START) llResetScript();
    }//close changed

    state_entry()
    {
        SetupListener(); //setup listeners
        GetLinks();//get the record link
        llSetLinkPrimitiveParams(recordLink, [PRIM_OMEGA, <0,0,0>,TWO_PI,1.0, PRIM_COLOR, ALL_SIDES, <1,1,1>, 0  ] );//set record invisible and still
    }//close state entry

    listen( integer channel, string name, key id, string message )
    {   //if channel matches coms channes, process the message
        if (channel == comsChannel) ProcessMessage(id, message);
    }//close listen

    timer()
    {
        if (timerCount == 0 ) 
        {   //first time the timer executes play track2
            llPlaySound("carmina burana 2", 1);
        }//close if timer count is 0
        else 
        {   //2nd track finished
            llSetTimerEvent(0);//stop the timer
            string toSay = (string)user +  "," + "MusicStoreOwner";//message to the store owner prim to begin
            llRegionSay(comsChannel, toSay);//send the message
            llResetScript();//reset this script
        }//close else count is greater than 0
        ++timerCount;//add one to the timer count
    }//close timer
}