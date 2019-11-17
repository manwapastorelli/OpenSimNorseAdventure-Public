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

integer mainMenuChannel;
integer mainMenuChannelListen;
list pewLinkNos;//list of link numbers, ChurchPew0 at index0, ChurchPew1 at index1, etc
list pewPosNums;//list of position numbers, indexes match pewLinkNos;
integer comsChannel = -111111;
integer comsChannelListen;

SetupListeners()
{   //sets up the listeners
    mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
    mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (mainMenuChannelListen, FALSE); //turns on listeners for main menu channel
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, FALSE);
}//close setup listeners
 
GetLinkNumbers()
{   //stores all the link pew link numbers in a list
    integer pew0Link; integer pew1Link; integer pew2Link; integer pew3Link;
    integer pew4Link; integer pew5Link; integer pew6Link; integer pew7Link;
    integer pew8Link; integer pew9Link; integer pew10Link; integer pew11Link;
    integer pew12Link; integer pew13Link; integer linkIndex;
    for (linkIndex = 2; linkIndex <= llGetNumberOfPrims(); ++linkIndex)
    {   //loops through the links starting at 2 to avoid the root prim
        string linkName = llGetLinkName(linkIndex);
        if (linkName == "ChurchPew0") pew0Link = linkIndex;
        else if (linkName == "ChurchPew1") pew1Link = linkIndex;
        else if (linkName == "ChurchPew2") pew2Link = linkIndex;
        else if (linkName == "ChurchPew3") pew3Link = linkIndex;
        else if (linkName == "ChurchPew4") pew4Link = linkIndex;
        else if (linkName == "ChurchPew5") pew5Link = linkIndex;
        else if (linkName == "ChurchPew6") pew6Link = linkIndex;
        else if (linkName == "ChurchPew7") pew7Link = linkIndex;
        else if (linkName == "ChurchPew8") pew8Link = linkIndex;
        else if (linkName == "ChurchPew9") pew9Link = linkIndex;
        else if (linkName == "ChurchPew10") pew10Link = linkIndex;
        else if (linkName == "ChurchPew11") pew11Link = linkIndex;
        else if (linkName == "ChurchPew12") pew12Link = linkIndex;
    }//close loop through links
    pewLinkNos =[  
                        pew0Link, pew1Link, pew2Link, pew3Link, pew4Link, 
                        pew5Link, pew6Link, pew7Link, pew8Link, pew9Link, 
                        pew10Link, pew11Link, pew12Link
                ];
}//close get link numbers;

SavePewPosRot(string name)
{   //saves the current local pos rot of each pew to a notecard
    //notecard line numbers relate to pewLinkNos index  
    list posRotToSave = []; //list generated and used to make a notecard
    list linkDetails; //list used to store retrieved details a link
    integer pewIndex;
    for (pewIndex = 0; pewIndex < llGetListLength(pewLinkNos); ++pewIndex)
    {   //loops through all items in the pews list
        integer linkNum = llList2Integer(pewLinkNos, pewIndex); //gets the link number of the pew
        linkDetails = llGetLinkPrimitiveParams(linkNum, [PRIM_POS_LOCAL, PRIM_ROT_LOCAL]);
        vector pewLocalPos = llList2Vector(linkDetails, 0);
        rotation pewLocalRot = llList2Rot(linkDetails, 1);
        string toSave = (string)pewLocalPos + "," + (string)pewLocalRot;
        posRotToSave += toSave;
    }
    if (llGetInventoryType(name) == INVENTORY_NOTECARD) llRemoveInventory(name);
    osMakeNotecard(name, posRotToSave);
}//close save local pos rot to notecard

DisplayMainMenu(key aviUUID)
{   //displays the main menu
    llListenControl (mainMenuChannelListen, TRUE);
    list menuButtons = ["SaveRight", "SaveWrong1", "SaveWrong2", "SetCorrect", "SetWrong1", "SetWrong2", "ReSet" ];
    string menuMessage = "Please choose from the following";
    llSetTimerEvent(30);
    llDialog(aviUUID, menuMessage, menuButtons, mainMenuChannel); 
}//close display main menu

ProcessMainMenu(string message)
{   //process menu clicks
    if (message == "SaveRight") 
    {
        TurnOffMenu();
        SavePewPosRot("Pews0");
    } 
    else if (message == "SaveWrong1") 
    {
        TurnOffMenu();
        SavePewPosRot("Pews1");
    }
    else if (message == "SaveWrong2") 
    {
        TurnOffMenu();
        SavePewPosRot("Pews2");
    }
    else if (message == "SetCorrect") 
    {
        TurnOffMenu();
        SetPewsPositons(0);
    }
    else if (message == "SetWrong1") 
    {
        TurnOffMenu();
        SetPewsPositons(1);
    }
    else if (message == "SetWrong2") 
    {
        TurnOffMenu();
        SetPewsPositons(2);
    }
    else if (message == "ReSet")  llResetScript();
}//close process main menu

SetPewsPositons(integer posCardNum)
{   //sets pews to the positions on the given notecard
    integer pewPosNumsIndex;
    pewPosNums = [];
    for (pewPosNumsIndex = 0; pewPosNumsIndex < llGetListLength(pewLinkNos); ++pewPosNumsIndex)
    {   //sets the integer of all pos numbers to the number of the applied set
        pewPosNums += posCardNum;
    }//close loops through all pews
    integer lineIndex;
    string name = "Pews" + (string)posCardNum;
    for (lineIndex = 0; lineIndex < osGetNumberOfNotecardLines(name); ++lineIndex)
    {   //loops through the notecard 
        integer pewLinkIndex = lineIndex;
        integer pewLinkNum = llList2Integer(pewLinkNos, pewLinkIndex);
        string currentLine = osGetNotecardLine(name, lineIndex);
        if (currentLine != "")
        {   //filter blank lines as OS adds extras at the end when writing
            //auto generated card so no need to filter for more
            list posRot = llCSV2List(currentLine);
            vector posToSet = llList2Vector(posRot, 0);
            rotation rotToSet = llList2Rot(posRot, 1);
            SetPewPosRot(pewLinkNum, posToSet, rotToSet); //actually moves the pew
        }//close if line isnt blank
    }//close loop through notecard
}//close set pews positions

