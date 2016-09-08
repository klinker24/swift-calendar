import UIKit
import CoreData

class ViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var calendarView: CVCalendarView!
    @IBOutlet weak var menuView: CVCalendarMenuView!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var daysOutSwitch: UISwitch!
    
    var shouldShowDaysOut = false
    var animationFinished = true
    var switched = false
    
    var singleTap = false
    var doubleTap = false
    
    @IBOutlet weak var events: UILabel!
    
    var daysSet = NSMutableSet()
        
    @IBAction func todayClicked(sender: AnyObject) {
        self.switched = true
    }
    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        monthLabel.text = CVDate(date: NSDate()).globalDescription
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        calendarView.commitCalendarViewUpdate()
        menuView.commitMenuViewUpdate()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Event")

        do {
         let fetchedResults =
                try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            
            for r in fetchedResults! {
                let day = r.valueForKey("day") as! Int
                let month = r.valueForKey("month") as! Int
                let year = r.valueForKey("year") as! Int
                let s = "\(day) \(month) \(year)"
                
                daysSet.addObject(s)
            }
            
            print("set: \(daysSet)")
            
        } catch let error {
             print("Could not fetch \(error)")
        }
        
    }
    
    
}

// MARK: - CVCalendarViewDelegate

extension ViewController: CVCalendarViewDelegate
{
    func supplementaryView(viewOnDayView dayView: DayView) -> UIView
    {
        let π = M_PI
        
        let ringSpacing: CGFloat = 3.0
        let ringInsetWidth: CGFloat = 1.0
        let ringVerticalOffset: CGFloat = 1.0
        var ringLayer: CAShapeLayer!
        let ringLineWidth: CGFloat = 0.0
        let ringLineColour: UIColor = .blueColor()
        
        let newView = UIView(frame: dayView.bounds)
        
        let diameter: CGFloat = (newView.bounds.width) - ringSpacing
        let radius: CGFloat = diameter / 2.0
        
        let rect = CGRectMake(newView.frame.midX-radius, newView.frame.midY-radius-ringVerticalOffset, diameter, diameter)
        
        ringLayer = CAShapeLayer()
        newView.layer.addSublayer(ringLayer)
        
        ringLayer.fillColor = nil
        ringLayer.lineWidth = ringLineWidth
        ringLayer.strokeColor = ringLineColour.CGColor
        
        let ringLineWidthInset: CGFloat = CGFloat(ringLineWidth/2.0) + ringInsetWidth
        let ringRect: CGRect = CGRectInset(rect, ringLineWidthInset, ringLineWidthInset)
        let centrePoint: CGPoint = CGPointMake(ringRect.midX, ringRect.midY)
        let startAngle: CGFloat = CGFloat(-π/2.0)
        let endAngle: CGFloat = CGFloat(π * 2.0) + startAngle
        let ringPath: UIBezierPath = UIBezierPath(arcCenter: centrePoint, radius: ringRect.width/2.0, startAngle: startAngle, endAngle: endAngle, clockwise: true)
        
        ringLayer.path = ringPath.CGPath
        ringLayer.frame = newView.layer.bounds
        
        return newView
    }
    
    func supplementaryView(shouldDisplayOnDayView dayView: DayView) -> Bool
    {
        if (Int(arc4random_uniform(3)) == 1)
        {
            return true
        }
        return false
    }
    
    func presentationMode() -> CalendarMode {
        return .MonthView
    }
    
    func firstWeekday() -> Weekday {
        return .Sunday
    }
    
    func shouldShowWeekdaysOut() -> Bool {
        return shouldShowDaysOut
    }
    
    func didSelectDayView(dayView: CVCalendarDayView) {
        let date = dayView.date
        
        if (self.switched == true) {
            switched = false
            //return
        }
        
        let delay = 0.25 * Double(NSEC_PER_SEC);
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue()) {
            if (self.singleTap == true && self.doubleTap == false) {
                // todo: write the days events into the text field below the calendar
                print("single tap to display events")
                self.events.text = self.getEvents(date)
            }
            
            self.singleTap = false
            self.doubleTap = false
        }
        
