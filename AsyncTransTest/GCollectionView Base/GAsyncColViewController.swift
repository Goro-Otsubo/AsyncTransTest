//
//  GAsyncColViewController.swift
//  GPaperTrans
//
//  Created by 大坪五郎 on 2014/12/24.
//  Copyright (c) 2014年 demodev. All rights reserved.
//

import UIKit


//Base UICollectionViewController class
//also serves as view controller for magnified view

class GAsyncColViewController: UIViewController,UIGestureRecognizerDelegate ,ASCollectionViewDataSource,ASCollectionViewDelegate{
    
    class var instance: GAsyncColViewController {
        struct Instance {
            static let i = GAsyncColViewController(nibName:nil,bundle:nil)
        }
        return Instance.i
    }
    
    var initialPanPoint:CGPoint     // record the point where pan began
    var shortLayout:UICollectionViewFlowLayout  //layout for short height collectionViewCell
    var tallLayout:UICollectionViewFlowLayout   //layout for tall height collectionViewCell
    var toBeExpandedFlag:Bool       //true if transition from short to tall. false if otherwise
    var targetY:CGFloat             //if the touch point moved to this y values, progress should be 1.0
    var panRecog:UIPanGestureRecognizer?
    var transitioningFlag = false   //true from collectioView.startInt.. to finishUpInteraction
    var changedFlag = false         //true if UIGestureRecognizerState.Changed  after interaction began
    var collectionView:ASCollectionView?
    
