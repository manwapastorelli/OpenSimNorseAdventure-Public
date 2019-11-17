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

//This is a very slightly modiefied version of hte covey rezzer control script, removing more automated outputs due to the design of the sim


/*
Covey Rez Pro System - Control Script  
=====================================
--------------------------------------------------------------------------
Do not adjust settings below this line unless you know what you are doing!
--------------------------------------------------------------------------
*/  
 
//coms system
integer itemsComsChannel = -83654730; 
integer rezBoxComsChannel = -83654729;
integer rezBoxComsChannelListen;
integer rezBoxChannel = -234576914; //stores the rez box to rez box coms
integer rezBoxChannelListen; // used to turn the listener on and off
integer mainMenuChannel; //global integer for menu channel 
integer mainMenuChannelListen;//clobal control integer for turning menu listen on and off
integer dynamicMenuChannel; //global integer for dynamic menu channel
integer dynamicMenuChannelListen;//clobal control integer for turning menu listen on and off
integer textBoxChannel; //global integer for dynamic menu channel
integer textBoxChannelListen;//lobal control integer for turning menu listen on and off
integer apiRegionChannelIn;//global integer for the api channel inbound
integer apiRegionChannelOut;//global integer for the api channel out;
integer apiRegionChannelListen; //global control for the api listener. 
integer allowPosRecording;//true means box talks to position requests, false it does not.

//instuction processing
string confirmationMenuType; //used to tell the method what we are confirming
string rezDerezMode; //string which tells the method to rez or derez specified item
integer chatFeedback = TRUE; //used to decide if feedback is given in local chat
integer displayHoverText = FALSE; // used to decide if hover text information is displayed
integer apiLinkedMessage; //on/off control for the linked message api inbound and outbound
integer apiRegionSay; //on/off status for the listener and output in regionsay
integer recallMenu; // set to true when instruction from menu set, fals when its from the api, if true the menu gets called after
integer relativePos = FALSE; // if true items rez and move relative to the rez box, if false rez in original sim position and rotation
vector currentPos; //stores the current position of the rez box
rotation currentRot; //stores the current rotation of the rez box
integer rezBoxSetNo; //stores the set number for items rezzed by the box, avoids cross talk with multiple rez box's
integer itemsRezzed = FALSE; //True means the box has items rezzed, false means nothing is rezzed from this box
integer rexBoxPhantom; //used to define and control the phantom status
integer rexBoxAlpha; //used to define and control the alpha status
string textBoxMessageType;//used to set the type of message being processed by the text box. 
integer autoPickup = FALSE; // defines if auto pickup is on or off, gets passed to the items script
integer underGroundMovement = FALSE; // defines if the system will try and move items under ground. Enable this only in sims which allow underground movement. 
list itemPositions; //used as a temp store to calc the average angle between the rez box and the items rezzed
integer dialogMenu = TRUE; //use to control if dialogmenus are active
integer timerCount; //used to turn off the relative mode timer
  
//dynamic menu for individual rezzing of items
list dynamicMenuButtonNumbers;//dynamic menu button nynbers generated from the nanes list;
list reservedButtons = ["Back", "MainMenu", "Next"]; // permanant buttons on the dynamic menu
list tempMenuButtons; //used to store temp menu entries.This is the list which gets displayed in the dialog statement.
integer menuLength; //used to store the length of the menu being worked on
integer currentPageNumber; //used to store the current page number
integer numOfPages; //used to store the total number of pages in this menu
integer dynamicButtonsPerPage; //the number of spaces left after the reserved buttons
integer reservedButtonsPerPage; //number of reserved buttoons per page
string pageMessage; //used to set the page message in the dynamic menu
integer inventoryType; //sets the inventory type for use in text box and dynamic menu responses

integer ChkIsVec (string inputString)
{   //returns a true bool if the supplied string can be typecasted to a vector successfully 
    integer isVec;
    vector chkVec = (vector)inputString;
    string startProcess = llStringTrim ((inputString), STRING_TRIM);
    integer startIndex = (llSubStringIndex(startProcess, "<")+1);
    integer endIndex = (llSubStringIndex(startProcess, ">")-1);
    startProcess = llGetSubString(startProcess, startIndex, endIndex); 
    list stringParts = llCSV2List(startProcess); 
    string strX =  llStringTrim( (llList2String(stringParts,0)), STRING_TRIM); 
    string strY =  llStringTrim( (llList2String(stringParts,1)), STRING_TRIM); 
    string strZ =  llStringTrim( (llList2String(stringParts,2)), STRING_TRIM); 
    float fltX = (float) strX;
    float fltY = (float) strY;
    float fltZ = (float) strZ;
    vector reformedVec = <fltX, fltY, fltZ>;
    if (inputString == "") isVec  = FALSE;
    else if ((chkVec - reformedVec) == <0,0,0>) isVec = TRUE;
    else isVec  = FALSE;
    return isVec;
}//close check is vector

integer CheckMoveLimits(vector targetPos)
{// check the ground height where the item is to be rezzed and make sure its not under ground. Then check its not trying to move off sim or above the cieling height for rezzing. 
    integer moveIsValid;
    float GroundHeight = llGround(targetPos-llGetPos() ); //get ground height where item is to be moved to
    vector simSizeVec = osGetRegionSize(); //gets the region size as sa vector
    integer simSize = (integer)simSizeVec.x;    //converts vec to int
    if ((GroundHeight < targetPos.z) &&  (targetPos.z < 10000) && (targetPos.y < simSize) && (targetPos.x < simSize)) moveIsValid = TRUE; // if inside sim limits set move is valid to true
    else moveIsValid = FALSE; //set move is valid to false
    return moveIsValid;
}//close check rez limits

integer contains(string haystack, string needle) 
{   //returns true if a needle is found inside the heystack 
    return ~llSubStringIndex(haystack, needle); //returns integer
}// close contains

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random main menu channel
    mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, "");//sets up main menu listen integer
    rezBoxChannelListen = llListen(rezBoxComsChannel, "", NULL_KEY, "");//sets up coms channel listen integer
    dynamicMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random dynamic menu channel
    dynamicMenuChannelListen = llListen(dynamicMenuChannel, "", NULL_KEY, "");//sets up dynamic menu listen integer
    textBoxChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generates random dynamic menu channel
    textBoxChannelListen = llListen(textBoxChannel, "", NULL_KEY, "");//sets up dynamic menu listen integer
    rezBoxChannelListen = llListen(rezBoxChannel, "", NULL_KEY, "");
    rezBoxComsChannelListen = llListen(rezBoxComsChannel, "", NULL_KEY, "");
    llListenControl (mainMenuChannelListen, TRUE); //turns on listeners for main menu channel
    llListenControl (dynamicMenuChannelListen, FALSE); //turns off listeners for dynamic menu channel
    llListenControl (textBoxChannelListen, FALSE); //turns off listeners for dynamic menu channel
    llListenControl (rezBoxChannelListen, TRUE); // turns on listeners for the rezbox channel 
    llListenControl (rezBoxComsChannelListen, TRUE);
    SetupApiListeners();
}//close set up listeners

SetupApiListeners()
{   //sets up the api listeners
    apiRegionChannelIn = rezBoxSetNo;
    apiRegionChannelOut = rezBoxSetNo *-1;
    apiRegionChannelListen = llListen(apiRegionChannelIn, "", NULL_KEY, "");//sets up coms channel listen integer
    if (apiRegionSay) llListenControl (apiRegionChannelListen, TRUE); // turns on listeners for the rezbox channel 
    else llListenControl (apiRegionChannelListen, FALSE); // turns off listeners for the rezbox channel 
}//close set up api listeners

string GenUpdatePosDataString()
{   //makes the string sent to items for positons
    string data = (string)currentPos + "," +  (string)currentRot + "," + (string)relativePos + "," + (string)autoPickup + "," + (string)underGroundMovement;
    return data; 
}//close gen position data string

MessageItems(string which, string instruction, string data, key UUID)
{   //sends a message to all items or a single item depending on the "which" string
    string toSend = (string)rezBoxSetNo + "," + instruction + ":" + data;
    if (which == "All") llRegionSay(itemsComsChannel, toSend); //send message to all items
    else if (which == "SingleItem") llRegionSayTo(UUID, itemsComsChannel, toSend); //send message to specific item
}//closwe message items

MessageRezBoxs(string instruction, string data)
{   //sends messages to other rez boxs on the sim
    string toSend = instruction + "," + data;
    llRegionSay(rezBoxChannel, toSend);
}//close message rez box's
 
MessageFeedback(string instruction, string data)
{   //sends feedback through the api and local chat if enabled. 
    string toSend = instruction + "," + data;
    if (apiLinkedMessage) llMessageLinked(LINK_ALL_OTHERS, (apiRegionChannelOut), toSend, "" );
    if (apiRegionSay) llRegionSay((apiRegionChannelOut), toSend);
    if (chatFeedback) llOwnerSay(instruction + ": " + data);
} //close send feedback. 

MessageRezScript (string message, string message2)
{   //sends a linked message to the rez script
    integer num = 10000;
    llMessageLinked(LINK_THIS, num, message, message2);
}//close send linked message to rez script

MainDialogMenu()
{ //displays the main menu and turns off unrequired listeners and clears un-needed lists if present.
    list MainMenuList = ["Rez/DeRez", "Finalise", "RezMode", "PosRecMenu", "InfoDisplay", "ApiControls", "ReTexure", "Done"]; //main menu items list
    llListenControl (dynamicMenuChannelListen, FALSE); //turns off listeners for dynamic menu channel
    llListenControl (textBoxChannelListen, FALSE); //turns on listeners for dynamic menu channel
    string pageMessage = "";
    dynamicMenuButtonNumbers = []; //clears the dynamic numbers list
    llDialog(llGetOwner(), "Please Make your selection", MainMenuList , mainMenuChannel);  
}//close display main menu