        if (self.singleTap == true) {
            self.doubleTap = true
            
            print("double tap to open creation dialog")
            let events = self.getEvents(date)
            self.events.text = events
            createNewEventDialog(date, message: "")
        }
        
        self.singleTap = true
    }
    
    func getEvents(date: Date) -> String {
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        let fetchRequest = NSFetchRequest(entityName:"Event")
        
        var andList = [NSPredicate]()
        andList.append(NSPredicate(format: "day = %i", date.day as Int))
        andList.append(NSPredicate(format: "month = %i", date.month as Int))
        andList.append(NSPredicate(format: "year = %i", date.year as Int))
        
        let compound = NSCompoundPredicate.init(andPredicateWithSubpredicates: andList)
        
        
//        let compound = NSCompoundPredicate.andPredicateWithSubpredicates(andList)
        
        fetchRequest.predicate = compound
        var message = ""
        var current = 1
        
        do {
         let fetchedResults =
                try managedContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            for r in fetchedResults! {
                let val = r.valueForKey("title") as! String
                
                if (message != "") {
                    message = "\(message)\n"
                }
                
                message = "\(message)\(current).) \(val)"
                
                current = current + 1
            }
            
            if (message == "") {
                message = "No Scheduled Events"
            }
            
        } catch let error {
            print("Could not fetch \(error)")
            message = "No Scheduled Events"
        }
        
        return message
    }
    
    func createNewEventDialog(date: Date, message: String) {
        let alert = UIAlertController(title: "\(date.commonDescription)",
            message: message,
            preferredStyle: .Alert)
        
        let saveAction = UIAlertAction(title: "Add",
            style: .Default) { (action: UIAlertAction) -> Void in
                let textField = alert.textFields![0] 
                self.saveEvent(textField.text!, date: date)
        }
        
        let cancelAction = UIAlertAction(title: "Close",
            style: .Default) { (action: UIAlertAction) -> Void in
        }
        
        alert.addTextFieldWithConfigurationHandler {
            (textField: UITextField!) -> Void in
            let textField = alert.textFields![0] 
            textField.placeholder = "Add Event"
            textField.autocapitalizationType = UITextAutocapitalizationType.Words
        }
        
        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        
        presentViewController(alert,
            animated: true,
            completion: nil)
    }
    
    func saveEvent(title: String, date: Date) {
        //1
        let appDelegate =
        UIApplication.sharedApplication().delegate as! AppDelegate
        
        let managedContext = appDelegate.managedObjectContext!
        
        //2
        let entity =  NSEntityDescription.entityForName("Event",
            inManagedObjectContext:
            managedContext)
        
        let event = NSManagedObject(entity: entity!,
            insertIntoManagedObjectContext:managedContext)
        
        //3
        event.setValue(title, forKey: "title")
        event.setValue(date.day, forKey: "day")
        event.setValue(date.month, forKey: "month")
        event.setValue(date.year, forKey: "year")
        
        //4
        var error: NSError?
        do {
            try managedContext.save()
        } catch let error1 as NSError {
            error = error1
            print("Could not save \(error), \(error?.userInfo)")
        }
        
    }
    
    func presentedDateUpdated(date: CVDate) {
        if monthLabel.text != date.globalDescription && self.animationFinished {
            
            switched = true
            
            let updatedMonthLabel = UILabel()
            updatedMonthLabel.textColor = monthLabel.textColor
            updatedMonthLabel.font = monthLabel.font
            updatedMonthLabel.textAlignment = .Center
            updatedMonthLabel.text = date.globalDescription
            updatedMonthLabel.sizeToFit()
            updatedMonthLabel.alpha = 0
            updatedMonthLabel.center = self.monthLabel.center
            
            let offset = CGFloat(48)
            updatedMonthLabel.transform = CGAffineTransformMakeTranslation(0, offset)
            updatedMonthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
            
            UIView.animateWithDuration(0.35, delay: 0, options: UIViewAnimationOptions.CurveEaseIn, animations: {
                self.animationFinished = false
                self.monthLabel.transform = CGAffineTransformMakeTranslation(0, -offset)
                self.monthLabel.transform = CGAffineTransformMakeScale(1, 0.1)
                self.monthLabel.alpha = 0
                
                updatedMonthLabel.alpha = 1
                updatedMonthLabel.transform = CGAffineTransformIdentity
                
                }) { _ in
                    
                    self.animationFinished = true
                    self.monthLabel.frame = updatedMonthLabel.frame
                    self.monthLabel.text = updatedMonthLabel.text
                    self.monthLabel.transform = CGAffineTransformIdentity
                    self.monthLabel.alpha = 1
                    updatedMonthLabel.removeFromSuperview()
            }
            
            self.view.insertSubview(updatedMonthLabel, aboveSubview: self.monthLabel)
        }
    }
    
    func topMarker(shouldDisplayOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
    
    // TODO: dots for the days with events
    func dotMarker(shouldShowOnDayView dayView: CVCalendarDayView) -> Bool {
        let date = dayView.date
        
        if isToday(date) {
            return false
        }
        
        let s = "\(date.day) \(date.month) \(date.year)"
        
        if daysSet.containsObject(s) {
            return true
        }
        
        return false
    }
    
    func isToday(date : CVDate) -> Bool {
        let today = NSDate()
        let calendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Day, .Month, .Year], fromDate: today)
        let day = components.day
        let month = components.month
        let year = components.year
        
        if day == date.day && month == date.month && year == date.year {
            return true
        } else {
            return false
        }
    }
    
    func dotMarker(colorOnDayView dayView: CVCalendarDayView) -> UIColor {
        let day = dayView.date.day
        
        let red = CGFloat(0 / 255)
        let green = CGFloat(0 / 255)
        let blue = CGFloat(600 / 255)
        
        let color = UIColor(red: red, green: green, blue: blue, alpha: 1)

        return color
    }
    
    func dotMarker(shouldMoveOnHighlightingOnDayView dayView: CVCalendarDayView) -> Bool {
        return true
    }
}

