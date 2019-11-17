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

list currentUsers;
list choiceDelivered;
list avisToTrap;

integer comsChannel = -111111;
integer comsChannelListen;
integer menuChannel;
integer menuChannelListen;
integer sensorCount;

key trapUUID;

SetupListeners()
{   //definwes listeners and turns them on or off as required
    menuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0);
    menuChannelListen = llListen(menuChannel, "", NULL_KEY, "");
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");
    llListenControl(comsChannelListen, TRUE); //turns on the coms channel listener
    llListenControl(menuChannelListen, FALSE); //turns off the menu listener
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
string fullName = firstName + " " + lastName;
return fullName;
}//close parse name

ProcessResponse(key aviUUID, string message)
{   //mages responses to the menu
    if (message == "Story") DeliverStory(aviUUID);
    //do nothing if desire is clicked as a timer is already running, the button is just for show.;    
}//close proceass menu response

DeliverStory(key aviUUID)
{   //reads out lokis story then removes thewm from the palace in a ball
    //add code to read the story here, then do the trap and remove.
    
    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "One night I sneakered into Sif's bedroom- Thor's bethroted, while she was asleep and cut off her beautiful golden hair. What a wonderful stunt! But Thor didn't like it and almost strangled me, so I agreed to meet the dwarves and talk them into making a magical cap of golden hair for Sif, so that it might grow like real hair when placed on her head. Bring me the golden cap, my reward and Odin's will be yours");
    llSleep(5);
    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Now you know what i want it is time for you to leave!");
    TrapAndRemove(aviUUID);
}//close deliver story

TrapAndRemove(key aviToTrap)
{   //force sits the avi from the last button click onto the trap
    if (!(~llListFindList(avisToTrap, (list)aviToTrap))) avisToTrap += aviToTrap;
    //llOwnerSay("Debug: toTrapList: " + llList2CSV(avisToTrap));
    integer trapIndex ;
    for (trapIndex = (llGetListLength(avisToTrap)-1); trapIndex >= 0; --trapIndex);
    {
        key aviToRemove = llList2Key(avisToTrap, trapIndex);
        //llOwnerSay("Debug: Remove Avi: " + (string) aviToRemove);
        osForceOtherSit(llList2Key(avisToTrap, trapIndex), trapUUID);
        avisToTrap = llDeleteSubList(avisToTrap, trapIndex, trapIndex);
        RemoveFromCurrentUsers(aviToTrap);
        llSleep(7);
    }  
}//close trap and remove. 

ReturnToAsgard(key aviUUID)
{   //teleports them back to asgard
    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Take this book, place it on the Asgard side of the bi-frost. There you will find your reward. Now I will return you to Asgard.");
    llSleep(3);
    vector asgard = <654.70361, 578.43115, 6001.21387>;
    osTeleportAgent(aviUUID, asgard, ZERO_VECTOR); //does the teleport
    RemoveFromCurrentUsers(aviUUID); //removes this person from the current users list
}//close telwport to asgard

RemoveFromCurrentUsers(key aviUUID)
{   //removes the specified uuid from the list of current users
    integer aviListIndex = llListFindList(currentUsers, aviUUID); //finds the index of this uuid entry in the list
    if (aviListIndex != -1) currentUsers = llDeleteSubList(currentUsers, aviListIndex, aviListIndex); //assuming the entry actually exists remove it
    if (llGetListLength(currentUsers) == 0) llResetScript();//no users to reset the script. 
}//close remove from current users

ClearListsReset()
{   //if 30mins have expired with people just doing nothing kick them out so we can clear and rest the script
    //memory management. 
    integer usersListLength = llGetListLength(currentUsers);
    integer userIndex;
    for(userIndex = 0; userIndex < usersListLength; ++userIndex)
    {   //loops through all users currently on the list
        key aviUUID = llList2Key(currentUsers, userIndex); //finds the uuid stored at the current list index
        string message = "Laughter errupts from Loki, you are so slow you try the patience of a GOD, ouside the palace you go!";
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, message); //deliver good bye message
        TrapAndRemove(aviUUID); //fore sits on the trap ball
        llSleep(5); //allow time for new trap to rez and move into place
    }
    llResetScript();
}//close clear lists and reset

ResetTraps()
{   //remove any rezzed traps and rez a new one
    integer rezzerChannel = -1868343768;
    string message = "DeRezItems";
    llRegionSay(rezzerChannel, message);
    llSleep(5);
    message = "RezSingleItem" + "," + "Loki Trap - Wire Cage";
    llRegionSay(rezzerChannel, message);
}//close reset traps

RemoveUnknownAvi(key suppliedUUID)
{   //sends removal message to avi then force sits them on the trap
    key userNow = suppliedUUID;
    llRegionSayTo(suppliedUUID, PUBLIC_CHANNEL, "Hmmm how did you get in here, did you somehow bypass my people outside... or have you just taken so long they do not remember you? No matter, you must now go through them regardless! BEGONE!");
    TrapAndRemove(userNow);
}//close remove unknown avi


