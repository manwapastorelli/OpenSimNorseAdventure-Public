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



list aviAndBots; //strided list aviUUID, botUUID - lists avis and bots currently being used.
list movingBots; //strided list aviUUID, botUUID - list of bots which are moving towards their avi
list msg2Delivered; //list of botUUID's out which have given messag2
rotation botROT;
vector standPos;
string currentWalk;
string currentStand;
string maleWalk = "MensWalk";
string maleStand = "MensStand";
string femaleWalk = "LadiesWalk";
string femaleStand = "LadiesStand";
string firstName;
string lastName;
key detectedUUID;


SetBotStartPosRot()
{
botROT = llEuler2Rot(<0,0,0>*DEG_TO_RAD);
standPos = llGetPos() + <0,0,0>;
}

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

CreateNewBot(key detectedUUID)
{   //makes a new both with specified details and adds both the avi and bot uuid to the aviandbots list
    key newBotID = osNpcCreate(firstName, lastName, standPos, detectedUUID);
    SetGender(detectedUUID);
    SetStandAnim (newBotID);
    string about = firstName + " " + lastName + "'s doppleganger";
    osNpcSetProfileAbout(newBotID, about);
    aviAndBots += detectedUUID; 
    aviAndBots += newBotID;
    firstName = "";
    lastName = "";
    SayMessage(detectedUUID, newBotID, 1);
    llSensorRepeat( "", "", AGENT, 30, PI, 5);
}//close create new bot

RemoveAllBots()
{   //lopps through all bots and removes them all
    integer listIndex;
    for (listIndex = 1; listIndex < llGetListLength(aviAndBots); listIndex = listIndex+2)
    {
        key currentBot = llList2Key(aviAndBots, listIndex);
        osNpcRemove(currentBot);
    }
}//close remove all bots

list ItemDelete(list listToDelFrom, key botToRemove)
{
    integer itemIndex = llListFindList(listToDelFrom, [botToRemove]);
    if (itemIndex != -1) return llDeleteSubList(listToDelFrom, itemIndex, itemIndex);
    else return listToDelFrom;
}

CleansListAndBots(list currentAvis, list detectedAvis)
{   //removes boths and clears lists of avis no longer present
    integer currentAvisIndex;
    for (currentAvisIndex = 0; currentAvisIndex < llGetListLength(currentAvis); ++ currentAvisIndex)
    {   //loops through the avi's we have made bots for
        key aviToChk = llList2Key(currentAvis, currentAvisIndex);
        if(!(~llListFindList(detectedAvis, (list)aviToChk)))
        {   //if the currently being checked avi is not in detected avi's list
            integer aviAndBotsIndex = llListFindList(aviAndBots, [aviToChk]); //find its position in the main list
            key botToRemove = llList2Key(aviAndBots, aviAndBotsIndex+1); //gets the key of the bot to remove
            osNpcRemove(botToRemove); //removes the bot associated with the avi thats gone away
            msg2Delivered = ItemDelete(msg2Delivered, botToRemove);    
            aviAndBots = llDeleteSubList(aviAndBots, aviAndBotsIndex, aviAndBotsIndex+1); //remove avi and bot from the main list
            if (llGetListLength(aviAndBots) == 0)ClearAndReset(); //clears memory and resets the script as the item is not in use
        }//close if the avi has gone away
    }//close loop through current avi list
}//close clean lists and bots
 
ClearAndReset()
{   //removes the sensor, clears the list and resets the script
    llSensorRemove();
    aviAndBots = [];
    movingBots = [];
    msg2Delivered =[];
    llResetScript();
}//close clear and reset

UpdateBotPositions()
{   //compares the positions of avi and bot pairs, moving the bots to the avi's
    integer aviBotsIndex;
    for (aviBotsIndex = 0; aviBotsIndex < llGetListLength(aviAndBots); aviBotsIndex = aviBotsIndex+2)
    {   //loops through the list of avi and bots
        key aviToChk = llList2Key(aviAndBots, aviBotsIndex);
        key botToChk = llList2Key(aviAndBots, aviBotsIndex+1);
        list aviDetails = llGetObjectDetails(aviToChk, [OBJECT_POS] );
        vector aviPos = llList2Vector(aviDetails,0);
        vector botPos = osNpcGetPos(botToChk);
        float distBetween = llVecDist( aviPos, botPos);
        if (distBetween > 5) 
        {
            SetGender(aviToChk);
            SetWalkAnim(botToChk);
            osNpcMoveToTarget(botToChk, aviPos, OS_NPC_NO_FLY); //walks the bot to the avi
            if(!(~llListFindList(movingBots, (list)aviToChk)))
            {
                movingBots += aviToChk; //adds avi to moving list
                movingBots += botToChk; //adds bot to moving list
            }
            llSetTimerEvent(0.5); //starts a timer
        } 
    }//close loop through avi in list
}//close update bot positions

SetGender(key aviToCheck)
{   //sets the current animation to male or female based in the avi provided
    string aviGender = osGetGender(aviToCheck); //get avi gender, aka animation to effect
    if (aviGender == "male") 
    {   //sets to male animations
        currentWalk = maleWalk;
        currentStand = maleStand;
    }
    else 
    {   //sets to female animations
        currentWalk = femaleWalk;
        currentStand = femaleStand;
    }
}//close set gender for animation

