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

string ParseName(string detectedName)
{ // parse name so both local and hg visitors are displayed nicely
string firstName;
string lastName;
integer periodIndex = llSubStringIndex(detectedName, ".");
list nameSegments;
if (periodIndex != -1)
    {   //this is a hypergrid visitor
        nameSegments = llParseString2List(detectedName,[" "],["@"]);
        string hGGridName = llList2String(nameSegments,0);
        nameSegments = [];
        nameSegments = llParseStringKeepNulls(hGGridName, [" "], ["."]);
        firstName = llList2String(nameSegments,0);
        lastName = llList2String(nameSegments,2);
    }//close if hg visitor
else
    {   //this is a local visitor
        nameSegments = llParseString2List(detectedName, [" "], []);
        firstName = llList2String(nameSegments, 0);
        lastName = llList2String(nameSegments, 1);
    }//close if local visitor
string fullName = firstName + " " + lastName;
return fullName;
}//close parse name


default
{
     changed (integer change)
    {   //reset the script if the region restarts or the owner changes
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);//make the item volumetric
        llSetObjectName("Welcome Sign Greeter");//set object name to welcome sign
    }

    collision_start(integer total_number)
    {   //come here when someone walks through the greeter
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            if(!(~llListFindList(currentAvis, (list)detectedUUID)))
            {   //only process if a bot fo this avatar doesn't exist already
                currentAvis += detectedUUID;
                string detectedName = llKey2Name(detectedUUID);
                string name = ParseName(detectedName);
                llSetObjectName(name); //sets the object name to the avi name so it looks like a thought
                //deliver the message
                llRegionSayTo(detectedUUID, PUBLIC_CHANNEL, "stepping under the welcome sign you find yourself in a modern norse town. Oddly your belly rumbles reminding you that you are hungry");
                llSetTimerEvent(60);//set a timer for a min
            }//close if bot for avi doesn't exist
        }//close if detected type is an avatar
    }//close collissions
    
    timer()
    {
        llResetScript();
    }//close timer
}