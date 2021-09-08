#include "ofApp.h"

//--------------------------------------------------------------
void ofApp::setup(){
    size = ofGetWidth()*0.12;
    
    //加速度センサーを使う
    coreMotion.setupAccelerometer();
    
    //box2dの基本設定
    gravity.x = 0;
    gravity.y = 15;
    box2d.init(); //初期化
    box2d.setGravity(gravity.x, gravity.y); //重力の設定（下方向に１）
    ofRectangle rec = ofRectangle(0, 0, ofGetWidth(), ofGetHeight());
    box2d.createBounds(rec); //枠を追加
    box2d.setFPS(30); //Box2Dの演算の更新頻度を設定
    box2d.setIterations(5, 5); //インタラクションの精度を設定
    
    //svgをロード
    ofDirectory dir;
    dir.listDir("svg/");
    dir.allowExt("svg");
    dir.sort();
    if (dir.size()) {
        svgs.assign(dir.size(), ofxSVG());
    }
    for (int i = 0; i < (int)dir.size(); i++) {
        svgs[i].load(dir.getPath(i));
    }
    
    //svg（アウトライン）をロード
    ofDirectory dir2;
    dir2.listDir("svg_outline/");
    dir2.allowExt("svg");
    dir2.sort();
    if (dir2.size()) {
        svgs2.assign(dir2.size(), ofxSVG());
    }
    for (int i = 0; i < (int)dir2.size(); i++) {
        svgs2[i].load(dir2.getPath(i));
    }
    //svgの頂点を配列に保存
    for (int i = 0; i < svgs2.size(); i++) {
        for (int j = 0; j < svgs2[i].getNumPath(); j++) {
            ofPath p = svgs2[i].getPathAt(j);
            p.setPolyWindingMode(OF_POLY_WINDING_ODD);
            vector<ofPolyline> vpl= p.getOutline();
            vp.push_back(vector<glm::vec3>());
            for (int k = 0; k < vpl.size(); k++) {
                ofPolyline pl = vpl[k];
                vp[i] = pl.getVertices();
            }
        }
    }
    
    //オブジェクト全消しアイコンをロード
    clearSvg.load("loader-outline.svg");
    //↑のsvgをofPathに渡す
    for (ofPath p: clearSvg.getPaths()){
        p.setPolyWindingMode(OF_POLY_WINDING_ODD);
        const vector<ofPolyline>& lines = p.getOutline();
        vector<ofPolyline> outlines;
        for(const ofPolyline & line: lines){
            outlines.push_back(line.getResampledBySpacing(1));
        }
        for (int j = 0; j < outlines.size(); j++) {
            ofPolyline & line = outlines[j];
            for (int k = 0; k < line.size(); k++) {
                if (j==0 && k==0){
                    path.lineTo(line[k]);
                } else if(j>0 && k==0){
                    path.moveTo(line[k]);
                }else if (k > 0) {
                    path.lineTo(line[k]);
                }
            }
            path.close();
        }
    }
    
    //オブジェクト全消しアイコンの位置を決定。rect.set(x, y, width, height)
    int iconSize = ofGetWidth()*0.08;
    clearRect.set(ofGetWidth()-iconSize-20, 20, iconSize, iconSize);
    
    count = 0; //オブジェクトの配列に使う数値（polyShapesのcount番にbox2dオブジェクトを追加）
    scount2 = 0; //アップロードしたsvgが入った配列にアクセスするときの数値（scount2番のsvgs,svgs2にアクセス）
    scount3 = 0;

}

//--------------------------------------------------------------
void ofApp::update(){
    //加速度センサーで重力を設定
    coreMotion.update();
    gravity = coreMotion.getAccelerometerData();
    gravity *= 20.0;
    gravity.y *= -1.0;
    box2d.setGravity(gravity.x, gravity.y);
    
    box2d.update(); //Box2Dの物理演算の実行

}

