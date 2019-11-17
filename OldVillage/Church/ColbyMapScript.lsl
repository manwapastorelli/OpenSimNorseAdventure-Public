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

integer comsChannel = -1433668630;
integer sensorCount = 0;

DeliverMap()
{   //delivers the map ot our owner if its present, otherwise give an error
    integer inventoryType = llGetInventoryType("Colby Map"); //gets the inventory type of the named item
    if (inventoryType == INVENTORY_TEXTURE) llGiveInventory( llGetOwner(), "Colby Map"); //item exits deliver it 
    else llOwnerSay("This item is supposed to contain a map it gives to you. If you have deleted the map please go and get another copy. If it is just missing without any reason please report this to Sara Payne.");
}

CheckRange()
{   //set a sensor looking for the old table within 3m
    string name = "Old Table In Cave"; //defines the item name
    float range = 3;//defines the range
    llSensorRepeat( name, "", PASSIVE|SCRIPTED, range, PI , 3 );//sets the sensor running
} //close check range

default
{
    on_rez(integer param)
    {   //resets the script when rezzed
        llResetScript();
    }
    
    changed (integer change)
    {   //reset if our owner is changed
        if (change & CHANGED_OWNER) llResetScript();
    }
    
    state_entry()
    {
        llSetAlpha( 1,  ALL_SIDES ); //set visible
        llSetStatus( STATUS_PHANTOM, FALSE);//set solid
        CheckRange();//check range from desired object
    }
    
    touch_start(integer dontCare)
    {   //if touched come here
        key user = llDetectedKey(0); //set uuid of toucher
        if (user == llGetOwner()) DeliverMap();//if its our owner deliver a texture of the map
        else llRegionSayTo(user, PUBLIC_CHANNEL, "This map can only be used by its owner, please obtain your own copy, its around here somehwere."); //if its not our owner deliver an error message
    }//close touch start
    
    sensor( integer detected )
    {   //come here if the item was detected in range
        key tableKey = llDetectedKey(0);  //gets the table uuid
        llSensorRemove();//stop the sensor 
        llRegionSayTo(tableKey, comsChannel, "ShowMap");//send a message to the table
        llSetAlpha( 0,  ALL_SIDES );//set invisible
        llSetTimerEvent(10);//set a timer for 10s
        llSetStatus( STATUS_PHANTOM, TRUE);//set phantom
    }
    
    no_sensor()
    {   //come here if there is no sensor
        if (sensorCount > 20) 
        {   //if the sensor has no results 20 times come here
            llOwnerSay("Timed out and is now being removed"); //deliver message to items owner
            llDie();//remove from the sim
        }//close if time out has occured
        ++sensorCount;//add one to the sensor count
    }//close no sensor
    
    timer()
    {   //if the timer runs out remove this item from the sim
        llDie();//remove item
    }//close timer
    
}