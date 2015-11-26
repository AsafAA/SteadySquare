//
//  ViewController.swift
//  Square
//
//  Created by Asaf Avidan Antonir on 11/9/15.
//  Copyright © 2015 Asaf Avidan Antonir. All rights reserved.
//

import UIKit

class GamePlayViewController: UIViewController {
    
    @IBOutlet var scoreLabel: UILabel!
    
    var square: UIView!
    var viewWidth: CGFloat = 0.0
    var viewHeight: CGFloat = 0.0
    var squareWidth: CGFloat = 0.0
    var lineWidth: CGFloat = 0.0
    var squareX: CGFloat = 0.0
    var maxY: CGFloat = 0.0
    var minY: CGFloat = 0.0
    var timer: NSTimer = NSTimer()
    var lineTimer: NSTimer = NSTimer()
    var lines: [UIView] = []
    var currentLevel: Int = 0
    var linesPassed: Int = 0
    var lineNumber: Int = 0
    var gameMode: String! = ""
    let linesPerLevel: Int = 16
    var randomLevelOffset: Int = 0
    @IBOutlet var exitButton: UIButton!
    var tick: Double = 0.0
    var finalScore = 0
    let defaults = NSUserDefaults(suiteName: "group.io.asaf.square")!
    let colorLevels: ColorLevels = ColorLevels()
    var previouslyOverlapping: Bool = false
    var lineShapes: [CAShapeLayer] = []
    var lineFrames: [CGRect]  = []

    @IBOutlet var facebookButton: UIButton!
    @IBOutlet var menuButton: UIButton!
    @IBOutlet var replayButton: UIButton!
    @IBOutlet var gameOverView: UIView!
    @IBOutlet var finalScoreLabel: UILabel!
    @IBOutlet var bestScoreLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        viewWidth = self.view.frame.width
        viewHeight = self.view.frame.height
        squareWidth = self.view.frame.height / 30
        lineWidth = squareWidth
        maxY = viewHeight - squareWidth/2
        minY = squareWidth / 2
        squareX = viewWidth * 0.15
        scoreLabel.layer.zPosition = 1
        exitButton.layer.zPosition = 1
        gameOverView.layer.zPosition = 1
        gameOverView.layer.cornerRadius = 10.0
        gameOverView.layer.shadowRadius = 2.0
        gameOverView.layer.shadowOpacity = 0.2
        gameOverView.layer.shadowOffset = CGSize(width: 1, height: 1)
        exitButton.hidden = (gameMode != "training")
        
        menuButton.layer.cornerRadius = 5
        replayButton.layer.cornerRadius = 5
        facebookButton.layer.cornerRadius = 5
    
        
        
        
        startGame()
    }
    
    //==============================
    // MARK: - Game States
    
    func startGame() {
        randomLevelOffset = Int(arc4random_uniform(UInt32(LEVELS.count)))
        updateColors()
        gameOverView.hidden = true
        tick = 0
        linesPassed = 0
        lineNumber = 0
        scoreLabel.text = String("0")
        scoreLabel.hidden = false
        finalScore = 0
        initSquare()
        startGameLoop()
    }
    
    func presentGameOverView() {
        finalScore = linesPassed
        var bestScore = 0
        defaults.synchronize()
        
        if let score = defaults.integerForKey(bestScoreKey()) as? Int {
            bestScore = score
        }
        
        if finalScore > bestScore {
            bestScore = finalScore
            defaults.setInteger(finalScore, forKey: bestScoreKey())
        }
        defaults.synchronize()
        
        scoreLabel.hidden = true
        square.hidden = true
        finalScoreLabel.text = String(finalScore)
        bestScoreLabel.text = String(bestScore)
//        gameOverView.backgroundColor = getGameOverViewBackground()
        
        gameOverView.hidden = false
    }
    
    func startGameLoop() {
        dispatch_async(dispatch_get_main_queue(),{
            self.timer = NSTimer.scheduledTimerWithTimeInterval(1.0/60.0, target: self, selector: "checkState", userInfo: nil, repeats: true)
        })
    }
    
//    func stopGame() {
//        print("STOP GAME")
//        dispatch_async(dispatch_get_main_queue(),{
//            self.timer.invalidate()
//        })
//        
//        square.removeFromSuperview()
//
//        for line in lines {
//            line.removeFromSuperview()
//        }
//        
//        lines.removeAll()
//    }
    
    func stopGame() {
//        print("STOP GAME")
        dispatch_async(dispatch_get_main_queue(),{
            self.timer.invalidate()
        })

        square.removeFromSuperview()

        for lineShape in lineShapes {
            lineShape.removeFromSuperlayer()
        }

        lineShapes.removeAll()
        lineFrames.removeAll()
    }
    