ApiDialogMenu()
{   //displays the api menu
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "RegionOn = Turn on the API listener and RegionSay messages \n" + 
                    "RegionOff = Turn off the API listener and RegionSay messages \n" + 
                    "LinkedOn = Turns on processing and sending of API Linked Messages \n" +
                    "LinkedOff = Turns off the processing and sending of API linked messages \n" + 
                    "ShowBoxNum = Shows the rez box number in local chat"; 
    string menuMessage = line0 + line1;
    list apiMenuList = ["RegionOn", "RegionOff", "LinkedOn", "LinkedOff", "ShowBoxNum", "MainMenu"];
    llDialog(llGetOwner(), menuMessage, apiMenuList, mainMenuChannel);
}//close display api menu

SingleItemsDialogMenu() 
{ //displays the single items dialog menu
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "RezItemList = choose item to rez using the menu" + " \n" + 
                    "DelItemList = choose item to de-rez from menu" + " \n" + 
                    "RezName = Type in the name of the item to rez" + " \n" +
                    "DelName = Type in the name of the item to de-rez" + " \n" + 
                    "ListItems = See box contents in local chat";
    string menuMessage = line0+line1;
    list SingleItemsMenuList = ["RezItemList", "DelItemList", "RezName", "DelName", "ListItems", "MainMenu"];
    llDialog(llGetOwner(), menuMessage, SingleItemsMenuList , mainMenuChannel);  
}///close single items dialog menu

RezSetsDialogMenu()
{   //displays the rez sets menu to the user
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "RezSetList = choose rez set to rez from menu" + " \n" + 
                    "DelSetList = choose res set to de-rez from menu" + " \n" + 
                    "RezSetName = Type in the name of the rez set to rez" + " \n" +
                    "DelSetName = Type in the name of the rez set to de-rez" + " \n" + 
                    "MakeRezSet = Make a rez set from inventory" + " \n" +
                    "ListSets = See rez sets in local chat";
    string menuMessage = line0+line1;
    list rezSetMenuList = ["RezSetList", "DelSetList", "RezSetName", "DelSetName", "MakeRezSet", "ListSets", "MainMenu"];
    llDialog(llGetOwner(), menuMessage, rezSetMenuList , mainMenuChannel);  
}//close rez sets menu

RezDeRezMenuDialog()
{   //displays the rez/derez menu to the user 
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "RezAll = Rez All Items" + " \n" + 
                    "DeRezAll = De-Rez All Items" +  " \n" + 
                    "RezSets = Rez Sets Menu" + " \n" +
                    "SingleItems = Single Items Menu" + "\n" + 
                    "ForceUpdate = Force items to update their positions" + "\n" + 
                    "SlowRezAll = Rez all items slowly";
    string menuMessage = line0 + line1;
    list rezDerezMenuList = ["RezAll", "DeRezAll", "RezSets", "SingleItems", "ForceUpdate", "SlowRezAll", "MainMenu"];
    llDialog(llGetOwner(), menuMessage, rezDerezMenuList, mainMenuChannel);
}//close rez/derez menu

RezModeDialogMenu() 
{//call res mode menu
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "Absolute = Return items to their original location" + "\n" + 
                    "Relative = Move items in relation to the rez box position" + " \n" +
                    "AutoPickup = Put items into your inventory automatically" + " \n" + 
                    "ManPickup = Pick up items yourself after recording" + " \n" + 
                    "UndrGrndOn = Allow items to be placed under ground" + " \n" + 
                    "UndrGrndOff = Do not allow items to be placed underground" + " \n" + 
                    "TestRecOn = Test recorded status on" + " \n" + 
                    "TestRecOff = Test recorded status off" ;
    string menuMessage = line0 + line1;
    list RezModeList = ["Absolute", "Relative", "AutoPickup", "ManPickup", "UndrGrndOn", "UndrGrndOff", "TestRecOn", "TestRecOff", "MainMenu"]; //Rez mode items list. 
    llDialog (llGetOwner(), menuMessage, RezModeList, mainMenuChannel); 
}//close call rez mode menu

PosRecordDialogMenu()
{//call pos record menu
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "RecOn = Turn on recording" + " \n" + 
                    "RecOff =Turn off recording" + " \n" + 
                    "AllowRePos = Prepares RezBox to change start position" + " \n" +
                    "SetRecPos = Sets the current position as start point" + "\n" +
                    "SetBoxPos = Sets the box to a given position on the sim" + " \n" + 
                    "SetBoxRot = Sets the rotation of the box on the sim" + " \n" +
                    "PrepReRecrd = Prepares itemns so you can record by manually resetting the scripts" + " \n" + 
                    "ReRecAll = Re Record the items rezzed" + " \n" + 
                    "PrepBoxExch = Configures rezzed items to pickup and drop into a fresh rez box";              
    list PositionRecordingMenu = ["RecOn", "RecOff", "AllowRePos", "SetRecPos", "SetBoxPos", "SetBoxRot", "PrepReRecrd", "ReRecAll", "PrepBoxExch", "MainMenu"]; //list of recording menu buttons
    string RePositionAllowed;
    string menuMessage = line0 + line1;
    llDialog (llGetOwner(), menuMessage, PositionRecordingMenu, mainMenuChannel);
}//close call position record menu

InfoDisplayDialogMenu()
{   //displays the info displaymenu
    string line0 = "Please Choose From The Following: \n\n";
    string line1 =  "ChatOn = Turns on feedback in local chat" + " \n" + 
                    "ChatOff = Turns off feed back in local chat" + " \n" + 
                    "TextSetting = Displays Settings in HoverText" + " \n" + 
                    "TextContent = Displays Contents in HoverText" + " \n" + 
                    "TextOff = Turns off hover text information" + "\n" + 
                    "AplhaOn =  Makes the rez box invisible" + " \n" + 
                    "AlphaOff = Makes the rez box visible" + " \n" + 
                    "PhantomOn = Make the rez box phantom" + " \n" + 
                    "PhantomOff = Make the rez box solid";    
    list infoDisplayMenu = ["ChatOn", "ChatOff", "TextSetting", "TextOff", "TextContent", "AplhaOn", "AlphaOff", "PhantomOn", "PhantomOff", "MainMenu"]; //defines the button list
    string menuMessage = line0 + line1;
    llDialog (llGetOwner(), menuMessage, infoDisplayMenu, mainMenuChannel);
}//close display infoDisplayMenu 

ConfirmationDialogueMenu()
{ //displays yes no confirmation dialog menu
    list confirmationMenu = ["Yes", "No"]; //defines the button list
    string dialogMessage; //defines the message string
    if (confirmationMenuType == "DelBoxInventoryObjects") dialogMessage = "Would you like to automatically remove items currently in the rez box?"; 
    else if (confirmationMenuType == "AutoFixBoxRotationForRecording" )  dialogMessage = "Rez box mustbe rotated to <0,0,0> for recroding.  \n Currently it is not. \n\n Would you like the p     position setting automatically for you? \n\n Please note this will also de-rez any rezzed item you have";
    llDialog (llGetOwner(), dialogMessage, confirmationMenu, mainMenuChannel); //sends menu to the user
}//close display confirmation dialog menu

TextBoxMenu (string instuctionType, string message)
{   //displays the text box dialog to the user
    llListenControl (textBoxChannelListen, TRUE);
    textBoxMessageType = instuctionType;
    llTextBox(llGetOwner(), message, textBoxChannel );
}//close text box dialog menu

ProcessItemMessage(key listenRecievedKey, string listenRecievedMessage)
{//break down the message into a list and proccess then send response to item
    list itemsInstructions = llCSV2List(listenRecievedMessage); //turn the recieved message into a list from comma seperated values
    string recievedInstruction = llList2String(itemsInstructions, 0); //define the recieved instruction from list
    if ((recievedInstruction == "OrigRezBoxPositionRequest") && allowPosRecording)
    { // do this if the instruction from the item is an original position request and we have recording turned on.      
        if (llGetRot() != <0.00000, 0.00000, 0.00000, 1.00000>)  
        {   //come here if the roation of the box is not a zero vector
            confirmationMenuType = "AutoFixBoxRotationForRecording"; //set the confirmation type
            ConfirmationDialogueMenu(); //send confirmation to user
        } //close if rotation is wrong
        //if the box is not rotated correctly ask if they would like it autofixing
        else
        {   //come here if the box is rotated corrrectly
            RecordCurrentPosRot(); // set the current pos
            string data = GenUpdatePosDataString();
            MessageItems("SingleItem", "RezBoxData", data, listenRecievedKey);
            //send string RezBoxData , current position rotation and rez box set number back to item as comma seperated values             
        }// close else box is rotated correctly
    }//close if original position request   
    else if (recievedInstruction == "RezedFromBox" )
    {//do this is the instruction says item was just rezzed from a rez box
        integer RecievedBoxNumber = (integer)llList2Integer(itemsInstructions, 1);//record the box number the item says it belongs to
        if (RecievedBoxNumber == rezBoxSetNo) //check the number is the same as this box number
        {//get current position and rotation then send back to item with instuction rez at the start
            RecordCurrentPosRot(); 
            string data = GenUpdatePosDataString();
            MessageItems("SingleItem", "Rez", data, listenRecievedKey);
            // send rez instruction back to the item along with the box number, position and rotation as well as Rez Mode as comma seperated values. 
        }//close box number check
    }//close if rezzed from box instruction
    else if (recievedInstruction == "ItemPosition")
    {   //come here if item is reporting its position for arror positioning
        vector toAdd = llList2Vector (itemsInstructions, 1);
        itemPositions += toAdd;
    }//close if instruction is item positions
}//close process item message

