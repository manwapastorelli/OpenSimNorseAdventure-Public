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

list currentAvis;
list detectedAvis;
integer rezzerChannel = -111111;
integer inUse = FALSE;

ProcessNewArrival(key aviUUID)
{   //process new avi with provided uuid
    if (!inUse) llRegionSay(rezzerChannel, "RezItems") ; //if items not rezzed, rez them
    inUse = TRUE;//set in use to true
    currentAvis += aviUUID;//add this avi to the current avis
    integer noOfSounds = llGetInventoryNumber(INVENTORY_SOUND); //find out how many sounds are in the inventory
    integer soundIndex = 0; //set an index integer
    for(soundIndex = 0; soundIndex < noOfSounds; ++soundIndex)
    {   //lopp through all the sounds in the inventory caching them
        string soundName = llGetInventoryName(INVENTORY_SOUND, soundIndex); //get the name of the current sound
        llPreloadSound(soundName );//preload the sound to cache it
    }//close loop through sounds in the inventory
    integer range = 15;//sets the range for the sensor below
    integer rate = 5;//rate of checking for the sensor below
    llSensorRepeat("", NULL_KEY, AGENT, range, PI, rate);//sets the sensor running. 
}//close process new arrival

RemoveMissingAvis()
{   //remove any avi's not detected from the current avi's list
    integer currentAviIndex = (llGetListLength(currentAvis))-1;
    for (currentAviIndex; currentAviIndex >=0; --currentAviIndex)
    {   //loops through the list of known avi's
        key uuidToCheck = llList2Key(currentAvis, currentAviIndex); //uuid of the avi being checked now
        if (!(~llListFindList(detectedAvis, uuidToCheck)))
        {   //come here if the name on the list is not found among the detected avis
            currentAvis = llDeleteSubList(currentAvis, currentAviIndex, currentAviIndex);//remove this avi from the known avi's
        }//close if not found in the detected avis
    }//close loop through known avi's
    if (llGetListLength(currentAvis) == 0) ClearAndReset("RemoveMissingAvis");//if the list is now empty clear and reset
}//close remove missing avis

ClearAndReset(string from)
{   //removes rezzed items then resets the script
    llRegionSay(rezzerChannel, "DeRezItems");//messages rezzer to de-rez items
    llResetScript();//reset the script
}//close clear and reset

default
{
    changed (integer change)
    {   //if the sim restarts or the owner changes reset the script
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE); //makes the item volumetric
        inUse = FALSE;//sets item to off
        llRegionSay(rezzerChannel, "DialogMenuStatus,Off"); //ensures the menu for the rezzer is turned off
        llRegionSay(rezzerChannel, "DeRezItems");//ensures all items are de-ressed at startup
        llRegionSay(rezzerChannel, "ChatFeedback,Off"); //turns chat feedback off
    }

    sensor( integer num_detected )
    {
        integer aviIndex;
        detectedAvis = [];
        for (aviIndex = 0; aviIndex < num_detected; ++aviIndex)
        {   //loop through detected avis and add then to a list
            detectedAvis += llDetectedKey(aviIndex);
        }//close loop
        RemoveMissingAvis();//remove avis which have gone away from the list
    }//close sensor

    no_sensor()
    {   //no one around, 
        ClearAndReset("NoSensor");//clears records and resets the system
    }//close no sensor
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            if(!(~llListFindList(currentAvis, (list)detectedUUID)))
            {   //only process if a bot fo this avatar doesn't exist already
                ProcessNewArrival(detectedUUID);
            }//close if bot for avi doesn't exist
        }//close if detected type is an avatar
    }//close collissions
}