#pragma once

#include "ofxiOS.h"
#include "ofxSvg.h"
#include "ofxBox2d.h"
#include "ofxiOSCoreMotion.h"

class ofApp : public ofxiOSApp {
	
    public:
        void setup();
        void update();
        void draw();
        void exit();
	
        void touchDown(ofTouchEventArgs & touch);
        void touchMoved(ofTouchEventArgs & touch);
        void touchUp(ofTouchEventArgs & touch);
        void touchDoubleTap(ofTouchEventArgs & touch);
        void touchCancelled(ofTouchEventArgs & touch);

        void lostFocus();
        void gotFocus();
        void gotMemoryWarning();
        void deviceOrientationChanged(int newOrientation);
    
    void randomSvg();

    int size, count, scount, scount2, scount3;
    ofxiOSCoreMotion coreMotion;
    ofVec3f gravity;
    
    //box2d
    ofxBox2d box2d;
    vector <shared_ptr<ofxBox2dCircle> > circles;
    vector <shared_ptr<ofxBox2dPolygon>>  polyShapes;
    vector<int> pcount;
    
    //svg
    vector<ofxSVG> svgs2;
    vector<ofxSVG> svgs;
    vector<vector<glm::vec3> > vp;
    ofxSVG clearSvg;
    ofPath path;
    ofRectangle clearRect;
};