//    override func animationDidStop(anim: CAAnimation, finished flag: Bool) {
//        if let first = lineShapes.first {
//            first.removeFromSuperlayer()
//            lineShapes.removeFirst()
//        }
//        
//        if let second = lineShapes.first {
//            second.removeFromSuperlayer()
//            lineShapes.removeFirst()
//        }
//        
//        if let firstFrame = lineFrames.first {
//            lineFrames.removeFirst()
//        }
//        
//        if let secondFrame = lineFrames.first {
//            lineFrames.removeFirst()
//        }
//        
//    }

    
    func initGapLine() {
        print(lineShapes.count)
        let gapHeight = viewHeight * CGFloat(gapHeightMultiplier())
        
        initLine(CGFloat(Int(arc4random_uniform(UInt32(viewHeight - gapHeight * 1.5))) + Int(gapHeight * 0.75)), gapHeight: gapHeight)
    }
    
    func checkState() {
        tick += 1
        if tick % (lineGapTime() * 60) == 0 {
            initGapLine()
        }
        
        if previouslyOverlapping && !currentlyOverlapping() {
            self.linesPassed += 1
            if self.gameMode != "training" {
                self.scoreLabel.text = String(self.linesPassed)
            }
        }
        
        previouslyOverlapping = currentlyOverlapping()
        
        if gameMode != "training" && collision() {
            presentGameOverView()
        }
    }
    
//    func currentlyOverlapping() -> Bool {
//        if !gameOverView.hidden {
//            return false
//        }
//        for line in self.lines {
//            if overlap(square, view2: line) {
//                return true
//            }
//        }
//        return false
//    }
    
    func currentlyOverlapping() -> Bool {
        if !gameOverView.hidden {
            return false
        }
        var lineIndex = 0
        for lineShape in self.lineShapes {
            if overlap(square, view2: lineShape, view2frame: lineFrames[lineIndex]) {
                return true
            }
            lineIndex += 1
        }
        return false
    }

    func overlap(view1: UIView, view2: CAShapeLayer, view2frame: CGRect) -> Bool {
        if let layer1 = view1.layer.presentationLayer() {
            if let layer2 = view2.presentationLayer() {
                let frame1 = layer1.frame
                let frame2 = CGRectMake(viewWidth + layer2.position.x, view2frame.minY, lineWidth, view2frame.height)
                
                return  !((frame1.maxX < frame2.minX) || (frame2.maxX < frame1.minX) )
            }
        }
        
        return false
    }
    
//    func overlap(view1: UIView, view2: UIView) -> Bool {
//        if let layer1 = view1.layer.presentationLayer() {
//            if let layer2 = view2.layer.presentationLayer() {
//                let frame1 = layer1.frame
//                let frame2 = layer2.frame
//                
//                return  !((frame1.maxX < frame2.minX) || (frame2.maxX < frame1.minX) )
//            }
//        }
//        
//        return false
//    }
    
//    func collision() -> Bool {
//        if !gameOverView.hidden {
//            return false
//        }
//        for line in self.lines {
//            if collide(square, view2: line) {
//                return true
//            }
//        }
//        return false
//    }
    
    func collision() -> Bool {
        if !gameOverView.hidden {
            return false
        }
        var lineIndex = 0
        for lineShape in self.lineShapes {
            
            if collide(square, view2: lineShape, lineFrame: self.lineFrames[lineIndex]) {
                return true
            }
//            print("HEIGHT: " + String(lineHeights[lineIndex]))
            lineIndex += 1
        }
        return false
    }
    
    func collide(view1: UIView, view2: CAShapeLayer, lineFrame: CGRect) -> Bool {
        
        if let layer1 = view1.layer.presentationLayer() {
            if let layer2 = view2.presentationLayer() {
                let positionX = layer2.position.x
                let positionY = layer2.position.y
                let frame1 = layer1.frame
                let frame2 = CGRectMake(viewWidth + positionX, lineFrame.minY, lineWidth, lineFrame.height)
                
//                print(frame2)
                
//                print("maxX " + String(frame2.maxX) + " minX " + String(frame2.minX))
//                print("height" + String(frame2.height))
//                print(layer2.position.x)
//                print("Position Y: " + String(layer2.position.y))
                
                return  !((frame1.maxX < frame2.minX) || (frame2.maxX < frame1.minX) || (frame1.maxY < frame2.minY) || (frame2.maxY < frame1.minY))
            }
        }
        
        return false
    }
    
