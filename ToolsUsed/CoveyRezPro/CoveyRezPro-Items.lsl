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

//Identical script used in both the tardis and the tardis tp ball in conjuction with the tardis rezzor. 

/*
Covey Rez Pro System  - Items Script
====================================   
--------------------------------------------------------------------------
Do not adjust settings below this line unless you know what you are doing!
-------------------------------------------------------------------------- 
*/   
integer simSize; //integer derived from getsimsize vector to store the size of the sim. 
integer recordingAllowed = FALSE; //used to determine if the menu is turned on. If recording is disabled the menu couldn't do anything anyway
integer autoPickup = TRUE; //if this is TRUE and a record position is requested items will attach to the avatar afterwards
integer phantomFixDone = FALSE;
integer underGroundMovement = FALSE; // if set to true, items will attempt to move underground
integer relativePos = TRUE;  // turned on or off. If relative rez mode then this is TRUE. If its absolute this is FALSE
integer phantom = FALSE; // used to store the phantom status of the object when recorded
vector originalPos; //this items original position when recorded
rotation originalRot; //this items original rotation when recorded
vector relativeMove; //displacement vector for this item relative to the rez box
rotation relativeRot; //rotation of this item relative to the rez box
vector origRezBoxPos; //orinal rez box position when item was recorded
rotation origRezBoxRot; //original rez box rotation when item was recorded
vector newRezBoxPos; //new position sent from rez box
rotation newRezBoxRot; //new rot sent from rez box
vector endPos; //end position after movement
rotation endRot; //end rotation after movement
integer rezBoxSetNumber; //rez box set number
integer stopForRezLimit = FALSE;
integer rezBoxComsChannel = -83654729;
integer itemsComsChannel = -83654730;
integer itemsComsChannelListen;

integer mainMenuChannel; //menu channel
integer mainMenuChannelListen; //listener switch for the menu channel
integer seriousWarning = FALSE; //serious warning flag, auto pickup will be disabled if this is set
key rezBoxUUID;

SetUpListeners()
{   //sets up all the listeners 
    mainMenuChannel = (integer)(llFrand(-1000000000.0) - 1000000000.0); 
    mainMenuChannelListen = llListen(mainMenuChannel, "", NULL_KEY, ""); 
    itemsComsChannelListen = llListen(itemsComsChannel, "", NULL_KEY, ""); 
    llListenControl (itemsComsChannelListen, TRUE); 
    llListenControl (mainMenuChannelListen, FALSE); 
}//close setup listeners

ProcessRezBoxMessage(key listenRecievedKey, string listenRecievedMessage)
{   //processes all messages from rez box's
    integer colonSeperator = llSubStringIndex(listenRecievedMessage, ":"); 
    string numberInstruction = llGetSubString(listenRecievedMessage, 0, colonSeperator-1); 
    string data = llGetSubString (listenRecievedMessage, colonSeperator+1, -1 ); 
    list rezBoxInstructions = llCSV2List(numberInstruction); 
    integer recievedRezBoxSetNumber = llList2Integer(rezBoxInstructions, 0);
    string instructionType = llList2String(rezBoxInstructions,1); 
    if (instructionType == "RezBoxData") RezBoxData(data); //no known rez box at this point...
    else if (instructionType == "TestRecordedItems") TestRecorded(data);
    else
    {   //come here for everything except rez box data
        if (recievedRezBoxSetNumber == rezBoxSetNumber)
        {   //come here if the rez box number given matches our rez box
            if (instructionType == "DeRezItems") llDie(); 
            else if (instructionType == "FinaliseItems") FinaliseItems(); 
            else if (instructionType == "Rez") 
                {
                    MoveIntoPositon(data); 
                }
            else if (instructionType == "PrepReRecord") PrepReRecord(); 
            else if (instructionType == "UpdatePosRot") MoveIntoPositon(data); 
            else if (instructionType == "ReRecordAllItems") ReRecordAllItems();
            else if (instructionType == "DeRezSingleItem") DeRezSingleItem(data); 
            else if (instructionType == "Recording") MenuOnOff(data);
            else if (instructionType == "ItemPickup") ItemPickup(data);
            else if (instructionType == "UnderGroundMovement") UnderGroundMovement(data);
            else if (instructionType == "PrepItemBoxExchange") PrepItemBoxExchange();
            else if (instructionType == "ItemPositionRequest") SendPositionToRezBox(listenRecievedKey);
            else if (instructionType == "RezCheck") RezPosCheck();
        }//close if rez box number matches the one provided by the rez box
    }//close if instruction is not rez box data
}//close process rez box message