ProcessRezBoxMessage(key id, string listenRecievedMessage)
{//process messages from other rez box's
    list itemsInstructions = llCSV2List(listenRecievedMessage); //turn the recieved message into a list from comma seperated values
    string recievedInstruction = llList2String(itemsInstructions, 0); //define the recieved instruction from list
    string data = llList2String(itemsInstructions, 1);
    if (recievedInstruction == "Recording" && data =="On") 
    {   //come here if another box sends a recording on signal
        if (allowPosRecording)
        {   //if recording is currently on come here
            if (chatFeedback) llOwnerSay("Another rez box you own has turned on recording, disabling recording on this box"); //send upate to user if chatFeedback enabled
            Recording("Off"); //turns off recording in this box
        }//close if recording was enabled
    } //close if instruction is turn off recording
}//close process box message

ProcessMainMenuResponse(key id, string listenRecievedMessage)
{// process menu responses and act accordingly. 
    recallMenu = TRUE;
    //Itens From all or multiple menus
    if (listenRecievedMessage == "MainMenu") MainDialogMenu();
    else if (listenRecievedMessage == "Yes") ProcessYesComfirmation();
    else if (listenRecievedMessage == "No") ProcessNoConfirmation();
    //Main Menu
    else if (listenRecievedMessage == "Rez/DeRez") RezDeRezMenuDialog();
    else if (listenRecievedMessage == "PosRecMenu") PosRecordDialogMenu();
    else if (listenRecievedMessage == "InfoDisplay") InfoDisplayDialogMenu();
    else if (listenRecievedMessage == "Finalise") FinaliseItems();
    else if (listenRecievedMessage == "ApiControls") ApiDialogMenu();
    else if (listenRecievedMessage == "RezMode") RezModeDialogMenu();
    else if (listenRecievedMessage == "ReTexure") ApplyShapeTexture(0); 
    //Rez / DeRez Menu
    else if (listenRecievedMessage == "RezAll") RezItems();
    else if (listenRecievedMessage == "DeRezAll") DeRezItems();
    else if (listenRecievedMessage == "RezSets") RezSetsDialogMenu();
    else if (listenRecievedMessage == "SingleItems") SingleItemsDialogMenu();
    else if (listenRecievedMessage == "ForceUpdate") ForceUpdateItemPositons();
    else if (listenRecievedMessage == "SlowRezAll") SlowRezAll();
    //Positioning Menu
    else if (listenRecievedMessage == "Absolute") PositioningMode("Absolute");
    else if (listenRecievedMessage == "Relative") PositioningMode("Relative");
    else if (listenRecievedMessage == "AutoPickup") ItemPickup("Auto");
    else if (listenRecievedMessage == "ManPickup") ItemPickup("Manual");
    else if (listenRecievedMessage == "UndrGrndOn") UnderGroundMovement ("On");
    else if (listenRecievedMessage == "UndrGrndOff") UnderGroundMovement ("Off");
    else if (listenRecievedMessage == "TestRecOn") TestRecordedItems("On");
    else if (listenRecievedMessage == "TestRecOff") TestRecordedItems("Off"); 
    //Record Mode Menu
    else if (listenRecievedMessage == "RecOn") ChkBoxPosForRecording();
    else if (listenRecievedMessage == "RecOff") Recording("Off");
    else if (listenRecievedMessage == "AllowRePos") AllowBoxReposition();
    else if (listenRecievedMessage == "SetRecPos") RecordCurrentPosRot();
    else if (listenRecievedMessage == "SetBoxPos") SetBoxPosRotFromMenu("Position");
    else if (listenRecievedMessage == "SetBoxRot") SetBoxPosRotFromMenu("Rotation");
    else if (listenRecievedMessage == "ReRecAll") ReRecordAllItems();
    else if (listenRecievedMessage == "PrepReRecrd") PrepReRecord();
    else if (listenRecievedMessage == "PrepBoxExch") PrepItemBoxExchange();
    //Info Display Menu
    else if (listenRecievedMessage == "ChatOn") ChatFeedBack("On");
    else if (listenRecievedMessage == "ChatOff") ChatFeedBack("Off");
    else if (listenRecievedMessage == "TextSetting") HoverTextInfo("Settings");
    else if (listenRecievedMessage == "TextContent") HoverTextInfo("Contents");
    else if (listenRecievedMessage == "TextOff") HoverTextInfo("Off");
    else if (listenRecievedMessage == "AplhaOn") RezBoxAlpha("On");
    else if (listenRecievedMessage == "AlphaOff") RezBoxAlpha("Off");
    else if (listenRecievedMessage == "PhantomOn") RexBoxPhantom("On");
    else if (listenRecievedMessage == "PhantomOff") RexBoxPhantom("Off"); 
    //Api Controls Menu
    else if (listenRecievedMessage == "RegionOn") ApiRegionSay("On");
    else if (listenRecievedMessage == "RegionOff") ApiRegionSay("Off");
    else if (listenRecievedMessage == "LinkedOn") ApiLinkedMessage("On");
    else if (listenRecievedMessage == "LinkedOff") ApiLinkedMessage("Off");
    else if (listenRecievedMessage == "ShowBoxNum") DisplayBoxNumber();
    //Single Items Menu
    else if (listenRecievedMessage == "RezItemList") RemoveRezListItems("RezItems", INVENTORY_OBJECT);
    else if (listenRecievedMessage == "DelItemList") RemoveRezListItems("RemItems", INVENTORY_OBJECT);
    else if (listenRecievedMessage == "RezName") RemoveRezByName("RezItems", INVENTORY_OBJECT);
    else if (listenRecievedMessage == "DelName") RemoveRezByName("RemItems", INVENTORY_OBJECT);
    else if (listenRecievedMessage == "ListItems") RezBoxListToChat(INVENTORY_OBJECT);
    //RezSets Menu
    else if (listenRecievedMessage == "RezSetList") RemoveRezListItems("RezItems", INVENTORY_NOTECARD);
    else if (listenRecievedMessage == "DelSetList") RemoveRezListItems("RemItems", INVENTORY_NOTECARD);
    else if (listenRecievedMessage == "RezSetName") RemoveRezByName("RezItems", INVENTORY_NOTECARD);
    else if (listenRecievedMessage == "DelSetName") RemoveRezByName("RemItems", INVENTORY_NOTECARD);
    else if (listenRecievedMessage == "MakeRezSet") MakeRexSetNane();
    else if (listenRecievedMessage == "ListSets") RezBoxListToChat(INVENTORY_NOTECARD);   
}//close process menu responses

ProcessTextBoxResponse(key id, string message)
{   //processews the response from the text box and actions accordingly
    recallMenu = TRUE;
    if (textBoxMessageType == "RemRezItems")
    {   //come here if the text box message type is Remove or Rez items
        //GenDynamicButtonsNamesList(inventoryType);
        if(llGetInventoryType(message) == inventoryType )
        {   //come her if the name given exists in the rez box
            string itemToAction = message;
            if (inventoryType == INVENTORY_OBJECT)
            {
                RezDeRezIndividualItem(itemToAction);
                itemsRezzed = TRUE;
                if (recallMenu) MainDialogMenu(); 
            }
            else if (inventoryType == INVENTORY_NOTECARD)
            {
                RezDeRezSet(message);
            }    
        }// close if the item exists in the rez box
        else 
        {   //named item doesn't existn send error message and go back to the single items menu
            if (chatFeedback) llOwnerSay("Sorry that name does not exist, please try again");
            if (recallMenu) SingleItemsDialogMenu();
        }// close if item doesn't exist
    }//close if text box message type is rem/rez items
    else if (textBoxMessageType == "NewRezSetName") MakeRezSet(message);
    else if (textBoxMessageType == "BoxPosition" ) RezBoxPos(message);
    else if (textBoxMessageType == "BoxRotation") RezBoxRot(message);     
}//close process text box response

ProcessNoConfirmation()
{   //processes no responses to the confirmation menu
    if (confirmationMenuType == "AutoFixBoxRotationForRecording")
    {   //come here fi the menu was called due to auto fix rotation request
        string message  = "Recording not enabled, pleased manually fix the position and try again";
        list buttons = ["Ok"];
        if (chatFeedback) llOwnerSay (message);
        Recording("Off");
        llDialog (llGetOwner(), message, buttons, mainMenuChannel);//send an ok dialog to provide a warning
    }//close if confirmation type is auto fix recording
    else MainDialogMenu(); //otherwise send the main menu dialog
}//close process no confirmation

ProcessYesComfirmation()
{//pprocess yes confirmation from dialog menu
if (confirmationMenuType == "DelBoxInventoryObjects")DelInventoryObjects();
if (confirmationMenuType == "AutoFixBoxRotationForRecording") 
    {   //come here if confirmation type is fix rotation for recording
        if (itemsRezzed) DeRezItems();
        vector vecRotDeg = llRot2Euler(llGetRot())*RAD_TO_DEG;
        if (chatFeedback) llOwnerSay("Box rotation before fix was: " + (string)vecRotDeg);
        SetBoxRotationForRecording();
        Recording("On");
    } //close if convermation type is auto fix recording
}//close process yes confirmation

