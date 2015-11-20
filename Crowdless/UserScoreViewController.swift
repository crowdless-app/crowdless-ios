//
//  UserScoreViewController.swift
//  Crowdless
//
//  Created by Patrick Kelly on 11/10/15.
//  Copyright © 2015 Crowdless, Inc. All rights reserved.
//

import UIKit
import Parse
import ParseUI
import ReachabilitySwift
import CocoaLumberjack

class UserScoreViewController: UIViewController {
    
    var userScore: PFObject!
    var userScorePeerComment: PFObject!
    
    @IBOutlet var userImage: PFImageView!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var userComment: UILabel!
    @IBOutlet var userScoreTime: UILabel!
    @IBOutlet var userName: UILabel!
    @IBOutlet var reportButton: UIButton!
    @IBOutlet var helpfulButton: UIButton!
    @IBOutlet var wait: UILabel!
    @IBOutlet var waitImage: UIImageView!
    @IBOutlet var parking: UILabel!
    @IBOutlet var parkingImage: UIImageView!
    @IBOutlet var coverCharge: UILabel!
    @IBOutlet var coverChargeImage: UIImageView!
    @IBOutlet var crowded: UILabel!
    @IBOutlet var crowdedImage: UIImageView!
    @IBOutlet var helpful: UILabel!
    @IBOutlet var deleteScoreButton: UIButton!
    @IBOutlet var editScoreButton: UIButton!
    
    private var currentCalendar = NSCalendar.autoupdatingCurrentCalendar();
    private var reportActionSheet: UIAlertController!
    private var deleteActionSheet: UIAlertController!
    private var currentHelpfulCount = 0
    
    private let greenColor = UIColor(red: 123/255, green: 191/255, blue: 106/255, alpha: 1.0)
    private let yellowColor = UIColor(red: 254/255, green: 215/255, blue: 0/255, alpha: 1.0)
    private let redColor = UIColor(red: 224/255, green: 64/255, blue: 51/255, alpha: 1.0)
    private let malibuBlueColor = UIColor(red: 116/255, green: 169/255, blue: 255/255, alpha: 1.0)

