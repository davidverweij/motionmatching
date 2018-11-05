void iniSeries() {
  nr_rows = series_row.size();
  for (int u = 0; u < nr_rows; u++) {
    float y_pos=0;
    switch(u) {
    case 0:
      y_pos = posRow1;
      break;
    case 1:
      y_pos = posRow2;
      break;
    case 2:
      y_pos = posRow3;
      break;
    default:
      break;
    } 

    for (int i = 0; i < NR_SERIES; i++) {
      series_row.get(u).get(i).set_param(CENTERX-(size_series/2)+widthRow/2+(i*(widthRow+distSerie)), y_pos, widthRow, sizeRow1 );
      //series_row.get(u).get(i).set_scroll(0);
    }
  }
}
void adjustSeries(int up_down) {
  if (up_down ==1 || up_down == -1) {      // switch row!
    background(0);
    int nr_rows = series_row.size();
    ArrayList<Serie> moveList;
    if (up_down == 1) {                        //move last row to first
      moveList = series_row.get(nr_rows-1);
      series_row.remove(nr_rows-1);
      series_row.add(0, moveList);
    } else {                                   // move first row to last
      moveList = series_row.get(0);
      series_row.add(moveList);
      series_row.remove(0);
    }
    for (int u = 0; u < nr_rows; u++) {
      float y_pos = 0;
      switch(u) {
      case 0:
        y_pos = posRow1;
        break;
      case 1:
        y_pos = posRow2;
        break;
      case 2:
        y_pos = posRow3;
        break;
      default:
        break;
      } 
      for (int i = 0; i < NR_SERIES; i++) {
        series_row.get(u).get(i).set_param(false, y_pos, widthRow, sizeRow1);
        if (u!=1) series_row.get(u).get(i).draw(.3);
      }
    }
    fill(255);
    noStroke();
    textAlign(LEFT, TOP);
    textSize(sizeGenre2);
    text(series_row.get(0).get(0).get_genre(), distLeft, posGenre1);
    text(series_row.get(1).get(0).get_genre(), distLeft, posGenre2);
    text(series_row.get(2).get(0).get_genre(), distLeft, posGenre3);
  } else if (up_down == 0) {             // update main row!
    int nr_series = series_row.get(1).size();
    for (int i = 0; i < nr_series; i++) {
      boolean selectedS = series_row.get(1).get(i).set_scroll(scroll_series);
      if (selectedS) {
        newSelectedID = series_row.get(1).get(i).get_ID();
        if (newSelectedID != selectedID) {
          selectedSerie = series_row.get(1).get(i);
          //println("new serie!");
        }
      }
    }
    scroll_series = 0;
    if (series_row.get(1).get(0).get_pos()[0]>CENTERX-size_series/3) {
      //println("1st if off charts!! , pos SERIE = ");
      Serie index = series_row.get(1).get(nr_series-1);
      index.set_param(series_row.get(1).get(0).get_pos()[0]-distSerie-widthRow, posRow2, widthRow, sizeRow2);
      series_row.get(1).remove(nr_series-1);
      series_row.get(1).add(0, index);
    } else if (series_row.get(1).get(NR_SERIES-1).get_pos()[0]<CENTERX+size_series/3) {
      //println("last if off charts!! , pos_series = ");
      Serie index = series_row.get(1).get(0);
      index.set_param(series_row.get(1).get(nr_series-1).get_pos()[0]+distSerie+widthRow, posRow2, widthRow, sizeRow2);
      series_row.get(1).remove(0);
      series_row.get(1).add(index);
    }
  } else if (up_down == -9) {
    for (int u = 0; u < nr_rows; u++) {
      float y_pos = 0;
      switch(u) {
      case 0:
        y_pos = posRow1;
        break;
      case 1:
        y_pos = posRow2;
        break;
      case 2:
        y_pos = posRow3;
        break;
      default:
        break;
      } 
      for (int i = 0; i < NR_SERIES; i++) {
        series_row.get(u).get(i).set_param(false, y_pos, widthRow, sizeRow1);
        if (u!=1) series_row.get(u).get(i).draw(.3);
        else {
          boolean selectedS = series_row.get(1).get(i).set_scroll(scroll_series);
          if (selectedS) {
            newSelectedID = series_row.get(1).get(i).get_ID();
            if (newSelectedID != selectedID) {
              selectedSerie = series_row.get(1).get(i);
            }
          }
        }
      }
      fill(255);
      noStroke();
      textAlign(LEFT, TOP);
      textSize(sizeGenre2);
      text(series_row.get(0).get(0).get_genre(), distLeft, posGenre1);
      text(series_row.get(1).get(0).get_genre(), distLeft, posGenre2);
      text(series_row.get(2).get(0).get_genre(), distLeft, posGenre3);
    }
  } else {
    println("error, received invalid operation AdjustSeries()");
  }
}

