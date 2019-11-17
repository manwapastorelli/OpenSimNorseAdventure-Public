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

vector destination; 
integer comsChannel = -1890877079;
integer comsChannelListen;
key user;

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    comsChannelListen = llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE);
}//close set up listeners

Teleport(vector target)
{
    rotation rot = llGetRot();
    osTeleportObject(llGetKey(),target,rot,1);
    llUnSit(user);   
}

Return()
{
   vector startPos = <581.15332, 639.39886, 4003.05933>;
   float distanceFromTarget = llVecDist(llGetPos(), startPos); //caclulate how far we are from the end position
   while (distanceFromTarget >= 10)
   {   //if we are more than 10m from the target come here 
       llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, startPos]); //moves the item towards its target by upto 10m
       distanceFromTarget = llVecDist(llGetPos(), startPos); //calculates the distance from target again now. 
    }
   llSetLinkPrimitiveParamsFast(llGetLinkNumber(), [PRIM_POSITION, startPos]); // sets the final position as its less than 10m away 
   llListenControl (comsChannelListen, TRUE);
   llResetScript();
}//close return;

ChkAtDest()
{   //makes sure we arrived at destination, if not uses teleport to move the avatar there
    vector currentPos = llGetPos();
    float distFromTarget = llVecDist(destination, currentPos);
    if (distFromTarget > 1) osTeleportAgent(user, destination, ZERO_VECTOR);
}//close check at destination

default
{
    on_rez(integer param)
    {
        llResetScript();
    }
    
    state_entry()
    {
       SetUpListeners();
       llSitTarget(<0, 0, 1>, ZERO_ROTATION);
    }
    
    changed(integer change)
    {
        if (change & CHANGED_LINK)
        { 
            user = llAvatarOnSitTarget();
            if (user == "00000000-0000-0000-0000-000000000000") 
            {   //if the user unsits and at the desitnation return
                ChkAtDest();
                Return();
            }
            else 
            {
                Teleport(destination); //move to destination with the avi still sat
            }
        }
    }
    
    listen(integer channel, string name, key id, string message)
    {//listens on the set channels, then depending on the heard channel sends the message for processing.
        if (channel == comsChannel && llGetOwnerKey(id) == llGetOwner())
        {
            list instructions = llCSV2List(message);//turn the message into a list of instrucitons
            key aviUUID = llList2Key(instructions, 0);
            string instruction = llList2String(instructions, 1);
            vector oldVillagePos = <306.09781, 266.87286, 19.83971>;
            vector modernVillagePos = <157, 106, 6993>;
            if (instruction == "TimeTunnelToOldVillage") destination = oldVillagePos;//set the desination
            else if (instruction == "TimeTunnelToModernVillage") destination = modernVillagePos;
            osForceOtherSit(aviUUID, llGetKey());//force sit the avi
            llListenControl (comsChannelListen, FALSE); //stop the listener
        }     
    } 
}