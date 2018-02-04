import java.util.*;

final PVector X = new PVector(1, 0, 0);
final PVector Y = new PVector(0, 1, 0);
final PVector Z = new PVector(0, 0, 1);

final int[][] colors = {
  {#0E5A8A, #137CBD, #48AFF0},
  {#0A6640, #0F9960, #3DCC91},
  {#A66321, #D9822B, #FFB366},
  {#A82A2A, #DB3737, #FF7373},
};
int colorIndex = -1;

static float[] X_POW_5_CACHE = new float[1000];
static {
  for (int i = 0; i < 1000; i++) {
    X_POW_5_CACHE[i] = pow(5, map(i, 0, 1000, -5, 5));
  }
}

float tierDifferenceMultiplier(float tier) { // tier can range from -4 to 4
//  float fraction = tier % 1;
  float lower = X_POW_5_CACHE[floor(map(tier, -5, 5, 0, 1000))];
  return lower;
//  float upper = X_POW_5_CACHE[ceil(map(tier, -5, 5, 0, 1000))];
// return map(fraction, 0, 1, lower, upper);
}

boolean repelDistance = false;
boolean repelAngle = true;

void keyPressed() {
  if (key == 'd') {
    repelDistance = !repelDistance;
  }
  if (key == 'a') {
    repelAngle = !repelAngle;
  }
  if (key == ' ') {
    newSet();
  }
}

class Particle {
  PVector position;
  PVector velocity;
  private PVector force = new PVector(0, 0, 0);
  // tier 1 is small, tier 2 is bigger, tier 3 is bigger, tier 4 is bigger
  int tier;
  float twist;
  PVector positionNorm;
  Particle[][] closestPerTier = new Particle[5][2];
  
  Particle(PVector pos, PVector vel, int tier, float twist) {
    position = pos;
    velocity = vel;
    this.tier = tier;
    this.twist = twist;
    positionNorm = position.normalize(null);
  }
  
  void resetClosestTierList() {
    for (Particle[] closestParticles : closestPerTier) {
      closestParticles[0] = closestParticles[1] = null;
    }
  }
  
  void updateClosestTierList(Particle p) {
    Particle[] closestParticles = closestPerTier[p.tier];
    Particle closestParticle = closestParticles[0];
    if (closestParticle == null || p.position.dist(this.position) < closestParticle.position.dist(this.position)) {
      closestParticles[1] = closestParticles[0];
      closestParticles[0] = p;
    }
  }
  
  void calculateForce() {
    force.set(0, 0, 0);
    resetClosestTierList();
    // first, calculate repelling force: 
    // repel away from everything in your tier or higher
    for (Particle p : particles) {
       if (p.tier >= this.tier && p != this) {
         if (p.tier - this.tier <= 1) {
           updateClosestTierList(p);
         }
        //if (p != this) {
        // repel based on distance
        if (repelDistance) {
          PVector offset = PVector.sub(position, p.position);
          float dist = offset.mag();
          PVector f = offset.normalize().mult(tierDifferenceMultiplier(p.tier - this.tier) * 10 / dist);
          force.add(f);
        }
        
        // repel based on angle
        if (repelAngle) {
          PVector pPositionNorm = p.positionNorm;
          float angleBetween = PVector.angleBetween(pPositionNorm, positionNorm);
          if (angleBetween > 0) {
            float tdm = tierDifferenceMultiplier(p.tier - this.tier);
            float mag = tdm * tdm * 0.1 / angleBetween;
            PVector direction = PVector.sub(positionNorm, pPositionNorm).normalize();
            PVector correctedDirection = PVector.lerp(direction, positionNorm, -angleBetween);
            correctedDirection.setMag(mag);
            force.add(correctedDirection);
          }
        }
      }
    }
    
    // finally, add a drag force:
    PVector dragForce = this.velocity.copy().mult(-0.03);
    force.add(dragForce);
  }
  
  void timeStep(float dt) {
    this.force.mult(dt);
    this.velocity.add(this.force);
    this.position.add(PVector.mult(this.velocity, dt));
    
    float angleX = PVector.angleBetween(X, this.position);
    float angleY = PVector.angleBetween(Y, this.position);
    float angleZ = PVector.angleBetween(Z, this.position);
    float noiseTime = millis() / 5000f * 0;
    float NOISE_SCALE = 0.5;
    float wantedDistance = 2 * 600 / (this.tier + 1) + 100 * noise(
      angleX * NOISE_SCALE + noiseTime + 123920,
      angleY * NOISE_SCALE + 93123.123,
      angleZ * NOISE_SCALE - 13.12412
    ) - 25;
    this.position.setMag(wantedDistance);
    positionNorm = position.normalize(null);
  }
  
  void draw() {
    noStroke();
    // fill(255);
    if (tier == 1) {
      fill(colors[colorIndex][0]);
    } else if (tier == 2) {
      fill(colors[colorIndex][1]);
    } else if (tier == 3) {
      fill(colors[colorIndex][2]);
    }
    pushMatrix();
    translate(this.position.x, this.position.y, this.position.z);
    sphere(tierDifferenceMultiplier(this.tier));
    //box(sqrt(tierDifferenceMultiplier(this.tier)) * 1);
    popMatrix();
    
    strokeWeight(tierDifferenceMultiplier(this.tier) / 3);
     stroke(30, 40);
    noFill();
    pushMatrix();
    //scale(this.tier);
    //line(0, 0, 0, this.position.x, this.position.y, this.position.z);
    //for (Particle[] closestParticles : closestPerTier) {
    if (this.tier <= 2) {
      Particle[] closestParticles = closestPerTier[this.tier + 1];
      Particle closest = closestParticles[0];
      Particle second = closestParticles[1];
      if (closest != null) {
        beginShape();
        curveVertex(this.position.x * 2, this.position.y * 2, this.position.z * 2);
        curveVertex(this.position.x, this.position.y, this.position.z);
        //if (second != null) {
        //  curveVertex(second.position.x, second.position.y, second.position.z);
        //}
        curveVertex(closest.position.x, closest.position.y, closest.position.z);
        curveVertex(0, 0, 0);
//          line(p.position.x, p.position.y, p.position.z, this.position.x, this.position.y, this.position.z);
        endShape();
      }
    }
    popMatrix();
  }
}

List<Particle> particles;

void setup() {
  size(displayWidth, displayHeight, P3D);
  sphereDetail(3, 1);
  
  noiseSeed(0);
  randomSeed(0);
  
  newSet();
}

void newSet() {
  particles = new ArrayList();
  float num = random(250, 350);
  for(int i = 0; i < num; i++) {
    int tier = 1;
    if (random(1) < 0.1) tier++;
    if (random(1) < 0.1) tier++;
    if (random(1) < 0.1) tier++;
    Particle p = new Particle(
      new PVector(randomGaussian() * 200, randomGaussian() * 200, randomGaussian() * 200),
      new PVector(0, 0, 0),
      tier,
      1
    );
    particles.add(p);
  }
  angle = random(TWO_PI);
  distTime = random(10000);
  colorIndex = (colorIndex + 1) % colors.length;
}

float angle = 0;
float distTime = 0;

void draw() {
  background(255);
  lights();
  angle += 0.003;
  distTime += 0.01;
  float dist = 3 * (300 + map(sin(distTime), -1, 1, 0, height) / 10);
  camera(
    dist * cos(angle),
    dist * sin(angle),
    mouseY / 2,
    0, 0, 0,
    0, 0, -1);
//  box(50);
  //stroke(255, 0, 0);
  //line(0, 0, 0, 255, 0, 0);
  //stroke(0, 255, 0);
  //line(0, 0, 0, 0, 255, 0);
  //stroke(0, 0, 255);
  //line(0, 0, 0, 0, 0, 255);
  for (Particle p : particles) {
    p.calculateForce();
  }
  for (Particle p : particles) {
    p.timeStep(1);
  }
  for (Particle p : particles) {
    p.draw();
  }
  println("repelDistance: " + repelDistance + ", repelAngle: " + repelAngle);
}