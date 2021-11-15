float screenhyp;
ArrayList<Track> tracks = new ArrayList<Track>();
Track loop;
Recording record;
void setup() {
    size(512, 512);
    background(255);
    screenhyp = 50 + width/2;
    float x = -50;
    float y = width/2;
    float space = 5;
    for (int i = 1; i < 110; i++) {
        // x -= space;
        y += space;
        Track track = new Track(x, y, 0, -2.5 + i * space*(6.0/5.0));
        tracks.add(track);
    }

    record.start();
}

int stopshooting = 300;
int stopcount = 0;
boolean shooting = true;

void draw() {
    background(255);
    for (int i = tracks.size()-1; i >= 0; i--){
        Track track = tracks.get(i);
        if (shooting frameCunt < 140 * 30){
            track.shoot();
        }
        
        track.move();
        track.display();
    }
    if (stopcount > stopshooting){
        shooting = !shooting;
        if (!shooting) {
            stopshooting = 300;
        } else {
            stopshooting = 300;
        }
        stopcount = 0;
    }
    stopcount += 1;
    record.control();
}

class Track {
    ArrayList<Segment> segs = new ArrayList<Segment>();
    PVector loc;
    float circle_rotation = PI*3.0/2.0;

    float radius;
    float rotation;
    
    public Track(float x, float y, float rotation, float radius){
        loc = new PVector(x, y);
        this.rotation = rotation;
        this.radius = radius;
        shoot();
    }

    void shoot() {
        if (segs.size() > 0){
            Segment newest = segs.get(segs.size()-1);
            if (newest.cleared) {
                Segment seg = new Segment(loc, radius);
                segs.add(seg);
            }
        } else {
            Segment seg = new Segment(loc, radius);
            segs.add(seg);
        }
        
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
        for (int i = segs.size()-1; i >= 0; i--){
            Segment seg = segs.get(i);
            if (!seg.finished) {
                seg.move();
            } else {
                segs.remove(i);
            }
        }
    }

}

class Segment {
    ArrayList<PVector> pts = new ArrayList<PVector>();
    int segs;
    int dist_until_new;
    float segsize = 5;
    float radius;
    float speed = 2;
    PVector loc;
    PVector offset;
    boolean cleared = false;
    boolean finished = false;

    public Segment(PVector loc, float radius){
        segs = int(random(3, 15));
        dist_until_new = int(random(4, 10) * segsize);
        this.radius = radius;
        this.offset = new PVector(screenhyp, radius);
        this.loc = loc;
        for (int i = 0; i < segs; i++){
            
            float x = -offset.x - (i * segsize);
            PVector pt = new PVector(x, -offset.y);
            pts.add(pt);
        }
    }

    void display() {
        PVector first = pts.get(0);
        float c = 155 - first.x/3.0;
        float a = first.x/2.0;
        stroke(c,c,c, a);
        strokeCap(ROUND);
        strokeWeight(3);
        beginShape();
        for (int i = 0; i < pts.size(); i++){
            PVector pt = pts.get(i);
            PVector vispt;
            if (pt.x < 0){
                vispt = mytrans(mytrans(pt, offset), loc);
            } else {
                float rotatedist = 2*PI*radius*(3.0/4.0);
                if (pt.x < rotatedist){
                    vispt = loc.copy();
                    vispt.x += offset.x;
                    float angle = anglecalc(pt.x);
                    PVector pivot = vispt.copy();
                    pivot.y -= offset.y;
                    vispt = myrotate(vispt, pivot, angle);
                } else {
                    float angle = anglecalc(rotatedist);
                    vispt = loc.copy();
                    vispt.x += offset.x;
                    PVector pivot = vispt.copy();
                    pivot.y -= offset.y;
                    vispt.x += pt.x - rotatedist;
                    vispt = myrotate(vispt, pivot, angle);
                }
                if ((-5 > vispt.x  || height + 5 < vispt.y) && i == pts.size()-1) {
                    finished = true;
                }
            } 
            curveVertex(vispt.x, vispt.y);
        }
        endShape();
        PVector lastpt = pts.get(pts.size()-1);
        if (lastpt.x > dist_until_new - offset.x) {
            cleared = true;
        }
    }

    PVector mytrans(PVector pt, PVector trans){
        return PVector.add(pt, trans);
    }

    float anglecalc(float dist){
        return dist / radius;
    }

    PVector myrotate(PVector pt, PVector pivot, float angle) {
        float s = sin(-angle);
        float c = cos(-angle);
        pt = PVector.sub(pt, pivot);
        float x = pt.x * c - pt.y * s;
        float y = pt.x * s + pt.y * c;

        pt.x = x + pivot.x;
        pt.y = y + pivot.y;

        return pt;
    }   

    void move(){
        for (int i = 0; i < pts.size(); i++){
            PVector pt = pts.get(i);
            pt.x += speed;
        }
    }
}

class Recording {
    boolean recording = false;
    boolean stopped = false;
    int start_frame;
    int stop_frame;
    int frame_rate = 30;
    int recording_time = 170;

    public Recording() {
        
    }

    void start(){
        if (recording == false && stopped == false) {
                recording = true;
                start_frame = frameCount;
                stop_frame = start_frame + (frame_rate * recording_time) - 1;
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