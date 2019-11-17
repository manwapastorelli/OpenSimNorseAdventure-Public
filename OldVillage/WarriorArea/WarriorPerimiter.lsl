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

integer inUse = FALSE;
integer timerCount = 0;
integer comsChannel = -111111;

default
{
    changed (integer change)
    {   //if the objects owner or region changes reset the script
        if (change & (CHANGED_REGION_RESTART | CHANGED_OWNER | CHANGED_REGION_START) ) llResetScript();
    }
    
    state_entry()
    {
        osVolumeDetect(TRUE); //sets item to volumetric
        llSay(comsChannel, "HideClockClock"); //sends a message to the clock to hide its self
    }
    
    collision_start(integer total_number)
    {
        integer detectedType = llDetectedType(0);
        if (detectedType == 1 || detectedType == 3 || detectedType == 5)
        {   //only process avatars, no bots or physical objects
            key detectedUUID = llDetectedKey(0);
            if (!inUse)
            {   //if the item is not already in use come here
                inUse = TRUE;//set to inuse
                llSetObjectName("Narrator"); //set the object name to narrator
                llSay(0, "As you approach the top of the tower a feeling of anticipation consumes you. Something important is about to transpire. "); //deliver message
                llSetTimerEvent (9);//set a timer event for 5s
            }//close if not in use
        }//close if detected type is an avatar
    }//close collissions

    no_sensor()
    {   //no one around, remove the sensor and reset the script
        llSensorRemove();//removes the sensor
        llResetScript(); //resets the script
    }//close no sensor

    timer()
    {   //main function handled by the timer
        string toSay;
        if (timerCount == 0) 
        {
            llSetObjectName("Narrator"); //set object name to narator
            llSay(0, "A warrior stands before a compass examining it closely "); //deliver message as narator 
            toSay = "There was a time when to navigate, all you needed was this and the sky"; //define warrior message
            llSetObjectName("Warrior");//set object name to warrior
            llSay(0, toSay);//deliver message as warrior
        }
        else if(timerCount == 1) 
        {
            llSetObjectName("Narrator");//set object name to narator
            llSay(0, "The warrior lets out a frustrated sigh and waves his hand to another bit of broken wall. As he does this clock appears.");//deliver message as narator 
            llSay(comsChannel, "ShowClock");//send message to the clock to show its self
            toSay = "Now we also need this";//define warrior message
            llSetObjectName("Warrior");
            llSay(0, toSay);//deliver message as warrior
        }
        else if (timerCount == 2)
        {
            llSetObjectName("Narrator");//set object name to narator
            llSay(0, "The frustration the warrior feels is is clear to see in his body language. ");//deliver message as narator 
            toSay = "Tell me how you navigate with this!";//define warrior message
            llSetObjectName("Warrior");
            llSay(0, toSay);//deliver message as warrior
        }
        else if (timerCount == 3)
        {
            llSetObjectName("Narrator");//set object name to narator
            llSay(0, "You watch the warrior shaking his head. After the head shake his finger follows the direction of the hands on the clock");//deliver message as narator 
            toSay = "What am i supposed to do with this?";//define warrior message
            llSetObjectName("Warrior");
            llSay(0, toSay); //deliver message as warrior      
        }
        else if (timerCount == 4)
        {
            llSetObjectName("Narrator");//set object name to narator
            llSay(0, "The warrior waves with indignation towards the church.");//deliver message as narator 
            toSay = "I know nothing of that one, but the rumours from there....Allfather I hope it is your doing this lord and their box.";//define warrior message
            llSetObjectName("Warrior");//deliver message as warrior
            llSay(0, toSay);
        }

        else if (timerCount == 5)
        {
            llSetObjectName("Narrator");//set object name to narator
            llSay(0, "Seeming to have forgotten your there at all the warrior returns his focus to the compass and the clock without saying another word.");//deliver message as narator 
            llSensorRepeat( "", "", AGENT, 10, PI, 5); //set a short range sensor running
            llSetTimerEvent(0);//stop the timer event
        }
        ++timerCount;//add one to the timer count
    }//close timer
}