void drawSTATE0() {

  if (withWatch) {
    if (!demoPaused)
    {
      nextSTATE = 1;
      animate_1 = true;
    }
  }
  background(0);
  textAlign(CENTER, CENTER);
  fill(255, 150);
  textFont(AllerFont);
  textSize(userTitleSize);
  text("Flick Wrist to Start", CENTERX, CENTERY);

  runStudy();
  fill(255);
  imageMode(CENTER);
  float logoWidth = sizeLogo/logo.height*logo.width;
  image(logo, 2*CENTERX-(posExit+(logoWidth/2)), posExit, logoWidth, sizeLogo);
}

void drawSTATE1() {
  if (withWatch) {
    if (demoPaused)
    {
      nextSTATE = -1;
      animate_1 = true;
    }
  }
  background(0);
  textAlign(CENTER);

  fill(255);
  textFont(AllerDisplay);
  textSize(titleSize);
  text("Who's Watching?", width/2, height/3);

  runStudy();
  fill(255);
  imageMode(CENTER);
  float logoWidth = sizeLogo/logo.height*logo.width;
  image(logo, 2*CENTERX-(posExit+(logoWidth/2)), posExit, logoWidth, sizeLogo);

  tint(255, 255);
  textFont(AllerFont);
  textSize(userTitleSize);
  image(user1, posUser1, height/2, userSize, userSize);
  text("user1", posUser1, height/2+userSize);
  image(user2, posUser2, height/2, userSize, userSize);
  text("user2", posUser2, height/2+userSize);
  image(user3, posUser3, height/2, userSize, userSize);
  text("user3", posUser3, height/2+userSize);
  image(user4, posUser4, height/2, userSize, userSize);
  text("user4", posUser4, height/2+userSize);
}

void drawSTATE2() {
  if (withWatch) {
    if (demoPaused)
    {
      nextSTATE = -2;
      animate_1 = true;
    }
  }
  fill(0);
  noStroke();
  rectMode(CORNER);
  rect(0, posRow2-(sizeRow2/2)-1, width, sizeRow2+2);  
  ellipse(CENTERX, posScroll, sizeScroll+(height/45), sizeScroll+(height/45));
  if (newSelectedID != selectedID && !animate_2) {
    fill(0);
    rect(0, 0, width, posTitleImage+2);
    showSelectedSerie();
    selectedID = newSelectedID;
  }    
  noFill();
  stroke(255);
  strokeWeight(4);
  ellipse(CENTERX, posScroll, sizeScroll, sizeScroll);
  drawSeries();
  noFill();
  stroke(255, 100);
  strokeWeight(4);
  ellipse(CENTERX, posScroll, sizeScroll, sizeScroll);
  runStudy();
  tint(255, 255);
  image(up, CENTERX, posUp, sizeUp, sizeUp);
  image(down, CENTERX, posDown, sizeDown, sizeDown);
  image(play, distLeft+sizePlay/2, posPlay, sizePlay, sizePlay);
  image(exit, width-posExit, posExit, sizeExit, sizeExit);
}

