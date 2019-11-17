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


list codeToOpen; //list stores the saved code, index positions relate to dial numbers
integer rotClockwise; //used to decide which way the dials turn when touched
integer codeEntryNum; //used during the entry of a new code

string XDIGITS = "0123456789abcdef"; // could be "0123456789ABCDEF" //used in decimal to hex conversion
integer dispDialPositions;
integer mainMenuChannel; //global integer for menu channel
integer mainMenuChannelListen;//clobal control integer for turning menu listen on and off
integer textBoxChannel; //global integer for menu channel
integer textBoxChannelListen;//clobal control integer for turning menu listen on and off

//current position of the dials. Ranges from 0 to 25 (26 possible possitions)
integer disc0Count; //this is the position of the dial0 (0-25)
integer disc1Count; //this is the position of the dial1 (0-25)
integer disc2Count; //this is the position of the dial2 (0-25)
integer disc3Count; //this is the position of the dial3 (0-25)
integer disc4Count; //this is the position of the dial4 (0-25)

//Link Numbers of the dials
integer disc0LinkNum; //link number of dial 0
integer disc1LinkNum; //link number of dial 0
integer disc2LinkNum; //link number of dial 0
integer disc3LinkNum; //link number of dial 0
integer disc4LinkNum; //link number of dial 0

string hexes(integer bits)
{   //used by method hex (ingeger value)
    string nybbles = "";
    while (bits)
    {
        integer lsn = bits & 0xF; // least significant nybble
        string nybble = llGetSubString(XDIGITS, lsn, lsn);
        nybbles = nybble + nybbles;
        bits = bits >> 4; // discard the least significant bits at right
        bits = bits & 0xfffFFFF; // discard the sign bits at left
    }
    return nybbles;
}//close hexes

string hex(integer value)
{   // takes a given integer value and converts it to a hex string
    if (value < 0)
    {
        return "-0x" + hexes(-value);
    }
    else if (value == 0)
    {
        return "0x0"; // hexes(value) == "" when (value == 0)
    }
    else // if (0 < value)
    {
        return "0x" + hexes(value);
    }
}//close convert integer to hex 

integer random_integer(integer min, integer max)
{   //returns an integure between two supplied ranges
    return min + (integer)(llFrand(max - min + 1));
}//close random integer

integer ChkIsValidInt (string inputString)
{   //takes the given string and makes sure it can be converted into an integer between 0 and 25
    //returns true if its possible and false if its not 
    integer isInt;
    integer chkInt = (integer)inputString;
    string chkStr = (string)chkInt;
    if (inputString == "") isInt = FALSE;
    else if (chkStr == inputString) isInt = TRUE;
    else isInt = FALSE;
    if (isInt)
    {   //if the supplied info is an integer come here
        if (chkInt < 0 || chkInt > 25) isInt  = FALSE;   //if the value falls outside the give range set to false
    }     
    return isInt; //returns the current state of isInt
}//close check is a valid integer

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, "");//sets up main menu listen integer
textBoxChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
textBoxChannelListen = llListen(textBoxChannel, "", NULL_KEY, ""); //sets up text box listen listen integer
llListenControl (mainMenuChannelListen, FALSE); //turns off listeners for main menu channel
llListenControl (textBoxChannelListen, FALSE); //turns off listeners for main menu channel
}//close set up listeners

FindLinkNumbers()
{// loops through all the prims getting their name and assigning link numbers to the named links
    integer linkIndex;
    for(linkIndex = 2; linkIndex <= llGetNumberOfPrims(); linkIndex++)
    { //loops through all links in the linkset starting at 2 to avoid taking in the root prim
    list linkDetails = llGetLinkPrimitiveParams (linkIndex, [PRIM_NAME]); //gets the details of the current link in the loop
    string linkName = llList2String(linkDetails,0); //stores the name of the current link in the loop
    if (linkName == "CodeDisc0") disc0LinkNum = linkIndex; //sets the link number if the name of this link is CodeDisc0
    else if (linkName == "CodeDisc1") disc1LinkNum = linkIndex; //sets the link number if the name of this link is CodeDisc1
    else if (linkName == "CodeDisc2") disc2LinkNum = linkIndex; //sets the link number if the name of this link is CodeDisc2
    else if (linkName == "CodeDisc3") disc3LinkNum = linkIndex; //sets the link number if the name of this link is CodeDisc3
    else if (linkName == "CodeDisc4") disc4LinkNum = linkIndex; //sets the link number if the name of this link is CodeDisc4
    } //close for loop
}//close find link numbers

