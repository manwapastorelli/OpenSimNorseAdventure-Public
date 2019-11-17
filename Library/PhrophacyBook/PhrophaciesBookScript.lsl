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

integer linkFace0;
integer linkFace1;
integer linkFace2;
integer linkFace3;
integer linkFace4;
integer linkFace5;
integer linkFace6;
integer linkFace7;
integer linkFace8;
integer linkFace9;
integer linkFace10;
list faceLinkList;
integer linkLock;
integer faceRaised = FALSE;
integer textBoxChannel;
integer textBoxChannelListen;
key toucher;

string riddleString = "water"; //riddle answer

string timerReason;


SetupListeners()
{   //sets up the listeners
    textBoxChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //defines a random channel
    textBoxChannelListen = llListen(textBoxChannel, "", NULL_KEY, "");//sets the listen handle
    llListenControl (textBoxChannelListen, FALSE);     //turns the listen handle off
}

GetLinkNumbers()
{   //scrolls thorugh the links assigning them variable names in the global variables above
    integer numOfLinks = llGetNumberOfPrims();
    integer linkIndex;
    for (linkIndex = 2; linkIndex <= numOfLinks ; ++linkIndex)
    {   //loops through all links in the object and assigns link numbers to names
        string linkName = llGetLinkName(linkIndex);
        if (linkName == "Face0") linkFace0 = linkIndex;
        else if (linkName == "Face1") linkFace1 = linkIndex;
        else if (linkName == "Face2") linkFace2 = linkIndex;
        else if (linkName == "Face3") linkFace3 = linkIndex;
        else if (linkName == "Face4") linkFace4 = linkIndex;
        else if (linkName == "Face4") linkFace4 = linkIndex;
        else if (linkName == "Face5") linkFace5 = linkIndex;
        else if (linkName == "Face6") linkFace6 = linkIndex;
        else if (linkName == "Face7") linkFace7 = linkIndex;
        else if (linkName == "Face8") linkFace8 = linkIndex;
        else if (linkName == "Face9") linkFace9 = linkIndex;
        else if (linkName == "Face10") linkFace10 = linkIndex;
        else if (linkName == "Lock") linkLock = linkIndex;
    }  
}

SetActiveFaceUp(integer faceLinkNum)
{   //loopps through the face raising it
    integer faceIndex;
    for (faceIndex = 0; faceIndex < llGetListLength(faceLinkList); ++faceIndex)
    {
        integer currentLinkNum = llList2Integer(faceLinkList, faceIndex);
        if (faceLinkNum == currentLinkNum) llSetLinkAlpha(currentLinkNum, 1.0, ALL_SIDES);
        else llSetLinkAlpha(currentLinkNum, 0.0, ALL_SIDES);
    }
}

SetActiveFaceDown(integer faceLinkNum)
{   //loops through the face links so the face lowers
    integer faceIndex;
    for (faceIndex = llGetListLength(faceLinkList)-1; faceIndex >= 0; --faceIndex)
    {
        integer currentLinkNum = llList2Integer(faceLinkList, faceIndex);
        if (faceLinkNum == currentLinkNum) llSetLinkAlpha(currentLinkNum, 1.0, ALL_SIDES);
        else llSetLinkAlpha(currentLinkNum, 0.0, ALL_SIDES);
    }
}

RaiseFace()
{   //raises the face by changing which link is visible 
    integer faceIndex;
    for (faceIndex = 0; faceIndex < llGetListLength(faceLinkList); ++faceIndex)
    {//loops through all links in the face changing in turn which one is visible. 
        integer activeFace = llList2Integer(faceLinkList, faceIndex);
        SetActiveFaceUp (activeFace);//sends the face to change to the method
        llSleep(0.15);//sleep for a moment
    }
    faceRaised = TRUE;//set raised to true
    llPlaySound("answer the riddle",1);//plays the sound
    llSensorRepeat( "", toucher, AGENT, 5, PI, 2 ); //starts the sensor
}

LowerFace()
{   //lowers the face 
    integer faceIndex;
    for (faceIndex = llGetListLength(faceLinkList)-1; faceIndex >= 0; --faceIndex)
    {   //loops through all the links in the face changing which one is visible
        integer activeFace = llList2Integer(faceLinkList, faceIndex);
        SetActiveFaceDown (activeFace); //sends the face to change to the method
        llSleep(0.15);//sleep for a bit
    }
    faceRaised = FALSE;
}

ProcessTextBoxMessage(string message)
{
    string cleanMessage =  llStringTrim( llToLower(message), STRING_TRIM ) ;
    if (cleanMessage == riddleString) DeliverInfo();
    else SendAway();
}