//    func collide(view1: UIView, view2: UIView) -> Bool {
//        
//        if let layer1 = view1.layer.presentationLayer() {
//            if let layer2 = view2.layer.presentationLayer() {
//                let frame1 = layer1.frame
//                let frame2 = layer2.frame
//                
//                return  !((frame1.maxX < frame2.minX) || (frame2.maxX < frame1.minX) || (frame1.maxY < frame2.minY) || (frame2.maxY < frame1.minY))
//            }
//        }
//        
//        return false
//    }
    
    //==============================
    // MARK: - Touch Callbacks
    
    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first where traitCollection.forceTouchCapability == .Available {
            let ratio = touch.force/touch.maximumPossibleForce
            square.center = CGPointMake(squareX, maxY - ratio*(maxY - minY))
            
            if gameMode == "training" {
                scoreLabel.text = String(Int(round(ratio*385)))
            }
        }
    }
    
    
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        square.center = CGPointMake(squareX, maxY)
        
        if gameMode == "training" {
            scoreLabel.text = "0"
        }
    }
    
    //==============================
    // MARK: - Game Object initializers
    
    func initSquare() {
        square = UIView(frame: CGRect(x: 0, y: 0, width: squareWidth, height: squareWidth))
        square.backgroundColor = UIColor.blackColor()
        square.center = CGPointMake(squareX, maxY)
        square.layer.zPosition = 1
        self.view.addSubview(square)
    }
    
    func rectanglePathWithCenter(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPath {
        
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(x - width/2, y - height/2))
        path.addLineToPoint(CGPointMake(x + width/2, y - height/2))
        path.addLineToPoint(CGPointMake(x + width/2, y + height/2))
        path.addLineToPoint(CGPointMake(x - width/2, y + height/2))
        path.closePath()
        
        //path.bounds.maxX
        return path.CGPath
    }
    
    func rectanglePath(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CGPath {
        
        let path = UIBezierPath()
        path.moveToPoint(CGPointMake(x, y))
        path.addLineToPoint(CGPointMake(x + width, y))
        path.addLineToPoint(CGPointMake(x + width, y + height))
        path.addLineToPoint(CGPointMake(x, y + height))
        path.closePath()
        
        //path.bounds.maxX
        return path.CGPath
    }
    
    func rectangleCAShapeWithCenter(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CAShapeLayer {
        let lineShape = CAShapeLayer()
        lineShape.opacity = 1
        lineShape.lineWidth = 0
        lineShape.strokeColor = UIColor.blackColor().CGColor
        lineShape.lineJoin = kCALineJoinMiter
        lineShape.strokeColor = getLineColor().CGColor
        lineShape.fillColor = getLineColor().CGColor
        lineShape.path = rectanglePathWithCenter(self.view.frame.width/2, y: self.view.frame.height/2, width: squareWidth, height: self.view.frame.height)
        lineShape.zPosition = 0.9

        return lineShape
    }
    
    func rectangleCAShape(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) -> CAShapeLayer {
        let lineShape = CAShapeLayer()
        lineShape.opacity = 1
        lineShape.lineWidth = 0
        lineShape.strokeColor = UIColor.blackColor().CGColor
        lineShape.lineJoin = kCALineJoinMiter
        lineShape.strokeColor = getLineColor().CGColor
        lineShape.fillColor = getLineColor().CGColor
        lineShape.path = rectanglePath(x, y: y, width: width, height: height)
        lineShape.zPosition = 0.9
        
        return lineShape
    }
    
    func initLine(gapY: CGFloat, gapHeight: CGFloat) {
        let lineTopHeight = gapY - gapHeight/2
        let lineBottomHeight = viewHeight - (gapY + gapHeight/2)
        
        let lineTop = rectangleCAShape(viewWidth, y: 0, width: lineWidth, height: lineTopHeight)
        let lineBottom = rectangleCAShape(viewWidth, y: gapY + gapHeight/2, width: lineWidth, height: lineBottomHeight )
//        lineTop.backgroundColor = getLineColor()
//        lineBottom.backgroundColor = getLineColor()
        self.view.layer.addSublayer(lineTop)
        self.lineShapes.append(lineTop)
        self.lineFrames.append(CGRectMake(viewWidth, 0, lineWidth, lineTopHeight))
        self.view.layer.addSublayer(lineBottom)
        self.lineShapes.append(lineBottom)
        self.lineFrames.append(CGRectMake(viewWidth, gapY + gapHeight/2, lineWidth, lineBottomHeight))
        
        if lineNumber == 0 {
            self.view.backgroundColor = self.getBackgroundColor()
        } else if lineNumber % linesPerLevel == 0 {
            UIView.animateWithDuration(0.5, animations: {
                self.updateColors()
                }, completion: nil)
        }
        
        self.lineNumber += 1
        
//        let lineTopPosition = lineTop.position
//        let lineTopAnimation = CABasicAnimation(keyPath: "position")
//        lineTopAnimation.fromValue = lineTop.valueForKey("position")
//        lineTopAnimation.toValue = NSValue(CGPoint: CGPointMake(lineTopPosition.x - viewWidth - squareWidth, lineTopPosition.y))
//        lineTopAnimation.duration = lineTime()
//        lineTop.addAnimation(lineTopAnimation, forKey: "position")
//        lineTop.position = CGPointMake(0,0)
        
//        let lineTopPosition = lineTop.position
        let lineTopAnimation = CABasicAnimation(keyPath: "path")
        lineTopAnimation.fromValue = lineTop.valueForKey("path")
        lineTopAnimation.toValue = rectanglePath(-1*squareWidth, y: 0, width: lineWidth, height: lineTopHeight)
        lineTopAnimation.duration = lineTime()
        lineTop.addAnimation(lineTopAnimation, forKey: "path")
        lineTop.path = rectanglePath(-1*squareWidth, y: 0, width: lineWidth, height: viewHeight)
        
        let lineBottomPosition = lineBottom.position
        let lineBottomAnimation = CABasicAnimation(keyPath: "position")
        lineBottomAnimation.fromValue = lineBottom.valueForKey("position")
        lineBottomAnimation.toValue = NSValue(CGPoint: CGPointMake(lineBottomPosition.x - viewWidth - squareWidth, lineBottomPosition.y))
        lineBottomAnimation.duration = lineTime()
        lineBottom.addAnimation(lineBottomAnimation, forKey: "position")
        lineBottom.position = CGPointMake(0,0)
        
        
//        UIView.animateWithDuration(lineTime(), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
////            lineTop.path = self.rectanglePath(0 - self.lineWidth, y: 0, width: self.lineWidth, height: lineTopHeight)
////            lineBottom.path = self.rectanglePath(0 - self.lineWidth, y: gapY + gapHeight/2, width: self.lineWidth, height: lineBottomHeight)
//            lineTop.position = CGPointMake(0, 0)
//            lineTop.position = CGPointMake(0, 0)
//            }, completion: { finished in
//                
//                //TODO THIS IS IT? lineTop.presentationLayer()?.bounds
//                
//                lineTop.removeFromSuperlayer()
//                lineBottom.removeFromSuperlayer()
//                
//                // Lines may have been removed by stopGame()
//                if !self.lineShapes.isEmpty {
//                    self.lineShapes.removeFirst()
//                }
//                if !self.lineShapes.isEmpty {
//                    self.lineShapes.removeFirst()
//                }
//        })
        
        
    }

    
//    func initLine(gapY: CGFloat, gapHeight: CGFloat) {
//        let lineTopHeight = gapY - gapHeight/2
//        let lineBottomHeight = viewHeight - (gapY + gapHeight/2)
//        
//        let lineTop = UIView(frame: CGRect(x: viewWidth, y: 0, width: lineWidth, height: lineTopHeight))
//        let lineBottom = UIView(frame: CGRect(x: viewWidth, y: gapY + gapHeight/2, width: lineWidth, height: lineBottomHeight ))
//        lineTop.backgroundColor = getLineColor()
//        lineBottom.backgroundColor = getLineColor()
//        self.view.addSubview(lineTop)
//        self.lines.append(lineTop)
//        self.view.addSubview(lineBottom)
//        self.lines.append(lineBottom)
//        
//        if lineNumber == 0 {
//            self.view.backgroundColor = self.getBackgroundColor()
//        } else if lineNumber % linesPerLevel == 0 {
//            UIView.animateWithDuration(0.5, animations: {
//                self.updateColors()
//            }, completion: nil)
//        }
//        
//        self.lineNumber += 1
//        
//        UIView.animateWithDuration(lineTime(), delay: 0, options: UIViewAnimationOptions.CurveLinear, animations: {
//            lineTop.frame = CGRectMake(0 - self.lineWidth, 0, self.lineWidth, lineTopHeight)
//            lineBottom.frame = CGRectMake(0 - self.lineWidth, gapY + gapHeight/2, self.lineWidth, lineBottomHeight)
//            }, completion: { finished in
//                
//                
//                
//                lineTop.removeFromSuperview()
//                lineBottom.removeFromSuperview()
//                
//                // Lines may have been removed by stopGame()
//                if !self.lines.isEmpty {
//                    self.lines.removeFirst()
//                }
//                if !self.lines.isEmpty {
//                    self.lines.removeFirst()
//                }
//        })
//        
//      
//    }
    
    //==============================
    // MARK: - Levels
    
    func lineTime() -> Double {
        return MODES[gameMode]!["lineTime"]!
    }
    
    func lineGapTime() -> Double {
        return MODES[gameMode]!["lineGapTime"]!
    }
    
    func gapHeightMultiplier() -> Double {
        return MODES[gameMode]!["gapHeightMultiplier"]!
    }
    
    func updateColors() {
        self.view.backgroundColor = self.getBackgroundColor()
        self.gameOverView.backgroundColor = self.getGameOverViewBackground()
        self.replayButton.backgroundColor = self.getReplayButtonBackgroundColor()
        self.menuButton.backgroundColor = self.getMenuButtonBackgroundColor()
        self.facebookButton.backgroundColor = self.getFacebookButtonBackgroundColor()
    }
    
    let MODES = [
        "easy" : [
            "lineTime" : 3.0,
            "gapHeightMultiplier" : 0.3,
            "lineGapTime": 1.5
        ],
        "medium": [
            "lineTime" : 2.8,
            "gapHeightMultiplier" : 0.19,
            "lineGapTime": 1.3
        ],
        "hard" : [
            "lineTime" : 2.5,
            "gapHeightMultiplier" : 0.12,
            "lineGapTime": 0.9
        ],
        "insane" : [
            "lineTime" : 2.5,
            "gapHeightMultiplier" : 0.075,
            "lineGapTime": 0.75
        ],
        "training" : [
            "lineTime" : 2.5,
            "gapHeightMultiplier" : 0.0,
            "lineGapTime": 0.75
        ]
    ]
    
        
    //==============================
    // MARK: - Misc
    
    func bestScoreKey() -> String {
        return "bestScore" + gameMode.capitalizedString
    }
    
    @IBAction func replayPressed(sender: AnyObject) {
        stopGame()
        startGame()
    }
    @IBAction func menuPressed(sender: AnyObject) {
        stopGame()
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    @IBAction func facebookPressed(sender: AnyObject) {
    }
    @IBAction func exitGame(sender: AnyObject) {
        dispatch_async(dispatch_get_main_queue(),{
            self.timer.invalidate()
        })
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    func getLineColor() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let lineNumberInLevel = self.lineNumber % linesPerLevel
        let lineColors = LEVELS[levelIndex]["line_colors"]
        let lineColorIndex = lineNumberInLevel % (lineColors?.count)!
        let lineColorHex = lineColors![lineColorIndex]
        return colorLevels.colorWithHexString(lineColorHex as! String)
    }
    
    func getBackgroundColor() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let backgroundColorHex = LEVELS[levelIndex]["background_color"]
        return colorLevels.colorWithHexString(backgroundColorHex as! String)
    }
    
    func getGameOverViewBackground() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let backgroundColorHex = LEVELS[levelIndex]["game_over_background_color"]
        return colorLevels.colorWithHexString(backgroundColorHex as! String)
    }
    
    func getReplayButtonBackgroundColor() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let backgroundColorHex = LEVELS[levelIndex]["button1_color"]
        return colorLevels.colorWithHexString(backgroundColorHex as! String)
    }
    
    func getMenuButtonBackgroundColor() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let backgroundColorHex = LEVELS[levelIndex]["button2_color"]
        return colorLevels.colorWithHexString(backgroundColorHex as! String)
    }
    
    func getFacebookButtonBackgroundColor() -> UIColor {
        let levelNumber = self.lineNumber / linesPerLevel + randomLevelOffset
        let levelIndex = levelNumber % LEVELS.count
        let backgroundColorHex = LEVELS[levelIndex]["button3_color"]
        return colorLevels.colorWithHexString(backgroundColorHex as! String)
    }
    
    }