TestRecorded(string data)
{   //moves itens up 500m if test recorded is On
    //moves them back to the original position if test record is off
    integer extrasCardType = llGetInventoryType(".ExtraInfo");
    if (extrasCardType == INVENTORY_NONE) 
    {   //because we can't check a box number at this stage we filter by the presence of the extras card
        //if not extras card exists this is a fresh set not one rezzed from the box (excluding later prep re-record)
        if (data == "On") 
        {   //turns on testing flag and moves items up 500m
            endPos =  originalPos + <0,0, 500>; //sets the testing possition
            endRot =  originalRot;//sets the rotation
        }//close send testing positions and flag
        else if (data == "Off") 
        {   //sets the testing flag to off and the move position to the original pos
            endPos =  originalPos; //sets the end position to the original position
            endRot =  originalRot;//sets the rotation
        }//close if data is off
        StartMove("Testing"); //moves the items to the set position
    } //close if extras card does not exist
}//close test record 

integer contains(string haystack, string needle) 
{   //returns true if a needle is found inside the heystack 
    return ~llSubStringIndex(haystack, needle); //returns integer
}// close contains
 
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

MenuOnOff(string instruction)
{   //turns the menu on and off based on the instruction
    if (instruction == "On")
    {   //turns the menu on
        recordingAllowed = TRUE;
        llListenControl (mainMenuChannelListen, TRUE); 
    }//close turn on menu
    else if (instruction == "Off")
    {   //turns the menu off
        recordingAllowed = FALSE;
        llListenControl (mainMenuChannelListen, FALSE); 
    }//close turn off menu
}//close menu on and off

SetPosInfo()
{   //sets the original item information ready for saving
    originalPos = llGetPos(); //gets the position
    originalRot = llGetRot(); //gets the rotation
    list objectPhantomDetails = llGetObjectDetails(llGetKey(), [PRIM_PHANTOM]); //checks the itens phantom status
    integer phantom = llGetStatus(STATUS_PHANTOM); //stores the phantom status
    float GroundHeight = llGround(originalPos); //checks the ground height at items positon
    if (originalPos.z < GroundHeight) SeriousWarning(); //sends a warning if item is below ground
    else seriousWarning = FALSE; // ensures warning flag is turned off incase this is a re-record
    llRegionSay(rezBoxComsChannel, "OrigRezBoxPositionRequest" + "," + (string)llGetKey() + "," + (string)llGetOwner()); //messages the rez box
}//close set pos info

SendPositionToRezBox(key rezBoxUUID)
{   //send the current position to the requesting rez box
    string itemPos = (string)llGetPos();
    llRegionSayTo(rezBoxUUID, rezBoxComsChannel, "ItemPosition" + "," + itemPos); 
}//close send position to rez box. 
 
SeriousWarning()
{   //issues a warning in chat and dialog menu and turns off auot pickup
    list buttons = ["Ok"]; // buttons in menu
    string message = "Restoring to this position may fail. It may also permanantly corrupt your sim. It is STRONGLY recomended that you attach another link as the root object which is above ground height. If you do not have an OAR to restore this region DO! NOT! restore items to this position! Auto pickup disabled to give you time to fix this. "; //message to send
    llOwnerSay (message); // warning in local chat
    llDialog (llGetOwner(), message, buttons, mainMenuChannel); //warning dialog menu
    autoPickup = FALSE; //turns off auto pickup
    seriousWarning = TRUE; //sets serious warning flag
} //close serious warning