SetWalkAnim(key botUUID)
{   //stops the stand if playing and starts walk anim
    osNpcStopAnimation(botUUID, currentStand); //stop animation walk
    osNpcPlayAnimation(botUUID, currentWalk); //start animation stand
}//close set walk anim

SetStandAnim (key botUUID)
{   //stops the walk if playing and starts the stand anim
    osNpcStopAnimation(botUUID, currentWalk); //stop animation walk
    osNpcPlayAnimation(botUUID, currentStand); //start animation stand
}//close set stand anim

SayMessage(key aviUUID, key botUUID, integer  msgNum)
{   //delivers a message
    //llOwnerSay("Debug: avi uuid: " + (string)aviUUID);
    string aviName = llKey2Name(aviUUID);
    CleanNamesIncaseHgVisitor(aviName);
    string message; 
    string toSay;
    if (msgNum == 1)
    {
        message = "You are the righteous offspring. You will be given the truth if you dare starting this journey. Find the old village and you will be shown a messenger";
        toSay = aviName + "? Yes it is, it really is you, I mean me, I mean you. " + message;
        osNpcSay(botUUID, toSay);
    }
    else if (msgNum == 2)
    {   //deliver message 2 if this bot has not delivered it already
        if(!(~llListFindList(msg2Delivered, (list)botUUID)))
        {   //if msg2 not delivered deliver it now
            message = "I can't follow you far but i will stay with you as long as i can";
            toSay = firstName + " " + message;
            msg2Delivered += botUUID;
            osNpcSay(botUUID, toSay);
        }//close if not delivered   
    }//close 
}//close say message

default
{
     changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE);
        SetBotStartPosRot();
    }
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            detectedUUID = llDetectedKey(0);
            if(!(~llListFindList(aviAndBots, (list)detectedUUID)))
            {   //only process if a bot fo this avatar doesn't exist already
                string detectedName = osKey2Name(detectedUUID);
                CleanNamesIncaseHgVisitor(detectedName);
                CreateNewBot(detectedUUID);
                llSensorRepeat( "", "", AGENT, 30, PI, 5);
            }//close if bot for avi doesn't exist
        }//close if detected type is an avatar
    }//close collissions
    
    sensor  (integer numDetected)
    {
        integer detectedIndex;
        list currentAvis = [];
        integer aviBotsListIndex;
        integer aviBotsListLength = llGetListLength(aviAndBots);
        if (aviBotsListLength == 0 ) 
        {   //nothing to check or update, kill the sensor
            llSensorRemove();
        }//close if nothing to do
        else 
        {   //come here if we have avis and bots to check
            for (aviBotsListIndex = 0; aviBotsListIndex < aviBotsListLength; aviBotsListIndex = aviBotsListIndex +2)
            {   //loops through the list of avis and bots making seperate list of just avis
                currentAvis += llList2Key(aviAndBots, aviBotsListIndex);
            }//close make bots list
            list detectedAvis = [];
            for (detectedIndex = 0; detectedIndex < numDetected; ++detectedIndex)
            {   //loops through all detected agents
                detectedUUID = llDetectedKey(detectedIndex);
                if(~llListFindList(currentAvis, (list)detectedUUID))
                {   //if the detected avi is in the list of current avi's add to the list of detected avis, 
                    //no need to worry about others randomly wandering around
                    detectedAvis += detectedUUID; //add to list of detected avis
                } 
            }
            CleansListAndBots(currentAvis, detectedAvis); //clears no longer needed bots and list entries
            UpdateBotPositions(); //moves bots to updated positions if needed            
        }//close if we have bots out 
    }//close sensor
        
    no_sensor()
    {   // no one around, clear bots and memory
        RemoveAllBots();
        ClearAndReset();
    }//close no sensor
    
    timer()
    {
        integer movingBotsListLength = llGetListLength(movingBots);
        if (movingBotsListLength < 2) llSetTimerEvent(0); //nothings moving kill the timer
        else
        {   //come here if we have moving bots
            integer movingIndex;
            for (movingIndex = 0; movingIndex < llGetListLength(movingBots); movingIndex += 2)
            {   //loops through the list of moving bots
                key aviUUID = llList2Key(movingBots, movingIndex);
                key botUUID = llList2Key(movingBots, movingIndex+1);
                list aviDetails = llGetObjectDetails(aviUUID, [OBJECT_POS] );
                vector aviPos = llList2Vector(aviDetails,0);
                vector botPos = osNpcGetPos(botUUID);
                float distBetween = llVecDist(aviPos, botPos);
                if (distBetween < 3 )
                {   //stop the movement, stop the walk anim, start the standing anim, remove from moving list
                    SetGender(aviUUID);
                    osNpcStopMoveToTarget(botUUID); //stop movement
                    SetStandAnim (botUUID); //set standing
                    SayMessage(aviUUID, botUUID, 2); //deliver message
                    movingBots = llDeleteSubList(movingBots, movingIndex, movingIndex+1); //remove avi and bot from the main list
                }//close if distnace is less than 2m
            }//close loop through moving bots
        }//close if we have moving bots
    }//close timer
}