//--------------------------------------------------------------
void ofApp::draw(){
    ofBackground(241, 140, 121);
    
    // object
    for (int i = 0; i < polyShapes.size(); i++){
        ofPoint pos = polyShapes[i].get()->getPosition();
        auto box = polyShapes[i].get()->getBoundingBox();
        float rot = polyShapes[i].get()->getRotation();
        int number = pcount[i];
        
        ofPushMatrix();
        ofTranslate(pos.x, pos.y);
        ofRotateDeg(rot);
        ofScale(1/svgs[number].getWidth()*size);
        ofScale(0.8);
        ofTranslate(-svgs[number].getWidth()/2, -svgs[number].getHeight()/2);
        ofSetColor(255, 255, 255);
        svgs[number].draw();
        ofPopMatrix();
        
        //polygon
        /*
        ofSetColor(255, 255, 255);
        ofSetLineWidth(20);
        ofNoFill();
        polyShapes[i].get()->draw();
         */
    }
    
    //オブジェクトの全消しを実行するアイコン
    ofPushMatrix();
    ofTranslate(clearRect.x, clearRect.y);
    ofScale(1/clearSvg.getWidth()*clearRect.getWidth(), 1/clearSvg.getHeight()*clearRect.getHeight());
    path.setColor(ofColor(245, 238, 227));
    path.draw();
    ofPopMatrix();
	
}

//--------------------------------------------------------------
void ofApp::exit(){

}

//--------------------------------------------------------------
void ofApp::touchDown(ofTouchEventArgs & touch){
    
    if(clearRect.inside(touch.x, touch.y)){ //全消しアイコンを押したら
        polyShapes.clear();
        pcount.clear();
        count = 0;
        
    } else { //画面をタッチすると新たにオブジェクトを追加する
        
        //ランダムにsvgを決める
        randomSvg();
        
        auto poly = std::make_shared<ofxBox2dPolygon>();
        for (int i = 0; i < vp[scount].size(); i++){
            float scale = size/svgs2[scount].getWidth();
            poly->addVertex(touch.x + vp[scount][i].x*scale - size/2, touch.y + vp[scount][i].y*scale - size/2);
        }
        poly->setPhysics(1.0, 0.5, 0.1); //物理パラメーターを設定（重さ、反発力、摩擦力）
        poly->simplifyToMaxVerts(); //ポリゴンを単純化
        poly->create(box2d.getWorld());
        polyShapes.push_back(poly);
        
        //画面の向きに合わせてオブジェクトの向きを設定する
        float radian, degree;
        radian = atan2(gravity.y - 0, gravity.x - 0);
        if(radian < 0){
            radian = ofMap(radian, -3.14, 0, 0, 3.14)+3.14;
        }
        degree = ofMap(radian, 0, 6.28, 0, 360)-90;
        polyShapes[count].get()->setRotation(degree);
        
        
        pcount.push_back(scount);
        count += 1;
    }
}
//--------------------------------------------------------------
void ofApp::randomSvg(){
    int arr[5];
    arr[0] = 3;
    arr[1] = 4;
    arr[2] = 8;
    arr[3] = 11;
    arr[4] = 14;
    
    float random = ofRandom(10);
    if (random < 1 ) { //たまにだけ3, 4, 8, 11, 14番目のsvgが出るようにする
        scount = arr[scount3];
        scount3++;
        if (scount3>=5) {
            scount3=0;
        }
    } else {
        scount = scount2;
        scount2++;
        if (scount2 == arr[0]) {
            scount2+=2;
        } else if(scount2 == arr[1] || scount2 == arr[2] || scount2 == arr[3] || scount2 == arr[4]){
            scount2+=1;
        } else if(scount2 >= svgs.size()){
            scount2=0;
        }
    }
}
//--------------------------------------------------------------
void ofApp::touchMoved(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchUp(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchDoubleTap(ofTouchEventArgs & touch){

}

//--------------------------------------------------------------
void ofApp::touchCancelled(ofTouchEventArgs & touch){
    
}

//--------------------------------------------------------------
void ofApp::lostFocus(){

}

//--------------------------------------------------------------
void ofApp::gotFocus(){

}

//--------------------------------------------------------------
void ofApp::gotMemoryWarning(){

}

//--------------------------------------------------------------
void ofApp::deviceOrientationChanged(int newOrientation){

}