ChkForSavedCode()
{   //retrieves the descriptio of all dials and converts to integers and saves if all values found are ok. 
    list lstDesDial0 = llGetLinkPrimitiveParams (disc0LinkNum, [ PRIM_DESC ]); //gets dial 0's description
    list lstDesDial1 = llGetLinkPrimitiveParams (disc1LinkNum, [ PRIM_DESC ]); //gets dial 0's description
    list lstDesDial2 = llGetLinkPrimitiveParams (disc2LinkNum, [ PRIM_DESC ]); //gets dial 0's description
    list lstDesDial3 = llGetLinkPrimitiveParams (disc3LinkNum, [ PRIM_DESC ]); //gets dial 0's description
    list lstDesDial4 = llGetLinkPrimitiveParams (disc4LinkNum, [ PRIM_DESC ]); //gets dial 0's description
    string descDial0 = llList2String(lstDesDial0, 0); //makes the string from the retrieved list
    string descDial1 = llList2String(lstDesDial1, 0); //makes the string from the retrieved list
    string descDial2 = llList2String(lstDesDial2, 0); //makes the string from the retrieved list
    string descDial3 = llList2String(lstDesDial3, 0); //makes the string from the retrieved list
    string descDial4 = llList2String(lstDesDial4, 0); //makes the string from the retrieved list
    integer decDial0 = ((integer)descDial0)/10; //converts hex to decimal and divides by 10
    integer decDial1 = ((integer)descDial1)/10; //converts hex to decimal and divides by 10
    integer decDial2 = ((integer)descDial2)/10; //converts hex to decimal and divides by 10
    integer decDial3 = ((integer)descDial3)/10; //converts hex to decimal and divides by 10
    integer decDial4 = ((integer)descDial4)/10; //converts hex to decimal and divides by 10
    codeToOpen = [decDial0, decDial1 ,decDial2, decDial3, decDial4]; //saves the retrieved code to the list
}//close check for a valid code. 

saveCodeToDesc()
{//multiples the intgers of the code by 10 then converts to hex and saves to dial description. 
    integer dial0ToSave = llList2Integer(codeToOpen, 0) *10;
    integer dial1ToSave = llList2Integer(codeToOpen, 1) *10;
    integer dial2ToSave = llList2Integer(codeToOpen, 2) *10;
    integer dial3ToSave = llList2Integer(codeToOpen, 3) *10;
    integer dial4ToSave = llList2Integer(codeToOpen, 4) *10;
    string hexDial0 = hex ( dial0ToSave );
    string hexDial1 = hex ( dial1ToSave );
    string hexDial2 = hex ( dial2ToSave );
    string hexDial3 = hex ( dial3ToSave );
    string hexDial4 = hex ( dial4ToSave );
    llSetLinkPrimitiveParamsFast(disc0LinkNum, [PRIM_DESC, hexDial0]);
    llSetLinkPrimitiveParamsFast(disc1LinkNum, [PRIM_DESC, hexDial1]);
    llSetLinkPrimitiveParamsFast(disc2LinkNum, [PRIM_DESC, hexDial2]);
    llSetLinkPrimitiveParamsFast(disc3LinkNum, [PRIM_DESC, hexDial3]);
    llSetLinkPrimitiveParamsFast(disc4LinkNum, [PRIM_DESC, hexDial4]);
}//close save code to descriptions

SetRandomPositions()
{   //sets each of the dials to a random possition
    disc0Count = random_integer(0, 25); //sets dial 0 to a random number
    disc1Count = random_integer(0, 25); //sets dial 1 to a random number
    disc2Count = random_integer(0, 25); //sets dial 2 to a random number
    disc3Count = random_integer(0, 25); //sets dial 3 to a random number
    disc4Count = random_integer(0, 25); //sets dial 4 to a random number
    MoveCodeDisc(disc0LinkNum); //moves the dial0 to match the number above and adds 1
    MoveCodeDisc(disc1LinkNum); //moves the dial1 to match the number above and adds 1
    MoveCodeDisc(disc2LinkNum); //moves the dial2 to match the number above and adds 1
    MoveCodeDisc(disc3LinkNum); //moves the dial3 to match the number above and adds 1
    MoveCodeDisc(disc4LinkNum); //moves the dial4 to match the number above and adds 1
}//close set random positions

