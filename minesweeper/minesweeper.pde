class Tile {
  int px, py;
  float w;
  int bombs;
  float state;

  public Tile(int px, int py, float w, int bombs) {
    this.px = px;
    this.py = py;

    this.w = w;
    this.state = 0;
    this.bombs = bombs;
  }

  public void flagged() {
    if (state == 1) {
      state = 0;
    } else {
      state = 1;
    }
  }
  public void displayed() {
    state = 2;
  }

  private int[][] makeStates() {
    // create a template for the numbers in the tiles
    int[][] states = new int[totTiles][totTiles];
    for (int numBomb = 0; numBomb < totBombs; numBomb++) {
      int bombx = (int)random(states.length);
      int bomby = (int)random(states[0].length);
      states[bombx][bomby] = -1;
      while ((bombx == px && bomby == py) || checkBombs(px, py, states) != 0) {
        states[bombx][bomby] = 0;
        bombx = (int)random(states.length);
        bomby = (int)random(states[0].length);
        states[bombx][bomby] = -1;
      }
    }
    return states;
  }
  /*
  When mouse button is released, mouseButton is not reset immediately, and will take ~3/20 seconds to reset. Therefore,
   the draw function may be called multiple times while the mouseButton is not zero.
   */
  public void clicked() {
    float x = px * width / totTiles;
    float y = py * height / totTiles;
    boolean meetingX = mouseX > x && mouseX < x + w;
    boolean meetingY = mouseY > y && mouseY < y + w;
    if (mousePressed && meetingX && meetingY) {
      if (mouseButton == RIGHT && tiles[px][py].state != 2) {
        flagged();
        mouseButton = 0;
        mousePressed = false;
      } else if (tiles[px][py].state != 1) {
        if (firstClick) {
          firstClick = false;
          int[][] states = makeStates();
          for (int stateX = 0; stateX < states.length; stateX++) {
            for (int stateY = 0; stateY < states[0].length; stateY++) {
              if (states[stateX][stateY] == -1) {
                continue;
              }
              states[stateX][stateY] = checkBombs(stateX, stateY, states);
            }
          }
          for (int statex = 0; statex < tiles.length; statex++) {
            for (int statey = 0; statey < tiles[0].length; statey++) {
              tiles[statex][statey].bombs = states[statex][statey];
            }
          }
        }
        displayed();
        boolean[][] seen = new boolean[totTiles][totTiles];
        reveal(px, py, seen);
        mouseButton = 0;
        mousePressed = false;
      }
    }
  }

  public void display() {
    float x = px * width / totTiles;
    float y = py * height / totTiles;
    fill(255);
    square(x, y, w);
    fill(0);
    float displayX = x + w / 2;
    float displayY = y + 5 * w / 6;
    if (state == 1) {
      PImage flag = loadImage("flag.png");
      image(flag,x,y,w,w);
    }
    if (state == 2 && bombs != -1) {
      fill(225);
      square(x, y, w);
      fill(colors[bombs]);
      text(bombs, displayX, displayY);
    }
    if (state == 2 && bombs == -1) {
      fill(255, 0, 0);
      square(x, y, w);
      PImage mine = loadImage("mine.png");
      image(mine,x,y,w,w);
      dead = true;
    }
  }
  void won() {
    float x = px * width / totTiles;
    float y = py * height / totTiles;
    if (bombs != -1) {
      fill(135,206,235);
      square(x,y,w); 
    } else {
      PImage flower = loadImage("flower.png");
      image(flower,x,y,w,w);
    }
  }
}

Tile[][] tiles;
color[] colors = new color[]{color(225), color(0, 0, 255), color(0, 255, 0), color(255, 255, 0), color(160, 32, 240), color(255, 183, 197), color(255), color(100), color(200)};
boolean dead;
boolean firstClick;
int totTiles;
int totBombs;
String username;
boolean won;
String difficulty;
String time;
int debug = 0;

