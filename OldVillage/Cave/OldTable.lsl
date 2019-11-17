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

integer comsChannel = -1433668630;
integer comsChannelListen;
integer mapLink;
integer timerCount;
key user;

SetupListener()
{
    integer comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE);
}

ProcessMessage(key id, string message)
{   //process the provided message
    if (message == "ShowMap") 
    {   //come here if the message is ShowMap
        user = llGetOwnerKey(id); //gets the uuid of the toucher
        ShowMap();//call show map method
    } //close if message is show map
    else if (message == "Reset") 
    {   //come here if the message is reset
        llResetScript(); //resets the script
    }//close if message is reset
}//close process message

ShowMap()
{   //displays the map on the table
    llSetLinkPrimitiveParams(mapLink, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 1  ] );//sets the link visible
    llSay(PUBLIC_CHANNEL, "A strange presence and glow fills the cavern, a blue light develops near the table");//delivers a message
    llRegionSay(comsChannel, "ActivatePortal");//send message to portal
}//close show map

GetLinks()
{   //loops through the links and find the record link
    integer linkIndex;
    for (linkIndex = 2; linkIndex <= llGetNumberOfPrims(); ++linkIndex)
    {   //loop through all links untill we find the map link then store it
        string linkName = llGetLinkName(linkIndex);
        if (llGetLinkName(linkIndex) == "Colby Map") 
        {   //match found - come here
            mapLink = linkIndex;//store the map link index
        }   //close  match found
    }//close get links
}//close get links


default
{
    on_rez( integer start_param)
    {   //when rezzed reset the script
        llResetScript();
    }

    changed (integer change)
    {   //if the owner changes or the region restarts reset the script
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }

    state_entry()
    {
        SetupListener();//sets up listeners
        GetLinks();//lets the link numbers
        llSetLinkPrimitiveParams(mapLink, [PRIM_COLOR, ALL_SIDES, <1,1,1>, 0  ] ); //sets the map link to invisible
    }

    listen( integer channel, string name, key id, string message )
    {   //if a message is heard on the coms channel process it
        if (channel == comsChannel) ProcessMessage(id, message);//send the nmessage to the process message method
    }

}