CheckSettingsCardExists()
{   //checks to see if settings card exists before attaching or telling the user the item is ready to pickup   
    if (seriousWarning) autoPickup = FALSE; //ensures that if serious warning is flagged auto pickup is disabled
    integer check = llGetInventoryType(".SavedSettings"); //gets the inventory type of the settings card
    if (check == INVENTORY_NONE) CheckSettingsCardExists(); //if the item doesn't exist check again
    else 
    {   //come here if the settings card is found
        if (autoPickup) AttachToAvatar();  //if auto pickup is enabled attaches item to the avatar
        else llOwnerSay("All positions and rotations have been saved in a notecard inside the items inventory. Please now take this item to your inventory and then drop it into the Rez Box. "); // if auto pickup is disabled, sends message to user saying item is ready to pickup
    }//close if settings card exists 
}//close check if settings card exists

CheckExtrasCardExists()
{   //checks to see if extras card exists. If it does this is not a first rez from the box
    integer check = llGetInventoryType(".ExtraInfo");
    if (check == INVENTORY_NOTECARD)
    {   //come here if the extras card exists (not first rez from box)
        MenuOnOff("Off"); // turns off the menu
        ReadConfigCards(".ExtraInfo"); //reads the extras card
    }//close if settings card exists
    else 
    {   //this is the first rez from the box, enables the update menu
        MenuOnOff("On"); //turns on the menu
    }//
}//close check if extras card exists

AttachToAvatar()
{   //force attaches item to avatar then calls detach
    osForceAttachToAvatar(ATTACH_CHEST); //force attaches to avatar
    DetachFromAvatar(); //detaches from avatar
}//close attach to avatar

DetachFromAvatar()
{   //detaches the item from the avatar if its attached
    integer attached = llGetAttached(); //gets attacment status
    if (attached) llRequestPermissions(llGetOwner(), PERMISSION_ATTACH ); //if attached calls detach
    else AttachToAvatar(); //if we are not already attached, calls attach again as we should be attached now!
}//close detach fromn avatar

RezBoxData(string data)
{   //process rez box data sent from rez box and stores it   
    list information = llCSV2List (data); 
    origRezBoxPos = llList2Vector(information, 0);
    origRezBoxRot = llList2Rot(information,1);
    relativePos = llList2Integer(information, 2);
    autoPickup = llList2Integer(information, 3);
    underGroundMovement = llList2Integer(information, 4); 
    relativeMove = origRezBoxPos-originalPos; //calculates the relative move
    relativeRot = origRezBoxRot/originalRot; //calcuates the relative rotation
    if (seriousWarning) autoPickup = FALSE; //ensures if underground no auto pickup is allowed
    SaveSettings(); //saves the settings card
}//close rez box data

FinaliseItems()
{   //removes settings and scripts
    PrepReRecord(); //removes settings cards
    llRemoveInventory(llGetScriptName()); //removes the script
}//close finalise items

ReRecordAllItems()
{   //removes the settings cards and resets the script (like dropping a script in a fresh item)
    PrepReRecord(); // removes settings cards
    llResetScript(); //reset the script
}//close re-record items

DeRezSingleItem(string name)
{   // if this object name matches the one sent, remove this object   
    if (name == llGetObjectName() ) llDie(); 
}//close de-rez single item

ItemPickup(string data)
{   //if auto pickup is changed by the box update according in this objevt
    //this will be over written if we are in a serious warning state
    if (data == "Auto") autoPickup = TRUE;
    else if (data == "Manual") autoPickup = FALSE;
}//close item pickup mode

CalcFinalPosRot()
{   //calculates the position to move this iten to
    if (relativePos) 
    {   //come here if relative positioning is enabled
        endPos = newRezBoxPos - relativeMove*newRezBoxRot; 
        endRot = originalRot * newRezBoxRot; 
    }//close if relative positioning
    else
    {   //come here if absolute positioning is enabled
        endPos = originalPos; 
        endRot = originalRot; 
    }//close if absolute positioning
    CheckRezLimits(); //ensure we are allowed to move to the calculated place
}//close check final pos/rot

