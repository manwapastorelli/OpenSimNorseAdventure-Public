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

string CleanNamesIncaseHgVisitor(string detectedName)
{ // parse name so both local and hg visitors are displayed nicely
//hypergrid name example firstName.LastName@SomeGrid.com:8002
string firstName;
string lastName;
string cleanName;
integer atIndex = llSubStringIndex(detectedName, "@"); //get the index position of the "@" symbol if present
integer periodIndex = llSubStringIndex(detectedName, ".");//get the index position of the "." if present
list nameSegments;
if ((periodIndex >= 0) && (atIndex >= 0))
    {   //the detected name contains both an "@"" and "." so this avi is a hypergrid visitor
        //llOwnerSay("HyperGridAviDetected");
        nameSegments = llParseString2List(detectedName,[" "],["@"]);//split the dected name into two list elements
        string hGGridName = llList2String(nameSegments,0); //everything before the @ 
        nameSegments = llParseStringKeepNulls(hGGridName, [" "], ["."]); //split the hg name into two list elements
        firstName = llList2String(nameSegments,0); //retrieve the first name from the 1st index in the list
        lastName = llList2String(nameSegments,2); //retrieve  the last name form the 2nd index in the list
        cleanName = firstName + " " + lastName; //combines the names to look like a local visitors name
    }//close if hg visitor
else
    {   //this is a local visitor the name is already clean
        cleanName = detectedName;
    }//close if local visitor
return cleanName; //returns the cleaned name to the calling method
}//close parse name

default
{
     changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);
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
                string detectedName = llKey2Name(detectedUUID);
                string name = CleanNamesIncaseHgVisitor(detectedName);
                llSetObjectName(name);
                llRegionSayTo(detectedUUID, PUBLIC_CHANNEL, "weird..those stones are different, like they don't belong here");
                llSetTimerEvent(60);
            }//close if bot for avi doesn't exist
        }//close if detected type is an avatar
    }//close collissions
    
    timer()
    {
        llResetScript();
    }//close timer
}