MoveCodeDisc(integer linkNum)
{   //based on the supplied link number adds to that links count and moves the dial to match
    vector increment = <PI/13, 0,0>; //full circle divided by 26 in radians
    integer count;
    if (linkNum == disc0LinkNum) 
    {   //come here if dial 0 was clicked
        if (rotClockwise) ++disc0Count; //adds 1 to the number positon of disc 0
        else -- disc0Count; // subtracts 1 from the position number of disc 0
        if (disc0Count > 25) disc0Count = 0; //if adding 1 goes beyond the highest position set to the start again
        else if (disc0Count < 0 ) disc0Count = 25; //if subtracting goes below the lowest position set to the end
        count = disc0Count; //saves the count for further down
    }//close if dial 0
    else if (linkNum == disc1LinkNum) 
    {   //come here if dial 1 was clicked
        if (rotClockwise) ++disc1Count; //adds 1 to the number positon of disc 0
        else -- disc1Count; // subtracts 1 from the position number of disc 0
        if (disc1Count > 25) disc1Count = 0; //if adding 1 goes beyond the last position set to the start again
        else if (disc1Count < 0 ) disc1Count = 25; //if subtracting goes below the lowest position set to the end
        count = disc1Count; //saves the count for further down
    }//close if dial 1
    else if (linkNum == disc2LinkNum)
    {   //come here if dial 2 was clicked
        if (rotClockwise) ++disc2Count; //adds 1 to the number positon of disc 0
        else -- disc2Count; // subtracts 1 from the position number of disc 0
        if (disc2Count > 25) disc2Count = 0; //if adding 1 goes beyond the last position set to the start again
        else if (disc2Count < 0 ) disc2Count = 25; //if subtracting goes below the lowest position set to the end
        count = disc2Count; //saves the count for further down
    }//close if dial 2
    else if (linkNum == disc3LinkNum) 
    {   //come here if dial 3 was clicked
        if (rotClockwise) ++disc3Count; //adds 1 to the number positon of disc 0
        else -- disc3Count; // subtracts 1 from the position number of disc 0
        if (disc3Count > 25) disc3Count = 0; //if adding 1 goes beyond the last position set to the start again
        else if (disc3Count < 0 ) disc3Count = 25; //if subtracting goes below the lowest position set to the end
        count = disc3Count; //saves the count for further down
    }//close if dial 3
    else if (linkNum == disc4LinkNum)
    {   //come here if dial 4 was clicked
        if (rotClockwise) ++disc4Count; //adds 1 to the number positon of disc 0
        else -- disc4Count; // subtracts 1 from the position number of disc 0
        if (disc4Count > 25) disc4Count = 0; //if adding 1 goes beyond the last position set to the start again
        else if (disc4Count < 0 ) disc4Count = 25; //if subtracting goes below the lowest position set to the end
        count = disc4Count; //saves the count for further down
    }//close if dial 4
    vector vecRotToApply = count * increment; // multiples the count by 1/26 of a full circle in radians
    rotation rotToApply = llEuler2Rot (vecRotToApply); //converts the euler to a rotation
    llSetLinkPrimitiveParamsFast(linkNum, [PRIM_ROT_LOCAL, rotToApply]); //sets the calculated rotation relative to the root prim
    if (dispDialPositions)llOwnerSay("Debug: " + "\n" + 
                "Disc0 Count: " + (string)disc0Count + "\n" + 
                "Disc1 Count: " + (string)disc1Count + "\n" + 
                "Disc2 Count: " + (string)disc2Count + "\n" + 
                "Disc3 Count: " + (string)disc3Count + "\n" + 
                "Disc4 Count: " + (string)disc4Count);
}//close move code disc

