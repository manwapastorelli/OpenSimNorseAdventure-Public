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
    touch_start(integer num_detected)
    {
        llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "A folder with information about The Norse Adventure will be delivered shortly. ");
        string thisScript = llGetScriptName();
        list inventoryItems; //define a list for the items
        integer inventoryNumber = llGetInventoryNumber(INVENTORY_ALL);//find out how many items are in the inventory
        integer index;//define an index
        for ( ; index < inventoryNumber; ++index )
        {   //loop through the inventory
            string itemName = llGetInventoryName(INVENTORY_ALL, index); //nanme of the item being checked
            if (itemName != thisScript)
            {   //ignore this script
                if (llGetInventoryPermMask(itemName, MASK_OWNER) & PERM_COPY)
                {   //if the items are copy permision for the owner
                    inventoryItems += itemName; //add item to the list
                }//close if item is copy
                else
                {   //send error message if not able to deliver
                    llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "Unable to copy the item named '" + itemName + "'." + "Pleas contant an admin. This item is owned by: " +  llKey2Name(llGetOwner()));
                }
            }//close if item is not this script
        }//close loop through inventory
        if (inventoryItems == [] )
        {   //come here if there is nothing to deliver 
            llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "No copiable items found, sorry. Please contact an admin, this item is owned by: " + llKey2Name(llGetOwner()));
        }//close if there are no items
        else
        {   //items are present, deliver them in a folder
            llGiveInventoryList(llDetectedKey(0), llGetObjectName(), inventoryItems); //deliver the folder with content
        }
    }
}