DeliverInfo()
{   //delivers info after an avi gets the riddle correct
    llPlaySound("you get to live this time",1); //plays the sound
    StopParticles();//stops the particles
    string itemName = "Story Book: COLBY";//defines the name of the item to give
    integer invPresent = llGetInventoryType("Story Book: COLBY");//checks if the book is in the inventory
    if (invPresent) llGiveInventory(toucher, itemName);//if present deliver the book
    else llRegionSayTo(toucher, PUBLIC_CHANNEL, "I am sorry the item: " + itemName +  " your supposed to recieve is missing. Please contact admin. This item is owned by: " + llKey2Name(llGetOwner()));//error message to user if not found
    ReplaceCase();//replace the case. 
}

ReplaceCase()
{   //replaces the case
    integer rezzerChannel = -1673985489;
    llRegionSay(rezzerChannel, "RezItems");//sends a message to the rezzer
}

SendAway()
{   //force sits the avi onto the teleport ball, delivering a message and playing a sound. 
    llPlaySound("Wrong Answer",1);//plays the sound file
    llRegionSayTo(toucher, 0, "wrong answer, now you are mine!");//message to the avi in private
    integer comsChannel = -111111;
    string toSend = "ForceSit" + "," + (string)toucher;//message to send to the tp ball
    llRegionSay(comsChannel, toSend);//sends the message using regionSay
    llSleep(3);//sleeps the script for 3s
    StopParticles();//stops the particles
    ReplaceCase();//replaces the case
}

StopParticles()
{   //stops the particle beam
    llParticleSystem([]);
}

StartParticles()
{   //starts a beam of particles from the book to the avi
    llParticleSystem(
        [
            PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_EXPLODE,
            PSYS_SRC_BURST_RADIUS,0,
            PSYS_SRC_ANGLE_BEGIN,0,
            PSYS_SRC_ANGLE_END,0,
            PSYS_SRC_TARGET_KEY,toucher,
            PSYS_PART_START_COLOR,<0.500000,0.000000,0.000000>,
            PSYS_PART_END_COLOR,<1.000000,1.000000,1.000000>,
            PSYS_PART_START_ALPHA,0.5,
            PSYS_PART_END_ALPHA,1,
            PSYS_PART_START_GLOW,0,
            PSYS_PART_END_GLOW,0.1,
            PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
            PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
            PSYS_PART_START_SCALE,<0.200000,0.200000,0.000000>,
            PSYS_PART_END_SCALE,<1.000000,1.000000,0.000000>,
            PSYS_SRC_TEXTURE,"",
            PSYS_SRC_MAX_AGE,0,
            PSYS_PART_MAX_AGE,5,
            PSYS_SRC_BURST_RATE,0.2,
            PSYS_SRC_BURST_PART_COUNT,5,
            PSYS_SRC_ACCEL,<0.000000,0.000000,0.000000>,
            PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
            PSYS_SRC_BURST_SPEED_MIN,0.5,
            PSYS_SRC_BURST_SPEED_MAX,0.5,
            PSYS_PART_FLAGS,
                0 |
                PSYS_PART_INTERP_SCALE_MASK |
                PSYS_PART_TARGET_LINEAR_MASK
    ]);
}//close start particles


default
{
    changed (integer change)
    {   //reset the script if the region restarts of the owner changes
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {   
        GetLinkNumbers(); //give link numbers variable names
        SetupListeners();//setup the listeners
        faceLinkList = [linkFace0, linkFace1, linkFace2, linkFace3, linkFace4, linkFace5, linkFace6, linkFace7, linkFace8, linkFace9, linkFace10];//define a list of linkNumbe variables
        LowerFace();//make sure the face is lowered at the start
    }
    
    touch_start(integer dontCare)
    {   //come here when the book is touched
        toucher = llDetectedKey(0);
        if (!faceRaised) 
        {   //if the face is not already raised raise it. 
            RaiseFace();//call the raise face method
            llSay(PUBLIC_CHANNEL, "To read the prophecy, you must enter the answer to my riddle. Place your hands on me for two seconds and make sure you give me the right answer. (left click and hold for two seconds)");    //deliver a message
        }
        llSetTimerEvent(2);  //set a timer event with a 2s interval
    }
    
    touch_end(integer dontCare)
    {  
        llSetTimerEvent(0); //do this as the touch ends (click released)
    }
    
    listen (integer channel, string name, key id, string messsage)
    {   //if the message comes in on the text box channel process it. 
        if (channel == textBoxChannel && llGetOwnerKey(id) == toucher) ProcessTextBoxMessage(messsage);
    }
    
    no_sensor() 
    {
        LowerFace();//lowers the face
        ReplaceCase();//replaces the case
        llResetScript();//resets the script
    }
    
    timer()
    {
        llRegionSayTo(toucher, 0, "eddying stream and broad geysir and land of the fish"); //deliver the riddle privately
        llListenControl (textBoxChannelListen, TRUE);  //turn on listeners
        string message = "Please enter the anser to the riddle exactly as you found it elsewhere.";//message to deliver
        llTextBox( toucher, message, textBoxChannel);//sends a text box to this avi
        StartParticles();//starts a particle beam from the book to the avi
        llSetTimerEvent(0);//stop the timer event. 
    }
}