CheckValidCode(key aviUUID)
{   // checks the positions of the dials to see if they match the code to open the cryptex
    if (disc0Count == llList2Integer(codeToOpen,0) &&
        disc1Count == llList2Integer(codeToOpen,1) &&
        disc2Count == llList2Integer(codeToOpen,2) &&
        disc3Count == llList2Integer(codeToOpen,3) &&
        disc4Count == llList2Integer(codeToOpen,4) )
    {   //come here if the code is correct
        DeliverPrize(aviUUID);
    }// close correct code supplied
    else 
    {   //come here if the code is incorrect
        string message =    "Sorry you need to have the correct code to open the cryptex" + "\n" +
                            "Click the dials to adjust then try clicking anywhere else again" + "\n" + 
                            "Why not look around see if you can find some clues!"; //message to display on the menu
        list buttons = ["Ok"]; //adds a single ok butto to the meny that does nothing. 
        integer channel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //sets a random negatibe channel to avoid conflicts
        llDialog( aviUUID,  message, buttons, channel); //sends a popup menu to the user telling them the code is wrong
    }//close incorrect code supplied
}//close check if the code is valid

ProcessMenuMessage(key id, string message)
{   //process the menu click and does what is required
    if (message == "RotFwd") 
    {   //come here if the message is rotate forwards
        rotClockwise = TRUE; //swaps the bool used to control disc rotation direction
        llSetObjectDesc ((string)rotClockwise); //saves new value to object description
    }//close if message is roate backwards
    else if (message == "RotBkwd") 
    {   //come here if the message is rotate forwards
        rotClockwise = FALSE; //swaps the bool used to control disc rotation direction
        llSetObjectDesc ((string)rotClockwise);//saves new values to object desc
    }// close if message is rotate backwards
    else if (message == "NewCode") 
    {   //come here if the new code button was pressed
        codeToOpen = []; //clears the current code
        codeEntryNum = 0; //sets the disc number to 0 ready for the next method
        TextBoxDialog(id); //calls the text box
    }//close if new code button was pressed
    else if (message == "ShowCode") ShowCode(); //displays the current code to the owner in local chat
    else if (message == "TestLock") CheckValidCode(llGetOwner());//try to open the lock as the owner
    else if (message == "ShowPosOn") dispDialPositions = TRUE;
    else if (message == "ShowPosOff") dispDialPositions = FALSE;
    else if (message == "Reset") llResetScript(); //resets the script
    llListenControl (mainMenuChannelListen, FALSE); //turns off listeners for main menu channel
    llSetTimerEvent(0); //turns off the timer
}//close process menu message

ProcessTextBoxEntry(key id, string message)
{   //process text box entry
    integer isValidInt = ChkIsValidInt (message); // returns true if the entered value is an integer between 0 and 25
    if (isValidInt)
    {   //come here if a valid integer was provided
         codeToOpen += (integer)message;
         if (codeEntryNum < 4)
         {  //come here if the code entry number is less than
            ++codeEntryNum; //adds one to the code number
            TextBoxDialog(id); //calls the text box again
         }//close if the code entry is less than 4
         else
         {  //come here if we have no more dials to enter a value for
             saveCodeToDesc();
             llListenControl (textBoxChannelListen, FALSE); //turns off listeners for main menu channel
             SetRandomPositions();
             llOwnerSay("New Code: " + llList2CSV(codeToOpen));
             MainMenuDialog(llGetOwner()); //sends the main menu again
             llSetTimerEvent(0); //truns the time off
         } //close if we have no more entries to set a value for
    }//close if we have a valid integer supplied
    else
    {   //come here if the supplied info was not a valid integer
        string boxmessage = "sorry the value you entered was either not a whole number or else it was not between 0 and 25. Please try again";
        llTextBox( id, boxmessage, textBoxChannel);  
    }//close if the entry needs to be tried again
}//close process text box entry

TextBoxDialog(key id)
{   //sends a text box entry to the user asking for the code position for the current disc
    llListenControl (textBoxChannelListen, TRUE); //turns on listeners for main menu channel
    llSetTimerEvent(30);
    string message = "Please enter the position number for dial " + (string)codeEntryNum;
    llTextBox( id, message, textBoxChannel);  
}//close text box entry

MainMenuDialog(key id)
{   //displays the owner menu to the owner
    llListenControl (mainMenuChannelListen, TRUE); //turns on listeners for main menu channel
    list menuButtons = ["RotFwd", "RotBkwd", "NewCode", "ShowCode", "TestLock", "ShowPosOn", "ShowPosOff", "Reset", "Done"];
    string message = "Please pick from the following options.";
    llDialog(id, message, menuButtons, mainMenuChannel);
}//close display owner menu

