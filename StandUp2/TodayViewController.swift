//
//  TodayViewController.swift
//  StandUp2
//
//  Created by Lindsey.Hanna on 4/6/15.
//  Copyright (c) 2015 Lindsey.Hanna. All rights reserved.
//

import UIKit
import CoreData

class TodayViewController: UIViewController, UITableViewDataSource, UITableViewDelegate/*, AddEditViewControllerDelegate*/ {
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    let formatter = NSDateFormatter()
    let today = NSCalendar.currentCalendar().startOfDayForDate(NSDate())
    
    // Outlets
    @IBOutlet weak var activityListTable: UITableView!
    @IBOutlet weak var pieChartView: PieChartView2!
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var addItemButton: UIButton!
    @IBOutlet weak var nextDayOutlet: UIButton!
    
    // Actions
    @IBAction func refreshButton(sender: AnyObject) {
        refreshTodayView()
    }
    
    @IBAction func nextDayButton(sender: AnyObject) {
        changeRenderedDay(1)
    }
    @IBAction func prevDayButton(sender: AnyObject) {
        changeRenderedDay(-1)
    }
    // Local Variables
    var activityRecordsList = [ActivityRecord]()
    let tableCellID2 = "ActivityListItem"
    var requestedDate = NSDate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let moc = self.managedObjectContext {
            
            activityListTable.delegate = self
            activityListTable.dataSource = self
        }
        // Do any additional setup after loading the view, typically from a nib.
        
        
//        dummyData()
        
        refreshTodayView()
        dateLabel.text = "Today"
        nextDayOutlet.enabled = false
        
        formatter.dateStyle = NSDateFormatterStyle.LongStyle
        formatter.timeStyle = NSDateFormatterStyle.NoStyle
        
    }

    func dummyData() {
    
        var data = getDummyData(5)
    
        for (var i = 0; i < data.count; i++) {
            var record = data[i]
            ActivityRecord.createInManagedObjectContext(
                self.managedObjectContext!,
                type: record.activityType,
                startTime: record.startTime,
                endTime: record.endTime)
        }
    }

    func fetchLog() {
        let fetchRequest = NSFetchRequest(entityName: "ActivityRecord")
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "startTime", ascending: true)]
        fetchRequest.shouldRefreshRefetchedObjects = true
        
        var startDate = NSCalendar.currentCalendar().startOfDayForDate(requestedDate)
        var endDate = NSDate(timeInterval: NSTimeInterval(60*60*24), sinceDate: NSCalendar.currentCalendar().startOfDayForDate(requestedDate))
        
        let datePredicate = NSPredicate(format: "startTime BETWEEN {%@, %@}", argumentArray: [startDate, endDate])
        
        fetchRequest.predicate = datePredicate
        
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [ActivityRecord] {
            activityRecordsList = fetchResults
        }
        activityListTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    // MARK:  UITextFieldDelegate Methods
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activityRecordsList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(tableCellID2, forIndexPath: indexPath) as! UITableViewCell
        
        let row = indexPath.row
        let record = activityRecordsList[row]
        var elapsedTime = record.endTime.timeIntervalSinceDate(record.startTime)
        
        let elapsedTimeText = createDurationString(elapsedTime)
        cell.textLabel?.text = activityRecordsList[row].type + " - " + elapsedTimeText
        
        return cell
    }
    
    // MARK:  UITableViewDelegate Methods
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
//        let row = indexPath.row
//        println(activityRecordsList[row].type)
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // placeholder so editActionsforRowAtIndexPath works
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]?  {
        // 1: delete
        var deleteAction = UITableViewRowAction(style: UITableViewRowActionStyle.Default, title: "Delete" , handler: { (action: UITableViewRowAction!, indexPath: NSIndexPath!) -> Void in
            let itemToDelete = self.activityRecordsList[indexPath.row]
            
            self.managedObjectContext?.deleteObject(itemToDelete)
            self.refreshTodayView()
        })
        
        // 2: edit
        var editAction = UITableViewRowAction(style: UITableViewRowActionStyle.Normal, title: "Edit" , handler: { (action:UITableViewRowAction!, indexPath:NSIndexPath!) -> Void in
            tableView.editing = false
            
            // show AddEditViewController
            var editVC = self.storyboard?.instantiateViewControllerWithIdentifier("addEdit") as! AddEditViewController
            editVC.isEditPicker = true
            editVC.inputRecord = self.activityRecordsList[indexPath.row]
            self.presentViewController(editVC, animated: true, completion: nil)
        })
        editAction.backgroundColor = UIColor.grayColor();
        
        return [deleteAction, editAction]
    }
    
    // MARK: rendering methods
    func refreshTodayView() {
        fetchLog()
        drawPieChartView()
    }

    func drawPieChartView() {
        pieChartView.clearItems()
        for (var i = 0; i < activityRecordsList.count; i++) {
            let record = activityRecordsList[i]
            
            pieChartView.addItem(record.startTime, endTime: record.endTime, activityType: record.type)
        }
        pieChartView.setNeedsDisplay()
    }
    
    override func viewWillAppear(animated: Bool) {
//        requestedDate = NSDate(timeInterval: NSTimeInterval(-60*60*24), sinceDate: requestedDate)
        refreshTodayView()
    }

    // timeDirection should be -1 for prev day, 1 for next day
    func changeRenderedDay(timeDirection: Int) {
        requestedDate = NSDate(timeInterval: NSTimeInterval(timeDirection*60*60*24), sinceDate: requestedDate)
        if (NSCalendar.currentCalendar().startOfDayForDate(requestedDate) == today) {
            dateLabel.text = "Today"
            nextDayOutlet.enabled = false
        } else {
            dateLabel.text = formatter.stringFromDate(requestedDate)
            nextDayOutlet.enabled = true
        }
        refreshTodayView()
    }
    
    // MARK: AddEditViewControllerDelegate Methods
//    func myVCDidFinish(controller: AddEditViewController, text: String) {
//        controller.dismissViewControllerAnimated(true, completion: nil)
//    }
    
//    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
//        if segue.identifier == "addEditSegue" {
//            let vc = segue.destinationViewController as! AddEditViewController
//            vc.delegate = self
//            
//            // if we are editing, let the AddEditViewController know
//            if let isEdit : AnyObject? = sender?["inputRecord"] {
//                vc.isEditPicker = true
//                vc.inputRecord = sender?["inputRecord"] as? ActivityRecord
//            }
//        }
//    }
}

