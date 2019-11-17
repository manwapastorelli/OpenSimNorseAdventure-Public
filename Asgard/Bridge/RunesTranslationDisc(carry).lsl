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

integer sensorCount;

CheckRange()
{
    string name = "Muspelheim Story Book";
    float range = 10;
    llSensorRepeat( name, "", PASSIVE|SCRIPTED, range, PI , 3 );
}


default
{
    on_rez(integer start_param)
    {
        llResetScript();
    }

    state_entry()
    {
        llSetAlpha( 1, ALL_SIDES );
        llSetStatus( STATUS_PHANTOM, FALSE);
        sensorCount = 0;
        CheckRange();
    }

    sensor( integer detected )
    {
        string detectedName = llDetectedName(0);
        key bookKey = llDetectedKey(0);
        key bookOwner = llGetOwnerKey(llDetectedKey(0));
        llSensorRemove();
        integer comsChannel = -1568493613;
        llRegionSayTo(bookKey, comsChannel, "StarTranslation");
        llSetAlpha( 0,  ALL_SIDES );
        llSetTimerEvent(10);
        llSetStatus( STATUS_PHANTOM, TRUE);
    }
    
    no_sensor()
    {
        if (sensorCount > 20) llDie();
        ++sensorCount;
    }
    
    timer()
    {
        llDie();
    }
}