ProcessApiMessage(string message)
{   //process the api message and acts on the instruction
    // string arrives in the format Level0Command,Level1Command
    list instructions = llCSV2List(message);
    string instruction = llList2String(instructions,0);
    string data = llList2String(instructions,1);
    recallMenu = FALSE; 
    if (instruction == "RezItems") RezItems();
    else if (instruction == "DeRezItems") DeRezItems();
    else if (instruction == "FinaliseItems") FinaliseItems();
    else if (instruction == "PositioningMode") PositioningMode(data);
    else if (instruction == "Recording")
    {
        if (data == "On") ChkBoxPosForRecording();
        else if (data == "Off") Recording(data);
    }
    else if (instruction == "BoxRePos") AllowBoxReposition();
    else if (instruction == "SetBoxPos") RecordCurrentPosRot();
    else if (instruction == "ReRecordAllItems") ReRecordAllItems();
    else if (instruction == "RezSingleItem")
    {
        rezDerezMode = "RezItems";
        RezDeRezIndividualItem(data);
    }
    else if (instruction == "DeRezIndividualItem")
    {
        rezDerezMode = "RemItems";
        RezDeRezIndividualItem(data);
    }
    else if (instruction == "RezRezSet") 
    {
        rezDerezMode = "RezItems";
        RezDeRezSet(data);
    }
    else if (instruction == "DeRezRezSet")
    {
        rezDerezMode = "RemItems";
        RezDeRezSet(data);
    }
    else if (instruction == "HoverTextInfo") HoverTextInfo(data);
    else if (instruction == "ChatFeedback") ChatFeedBack(data);
    else if (instruction == "ApiRegionSay") ApiRegionSay(data);
    else if (instruction == "ApiLinkedMessage") ApiLinkedMessage(data);
    else if (instruction == "RezBoxRot") RezBoxRot(data);
    else if (instruction == "RezBoxPos") RezBoxPos(data);
    else if (instruction == "DisplayBoxNumber") DisplayBoxNumber();
    else if (instruction == "RexBoxPhantom") RexBoxPhantom(data);
    else if (instruction == "RezBoxAlpha") RezBoxAlpha(data);
    else if (instruction == "AllowBoxReposition") AllowBoxReposition;
    else if (instruction == "ItemPickup") ItemPickup(data);
    else if (instruction == "UnderGroundMovement") UnderGroundMovement (data);
    else if (instruction == "PrepItemBoxExchange") PrepItemBoxExchange();
    else if (instruction == "MakeRezSet") MakeRezSet(data);
    else if (instruction == "ReRecordAllItems") ReRecordAllItems();
    else if (instruction == "PrepReRecord") PrepReRecord();
    else if (instruction == "UnderGroundMovement") UnderGroundMovement(data);
    else if (instruction == "ItemPickup") ItemPickup(data);
    else if (instruction == "MakeRezSet") MakeRezSet(data); 
    else if (instruction == "DialogMenuStatus" ) DialogMenuStatus(data);
    else if (instruction == "ForceUpdateItemPositons") ForceUpdateItemPositons();
}//close process api message
    
ProcessDynamicMenuResponse(key id, string message)
{ // processes responses to the listen event
    if (message == llList2String(reservedButtons, 0))
    {
        -- currentPageNumber; // button in this example is back so subtract 1 from the page number 
        DialogueMenu(dynamicMenuButtonNumbers); //call the menu again
    }
    else if (message == llList2String(reservedButtons, 1)) MainDialogMenu();
    else if (message == llList2String(reservedButtons, 2) )
    {
        ++ currentPageNumber; //button in this example is Next to add 1 to the page number and call the menu again
        DialogueMenu(dynamicMenuButtonNumbers); //call the menu again
    }
    else 
    {   // come here if pressed button is not in the reserved list
        if(~llListFindList(dynamicMenuButtonNumbers, (list)message))
        {   //come her if the button pressed is in the dynamic buttons list
            integer buttonIndex = (integer)message;
            string itemToAction = llGetInventoryName( inventoryType, buttonIndex );//sets the name of the item to rez/derez
            if (inventoryType == INVENTORY_OBJECT)
            {   //if the menu is displaying inventory objects
                RezDeRezIndividualItem(itemToAction);
                itemsRezzed = TRUE;
                if (recallMenu) MainDialogMenu();
            }//close if displaying inventory notecards
            else if (inventoryType == INVENTORY_NOTECARD)
            {   //if the menu is displaying notecards
                RezDeRezSet(itemToAction);
            }//close if inventory is displaying notecards
        }//close if item actually exists. 
        else if (chatFeedback) llOwnerSay ("Debug: Unknown button pressed");  //this shoud never happen!
    }//close else this is a dynamic button response
}// close process messages from the listen event

DialogMenuStatus(string status)
{   //turns the dialog menu on an off
    if (status == "Off") dialogMenu = FALSE;
    else if (status == "On") dialogMenu = TRUE;
    MessageFeedback("DialogMenuStatus", status);
}//close dialog menu status

integer ChkSlowRezCardExists()
{   //returns a true if the card is found
    integer exists;
    if (llGetInventoryType("SlowRes-AutoGen") == INVENTORY_NOTECARD) exists = TRUE;
    else exists = FALSE;
    return exists;
}//close chkj for slow rez card

SlowRezAll()
{   //makes a rez set containing all itmes then uses rez-set to rez them as its much slower
    MakeRezSet("SlowRes-AutoGen"); //makes the set containing all items
    integer slowRezCardExists = FALSE; //sets the integer as false to begin the checking loop
    while (!slowRezCardExists)
    {   //holds the system in the loop untill notecard generation has finished
        slowRezCardExists = ChkSlowRezCardExists(); //call the check on each loop
    }//close the loop
    rezDerezMode = "RezItems"; //sets the mode to rez so items rez when the next method is called
    RezDeRezSet("SlowRes-AutoGen");//calls the rez rezset method
}//close slow rez all. 

RezDeRezSet(string notecardName)
{   //come here to rez or de-rez a notecard list
    if (rezDerezMode == "RezSet") rezDerezMode = "RezItems";
    else if (rezDerezMode == "RemoveSet") rezDerezMode = "RemItems";
    if (llGetInventoryType (notecardName) == INVENTORY_NOTECARD)
    {   //come here if the named notecard exists
        integer notecardLength = osGetNumberOfNotecardLines(notecardName);
        integer lineIndex;
        for (lineIndex = 0; lineIndex < notecardLength; ++ lineIndex)
        {
            string currentLine = llStringTrim(osGetNotecardLine(notecardName, lineIndex), STRING_TRIM);
            string firstChar = llGetSubString(currentLine, 0, 0);
            integer equalsIndex = llSubStringIndex(currentLine, "=");
            string instruction = llToLower (llStringTrim(llGetSubString(currentLine, 0, equalsIndex-1), STRING_TRIM));
            string itemName = llStringTrim(llGetSubString(currentLine, equalsIndex+1, -1), STRING_TRIM);
            if (currentLine != "" && firstChar != "#" && equalsIndex != -1  && instruction == "itemname")
            {   // if the lines not blank, doesn't begin with a #, contains an equals sign and has intstruction itemname do this
                RezDeRezIndividualItem(itemName);
            }
        }//close loop through notecard
    }//close if notecard exists
    else 
    {   //come here if the notecard is not found
        if (chatFeedback) llOwnerSay("Notecard: " + notecardName + "not found, please try again" );
        if (recallMenu) RezSetsDialogMenu();
    }//close if notecard not found
}//close RezDeRezSet

TestRecordedItems(string instruction)
{   //sends test recorded itens in manual pickup mode to test positon
    MessageItems("All", "TestRecordedItems",instruction, "");
    MessageFeedback("TestRecordedItems", instruction);
    if (recallMenu) RezModeDialogMenu();
}//close test recored items positon

ForceUpdateItemPositons()
{   //sends message to items to update their positions if they are out of place
    MessageItems("All", "RezCheck", "autoPickup", "");
    MessageFeedback("ForceUpdateItemPositons", "");
}//close force update item positions

RezDeRezIndividualItem(string name)
{   //rezes an individual item
    if (rezDerezMode == "RezItems")
    {   //come here if the instruction is rez item
        integer typeOfInventory = llGetInventoryType(name);
        if (typeOfInventory == INVENTORY_OBJECT)
        {   //come here if the item exists in the inventory
            llListenControl (rezBoxComsChannel, TRUE); //turns on listeners for coms channel
            string RezInstruction = "RezSingleItem" + "," + (string)rezBoxSetNo;
            MessageRezScript (RezInstruction, name);
            if (chatFeedback) MessageItems("All", "ChatFeeback", "On", "");
            else MessageItems("All", "ChatFeeback", "Off", "");
            MessageFeedback("RezedSingleItem", name);
        }//close if item exists in the inventory
        else 
        {   //come here if the item does not exist in the inventory
            if (chatFeedback) llOwnerSay("Sorry no object with that name exists in the inventory, did you forget to add it to the box?");
        }//close if item doesn't exist in the inventory
    }// close if single items mode is rez 
    else if (rezDerezMode == "RemItems")
    {   //come here if the instrructions is de-rez item
        MessageItems("All", "DeRezSingleItem", name, "");
        MessageFeedback("DeRezedSingleItem", name);
    }// close if single items mode is remove
    if (recallMenu) RezDeRezMenuDialog();
}// close rez individual item

MakeRexSetNane()
{   //sents a text box dialog to the user asking for the rez set name
    string message = "Please enter a name for the Rez Set Notecard";
    string instructionType = "NewRezSetName";
    TextBoxMenu (instructionType, message);
}//close send text box dialog to the user asking for a rez set name.

MakeRezSet(string name)
{   //loops through the inventory objevts and generates a notecard listing all the names
    integer notecardIndex;
    list inventoryObjects = [];
    for (notecardIndex = 0; notecardIndex < llGetInventoryNumber(INVENTORY_OBJECT); notecardIndex++)
    {
        string instruction = "itemname";
        string objectName = llGetInventoryName(INVENTORY_OBJECT, notecardIndex);
        string toAdd = instruction + "=" +objectName;
        inventoryObjects += toAdd;
    }
    if (llGetInventoryType(name) == INVENTORY_NOTECARD) llRemoveInventory(name);
    osMakeNotecard(name, inventoryObjects);
    MessageFeedback("MakeRezSet", name);
    if (recallMenu) RezSetsDialogMenu();
}// close make rez set notecard

