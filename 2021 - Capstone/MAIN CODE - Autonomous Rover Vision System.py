#2021 OUTBACK JOE CHALLENGE - CAPSTONE
#AUTONOMOUS ROVER VISION SYSTEM
#AUTHOR: MATTHEW DEVONSHIRE S3659780

# Import libraries
import cv2
import numpy as np
import RPi.GPIO as GPIO
import time
import pigpio
import math
import smbus

#Setup for the colour locating
frameWidth = 640
frameHeight = 480
cap = cv2.VideoCapture(0)
cap.set(3, frameWidth)
cap.set(4, frameHeight)
midpoint_x = 320
OJ_found = 0
power_level = 0
endconfirm = 0

#Setup for face recognition
faceCascade = cv2.CascadeClassifier('Cascades/haarcascade_frontalface_default.xml')
face_area = 0
face_found = 0


def empty(a):
     pass

# Set GPIO numbering mode
GPIO.setmode(GPIO.BOARD)

#Set timeout number
maxTime = 0.04


#---------------------------
#COMPASS RELATED CODE
#Setup for the compass
bus = smbus.SMBus(1)
address = 0x0d

def read_byte(adr): #communicate with compass
    return bus.read_byte_data(address, adr)
 
def read_word(adr):
    low = bus.read_byte_data(address, adr)
    high = bus.read_byte_data(address, adr+1)
    val = (high<< 8) + low
    return val

def read_word_2c(adr):
    val = read_word(adr)
    if (val>= 0x8000):
        return -((65535 - val)+1)
    else:
        return val
    
def write_byte(adr,value):
    bus.write_byte_data(address, adr, value)
    return

#initialising values + communication with compas device
bearing = 0 #bearing is the direction we want to go
heading = 0 #heading is the direction we are currently going
write_byte(11, 0b01110000) #reset
write_byte(10, 0b00100000) 
write_byte(9, 0xD) #config
scale = 0.92
x_offset = -10
y_offset = 10

def check_heading():
    x_out = (read_word_2c(0)- x_offset+2) * scale #calculating x,y,z coordinates
    y_out = (read_word_2c(2)- y_offset+2)* scale
    z_out = read_word_2c(4) * scale
    abearing = math.atan2(y_out, x_out)+.48 #0.48 is correction value
    abearing = math.degrees(abearing)
    global heading
    heading = abearing
    print(heading)
    return
#---------------------------



#---------------------------
#SERVO RELATED CODE
servoL = 17 #pigpio uses BCM pin numbers only, rather than GPIO.BOARD
servoR = 18
pwm = pigpio.pi()
pwm.set_mode(servoL, pigpio.OUTPUT)
pwm.set_mode(servoR, pigpio.OUTPUT)

pwm.set_PWM_frequency(servoL, 50) # 50 = 50Hz pulse
pwm.set_PWM_frequency(servoL, 50)

# Define the middle/stopped position
midpos = 1540

#SETUP SERVOS TO ACT TOGETHER
#set up global rover status
Rstatus = 99
turn_direction = 0
#Counters for turning sequences
turn_counter = 20
counter_min = 20
check_counter = 1
checking_counter = 0
checking_counter_max = 13
currently_checking = 0
break_cycle_OJ = 0
needturnback = 0
OJ_bearing = -121

#The "Rstatus" variable is used to quickly determine what action the rover is currently doing.
#key: 99=blank 0=stationary 1=forward 2=backward 3=left 4=right.
#Set up the movement functions:
def forward(speed):
    pwm.set_servo_pulsewidth(servoL, midpos + speed * 25)
    pwm.set_servo_pulsewidth(servoR, midpos - speed * 25)
    global Rstatus
    Rstatus = 1
    return
    
def backward(speed):
    Lspeed = midpos - speed * 25
    Rspeed = midpos + speed * 25
    pwm.set_servo_pulsewidth(servoL, Lspeed)
    pwm.set_servo_pulsewidth(servoR, Rspeed)
    global Rstatus
    Rstatus = 2
    return
    
