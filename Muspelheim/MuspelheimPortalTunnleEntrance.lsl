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

list currentMessages; //list of all walkway reports as avi's walk over them
integer comsChannel = -111111;
integer comsChannelListen;
list approvedAccess; //list of who currently here has walked over all walkway bits but not yet passed through the gate
list currentAviPieces; //used while processing wich walkway bits an avi has been onver

SetupListener()
{   //sets up listeners
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE); //turns on listeners for main menu channel
}//close setup listeners

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
    string parsedName = firstName + " " + lastName;
    return parsedName;
}//close parse name

ProcessMessage(string message)
{   //adds walkway sensor messages to the messages list
    //string format aviUUID,ObjectName as a csv
    if (message == "WalkWaySensorOff") currentMessages = [];//clears all current messages from memory
    else if (message != "WalkWaySensorOn")
    {   //ignores any walkway sensor on messages and adds everything else to the messages list
        currentMessages += message;
        llSetTimerEvent(600);//10 mins timer
    }//close add messages
}//close process messages
 
ChkAviHasAccess(key dectectedUUID)
{   //checks to make sure this avi has walked over all the path pieces
    integer listLength = llGetListLength(currentMessages); //all messsages (multiple avis)
    integer currentMessagesIndex;
    currentAviPieces = []; //makes sure the current list is clear
    for (currentMessagesIndex = 0; currentMessagesIndex < listLength; ++ currentMessagesIndex)
    {   
        /*
        Loops through all entries in the current messages for walkway pieces walked over by this
        Avi. When it finds one it adds that piece to a new list which is specific to this avi. 
        */
        string strIndexEntry = llList2String(currentMessages, currentMessagesIndex);
        list lstIndexEntry = llCSV2List(strIndexEntry);
        key uuidLstEntry = llList2Key(lstIndexEntry, 0);
        string objectName = llList2String(lstIndexEntry, 1);
        if (uuidLstEntry == dectectedUUID) currentAviPieces += objectName;
    }//close loop through current messages
    integer currentAviPiecesLength = llGetListLength(currentAviPieces);
    integer passed;
    if (currentAviPiecesLength == 38) passed = TRUE; //correct number of entries in the list
    else passed = FALSE;
    integer piecesIndex = 0;
    while (passed && piecesIndex < currentAviPiecesLength)
    {   //loop through the entries checking they all match the expected format. 
        string pieceToCheck = "WalkWayDetector-" + (string)piecesIndex;
        if(!(~llListFindList(currentAviPieces, (list)pieceToCheck)))  
        {   //someone tried to cheat or else something else interfeared on the same channel
            passed = FALSE;
            llRegionSayTo(dectectedUUID, 0, "Did you try and cheat? If not please report this to an admin asbug. This item is owned by " + llKey2Name(llGetOwner()));
        }//close check list contents
        ++ piecesIndex;
    }//close while loop
    if (passed)
    {   //if all pieces have been walked over and the avi is not already in the list add them
        if(!(~llListFindList(approvedAccess, (list)dectectedUUID)))  approvedAccess += dectectedUUID;
    } //close if passed
    ChkApprovedAccessList(dectectedUUID); //send to chck approved access list
}//close check access

ChkApprovedAccessList(key dectectedUUID)
{   //checks to make sure the avi is on the access list
    string parsedName = ParseName(llKey2Name(dectectedUUID));
    if((~llListFindList(approvedAccess, (list)dectectedUUID))) 
    {   //come here if avi is on the approved access list
        llSay(0, "The gods nod their heads approvingly at " + parsedName);
        integer lastPortalChannel = -111111;
        string toSay = "GrantAccess" + "," + (string)dectectedUUID;
        llRegionSay(lastPortalChannel, toSay);
        RemoveAccess(dectectedUUID); //removes them from this temp access list after adding to the global
    }//close if avi is on approved access list
    else llSay(0, "The gods shake their heads dissaprovingly at " + parsedName);
}//close check access approved list

RemoveAccess(key dectectedUUID)
{   //removes access afer using the gate, this is just the temp list for this gate, they are now on the gloabal list 
     integer uuidListIndex =  llListFindList(approvedAccess, dectectedUUID);
     approvedAccess = llDeleteSubList(approvedAccess, uuidListIndex, uuidListIndex); //removes entry from approved access list
     integer index;
     for (index = (llGetListLength(currentMessages))-1; index >=0; --index)
     {  //loops through messages list clearing out all entries from this avi
         string strIndexEntry = llList2String(currentMessages,index);
         list listIndexEntry = llCSV2List(strIndexEntry);
         key uuidToCheck = llList2Key(listIndexEntry, 0);
         if (uuidToCheck == dectectedUUID) currentMessages = llDeleteSubList(currentMessages, index, index);
     }//close remove messages about this avi from messages list
     if (llGetListLength(currentMessages) == 0) llResetScript(); //clean up as no one is using the system
}//close remove access

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);
        SetupListener();
    }
    
     collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            ChkAviHasAccess(detectedUUID);
        }//close if detected type is an avatar
    }//close collissions
    
    listen( integer channel, string name, key id, string message )
    {
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {
            ProcessMessage(message);
        }
    }
    
    no_sensor()
    {   //no one around reset the script
        llSensorRemove();
        llResetScript();
    }
    
    timer()
    {   //clear lists, turn off sensors, stop timer
        currentMessages = [];
        approvedAccess = [];
        currentAviPieces = [];
        llRegionSay(comsChannel, "WalkWaySensorOff");//turns off the path sensors
        integer rezzerChannel = -111111;
        llRegionSay(rezzerChannel, "DeRezItems");//removes the walk way
        llSetTimerEvent(0); 
        llSensorRepeat( "", "", AGENT, 99, PI, 5 ); //will do a full reset if no one is around
    }
}