UnderGroundMovement (string data)
{   //enables/disables underground movement 
    if (data == "On") underGroundMovement = TRUE;
    else if (data == "Off") underGroundMovement = FALSE;
    MessageItems("All", "UnderGroundMovement", data, "");
    MessageFeedback("UnderGroundMovement", data);
    if (underGroundMovement) SeriousWarning();
    else  
        {
            if (recallMenu) RezModeDialogMenu();
        }
    if (displayHoverText) HoverTextInfo("Settings");
}//close enable or disable under ground movement

SeriousWarning()
{   //gives a serious warning about potential sim destroying movement
    list buttons = ["Ok"];
    string message = "Restoring to underground positions may fail. It may also permanantly corrupt your sim. It is STRONGLY recomended that you attach another link as the root object which is above ground height. If you do not have an OAR to restore this region DO! NOT! restore items to this position! ";
    llOwnerSay (message);
    llDialog (llGetOwner(), message, buttons, mainMenuChannel);
    autoPickup = FALSE;
} //close serious warning

ItemPickup(string data)
{   //set item pickup mode based on data
    if (data == "Auto") autoPickup = TRUE;
    else if (data == "Manual") autoPickup = FALSE;
    if (displayHoverText) HoverTextInfo("Settings");
    //if (chatFeedback) llOwnerSay("ItemPickup: " + data);
    if (recallMenu) RezModeDialogMenu();
    MessageItems("All", "ItemPickup", data, "");
    MessageFeedback("ItemPickup", data);
}//close set pickup mode 

ChatFeedBack(string instruction)
{   //turns the chat feedback on or off based on the instruction
    if (instruction == "On")
    {   //come here if instruction is turn chat on
        chatFeedback = TRUE;
        if (displayHoverText) HoverTextInfo("Settings");       
    }//close chat on
    else if (instruction == "Off")
    {   //come here if instruction ius chat off
        if (displayHoverText) HoverTextInfo("Off");
        chatFeedback = FALSE;        
    }//close chat off
    //if  (chatFeedback) llOwnerSay("ChatFeedBack: " + instruction);
    MessageRezScript ("ChatFeedBack", instruction);
    MessageFeedback("ChatFeedBack", instruction);
    Settings("Save");
}//close chat feedback

HoverTextInfo(string instruction)
{   //sets the hover text info or removes it
    string displayText;
    if  (instruction == "Off") 
    {   //turn thover text off and notify
        displayHoverText = FALSE;
        displayText = "";
    }//close turn off hover text
    else if (instruction == "Settings")
    {
        displayHoverText = TRUE;
        string chatFeedbackMode;
        if (chatFeedback) chatFeedbackMode = "On";
        else chatFeedbackMode = "Off";
        string positionMode;
        if (relativePos) positionMode = "Relative";
        else positionMode = "Absolute";
        string pickupMode;
        if (autoPickup) pickupMode = "Auto";
        else pickupMode = "Manual";
        string underGround;
        if (underGroundMovement) underGround = "On";
        else underGround = "Off";
        string recordingMode;
        if (allowPosRecording) recordingMode = "On";
        else recordingMode = "Off";
        string apiLinkedMode;
        if (apiLinkedMessage) apiLinkedMode = "On";
        else apiLinkedMode = "Off";
        string apiRegionMode;
        if (apiRegionSay) apiRegionMode = "On";
        else apiRegionMode = "Off";        
        string line0 = "Name: " + llGetObjectName() + "\n \n ";
        string line1 = "Positioning Mode: " + positionMode + "\n ";
        string line2 = "Pickup Mode: " + pickupMode + "\n ";
        string line3 = "Under Ground Movement: " + underGround + "\n ";
        string line4 = "Position Recording: " + recordingMode + "\n ";
        string line5 = "Chat Feedback:  " + chatFeedbackMode + "\n ";
        string line6 = "Api LinkedMessages: " +  apiLinkedMode + "\n ";
        string line7 = "Api RegionSay: " + apiRegionMode + "\n\n ";
        displayText = line0 + line1 + line2 + line3 + line4 + line5 + line6 + line7;
    }
    else if (instruction == "Contents")
    {
        displayHoverText = TRUE;
        string line8 = "This box contains: " + "\n "; 
        displayText = line8; //combine the above lines
        list inventoryTypes = [ INVENTORY_ALL, "Inventory Total: ", 
                                INVENTORY_TEXTURE, "Textures: ", 
                                INVENTORY_SOUND, "Sounds: ", 
                                INVENTORY_LANDMARK, "Landmarks: ", 
                                INVENTORY_CLOTHING, "Clothing Items: ",
                                INVENTORY_OBJECT, "Objects: ",
                                INVENTORY_NOTECARD, "Notecards: ", 
                                INVENTORY_SCRIPT, "Scripts: ",
                                INVENTORY_BODYPART, "Body Parts: ", 
                                INVENTORY_ANIMATION, "Animations: ",
                                INVENTORY_GESTURE, "Guestures: "
                               ];
        integer i;
        for (i = 0; i < llGetListLength(inventoryTypes); i = i+2)
        {   //loops through the types string adding found items to the display text
            integer itemTypeCount = llGetInventoryNumber(llList2Integer(inventoryTypes,i));
            if (itemTypeCount > 0)
            {   //if there are items if this kind found, add the information to the display info
                string dataToAdd = llList2String(inventoryTypes, (i+1)) + (string)itemTypeCount + "\n ";
                displayText += dataToAdd;   
            }//close if items of this type found
        }//close loop through types     
    }
    llSetText(displayText, <1,1,0>, 1.0);
    MessageFeedback("HoverTextInfo", instruction);
} //close hover text info

PrepItemBoxExchange()
{   //sends a message to the itesm telling them to prepare for a rez box exchange
    MessageItems("All", "PrepItemBoxExchange", "", ""); 
    MessageFeedback("PrepItemBoxExchange", "");
    if (recallMenu) PosRecordDialogMenu();
}//close prep item for box exchange

RezBoxAlpha(string status)
{   //sets alpha of rez box links/faces if the coulour change will not break anything
    if (status == "On") rexBoxAlpha = TRUE; //sets alpha status on
    else if (status == "Off") rexBoxAlpha = FALSE; //sets alpha status off
    integer numOfPrims = llGetNumberOfPrims();
    integer startIndex;
    if (numOfPrims == 1) startIndex = 0; //single link item
    else startIndex = 1; //multi link item
    integer linkIndex;
    for (linkIndex = startIndex; linkIndex < numOfPrims; ++ linkIndex)
    {   //loops through the linkset setting the alpha on all sides of each link appropriately
        llSetAlpha( (float)(!rexBoxAlpha), ALL_SIDES); //inverses the alpha above to set on the faces
    }//close loop through all links
    MessageFeedback("RezBoxAlpha", status);
    Settings("Save"); //update description
    if (recallMenu) InfoDisplayDialogMenu();
}//close rez box alpha

RexBoxPhantom (string status)
{   //sets linkset phantom based on input integer
    if (status == "On") rexBoxPhantom = TRUE;
    else if (status == "Off") rexBoxPhantom = FALSE;
    llSetLinkPrimitiveParamsFast(LINK_SET, [PRIM_PHANTOM, rexBoxPhantom]);
    MessageFeedback("RexBoxPhantom", status);
    Settings("Save");
    if (recallMenu) InfoDisplayDialogMenu();
}//close rez box phantom

SetBoxPosRotFromMenu(string instruction)
{   //come here if enter a pos / rot for the rez bots is called from the menu
    if (instruction == "Position") TextBoxMenu ("BoxPosition", "Please enter position vector <x,y,z>");
    else if (instruction == "Rotation") TextBoxMenu ("BoxRotation","Please enter rotation vector in degrees <x,y,z>");
}// set box pos/rot from menu

RezBoxRot(string vecDegRot)
{// adjusts the box rotation to the supplied rot assuming its possible
    integer isVec = ChkIsVec (vecDegRot);
    if (isVec)
    {   //come here if a valid vector was supplied
        vector vecDegTarget = (vector)vecDegRot;
        vector vecDegCurRot = llRot2Euler(llGetRot())*RAD_TO_DEG;
        rotation targetRot = llEuler2Rot(vecDegTarget*DEG_TO_RAD);
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_ROTATION, targetRot]); //sets the rotation of our item
        MessageFeedback("RezBoxRot", (string)vecDegRot);
        if (recallMenu) InfoDisplayDialogMenu();
    }//close if a valid vectore was supplied
    else 
    {   //come here if the data supplied is not a valid eulear rotation vector
        if (chatFeedback) llOwnerSay("The supplied rotation not a euler vector. Please fix this and try again. ");
    }//close if not supplied with a valid vector. 
}//close set rez box rotation

RezBoxPos(string vecPos)
{   //moves the rez box to a supplied positon 
    vector currentPos = llGetPos();
    integer isVec = ChkIsVec (vecPos);
    if (isVec) 
    {   //come here if a valid vector was supplied
        vector targetVec = (vector)vecPos;
        integer moveIsPossible = CheckMoveLimits(targetVec);
        if (moveIsPossible)
        {   //come here if the target pos is valid for this sim
            MoveRezBox(targetVec); //perform the move
            MessageFeedback("RezBoxPos", vecPos);
        }//close if target position is valid for this sim
        else 
        {   //come here if the api is attempting to move the box outside the sim limits
            if (chatFeedback) llOwnerSay("The position supplied was a valid vector but it is outside the rez limits for this sim. Please check and try again.");
        }//close if attempting to move the box outside the sim limits
    }//close if valid vector supplied
    else
    {   //come here if the supplied string could not be turned into a vector
        if (chatFeedback) llOwnerSay("The supplied information is not a vector. Please fix this and try again. ");
    }//close if not a vector
    if (recallMenu) InfoDisplayDialogMenu();
}//close rez box position 

