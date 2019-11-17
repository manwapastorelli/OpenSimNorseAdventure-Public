/*
New BSD License
===============
Copyright 2019 Sara Payne

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

/*
How To Use Instructions in a notecard inside the same item as this script. 
Basic script flow at the base of this script.
*/

integer bookOpen; //bool used to store the open or closed state of the book
integer linkCover; //stores the cover link number
integer linkBack; //stores the back link number
integer linkCache;//stores the cache prim link number
integer numberOfPages; //stores the number of pages found;
integer currentPage; //current odd page number, note 0 is odd at the start


SetTextures()
{   //sets page textures based on the page number
    integer oddPageFace = 3; //face number of the page texture on the cover prim
    integer evenPageFace = 0; //face number of the page texture on the back prim
    integer intOddPageTail = currentPage+1; //page numbers start at 0, but tails start at 1
    string oddPageTexture = CurrentPagePrefix(intOddPageTail) + (string)intOddPageTail;//generate texture name based on the tail, which is based on the page number
    integer intEvenPageTail = currentPage+2;//page numbers start at 0, but tails start at 1
    string evenPageTexture = CurrentPagePrefix(intEvenPageTail) + (string)intEvenPageTail;//generate texture name based on the tail, which is based on the page number
    llSetLinkPrimitiveParamsFast(linkCover, [ PRIM_TEXTURE, oddPageFace, oddPageTexture, <2,1,1>, <0.5,0,0>, 0 ]); //apply the texture to the odd face
    llSetLinkPrimitiveParamsFast(linkBack, [ PRIM_TEXTURE, evenPageFace, evenPageTexture, <2,1,1>, <0.5,0,0>, 0 ]); //apply the texture to the even face
    CachePages(intOddPageTail, intEvenPageTail);//generate cache texture names and apply them based on tail tail numbers, which are based on the page number
}//close set textures

CachePages(integer intOddPageTail, integer intEvenPageTail)
{   //apply cached images based on tail numbers and the number of pages 
    integer intCachePage0;
    integer intCachePage1;
    integer intCachePage2;
    integer intCachePage3;
    string cacheTexture0;
    string cacheTexture1;
    string cacheTexture2;
    string cacheTexture3;
    if (numberOfPages < 4)
    {   //if there are only two pages apply the two images to all cache spaces
        //no need to fix these as there are only two pages, no need to worry about max/min pages
        intCachePage0 = intOddPageTail;
        intCachePage1 = intOddPageTail;
        intCachePage2 = intEvenPageTail;
        intCachePage3 = intEvenPageTail;
    }//close 2 pages
    else if (numberOfPages < 6)
    {   //if there are 4 pages apply one image before and after the tail number to cache
        //FixChachPagePrefix - adjusts if they go below 1 or above the last page
        //Does this for one page before and one page after the current tail number
        intCachePage0 = FixCachePagePrefix((intOddPageTail-1)) ;
        intCachePage1 = FixCachePagePrefix((intOddPageTail-1)) ;
        intCachePage2 = FixCachePagePrefix((intEvenPageTail+1)) ;
        intCachePage3 = FixCachePagePrefix((intEvenPageTail+1)) ;
    }//close 4 pages
    else
    {   //if there are 6 or more pages add two images before and after the tail number to cache
        //FixChachPagePrefix - adjusts if they go below 1 or above the last page
        //Does this for two pages before and one page after the current tail number
        intCachePage0 = FixCachePagePrefix((intOddPageTail-1)) ;
        intCachePage1 = FixCachePagePrefix((intOddPageTail-2)) ;
        intCachePage2 = FixCachePagePrefix((intEvenPageTail+1)) ;
        intCachePage3 = FixCachePagePrefix((intEvenPageTail+2)) ;
    }//close 6 or more pages
    //put the current bits together to make the texture names
    cacheTexture0 = CurrentPagePrefix(intCachePage0) + (string)intCachePage0;
    cacheTexture1 = CurrentPagePrefix(intCachePage1) + (string)intCachePage1;
    cacheTexture2 = CurrentPagePrefix(intCachePage2) + (string)intCachePage2;
    cacheTexture3 = CurrentPagePrefix(intCachePage3) + (string)intCachePage3;
    //apply the generated names to the cache prim
    llSetLinkPrimitiveParamsFast(linkCache, [ PRIM_TEXTURE, 0, cacheTexture0, <1,1,1>, <0,0,0>, 0 ]);
    llSetLinkPrimitiveParamsFast(linkCache, [ PRIM_TEXTURE, 1, cacheTexture1, <1,1,1>, <0,0,0>, 0 ]);
    llSetLinkPrimitiveParamsFast(linkCache, [ PRIM_TEXTURE, 2, cacheTexture2, <1,1,1>, <0,0,0>, 0 ]);
    llSetLinkPrimitiveParamsFast(linkCache, [ PRIM_TEXTURE, 3, cacheTexture3, <1,1,1>, <0,0,0>, 0 ]);
}//close cache pages

