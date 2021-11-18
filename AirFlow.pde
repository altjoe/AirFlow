
ArrayList<Track> tracks = new ArrayList<Track>();
Recording record;
void setup() {
    size(512, 512);
    background(255);
    frameRate(30);


    for (int i = 0; i < 150; i++){
        Track track = new Track(i*width/100 - 100, height+50, 0);
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
        track.shoot();
        track.move();
        // track.deletefinished();
        track.display();
    }
}

class Track {
    ArrayList<Segment> segs = new ArrayList<Segment>();
    PVector loc;
    float circle_rotation = PI*3.0/2.0;
    float radius;
    float rotation;

    float distbetweenshots = int(random(10, 20));
    
    public Track(float x, float y, float r){
        loc = new PVector(x, y);
        rotation = r;
        shoot();
    }

    void shoot() {
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
        seg.add_rotation(PI, 100, false);
        seg.add_rotation(PI, 50, true);
        seg.add_rotation(PI, 100, false);
        seg.add_rotation(PI, 100, true);
        // seg.add_translation(new PVector(50, 0));

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
    float speed = 5;
    int segcount = 5;
    float segsize = 5;
    float rotation;
    float totalphasedist;

    public Segment(PVector loc, float r){
        rotation = r;
        this.loc = loc;
        visible = new PVector[segcount];
        segcount = int(random(8, 30));
        segsize = int(random(8, 30));
        segcount = int(segsize);
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
    }

    void add_translation(PVector trans){ // phases pvector will need a zero z value 
        totalphasedist += trans.mag();
        phases.add(trans);
        phaseids.add(0.0); 
    }

    // phases pvector x,y will contain pivot pt, z will contain rotation no need to store radius because it will be distance from pviot and offset  
    void add_rotation(float rotation, float radius, boolean clockwize){ 
        totalphasedist += abs(radius * rotation);
        if (clockwize) { 
            rotation *= -1; 
        } else { 
            radius *= -1; 
        }

        PVector pivot = new PVector(0, radius);
        
        for (PVector phase : phases){
            if (phase.z != 0){
                pivot.rotate(phase.z);
            }
            
        }
        phases.add(new PVector(pivot.x, pivot.y, rotation));
        phaseids.add(1.0);
    }

    void move(){
        for (int i = 0; i < pts.size(); i++){
            PVector pt = pts.get(i);
            pt.x += speed;
            pts.set(i, pt);

            PVector vispt = loc.copy();
            float currdist = pt.x;
            for (int j = 0; j < phases.size(); j++){
                PVector phase = phases.get(j);
                float phaseid = phaseids.get(j);
                if (phaseid == 0){
                    PVector offset = move_translate(currdist, phase);
                    currdist -= offset.mag();
                    vispt = PVector.add(vispt, offset);
                } else {
                    PVector offset = move_rotation(currdist, phase);
                    float radius = new PVector(phase.x, phase.y).mag();
                    currdist -= abs(radius* phase.z);
                    vispt = PVector.add(vispt, offset);
                }
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
        if (currdist >= phase.mag()){
            return phase;
        } else {
            PVector norm = phase.copy();
            norm.normalize();
            norm.x *= currdist;
            norm.y *= currdist;
            return norm;
        } 
    }   

    PVector move_rotation(float currdist, PVector phase){
        float radius = new PVector(phase.x, phase.y).mag();
        float totalangle = phase.z;
        float totalphasedist = abs(radius * totalangle);
        float currangle = (currdist / totalphasedist) * totalangle;
        
        PVector pivot = new PVector(phase.x, phase.y);
        
        if (currdist >= totalphasedist) {
            return mypivot(new PVector(0,0), pivot, totalangle);
        } else if (currdist > 0){
            return mypivot(new PVector(0,0), pivot, currangle);
        }
        return new PVector(0,0);
    }

    PVector mypivot(PVector pt, PVector pivot, float angle) {
        float s = sin(-angle);
        float c = cos(-angle);
        pt = PVector.sub(pt, pivot);
        float x = pt.x * c - pt.y * s;
        float y = pt.x * s + pt.y * c;

        pt.x = x + pivot.x;
        pt.y = y + pivot.y;
        return pt;
    }  

    void display(){
        if (visible.length > 0){
            float ratio = (totalphasedist - pts.get(0).x) / totalphasedist;
            float sw = 10;
            if (sw * ratio >= 0){
                strokeWeight(sw * ratio);
            } else {
                strokeWeight(0);
            }
            noFill();
            beginShape();
            for (int i = 0; i < visible.length; i++){
                if (pts.get(i).x >= 0){
                    curveVertex(visible[i].x, visible[i].y);
                    // ellipse(visible[i].x, visible[i].y, 5, 5);
                    // ellipse(pts.get(i).x, pts.get(i).y, 5, 5);
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

    void start(){
        if (recording == false && stopped == false) {
                recording = true;
                start_frame = frameCount;
                stop_frame = start_frame + (frame_rate * recording_time);
        }
    }

    void control(){
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
