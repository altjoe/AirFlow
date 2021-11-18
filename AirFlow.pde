ArrayList<BlackHole> holes = new ArrayList<BlackHole>();
ArrayList<BulletLine> lines = new ArrayList<BulletLine>();
void setup() {
    size(512, 512);
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

void draw() {
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

    void shoot(){
        Bullet bullet = new Bullet(loc.x, loc.y);
        bullets.add(bullet);
    }

    void move(){
        for (Bullet bullet : bullets){
            bullet.move();
        }

        Bullet lastbullet = bullets.get(bullets.size()-1);
        Verlet lastptofbullet = lastbullet.pts.get(lastbullet.pts.size()-1);
        if (lastptofbullet.curr.x > loc.x + beforenext){
            shoot();
            beforenext = int(random(3, 10));
        }
    }

    void display(){
        for (Bullet bullet : bullets){
            bullet.display();
        }
    }
}

class Bullet {
    ArrayList<Verlet> pts = new ArrayList<Verlet>();
    int segsize = 2;
    int numsegs = int(random(5, 25));
    public Bullet(float x, float y){
        for (int i = 0; i < numsegs; i++){
            Verlet pt = new Verlet(x - segsize*i, y);
            pt.addforce(new PVector(2, 0));
            pts.add(pt);
        }
    }

    void move(){
        for (Verlet pt : pts){
            pt.move();
        }
    }

    void display(){
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

    void addforce(PVector force){
        prev = PVector.sub(prev, force);
    }

    void move(){
        PVector diff = PVector.sub(curr, prev);
        if (onscreen(curr)){
            disttraveled += diff.mag();
        }
        
        prev = curr.copy();
        curr = PVector.add(curr, diff);
    }

    boolean onscreen(PVector loc){
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
    float gravity = 0.02;
    PVector loc; 

    public BlackHole(float x, float y, float range){
        loc = new PVector(x, y);
        this.range = range;
    }

    void affectbullets(){
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

    void display(){
        noFill();
        ellipse(loc.x, loc.y, range*2, range*2);
        fill(0);
        ellipse(loc.x, loc.y, 10, 10);
    }
}