DeliverBook (key aviUUID)
{   //if the book exists in the inventory deliver it, else send an error message
    string itemName = "Sif' story book";//define the item name
    integer itemType = llGetInventoryType(itemName); //get the type of the item with this name
    if (itemType == INVENTORY_OBJECT) llGiveInventory(aviUUID, itemName); //deliver the item if it exists
    else llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Sorry this item is supposed to give you Sif's Story Book, however it is missing form the items contents. You can not continue without it. Please report this to the admin. This item is owned by:" + llKey2Name(llGetOwner())) ;
} //close deliver book

DialogMenu(key aviUUID)
{
     string aviName = ParseName(llKey2Name(aviUUID)); //clean up the name incase of HG visitors
     string message = "Welcome " + aviName + "\n I am Loki. Would you like to hear part of my story or have you brought me my desire? \n \n Please note that choosing to give Loki his desire will start a 30 min timer. If you do not complete the task in that time you will be removed from the palace. If you logout from the palace and relog you will be stuck inside. If this happens to you just click on Loki, then you will be transported back to the start of this area.";
     llRegionSayTo(aviUUID, PUBLIC_CHANNEL, message); //deliver message
     list menuButtons = ["Story", "Desire"]; //make the menu
     llDialog(aviUUID, message, menuButtons, menuChannel);//deliver the menu
}

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {   //this happens when the script first starts
        SetupListeners();
        ResetTraps();
    }//close state entry

    listen( integer channel, string name, key id, string message )
    {   //listen event reports on all items heard based on the listeners set
        if (channel == comsChannel )
        {
            list instructions = llCSV2List(message); //make a list from the messagw
            string instruction = llList2String(instructions, 0); //first element in the list
            key aviUUID = llList2Key(instructions, 1);//second element in the list
            if (instruction == "SifsGoldenCap")
            {   //come here if the instruction is sifs golden cap
                if (~llListFindList(currentUsers, (list)aviUUID))
                {   //come here if the avi is found on the current users
                    llRegionSayTo(id, comsChannel, "Die"); //sends a message to the cap to die
                    DeliverBook (aviUUID);
                    ReturnToAsgard(aviUUID);
                }//close if found on list
                else RemoveUnknownAvi(aviUUID); //not on list, tried to cheat or reloged here, remove the avi
            }//close if instruction is golden cap
            else
            {   //come here for all instructions other than sifs golden cap
                if (llGetOwnerKey(id) == llGetOwner())
                {   //come here if the sending object has the same owner
                    if (instruction == "ActivateLoki")
                    {    //comw here if the first part is ActivateLoki
                        llListenControl(menuChannelListen, TRUE); //turn the menu channel listener on if its not already
                        if (!(~llListFindList(currentUsers, aviUUID))) currentUsers+= aviUUID; //add to current users if not already
                        llSetTimerEvent(1800); // 30 mins timer begins
                        llSensorRepeat("", NULL_KEY, AGENT, 10, PI, 3); // start a repeated sensor
                    }//close if activate loki
                    else if (instruction == "TrapUUID") trapUUID = id;
                }//close if message sent by an object with the same owner
            }//close else if not golden cap message
        }//close if channel is coms channel
        else if (channel == menuChannel)
        {   //if the response comes from a current user and is on the text box channel process the message
            if(~llListFindList(currentUsers, id)) ProcessResponse(id, message);
        }//close textbox channel
    }//close listen event
    
    touch_start(integer dont_care)
    {
        key aviUUID = llDetectedKey(0);
        if (~llListFindList(currentUsers, aviUUID)) DialogMenu(aviUUID);
        else RemoveUnknownAvi(aviUUID);
    }

    sensor( integer num_detected )
    {   //sensor reports on avis and objects specified by the sensor instruction. 
        integer agentIndex;
        for(agentIndex = 0; agentIndex < num_detected; ++ agentIndex)
        {//loops through the sensor results
            key aviUUID = llDetectedKey(agentIndex);
            if (~llListFindList(currentUsers, aviUUID))
            {   //come here if avi not found on current users list
                if (!(~llListFindList(choiceDelivered, aviUUID))) 
                {   //come here if avi not found on choices delivered list either
                    choiceDelivered += aviUUID; //add them to this list
                    string name = ParseName(llKey2Name(aviUUID));
                    llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Welcome " + name + " place your hand on me (click me) to get your choices. You must be patient though, I will only deal with one person at a time. If you touch me while i am still dealing with someone else I will simply ignore you!");
                }//close if not found on choices delivered list
            }//close if not found on the current users list
        }//closee loops through sensor results
    }//close sensor

    timer()
    {   //clears lists and resets if the timer runs out
        ClearListsReset();
    } 
}//close state default