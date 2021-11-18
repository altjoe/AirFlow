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
public void setup() {
    
    background(255);

    BlackHole hole = new BlackHole(width/3, height/3, 100);
    holes.add(hole);
    hole = new BlackHole(width/3, height*2/3, 50);
    holes.add(hole);
    hole = new BlackHole(width*2/3, height/3, 300);
    holes.add(hole);
    hole = new BlackHole(width*2/3, height*2/3, 200);
    holes.add(hole);
    float numlines = 150;
    for (int i = 0; i < numlines; i++){
        BulletLine line = new BulletLine(-10, height*i/numlines);
        lines.add(line);
    }
    
}

public void draw() {
    background(255);
    translate(-width/2, 0);
    for (BlackHole hole : holes){
        hole.affectbullets();
        // hole.display();
    }

    for (BulletLine line : lines){
        line.move();
        line.display();
    }

    
}


class BulletLine {
    ArrayList<Bullet> bullets = new ArrayList<Bullet>();
    PVector loc;
    float beforenext = 5;
    public BulletLine(float x, float y){
        loc = new PVector(x, y);
        shoot();
    }

    public void shoot(){
        Bullet bullet = new Bullet(loc.x, loc.y);
        bullets.add(bullet);
    }

    public void move(){
        for (Bullet bullet : bullets){
            bullet.move();
        }

        Bullet lastbullet = bullets.get(bullets.size()-1);
        Verlet lastptofbullet = lastbullet.pts.get(lastbullet.pts.size()-1);
        if (lastptofbullet.curr.x > loc.x + beforenext){
            shoot();
            beforenext = PApplet.parseInt(random(3, 10));
        }
    }

    public void display(){
        for (Bullet bullet : bullets){
            bullet.display();
        }
    }
}

class Bullet {
    ArrayList<Verlet> pts = new ArrayList<Verlet>();
    int segsize = 2;
    int numsegs = PApplet.parseInt(random(5, 25));
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
        float disttraveled = pts.get(0).disttraveled;
        float ratio = (width - disttraveled) / width;
        float sw = ratio * 3;
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
  public void settings() {  size(512, 512); }
  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "AirFlow" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