CheckRezLimits()
{   //checks to make sure that moving to the requested position is possible
    float GroundHeight = llGround(endPos-llGetPos() ); //checks the ground height at the target position
    if (!underGroundMovement)
    {   //come here if underground movement is turned off, do checks including ground position
        if ((GroundHeight < endPos.z) &&  (endPos.z < 10000) && (endPos.y < simSize) && (endPos.x < simSize)) 
        {   // if target position is inside the sim bround, above ground and less than 10km high
            StartMove("Normal"); //starts the movement
        }//close if movement is not trying to go under ground
        else 
        {   //sends warning that includes ground height check
            stopForRezLimit = TRUE;
        }//close if movement would go outside the limits
    }//close if underground movement is off
    else
    {   //underground movement is enabled, do checks without ground position
        if ((endPos.z < 10000) && (endPos.y < simSize) && (endPos.x < simSize)) 
        {   //if the target position is inside the sim broundies and below 10km high 
            StartMove("Normal"); //starts movement
        }//close if inside rez limits
        else  
        {   //send warning but don't mention ground as underground movemnt is on
            stopForRezLimit = TRUE;
        }//close else outside rez limits
    }//close if underground movement is on
}//close check rez limits

StartMove(string moveReason)
{   //moves the object into position
    llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_ROTATION, endRot]); //rotates the object to desired roation
    if (endPos.z < 4096)
    {   //if end position is less than 4096m high use set region position to save sim resources 
        llSetRegionPos(endPos); //moves the item close to final target
        if (llGetPos() != endPos) llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, endPos]); //finishes the movement making it exact
    }//close if final position is under 4096, high 
    else
    {   //final position is above 4096m, set region pos will fail so we must do a loop with set primitive parans fast
        float distanceFromTarget = llVecDist(llGetPos(), endPos); //caclulate how far we are from the end position
        while (distanceFromTarget >= 10)
        {   //if we are more than 10m from the target come here 
            llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, endPos]); //moves the item towards its target by upto 10m
            distanceFromTarget = llVecDist(llGetPos(), endPos); //calculates the distance from target again now. 
        }
        llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, endPos]); // sets the final position as its less than 10m away
    }//close if final position is above 4096m high
    if (seriousWarning) autoPickup = FALSE; //ensures auto pickup is disabled if serious warning is flagged
    if (moveReason != "Testing") 
    {
        SaveExtraInfoCard(); //saves the extra info settings card incase of script resets unless testing mode is on. 
        integer timeSpan = random_integer(10, 30);
        if (!stopForRezLimit) llSetTimerEvent((float)timeSpan);
    }
    
}//close move item into place

integer random_integer(integer min, integer max)
{
    return min + (integer)(llFrand(max - min + 1));
}

SetPhantomStatus()
{   //Works around phantom bug after attachment, forces the phantom status to its opposite setting and back again
    if (!phantom) 
    {   // if the item was originally solid, set it phantom and then back to solid
        llSetStatus (PRIM_PHANTOM, TRUE); //sets status to phantom
        llSetStatus (PRIM_PHANTOM, FALSE); //sets status to solid
        phantomFixDone = TRUE;
        SaveExtraInfoCard();
    }    //close if original status of the item was solid
}//close set phanton status. 

SaveSettings()
{   //saves the settings card
    if (llGetInventoryType(".SavedSettings") == INVENTORY_NOTECARD) llRemoveInventory(".SavedSettings"); //if a card already exists remove it
    list savedSettings = [originalPos, originalRot, origRezBoxPos, origRezBoxRot, relativePos, autoPickup, underGroundMovement, phantom, phantomFixDone]; //makes the list to save
    osMakeNotecard(".SavedSettings", savedSettings); //writes the settings notecard
    CheckSettingsCardExists(); //checks to make sure the card is written
}//close save settings

SaveExtraInfoCard()
{   //saves the extra info card, used to restore the settings if the script is reset
    if (seriousWarning) autoPickup = FALSE; //ensures if we are in a serious warning state that auto pickup is disabled
    list settingsToSave = [rezBoxSetNumber, recordingAllowed, relativePos, autoPickup, underGroundMovement, phantom, phantomFixDone]; //makes list to save
    if (llGetInventoryType(".ExtraInfo") == INVENTORY_NOTECARD) llRemoveInventory(".ExtraInfo"); //if an extra info card already exists remove it
    osMakeNotecard(".ExtraInfo", settingsToSave); //saves the new card
}//close save extra info card

ProcessMenuResponse(key listenRecievedKey, string listenRecievedMessage)
{   // processes response to the menu 
    if (llGetOwnerKey(listenRecievedKey) == llGetOwner()) 
    {   //come here if the user is the owner
        if (listenRecievedMessage == "Update") SetPosInfo();  //updates the position information for this item
    }//close if its the owner trying to use this item
}//close process menu response

