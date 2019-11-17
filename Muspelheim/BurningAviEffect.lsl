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
key rezzingObject;

SetUpListeners()
{//sets the coms channel and the random menu channel then turns the listeners on.
    comsChannelListen= llListen(comsChannel, "", NULL_KEY, "");//sets up main menu listen integer
    llListenControl (comsChannelListen, TRUE);
}//close set up listeners

StartParticles()
{
    llParticleSystem(
    [
        PSYS_SRC_PATTERN,PSYS_SRC_PATTERN_ANGLE_CONE,
        PSYS_SRC_BURST_RADIUS,0.9,
        PSYS_SRC_ANGLE_BEGIN,0.6,
        PSYS_SRC_ANGLE_END,0,
        PSYS_SRC_TARGET_KEY,llGetKey(),
        PSYS_PART_START_COLOR,<0.915619,0.635353,0.467194>,
        PSYS_PART_END_COLOR,<1.000000,1.000000,0.000000>,
        PSYS_PART_START_ALPHA,1,
        PSYS_PART_END_ALPHA,0,
        PSYS_PART_START_GLOW,0,
        PSYS_PART_END_GLOW,0.001,
        PSYS_PART_BLEND_FUNC_SOURCE,PSYS_PART_BF_SOURCE_ALPHA,
        PSYS_PART_BLEND_FUNC_DEST,PSYS_PART_BF_ONE_MINUS_SOURCE_ALPHA,
        PSYS_PART_START_SCALE,<0.100000,0.100000,0.000000>,
        PSYS_PART_END_SCALE,<1.5000000,1.5000000,0.000000>,
        PSYS_SRC_TEXTURE,"91d1204d-9f71-4de1-9aee-36c6fee529f3",
        PSYS_SRC_MAX_AGE,0,
        PSYS_PART_MAX_AGE,1,
        PSYS_SRC_BURST_RATE,0,
        PSYS_SRC_BURST_PART_COUNT,30,
        PSYS_SRC_ACCEL,<0.000000,0.000000,1>,
        PSYS_SRC_OMEGA,<0.000000,0.000000,0.000000>,
        PSYS_SRC_BURST_SPEED_MIN,0.01,
        PSYS_SRC_BURST_SPEED_MAX,0.4,
        PSYS_PART_FLAGS,
            0 |
            PSYS_PART_EMISSIVE_MASK |
            PSYS_PART_INTERP_COLOR_MASK |
            PSYS_PART_INTERP_SCALE_MASK
    ]);
}



default
{
    on_rez(integer param)
    {
        llResetScript();
    }

    state_entry()
    {
        StartParticles();
        SetUpListeners();
    }
    
    attach(key id)
    {
        if (id == "00000000-0000-0000-0000-000000000000")  
        {   //item has been detached
            llDie();
        }
    }

    listen( integer channel, string name, key id, string message )
    {
        key SaraPayne = "b2803c46-d65a-44e9-ba16-32a662d64c61";
        if (channel == comsChannel && llGetOwnerKey(id) == SaraPayne && message == "Detach") 
        {
            osForceDropAttachment();
        }
    }    
}