    private var reachability: Reachability?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            reachability = try Reachability.reachabilityForInternetConnection()
        } catch {
            DDLogError("Unable to create Reachability")
            return
        }
        
        initView();
    }
    
    override func viewWillAppear(animated: Bool) {
        
        updateView();
        
        super.viewWillAppear(animated);
    }
    
    private func retrieveUserScorePeerComment() {
        
        let userScorePeerCommentQuery = PFQuery(className:"UserScorePeerComment")
        userScorePeerCommentQuery.whereKey("user", equalTo: PFUser.currentUser()!)
        userScorePeerCommentQuery.whereKey("userScore", equalTo: userScore)
        userScorePeerCommentQuery.orderByDescending("updatedAt")
        userScorePeerCommentQuery.findObjectsInBackgroundWithBlock( {
            [weak self] (results, error) -> Void in
            if let results = results {
                if(results.count > 0) {
                    self?.userScorePeerComment = results[0]
                    DDLogDebug("User score peer comment successfully retrieved for user: " +
                        PFUser.currentUser()!.objectId! + "and user score: " + (self?.userScore.objectId)!)
                    self?.updateUserScorePeerComments()
                } else {
                    self?.userScorePeerComment = PFObject(className: "UserScorePeerComment")
                    DDLogDebug("No user score peer comment for user: " +
                        PFUser.currentUser()!.objectId! + "and user score: " + (self?.userScore.objectId!)!)
                }
            } else {
                DDLogError("Error retrieving  user score peer comment from Parse: \(error)")
                self?.userScorePeerComment = PFObject(className: "UserScorePeerComment")
            }
        })
    }
    
    private func updateView() {
        
        let currentUser = PFUser.currentUser()!
        if currentUser.objectId == userScore["user"].objectId {
            helpfulButton.hidden = true
            reportButton.hidden = true
            editScoreButton.hidden = false
            deleteScoreButton.hidden = false
        } else {
            helpfulButton.hidden = false
            reportButton.hidden = false
            editScoreButton.hidden = true
            deleteScoreButton.hidden = true
            retrieveUserScorePeerComment()
        }
        
        let user = userScore["user"] as! PFUser
        let userImageFile = user["image"] as? PFFile
        userImage.file = userImageFile
        userImage.loadInBackground()
        
        userName.text = user["name"] as? String
        
        if let scoreTime = userScore.updatedAt {
            let formatter = NSDateFormatter()
            formatter.timeStyle = .ShortStyle
            if currentCalendar.isDateInToday(scoreTime) {
                userScoreTime.text = formatter.stringFromDate(scoreTime)
            } else if currentCalendar.isDateInYesterday(scoreTime) {
                userScoreTime.text = "Yesterday, " + formatter.stringFromDate(scoreTime)
            } else {
                formatter.dateStyle = .ShortStyle
                userScoreTime.text = formatter.stringFromDate(scoreTime)
            }
        } else {
            userScoreTime.text = ""
        }
        
        if let comment = userScore["comment"] {
            userComment.text = comment as? String
            userComment.font = UIFont(name:"HelveticaNeue", size: 14.0)
        } else {
            userComment.text = user["name"] as! String + " scored this crowd without a comment."
            userComment.font = UIFont(name:"HelveticaNeue-Italic", size: 14.0)
        }
        
        updateHelpfulLabelAndCount()
        updateUserCrowdScoreImagesAndLabels();
        
    }
    
    private func updateUserScorePeerComments() {
        helpfulButton.selected = userScorePeerComment["helpful"] as! Bool
        reportButton.selected = userScorePeerComment["reported"] as! Bool
    }
    
    private func updateHelpfulLabelAndCount() {
        currentHelpfulCount = 0;
        if let helpfulCount = userScore["helpfulCount"] {
            if helpfulCount as! Int > 0 {
                helpful.text = String(helpfulCount as! Int) + " found this helpful"
                currentHelpfulCount = helpfulCount as! Int;
            } else {
                helpful.text = "Be the first to find this score helpful"
            }
        } else {
            helpful.text = "Be the first to find this score helpful"
        }
    }
    
    private func updateUserCrowdScoreImagesAndLabels() {
        
        if let crowd = userScore["crowded"] as? Int {
            switch crowd {
            case 0:
                crowdedImage.image = UIImage(named: "people-green")
                crowded.text = "Not crowded"
                crowded.textColor = greenColor
            case 5:
                crowdedImage.image = UIImage(named: "people-red")
                crowded.text = "Crowded"
                crowded.textColor = redColor
            default:
                crowdedImage.image = UIImage(named: "people-green")
                crowded.text = "Not crowded"
                crowded.textColor = greenColor
            }
        }
        
        if let drove = userScore["drove"] as? Bool where drove {
            if let userParkingDifficult = userScore["parkingDifficult"] as? Int {
                if(userParkingDifficult == 5) {
                    parkingImage.image = UIImage(named: "car-red")
                    parking.text = "Difficult parking"
                    parking.textColor = redColor
                } else {
                    parkingImage.image = UIImage(named: "car-green")
                    parking.text = "Easy parking"
                    parking.textColor = greenColor
                }
            } else {
                parkingImage.image = UIImage(named: "car-white");
                parking.text = "Did not drive"
                parking.textColor = UIColor.whiteColor()
            }
        } else {
            parkingImage.image = UIImage(named: "car-white");
            parking.text = "Did not drive"
            parking.textColor = UIColor.whiteColor()
        }
        
        if let userEntranceCharge = userScore["coverCharge"] as? Int {
            switch userEntranceCharge {
            case 1:
                coverChargeImage.image = UIImage(named: "money-green")
                coverCharge.text = "$1-5 cover"
                coverCharge.textColor = greenColor
            case 3:
                coverChargeImage.image = UIImage(named: "money-yellow")
                coverCharge.text = "$6-10 cover"
                coverCharge.textColor = yellowColor
            case 5:
                coverChargeImage.image = UIImage(named: "money-red")
                coverCharge.text = "Over $10 cover"
                coverCharge.textColor = redColor
            default:
                coverChargeImage.image = UIImage(named: "money-white")
                coverCharge.text = "No cover"
                coverCharge.textColor = UIColor.whiteColor()
            }
        } else {
            coverChargeImage.image = UIImage(named: "money-white")
            coverCharge.text = "No cover"
            coverCharge.textColor = UIColor.whiteColor()
        }
        
        if let waitTime = userScore["waitTime"] as? Int {
            switch waitTime {
            case 1:
                waitImage.image = UIImage(named: "clock-green")
                wait.text = "1-9 min wait"
                wait.textColor = greenColor
            case 3:
                waitImage.image = UIImage(named: "clock-yellow")
                wait.text = "10-30 min wait"
                wait.textColor = yellowColor
            case 5:
                waitImage.image = UIImage(named: "clock-red")
                wait.text = "Over 30 min wait"
                wait.textColor = redColor
            default:
                waitImage.image = UIImage(named: "clock-white")
                wait.text = "No wait"
                wait.textColor = UIColor.whiteColor()
            }
        } else {
            waitImage.image = UIImage(named: "clock-white")
            wait.text = "No wait"
            wait.textColor = UIColor.whiteColor()
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func deleteButtonPressed(sender: AnyObject) {
        if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
            let popPresenter: UIPopoverPresentationController = deleteActionSheet.popoverPresentationController!
            popPresenter.permittedArrowDirections = .Up
            popPresenter.sourceView = sender as? UIView
            popPresenter.sourceRect = sender.bounds
        }
        self.presentViewController(deleteActionSheet, animated: true, completion: nil)
    }
    
    @IBAction func helpfulButtonPressed(sender: AnyObject) {
        helpfulButton.selected = !helpfulButton.selected;
        print(helpfulButton.selected)
        userScorePeerComment["helpful"] = helpfulButton.selected
        saveUserScorePeerComment()
        incrementCurrentHelpfulCountBy(helpfulButton.selected ? 1 : -1)
    }
    
    @IBAction func reportButtonPressed (sender: AnyObject) {
        if reportButton.selected {
            self.reportButton.selected = false;
            userScorePeerComment["reported"] = false
            userScorePeerComment.removeObjectForKey("reportedReason")
            saveUserScorePeerComment()
        } else {
            
            if UIDevice.currentDevice().userInterfaceIdiom == .Pad {
                let popPresenter: UIPopoverPresentationController = reportActionSheet.popoverPresentationController!
                popPresenter.sourceRect = sender.bounds
                popPresenter.sourceView = sender as? UIView
                popPresenter.permittedArrowDirections = .Up
            }
            
            self.presentViewController(reportActionSheet, animated: true, completion: nil)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "editScoreSegue", let destination = segue.destinationViewController as? ScorecardViewController {
            destination.userScore = userScore
        }
    }
    
    private func incrementCurrentHelpfulCountBy(incrementAmount: Int) {
        currentHelpfulCount = currentHelpfulCount + incrementAmount
        if (currentHelpfulCount) > 0 {
            helpful.text = String(currentHelpfulCount) + " found this helpful"
        } else {
            helpful.text = "Be the first person to find this score helpful"
        }
    }
    
    private func saveUserScorePeerComment() {
        
        let currentUser = PFUser.currentUser()!
        userScorePeerComment["user"] = currentUser
        userScorePeerComment["userScore"] = userScore
        userScorePeerComment.saveEventually {
            (success: Bool, error: NSError?) -> Void in
            if (success) {
                DDLogInfo("User score comment successfully saved for score: " + self.userScore.objectId!)
            } else {
                DDLogError("Error saving user score comment to Parse: \(error)")
            }
        }
    }
    
    private func deleteUserScore() {
        userScore.deleteInBackground()
        self.performSegueWithIdentifier("deleteUnwindSegue", sender: self)
    }
    
//    private func refreshUserScore() {
//        if let reachability = reachability {
//            if(reachability.isReachable()) {
//                userScore.fetchInBackgroundWithBlock({
//                    [weak self] (refreshedUserScore, error) -> Void in
//                    if error == nil {
//                        self?.userScore = refreshedUserScore
//                        self?.updateView()
//                    } else {
//                        DDLogError("Error fetching/refreshing user score: \(error)")
//                    }
//                })
//            } else {
//                DDLogError("Not reachable.  Can't refresh user score.")
//            }
//        }
//    }
    
    private func initView() {
        
        reportActionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        let offensive = UIAlertAction(title: "Offensive", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.reportButton.selected = true;
            self.userScorePeerComment["reported"] = true
            self.userScorePeerComment["reportedReason"] = "Offensive"
            self.saveUserScorePeerComment()
        })
        
        let spam = UIAlertAction(title: "Spam", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.reportButton.selected = true;
            self.userScorePeerComment["reported"] = true
            self.userScorePeerComment["reportedReason"] = "Spam"
            self.saveUserScorePeerComment()
        })
        
        let inappropriate = UIAlertAction(title: "Inappropriate", style: .Default, handler: {
            (alert: UIAlertAction!) -> Void in
            self.reportButton.selected = true;
            self.userScorePeerComment["reported"] = true
            self.userScorePeerComment["reportedReason"] = "Inappropriate"
            self.saveUserScorePeerComment()
        })
        
        let cancelReport = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        reportActionSheet.addAction(offensive)
        reportActionSheet.addAction(spam)
        reportActionSheet.addAction(inappropriate)
        reportActionSheet.addAction(cancelReport)
        
        deleteActionSheet = UIAlertController(title: "Are you sure you want to delete this score?", message: nil, preferredStyle: .ActionSheet)
        let delete = UIAlertAction(title: "Delete Score", style: .Destructive, handler: {
            (alert: UIAlertAction!) -> Void in
            self.deleteUserScore()
        })
        
        let cancelDelete = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        deleteActionSheet.addAction(delete)
        deleteActionSheet.addAction(cancelDelete)
        
        helpfulButton.setImage(UIImage(named: "helpful-star"), forState: .Selected)
        helpfulButton.setTitleColor(malibuBlueColor, forState: .Selected)
        helpfulButton.setImage(UIImage(named: "white-outline-star"), forState: .Normal)
        helpfulButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        
        reportButton.setImage(UIImage(named: "flag-red"), forState: .Selected)
        reportButton.setTitleColor(redColor, forState: .Selected)
        reportButton.setTitle("Reported", forState: .Selected)
        reportButton.setImage(UIImage(named: "flag-white"), forState: .Normal)
        reportButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        reportButton.setTitle("Report", forState: .Normal)
    }
}
