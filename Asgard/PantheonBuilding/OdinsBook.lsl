// ----------------------------------------------------------------  
// Script Title:    3-Prim Book
// Created by:      WhiteStar Magic
// Creation Date:   Oct.05.2012
// Platforms:
//    SecondLife:    Not Tested
//    OpenSim:       Yes 
//
// Revision:        V.0.4
// Revision History:
//
// Origination:
// Initially Based loosely off the Improved book script Script @ http://forums.osgrid.org/viewtopic.php?f=5&t=2400
// This script evolved from "1-Prim Book" written by me @ http://forums.osgrid.org/viewtopic.php?f=5&t=3914
//
// Revision Contributors: WhiteStar V.0.1
// - Streamlined page handling
// - Optimized pages so each inside face holds a full texture
// - Modified texture pre-caching to use the spine (root prim, cylinder) top & bottom" faces to preload up coming textures
// - added facility to use front & back cover textures
// - add states for "run" and "GET_NOTECARDS"
// - Installed Notecard reader facility to eliminate script from having to be edited.
// -    CoverFR= for front Cover entry into NoteCard
// -    CoverBK= for back Cover entry into NoteCard
// -    Page=    to specify the pages. 1 per line using name(if contained in prim) or UUID, in sequential order.  Page-1, Page-2 Page-3 etc
// Revision Contributors: WhiteStar V.0.2
// - Streamlined page handling
// - Divided pages up so each inside face holds a full texture
// - Modified texture pre-caching to use "spine & bottom" edges to preload up coming textures
// - added facility to use front & back covers
// - add states for "run" and "GET_NOTECARDS"
// - Installed Notecard reader facility to eliminate script from having to be edited.
// -    Size=    allows use of REG, LG & XLG book sizes depending on material
// -    CoverFR= for front Cover entry into NoteCard
// -    CoverBK= for back Cover entry into NoteCard
// -    Page=    to specify the pages. 1 per line using name(if contained in prim) or UUID, in sequential order.  Page-1, Page-2 Page-3 etc
//
// V.0.3 Oct.01.2012 (enhancement for Book with Giver Capabilities.  NOT in this script set.
//
// V.0.4 Oct.05.2012 
//      Added a safety for ODD number pages to prevent the book closing prematurely.  
//      EX: If 5 pages were loaded, on the last page it would close teh book as there is only 1 image & not 2
//      Added / Fixed pre_caching and removed reliance on Timer as that was not working properly.
//      Cleaned up the code a little witha  little housekeeping
//
//
// ================================================================
// ** SCRIPT NOTES **
// The following must be in the root prim:  This script, Book.CFG notecard, Textures if desired (best for portability).
//
//** PRIM NOTES **
// ROOT prim (spine) = cyl.  Face=0 top, Face=2 bottom, face=1 = long (visible) face
// PAGE prims are rectangles with 50% cut.  The Cut Edge is linked to the root prim.
//      done this way to allow for easy stretching & shrinking.
// COVER prim is 0.010 shorter & narrower than Back prim.  Done so that it folds closed nicely without flickering
//      NOTE it's X position is offset by -0.05 to keep cover always visible when closed without flickering.
//
//================================================================
// ** Licence ** 
// !Attribution-NonCommercial-ShareAlike 3.0 Unported (CC BY-NC-SA 3.0) 
// REFERENCE http://creativecommons.org/licenses/by-nc-sa/3.0/
//================================================================
//
// adjust below to make book only respond to owner
integer OWNER_ONLY  = FALSE;  // default FALSE allows anyone to use book
//
// ====================================== \\
// Make changes below at your own peril ! \\
// ====================================== \\
//
// Global Variables
//
integer root_id;            // holder for Root Prim ID number
integer cover_id;           // holder for Front Cover Prim ID number
integer back_id;            // holder for Back Cover Prim ID number
//      FR=Front, BK=Back covers. from notecard. UUID or TextureName if contained
string  cover_FR;
string  cover_BK;
//
string  bookstate   = "closed";
string  bookconfig  = "Book.CFG";
key     NChandle    = NULL_KEY;
integer line        = 0;
//
list    Lst_pages;          // page= data from notecard (uuid or name)
integer page_qty;           // # of pages in Lst_pages
integer page_crnt   = 0;
integer page_next   = 1;
//
integer tLT         = 3;    // Left page Touchface
integer tRT         = 0;    // Right page Touchface
float   timer_delay = 5.0;
//
// ==================== \\
// SCRIPT STARTS HERE ! \\
//======================\\
//
set_texture_parms()
{
    // here the front & back covers are set along with the scaling for this application
    llSetLinkPrimitiveParams(cover_id, [PRIM_TEXTURE, 1, cover_FR, <2.0,1.0,0>, <0.50,0.0,0>, 0.0]); // set front cover & scale 
    llSetLinkPrimitiveParams(back_id, [PRIM_TEXTURE, 4, cover_BK, <2.0,1.0,0>, <0.50,0.0,0>, 0.0]);  // set back cover & scale
    //
    llSetLinkPrimitiveParams(cover_id,[PRIM_TEXTURE, 3, llList2Key(Lst_pages,0), <2.0,1.0,0.0>, <0.50,0.0,0>, 0.0]); // LT-page    
    llSetLinkPrimitiveParams(back_id,[PRIM_TEXTURE, 0, llList2Key(Lst_pages,1), <2.0,1.0,0.0>, <0.50,0.0,0>, 0.0]);  // RT-page    
    //
    // Face 1 of the spine (cylinder) is what everyone sees, not changing it.
    llSetColor(<0,0,0>, 0);   // colour over top face of spine (cylinder)
    llSetColor(<0,0,0>, 2);   // colour over bottom face of spine     
}

