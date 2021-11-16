
ArrayList<Track> tracks = new ArrayList<Track>();
int trackcount = 100;
void setup() {
    size(512, 512);
    background(255);
    frameRate(30);
    float angle = radians(-30);
    for (int i = 0; i < 300; i++) {
        angle += radians(2);
        // Track track = new Track(width/2, height/2, angle);
        Track track = new Track(-10, -10, angle);
        tracks.add(track);
    }

}

int shoottime = 200;
int shootcount = 0;
boolean shooton = true;
float wavecount = 0;

void draw() {
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
        wavecount += 0.5;
    }
    shootcount += 1;
}

class Track {
    ArrayList<Segment> segs = new ArrayList<Segment>();
    PVector loc;
    float circle_rotation = PI*3.0/2.0;
    float radius;
    float rotation;

    float distbetweenshots = int(random(3, 8));
    
    public Track(float x, float y, float r){
        loc = new PVector(x, y);
        rotation = r;
        shoot();
    }

    void shoot() {
        if (segs.size() > 0){
            Segment seg = segs.get(segs.size()-1);
            PVector lastpt = seg.pts.get(seg.pts.size()-1);
            if (lastpt.x > distbetweenshots){
                shootone();
            }  
            distbetweenshots = int(random(3, 8));
        } else {
            shootone();
        }
        
    }

    void deletefinished(){
        for (int i = segs.size()-1; i >= 0; i--){
            Segment seg = segs.get(i);
            if (seg.pts.get(seg.pts.size()-1).x > seg.totalphasedist){
                segs.remove(i);
            }
        }
    }

    void shootone(){
        Segment seg = new Segment(loc, rotation);
        seg.add_translation(new PVector(200, 50));
        seg.add_translation(new PVector(50, 200));
        seg.add_translation(new PVector(200, -20));
        seg.add_translation(new PVector(-30, 400));
        // seg.add_translation(new PVector(200, 100));
        seg.myrotate(rotation);
        segs.add(seg);
    }

    void display() {
        for (Segment seg : segs) {
            seg.display();
        }
    }

    void move(){
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
    float speed = 3;
    int segcount = 5;
    float segsize = 5;
    float rotation;
    float totalphasedist;
    public Segment(PVector loc, float r){
        rotation = r;
        this.loc = loc;
        visible = new PVector[segcount];
        segsize = int(random(3, 15));
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

    void add_translation(PVector trans){ // phases pvector will need a zero z value 
        totalphasedist += trans.mag();
        phases.add(trans);
        phaseids.add(0.0); 
    }

    // phases pvector x,y will contain pivot pt, z will contain rotation no need to store radius because it will be distance from pviot and offset  
    void add_rotation(float rotation, float radius, boolean left){ 
        if (left){
            phases.add(new PVector(0, radius, rotation));
        } else {
            phases.add(new PVector(0, -radius, rotation));
        }
        phaseids.add(1.0);
    }

    void move(){
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

    void myrotate(float angle) {
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

    PVector move_translate(float currdist, PVector phase){
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

    void display(){
        if (visible.length > 0){
            float ratio = (totalphasedist - pts.get(0).x) / totalphasedist;
            if (3 * ratio >= 0){
                strokeWeight(6 * ratio);
            } else {
                strokeWeight(0);
            }
            
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