void drawSTATE3() {
  if (scroll_series != 0) {
    if (movieRunning) runMovie.pause();
    scroll_video += scroll_series;
    scroll_series = 0;
    prev_scroll_video = millis();
  }   
  if (prev_scroll_video != 0) {      // a scroll has occured
    if (millis() - prev_scroll_video > scroll_video_thres) {
      runMovie.pause();
      float jumping = constrain(runMovie.time()+scroll_video, 0, runMovie.duration());
      runMovie.jump(jumping);
      if (movieRunning) runMovie.play();
      scroll_video = 0;
      prev_scroll_video = 0;
    }
  }
  background(0);
  imageMode(CENTER);
  tint(255, 255);
  image(runMovie, CENTERX, CENTERY);
  runMovie.volume(volume);
  if (menuToggle || menuToggleCounter<menuToggleCounterInit-1) {
    if (menuToggle) menuToggleCounter = constrain(menuToggleCounter-=15, 0, menuToggleCounterInit);
    else menuToggleCounter = constrain(menuToggleCounter+=15, 0, menuToggleCounterInit);
    pushMatrix();
    translate(0, -menuToggleCounter/3);

    rectMode(CORNER);
    fill(0, 150);
    rect(0, 0, width, 2*posExit);
    popMatrix();

    pushMatrix();
    translate(0, menuToggleCounter);
    float dur = runMovie.duration();
    float movietime = constrain(runMovie.time()+scroll_video, 0, dur);
    float progTime = movietime/dur*widthProg+(CENTERX-.5*widthProg);
    long movieTime = (long)movietime;
    //println(movieTime);     
    long hours = TimeUnit.SECONDS.toHours(movieTime);
    long minute = TimeUnit.SECONDS.toMinutes(movieTime) - (TimeUnit.SECONDS.toHours(movieTime)* 60);
    long second = TimeUnit.SECONDS.toSeconds(movieTime) - (TimeUnit.SECONDS.toMinutes(movieTime) *60);
    String displayTime = String.format("%02d:%02d:%02d", hours, minute, second);
    rectMode(CORNER);
    fill(0, 150);
    rect(0, posMenu-sizeScroll2/2-20, width, height);

    float logoWidth = sizeDolby/soundIcon.height*soundIcon.width;
    image(soundIcon, posDolby, posMenu, logoWidth, sizeDolby); 

    image(volumeIcon, posVol, posMenu, sizeVol, sizeVol); 

    noFill();
    stroke(100);
    strokeWeight(strokeVol*.95);
    ellipse(posVol, posMenu, sizeVol, sizeVol);
    stroke(0, 161, 131);
    strokeWeight(strokeVol);
    arc(posVol, posMenu, sizeVol, sizeVol, 0, (float)(volume*TWO_PI));

    textAlign(CENTER, CENTER);
    fill(0);
    textFont(AllerFont);
    textSize(sizeVolText);
    text((int) (volume*100), posVol, posMenu-.20*sizeVolText);

    noFill();
    stroke(255);
    strokeWeight(4);
    ellipse(CENTERX, posMenu, sizeScroll2, sizeScroll2);

    stroke(100);
    strokeWeight(sizeProg);
    strokeCap(ROUND);
    line(CENTERX-.5*widthProg, posMenu, CENTERX+.5*widthProg, posMenu);
    stroke(150);
    strokeWeight(sizeInnerProg);
    line(CENTERX-.5*widthProg, posMenu, progTime, posMenu);
    noStroke();
    fill(0, 161, 131);
    ellipse(progTime, posMenu, sizeProgPoint, sizeProgPoint);
    strokeCap(SQUARE);

    noFill();
    stroke(255, 100);
    strokeWeight(4);
    ellipse(CENTERX, posMenu, sizeScroll2, sizeScroll2);

    textAlign(CENTER, CENTER);
    fill(255);
    textFont(AllerFont);
    textSize(sizeTime);
    text(displayTime, CENTERX, posMenu-(.20*sizeTime));

    if (prev_scroll_video != 0) {    // if scrolling through time
      textFont(AllerDisplay);
      textSize(sizeTime*5);
      text(displayTime, CENTERX, CENTERY);
    }


    runStudy();

    if (movieRunning) image(pause, posPlay2, posMenu, sizePlay2, sizePlay2);
    else image(play, posPlay2, posMenu, sizePlay2, sizePlay2);

    popMatrix();
    pushMatrix();
    translate(0, -menuToggleCounter/3);
    float logoWidth2 = sizeLogo/logo.height*logo.width;
    image(logo, 2*CENTERX-(posExit*3.5+(logoWidth2/2)), posExit, logoWidth2, sizeLogo);
    image(userSelected, 2*CENTERX-(posExit*2.5), posExit, sizeExit*1.7, sizeExit*1.7);
    image(exit, width-posExit, posExit, sizeExit, sizeExit);
    popMatrix();
  }
}

void drawSTATEtransition() {
  if (animate_1)
  {
    fill(0, alpha);
    rectMode(CORNER);
    rect(0, 0, width, height);
    alpha+=15;
    if (alpha>255) {
      animate_1 = false;
      switchState(nextSTATE);
      nextSTATE = 0;
      alpha = 0;
    }
  }
  /*
  if (animate_2)
   {
   
   fill(0, alpha);
   rectMode(CORNER);
   rect(0, 0, width, height);
   alpha-=15;
   if (alpha<0) {
   animate_2 = false;
   alpha = 0;
   }
   }*/
}