SetPewPosRot(integer pewLinkNum, vector localPos, rotation localRot)
{   //sets the pew local pos and rot from supplied info
    llSetLinkPrimitiveParamsFast(pewLinkNum, [PRIM_POS_LOCAL, localPos, PRIM_ROT_LOCAL, localRot]);
    CheckPewsPositons();//check to see if all are now correct. 
}//close set pew local pos rot


ProcessClicks(integer linkNum, key toucher)
{   //process all clicks on all links
    if (linkNum == LINK_ROOT)
    {   //only deliver root prim click if authorised
        if (toucher == llGetOwner() || toucher == "54150836-5148-4a3a-9c1a-a0cd0ded0da2") DisplayMainMenu(toucher);
    }//close if link is root
    else 
    {   //pew has been clicked
        integer pewLinkIndex = llListFindList( pewLinkNos, linkNum);//find the link index
        MovePew(pewLinkIndex);//move the pew to the next position
    }//close if pew is clicked
}//close process clicks

MovePew(integer pewLinkIndex)
{   //moves the pew to its next position
    integer pewPosNum = llList2Integer(pewPosNums, pewLinkIndex); //fets the position of the pew now
    if (pewPosNum < 2) ++ pewPosNum; //if less than 2 add one ot the position number
    else if (pewPosNum >= 2) pewPosNum = 0; //if it is 2 make the number now 1
    pewPosNums = llListReplaceList(pewPosNums, [pewPosNum], pewLinkIndex,pewLinkIndex); //replace the list position numbers
    integer nCardLineIndex = pewLinkIndex; //line index matches the pew index in the links list
    string nCardBaseName = "Pews"; //this is the name of the notecard without the number
    string nCardNum = (string)pewPosNum;//tail is the card number
    string ncardName = nCardBaseName+nCardNum; //full card name combines the carn number and base name
    string nCardLine = osGetNotecardLine(ncardName, nCardLineIndex); //read the line directly from the notecard
    list localPosRot = llCSV2List(nCardLine);//turn the retieved line into  a list
    vector localPos = llList2Vector(localPosRot, 0);//position is list element 0
    rotation localRot = llList2Rot(localPosRot, 1); //rotatoin is list element 1
    integer pewLinkNum = llList2Integer(pewLinkNos, pewLinkIndex); //retrieve the pew link link number
    SetPewPosRot(pewLinkNum, localPos, localRot); //sets thep position based on the retieved information
}//close move pew

CheckPewsPositons()
{   //loops through the pew links checking their position, if incorrect it breaks the loop
    integer pewPosNumsIndex = 0;
    integer correctCombo = TRUE;//start at true, change to false if any are in the wrong position
    while (correctCombo && pewPosNumsIndex < llGetListLength(pewPosNums))
    {   //loop through the pew links
        if (llList2Integer(pewPosNums, pewPosNumsIndex) != 0) correctCombo = FALSE; //change to false if an incorrect position is found
        ++pewPosNumsIndex;//add one to the index
    }//close loop
    if (correctCombo) SendRezMessage();//if combo is still ok at the end of the loop send rez message to the rezzer
}//close check pew positions. 

SendRezMessage()
{   //message rez box to rez the tardis, adviser user
    integer rezBoxChannel = -111111; //set channel number
    string toSend = "RezItems";//message to send
    llListenControl (comsChannelListen, TRUE);//turn listeners on
    llRegionSay(rezBoxChannel, toSend);//send message to rez box
    llSay(PUBLIC_CHANNEL, "You have solved the pews puzzle. The tardis will now materialise. If for any reason this does not happen please contact an admin as you will be unable to contineue without it. This object is owned by: " + llKey2Name(llGetOwner()));
}//close send rez message

ProcessComsChannel (string message)
{   //if message is reset, reset the script
    if (message == "ResetPews") llResetScript();
}//close process coms channel

TurnOffMenu()
{   //turns the listener and timer off
    llListenControl (mainMenuChannelListen, FALSE);//turn off the listener
    llSetTimerEvent(0); //stop the timer
}//close turn off menu

default
{
    changed (integer change)
    {   //if the sim restarts or the owner changes reset the script
        if (change & (CHANGED_REGION_START | CHANGED_REGION_RESTART | CHANGED_OWNER)) llResetScript();
    }
    
    state_entry()
    {
        SetupListeners(); //setup listeners
        GetLinkNumbers(); //save link numbers by name
        SetPewsPositons(1);//set per positions to position 1;
    }
    
    touch_start(integer dontCare)
    {
        ProcessClicks(llDetectedLinkNumber(0), llDetectedKey(0)); //send clicked link and avi uuid to process clicks method
    }//close touch start
    
    listen(integer channel, string name, key id, string message)
    {   //id checks done when sending dialog menu so don't check twice
        if (channel == mainMenuChannel) ProcessMainMenu(message); //send message to process menu method
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner()) ProcessComsChannel (message); //send message to process coms method
    }//close listen
    
    timer()
    {   //time out, turn of the menu listener, send error message
        llSay(0, "Menu time out, please click again");//send error message
        TurnOffMenu();//turns menu off
    }//close timer
}