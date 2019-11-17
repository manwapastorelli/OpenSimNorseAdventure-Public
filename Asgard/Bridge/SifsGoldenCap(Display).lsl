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


default
{
    touch_start (integer any)
    {   //come here when the item is clicked
        key aviUUID = llDetectedKey(0); //gets the uuid of the clicker
        vector capPos = llGetPos(); //gets the position of the cap
        list userDetails = llGetObjectDetails(aviUUID, [OBJECT_POS]);//generates a list which contains the position of the clicking avi
        vector aviPos = llList2Vector(userDetails, 0); //gets the vector from the list above
        float distance = llVecDist(capPos, aviPos); //calculates the distance between the two points
        if (distance < 30 )
        {   //come here if the distance is less than 30m
            string itemName = "Sifs Golden Cap"; //defines the name of the object to give
            integer inventoryType = llGetInventoryType(itemName); //gets the inventory type, it should be objevt, if not its missing or otherwise broken
            if (inventoryType == INVENTORY_OBJECT)
            {   //come here if there is an objevt with the correct name in the inventory
                llGiveInventory(aviUUID, itemName);
            }//close if found
            else 
            {   //come here if the item is misssing, and give the user a sensible error
                llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "This item is supposed to have given you 'Sifs Golden Cap', however it is missing from the objects inventory. Without this item you will be unable to proceed. Please report this to your admin. This item is owned by: " + llKey2Name(llGetOwner()));
            }//close if not found
        }//close if distance less than 30m
        else
        {   //if the user is more than 30m away send them an error messate
            llRegionSayTo(aviUUID, PUBLIC_CHANNEL, "Sorry you must be less than 30m away to use this item.");
        }//close if more than 30m away
    }//close touch start. 
}