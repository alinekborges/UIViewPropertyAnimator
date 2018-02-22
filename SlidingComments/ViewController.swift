//
//  ViewController.swift
//  SlidingComments
//
//  Created by Aline Borges on 21/02/18.
//  Copyright © 2018 Aline Borges. All rights reserved.
//

import UIKit

enum State {
    case closed
    case open
    
    var opposite: State {
        return self == .open ? .closed : .open
    }
}

class ViewController: UIViewController {

    
    @IBOutlet weak var commentsView: UIView!
    @IBOutlet weak var commentsBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var commentsTitle: UILabel!
    @IBOutlet weak var titlePositionConstraint: NSLayoutConstraint!
    @IBOutlet weak var blurView: UIVisualEffectView!
    @IBOutlet weak var icon: UIImageView!
    
    //Array with all animators for the view
    var runningAnimators: [UIViewPropertyAnimator] = []
    
    //Current state of comments view
    var state: State = .closed
    
    
    var viewOffset: CGFloat = 300
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }
    
    /*
        Creates new animators based on the state the view wants to go
        On animation complete (means view went to desired state) it will remove all animators
        And wait to be called again
     
        This function should be called on .began of drag gesture
    */
    func animateIfNeeded(to state: State, duration: TimeInterval) {
        
        //if there is animators running, ignore
        guard runningAnimators.isEmpty else { return }
        
        //Creates a basic animator to take care of the states of the view
        let basicAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeIn, animations: nil)
        
        //Add animations to the animator
        //Related to view position, corner radius and icon alpha
        //Just use the desired value for each state (closed or open)
        basicAnimator.addAnimations {
            switch state {
            case .open:
                self.commentsBottomConstraint.constant = self.viewOffset
                self.commentsView.layer.cornerRadius = 60
            case .closed:
                self.commentsBottomConstraint.constant = 0
                self.commentsView.layer.cornerRadius = 0
            }
            self.view.layoutIfNeeded()
        }
        
        //Add animations related to titlePosition, size and icon alpha
        basicAnimator.addAnimations {
            switch state {
            case .open:
                self.titlePositionConstraint.constant = 130
                self.commentsTitle.transform = CGAffineTransform(scaleX: 1, y: 1)
                self.icon.alpha = 0
            case .closed:
                self.titlePositionConstraint.constant = 52
                self.commentsTitle.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
                self.icon.alpha = 1
            }
            self.view.layoutIfNeeded()
        }
        
        //Create an animator for the blur background
        //Use custom curve so the blur starts very slow
        let blurAnimator = UIViewPropertyAnimator(
            duration: duration,
            controlPoint1: CGPoint(x: 0.8, y: 0.2),
            controlPoint2: CGPoint(x: 0.8, y: 0.2)) {
            switch state {
            case .open:
                self.blurView.effect = UIBlurEffect(style: .light)
            case .closed:
                self.blurView.effect = nil
            }
        }
        blurAnimator.scrubsLinearly = false //needed to scrub conforming to custom curve
        
        
        basicAnimator.addCompletion { position in
            self.runningAnimators.removeAll()
            self.state = self.state.opposite //change the current state to the opposite
        }

        
        runningAnimators.append(basicAnimator)
        runningAnimators.append(blurAnimator)
        
    }
    
    @objc func onDrag(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            //create animations to desired state
            animateIfNeeded(to: state.opposite, duration: 0.4)
        case .changed:
            //calculates the percent of completion and sets it to all running animators
            let translation = gesture.translation(in: commentsView)
            let fraction = abs(translation.y / viewOffset)
            
            runningAnimators.forEach { animator in
                animator.fractionComplete = fraction
            }
        case .ended:
            //finish running animations to desired state
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
        default:
            break
        }
        
    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        
        //create animations and 
        animateIfNeeded(to: state.opposite, duration: 0.4)
        runningAnimators.forEach { $0.startAnimation() }
        
    }
    
    func setupViews() {
        
        //setup closed state for comments view
        self.commentsBottomConstraint.constant = 0
        self.commentsTitle.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        self.blurView.effect = nil
        self.blurView.isHidden = false
        self.view.layoutIfNeeded()
        
        //create pan gesture recognizer and add it to view
        //pan gesture is responsible for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onDrag(_:)))
        self.commentsView.addGestureRecognizer(panGesture)
        
        //create tap gesture recognizer and add to view
        //view will open and close on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:)))
        self.commentsView.addGestureRecognizer(tapGesture)
        
        //maske corners of comment view so corner radius is applied only to top corners
        self.commentsView.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMinXMinYCorner]
        
        //add shadow to look pretty :)
        self.commentsView.layer.shadowColor = UIColor.black.cgColor
        self.commentsView.layer.shadowOpacity = 1
        self.commentsView.layer.shadowRadius = 3
        
    }
}