def turnL(speed):
    pwm.set_servo_pulsewidth(servoL, midpos - speed * 25)
    pwm.set_servo_pulsewidth(servoR, midpos - speed * 25)
    global Rstatus
    Rstatus = 3
    return
    
def turnR(speed):
    pwm.set_servo_pulsewidth(servoL, midpos + speed * 25)
    pwm.set_servo_pulsewidth(servoR, midpos + speed * 25)
    global Rstatus
    Rstatus = 4
    return
    
def stationary():
    pwm.set_servo_pulsewidth(servoL, midpos)
    pwm.set_servo_pulsewidth(servoR, midpos)
    global Rstatus
    Rstatus = 0
    return
#---------------------------



#---------------------------
#ULTRASONIC SENSOR CODE
#Setup echo and trig for prox sensor
TRIG = 15 #This is using GPIO.BOARD numbering as defined earlier
ECHO = 13
GPIO.setup(ECHO,GPIO.IN)
GPIO.setup(TRIG,GPIO.OUT)
#setup global distance variable
prox_distance = 999

def check_distance():
    GPIO.output(TRIG, False)
    #print ("Waiting for sensor to settle")
    #time.sleep(0.00001)
    GPIO.output(TRIG, True)
    time.sleep(0.000001)
    GPIO.output(TRIG, False)
    
    pulse_start = time.time()
    timeout = pulse_start + maxTime
    while GPIO.input(ECHO) == 0 and pulse_start < timeout:
        pulse_start = time.time()
    
    pulse_end = time.time()
    timeout = pulse_end + maxTime
    while GPIO.input(ECHO) == 1 and pulse_end < timeout:
        pulse_end = time.time()
            
    pulse_duration = pulse_end - pulse_start
    distance = pulse_duration * 17150
    distance = round(distance, 2)
    #print ("Distance: ",distance, "cm")
    global prox_distance
    prox_distance = distance
    
    return
#---------------------------



#---------------------------
#HI-VIS RECOGNITION CODE
#add the blocks of code for the colour detection
def getContours(img, imgContour):
    
    contours, hierarchy = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    cv2.drawContours(imgContour, contours, -1, (255, 0, 255), 7)
    
    for cnt in contours:
        area = cv2.contourArea(cnt)
        if area > 5000:
            cv2.drawContours(imgContour, cnt, -1, (255, 0, 255), 7)
            peri = cv2.arcLength(cnt, True)
            approx = cv2.approxPolyDP(cnt, 0.02 * peri, True)
            x , y , w , h = cv2.boundingRect(approx)
            cv2.rectangle(imgContour, (x, y), (x + w, y + h), (0,255,0),5)
            cv2.putText(imgContour, "Area: " + str(int(area)), (x + w + 20, y + 20), cv2.FONT_HERSHEY_COMPLEX, 0.7, (0, 255, 0), 2)

def get_contour_areas(contours):
    
    all_areas = []
    
    for cnt in contours:
        area = cv2.contourArea(cnt)
        all_areas.append(area)   

