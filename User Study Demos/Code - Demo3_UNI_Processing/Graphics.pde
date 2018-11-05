void drawQuestion_part1(int nr, boolean result) {
  // Background
  imageMode(CORNER);
  image(background, 0, 0);

  switch(nr) {
  case 0:
    break;
  case 1:
    break;
  case 2:
    if (begin_question || result) {
      noFill();
      stroke(WTlight);
      strokeWeight(answerSize/3);
      ellipse(Q1_topLeftX+Q1R_L/2, Q2_targetY, Q2_targetSize, Q2_targetSize);
    }
    break;
  case 3:
    break;
  case 4:
    break;
  default:
    break;
  }
}

void drawQuestion_part2(int nr, boolean result) {
  //Titles
  textFont(AllerBold); 
  textSize(questionNrSize); 
  textLeading(questionNrSize*1.2);
  fill(255);
  textAlign(RIGHT, CENTER);
  if (nr>0) text("Question\n"+nr+" of 4   ", questionNrX, questionY);
  if (!transition || STATE == 0) {

    textFont(AllerItalic);
    textAlign(LEFT, CENTER);
    textSize(questionSize);
    textLeading(questionSize*1.2);
    text(questions[nr], questionX, questionY);
    if (showA) {
      begin_question = true;
      begin_question_time = 0;
      showA = false;
    }
  }

  int lengthR = 0;
  int sum = 0;
  int max = 0;
  int maxI = -13;
  float[] perc = {0, 0};

  if (transition && STATE != 0) {
    if (showQ) {
      transition = false;
      showQ = false;
    } else {
      fill(255);
      textFont(AllerItalic);
      textAlign(LEFT, CENTER);
      textSize(questionSize);
      textLeading(questionSize*1.2);
      text(instructions2[nr], questionX, questionY);
      textAlign(LEFT, TOP);
      textFont(Aller);
      textSize(answerSize);
      fill(0);
      text(instructions1[nr], Q1_topLeftX, Q2_targetY-.2*textAscent()-answerSize*6);
    }
  } else {

    switch (nr) {
    case 0:

      break;
    case 1:                 // QUESTION 1

      if (begin_question) {
        if (begin_question_time == 0)
          begin_question_time = System.currentTimeMillis();
        long diff = System.currentTimeMillis()-begin_question_time;
        // stroke(WTlight);
        // strokeWeight(timeStroke);
        //line(map(diff, 0, begin_question_thres, questionNrX, width), timeStrokeHeight, width, timeStrokeHeight);
        if (diff>begin_question_thres) {
          begin_question_time = 0;
          begin_question = false;
          resultQ = true;
          sendBreak();
          sendResults();
        }
      }


      int textfill;
      if (result) {
        textfill = 110;
        begin_question_time = 0;
        begin_question = false;
      } else textfill = 30;

      if (result) {
        animation = constrain(animation+.1+(100-animation)/40, 0, 100);

        int count[] = {0, 0, 0, 0, 0, 0};
        lengthR = results[nr].length;
        for (int i = 0; i <lengthR; i++)
          if (results[nr][i]>=0 && results[nr][i] <6)
            count[results[nr][i]]++;

        lengthR = count.length;
        sum = 0;
        max = -1;
        maxI = -1;
        for (int i=0; i<lengthR; i++) {
          int val = count[i];
          sum+= val;
          if (val > max) {
            max = val;
            maxI = i;
          }
        }
        perc = new float[lengthR];
        for (int i = 0; i<lengthR; i++) perc[i] = (float)count[i]/(float)max;
      } else animation = 0;

      ellipseMode(CENTER);
      textFont(Aller);
      noStroke();
      stroke(WTlight);
      strokeCap(ROUND);
      for (int i = 0; i<6; i++) {

        if (result) { 
          stroke(WT, animation/50*255);
          strokeWeight(Q1_targetSize-1);
          line(Q1_topLeftX, Q1_topLeftY+(i*Q1_targetDist), Q1_topLeftX-Q1_targetSize, Q1_topLeftY+(i*Q1_targetDist));
          stroke(255);
          strokeWeight((Q1_targetSize-1)*.9);
          line(Q1_topLeftX, Q1_topLeftY+(i*Q1_targetDist), Q1_topLeftX-Q1_targetSize, Q1_topLeftY+(i*Q1_targetDist));

          String percentage = (int)(perc[i]*max/sum*100) + "%";
          textAlign(CENTER, CENTER);        
          textSize(answerSize*.7);
          fill(110, animation/50*255);
          text(percentage, Q1_topLeftX-.9*Q1_targetSize, Q1_topLeftY+(i*Q1_targetDist)-.2*textAscent());

          strokeWeight(Q1_targetSize);
          stroke(WTlight);
          line(Q1_topLeftX, Q1_topLeftY+(i*Q1_targetDist), Q1_topLeftX+constrain((animation/100)*perc[maxI], 0, perc[i])*Q1R_L, Q1_topLeftY+(i*Q1_targetDist));
        } else if (begin_question) {
          strokeWeight(Q1_targetSize);
          stroke(WTlight);
          line(Q1_topLeftX, Q1_topLeftY+(i*Q1_targetDist), Q1_topLeftX, Q1_topLeftY+(i*Q1_targetDist));              //effectively drawing a dot
        }
        if (begin_question || result) {

          textAlign(LEFT, CENTER);
          textSize(answerSize);
          fill(textfill);
          char first = answers1[i].charAt(0);        
          text(answers1[i], Q1_topLeftX-(textWidth(first)/2), Q1_topLeftY+(i*Q1_targetDist)-.2*textAscent());
        }
      }


      break;
    case 2:                // QUESTION 2

      if (begin_question) {
        if (begin_question_time == 0)
          begin_question_time = System.currentTimeMillis();
        long diff = System.currentTimeMillis()-begin_question_time;
        //stroke(WTlight);
        //strokeWeight(timeStroke);
        //line(map(diff, 0, begin_question_thres, questionNrX, width), timeStrokeHeight, width, timeStrokeHeight);
        if (diff>begin_question_thres) {
          begin_question_time = 0;
          begin_question = false;
          resultQ = true;
          sendBreak();
          sendResults();
        }
      }

      if (result) {
        animation = constrain(animation+.1+(100-animation)/20, 0, 100);
        begin_question_time = 0;
        begin_question = false;

        int count[] = {0, 0};
        lengthR = results[nr].length;
        for (int i = 0; i <lengthR; i++)
          if (results[nr][i]>=0 && results[nr][i] <2)
            count[results[nr][i]]++;

        lengthR = count.length;
        sum = 0;
        max = -1;
        maxI = -1;
        for (int i=0; i<lengthR; i++) {
          int val = count[i];
          sum+= val;
          if (val > max) {
            max = val;
            maxI = i;
          }
        }
        perc = new float[lengthR];
        for (int i = 0; i<lengthR; i++) perc[i] = (float)count[i]/(float)max;
      } else animation = 0;


      if (begin_question) {
        textFont(AllerBold);
        textSize(2*answerSize);
        textAlign(CENTER, CENTER);
        String L = "true";
        String slash = " / ";
        String R = "false";
        fill(WT);
        text(L, Q1_topLeftX+Q1R_L/2-textWidth(L+slash)/2, Q2_targetY-.2*textAscent());
        fill(WTlight);
        text(slash, Q1_topLeftX+Q1R_L/2, Q2_targetY-.2*textAscent());
        fill(WTred);
        text(R, Q1_topLeftX+Q1R_L/2+textWidth(R+slash)/2, Q2_targetY-.2*textAscent());
      } else if (result) {
        noFill();
        stroke(WTlight);
        strokeWeight(answerSize/3);
        ellipse(Q1_topLeftX+Q1R_L/2, Q2_targetY, Q2_targetSize, Q2_targetSize);
        strokeCap(RECT);
        noFill();
        strokeWeight(answerSize*2);
        stroke(WT);
        arc(Q1_topLeftX+Q1R_L/2, Q2_targetY, Q2_targetSize, Q2_targetSize, 0, (animation/100)*perc[0]*TWO_PI);
        stroke(WTred);
        arc(Q1_topLeftX+Q1R_L/2, Q2_targetY, Q2_targetSize, Q2_targetSize, (animation/100)*perc[0]*TWO_PI, (animation/100)*perc[0]*TWO_PI+(animation/100)*perc[1]*TWO_PI);




        textFont(AllerBold);
        textSize(1.8*answerSize);
        textAlign(CENTER, CENTER);
        String percentage0 = (int)(perc[0]*max/sum*100) + "%";
        String slash = " / ";
        String percentage1 = (int)(perc[1]*max/sum*100) + "%";
        fill(WT);
        text(percentage0, Q1_topLeftX+Q1R_L/2-textWidth(percentage0+slash)/2, Q2_targetY-.2*textAscent());
        fill(WTlight);
        text(slash, Q1_topLeftX+Q1R_L/2, Q2_targetY-.2*textAscent());
        fill(WTred);
        text(percentage1, Q1_topLeftX+Q1R_L/2+textWidth(percentage1+slash)/2, Q2_targetY-.2*textAscent());
      }
      break;
    case 3:                 // QUESTION 3

      if (begin_question) {
        if (begin_question_time == 0)
          begin_question_time = System.currentTimeMillis();
        long diff = System.currentTimeMillis()-begin_question_time;
        //stroke(WTlight);
        //strokeWeight(timeStroke);
        //line(map(diff, 0, begin_question_thres, questionNrX, width), timeStrokeHeight, width, timeStrokeHeight);
        if (diff>begin_question_thres) {
          begin_question_time = 0;
          begin_question = false;
          resultQ = true;
          sendBreak();
          sendResults();
        }
      }
      if (result) {
        animation = constrain(animation+.1+(100-animation)/20, 0, 100);
        begin_question_time = 0;
        begin_question = false;

        int count[] = {0, 0, 0, 0};
        lengthR = results[nr].length;
        for (int i = 0; i <lengthR; i++)
          if (results[nr][i]>=0 && results[nr][i] <4)
            count[results[nr][i]]++;

        lengthR = count.length;
        sum = 0;
        max = -1;
        maxI = -1;
        for (int i=0; i<lengthR; i++) {
          int val = count[i];
          sum+= val;
          if (val > max) {
            max = val;
            maxI = i;
          }
        }
        perc = new float[lengthR];
        for (int i = 0; i<lengthR; i++) perc[i] = (float)count[i]/(float)max;
      } else animation = 0;

      noStroke();
      textFont(Aller);
      textAlign(CENTER, CENTER);
      textSize(answerSize2);
      strokeCap(ROUND);
      if (begin_question || result) {
        for (int i = 0; i<4; i++) {      
          if (result) {
            strokeWeight(Q3_targetSize);
            stroke(WTlight);
            line(Q1_topLeftX+i*Q1R_L/3, Q3_targetY+(animation/100)*(2*Q1_targetDist), Q1_topLeftX+i*Q1R_L/3, Q3_targetY+(animation/100)*(2*Q1_targetDist)-(animation/100)*perc[i]*(4*Q1_targetDist));       
            noStroke();
            textFont(AllerBold);
            textSize(answerSize2);
            fill(WT);
            String string = (int)(perc[i]*max/sum*100) + "%";
            text(string, Q1_topLeftX+i*Q1R_L/3, Q3_targetY+(animation/100)*(2*Q1_targetDist)-(animation/100)*perc[i]*(4*Q1_targetDist)-1.2*Q1_targetDist);
          }
          strokeWeight(Q3_targetSize);
          stroke(WT);
          line(Q1_topLeftX+i*Q1R_L/3, Q3_targetY+(animation/100)*(2*Q1_targetDist), Q1_topLeftX+i*Q1R_L/3, Q3_targetY+(animation/100)*(2*Q1_targetDist));              //effectively drawing a dot
          fill(255);
          textFont(Aller);
          textSize(answerSize2);
          text(answers3[i], Q1_topLeftX+i*Q1R_L/3, Q3_targetY-.2*textAscent()+(animation/100)*(2*Q1_targetDist));
        }
      }
      break;
    case 4:                // QUESTION 4
      if (begin_question || result) {
        if (begin_question) {
          if (begin_question_time == 0)
            begin_question_time = System.currentTimeMillis();
          long diff = System.currentTimeMillis()-begin_question_time;
          //stroke(WTlight);
          //strokeWeight(timeStroke);
          //line(map(diff, 0, begin_question_thres, questionNrX, width), timeStrokeHeight, width, timeStrokeHeight);
          if (diff>begin_question_thres) {
            begin_question_time = 0;
            begin_question = false;
            resultQ = true;
            sendBreak();
            //sendResults();
          }
        }
        stroke(100);
        strokeWeight(answerSize/3);
        line(Q1_topLeftX, Q3_targetY, Q1_topRightX, Q3_targetY);
        noStroke();
        fill(WTlight);

        if (result) {
          animation = constrain(animation+.1+(100-animation)/20, 0, 100);
          begin_question_time = 0;
          begin_question = false;

          int count[] = {-999, -999, -999, -999, -999, -999};
          int nr_counts[] = {0, 0, 0, 0, 0, 0};
          lengthR = results[nr].length;
          for (int i = 0; i <lengthR; i++)
            if (results[nr][i]>=0 && results[nr][i] <=4) {
              if (count[results[nr+1][i]]==-999)
                count[results[nr+1][i]]=0;    // only use used political parties
              nr_counts[results[nr+1][i]]++;
              count[results[nr+1][i]]+=results[nr][i];      // add all answers (and take average further onwards)
            }
          for (int i =0; i < lengthR; i++)
            if (nr_counts[i] != 0) count[i] = count[i]/nr_counts[i];    // effectively taking the average of all anwsers


          imageMode(CENTER);
          for (int i = 0; i<6; i++) {
            if (count[i]!= -999) {
              float pos = map(count[i], 0, 4, -1.1*Q1R_L, -.1*Q1R_L);
              image(Q4_image[i], (Q1_topLeftX+4.4*Q1R_L/4)+(animation/100)*pos, Q3_targetY+(-2.5+i)*Q4_diff, Q4_size, Q4_size);
            }
          }
        } else {
          animation = 0;
          for (int i = 0; i<5; i++) {
            ellipse(Q1_topLeftX+i*Q1R_L/4, Q3_targetY, Q1_targetDist, Q1_targetDist);
          }
        }
        fill(WT);
        textFont(AllerItalic);
        textSize(1.5*answerSize);
        textAlign(RIGHT, CENTER);
        text("Left", Q1_topLeftX+-.4*Q1R_L/4, Q3_targetY-.2*textAscent());
        textAlign(LEFT, CENTER);
        text("Right", Q1_topLeftX+4.4*Q1R_L/4, Q3_targetY-.2*textAscent());
      }
      break;
    default:                 // DEFAULT
      break;
    }
  }
}

