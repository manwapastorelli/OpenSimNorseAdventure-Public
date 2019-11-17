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
    touch_start(integer any)
    {   //a simple script to deliver one item if its in the objects inventory
        string itemName = "Closed Scroll"; 
        integer scrollType = llGetInventoryType(itemName);
        if (scrollType != INVENTORY_OBJECT) 
        {   //item is missing send an error
            llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "This item has bits missing, please let admin knkow so they can fix it. You will not be able to proceed untill this is fixed.");
        }//close if item is missing
        else 
        {   //deliver the scroll and a message
            llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "When you examine the sigel a scroll falls out of the handle. Keen eyes may notice more. Use your eyes. ");//deliver message
            llGiveInventory(llDetectedKey(0), itemName);//deliver item
        }//close item is present
    }
}