void showSelectedSerie() {
  //PImage drawImage = selectedSerie.get_preview();
  //drawImage.mask(maskImage);
  imageMode(CORNER);
  fill(0);
  noStroke();

  rect(0, 0, width, posTitleImage+1);
  tint(255, 255);
  //image(drawImage, 0, 0,   posTitleImage/drawImage.height*drawImage.width, posTitleImage);
  image(selectedSerie.get_preview(), 0, 0);
  imageMode(CENTER);
  textFont(AllerDisplay);
  fill(255);
  textAlign(LEFT, TOP);
  textSize(sizeTitle);
  fill(255);
  text(selectedSerie.get_title(), distLeft, posTitle);
  textFont(AllerFont);
  textSize(sizeYear);
  text(selectedSerie.get_year(), distLeft, posYear);
  noStroke();
  for (int q = 0; q <5; q++) {
    if (q<selectedSerie.get_stars()) {
      fill(0, 161, 131);
    } else {
      fill(255);
    }
    star(distLeft+sizeStars/2 + q*(1.5*sizeStars), posStars+sizeStars/3, sizeStars/5, sizeStars/2, 5);
  }
  fill(255);
  textSize(sizeSubtext);
  text(selectedSerie.get_subtext(), distLeft, posSubtext);

  float logoWidth = sizeLogo/logo.height*logo.width;
  image(logo, 2*CENTERX-(posExit*3.5+(logoWidth/2)), posExit, logoWidth, sizeLogo);
  image(userSelected, 2*CENTERX-(posExit*2.5), posExit, sizeExit*1.7, sizeExit*1.7);

  fill(255);
  noStroke();
  textAlign(LEFT, TOP);
  textSize(sizeGenre2);
  text(series_row.get(0).get(0).get_genre(), distLeft, posGenre1);
}

void drawSeries() {
  adjustSeries(0);    //dont change row, update main row
  int nr_series = series_row.get(1).size();
  imageMode(CENTER);
  for (int i = 0; i < nr_series; i++) {
    series_row.get(1).get(i).draw(1);
  }
}

void loadSeries() {

  series_row = new ArrayList<ArrayList<Serie>>();

  for (int i = 0; i < 3; i++) {
    ArrayList<Serie> tempRow = new ArrayList<Serie>();
    series_row.add(tempRow);
  }

  String prefix0 = "movies/Topic1/Topic1";
  String prefix1 = "movies/Topic2/Topic2";
  String prefix2 = "movies/Topic3/Topic3";
  String mp4 = ".mp4";
  String txt = ".txt";
  String suffixP = "_preview.jpg";
  String suffixT = "_thumb.jpg";
  String[] genre = {"Topic 1 - Something", "Topic 2 - Something 2", "Topic 3 - Something 3"};

  //Topic

  for (int i = 0; i < NR_SERIES; i++) {
    series_row.get(0).add(new Serie(0+i, prefix0 + i + mp4, prefix0 + i + suffixP, prefix0 + i + suffixT, prefix0 + i + txt, genre[0]));
  }

  //Topic 2

  for (int i = 0; i < NR_SERIES; i++) {
    series_row.get(1).add(new Serie(100+i, prefix1 + i + mp4, prefix1 + i + suffixP, prefix1 + i + suffixT, prefix1 + i + txt, genre[1]));
  }


  // Topic 3

  for (int i = 0; i < NR_SERIES; i++) {
    series_row.get(2).add(new Serie(200+i, prefix2 + i + mp4, prefix2 + i + suffixP, prefix2 + i + suffixT, prefix2 + i + txt, genre[2]));
  }
}

public class Serie {

  private PImage thumb, preview;
  private String locMovie, locPreview, locThumb, locTxt;
  private float x, y, w, h;    // x, y , width, height
  private String title, subtext, year, genre;
  private int stars, ID;
  private Movie thisMovie;

  public Serie (int _ID, String _locMovie, String _locPreview, String _locThumb, String _locTxt, String _genre) {  // constructor
    ID = _ID;
    locMovie = _locMovie;
    locPreview = _locPreview;
    locThumb = _locThumb;
    locTxt = _locTxt;
    genre = _genre;

    String lines[] = loadStrings(locTxt);
    title = lines[0];
    year = lines[1];
    stars = parseInt(lines[2]);
    subtext = "";
    for (int i = 3; i < lines.length; i++) {
      if (i!=3) subtext += "\n";
      subtext += lines[i];
    }
    thumb = loadImage(locThumb);
    preview = loadImage(locPreview);
    preview.resize(ceil(posTitleImage/preview.height*preview.width), ceil(posTitleImage));
    preview.mask(maskImage);
    thisMovie = new Movie(thisGlobal, locMovie);
  }

  public PImage get_thumb () {
    return thumb;
  }

  public int get_ID() {
    return ID;
  }

  public float[] get_pos () {
    float[] x_y =   {x, y};
    return x_y;
  }

  public PImage get_preview () {
    return preview;
  }

  public Movie get_movie () {
    return thisMovie ;
  }

  public String get_loc() {
    return locMovie;
  }

  public String get_title () {
    return title;
  }

  public String get_year() {
    return year;
  }

  public int get_stars() {
    return stars;
  }

  public String get_subtext() {
    return subtext;
  }

  public boolean set_scroll (float _scroll) {
    x = x + _scroll;
    return selected(CENTERX, posRow2, distSerie);
  }

  public String get_genre() {
    return genre;
  }

  public void set_param(float _x, float _y, float _w, float _h) {
    x = _x;
    y = _y;
    w = _w;
    h = _h;
  }

  public void set_param(boolean _no_x, float _y, float _w, float _h) {               
    y = _y;
    w = _w;
    h = _h;
  }

  public float[] get_size() {
    float[] w_h = {w, h};
    return w_h;
  }

  public void draw(float opacity) {
    tint(255, opacity*255);
    image(thumb, x, y, w, h);
  }

  public boolean selected(float _x, float _y, float _margin) {
    if (_x >= x -.5*w-_margin && _x< x +.5*w-_margin) {
      return true;
    }
    return false;
  }
}

void star(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle/2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a+halfAngle) * radius1;
    sy = y + sin(a+halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}
