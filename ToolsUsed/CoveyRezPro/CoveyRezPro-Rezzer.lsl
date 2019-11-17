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

//minor modificatios to the main CoveyRezPro rezzer script to surpress more output to the object owner. 

/*
Covey Rez Pro System - Rezzor Script
====================================
--------------------------------------------------------------------------
Do not adjust settings below this line unless you know what you are doing!
--------------------------------------------------------------------------
*/ 
integer itemsComsChannel = -83654730; 
integer rezBoxSetNo; //sent from main script and recieved by linked messages
string instruction; //instruction recieved via linked messages
integer chatFeedback = TRUE; //used to decide if feedback is given in local chat

integer contains(string haystack, string needle) 
{   //returns true if a needle is found inside the heystack 
    return ~llSubStringIndex(haystack, needle); //returns integer
}// close contains

MessageItems(string which, string instruction, string data, key UUID)
{   //sends a message to all items or a single item depending on the "which" string
    string toSend = (string)rezBoxSetNo + "," + instruction + ":" + data;
    if (which == "All") llRegionSay(itemsComsChannel, toSend); //send message to all items
    else if (which == "SingleItem") llRegionSayTo(UUID, itemsComsChannel, toSend); //send message to specific item
}//closwe message items

RezItems()
{//code to rez the items in the rez box
if (chatFeedback) llOwnerSay("Rezzing has begun, please wait untill it tells you this is complete");
integer rezBoxIndex; //set the counter to 0
integer rezBoxItemCount = llGetInventoryNumber(INVENTORY_OBJECT); //get how many objects are in the rezzor
for (rezBoxIndex = 0; rezBoxIndex < rezBoxItemCount; ++rezBoxIndex)
{
    llRezAtRoot(llGetInventoryName(INVENTORY_OBJECT, rezBoxIndex), llGetPos(), ZERO_VECTOR, llGetRot(), rezBoxSetNo);
    llSleep(0.1);
}
MessageItems("All", "RezCheck", "", "");
llMessageLinked( LINK_SET, -105145667, "ApiRezzingComplete", llGetOwner() );
if (chatFeedback) llOwnerSay("Rezzing Is Complete, item movement may take a few seconds yet");//report rezzing finished
}//close rez items

RezSingleItem(string name)
{   //rez the specified item
    llRezAtRoot(name, llGetPos(), ZERO_VECTOR, llGetRot(), rezBoxSetNo);
} //closw rez single item

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
   state_entry()
   {
       CheckForExistingScript();
   }
   
   link_message(integer Sender, integer Number, string LnkMsg, key name) // This script is in the object too.
    {  //listen for linked messages coming from the control script, break it down into components and save.
        if (Number == 10000);
        {
           list Instructions = llCSV2List(LnkMsg); //make a list from the recieved message which is comma seperated values
           instruction = llList2String(Instructions, 0); //save instruction
           rezBoxSetNo = llList2Integer(Instructions, 1); //save rez box set number
           if (instruction == "RezItems") RezItems(); //check instruction and rez items if told to.  
           if (instruction == "RezSingleItem") 
           {    // convert the key to a string and call rez single item method
                string nameToRez = (string)name;
                RezSingleItem(nameToRez);       
           }//close rez single item
           if (instruction == "ChatFeedBack")
           {    //set the chat feedback to true or false based on the key field
               if (name == "On") chatFeedback = TRUE;
               else if (name == "Off") chatFeedback = FALSE;
           }//close if instruction is chat feeback
        }//close if number is 100000
    }//close linked mesage
}//close default

/*
Covey Rez Pro System
===============
Full instructions in the accompanying notecard
*/