get_link_ids() 
{
    integer i;
    integer len = llGetNumberOfPrims();
    for(i=1;i<=len;i++) 
    {        
        string name = llGetLinkName(i);
        if(name==llGetObjectName()) root_id = i;    // should be 1 as root always = 1
        else if(name=="cover") cover_id = i;        // should be 2 or 3 depending on how linked
        else if(name=="back") back_id = i;          // should be 3 or 2  "" ""
        else llOwnerSay("root prim, front cover, back cover have not been identified"+
            "\nThe 'root prim' (spine) can have any name.  Suggest using Descriptive Name for the book"+
            "\nThe 'Cover prim' must be called 'cover'"+
            "\nThe 'Back prim' must be called 'back'");
    }
    if(cover_id=="") llOwnerSay("Cover-ID="+cover_id);
    if(back_id=="")  llOwnerSay("Back-ID="+back_id);
    if(root_id=="")  llOwnerSay("Root-ID="+root_id);
}

set_pages() // set textures for both inner pages
{
    key Lt_pg = (key)llList2String(Lst_pages,page_crnt);     // ODD Pages on left
    key Rt_pg = (key)llList2String(Lst_pages,(page_crnt+1)); // EVEN pages on Right
    if (Rt_pg == NULL_KEY ||  Rt_pg == "") Rt_pg = TEXTURE_BLANK; // SAFETY BLANK for ODD numbers of pages
    llSetLinkTexture(cover_id, Lt_pg, 3); // LT-page    
    llSetLinkTexture(back_id, Rt_pg, 0);  // RT-page
    pre_cache();
}

pre_cache()
{
    key oddcache;
    key evencache;
    
    if(bookstate=="closed") 
    {
        oddcache=llList2Key(Lst_pages,0);
        evencache=llList2Key(Lst_pages,1);
        llSetTexture(oddcache,0);  // face 0 = top face of spine cyliner
        llSetTexture(evencache,2); // face 2 = bottom face edge of spine
    }
    else 
    {
        oddcache=llList2Key(Lst_pages,page_next+1);
        evencache=llList2Key(Lst_pages,page_next+2);
        llSetTexture(oddcache,0);  // face 0 = top face of spine cyliner
        llSetTexture(evencache,2); // face 2 = bottom face edge of spine
    }
}

openbook()
{
    bookstate="open";
    // open cover only, Back & Spine stay put.
    // The Hinging Cover
    list prim_rot = llGetLinkPrimitiveParams(cover_id,[PRIM_ROT_LOCAL]);
    rotation rot = llList2Rot(prim_rot,0);
    rotation delta = llEuler2Rot(<0,0,-PI/2>);
    rot = delta * rot;
    llSetLinkPrimitiveParams(cover_id, [PRIM_ROT_LOCAL,rot]);
    llSleep(0.05);
    rot = delta * rot;
    llSetLinkPrimitiveParams(cover_id, [PRIM_ROT_LOCAL,rot]);
}