SetsimSize()
{   //gets the size of the current region
    vector simSizeVec = osGetRegionSize(); //get sim size vector
    simSize = (integer)simSizeVec.x; // save integer from vector
}//close set sim size

PrepReRecord()
{   //remove the settings cards   
    llRemoveInventory(".ExtraInfo"); 
    llRemoveInventory(".SavedSettings"); 
}//close prep re-record

MoveIntoPositon(string data)
{   //process a move to given position request from the box   
    list information = llCSV2List (data); 
    newRezBoxPos = llList2Vector(information, 0);
    newRezBoxRot = llList2Rot(information, 1);
    relativePos = llList2Integer(information, 2);
    autoPickup = llList2Integer(information, 3);
    underGroundMovement = llList2Integer(information, 4);
    if (seriousWarning) autoPickup = FALSE;
    CalcFinalPosRot(); //calculate the new position based on the supplied information
}//close move into position

PrepItemBoxExchange()
{   //removes the exta info card allowing an item to be moved between rez boxes
    llRemoveInventory(".ExtraInfo");
    llOwnerSay("Is Ready to be picked up and transfered to a new box");
}//close prep item for box exchange

UnderGroundMovement(string data)
{   //turn undergrond movement on or off based on the rez box instruction
    if (data == "On") underGroundMovement = TRUE; //turn on underground movement
    else if (data == "Off")underGroundMovement = FALSE; //turn off underground movement
    if (seriousWarning) autoPickup = FALSE; // if we are in a serious warning state ensure auto pickup is off
    SaveExtraInfoCard();//save the extra info card
}//close underground movement

ReadConfigCards(string notecardName)
{   //reads and processes the settings cards   
    integer notecardNameType = llGetInventoryType(notecardName); //gets the item type for the requested name
    if (notecardNameType == INVENTORY_NOTECARD)
    {   //come here if the requested notecard exists
        integer notecardLength = osGetNumberOfNotecardLines(notecardName); //get the length of the notecard
        list notecardContents = []; //define contents list and ensure its empty.
        integer lineIndex;
        for (lineIndex = 0; lineIndex < notecardLength; ++lineIndex)
        {   //loops through the notecard line by line
            notecardContents += osGetNotecardLine(notecardName, lineIndex); //add each line found to the list
            //don't care about extra lines added at the end by osMakeNotecard as they are ignored later
            //notecards saved by a script, so don't check for user errors
        }//close loop through notecard
        if (notecardName == ".ExtraInfo")
        {   //come here if we are processing the extra info card (scripts have been reset while the iten is rezzed from the box)
            //protection against scripts being disabled at estate level and then re-enabled
            rezBoxSetNumber = llList2Integer(notecardContents,0);
            recordingAllowed = llList2Integer(notecardContents,1);
            relativePos = llList2Integer(notecardContents,2);
            autoPickup = llList2Integer(notecardContents, 3);
            underGroundMovement = llList2Integer(notecardContents, 4);
            phantom = llList2Integer(notecardContents, 5);
            phantomFixDone = llList2Integer(notecardContents, 6);
        }//close process extra info card
        else if (notecardName == ".SavedSettings") 
        {   //come here if we are reading the saved settings card
            //happens when the item is rezzed from the box
            originalPos = llList2Vector(notecardContents, 0); 
            originalRot = llList2Rot(notecardContents, 1); 
            origRezBoxPos = llList2Vector(notecardContents, 2); 
            relativePos = llList2Integer(notecardContents, 3);
            autoPickup = llList2Integer(notecardContents, 4); 
            underGroundMovement = llList2Integer(notecardContents, 5);
            phantom = llList2Integer (notecardContents, 6);
            phantomFixDone = llList2Integer (notecardContents, 7);
        }//close read settings card
        if (seriousWarning) autoPickup = FALSE; //if we are in a serious warning state ensure auto pickup is off
    }//close if the requested notecard exists
    else 
    {   //come here if the requested notecard name is not found
        llOwnerSay ("The notecard called " + notecardName + " is missing, did you remove it?"); //send warning to the user
    }//close if the requested notecard is not found
}//close read settings card

