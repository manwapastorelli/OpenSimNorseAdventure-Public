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

Error()
{
    llOwnerSay("This item should give you a map, please message admin to report this is missing");
}

GiveMap()
{
    if (llGetInventoryType("Colby Map") == INVENTORY_OBJECT)
    {   //if the item exists deliver it
        llGiveInventory(llGetOwner(), "Colby Map");
    }
    else llOwnerSay("This object is supposed to give you a map but it is missing. You will not be able to proceed without it, please contact the regions admin.");
}

default
{
    on_rez(integer param)
    {   //reset the script when rezzed
        llResetScript();
    }
    
    changed(integer change)
    {   //if changed owner reset the script
        if (change & CHANGED_OWNER) llResetScript();
    }
    
    state_entry()
    {
        string itemName = "Colby Map";
        if (llGetInventoryType("Colby Map") != INVENTORY_OBJECT) Error();
        else 
        {   //deliver the map to the items owner
            GiveMap();//gives the map
            llSetTimerEvent(30); //sets a timer for 30s
        }
    }
    
    touch_start(integer any)
    {
        if (llDetectedKey(0) == llGetOwner()) GiveMap(); //gives the map
        else llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "Only my owner can use me, you can get your own copy somewhere around here.");//error message if anyone other than the owner touches it
    }
    
    timer()
    {
        llDie(); //timeed out, time to die
    }
}