MoveRezBox(vector positon)
//Moving using this method allows sim wide movement and exact positioning however it can only move in increments of upto 10m so we work in stages
{//performs the movement of the object to its final position and rotation
if (positon.z < 4096)
    { // if the position is under 4096m high use the low resources method of moving.
        llSetRegionPos(positon);
        if (llGetPos() != positon) llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, positon]); //sets tpositions
    } //close if end pos is under 4096m
else
    {   //come here if the target 4096m or higher in z
        float distanceFromTarget = llVecDist(llGetPos(), positon);
        while (distanceFromTarget >= 10)
        { //keep looping untill we are less than 10m away from target
            llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, positon]);
            distanceFromTarget = llVecDist(llGetPos(), positon);
        }//close while distance from target is over 10m
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, positon]); //set the target one last time to finish the movement
    }//close if the target height is over 4096m
}//close start move

RemoveRezByName(string mode, integer invType)
{//removes items by name from the rezed items
    inventoryType = invType;
    rezDerezMode = mode;
    TextBoxMenu ("RemRezItems", "Please enter the name of the item to rez or remove");
} //close remove by name

RemoveRezListItems(string mode, integer invType)
{//generate and calls the dynamic menu
    inventoryType = invType;
    rezDerezMode = mode;
    llListenControl (dynamicMenuChannelListen, TRUE); //turns on listeners for dynamic menu channel
    GenDynamicButtonsNamesList(inventoryType);
    DialogueMenu(dynamicMenuButtonNumbers);
}//close dynamic menu

RezBoxListToChat(integer invType)
{ // loop through the box contents dumping the output to chat
    inventoryType = invType;
    integer i;
    for (i=0; i < llGetInventoryNumber(inventoryType); ++i)
    {   //loops through all objects in the inventory
        if (chatFeedback) llOwnerSay(llGetInventoryName(inventoryType,i)); //says the current object name in chat if chatFeedback enabled
    }//close loop through inventory objects
    if (recallMenu) 
        {
            if (inventoryType == INVENTORY_NOTECARD) RezSetsDialogMenu(); //send rez sets menu to user again
            else if (inventoryType == INVENTORY_OBJECT) SingleItemsDialogMenu(); //send single items menu to the user again
        }
} // close list bix cintents in chat

DelInventoryObjects()
{//removes all obects from the inventory
    integer z;
    string objectName;
    integer itemsNumber = llGetInventoryNumber(INVENTORY_OBJECT);
    for (z = itemsNumber; z >= 0; --z)
    {   //loops throug all objevts in the inventory in reverse order
        objectName = llGetInventoryName(INVENTORY_OBJECT, z); //gets the name of the current index
        llRemoveInventory(objectName); //deletes the current object
    }//close looop through inventory items
    MessageFeedback("DelInventoryObjects", "");
    if (chatFeedback)llOwnerSay ("Rez box items removed ready to add the re-recorded items");  
}//close remove inventory objects

PrepReRecord()
{   //prepares the rez box and items for re-recording of all items
    ChkBoxPosForRecording();
    RecordCurrentPosRot();
    confirmationMenuType = "DelBoxInventoryObjects"; //sets confirmatio menu type
    MessageItems("All", "PrepReRecord", "TRUE", ""); //sends message to items telling them to prepare to re-record
    MessageFeedback("PrepReRecord", "");
}//close prepare re-recording of items

ReRecordAllItems()
{// sends message tto all items via region say and sends delte itens dialog
    PrepReRecord();
    integer inventoryCount = llGetInventoryNumber(INVENTORY_OBJECT );
    if (inventoryCount > 100)
    {   //come here if there are less than 100 items in the box to re-record
        string message =    "You have more than 100 items in the rez box. Pickup Mode being set to manual. You will need to pick these items up manually.";
        if (chatFeedback) llOwnerSay(message);
        ItemPickup("Manual");
    }//close if there are more than 100 items in the box
    MessageItems("All", "ReRecordAllItems", "TRUE", ""); //sends message to items telling them to re-record
    MessageFeedback("ReRecordAllItems", "TRUE");
    ConfirmationDialogueMenu(); //sends the confirmation dialog to the user
    itemsRezzed = FALSE; //sets items to not rezzed 
}//close Re-Record Items

AllowBoxReposition()
{ // turns on position recording
    MessageFeedback("AllowBoxReposition", "TRUE");
    PositioningMode("Absolute");
    if (recallMenu) PosRecordDialogMenu();
}//close turn on position recording

ApiRegionSay(string instruction)
{   //turns the region api on/off based on the instruction
    if (instruction == "On") apiRegionSay = TRUE;
    else if (instruction == "Off") apiRegionSay = FALSE;
    if (apiRegionSay) llListenControl (apiRegionChannelListen, TRUE); // turns on listeners for the rezbox channel 
    else llListenControl (apiRegionChannelListen, FALSE); // turns off listeners for the rezbox channel 
    MessageFeedback("ApiRegionSay", instruction);
    if(displayHoverText) HoverTextInfo("Settings");
    Settings("Save");
    if (recallMenu) ApiDialogMenu();
}//close turn region api on/off

ApiLinkedMessage (string instruction)
{   //turns the linked message api on/off based on the instruction
    if (instruction == "On") apiLinkedMessage = TRUE;
    else if (instruction == "Off") apiLinkedMessage = FALSE;
    MessageFeedback("ApiLinkedMessage", instruction);
    Settings("Save");
    if(displayHoverText) HoverTextInfo("Settings");
    if (recallMenu) ApiDialogMenu(); 
}//close api linked message on/off

DisplayBoxNumber()
{   //displays the box number in local if chat feed back is on
    MessageFeedback("DisplayBoxNumber", (string)rezBoxSetNo);
    if (recallMenu) MainDialogMenu();
    llRegionSay(rezBoxChannel, "BoxNumber: " + (string)rezBoxSetNo );
}//close display box number in local

RecordCurrentPosRot()
{//gets and stores the position and rotation of the rez box
    currentPos = llGetPos(); //saves the current position
    currentRot = llGetRot(); //saves the current rotation
}//close record position and rotation

RezItems() 
{//send linked message to rezzor script to avoid issues with forced sleep time from rezzing
if (!itemsRezzed)
    {   //come here if items are not rezzed
        integer objectsInBox = llGetInventoryNumber (INVENTORY_OBJECT);
        if (objectsInBox == 0 ) 
        {   // comw here if no objects exist
            if (chatFeedback) llOwnerSay("There is nothing to rez. Did you forget to put your items into the rez box?");
        }   //close if no objects exist
        else
        {   //come here if there are objects to rez
            llListenControl (rezBoxComsChannel, TRUE); //turns on listeners for coms channel so we can hear rezed items
            MessageFeedback("RezItems", "TRUE");
            string RezInstruction = "RezItems" + "," + (string)rezBoxSetNo; //sets the comma seperated values message to be sent to the rez script
            MessageRezScript (RezInstruction, ""); //sends message to rez script
            itemsRezzed = TRUE; // sets the items rezzed tracker to true
            if (relativePos) StartRelativeModeTimer();
            Settings("Save");//update the description incase of region restart 
        }// close if we have objects to rez
    }//close if items not rezzed
else if (itemsRezzed)
    {   //come here if we already have items rezzed
        if (chatFeedback) llOwnerSay( "\n" + "Sorry items are already rezzed, aborting to avoid duplicate prims in the same place. " + "\n" + 
                    "If you have manually removed items or done it individually please press derez and try again");
        if (recallMenu) MainDialogMenu();
    }//close if items already rezed
    if (chatFeedback) MessageItems("All", "ChatFeeback", "On", "");
    else MessageItems("All", "ChatFeeback", "Off", "");
    if (recallMenu) RezDeRezMenuDialog();
}//close rez items

FinaliseItems()
{// do this if finalise button is pressed
    MessageItems("All", "FinaliseItems", "", "");
    MessageFeedback("FinaliseItems", "TRUE");
    itemsRezzed = FALSE;// sets the items rezzed tracker to no items rezzed
    llSetTimerEvent(0); //stop the timer as we no longer need to track the relation between the rez box and the items.
    if (recallMenu) MainDialogMenu();
    Settings("Save");//update the description incase of region restart
}//close finalise button pressed

DeRezItems()
{//do this if the de-rez button is pressed
    MessageItems("All", "DeRezItems", "", "");
    MessageFeedback("DeRezItems", "All");
    itemsRezzed = FALSE;// sets the items rezzed tracker to no items rezzed
    if (!allowPosRecording) llListenControl (rezBoxComsChannel, FALSE); //turns off listeners for coms channel, no need for it with nothing rezzed. and recording being turned off. 
    llSetTimerEvent(0); // turn the timer off if its runing as there are no longer any items to track
    Settings("Save");//update the description incase of region restart
    if (recallMenu) RezDeRezMenuDialog();
}//close de-rez items

PositioningMode(string mode)
{   //sets the positioning mode based on the supplied mode
    if (mode == "Relative") relativePos = TRUE; //turns on relative mode
    else if (mode == "Absolute") relativePos = FALSE; //turns on absolute mode
    Settings("Save");//update the description incase of region restart
    MessageFeedback("PositioningMode", mode);
    if (recallMenu) RezModeDialogMenu() ; //calls the main menu if called from a menu
    if (displayHoverText) HoverTextInfo("Settings");
    if (relativePos) StartRelativeModeTimer();
    else llSetTimerEvent(0);
}//close set position mode

