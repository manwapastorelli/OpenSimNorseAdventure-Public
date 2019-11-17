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

vector rezPos;
key aviUUID;
integer ValkChannel = -1111111;
integer inUse = FALSE;

default
{
     changed (integer change)
    {   //reset if we change owner or the region restarts
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    on_rez (integer param)
    {   //if ressed fresh reset the script
        llResetScript();
    }
    
    state_entry()
    {
        rezPos = llGetPos();//get the current position
        rezPos -= <0,0,0.70>;//set the res position offset
        inUse = FALSE;//se to not in luse
    }
    
    touch_start(integer any)
    {
        if ( llVecDist(llDetectedPos(0), llGetPos() ) > 5 )
        {   //if the toucher is a long way away send an error message
            llRegionSayTo(llDetectedKey(0), 0, "You need to be closer to use me"); 
        }//close user is too far away
        else
        {   //come here if they are close enough
            if (!inUse)
            {   //come here if the mirror is free for use
                inUse = TRUE; //set in use to restrict the mirror to this user for now
                aviUUID = llDetectedKey(0); //get the touchers uuid
                llRezAtRoot("Valkyrie Messenger", rezPos, ZERO_VECTOR, llGetRot(), 0); //rez the valkyrie messenger
                llSensorRepeat( "", aviUUID, AGENT, 10, PI, 1 );//set a sensor repeate to cehck for this avi leaving
            }//close mirror is free for use
            else 
            {   //send an error message as someone else is already using the mirror
                llRegionSayTo(llDetectedKey(0), 0, "Sorry the mirror is in use by someone else, please wait and try again");
            }//close mirror is in use by another avi
        }
    }
    
    no_sensor() 
     {  //come here if the avi who used the mirror has left the area  
        llRegionSay (ValkChannel, "Reverse"); //sends revers instruction to the valkyrie
        llSensorRemove();//stop the sensor
        llResetScript();//resets the script
     }//close no sensor
}