RetrieveRotDirection()
{   //retrieves the saved dial rotation direction if possible
    string objectDesc = llGetObjectDesc(); //retrieves the object description
    rotClockwise = ((integer)rotClockwise); //sets the bool by converting to int
    if (rotClockwise < 0 || rotClockwise > 1) rotClockwise = FALSE; //makes sure its a valid value, if not sets to false. 
}//close set RotDirection

ShowCode()
{   //displays the current code to the owner in local chat
    llOwnerSay("The current code is: " + llList2CSV(codeToOpen));
}// close show code. 

DeliverPrize(key aviUUID)
{   //checks to make sure the cryptex contains the prize and delivers is present
    string toSay = "The cryptex opens and a key falls out";
    string itemName = "Cryptex Key";
    integer pizeType = llGetInventoryType(itemName);
    if (pizeType == INVENTORY_OBJECT)
    {   //prize foundin inventory, deliver message and prize
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, toSay);
        llGiveInventory(aviUUID, itemName);
        llResetScript();
    }//close prize found
    else 
    {   //the itenm is missing, deliver error message
        string errorMessage =  "The item the cryptex is supposed to deliver to you is missing. You will be unable to continue without this. Please report this to your admin. The owner of this object is: " + llKey2Name(llGetOwner());
        llRegionSayTo(aviUUID, PUBLIC_CHANNEL, errorMessage );
    }//close error message
}//close deliver prize

default
{
    changed(integer change)
    {   //come here if a changed event is triggered
        if (change & CHANGED_OWNER) //note that it's & and not &&... it's bitwise!
        {   //come here if the owner has changed
            llResetScript();
        }//close if the owner has changed
    }//close changed
    
    state_entry()
    {   //come here once when the script first starts or is reset
        FindLinkNumbers(); //finds and saves the link nubers for each of the dials
        SetRandomPositions(); //sets the dial positions to something random
        SetUpListeners(); //sets up the listeners for the menu
        ChkForSavedCode();
        RetrieveRotDirection();
    }//close state entry
    
    touch_start(integer count)
    {   //come her if a user clicks the cryptex
        integer link = llDetectedLinkNumber(0);
        if (link == disc0LinkNum || link == disc1LinkNum || link == disc2LinkNum || link == disc3LinkNum || link == disc4LinkNum)
        {   //come here if one of the dials is clicked
            MoveCodeDisc(llDetectedLinkNumber(0)); //sends the clicked link number to the move code disc method
            //the method will then rotate the clicked dial into place. 
        }//close if one of the dials is clicked
        else 
        {   //come here if any other part of the cryptex is clicked
            if (llDetectedKey(0) == llGetOwner())
            {   //come here if its the owner using the object
                llListenControl (mainMenuChannelListen, TRUE); //turn on the menu listener
                MainMenuDialog(llDetectedKey(0)); //call the menu dialog
                llSetTimerEvent(30);//sets a timer event for 30s
            }//close if the object owner has clicked
            else CheckValidCode(llDetectedKey(0)); //do this if the click is not from the objevt owner
        }//close if anywhere other than the dials is clicked
    }//close touch start
        
    listen( integer channel, string name, key id, string message )
    {   //come here if a message is heard on one of the listening channels
        if (id == llGetOwner())
        { //only come here if the heard message was sent from the owner
            if (channel == mainMenuChannel)
            {   //come here if a message is heard on the main menu channel and its from the object owner
                ProcessMenuMessage(id, message); //sends the uuid of the sender and the message to the process menu method
            }//close if channel is main menu and message is from the owner
            else if (channel == textBoxChannel)
            {   //come here if the channel is text box channel
                ProcessTextBoxEntry(id, message); // sends the uuid of the sender and the message to the proess text box entry method
            }//close if the channel is the text box channel
        }//close if message is from the owners  
    }//close listen
        
    timer()
    {   //come here when the timer event is called
        llOwnerSay("The owners menu has timed out, please click to bring it up again."); //tells the owner the menu has timed out
        llListenControl (mainMenuChannelListen, FALSE); //turns off listeners for main menu channel
        llListenControl (textBoxChannelListen, FALSE); //turns off listeners for the text box channel
        llSetTimerEvent(0); //stops the timer
    }//close timer
}//close default