integer FixCachePagePrefix(integer inputInteger)
{   //adjust numbers if they go below 1 or above the last page 
    integer newPreFix;
    integer difference;
    if (inputInteger < 1)
    {   //set to the last page and subtract the difference
        difference = 1-inputInteger; //how far below the last page is this number
        newPreFix = numberOfPages+1 - difference; //prifix numbers are 1 higher than page numbers as inventory indexes start at 0;
    }
    else if (inputInteger > numberOfPages)
    {   //set to the first page and add on the difference
        difference = inputInteger - numberOfPages; //how many pages past the last is this?
        newPreFix = difference; //we don't need to add here as the first page is 0;
    }
    else newPreFix = inputInteger; //no changes required
    return newPreFix;//return the correct number
}//close fix cache page prefix


string CurrentPagePrefix(integer inputInteger)
{   //takes the current page num prefix and adds a 0 if required
    string basePreFix = "pg_";
    string zeroPrefix;
    if (numberOfPages > 9 && inputInteger < 10) zeroPrefix = "0";
    else zeroPrefix = "";
    string currentPrefix = basePreFix+zeroPrefix;
    return currentPrefix; //returns the result
}

string CleanString(string inputString)
{   //removes white space and converts to lower case
    string cleanString = llStringTrim(llToLower(inputString), STRING_TRIM);
    return cleanString; 
}//close clean string

string RemovePreFixZeros(string inputString)
{   //removes any 0's from the start of the string unless its the only character
    integer length = llStringLength(inputString);
    string firstChar = llGetSubString(inputString, 0, 0);
    while (length > 1 && firstChar == "0" )
    {   //ignore any 0's at the start of the string but not if its the only character
        inputString = llGetSubString(inputString, 1, -1); //get everything after the frist 0
        firstChar = llGetSubString(inputString, 0, 0); //set the new first character again
        length = llStringLength(inputString);//get the string length again
    }//close while string has more than 1 char
    return  inputString;
}//close remove pre fix 0's

integer ChkIsInt (string inputString)
{   //checks to see if a string can be parsed into an integer and returns true or false
    integer isInt;
    inputString = RemovePreFixZeros(inputString);
    integer chkInt = (integer)inputString; //type cast to integer
    string chkStr = (string)chkInt; // type cast back to string
    if (inputString == "") isInt = FALSE; //set false if string is blank
    else if (chkStr == inputString) isInt = TRUE; //if strings match set true
    else isInt = FALSE; //if they dont match set false
    return isInt; //return bool
}//close check is int

