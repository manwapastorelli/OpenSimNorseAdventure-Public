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

integer comsChannel = -111111;
integer comsChannelListen;
vector startPos = <87.86377, 170.24638, 6993.47607>;
vector tunnelStartPos = <729.08777, 639.39886, 4003.18115>;
vector tunnelEndPos = <563.27026, 639.39886, 4003>;
vector oldVillagePos = <306.09781, 266.87286, 19.83971>;
integer timerCount;
key user;

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE);
}//close set up listeners

Teleport(vector destination)
{
    rotation rot = llGetRot();
    osTeleportObject(llGetKey(),destination,rot,1);
    integer arrived = ChkAtDestination(destination);
    if (!arrived) Teleport(destination);
}
 
integer ChkAtDestination(vector targetDest)
{
    float distFromTarget = llVecDist(llGetPos(), targetDest);
    if (distFromTarget < 1) return TRUE;
    else return FALSE; 
}


SendDeRez()
{
    integer rezBoxchannel = -111111;
    string rezBoxInsuct = "DeRezItems" + "," +"";
    integer comsChannel = -111111;
    string pewsInstruct = "ResetPews";
    llRegionSay(rezBoxchannel, rezBoxInsuct);
    llRegionSay(comsChannel, pewsInstruct);
}

StartTimeTunnel()
{   //unsits the avi then change the script to state time tunne.
     llUnSit(user);//unist
     state timeTunnel;    //change script state
}


default
{
    on_rez(integer param)
    {
        //reset script whenever we are rezzed
        llResetScript();
    }
    
    state_entry()
    {
       SetUpListeners();
       llSetStatus(STATUS_PHYSICS, FALSE);//make sure physics are false at the start
       llSitTarget(<0, 0, 1>, ZERO_ROTATION);//set the sit target
    }
    
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { //if the linkn number changes get the sit target uuid
            user = llAvatarOnSitTarget();
            if (user != "00000000-0000-0000-0000-000000000000") 
            {   //come here if its not null, aka an avi just sat on this item
                rotation rot = llGetRot(); //get the current rot
                osTeleportObject(llGetKey(),tunnelStartPos,rot,1);//teleeport the object with the sat avi to the target position and rotation. 
                StartTimeTunnel();//calls the time tunnel method
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {//listens on the set channels, then depending on the heard channel sends the message for processing.
        if (channel == comsChannel && message == "TardisForceSit")
        {   //if the message is heard on the coms channel 
            user = llGetOwnerKey(id); //
            osForceOtherSit(user, llGetKey()); //force sit the avi
            llListenControl (comsChannelListen, FALSE);//turn the listener off
        }     
    } 
}//close state default

state timeTunnel
{
    state_entry()
    {
        llForceMouselook(TRUE); //forces the user into mouselook
        llSitTarget(<0, 0, 1>, ZERO_ROTATION); //sets the sit target
        osForceOtherSit(user, llGetKey());//forsits the avi again,
    }

    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { 
            key userTest = llAvatarOnSitTarget();
            if (userTest != "00000000-0000-0000-0000-000000000000") 
            {   //come here when an avi sits
                llSetStatus(STATUS_PHYSICS, TRUE); //pyysics on
                llMoveToTarget(tunnelEndPos, 10); //start moving towards the end of the tunnel
                timerCount = 0; //set the timer count to 0
                llPlaySound("dr who title scene-pt1", 1); //play the title music
                llSetTimerEvent(1);//set a timer event for every 1s
            }
            else if (userTest == "00000000-0000-0000-0000-000000000000") 
            {   //if the avi unsits
                integer timeTunnelChannel = -1890877079;
                string toSend = (string)user + "," + "TimeTunnelToOldVillage";//message to send about this event
                llRegionSay(timeTunnelChannel, toSend);//sends the time tunnel tp ball
                SendDeRez();//sends de-rez message to the tardis rezzer in the modern village
            }
        }
    }

    timer()
    {
        if (timerCount == 9 ) 
        {   //when the timer count is 9 do this..
            string itemName = "Blackout Hud"; //name of the item to attach
            osForceAttachToOtherAvatarFromInventory(user, itemName, ATTACH_HUD_CENTER_2);//force attach the hud
        }
        else if (timerCount == 10) llPlaySound("dr who title scene-pt2", 1);//play part 2 of the title music
        else if (timerCount >= 20)
        {//re reached the end
            llStopMoveToTarget();//stop movement
            llSetStatus(STATUS_PHYSICS, FALSE);//turn phyiscs off
            llUnSit(user);//usit the avi
            llSetTimerEvent(0);//sto the timer event
        }
        ++timerCount;//increase the time timer count at each timer interval
    }
}