void applyScreenSize() {
  /////////** SEE DESIGN IN RESOURCES FOLDER **/////////

  //posTitle,posYear,posStars,posSubtext,posPlay,posScroll,posExit,posUp,posDown,posLogo,posRow1,posRow2,posRow3,posGenre1,posGenre2,posGenre3;
  //sizeTitle,sizeYear,sizeStars,sizeSubtext,sizePlay,sizeScroll,sizeExit,sizeUp,sizeDown,sizeLogo,sizeRow1,sizeRow2,sizeRow3,sizeGenre1,sizeGenre2,sizeGenre3;
  float H = height;
  float W = width;

  questionNrX = .463*H;
  timeStroke = .02*H;
  timeStrokeHeight = .208*H;
  questionNrSize = .056*H;
  questionX = .535*H;
  questionY = .10*H;
  questionSize = .045*H;
  answerSize = .03*H;
  answerSize2 = .04*H;

  background.resize(ceil(H/background.height*background.width), ceil(H));

  Q1_topLeftX = .82*H;
  Q1_topLeftY = .326*H;
  Q1_topRightX = .875*W;
  Q1R_L = Q1_topRightX - Q1_topLeftX;
  Q1_targetDist = .108*H;
  Q1_targetSize = .08*H; 

  Q2_targetSize = .36*H*1.3;
  Q2_targetY = .627*H;

  Q3_targetSize = .158*H;
  Q3_targetY = Q1_topLeftY+(3*Q1_targetDist);

  Q4_diff = (Q3_targetY-Q1_topLeftY)/3;
  Q4_size = (int)(.134*H);

  questions[0] = "  Welcome to today's quiz!";
  questions[1] = "  Kepler’s laws are three rules which\ncan be used to describe the...";
  questions[2] = "  The binding of specific molecules to ion channels controls\nthe ability of particular ions to cross the cell membrane.";
  questions[3] = "  The centre of gravity of a semi-circle lies at a distance of\n_______ from its base measured along the vertical radius.";
  questions[4] = "  Place the political party from your watch\non the political spectrum below.";

  instructions1[0] = "";
  instructions1[1] = ""
    + "Vibration confirms system operational\n\n"
    + "Vibration confirms a selection. You can lower your hand\n\n"
    + "Reselect if you like\n\n"
    + "Check your watch for the result!";
  instructions1[2] = ""
    + "Vibration confirms system operational\n\n"
    + "Vibration confirms a selection. You can lower your hand\n\n"
    + "Reselect if you like\n\n"
    + "Check your watch for the result!";
  instructions1[3] = ""
    + "Vibration shows you your colour\n\n"
    + "Vibration confirms a selection. You can lower your hand\n\n"
    + "Reselect if you like\n\n"
    + "Check your watch for the result!";
  instructions1[4] = ""
    + "Vibration shows you your input\n\n"
    + "Vibration confirms a selection. You can lower your hand\n\n"
    + "Reselect if you like\n\n";

  instructions2[0] = "";
  instructions2[1] = "Physics";
  instructions2[2] = "Biology";
  instructions2[3] = "Mathematics";
  instructions2[4] = "a Poll";

  answers1[0] = "relation between volume and the amount of a gas";
  answers1[1] = "motion of planets around the sun";
  answers1[2] = "probability of a quantum measurement with a given result";
  answers1[3] = "flow of a fluid through a porous medium";
  answers1[4] = "orbital period of satellites orbiting planets ";
  answers1[5] = "distribution of electric charge to the resulting electric field";

  answers3[0] = "3r/8";
  answers3[1] = "3r/4π";
  answers3[2] = "4r/3π";
  answers3[3] = "8r/3";


  results = new int[6][Watches];
  results_prev = new int[6][Watches];
  if (useServer)
    for (int i = 0; i<6; i++)
      for (int q=0; q< Watches; q++) {
        results[i][q] = -13;
        results_prev[i][q] = -13;
      } else results = new int[][]{
    {0, 0}, {1, 5}, {1, 2}, {4, 2}, {2, 5}, {2, 5}
  };
  results_correct = new int[]{-99, 1, 0, 2, -99};

  TARGET_SIZE= Q1_targetSize/4;
}