    override required init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        self.initialPanPoint = CGPointZero
        self.toBeExpandedFlag = true
        self.targetY = 0
        self.shortLayout = UICollectionViewFlowLayout()
        self.tallLayout = UICollectionViewFlowLayout()
        self.panRecog = nil
        self.collectionView = nil
        super.init(nibName:nibNameOrNil, bundle:nibBundleOrNil)

    }
    
    func setLayout(layout:UICollectionViewLayout) {
        self.collectionView = ASCollectionView(frame: CGRectZero, collectionViewLayout: layout)

        collectionView?.asyncDataSource = self
        collectionView?.asyncDelegate = self
        //Gesture recognizer
        self.panRecog = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panRecog!.delegate = self
        
        self.collectionView!.addGestureRecognizer(panRecog!)
        
    }
    
    func isSingletonSet()->Bool{
        if self.collectionView == nil {
            return false
        }
        else{
            return true
        }
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("storyboards are incompatible with truth and beauty")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let viewWidth:CGFloat = CGRectGetWidth(self.view.frame)
        let viewHeight:CGFloat = CGRectGetHeight(self.view.frame)

        let cellSizeRatio:CGFloat = 0.4
        let cellHeight:CGFloat = viewHeight*cellSizeRatio
        
        // Create first choice view and set as rootViewController
        self.shortLayout = UICollectionViewFlowLayout()
        shortLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        shortLayout.itemSize = CGSizeMake(viewWidth*cellSizeRatio,cellHeight)
        
        //        shortLayout.itemSize = CGSizeMake(viewWidth*cellSizeRatio,viewHeight)
        shortLayout.sectionInset = UIEdgeInsetsMake(viewHeight - cellHeight, 0, 0, 0)
        //shortLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        shortLayout.minimumInteritemSpacing = 0
        shortLayout.minimumLineSpacing = 3
        
        self.tallLayout = UICollectionViewFlowLayout()
        tallLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        
        tallLayout.itemSize = CGSizeMake(viewWidth,viewHeight)
        tallLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        tallLayout.minimumInteritemSpacing = 0
        tallLayout.minimumLineSpacing = 3
        
        
        self.collectionView = ASCollectionView(frame:
            CGRectMake(0,0,CGRectGetWidth(self.view.frame),CGRectGetHeight(self.view.frame)),
            collectionViewLayout: shortLayout)
        
        collectionView?.asyncDataSource = self
        collectionView?.asyncDelegate = self
        //Gesture recognizer
        self.panRecog = UIPanGestureRecognizer(target: self, action: "handlePan:")
        panRecog!.delegate = self
        
        self.collectionView!.addGestureRecognizer(panRecog!)
        
        self.collectionView!.backgroundColor = UIColor.clearColor()
        

        self.view.addSubview(self.collectionView!)
        
 
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewDidAppear(animated: Bool) {


    }
    
    
    // MARK: ASCommonCollectionViewDataSource
    
    func collectionView(collectionView: ASCollectionView!, nodeForItemAtIndexPath indexPath: NSIndexPath!) -> ASCellNode! {
        
        let cell = GAsyncCell()
        cell.setIndex(indexPath.row)
        return cell
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView!) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView!, numberOfItemsInSection sectionNo: Int) ->Int{
        return 100
    }
    

    
    
    func getItemSize()->CGSize{
        let layout = self.collectionView!.collectionViewLayout
        if layout.isKindOfClass(UICollectionViewFlowLayout) {
            return (layout as UICollectionViewFlowLayout).itemSize
        }
        else{
            let tlayout = layout as UICollectionViewTransitionLayout
            let progress = tlayout.transitionProgress
            var zwidth = toBeExpandedFlag ? shortLayout.itemSize.width : tallLayout.itemSize.width
            var owidth = toBeExpandedFlag ? tallLayout.itemSize.width :shortLayout.itemSize.width
            var zheight = toBeExpandedFlag ? shortLayout.itemSize.height : tallLayout.itemSize.height
            var oheight = toBeExpandedFlag ? tallLayout.itemSize.height :shortLayout.itemSize.height
            
            return CGSizeMake(owidth * progress + (1-progress)*zwidth,
                oheight * progress + (1-progress)*zheight
            )
        }
    }
    
    func collectionView(collectionView: UICollectionView,
        transitionLayoutForOldLayout fromLayout: UICollectionViewLayout,
        newLayout toLayout: UICollectionViewLayout) -> UICollectionViewTransitionLayout
    {
        //let ret = UICollectionViewTransitionLayout(currentLayout:fromLayout, nextLayout: toLayout)
        let ret = GTransLayout(currentLayout:fromLayout, nextLayout: toLayout)
        return ret
        
    }
    
    func removeAnimation(){
        
        //completionBlock is executed when animation is removed.
        //therefore, make completionBlock nil before removal
        
        let anim: POPBasicAnimation? = self.pop_animationForKey("animation") as POPBasicAnimation?
        
        if anim != nil{
            anim!.completionBlock = nil
        }
        self.pop_removeAllAnimations()
    }
    
    // MARK: Gesture recognizer related
    
    func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool
    {
        if(gestureRecognizer === self.panRecog) {
            let panRecog = gestureRecognizer as UIPanGestureRecognizer
            let direction = panRecog.velocityInView(panRecog.view)
            let pos = panRecog.locationInView(panRecog.view)
            
            //if touch point of out of range of cell, return false
            if toBeExpandedFlag {
                if CGRectGetHeight(self.collectionView!.frame) - shortLayout.itemSize.height > pos.y{
                    return false
                }
            }
            
            // if swipe for vertical direction, returns true
            
            if abs(direction.y) >  abs(direction.x)  {
                return true
            }
            else{
                return false
            }
        }
        else{
            return true
        }
    }
    
    
    func handlePan(sender:UIPanGestureRecognizer){
        
        let point = sender.locationInView(sender.view)
        let velocity = sender.velocityInView(sender.view)
        
        //limit the range of velocity so that animation will not stop when verlocity is 0
        
        let yVelocity = CGFloat(max(min(abs(velocity.y),80.0),20.0))
        
        let progress = max(min(abs(point.y - initialPanPoint.y)/abs(targetY - initialPanPoint.y),1.0),0.0)
        
        switch sender.state{
            
        case UIGestureRecognizerState.Began:
            
            changedFlag = false     //clear flag here
            
            if let transLayout = getTransitionLayout(){
                //animation is interrupted by user action
                //initialPoint.y and targetY has to be updated according to progress
                //and touched position
                updatePositionData(point,progress: transLayout.transitionProgress)
                return;
            }
            if (velocity.y > 0 && toBeExpandedFlag) || (velocity.y < 0 && !toBeExpandedFlag) {
                //only respond to one direction of swipe
                return
            }
            
            self.initialPanPoint = point    // record the point where gesture began
            
            let tallHeight = tallLayout.itemSize.height
            let shortHeight = shortLayout.itemSize.height
            
            var hRatio = (tallHeight - self.initialPanPoint.y) / (self.toBeExpandedFlag ? shortHeight : tallHeight)
            
            // when the touch point.y reached targetY, that meanas progress = 1.0
            // update targetY value
            
            self.targetY = tallHeight - hRatio * (self.toBeExpandedFlag ? tallHeight : shortHeight)
            
            self.collectionView!.startInteractiveTransitionToCollectionViewLayout(
                toBeExpandedFlag ? tallLayout : shortLayout,
                completion: { completed, finished in
                    //self.postInteractionFinished()

            })
            transitioningFlag = true
            
        case UIGestureRecognizerState.Changed:
            if !transitioningFlag {//if not transitoning, return
                return
            }
            //            println("##changed")
            changedFlag = true  // set flag here
            
            self.removeAnimation()  //remove on-going animation here
            
            //update position only when point.y is between initialPoint.y and targety
            if (point.y - initialPanPoint.y) * (point.y - targetY) <= 0 {
                updateWithProgress(progress)
            }
        case UIGestureRecognizerState.Ended,UIGestureRecognizerState.Cancelled:
            
            if !changedFlag {//without this guard, collectionview behaves strangely
                return
            }
            
            if let layout = self.getTransitionLayout(){
                
                let success = layout.transitionProgress > 0.5

                    var yToReach : CGFloat
                    if success {
                        yToReach = targetY
                    }
                    else{
                        yToReach = initialPanPoint.y
                    }
                    let durationToFinish = abs(yToReach - point.y) / yVelocity
                    self.finishInteractiveTransition(progress, duration: durationToFinish, success:success)
                }

            
        default:
            break
        }
        
    }
    
    func updatePositionData(point:CGPoint,progress:CGFloat){
        let tallHeight = tallLayout.itemSize.height
        let shortHeight = shortLayout.itemSize.height
        
        let itemHeight = (1-progress) * (toBeExpandedFlag ? shortHeight : tallHeight)
            + progress * (toBeExpandedFlag ? tallHeight : shortHeight)
        let hRatio = (tallLayout.itemSize.height - point.y) / itemHeight
        
        initialPanPoint.y = tallHeight - hRatio * (toBeExpandedFlag ? shortLayout.itemSize.height:tallLayout.itemSize.height)
        targetY = tallHeight - hRatio * (toBeExpandedFlag ? tallLayout.itemSize.height:shortLayout.itemSize.height)
    }
    

    
    
    func finishInteractiveTransition(progress:CGFloat,duration:CGFloat,success:Bool){
        
        if (success && (progress >= 1.0)) || (!success && (progress <= 0.0)) {
            // no need to animate
            self.finishUpInteraction(success)
        }
        else if self.pop_animationForKey("animation") == nil {
            
            //add end interaction animation
            
            let prop:POPAnimatableProperty = POPAnimatableProperty.propertyWithName("com.goromi.ptrans.progress", initializer: {prop in
                prop.readBlock = {obj, values in
                    if let layout = self.getTransitionLayout(){
                        values[0] = layout.transitionProgress
                    }
                }
                prop.writeBlock = {obj, values in
                    //println("value = \(values[0])")
                    self.updateWithProgress(values[0])
                }
                prop.threshold = 0.1
            }) as POPAnimatableProperty
            
            let anim = POPBasicAnimation()
            anim.property = prop
            anim.fromValue = progress
            anim.toValue = success ? 1.0 : 0.0
            
            anim.completionBlock = { animation, finished in
                self.finishUpInteraction(success)
            }
            self.pop_addAnimation(anim, forKey: "animation")
        }
        
    }
    
    func finishUpInteraction(success:Bool){
        if !transitioningFlag {
            return
        }
        
        if success {
            self.updateWithProgress(1.0)
            self.collectionView!.finishInteractiveTransition()
            transitioningFlag = false
            self.toBeExpandedFlag = !self.toBeExpandedFlag
        }
        else{
            self.updateWithProgress(0.0)
            self.collectionView!.cancelInteractiveTransition()
            transitioningFlag = false
        }
    }
    
    
    func stopGesture(){
        self.panRecog!.enabled = false
    }
    
    func startGesture(){
        self.panRecog!.enabled = true
    }
    
    func updateWithProgress(progress:CGFloat){
        //collectionViewLayout may be changed between flowLayout and transitionLayout
        //at any time. therefore, this guard is needed
        
        if let layout = getTransitionLayout(){
            layout.transitionProgress = progress
            (NSNotificationCenter.defaultCenter()).postNotificationName("SizeNotification", object: nil, userInfo: nil)
        }
    }
    
    func getTransitionLayout()->UICollectionViewTransitionLayout?{
        
        let layout = self.collectionView!.collectionViewLayout
        
        if layout.isKindOfClass(UICollectionViewTransitionLayout) {
            return layout as? UICollectionViewTransitionLayout
        }
        else{
            return nil
        }
    }
    
    //to enable user to interact both vertically and horizontally, may need to
    //return yes here. but at this point, it just messes up.
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool{
            return false
    }
    

}