def get_biggest_contour(img, imgContour):
    global OJ_found
    global break_cycle_OJ
    contours, hierarchy = cv2.findContours(img, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
    get_contour_areas(contours)
    sorted_contours = sorted(contours, key = cv2.contourArea, reverse = True)
    if not sorted_contours:
        print("no hivis")
        OJ_found = 0
        break_cycle_OJ = break_cycle_OJ + 1
        print("OJ break counter:" ,break_cycle_OJ)
        return
    else:
        OJ_found = 1
        break_cycle_OJ = 0
        largest_item = sorted_contours[0]
        cv2.drawContours(imgContour, largest_item, -1, (255, 0, 255), 7)
        peri = cv2.arcLength(largest_item, True)
        approx = cv2.approxPolyDP(largest_item, 0.02 * peri, True)
        x , y , w , h = cv2.boundingRect(approx)
        cv2.rectangle(imgContour, (x, y), (x + w, y + h), (0,255,0),5)
        area = cv2.contourArea(largest_item)
        global power_level
        power_level = area
        print("area" ,power_level)
        if power_level < 5000:
            OJ_found = 0
            return
        else:
            cv2.putText(imgContour, "Area: " + str(int(area)), (x + w + 20, y + 20), cv2.FONT_HERSHEY_COMPLEX, 0.7, (0, 255, 0), 2)
            global midpoint_x
            midpoint_x = x + (w/2)
            print("midpoint x =" ,midpoint_x)
            return
#---------------------------



#---------------------------
#STARTUP FUNCTION
def move_part_one():
    
    #start PWM running, but with value of midpos (middle position)
    stationary()
    check_heading()
    global bearing
    bearing = heading
    print("starting engines")
    time.sleep(3)
    check_heading()
    bearing = heading
    time.sleep(3)
    #turnL(1)
    #time.sleep(5)
    return
#---------------------------



#---------------------------
#MAIN CODE
move_part_one()   
try:
    
    while True:
    	#---------------------------
        #COLOUR DETECTION CODE
        sucess, img = cap.read()
        img = cv2.flip(img, -1) #flip camera vertically
        imgContour = img.copy()
        imgHsv = cv2.cvtColor(img,cv2.COLOR_BGR2HSV)
        #add colour filter code
        lowerOrange = np.array([0,84,177])
        upperOrange = np.array([20,255,255])
        Orangemask = cv2.inRange(imgHsv,lowerOrange,upperOrange)
        OGmask = Orangemask
        #this is the hi vis filter image
        OGresult = cv2.bitwise_and(img,img, mask = OGmask)
        #blur the edges
        imgBlur = cv2.GaussianBlur(OGresult, (11, 11), 4)
        #make the blurred image grey
        imgGray = cv2.cvtColor(imgBlur, cv2.COLOR_BGR2GRAY)
        threshold1 = 59
        threshold2 = 42
        #Canny edge detection
        imgCanny = cv2.Canny(imgGray, threshold1, threshold2)
        #dilation (make the edges wider)
        kernal = np.ones((5, 5))
        imgDil = cv2.dilate(imgCanny, kernal, iterations=1)
        #find the contours
        getContours(imgDil, imgContour)
        #show and put a box around the largest contour
        get_biggest_contour(imgDil, imgContour)
        cv2.imshow("contour", imgContour)
        #
        #---------------------------
        
        
        
        #---------------------------
        #FACE DETECTION CODE
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = faceCascade.detectMultiScale(
            gray,
       
            scaleFactor=1.2,
            minNeighbors=5
            ,    
            minSize=(20, 20)
        )

        if np.any(faces):
            face_found = 1
            for (x,y,w,h) in faces:
                cv2.rectangle(img,(x,y),(x+w,y+h),(255,0,0),2)
                roi_gray = gray[y:y+h, x:x+w]
                roi_color = img[y:y+h, x:x+w]
                midpoint_x = x + w/2
                #following 4 lines are just for visual effects
                line_thickness = 2
                cv2.line(img, (int(midpoint_x), frameHeight), (int(midpoint_x), 0), (255, 0, 0), thickness = line_thickness)
                cv2.line(img, (220, frameHeight), (220, 0), (0, 0, 255), thickness = line_thickness)
                cv2.line(img, (430, frameHeight), (430, 0), (0, 0, 255), thickness = line_thickness)
        else:
            face_found = 0
        #---------------------------

        #---------------------------
        #TURN TO FACE CODE - This code makes the rover align towards the face that has been detected    
        if face_found == 1:
            if currently_checking == 1:
                stationary()
                currently_checking = 0
            while True:
                #add vision code
                ret, img = cap.read()
                img = cv2.flip(img, -1)
                gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
                faces = faceCascade.detectMultiScale(
                    gray,
       
                    scaleFactor=1.2,
                    minNeighbors=5
                    ,    
                    minSize=(20, 20)
                )
    
       
                for (x,y,w,h) in faces:
                    cv2.rectangle(img,(x,y),(x+w,y+h),(255,0,0),2)
                    roi_gray = gray[y:y+h, x:x+w]
                    roi_color = img[y:y+h, x:x+w]
                    midpoint_x = x + w/2
                    face_area = w*h
                    #add movement code
                    if midpoint_x < 220 and (Rstatus == 0 or 1):
                        turnL(1)
                        print("rotating to face L")
                    elif midpoint_x > 430 and (Rstatus == 0 or 1):
                        turnR(1)
                        print("rotating to face R")
                    elif Rstatus == 3 and midpoint_x > 320:
                        stationary()
                        break
                    elif Rstatus == 4 and midpoint_x < 320:
                        stationary()
                        break
                    else:
                        break
            check_heading()
            bearing = heading
            if face_area > 5000:
                print("Face Dectected, Stopping to prepare for transmission")
                stationary()
                time.sleep(10)
                #This is a successful end
        #---------------------------

        #---------------------------
        #TURN TO HI-VIS CODE - This code makes the rover align towards the hi-vis object that has been detected 
        if OJ_found == 1 and face_found == 0:
            if currently_checking == 1:
                currently_checking = 0
            while True:
                sucess, img = cap.read()
                img = cv2.flip(img, -1)
                imgContour = img.copy()
                imgHsv = cv2.cvtColor(img,cv2.COLOR_BGR2HSV)
                lowerOrange = np.array([0,84,177])
                upperOrange = np.array([20,255,255])
                Orangemask = cv2.inRange(imgHsv,lowerOrange,upperOrange)
                OGmask = Orangemask
                OGresult = cv2.bitwise_and(img,img, mask = OGmask)
                imgBlur = cv2.GaussianBlur(OGresult, (11, 11), 4)
                imgGray = cv2.cvtColor(imgBlur, cv2.COLOR_BGR2GRAY)
                threshold1 = 59
                threshold2 = 42
                imgCanny = cv2.Canny(imgGray, threshold1, threshold2)
                kernal = np.ones((5, 5))
                imgDil = cv2.dilate(imgCanny, kernal, iterations=1)
                getContours(imgDil, imgContour)
                get_biggest_contour(imgDil, imgContour)
                if break_cycle_OJ > 100:
                    print("in a rotating loop, break out!!")
                    break_cycle_OJ = 0
                    break
                if midpoint_x < 220 and (Rstatus == 0 or 1):
                    turnL(1)
                    print("rotating to OJ L")
                elif midpoint_x > 430 and (Rstatus == 0 or 1):
                    turnR(1)
                    print("rotating to OJ R")
                elif Rstatus == 3 and midpoint_x > 320:
                    stationary()
                    check_heading()
                    OJ_bearing = heading
                    print("align exit on rstat3 - OJ bearing =" ,OJ_bearing)
                    break
                elif Rstatus == 4 and midpoint_x < 320:
                    stationary()
                    check_heading()
                    OJ_bearing = heading
                    print("align exit on rstat4 - OJ bearing =" ,OJ_bearing)
                    break
                else:
                    if OJ_found == 0:
                        print("breaking cause no hivis")
                        break
                    if OJ_found == 1:
                        print("breaking just cause")
                        break
                   
            check_heading()
            bearing = heading
            print("oj area:" ,power_level)
            if power_level > 9000:
                print("its over 9000!!!!")
                stationary()
                time.sleep(10)
                #This is a successful end
        #---------------------------

        #---------------------------
        #OBJECT DETECTION AND PATHING        
        check_distance()
        print("Prox_Distance:" ,prox_distance)
        if prox_distance < 15:
           currently_checking = 0
           check_counter = 1
           backward(2)
           print("backing up")
           time.sleep(1.5)
           if turn_direction == 0:
               if turn_counter < counter_min:
                   turnL(2)
                   print("turning left big")
                   turn_counter = 0
                   turn_direction = 1
                   time.sleep(2.8)
                   if OJ_found == 1:
                       needturnback = 1
                       OJ_found = 0
               else:
                   turnL(2)
                   print("turning left")
                   turn_counter = 0
                   turn_direction = 1
                   time.sleep(1.4)
                   if OJ_found == 1:
                       needturnback = 1
                       OJ_found = 0
           elif turn_direction == 1:
               if turn_counter < counter_min:
                   turnR(2)
                   print("turning right big")
                   turn_counter = 0
                   turn_direction = 0
                   time.sleep(2.8)
                   if OJ_found == 1:
                       needturnback = 1
                       OJ_found = 0
               else:
                   turnR(2)
                   print("turning right")
                   turn_counter = 0
                   turn_direction = 0
                   time.sleep(1.4)
                   if OJ_found == 1:
                       needturnback = 1
                       OJ_found = 0
           check_heading()
           bearing = heading
        
        #TURN BACK TO OBJECTIVE IF AN EVASIVE MANOUVRE WAS MADE AFTER DETECTION
        if needturnback == 1:
            if turn_counter > 15:
                #use OJ_bearing to turn back
                turn_counter = 0
                while True:
                    check_heading()
                    if heading < (OJ_bearing-5) or heading > (OJ_bearing+5):
                        turnR(2)
                        print("Turning back to OJ, aim" ,OJ_bearing)
                    elif heading > (OJ_bearing-5) and heading < (OJ_bearing+5):
                        stationary()
                        print("Back on track, trying to find OJ again")
                        bearing = OJ_bearing
                        break
        #PERIODIC 360 DEG CHECK                
        if currently_checking == 0:
            turn_counter = turn_counter + 1
            print("turn counter:" ,turn_counter)
        if turn_counter/check_counter > 50 and OJ_found == 0:
            currently_checking = 1
            counter_i = 0
            check_counter = check_counter + 1
        if currently_checking == 1:
            counter_i = counter_i + 1
            if counter_i > 10: #this will allow the colour checking code to try 10 times before moving to next spot
                counter_i = 0
                turnL(1.5)
                time.sleep(0.7)
                stationary()
                checking_counter = checking_counter + 1
                print("checking_counter:" ,checking_counter)
            if checking_counter > checking_counter_max:
                currently_checking = 0
                checking_counter = 0
                stationary()
        #CHECK IF ON CORRECT BEARING, CORRECT IF NOT    
        check_heading()
        if bearing > -145 and bearing < 200 and currently_checking == 0:
            if heading > (bearing + 5): #check if drifting to right
                while heading > bearing:
                    print("correcting-going left -heading:" ,heading, "bearing:" ,bearing,)
                    check_heading()
                    turnL(1)
            elif heading < (bearing - 5): #check if drifting to left
               while heading < bearing:
                    check_heading()
                    turnR(1)
                    print("correcting-going right")
        #AFTER ALL THE ABOVE CODE, GENERALLY SPEAKING, THE ROVER WILL MOVE FORWARD IN THE DIRECTION IT IS AIMING
        if currently_checking == 0:
            forward(3)
            print("going forward")
        time.sleep(0.1)
                  
except KeyboardInterrupt:
    pass  
          
#SHUTDOWN PROCEDURE        
pwm.set_servo_pulsewidth(servoL, 0)
pwm.set_servo_pulsewidth(servoR, 0)
pwm.set_PWM_frequency(servoL, 0)
pwm.set_PWM_frequency(servoR, 0)       
print("Cleaning up")
GPIO.cleanup()