closebook()
{
    list prim_rot = llGetLinkPrimitiveParams(cover_id,[PRIM_ROT_LOCAL]); 
    rotation rot = llList2Rot(prim_rot,0);
    rotation delta = llEuler2Rot(<0,0,PI/2>);
    rot = delta * rot;
    llSetLinkPrimitiveParams(cover_id, [PRIM_ROT_LOCAL,rot]);
    llSleep(0.05);
    rot = delta * rot;
    llSetLinkPrimitiveParams(cover_id, [PRIM_ROT_LOCAL,rot]);
    // 
    bookstate="closed";
    page_crnt=0;
    page_next=1;
    //
    // set pages up for next use.  Includes setting page 1 & 2 and pre-caching 3 & 4
    llSetLinkTexture(cover_id, (key)llList2String(Lst_pages,1), 3); // LT-page    
    llSetLinkTexture(back_id, (key)llList2String(Lst_pages,2), 0);  // RT-page
    //
    llSetTexture((key)llList2String(Lst_pages,3),0); // setting pre-cache to pages 3 & 4
    llSetTexture((key)llList2String(Lst_pages,4),2);
    //
}

// START //
default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }
    state_entry()
    {
        get_link_ids();
        state GET_NOTECARDS;
    }
}
// RUNNING //
state run
{
    state_entry()
    {
        set_texture_parms();
        page_qty = llGetListLength(Lst_pages);
        llOwnerSay("[ "+page_qty+" ] Pages loaded. Ready, click on cover to read");
    }

    touch_start(integer num_times)
    {
        if(OWNER_ONLY && llDetectedKey(0)!=llGetOwner()) return; // only owner is set, to ignore others
        //
        integer touched_Prim = llDetectedLinkNumber(0);
        string  touched_Name = llGetLinkName(touched_Prim);
        if(bookstate=="closed")
        {
            openbook();
            set_pages();
            pre_cache();
        }
        else if(bookstate=="open")
        {
            if(llDetectedTouchFace(0)==tRT && touched_Name =="back") // RTface touched
            {
                page_crnt=page_crnt + 2; 

                if(page_crnt>(page_qty-1))
                {
                    closebook();
                    pre_cache();
                }
                else
                {
                    set_pages();
                    page_next = page_crnt+1;
                }
                if ( page_next < page_qty )pre_cache();
            }
            else if(llDetectedTouchFace(0) == tLT && touched_Name =="cover") // LTface touched
            {
                page_crnt=page_crnt - 2;
                if(page_crnt< 0)
                {
                    closebook();
                }
                else
                {
                    set_pages();
                    page_next = page_crnt-1;
                }
                if ( page_next < page_qty )pre_cache();
            }
        }
    }

    changed(integer change)
    {
        if (change & CHANGED_INVENTORY)
        {
            llOwnerSay("The inventory changed. Restarting book");
            llResetScript();
        }
        if (change & 1024) llResetScript();
    }
}
//-------------------\\
// Get Notecard Data \\
//-------------------\\
state GET_NOTECARDS
{
    state_entry()
    {
        line = 0;
        NChandle = llGetNotecardLine(bookconfig, 0); //
    }
    dataserver(key query_id, string data)
    {
        if(query_id == NChandle) // Filtering the call
        {

            if (data == EOF)
            {
                state run;
            }
            else
            {
                data = llStringTrim(data, STRING_TRIM_HEAD);
                if (llGetSubString (data, 0, 0) != "#") // If it's # skip the line, it's a comment
                {
                    integer s = llSubStringIndex(data, "=");
                    if(~s) // does it have an "=" in it? if YES it's Valid!
                    {
                        string token = llToLower(llStringTrim(llDeleteSubString(data, s, -1), STRING_TRIM)); // trim up token & lower case it
                        data = llStringTrim(llDeleteSubString(data, 0, s), STRING_TRIM);


                        if (token == "coverfr")         // Set Front Cover
                        {
                            if(data=="") llOwnerSay("CoverFR= is not identified in "+bookconfig+" No Front Cover will be shown");
                            else cover_FR = data;
                        }
                        else if (token == "coverbk")    // Set Back Cover
                        {
                            if(data=="") llOwnerSay("CoverBK= is not identified in "+bookconfig+" No Back Cover will be shown");
                            else cover_BK = data;
                        }
                        else if (token == "page")
                        {
                            if(data !="")
                            {
                                //llOwnerSay("The Data is: "+(string)data);
                                Lst_pages += [data];

                            }
                            else llOwnerSay("Loading Page= from "+bookconfig+" NoteCard: Data is Empty ! No Pages Available");
                        }
                    }
                }
                NChandle = llGetNotecardLine(bookconfig,++line);
            }
        }
    }
}