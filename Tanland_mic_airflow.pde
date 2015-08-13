/*
Author: Benjamin Low (Lthben@gmail.com)
 Date: 27 Jul 2015
 Description: Does an FFT analysis of a microphone input. Intention is to detect an airflow rather than sound.
 A moving average of mic readings for the lowest frequency band is tracked over a certain number of readings.
 If the moving average exceeds the noise threshold, the program sends out a TRUE reading to another Flash
 program. You can adjust the USER SENSITIVITY SETTINGS below.
 Note: Make sure the computer sound setting is ready to accept the microphone input.
 */

import ddf.minim.analysis.*;
import ddf.minim.*;

Minim minim;
AudioInput in;
FFT fft;

//USER SENSITIVITY SETTINGS
float noise_threshold = 0.6; //strength of airflow required
float tolerance = 1.2; //multiplier for noise threshold. Constrains the actual readings. Affects response time greatly.
int action_duration = 5;// response time in seconds

//Other settings
int num_readings = action_duration * 60; //assuming frameRate of 60
float reading_total, reading_average;
float[] readings;
boolean is_triggered;
int read_index;
long time_triggered;
float height45;
float spectrumScale = 50;
PFont font;

void setup()
{
    size(512, 480, P3D);
    height45 = 4*height/5;

    minim = new Minim(this);

    in = minim.getLineIn( Minim.STEREO, 1024, 44100 );

    fft = new FFT( 1024, 44100 );

    fft.linAverages(20); //num of frequency bands 

    rectMode(CORNERS);
    font = loadFont("ArialMT-12.vlw");

    readings = new float[num_readings];
}

void draw()
{
    if (millis() - time_triggered < action_duration*1000 && is_triggered) {
        background(25, 0, 128);
        fill(255,0,0);
        text("TRIGGERED", 0.85*width, 15);
    } else {
        fill(255);
        background(0);
    }

    fft.forward( in.mix );

    noStroke();

    float centerFrequency = 0;

    int w = int(width/fft.avgSize())*2;

    for (int i=0; i<fft.avgSize ()/2; i++) {
        if ( mouseX >= i*w && mouseX < i*w + w )
        {
            centerFrequency = fft.getAverageCenterFrequency(i);

            fill(255, 128);
            text("Linear Average Center Frequency: " + centerFrequency, 5, 30);

            fill(255, 0, 0);
        } else
        {
            fill(255);
        }
        rect(i*w, height45, i*w + w, height45 - fft.getAvg(i)*spectrumScale);
    }

    if (millis() - time_triggered > action_duration*1000 || !is_triggered) {
        float actual_reading = fft.getAvg(0);
        readings[read_index] = constrain(actual_reading, 0.0, tolerance*noise_threshold); 
        reading_total += readings[read_index];
        int index_oldest = (read_index + 1)%num_readings;
        reading_total -= readings[index_oldest];
        read_index++;

        if (read_index == num_readings) {
            read_index = 0;
        }    

        reading_average = reading_total/num_readings;
        
        fill(255,255,0);
        rect(0, 0, (reading_average/noise_threshold)*width, 10);
        
        if (actual_reading > noise_threshold) text("above noise reading: " + actual_reading, 5, height - 40);  
    } 

    if (reading_average > noise_threshold) {
        is_triggered = true;
        time_triggered = millis();
        reading_total = 0;
        reading_average = 0;
        for (int i=0; i<num_readings; i++) {
            readings[i] = 0;
        }        
    } else if (millis() - time_triggered > action_duration*1000) {
        is_triggered = false;
    }
    
    fill(255);
    text("noise threshold: " + noise_threshold, 5, height - 60);
    text("tolerance: " + tolerance, 200, height - 60);
    text("response time: " + action_duration, 350, height - 60);
    text("reading average: " + reading_average, 5, height - 20);
}

boolean sketchFullScreen() {
  return true;
}