CheckForCopyPremissions()
{   //checks to make sure the item has copy permisiosn for its owner. If not warns and removes the items script
    integer ownerPerms = llGetObjectPermMask( MASK_OWNER );
    integer copyPerms = PERM_COPY;
    if (! (ownerPerms & copyPerms)) 
    {   //come here if we do not have cvopy permissions
        llOwnerSay("You do not have copy permisions on this object. Packing it would likely mean you permanantly loosing it. Recording stoped. Removing this script.");
        llRemoveInventory(llGetScriptName()); //removes the script
    }//close if not copy permissions
}//close check for copy permissiosn

RezPosCheck()
{
    float distanceFromTarget = llVecDist(llGetPos(), endPos); //caclulate how far we are from the end position
    if (distanceFromTarget >= 0.01) CheckRezLimits();
    else 
    {
        llSetTimerEvent(0);
        if (autoPickup && !phantomFixDone) SetPhantomStatus();
    }
}


default
{   //start of the default state when script first starts 
    on_rez (integer boxNoFromRezBox)
    {   //do this if the iten is rezzed
        SetsimSize(); //gets the current sim siz
        rezBoxSetNumber = boxNoFromRezBox; //saves the rez box number we were rezzed from
        if(llGetLinkNumber() > 1) llOwnerSay("Script Only Works In The Root Prim, please place me there");
        if (rezBoxSetNumber == 0) SetPosInfo(); //do this if there is no rez box number 
        else  
        {   //read the settings card and turn the menu off
            rezBoxUUID = osGetRezzingObject();
            ReadConfigCards(".SavedSettings"); //read saved settings card
            MenuOnOff("Off"); //turn the menu off
            llRegionSayTo(rezBoxUUID ,rezBoxComsChannel, "RezedFromBox" + "," + (string)rezBoxSetNumber); 
        }
    }//close on rez
    
    changed(integer change) 
    {   //come here if the link is changed
        if(change & CHANGED_LINK && llGetLinkNumber() > 1) llOwnerSay("This script will only work in the root prim, please place it there");
    }//close changed
     
    state_entry()
    {   //do this once when the script first starts
        CheckForExistingScript(); //checks to see if there is a duplicate to this script and removes if there is
        CheckForCopyPremissions();//checks to make sure the item has copy permissions
        SetUpListeners(); //sets up the listeners
        CheckExtrasCardExists(); //checks for extra info card and restores settings if found
        SetsimSize(); //sets the sim size
        if (rezBoxSetNumber == 0) SetPosInfo(); //if there is no rez box nunber its a fresh drop, set pos info
        else  
        {   //this item has been rezzed from the box,  
            ReadConfigCards(".SavedSettings"); //read the settings card
            MenuOnOff("Off"); //turn the menu off
        }//close if rezzed from box
    }//close state entry
     
    /*
    REMOVED DUE TO BUG IN OS 0.9.0.1!!!!
    ======================================
    touch_start(integer dont_care)
    {   //do this if the iten is clicked
        if (llDetectedKey(0) == llGetOwner() && recordingAllowed) 
        {   //only do this if the itenms owner is clicking
            list mainMenuList = ["Update"]; 
            llDialog(llDetectedKey(0), "Please Make your selection", mainMenuList , mainMenuChannel); 
        }//close if toucher is owner
    }//close touch start
    */
     
    listen(integer channel, string name, key id, string message)
    {   //listens for messages based on the listeners defined
        if (llGetOwnerKey(id) == llGetOwner() && id != llGetKey())
        {   //only process messages if the sending item is owned by the my owner
            
            if (channel == itemsComsChannel) 
            {
                ProcessRezBoxMessage(id, message); //process coms channel messages from rez box
            }
            if (channel == mainMenuChannel) ProcessMenuResponse(id, message); //process menu chanel messages from  my owner
        }//close if user is our owner
    }//close listen
    
    run_time_permissions(integer perm)
    {   //called if permissions are requested 
        if(perm & PERMISSION_ATTACH)
        {   //if attach permision requested
            llDetachFromAvatar( ); //detach from avatar
        }//close if attach permisions requested
    }//close runtime
    
    timer()
    {
        RezPosCheck();
    }
}//close default

/*
Covey Rez Pro System  - Items Script
==================================== 
*/  