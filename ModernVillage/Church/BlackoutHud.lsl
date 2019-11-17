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

integer timerCount;
float alpha;
integer comsChannel = -111111;

default
{

    state_entry()
    {
        llSetLinkAlpha(LINK_SET, 0, ALL_SIDES); //at startup ensure the hud is total transparent
    }
    
    attach(key id)
    {
        if (id != "00000000-0000-0000-0000-000000000000")     // is a valid key and not NULL_KEY
        {   //we are attached, for a drop. 
            llPlaySound( "TardisSound - Take Off", 1.0); //play the take off sound
            timerCount = 0;
            alpha = 0;
            llSetTimerEvent(0.01);//start the timer... this script may not work well with timers on the default 0.5s for OS
        }
        else 
        {   //item has been dropped, kill it
            llDie();
        }
    }
    
    timer ()
    {
        ++timerCount; 
        if (timerCount < 100) 
        {   //add a tiny amount alpha level each timer cound
            alpha += 0.01;
            llSetLinkAlpha(LINK_SET, alpha, ALL_SIDES);
        }
        else if (timerCount == 120) 
        {   //force sit the avi onto the tp ball
            llRegionSay(comsChannel, "TardisForceSit");
            llPlaySound( "TardisSound- Landing", 1.0);
        }
        else if (timerCount > 130 && timerCount < 230) 
        {   //reduce the opacity by a tiny amount each timer count
            alpha -= 0.01;
            llSetLinkAlpha(LINK_SET, alpha, ALL_SIDES);
        }
        else if (timerCount >= 230) 
        {   //forces the attachment ot drop to the sim at the end. 
            osForceDropAttachment(); //force drops which will force deletion
            llSetTimerEvent(0);//stops the timer
        }
    }
}