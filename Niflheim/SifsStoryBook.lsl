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

string originalName = "Sif' story book";
integer comsChannel = -111111;
string aviName;
 
string ParseName(string detectedName)
{ // parse name so both local and hg visitors are displayed nicely
string firstName;
string lastName;
integer periodIndex = llSubStringIndex(detectedName, ".");
list nameSegments;
if (periodIndex != -1)
    {   //this is a hypergrid visitor
        nameSegments = llParseString2List(detectedName,[" "],["@"]);
        string hGGridName = llList2String(nameSegments,0);
        nameSegments = [];
        nameSegments = llParseStringKeepNulls(hGGridName, [" "], ["."]);
        firstName = llList2String(nameSegments,0);
        lastName = llList2String(nameSegments,2);
    }//close if hg visitor
else
    {   //this is a local visitor
        nameSegments = llParseString2List(detectedName, [" "], []);
        firstName = llList2String(nameSegments, 0);
        lastName = llList2String(nameSegments, 1);
    }//close if local visitor
string fullName = firstName + " " + lastName;
return fullName;
}//close parse name

DeliverStory()
{
   llSetObjectName(aviName);
   list storyList = 
        [  
            "Placing the book down you glance at the scene displayed, reading the story out loud ",
            "One night Loki sneaks into Sif’s bedroom while she sleeps and cuts off her beautiful golden hair. He lets her tresses fall where ever they would and steals out proud of himself for having played such a clever joke.", 
            "The next day when Thor discovers what has happened to Sif, he corners Loki, and he throttled him. Loki fearing for his life agrees to travel to the realm of the dwarves and convince the most talented of this race to create a golden cap of hair for Sif and to give it magical power, so that it might grow like real hair when placed on her head. ",
            "Loki arrives in Svartalfheim and finds the best craftsmen to make Sif a golden wig. He also asks that the dwarves make gifts for the gods Odin and Frey, a clever political consideration on Loki’s part. ",
            "Loki promises the dwarves that if they help him, they will not only have the gratitude of Odin, Frey and Thor, but their talents will shine far and wide. The dwarves agree and make Sif a wig finer than her original hair. ",
            "For Frey they build a ship called Skidbladnir which folds small enough to fit into a pocket. For Odin they make the mighty spear Gungnir, which becomes revered as a weapon ‘that an oath sworn upon its blade could never be broken, by god or man’"
        ];
    integer index;
    for (index = 0; index < llGetListLength(storyList); ++ index)
    {
        llRegionSayTo(llGetOwner(), PUBLIC_CHANNEL, llList2String(storyList, index));
        llSleep(10);
    }
    llSetObjectName(originalName);
}
 
default
{
    on_rez (integer param)
    {
        llResetScript();
    }

    state_entry()
    {
        aviName = ParseName(llKey2Name(llGetOwner())); // gets the name of the avi from their key and parses it incase of hyper grid visitors
        DeliverStory();
        string message = "SifsBook" + "," + (string)llGetOwner();
        llRegionSay(comsChannel, message);
        llRegionSayTo(llGetOwner(), PUBLIC_CHANNEL, "As you finish reading the book it magically vanishes, a rotating disc appears on the wall infront of you imediately capturing your attention");
        llDie();
    }
}