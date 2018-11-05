void drawTrainSchedule() {
  noStroke();
  rectMode(CORNERS);

  /*    Header Row    */
  fill(WTlight); 
  rect(0, 0, width, border+trainRow * .5);
  fill(WT);
  rect(column[4], border, width-border, border+trainRow * .5);
  drawClock();

  for (int i = 0; i < 7; i++) {
    if (i%2 == 1)  fill(WTlight); 
    else fill(255); 
    rect(0, border+trainRow * (i+.5), width, border+trainRow * (i+1.5));
  }

  fill(WT);
  textFont(Aller);
  textAlign(LEFT, CENTER);
  textSize(headerSize);
  text("Vertrek", column[0], border+trainRow *.5 *.4);
  text("Naar / Opmerkingen", column[1], border+trainRow *.5 *.4);
  text("Spoor", column[2], border+trainRow *.5 *.4);
  text("Trein", column[3], border+trainRow *.5 *.4);
  fill(255);
  text(String.format("%02d", hour()) + ":" + String.format("%02d", minute()), column[4]+trainRow*.5, border+trainRow *.5 *.4);
  fill(WT);

  if (minute() > trainTable.getRow(firstTrain).getInt("time")) {
    wait = true;
    boolean breakr = false;
    for (firstTrain = 0; firstTrain < tableSize && !breakr; firstTrain++) {
      if (trainTable.getRow(firstTrain).getInt("time") > minute()) {
        breakr = true;
      }
    }
  }

  for (int i = 0; i < 7; i++) {
    String[] trainText = new String[5];
    int time = trainTable.getRow((firstTrain+i)%tableSize).getInt("time");
    int hour = hour();
    if (time < minute()) hour+= 1;
    trainText[0] = String.format("%02d", hour) + ":" + String.format("%02d", time);
    trainText[1] = trainTable.getRow((firstTrain+i)%tableSize).getString("destination");
    trainText[2] = trainTable.getRow((firstTrain+i)%tableSize).getString("stops");
    trainText[3] = trainTable.getRow((firstTrain+i)%tableSize).getString("rail");

    trainText[4] = trainTable.getRow((firstTrain+i)%tableSize).getString("train");
    //printArray(trainText);

    textFont(AllerBold);
    textSize(trainSize);
    text(trainText[0], column[0], border+trainRow*(i+.8));
    text(trainText[1], column[1], border+trainRow*(i+.8));
    textFont(Aller);
    textSize(subTrainSize);
    text(trainText[2], column[1], border+trainRow*(i+1.2)); 
    textFont(AllerBold);
    textSize(trainSize);
    textAlign(CENTER, CENTER);
    text(trainText[3], column[2]+(.25*(column[3]-column[2])), border+trainRow*(i+1)-trainSize*.11); 
    textAlign(LEFT, CENTER);
    textFont(Aller);
    textSize(trainSize);
    text(trainText[4], column[3], border+trainRow*(i+1));
  }
}

void applyScreenSize() {
  /////////** SEE DESIGN IN RESOURCES FOLDER **/////////

  //posTitle,posYear,posStars,posSubtext,posPlay,posScroll,posExit,posUp,posDown,posLogo,posRow1,posRow2,posRow3,posGenre1,posGenre2,posGenre3;
  //sizeTitle,sizeYear,sizeStars,sizeSubtext,sizePlay,sizeScroll,sizeExit,sizeUp,sizeDown,sizeLogo,sizeRow1,sizeRow2,sizeRow3,sizeGenre1,sizeGenre2,sizeGenre3;
  float H = height;
  border = .08*H;
  float W = width - (2*border);

  trainRow = .112*H;
  column[0] = border+.022*W;
  column[1] = column[0]+.116*W;
  column[2] = column[1]+.533*W;
  column[3] = column[2]+.106*W;
  column[4] = column[3]+.09*W;
  columnTime = .111*W;
  updateRow = trainRow/2.5;

  headerSize = trainRow/4;
  trainSize = trainRow/3;
  subTrainSize = trainRow/5;

  logoHeight = border*0.5;
  logoWidth = logoHeight/logo.height*logo.width;
  logoPosX = width-border/3-logoWidth/2;
  logoPosY = H-border/2;

  TARGET_SIZE = trainRow/10;
}

void drawBorder() {
  fill(WTborder);
  rect(0, 0, border, height);
  rect(0, 0, width, border);
  rect(0, height-border, width, height);
  rect(width-border, 0, width, height);
  imageMode(CENTER);
  image(logo, logoPosX, logoPosY, logoWidth, logoHeight);
}

void drawClock() {
  noFill();
  float clockx = column[4]+trainRow*.25;
  float clocky =  border+trainRow * .25;
  float m = map(minute() + norm(second(), 0, 60), 0, 60, 0, TWO_PI) - HALF_PI;
  float h = map(hour() + norm(minute(), 0, 60), 0, 24, 0, TWO_PI * 2) - HALF_PI;
  stroke(255);
  strokeWeight(headerSize/10);
  ellipseMode(RADIUS);
  ellipse(clockx, clocky, trainRow*.15, trainRow*.15);
  strokeWeight(headerSize/12);
  stroke(240);
  line(clockx, clocky, clockx + cos(m) * trainRow*.11, clocky + sin(m) * trainRow*.11);
  stroke(230);
  strokeWeight(headerSize/11);
  line(clockx, clocky, clockx + cos(h) * trainRow*.07, clocky + sin(h) * trainRow*.07);

  noStroke();
}