ChkBoxPosForRecording()
{// checks to see if the boxs rotation <0,0,0>, if it is turn on recording, if not send confirmation for auto fix
    if (llGetRot() == <0.00000, 0.00000, 0.00000, 1.00000>)  Recording("On"); //turns recording on if box is correctly rotated
    else 
    {   //come here if the box has been rotated and needs adjusting for recording
        confirmationMenuType = "AutoFixBoxRotationForRecording"; //sets the confirmation dialog type
        ConfirmationDialogueMenu(); //sends confirmation dialog to the user
    }//close ele box position is incorrect for recroding
}// close check box position for recording

SetBoxRotationForRecording()
{//sets the position of the box to <0,0,0> ready for recording
    llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_ROTATION, <0.00000, 0.00000, 0.00000, 1.00000>]); //set the rotation of the box to <0,0,0>
    if (chatFeedback) llOwnerSay("The rotation of this item has been set to <0,0,0>. Please do not adjust the rotation while recording item positions. RezBox Ready To Record Item Positions" );//send message to the owner around box position and recording status
}//close set box rotation for recording

GenTempMenuList(list inputList)
{ // generates the temp menu buttons (the ones for the current page)
    tempMenuButtons = []; //makes sure the list is blank before we start
    integer firstIndex = currentPageNumber*dynamicButtonsPerPage; //uses the page number to work out the start index in the menu buttons list
    integer lastIndex = firstIndex + dynamicButtonsPerPage-1; // calculates the last index in the menu buttons list
    if (lastIndex >= llGetListLength(inputList)) lastIndex = llGetListLength(inputList) -1; //don't add extra blank buttons for no good reason
    integer i; 
    for ( i = firstIndex; i <= lastIndex; ++ i)
    {   // adds each of the index is the range calculated to the temp buttons list
        tempMenuButtons += llList2String(inputList,i); 
    }//close loop through range of indexed buttons
    AddReservedButtonsToTempMenu(); //adds the reserved buttons to the temp buttons list
    GenMenuPageMessage(firstIndex, lastIndex); 
} //close generate temp menu list

GenMenuPageMessage(integer firstIndex, integer lastIndex)
{   //generates the string to display on the menu page
    pageMessage = "You are viewing page " + (string)(currentPageNumber+1) + " of " + (string)(numOfPages) + "\n" ;
    integer i;
    for (i = firstIndex; i <= lastIndex; ++i)
    {   //loops through button items adding them to the page message
        pageMessage += "\n";
        pageMessage += (string)i ;
        pageMessage += "  " ;
        pageMessage += llGetInventoryName( inventoryType, i );  
    }//close loop through button items
}//close generate menu string

AddReservedButtonsToTempMenu()
{ // loops through the reserved buttons and adds them to the temp list
    integer i;
    for (i = 0; i < llGetListLength(reservedButtons); ++i)
    {   //loops through the reserved buttons adding them to the temp list
        tempMenuButtons += llList2String (reservedButtons, i); //adds the current button to the reserved list
    }// close loop through reserved buttons list
}//close add reserved buttons to temp list

DialogueMenu(list inputList)
{ //displays a big list of buttons dynamially over many pages
    numOfPages = CalcPagesInMenu(inputList);
    menuLength = llGetListLength (inputList);
    if ( currentPageNumber >= numOfPages) currentPageNumber = 0; // these two lines make sure the page number never goes out of range;
    else if (currentPageNumber < 0) currentPageNumber = numOfPages-1; //counting starts from 0 so the last page is 1 less than the total number of pages 
    GenTempMenuList(inputList); //gen list and pass the menu to process from   
    llDialog(llGetOwner(), pageMessage, tempMenuButtons, dynamicMenuChannel); //display the current page in the dialog
}// close display dialogue menu
 
GenDynamicButtonsNamesList(integer invType)
{   //loops through the prims contents and adds the name of each OBJECT to the list and then sorts the list
    inventoryType = invType;
    integer i;
    for (i = 0; i < llGetInventoryNumber(inventoryType); ++i)
    {   //gets the name of each object and adds it to the list
        dynamicMenuButtonNumbers += (string)i;
    }
} //close generate dynamic nanes list

integer CalcPagesInMenu(list inputList)
{ // works out the total number of pages needed allowing two buttons for forwards and backwards
    reservedButtonsPerPage = llGetListLength(reservedButtons); // how many button spaces per page we need to reserve
    dynamicButtonsPerPage = 12-reservedButtonsPerPage;  //subtract the reserve from the total availible of 12
    numOfPages = (integer)(llGetListLength(inputList) /dynamicButtonsPerPage); // 2 buttons for next and back with 1p per page and an extra page for any remainders
    if (menuLength%dynamicButtonsPerPage > 0) ++numOfPages; //if there is any remainder after dividing the number of buttons by 10 addd on another page
    return numOfPages; //returns the number of pages
}//close calculate pages in menu

ApplyShapeTexture(float rotationRAD)
{   //sets the shape of the box and textures it rotating the arrow to the specified position
    llSetLinkPrimitiveParamsFast(LINK_THIS, 
            [   
                PRIM_TYPE, PRIM_TYPE_CYLINDER, PRIM_HOLE_DEFAULT, <0.00, 1.0, 0.0>, 0.0, <0.0, 0.0, 0.0>, <1.0, 1.0, 0.0>, <0.0, 0.0, 0.0>,  
                PRIM_TEXTURE, ALL_SIDES, "1a1eef4d-2c98-4947-a9bd-34c6a49650fb", <2,1,0>, <0,0,0>, 0,
                PRIM_COLOR, 2, <0,0,0>, 1
            ]); //sets the shape to cylinder and adds the covey texture to all sides setting the repeat to 2 in x
    string sDynamicID = "";                          // not implemented yet
    string sContentType = "vector";                  // vector = text/lines,etc.  image = texture only
    string sData = "";                               // Storage for our drawing commands
    string sExtraParams = "width:512,height:256";    // optional parameters in the following format: [param]:[value],[param]:[value]
    integer iTimer = 0;                              // timer is not implemented yet, leave @ 0
    integer iAlpha = 100;                            // 0 = 100% Alpha, 255 = 100% Solid
    // draw a rectangle
    sData = osSetPenSize(sData, 3);                   // Set the pen width to 3 pixels
    sData = osSetPenColor(sData, "Black");             // Set the pen color to red
    sData = osMovePen(sData, 0, 0);                 // Upper left corner at <28,78>
    sData = osDrawFilledRectangle(sData, 512, 256);   // 200 pixels by 100 pixels
    // setup text to go in the drawn box
    sData = osMovePen(sData, 50, 5);                 // place pen @ X,Y coordinates 
    sData = osSetFontName(sData, "Arial");            // Set the Fontname to use
    sData = osSetFontSize(sData, 20);                 // Set the Font Size in pixels
    sData = osSetPenColor(sData, "White");           // Set the pen color to Green
    sData = osDrawText(sData, llGetObjectName()); // The text to write
    osSetDynamicTextureDataBlend( sDynamicID, sContentType, sData, sExtraParams, iTimer, iAlpha ); // Now draw it out
    llSetLinkPrimitiveParamsFast(LINK_THIS, [PRIM_TEXTURE, 0, "21f88ff4-8277-4f9d-a5ec-bee61fd08ea8", <-1,1,0>, <0,0,0>, rotationRAD]); //sets the arrow texture
    itemPositions = [];//clear the list to keep memory useage to a min. 
    if (recallMenu) MainDialogMenu();
}//close apply shape texture

Settings(string instruction)
{   //saves or loads the settings based on the instruction
    if (instruction == "Save")
    {   //come here if instruction is Save
        llSetObjectDesc(    (string)rezBoxSetNo + "," + 
                            (string)itemsRezzed + "," + 
                            (string)relativePos + "," + 
                            (string)chatFeedback + "," + 
                            (string)displayHoverText + "," + 
                            (string)apiLinkedMessage + "," + 
                            (string)apiRegionSay + "," + 
                            (string)rexBoxPhantom + "," + 
                            (string)rexBoxAlpha + "," +
                            (string)autoPickup + "," +
                            (string)underGroundMovement + "," +
                            (string)dialogMenu);
                        
    }//close save settins to object description
    else if (instruction == "Load")
    {   //come here if instruction is load
        string desc = llGetObjectDesc();
        list objectDescription = llCSV2List(desc); //retrieves the object descriptions and converts it to a list
        rezBoxSetNo = llList2Integer(objectDescription, 0); //if description exists get the description and turn it back into an integer 
        itemsRezzed = llList2Integer(objectDescription, 1); //retrive and save items rezzd true or false
        relativePos = llList2Integer(objectDescription, 2); // retrive and save relative pos mode 
        chatFeedback = llList2Integer(objectDescription, 3); //retrieve and set chat feedback
        displayHoverText = llList2Integer(objectDescription, 4); //retrieves and sets hover text. Hover text is persistent so no need to re-apply here
        apiLinkedMessage = llList2Integer(objectDescription, 5); //retrieves and sets the api Linked message status
        apiRegionSay = llList2Integer (objectDescription, 6); //retrieves and sets the api regionsay status. 
        rexBoxPhantom = llList2Integer (objectDescription, 7);//retrieves and sets the rez box phantom bool
        rexBoxAlpha = llList2Integer (objectDescription, 8); //retrieves and sets the rez box alpha bool
        autoPickup = llList2Integer (objectDescription, 9); //retrieves and sets the auto pickup variable
        underGroundMovement = llList2Integer (objectDescription, 10); //retrieves and sets the underground movement variable
        dialogMenu = llList2Integer(objectDescription, 11); //retrieves and sets the dialog menu status
        apiRegionChannelIn = rezBoxSetNo; //defines the api inbound channel
        apiRegionChannelOut = rezBoxSetNo *-1; //defines the api outbound channel
        if (itemsRezzed && relativePos) StartRelativeModeTimer(); //if items are rezzed turn turn on trimer to update position 
        else llSetTimerEvent(0);//if nothings rezzed or we are in absolute mode make sure the timers turned off. 
        if (chatFeedback) ChatFeedBack("On"); // turns chat feedback on
        else ChatFeedBack("Off"); // turns chat feedback off        
    }//close load settings
}//close settings, 

