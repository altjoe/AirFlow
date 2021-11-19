import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class AirFlow extends PApplet {

ArrayList<BlackHole> holes = new ArrayList<BlackHole>();
ArrayList<BulletLine> lines = new ArrayList<BulletLine>();
Recording record;
public void setup() {
    
    background(255);

    BlackHole hole = new BlackHole(width/3, height/3, 200);
    holes.add(hole);
    hole = new BlackHole(width/3, height*2/3, 100);
    holes.add(hole);
    hole = new BlackHole(width*2/3, height/3, 600);
    holes.add(hole);
    hole = new BlackHole(width*2/3, height*2/3, 400);
    holes.add(hole);

    float numlines = 200;
    for (int i = 0; i < numlines; i++){
        BulletLine line = new BulletLine(0, height*i/numlines);
        lines.add(line);
    }
    record = new Recording();
    record.start();
}

public void blackholes(int num){
    for (int i = 1; i <= num; i++){
        for (int j = 1; j <= num; j++){
            int range = PApplet.parseInt(random(1, 5)) * 75;
            BlackHole hole = new BlackHole(width*i/PApplet.parseFloat(num+1), height*j/PApplet.parseFloat(num+1), range);
            holes.add(hole);
        }
    }
}

int wavecount = 300;
int counter = 0;
boolean shooton = true;
int numwaves = 2;
int wave = 0;
public void draw() {
    background(255);
    translate(-width/2, 0);
    for (BlackHole hole : holes){
        hole.affectbullets();
        // hole.display();
    }

    for (BulletLine line : lines){
        if (shooton){
            if (line.previouslyoff){
                line.setframestostart();
                line.previouslyoff = false;
            }
            line.shoot();
        } else {
            line.previouslyoff = true;
        }
        
        line.move();
        line.display();
    }

    if (wavecount < counter){
        if (shooton){
            wavecount = 100;
            shooton = false;
        } else {
            wave += 1;
            // holes.removeAll(holes);
            // blackholes(int(random(2, 5)));
            wavecount = 500;
            if (wave < numwaves){
                shooton = true;
            }   
        }
        counter = 0;
    }
    counter += 1;
    record.control();
}


class BulletLine {
    ArrayList<Bullet> bullets = new ArrayList<Bullet>();
    PVector loc;
    float beforenext = 5;
    float framesbeforestart;
    boolean previouslyoff = false;
    public BulletLine(float x, float y){
        float distfrommiddle = abs(y - height/2) / (height/2);;
        framesbeforestart = 240 * distfrommiddle;
        loc = new PVector(x, y);
        // shootone();
    }

    public void shoot(){
        if (bullets.size() > 0){
             Bullet lastbullet = bullets.get(bullets.size()-1);
            Verlet lastptofbullet = lastbullet.pts.get(lastbullet.pts.size()-1);
            if (lastptofbullet.curr.x > loc.x + beforenext){
                shootone();
                beforenext = PApplet.parseInt(random(3, 10));
            }
        } else if (frameCount > framesbeforestart){
            shootone();
        }
       
    }

    public void setframestostart(){
        framesbeforestart += frameCount;
    }

    public void move(){
        for (Bullet bullet : bullets){
            bullet.move();
        }
    }

    public void shootone() {
        Bullet bullet = new Bullet(loc.x, loc.y);
        bullets.add(bullet);
    }

    public void display(){
        for (int i = bullets.size() -1; i >= 0; i--) {
            Bullet bullet = bullets.get(i);
            if (!bullet.finished){
                bullet.display();
            } else {
                bullets.remove(i);
            }
        }
    }
}

class Bullet {
    ArrayList<Verlet> pts = new ArrayList<Verlet>();
    int segsize = 2;
    int numsegs = PApplet.parseInt(random(5, 25));
    boolean starting = true;
    boolean finished = false;
    public Bullet(float x, float y){
        for (int i = 0; i < numsegs; i++){
            Verlet pt = new Verlet(x - segsize*i, y);
            pt.addforce(new PVector(2, 0));
            pts.add(pt);
        }
    }

    public void move(){
        for (Verlet pt : pts){
            pt.move();
        }
    }

    public void display(){
        Verlet pt1 = pts.get(0);
        Verlet pt2 = pts.get(pts.size()-1);
        if (onscreen(pt1.curr) || onscreen(pt2.curr)){
            starting = false;
            float ratio = (width - pt1.disttraveled) / width;
            float sw = ratio * 4;
            if (sw > 0){
                strokeWeight(sw);
            } else {
                strokeWeight(0);
            }
            
            noFill();
            beginShape();
            for (Verlet pt : pts){
                curveVertex(pt.curr.x, pt.curr.y);
            }
            endShape();
        } else if (!starting){
            finished = true;
        }
    }

    public boolean onscreen(PVector loc){
        PVector addtrans = loc.copy();
        addtrans.x -= width/2;
        if (0 < addtrans.x && addtrans.x < width){
            if (0 < loc.y && loc.y < height){
                return true;
            }
        }
        return false;
    }
}

class Verlet {
    PVector curr;
    PVector prev;
    float disttraveled = 0;
    public Verlet(float x, float y) {
        curr = new PVector(x, y);
        prev = curr.copy();
    }

    public void addforce(PVector force){
        prev = PVector.sub(prev, force);
    }

    public void move(){
        PVector diff = PVector.sub(curr, prev);
        
        if (onscreen(curr)){
            disttraveled += diff.mag();
        }
        
        prev = curr.copy();
        curr = PVector.add(curr, diff);
    }

    public boolean onscreen(PVector loc){
        PVector addtrans = loc.copy();
        addtrans.x -= width/2;
        if (0 < addtrans.x && addtrans.x < width){
            if (0 < loc.y && loc.y < height){
                return true;
            }
        }
        return false;
    }
}

class BlackHole {
    float range = 200;
    float gravity = 0.02f;
    PVector loc; 

    public BlackHole(float x, float y, float range){
        loc = new PVector(x, y);
        this.range = range;
    }

    public void affectbullets(){
        for (int i = 0; i < lines.size(); i++){
            BulletLine line = lines.get(i);

            for (int j = 0; j < line.bullets.size(); j++){
                Bullet bullet = line.bullets.get(j);

                for (int k = 0; k < bullet.pts.size(); k++){
                    Verlet pt = bullet.pts.get(k);

                    PVector diff = PVector.sub(loc, pt.curr);
                    if(diff.mag() < range){
                        float ratio = diff.mag() / range;
                        diff.normalize();
                        PVector force = diff.mult(ratio * gravity);
                        pt.addforce(force);
                        bullet.pts.set(k, pt);
                        // line.bullets.set(k)
                    }
                }
            }
        }
    }

    public void display(){
        noFill();
        ellipse(loc.x, loc.y, range*2, range*2);
        fill(0);
        ellipse(loc.x, loc.y, 10, 10);
    }
}


class Recording {
    boolean recording = false;
    boolean stopped = false;
    int start_frame;
    int stop_frame;
    int frame_rate = 30;
    int recording_time = 250;

    public Recording() {
        
    }

    public void start(){
        if (recording == false && stopped == false) {
                recording = true;
                start_frame = frameCount;
                stop_frame = start_frame + (frame_rate * recording_time);
        }
    }

    public void control(){
        if (recording) {
            saveFrame("output/img-####.png");
            if (stop_frame < frameCount) {
                stopped = true;
                recording = false;
            }
            print(stop_frame, frameCount, '\n');
            if (stopped) {
                println("Finished.");
                System.exit(0);
            }
        }
    }
}
  public void settings() {  size(1080, 1080); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "AirFlow" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
