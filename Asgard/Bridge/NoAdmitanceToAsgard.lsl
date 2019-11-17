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
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    on_rez(integer param)
    {
        llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);
    }
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        key aviKey = llDetectedKey(0);
        {
            if (detectedType == 1 || detectedType == 3 || detectedType == 5)
            {   //only process avatars, no bots or physical objects
                if(aviKey != lastAvi)
                {
                    lastAvi = aviKey;
                    llPlaySound("No Mortal Admision To Asgard Today", 1);
                    llSay(0,  "The Allfather is not seeing mortals this day");
                    llSetTimerEvent(20);
                }//close if not a double entry by the same avi
            }//close if detected type is an avatar
        }//close if active
    }//close collissions
    
    timer()
    {
        llResetScript();
    }
}