StartRelativeModeTimer()
{   //sets the timer count to 0 and starts the timer
    timerCount = 0;
    llSetTimerEvent(0.1);
}//close start relative mode timer

Recording(string instruction)
{   //turns recording on or off based on the instruction
    if (instruction == "On")
    {   //come here if recording instruction is on
        allowPosRecording = TRUE; // if the turn on button is pressed in the Recording menu, set the inter to true (on)
        MessageRezBoxs("Recording", "On"); //sends message to other rez box's on the sim so they turn recording off
        llListenControl (rezBoxChannelListen, TRUE); // turn listening for other rez box on incase recording is enabled on another
        llListenControl (rezBoxComsChannelListen, TRUE);//turns on the coms cahannel listener
    }//close turn recording on
    else if (instruction == "Off")
    {   //come here if instruction is off
        allowPosRecording = FALSE; // if the turn on button is pressed in the Recording menu, set the inter to false (off)
        llListenControl (rezBoxChannelListen, FALSE); //turn off the listener for other rez box's as recording is already now off
    }//close turn recording offf
    //MessageItems("All", "Recording", instruction, ""); //sends message to all items
    MessageFeedback("Recording", instruction); //sends feedback for the instruction
    MessageItems("All","Recording", instruction, "");
    if (displayHoverText) HoverTextInfo("Settings"); //sends hover text update if needed
    if (recallMenu) MainDialogMenu(); //calls the main menu if called from the menu
}//close turn recording on and off

CheckForDesc()
{//checks to see if a rez box set number is stored in the description, if found it restores and saves it. If no description is present, generate a new box number and save. 
    if (llGetObjectDesc() == "")
        {//do this if the description is blank
            rezBoxSetNo = (integer)(llFrand(-1000000000.0) - 1000000000.0); //generate a new random box set number and save
            apiRegionChannelIn = rezBoxSetNo;
            apiRegionChannelOut = rezBoxSetNo * -1;
            Settings("Save"); //store this number in the rez box description for the future.
        }//close if descriptoin is blank    
    else Settings("Load");
}//close check for items and description

CheckForItems()
{//checks to see if there are items in the rez box when its rezzed or the script is started
    integer InventoryObjects = llGetInventoryNumber(INVENTORY_OBJECT);
    if (!InventoryObjects)
    {//do this if no objects found
        SetBoxRotationForRecording(); //sets the rotation to <0,0,0>
        RezModeDialogMenu(); //sends the rez mode menu to the user
        Recording("On"); //turns recording on
    }//close if no items in the invnetory
    else
    {//do this if items are found in the inventory
        Recording("Off"); //turns recording off
        if (chatFeedback) llOwnerSay("Rez Box contains items already, Position recording is disabled. You can turn it back on in the menu."); //advise the owner of status
    }//close if item has objects in when rezzed or script dropped
}//close check for items in rez box when first starting up or being rezzed

CheckForExistingScript()
{   //checks to see if another copy of this script alreayd exists, if it does remove it. 
    string name = llGetScriptName(); // gets the current script name
    integer length = llStringLength(name); // how many charcters are in this script name
    string lastTwoChars = llGetSubString(name, -2 ,-1); // finds the last two characters in the name
    if (lastTwoChars == " 1" ) 
    {   // come here if the name ends with a space then the number 1 (like its been auto adjusted due to a duplicate name already existing)
        string mainScriptName = llGetSubString(name, 0,length-3); //get the script name without the space and 1 at the end
        integer check = llGetInventoryType(mainScriptName); //gets the inventory type of an item with name minus the tail if it exists
        if (check == INVENTORY_SCRIPT) 
        {   //come here if a script matching the name without the tail exists come here
            llRemoveInventory(mainScriptName); //remove the old script
            llOwnerSay("Duplicate script detected and removed");
        }//close if duplicate exists
    }//close if this script name ends in " 1"
    integer numScripts = llGetInventoryNumber(INVENTORY_SCRIPT); //get the number of scripts in the item after the above check
    if ( numScripts > 1)
    {   //come here if there are still multiple scripts in the item
        integer scriptIndex;
        for (scriptIndex = numScripts-1; scriptIndex >=0; --scriptIndex)
        {   //loop through all scripts in this object in reverse order so if removing we don't get adujust index issues 
            string currentScriptName = llGetInventoryName(INVENTORY_SCRIPT, scriptIndex); //gets the name of the current script index
            if (currentScriptName != name)
            {   //come here if we are not checking this script!. (Dont remove this script)
                integer isDuplicate = contains(currentScriptName, name); 
                //returns true if the name of this script is contained inside the name of the script we are checking
                //eg this script is "MainScript" and the script we are checking is "MainScript 1"
                if (isDuplicate) 
                {   //come here if the found script is a duplicate of this script
                    llRemoveInventory(currentScriptName); //remove the duplicate script
                    llOwnerSay("Duplicate script detected and removed");
                }//close if script is a duplicte
            }//close if we are dealing with a script other than this script 
        }//close loop through scripts in the object
    }//close if we still have more than 1 script in the objevt 
}//close check for existing script

default
{    
    changed(integer change)
    {// if the region has restarted set Box number from description
     //if the owner has changed reset the script. 
        if (change & CHANGED_REGION_START | CHANGED_REGION_RESTART) 
        {
            CheckForDesc();//if region has been restarted set the box number from the description
            DeRezItems();
        }
        if (change & CHANGED_OWNER) llResetScript();//if we hace changed owners ensure the script is reset. 
        if (change & CHANGED_INVENTORY)
        {   //come here if display hover text is turned on
            if (displayHoverText) HoverTextInfo("Contents");
        }//close if inventory has changed
    }//close changed event
    
    on_rez (integer rezCount)
    {//check the script is in the root prim, ensure its rotated to 0,0,0 and then act accordingly.
        llResetScript();
    }//close on rez
    
    state_entry()
    {//this is done when the script starts, sets up listeners, records the current position and rotation as well as setting a new set number. 
        CheckForExistingScript();
        CheckForDesc(); // call check rez box's descriptoin for previously saved set number
        SetUpListeners(); //cal set up listeners
        CheckForItems(); //call check for items in the inventory
        RecordCurrentPosRot(); //call record position and rotation
        dynamicMenuButtonNumbers = []; //clears the dynamic numbers list
        currentPageNumber = 0; //sets the page number to 0 when the script is frist run 
        DeRezItems();
    }//close state entry
    
    touch_start(integer dont_care)
    { //detecs touches and checks to see if its the owner, then launches the main menu if it is. 
        if (llDetectedKey(0) == llGetOwner() && dialogMenu) MainDialogMenu();
        //if the rez box is touched, check its the owner and popup the menu, ignore anyone else
    }//close touch start
    
    listen(integer channel, string name, key id, string message)
    {//listens on the set channels, then depending on the heard channel sends the message for processing. 
        if (llGetOwner() == llGetOwnerKey(id) && id != llGetKey())
        {
            if (channel == rezBoxComsChannel) 
                {
                    ProcessItemMessage(id, message);//if messages heard on coms channel call the process items messages
                }
            else if (channel == mainMenuChannel) ProcessMainMenuResponse(id, message); //if coms heard on the menu channel (menu button pressed) pass to process menu response
            else if (channel == rezBoxChannel) 
            {
                ProcessRezBoxMessage(id, message);
            }
            else if (channel == dynamicMenuChannel) ProcessDynamicMenuResponse(id, message);
            else if (channel == textBoxChannel) ProcessTextBoxResponse(id, message);
            else if (channel == apiRegionChannelIn) ProcessApiMessage(message);
        } //close if sending object is owned by the same person
    }//close listen 
    
    link_message(integer sender_num, integer num, string msg, key msg2)
    { // listens for messages from other scripts in this object
        if (num == rezBoxSetNo && apiLinkedMessage)
        {   //only process if the number matches the one above
            ProcessApiMessage(msg);
        }//close if number matches
    }//close linked messages
    
    timer()
    {//check position and rotation of the rezzer box while items are rezzed
        ++timerCount;
        if (!itemsRezzed) llSetTimerEvent(0); //should never happen but if we get here and nothings rezzed stop the timmer.
        if ((llGetPos() != currentPos) || (llGetRot() != currentRot)) //check to see if we have moved or rotated
        {//do this if the rez box has moved
            currentPos = llGetPos(); //saves new position
            currentRot = llGetRot(); //saves new rotation
            string data = GenUpdatePosDataString();
            //string data = (string)currentPos + "," +  (string)currentRot + "," + (string)relativePos + "," + (string)autoPickup;
            timerCount = 0;
            MessageItems("All", "UpdatePosRot", data, "");
        }//close if box has moved
        if (timerCount >= 18000)
        {   //more than 30 mins has elapsed since items were rezzed or items were moved. 
            //Set absolute positioning and send warning if feedback is on
            MessageFeedback("RelativeModeTimeOut", "SetAbsoluteMode");
            PositioningMode("Absolute");
        }//close if timer count is more than 30 mins. 
    }//close timer
    
}//close default state

/*
Covey Rez Pro System - Control Script
=====================================
Full instructions in the accompanying notecard
*//*

