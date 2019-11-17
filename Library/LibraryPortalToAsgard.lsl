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

key lastAvi;

default
{
    state_entry()
    {
        osVolumeDetect(TRUE);
        llSetTextureAnim( ANIM_ON | LOOP, ALL_SIDES, 4, 4, 0.0, 16.0, 6.4 );
    }

    collision_start(integer total_number)
    {   //avi passed through this prim
        integer detectedType = llDetectedType(0);
        key aviKey = llDetectedKey(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            if(aviKey != lastAvi)
            {   //if detected avatar is not a repeat of the last detected avi
                lastAvi = aviKey;
                vector asgardPos = <655, 579, 6003>; 
                osTeleportAgent(aviKey, asgardPos, ZERO_VECTOR); //teleport avi to asgard
                integer comsChannel = -111111; //sets the channel number
                string toSay = "RemoveAvi" + (string)aviKey;
                llRegionSay(comsChannel, toSay); //message the stairs to remove this avi from the list
                llSetTimerEvent(30); //set timer event to clear last avi after 30s
                }//close if not a double entry by the same avi
            }//close if detected type is an avatar
    }//close collissions

    timer()
    {   //reset the script 
        llResetScript();
    }
}