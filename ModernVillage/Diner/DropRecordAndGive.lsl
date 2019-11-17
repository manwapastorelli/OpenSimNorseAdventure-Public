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

integer comsChannel =  -111111;
integer comsChannelListen;

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


SetupListener()
{   //sets up the listeners
    integer comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannel, TRUE);
}//close setup listeners

RecordDrop()
{   //makes the record physical so it drops with gravity
    llSetStatus(STATUS_PHYSICS, TRUE);
}//close drop record

default
{
    state_entry()
    {
        SetupListener(); //sets up listeners
    }

    listen( integer channel, string name, key id, string message )
    {   //if meassage heard on coms channel and the object owner is our owner and the message is drop record - DO IT!
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner() && message == "RecordDrop") RecordDrop();
    }//close listen

    touch_start( integer num_detected )
    {   //when clicked
        string nameToGive = "vynil_record";
        key aviUUID = llDetectedKey(0);
        if (llGetInventoryType(nameToGive) == INVENTORY_OBJECT) 
        {   //if the item exists deliver the record to the one who clicked 
            llGiveInventory(aviUUID, nameToGive);
        }//close if item exists
        else 
        {   //the item is missing form the inventory, send erro0r message
            llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "This item is supposed to give you a record. You will not be able to continue without it. Please contanct an admin. This item is owned by:" + llKey2Name(llGetOwner()));
        }//close else not present
        string aviName = ParseName(llKey2Name(aviUUID)); //get the clean avi name without hg bits
        llSetObjectName(aviName);//set the name to the avi's name
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "a record... I wonder where it can be played... "); //deliver message like a thought from the avi. 
    }
}