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


ArrayList<Track> tracks = new ArrayList<Track>();
int trackcount = 150;
Recording record;
public void setup() {
    
    background(255);
    frameRate(30);
    float maxangle = radians(150);
    for (int i = 0; i < trackcount; i++) {
        float angle = maxangle * PApplet.parseFloat(i)/PApplet.parseFloat(trackcount) + radians(-100);
        // Track track = new Track(width/2, height/2, angle);
        Track track = new Track(-10, -10, angle);
        tracks.add(track);
    }
    record = new Recording();
    record.start();
}

int shoottime = 200;
int shootcount = 0;
boolean shooton = true;
float wavecount = 0;

public void draw() {
    background(255);
    
    for (Track track : tracks){
        if (shooton && wavecount < 5){
            track.shoot();
        } else if (wavecount > 5) {
            println(frameCount);
        }
        track.move();
        track.deletefinished();
        track.display();
    }
    if (shootcount > shoottime){
        shooton = !shooton;
        shootcount = 0;
        wavecount += 0.5f;
    }
    shootcount += 1;
    record.control();
}

class Track {
    ArrayList<Segment> segs = new ArrayList<Segment>();
    PVector loc;
    float circle_rotation = PI*3.0f/2.0f;
    float radius;
    float rotation;

    float distbetweenshots = PApplet.parseInt(random(10, 20));
    
    public Track(float x, float y, float r){
        loc = new PVector(x, y);
        rotation = r;
        shoot();
    }

    public void shoot() {
        boolean shootit = true;
        if (segs.size() > 0){
            Segment seg = segs.get(segs.size()-1);
            for (PVector pt : seg.pts){
                if (pt.x < distbetweenshots){
                    shootit = false;
                    break;
                }  
            }
            if (shootit) {
                shootone();
            }
            
            distbetweenshots = PApplet.parseInt(random(3, 8));
        } else {
            shootone();
        }
        
    }

    public void deletefinished(){
        for (int i = segs.size()-1; i >= 0; i--){
            Segment seg = segs.get(i);
            if (seg.pts.get(seg.pts.size()-1).x > seg.totalphasedist){
                segs.remove(i);
            }
        }
    }

    public void shootone(){
        Segment seg = new Segment(loc, rotation);
        seg.add_translation(new PVector(200*2, 50*2));
        seg.add_translation(new PVector(50*2, 200*2));
        seg.add_translation(new PVector(200*2, -20*2));
        seg.add_translation(new PVector(-30*2, 400*2));
        seg.myrotate(rotation);
        segs.add(seg);
    }

    public void display() {
        for (Segment seg : segs) {
            seg.display();
        }
    }

    public void move(){
        for (Segment seg : segs) {
            seg.move();
        }
    }
}

class Segment {
    PVector loc;
    ArrayList<Float> phaseids = new ArrayList<Float>();
    ArrayList<PVector> phases = new ArrayList<PVector>();
    ArrayList<PVector> pts = new ArrayList<PVector>();
    PVector[] visible;


    int phasecount = 0;
    float speed = 3*2;
    int segcount = 5;
    float segsize = 5;
    float rotation;
    float totalphasedist;

    public Segment(PVector loc, float r){
        rotation = r;
        this.loc = loc;
        visible = new PVector[segcount];
        // segcount = int(random(8, 30));
        segsize = PApplet.parseInt(random(8, 30));
        segcount = PApplet.parseInt(segsize);
        for (int i = 0; i < visible.length; i++){
            PVector vispt = loc.copy();
            PVector centerdir = PVector.sub(loc, new PVector(0, 0));
            centerdir.normalize();
            centerdir.x *= i * segsize;
            centerdir.y *= i * segsize;

            vispt = PVector.sub(vispt, centerdir);
            visible[i] = vispt;
            PVector pt = new PVector(-i * segsize, 0);
            pts.add(pt);
        }
        add_translation(new PVector(0, 0));
    }

    public void add_translation(PVector trans){ // phases pvector will need a zero z value 
        totalphasedist += trans.mag();
        phases.add(trans);
        phaseids.add(0.0f); 
    }

    // phases pvector x,y will contain pivot pt, z will contain rotation no need to store radius because it will be distance from pviot and offset  
    public void add_rotation(float rotation, float radius, boolean left){ 
        if (left){
            phases.add(new PVector(0, radius, rotation));
        } else {
            phases.add(new PVector(0, -radius, rotation));
        }
        phaseids.add(1.0f);
    }

    public void move(){
        for (int i = 0; i < pts.size(); i++){
            PVector pt = pts.get(i);
            pt.x += speed;
            pts.set(i, pt);

            PVector vispt = loc.copy();
            float currdist = pt.x;
            PVector prevphase = new PVector(0,0);
            for (int j = 0; j < phases.size(); j++){
                PVector phase = phases.get(j);
                float phaseid = phaseids.get(j);

                if (phaseid == 0){
                    PVector offset = move_translate(currdist, phase);
                    currdist -= offset.mag();
                    vispt = PVector.add(vispt, offset);
                } else {
                    // PVector offset = move_rotate(currdist, phase);
                }
                prevphase = phase.copy();
            }
            visible[i] = vispt;
        }
    }

    public void myrotate(float angle) {
        for (int i = 0; i < phases.size(); i++){
            PVector phase = phases.get(i);
            PVector pivot = loc.copy();
            float s = sin(-angle);
            float c = cos(-angle);
            phase = PVector.sub(phase, pivot);
            float x = phase.x * c - phase.y * s;
            float y = phase.x * s + phase.y * c;

            phase.x = x + pivot.x;
            phase.y = y + pivot.y;
            phases.set(i, phase);
        }
    }   

    public PVector move_translate(float currdist, PVector phase){
        if (currdist > phase.mag()){
            return phase;
        } else {
            PVector norm = phase.copy();
            norm.normalize();
            norm.x *= currdist;
            norm.y *= currdist;
            return norm;
        }
    }   

    public void display(){
        if (visible.length > 0){
            float ratio = (totalphasedist - pts.get(0).x) / totalphasedist;
            float sw = 10;
            if (sw * ratio >= 0){
                strokeWeight(sw * ratio);
            } else {
                strokeWeight(0);
            }
            // stroke(c);
            noFill();
            beginShape();
            for (int i = 0; i < visible.length; i++){
                if (pts.get(i).x >= 0){
                    curveVertex(visible[i].x, visible[i].y);
                }
            }
            endShape();
        }
    }
}

class Recording {
    boolean recording = false;
    boolean stopped = false;
    int start_frame;
    int stop_frame;
    int frame_rate = 30;
    int recording_time = 100;

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
