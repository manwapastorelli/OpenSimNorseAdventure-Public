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
integer sensorCount = 0;

CheckRange()
{   //sets the name to scan for then the range and starts a scanner
    string name = "CAS- Old_gramophone";//name to scan for
    float range = 1;//range
    llSensorRepeat( name, "", PASSIVE|SCRIPTED, range, PI , 3 );//stars a scanner with this info
} //close check range

default
{    
    on_rez(integer start_param)
    {   //when rezzed reset the script
        llResetScript();
    }//close on rez
 
    state_entry()
    {
        llSetAlpha(1,  ALL_SIDES );//set visible
        llSetStatus( STATUS_PHANTOM, FALSE);//set solid
        CheckRange();//scans the area for the gramophone
    }

    sensor( integer detected )
    {   //come here if the sensor detects the gramophone
        string detectedName = llDetectedName(0); //name of the detected item
        llSensorRemove();//stop the sensor
        llRegionSayTo(bookKey, comsChannel, "PlayRecord");//send a message tot he gramophone to play the song
        llSetAlpha( 0,  ALL_SIDES );//set invisible
        llSetTimerEvent(10);//start a timer for 10s
        llSetStatus( STATUS_PHANTOM, TRUE);//set phantom
    }//close sensor result
    
    no_sensor()
    {   //come here if there is no sensor result
        if (sensorCount > 20) 
        {   //if the count totals more than 20 come here
            llOwnerSay("Timed out and is now being removed");//message the owner
            llDie();//remove from the sim
        }//close if count is over 20
        ++sensorCount;//add one to the sesnor count
    }//close no sensor

    timer()
    {
        //come here if the timer runs out
        llDie();//remove from the sim
    }//close timer
}