void applyScreenSize() {
  /////////** SEE DESIGN IN RESOURCES FOLDER **/////////

  //posTitle,posYear,posStars,posSubtext,posPlay,posScroll,posExit,posUp,posDown,posLogo,posRow1,posRow2,posRow3,posGenre1,posGenre2,posGenre3;
  //sizeTitle,sizeYear,sizeStars,sizeSubtext,sizePlay,sizeScroll,sizeExit,sizeUp,sizeDown,sizeLogo,sizeRow1,sizeRow2,sizeRow3,sizeGenre1,sizeGenre2,sizeGenre3;
  float H = height;
  float W = width;

  // MENU 1
  userSize = W/10;
  posUser1 = CENTERX-1.8*userSize;
  posUser2 = CENTERX-.6*userSize;
  posUser3 = CENTERX+.6*userSize;
  posUser4 = CENTERX+1.8*userSize; 
  titleSize = W/16.8;
  userTitleSize = W/56;

  /// MENU 2
  NR_SERIES = 4;

  distLeft = 0.06*H;
  distSerie = 0.01*H;
  TARGET_SIZE = H/1800 * PPCM;

  // COLOR: 0, 161, 131

  // TARGETS
  posPlay = 0.5*H;
  sizePlay = 0.07*H;
  posScroll = 0.8*H;
  sizeScroll = 0.15*H;
  posUp = posScroll - 0.14*H;
  sizeUp = 0.06*H;
  posDown = posScroll + 0.14*H;
  sizeDown = sizeUp;
  posExit = 0.048*H;
  sizeExit = 0.034*H;

  // SELECTED SERIE
  posTitleImage = 0.6*H;
  posTitle = 0.057*H;
  sizeTitle = 0.07*H;
  posYear = 0.132*H;
  sizeYear = 0.035*H;
  posStars = 0.187*H;
  sizeStars = 0.03*H;
  posSubtext = 0.22*H;
  sizeSubtext = 0.02*H;
  sizeLogo = 0.034*H;

  // SERIES
  posRow2 = posScroll;
  sizeRow2 = 0.1*H;
  posRow1 = posRow2-0.14*H;
  sizeRow1 = sizeRow2;
  posRow3 = posRow2+0.14*H;
  sizeRow3 = sizeRow2;
  posGenre1 = posRow1 - 0.08*H;
  sizeGenre1 = 0.0213*H;
  posGenre2 = posRow2 - 0.08*H;
  sizeGenre2 = sizeGenre1;
  posGenre3 = posRow3 - 0.08*H;
  sizeGenre3 = sizeGenre1;
  widthRow = 48f/27f*sizeRow1;

  size_series = NR_SERIES*widthRow + (NR_SERIES-1)*distSerie;  // size series box + margin (1 less)

  // MENU 3
  sizeScroll2 = 0.15*H;
  sizeProg = .03*H;
  sizeInnerProg = sizeProg-4;
  sizeProgPoint = sizeInnerProg;
  sizeVol= 0.095*H;
  sizeVolText = 0.013*H/1.5;
  sizePlay2 = .07*H;
  sizeDolby = .025*H;
  sizeTime = .034*H/1.5;
  widthProg = W/2;
  posDolby = (.75 + .086) *W;
  posVol = (.25 - .06) * W;
  posPlay2 = (.25 - .12) * W;
  strokeVol = .008*H;
  posMenu = H-sizeScroll2/2-20;
  volume = .6;

  menuToggleCounter = .264*H;
  menuToggleCounterInit = menuToggleCounter;
}

void loadImages() {
  user1 = loadImage("assets/user-01.png");
  user2 = loadImage("assets/user-02.png");
  user3 = loadImage("assets/user-03.png");
  user4 = loadImage("assets/user-04.png");
  userSelected = user1;
  maskImage = loadImage("assets/alpha.png");
  up = loadImage("assets/up.png");
  down = loadImage("assets/down.png");
  play = loadImage("assets/play.png");
  pause = loadImage("assets/pause.png");
  exit = loadImage("assets/exit.png");
  logo = loadImage("assets/LOGO.png");
  volumeIcon = loadImage("assets/volume.png");
  soundIcon = loadImage("assets/dolby.png"); 

  maskImage.resize(ceil(posTitleImage/maskImage.height*maskImage.width), ceil(posTitleImage));
}
