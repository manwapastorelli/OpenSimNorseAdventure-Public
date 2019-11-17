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

list currentAvis;

ShowMap()
{   //makes the map glow a bit and delivers a message
    llSay(0 , "They used to live here, but now only ruins dwell among new abodes, and yet someone still does"); //delivers the message
    llSetLinkPrimitiveParamsFast( LINK_ALL_CHILDREN, [PRIM_GLOW, ALL_SIDES, 0.1] );//sets the map glowing
    llSetTimerEvent(60);//starts a timer event for 60s
}//close show map


default
{
     changed (integer change)
    {   //restarts the script is the region is restarted or the owner changes
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);//makes the item voumetric
        llSetLinkPrimitiveParamsFast( LINK_ALL_CHILDREN, [PRIM_GLOW, ALL_SIDES, 0.0] ); //turns off glow in all child prims
    }
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            if(!(~llListFindList(currentAvis, (list)detectedUUID)))
            {   //only process if a bot fo this avatar doesn't exist already
                currentAvis += detectedUUID;
                ShowMap();
            }//close if bot for avi doesn't exist
        }//close if detected type is an avatar
    }//close collissions
    
    
    
    timer()
    {
        llResetScript();
    }//close timer
}