PageTextureErrorMessage(string type, string imageName)
{   //if a page texture name error has been detected give the user some useful feedback to help them fix it
    //tell them which image name is incorrect and why
    string generalMessage = "All page textures must be in the format 'pg_number' and be in suquential order.";
    string catStartMsg = "Malformed Page Name: " + imageName +". ";
    string categoryMessage;
    if (type == "PreFix") categoryMessage = catStartMsg + "The page texture name does not begin with 'pg'.";
    else if (type == "Tail") categoryMessage = catStartMsg + "The tail (bit after the underscore) is not an integer (whole number)";
    else if (type == "Seperator") categoryMessage = catStartMsg + "There is no underscore in this name.";
    else if (type == "Sequential") categoryMessage = catStartMsg + "This page appears to be out of order, please check page numbers have no gaps. \n 
    If you have more than 9 pages you will need to a '0' before the number. eg '1' becomes '01'. If you have more than 99 pages please add anther '0', eg '001'";
    else if (type == "NumOfPages") categoryMessage = "To many pages, this script supports a maximim of 99 pages please reduce";
    else if (type == "OddNumberOfPages") categoryMessage = "There are an odd number of pages, please add once more page to act as a blank page at the end if you have no more real pages.";
    llOwnerSay(generalMessage);
    llOwnerSay(categoryMessage);
}//close page texture error message

CheckPageTextures()
{   //checks all textures in the book to make sure they are formatted correct and sends an error if they are not. 
    numberOfPages = 0;
    integer numOfTextures = llGetInventoryNumber(INVENTORY_TEXTURE);
    if (numOfTextures > 99) PageTextureErrorMessage("NumOfPages", "");
    integer imageIndex;
    for(imageIndex = 0; imageIndex < numOfTextures; ++imageIndex)
    {   //loops through all images in the book
        string imageName = llGetInventoryName(INVENTORY_TEXTURE, imageIndex);
        integer underScoreIndex = llSubStringIndex(imageName, "_"); //position of the underscor in the name
        if (underScoreIndex == -1) PageTextureErrorMessage ("Seperator", imageName); //if no undersore in the name throw an error
        string preFix = llGetSubString(imageName, 0, (underScoreIndex-1)); //get the bit before the under score
        preFix = CleanString(preFix); //clean it up the string
        string tail = llGetSubString(imageName, underScoreIndex+1, -1); //get the bit after the underscore
        tail = CleanString(tail); //clean up the string
        if (preFix == "pg") 
        {   //prefix and underscore ok, check the tail
            integer isInt = ChkIsInt (tail);
            if (!isInt) PageTextureErrorMessage("Tail", imageName);  //if its not an integer throw an error
            else
            {   //we know the tail is an integer now make sure they are all in order
                tail = RemovePreFixZeros(tail); 
                integer pgNum = (integer)tail; //typecast clean string to integer
                if (pgNum-1 != imageIndex) PageTextureErrorMessage("Sequential", imageName); //if page number minus 1 does not match the current image index throw an error
                else ++numberOfPages; //add one to the number of pages
            }//close else  
        }//close if prefix is ok
        else PageTextureErrorMessage("PreFix", imageName); //if prefix is incorrect throw an error
    }//close loop through book page images
    integer isOddNumber = (integer)(numberOfPages % 2);
    if(isOddNumber) PageTextureErrorMessage("OddNumberOfPages", "");
}//close check textures   

GetLinks()
{   //loops through all links in the book and records the front and back cover link numbers
    integer linkIndex;
    for(linkIndex = 2; linkIndex <= llGetNumberOfPrims(); ++linkIndex)
    {//loop through all links looking for fron and back covers ignoring root prim
        string linkName =  llGetLinkName(linkIndex)  ; //name of currently processing link
        if (linkName == "cover") linkCover = linkIndex; //store cover link number if name of link is cover
        else if (linkName == "back") linkBack = linkIndex; //store back link number if name of link is back
        else if (linkName == "TextureCache") linkCache = linkIndex;//store cache link number
    }//close loop
}//close get links

OpenCloseBook()
{   //gets the current rotation of the book cover and reverses it, then reverses the open status
    rotation rotToApply;
    if (bookOpen) rotToApply = llEuler2Rot(<0,0,PI/2>); // equivalent to 90deg in Z local to the root prim 
    else if (!bookOpen) rotToApply = llEuler2Rot(<0,0,-PI/2>);// equivalent to 90deg in Z local to the root prim 
    list coverDetails = llGetLinkPrimitiveParams(linkCover,[PRIM_ROT_LOCAL]); //generates a list contating the local rot of the cover prim
    rotation currentRot = llList2Rot(coverDetails,0); //convert list contents to rotatoion
    rotation newRot = currentRot * rotToApply; //combine the rotations
    //do the acutal rotation twice so it looks visuallylike the page is turning the exepcted direction and not backwards
    llSetLinkPrimitiveParamsFast(linkCover, [PRIM_ROT_LOCAL,newRot]); //set the new position
    newRot = newRot * rotToApply; //combine the rotations
    llSetLinkPrimitiveParamsFast(linkCover, [PRIM_ROT_LOCAL,newRot]); //set the new position
    bookOpen = !bookOpen; //toggle the status. 
}//close open/close book