// MARK: - CVCalendarViewAppearanceDelegate

extension ViewController: CVCalendarViewAppearanceDelegate {
    func dayLabelPresentWeekdayInitallyBold() -> Bool {
        return true
    }
    
    func spaceBetweenDayViews() -> CGFloat {
        return 2
    }
}

// MARK: - CVCalendarMenuViewDelegate

extension ViewController: CVCalendarMenuViewDelegate {
    // firstWeekday() has been already implemented.
}

// MARK: - IB Actions

extension ViewController {
    @IBAction func switchChanged(sender: UISwitch) {
        if sender.on {
            calendarView.changeDaysOutShowingState(false)
            shouldShowDaysOut = true
        } else {
            calendarView.changeDaysOutShowingState(true)
            shouldShowDaysOut = false
        }
    }
    
    @IBAction func todayMonthView() {
        calendarView.toggleCurrentDayView()
    }
    
    /// Switch to WeekView mode.
    @IBAction func toWeekView(sender: AnyObject) {
        calendarView.changeMode(.WeekView)
    }
    
    /// Switch to MonthView mode.
    @IBAction func toMonthView(sender: AnyObject) {
        calendarView.changeMode(.MonthView)
    }
    
    @IBAction func loadPrevious(sender: AnyObject) {
        calendarView.loadPreviousView()
    }
    
    
    @IBAction func loadNext(sender: AnyObject) {
        calendarView.loadNextView()
    }
}

// MARK: - Convenience API Demo

extension ViewController {
    func toggleMonthViewWithMonthOffset(offset: Int) {
        let calendar = NSCalendar.currentCalendar()
        let calendarManager = calendarView.manager
        let components = Manager.componentsForDate(NSDate()) // from today
        
        components.month += offset
        
        let resultDate = calendar.dateFromComponents(components)!
        
        self.calendarView.toggleViewWithDate(resultDate)
    }
}