void setup() {
  firstClick = true;
  dead = false;
  won = false;
  frameCount = 0;
  size(1000, 1000);
  background(200);

  // outside parameters
  brc();

  if (brcValue("difficulty").equals("E")) {
    totTiles = 9;
    totBombs = 10;
    difficulty = "Easy";
  } else if (brcValue("difficulty").equals("M")) {
    totTiles = 16;
    totBombs = 40;
    difficulty = "Medium";
  } else if (brcValue("difficulty").equals("H")) {
    totTiles = 20;
    totBombs = 150;
    difficulty = "Hard";
  } else if (brcValue("difficulty").equals("I")) {
    totTiles = 30;
    totBombs = 400;
    difficulty = "Insane";
  } else {
    totTiles = int(brcValue("size"));
    totBombs = int(brcValue("mines"));
    difficulty = "Custom";
  }
  
  brcSetMonitor("flags",totBombs);

  // initialize the tiles
  tiles = new Tile[totTiles][totTiles];
  for (int x = 0; x < tiles.length; x++) {
    for (int y = 0; y < tiles[0].length; y++) {
      tiles[x][y] = new Tile(x, y, width / totTiles, 0);
    }
  }

  // initialize the font
  PFont font = createFont("arial", width / totTiles);
  textFont(font);
  textAlign(CENTER);

  String[] easyLeaderboard = loadStrings("Easy.txt");
  String[] mediumLeaderboard = loadStrings("Medium.txt");
  String[] hardLeaderboard = loadStrings("Hard.txt");
  String[] insaneLeaderboard = loadStrings("Insane.txt");
  if (easyLeaderboard.length > 0) {
    brcSetMonitor("pbe", easyLeaderboard[0]);
  }
  if (easyLeaderboard.length == 0) {
    brcSetMonitor("pbe", "No Personal Best on Record");
  }
  if (mediumLeaderboard.length > 0) {
    brcSetMonitor("pbm", mediumLeaderboard[0]);
  }
  if (mediumLeaderboard.length == 0) {
    brcSetMonitor("pbm", "No Personal Best on Record");
  }
  if (hardLeaderboard.length > 0) {
    brcSetMonitor("pbh", hardLeaderboard[0]);
  }
  if (hardLeaderboard.length == 0) {
    brcSetMonitor("pbh", "No Personal Best on Record");
  }
  if (insaneLeaderboard.length > 0) {
    brcSetMonitor("pbi", insaneLeaderboard[0]);
  }
  if (insaneLeaderboard.length == 0) {
    brcSetMonitor("pbi", "No Personal Best on Record");
  }
}
void draw() {
  if (won) {
    for (int i = 0; i < tiles.length; i++) {
      for (int j = 0; j < tiles[0].length; j++) {
        tiles[i][j].won();
      }
    }
    brc();
    String changed = brcChanged();
    if (changed.equals("restart")) {
      setup();
    }
    return;
  }
  brc();
  String changed = brcChanged();
  if (changed.equals("restart")) {
    setup();
  }
  int seconds = (int)(frameCount/60);
  int minutes = (int)seconds / 60;
  seconds = seconds % 60;
  int hours = minutes / 60;
  minutes = minutes % 60;
  time = hours + ":" + minutes + ":" + seconds;
  brcSetMonitor("time", time);

  if (dead) {
    for (int px = 0; px < tiles.length; px++) {
      for (int py = 0; py < tiles.length; py++) {
        tiles[px][py].state = 2;
        tiles[px][py].display();
      }
    }
    return;
  }

  // reset is an outside variable
  boolean reset = false;
  if (reset) {
    setup();
  }
  int numFlagged = 0;
  // flagging is an outside variable
  boolean flagging = false;

  int tilesFound = 0;
  for (int posX = 0; posX < tiles.length; posX++) {
    for (int posY = 0; posY < tiles.length; posY++) {
      tiles[posX][posY].clicked();
      if (tiles[posX][posY].state == 1) {
        numFlagged++;
      }
      if (tiles[posX][posY].state == 2) {
        tilesFound++;
      }
      tiles[posX][posY].display();
    }
  }
  brcSetMonitor("flags", totBombs - numFlagged);

  if (tilesFound == totTiles * totTiles - totBombs) {
    PFont font = createFont("arial", 50);
    textFont(font);
    textAlign(0);
    background(200);
    text("Congradulations for beating a ", 200, 200);
    text(difficulty + " minesweeper game. ", 200,300);
    text("Time taken to beat: " + time, 200, 400);
    boolean place = checkNewRecord(time);
    if (place) {
      text("New Record for " + difficulty + " difficulty.", 200, 500);
    }
    won = true;
  }
}

boolean checkNewRecord(String time) {
  if (difficulty.equals("Custom")) {
    return false;
  }
  String[] ar = loadStrings(difficulty + ".txt");
  PrintWriter output = createWriter(difficulty + ".txt");
  String[] newAr = {time};
  if (ar.length <= 0) {
    output.println(newAr[0]);
    output.flush();
    output.close();
    return true;
  }
  if (time.compareTo(ar[0]) < 0) {
    newAr[0] = time;
    output.println(newAr[0]);
    output.flush();
    output.close();
    return true;
  } else {
    output.println(ar[0]);
    output.flush();
    output.close();
    return false;
  }
}

public void reveal(int posX, int posY, boolean[][] seen) {
  seen[posX][posY] = true;
  if (tiles[posX][posY].bombs == 0) {
    tiles[posX][posY].state = 2;
    if (posX - 1 >= 0 && !seen[posX-1][posY]) {
      reveal(posX-1, posY, seen);
    }
    if (posY - 1 >= 0 && !seen[posX][posY - 1]) {
      reveal(posX, posY-1, seen);
    }
    if (posX + 1 < tiles.length && !seen[posX + 1][posY]) {
      reveal(posX + 1, posY, seen);
    }
    if (posY + 1 < tiles.length && !seen[posX][posY + 1]) {
      reveal(posX, posY + 1, seen);
    }
    if (posX + 1 < tiles.length && posY + 1 < tiles.length && !seen[posX + 1][posY + 1]) {
      reveal(posX + 1, posY + 1, seen);
    }
    if (posX - 1 >= 0 && posY - 1 >= 0 && !seen[posX - 1][posY - 1]) {
      reveal(posX-1, posY-1, seen);
    }
  } else if (tiles[posX][posY].bombs != -1) {
    tiles[posX][posY].state = 2;
  }
}

public int checkBombs(int posX, int posY, int[][] states) {
  int bombs = 0;
  if (posX - 1 >= 0 && states[posX - 1][posY] == -1) {
    bombs++;
  }
  if (posY - 1 >= 0 && states[posX][posY - 1] == -1) {
    bombs++;
  }
  if (posX + 1 < states.length && states[posX + 1][posY] == -1) {
    bombs++;
  }
  if (posY + 1 < states.length && states[posX][posY + 1] == -1) {
    bombs++;
  }
  if (posX + 1 < states.length && posY + 1 < states.length && states[posX + 1][posY + 1] == -1) {
    bombs++;
  }
  if (posX - 1 >= 0 && posY - 1 >= 0 && states[posX - 1][posY - 1] == -1) {
    bombs++;
  }
  if (posX + 1 < states.length && posY - 1 >= 0 && states[posX + 1][posY - 1] == -1) {  
    bombs++;
  }
  if (posX - 1 >= 0 && posY + 1 < states.length && states[posX-1][posY+1] == -1) {
    bombs++;
  }
  return bombs;
}