SetClosed()
{   //closes the book if its open and sets status closed
    bookOpen = FALSE;
    rotation closedLocRot = <0.000000, 0.000000, 0.000002, -1.000000>;
    llSetLinkPrimitiveParamsFast(linkCover, [PRIM_ROT_LOCAL,closedLocRot]); //set the new position 
}//close set book closed

ProcessTouches(integer touchedLink)
{   //act based on which prim is touched, two pages per click as 2 pages shown at once
    if (touchedLink == linkCover) currentPage = currentPage-2; //if the cover prim is touched subtract 2 from the page number
    else if (touchedLink == linkBack) currentPage = currentPage+2; //if the back prim is touched, add 2 to the page number
    else if (currentPage < 0) OpenCloseBook();  
    if (currentPage >= numberOfPages ) 
    {   //if page adjustments make it lower than 0, set to 0 can close the book
        currentPage = 0;
        OpenCloseBook();
        MessageStairs();  
    }//close if page number less than 0;
    else if (currentPage == (numberOfPages-1))
    {
        //add code to activate the stairs here
    }
    SetTextures(); //apply textures based on page number
}//close process touches

MessageStairs()
{   //sends a regionsay message to the staircase to activate it
    integer comsChannel = -1154202259; //sets the channel number
    llRegionSay(comsChannel, "ActivateStairs" + "," + llGetOwner()); //messages the stairs
    llSetTimerEvent(1800);//sets the timer event for 30 mins to clean up this item if it is left rezzed
}//close message stairs

default
{
    on_rez( integer param)
    {   //reset the script when ever we are rezzed
        llResetScript();
    }

    changed( integer change )
    {   //reset the script if the inventory contents change
        if (change & CHANGED_INVENTORY ) llResetScript() ;
    }//close changed

    state_entry()
    {
        GetLinks(); //store link numbers in sensible names
        CheckPageTextures();//make sure all textures are named correctly
        SetClosed(); //close the book at startup
        currentPage = 0;//set current page to 0;
        SetTextures();//apply textures based on page number
        llSetTimerEvent(1800);//sets the timer event for 30 mins to clean up this item if it is left rezzed
    }//close state entry

    touch_start(integer num_detected)
    {
        if (llDetectedKey(0) == llGetOwner())
        {   //come here if the click is from the object owner
            llSetTimerEvent(1800);//sets the timer event for 30 mins to clean up this item if it is left rezzed
            if (!bookOpen) OpenCloseBook(); //if the book is closed, open it
            else ProcessTouches(llDetectedLinkNumber(0)); //if the book is alredy open process based on clicked page
        }//close if click is the object owner
        else llRegionSayTo(llDetectedKey(0), PUBLIC_CHANNEL, "Sorry only this objects owner can interact with this object, you will need to obtain your own copy. You should be able to find it around here somewhere."); //tell other touchers they can't use this object
    }//close touch start
    
    timer()
    {   //if the books been left out and untouched for 30 mins tell the owner its times out and remove
        llOwnerSay("Sorry but the book has timed out, please rez me again to use.");//message the user to let them know 
        llDie();//remove the book from the sim
    }//close timer
}

/*
Script Principles
=================
1. Every image in the root prim is considered a page texture
2. At startup the script counts the images and checks they fit the format required
3. Clicking the book when closed will open the book.
4. Clicking the left page will go back a page, the right page will go forwards a page
5. Pages cache based on the currently displayed pages
6. When the last page is viewed a message is sent to the stairs to activate them. 
*/