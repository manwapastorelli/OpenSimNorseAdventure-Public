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

integer textBoxChannel;
integer textBoxChannelListen;
integer comsChannel = -111111;
list currentUsers;

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    textBoxChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random dynamic menu channel
    textBoxChannelListen = llListen(textBoxChannel, "", NULL_KEY, "");//sets up dynamic menu listen integer
    llListenControl (textBoxChannelListen, FALSE); //turns off listeners for dynamic menu channel
}//close set up listeners

SendMessage(key detectedUUID)
{   //sends message to the avi who fell into the lava
    if(!(~llListFindList(currentUsers, (list)detectedUUID)))
    {   //come here if this user is not on the list of current users
        currentUsers += detectedUUID; //add them to the list
        string message1 = "Welcome Traveler, beware the trickster if you meet him.";
        string message2 = "Pronounce the name of the sacred Tree of life, this will grant you access to this place";
        string texBoxMsg = message1 + " " + message2; //combine messages into one message for the text box
        llRegionSayTo(detectedUUID, PUBLIC_CHANNEL, message1); //deliver the message in chat
        llListenControl (textBoxChannelListen, TRUE);//turn on the text box listener
        llTextBox( detectedUUID, texBoxMsg, textBoxChannel);//deliver the text box for the answer
        llSetTimerEvent(600); // ten min timer
    }//close if not a current user
}//close send message

ProcessResponse(key aviUUID, string message)
{   //processes the response from the avi
    message = llToLower(llStringTrim(message, STRING_TRIM)); //remove extra spaces and convert to lower case
    vector insidePalace = <118.56888, 128.97734, 9201.49316>;
    vector outsidePalace = <128.24402, 128.39577, 9201.49316>;
    vector destination; 
    if (message == "yggdrasil") 
    {   //come here if they give the correct answer
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "You gained entry to the palace, but heed our warning");
        string toSend = "ActivateLoki" + "," + (string)aviUUID; //define message to loki
        llRegionSay(comsChannel, toSend); //message loki to activate him
        destination = insidePalace; //set the destination to inside the palace. 
    }//close if correct answer is given
    else 
    {   //if the wrong answer is given come here
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Laughter can be heard from the inside of the palace. Here is your prize for a wrong answer. A door of ice!");
        destination = outsidePalace; //set the desitination to outside the palace door
    }//close if the wrong answer is given
    osTeleportAgent(aviUUID, destination, ZERO_VECTOR); //teleport the avi to the set destination
    RemoveFromCurrentUsers(aviUUID);//removes this user from the current users list
}//close process response

RemoveFromCurrentUsers(key aviUUID)
{   //removes this avi from the list of current users
    integer listPos = llListFindList(currentUsers, aviUUID); //find their position on the list of users
    if (listPos != - 1) currentUsers = llDeleteSubList(currentUsers, listPos, listPos); //assuming they are on the list remove them
    if (llGetListLength(currentUsers) == 0) llResetScript();//if the list is empty reset the script
}//close remove from current users

default
{
    changed (integer change)
    {
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE); //sets the item to volumetric (like pantom but with collission detection for avis)
        SetUpListeners();//sets up the listeners
    }//close state entry

    collision_start(integer total_number)
    {   //come here when an avi walks into this item
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0); //get the avi uuid
            SendMessage(detectedUUID); //send them a message
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
        vector outsidePalace = <128.24402, 128.39577, 9201.49316>; //sets the destination to outside the palace
        integer index;
        for (index = 0; index < llGetListLength(currentUsers); ++index)
        {   //loops through everyone on the current users list sending them back to the start
            key aviUUID = llList2Key(currentUsers, index);
            osTeleportAgent(aviUUID, outsidePalace, ZERO_VECTOR); //teleports the current avi 
            llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "You took too long and perished!");//sends the current avi a message
        }//close loop through current users
        llSetTimerEvent(0);
        llResetScript();
    }//close timer
}