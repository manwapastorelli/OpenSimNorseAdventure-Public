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

integer textBoxChannel; // text box channel integer
integer textBoxChannelListen; //listen handle
list currentUsers; //list of users currently trapped

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    textBoxChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random dynamic menu channel
    textBoxChannelListen = llListen(textBoxChannel, "", NULL_KEY, "");//sets up dynamic menu listen integer
    llListenControl (textBoxChannelListen, FALSE); //turns off listeners for dynamic menu channel
}//close set up listeners

SendMessage(key detectedUUID)
{   //sends message to the avi who fell into space
    if(!(~llListFindList(currentUsers, (list)detectedUUID)))
    {   //come here if this avi is not already on the users list
        currentUsers += detectedUUID;//add this avi to the current users. 
        string message1 = "By the Valkyrie, you jumped into space! You better hope the gods send them to save you!";
        string message2 = "Where do the Valkyrie carry the chosen slain to?";
        string texBoxMsg = message1 + " " + message2;
        llRegionSayTo(detectedUUID, PUBLIC_CHANNEL, message1); //deliver the messages
        llListenControl (textBoxChannelListen, TRUE); //turn on the listener for the text box
        llTextBox( detectedUUID, texBoxMsg, textBoxChannel);//send text box to user for their answer
        llSetTimerEvent(600); // ten min timer
        osForceAttachToOtherAvatarFromInventory(detectedUUID, "EnergyOrb", ATTACH_CHEST); //force attach fire to the avi
    }  //close if not on the users list
}//close send message

SendDetachMessage(key aviUUID)
{   //sends detach message to avi in question
    string message = "Detach";
    integer comsChannel = -111111;
    llRegionSayTo(aviUUID, comsChannel, message);
}//close send detach message

ProcessResponse(key aviUUID, string message)
{   //processes the response from the avi
    message = llToLower(llStringTrim(message, STRING_TRIM)); //remove extra spaces and convert to lower case
    vector asgardLanding = <654.54443, 579.61902, 6001.68652>;
    vector startPos = <308.24057, 267.57422, 18.08792>;
    vector destination; 
    if (message == "valhalla") 
    {   //come here if the answer given is valhalla
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "You won the gods favour, by Odin be more careful in the future!");
        destination = asgardLanding; //set the destiation to the path in asgard
    }//close correct answer
    else 
    {   //if the answer is incorrect
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Wrong Answer, the gods will not help you and you continue to fall through space, lost to the universe!");
        destination = startPos; //set the destiation to the old village
    }//close incorrect answer given
    osTeleportAgent(aviUUID, destination, ZERO_VECTOR); //teleport the user
    SendDetachMessage(aviUUID); //send message to the orb to detach
    RemoveFromCurrentUsers(aviUUID);//remove this avi from the trapped users
}//close process response

RemoveFromCurrentUsers(key aviUUID)
{   //removes this avi from the list of current users
    integer listPos = llListFindList(currentUsers, aviUUID);
    if (listPos != - 1) currentUsers = llDeleteSubList(currentUsers, listPos, listPos);
    if (llGetListLength(currentUsers) == 0) llResetScript();
}//close remove from current users

default
{
    state_entry()
    {
        osVolumeDetect(TRUE);
        SetUpListeners();
    }

    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0); //get the new users key
            SendMessage(detectedUUID); //send messages to the user who just fell into space!
        }//close if detected type is an avatar
    }//close collissions

    listen(integer channel, string name, key id, string message)
    {
        if (channel == textBoxChannel) 
        {   //if messages is on the correct channel and its from a current user
            if(~llListFindList(currentUsers, (list)id)) ProcessResponse(id, message);
        }//close if listen conditions met
    }//close listen
    
    timer()
    {
        vector startPos = <308.24057, 267.57422, 18.08792>;
        integer index;
        for (index = 0; index < llGetListLength(currentUsers); ++index)
        {   //loops through everyone on the current users list sending them back to the start
            key aviUUID = llList2Key(currentUsers, index);
            osTeleportAgent(aviUUID, startPos, ZERO_VECTOR); //teleports the avi
            SendDetachMessage(aviUUID); //sends message to the orb to detach
            llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "You took too long and perished!");
        }//close loop through current users
        llSetTimerEvent(0);
        llResetScript();
    }//close timer
}