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

SetupListeners()
{   //definwes listeners and turns them on or off as required
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE); //turns on the coms channel listener
}//close setup listeners
 
default
{
    on_rez (integer parm)
    {
        llResetScript(); //reset the script when rezzed. 
    }

    state_entry()
    {
        SetupListeners();
        string message = "SifsGoldenCap" + "," + (string)llGetOwner(); //define the message to send to loki
        llRegionSay(comsChannel, message); //send the message 
        llSetTimerEvent(300);//start the timer event to make sure everything is cleared up
    }

    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel && message == "Die")
        {   //come here if the channel is the coms channel and the message is die
            llDie();//remove item from the sim
        }//close if message is die
    }//close listen

    timer()
    {   //if the timer runs out remove the cap and send an error message to the user
        llRegionSayTo(llGetOwner(), PUBLIC_CHANNEL, "Sorry timed out, please rez me again"); //send error message to the user
        llDie();//remove from the sim
    }//close timer
}//close state default