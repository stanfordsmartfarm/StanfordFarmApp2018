//
//  BedViewController.swift
//  StanfordFarmApp2018
//
//  Created by Matthew Park on 8/8/18.
//  Copyright © 2018 Matthew Park. All rights reserved.
//

import UIKit
import Charts

class BedViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var chartsView: UIView!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var manualIrrigationControlView: UIView!
    @IBOutlet weak var manualIrrigationControlWidth: NSLayoutConstraint!
    @IBOutlet weak var manualIrrigationControlTitle: UILabel!
    @IBOutlet weak var manualIrrigationControlStatus: UILabel!
    @IBOutlet weak var scheduleCollectionView: UICollectionView!
    @IBOutlet weak var scheduleIrrigationView: UIView!
    @IBOutlet weak var sensorsSelectionView: UIView!
    @IBOutlet weak var sensorsSelectionTableView: UITableView!
    @IBOutlet weak var irrigationQueueView: UIView!
    @IBOutlet weak var scheduleSingleIrrigationView: UIView!
    @IBOutlet weak var irrigationQueueTableView: UITableView!
    @IBOutlet weak var scheduleSingleIrrigationLabel: UILabel!
    @IBOutlet weak var scheduleSingleIrrigationDatePicker: UIDatePicker!
    @IBOutlet weak var confirmStartTimeView: UIView!
    @IBOutlet weak var deleteView: UIView!
    @IBOutlet weak var confirmEndTimeView: UIView!
    
    private var numberOfSensors = 0
    var scheduleModal_dayInt = -1
    
    private var scatterChartView: ScatterChartView?
    
    var scheduledIrrigationStartValue:Date? = Date()
    var hideEndConfirm: Bool = true {
        didSet {
            self.configureScheduleSingleIrrigation()
        }
    }
    
    var bedNo: Int? {
        didSet {
            self.configure()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sensorsSelectionTableView.delegate = self
        sensorsSelectionTableView.dataSource = self
        irrigationQueueTableView.delegate = self
        irrigationQueueTableView.dataSource = self
        scheduleCollectionView.delegate = self
        scheduleCollectionView.dataSource = self
        
        irrigationQueueTableView.rowHeight = (irrigationQueueTableView.frame.height+1)/5
        sensorsSelectionTableView.rowHeight = (sensorsSelectionTableView.frame.height+1)/7
        
        chartsView.layer.cornerRadius = 4.0
        manualIrrigationControlView.layer.cornerRadius = 4.0
        scheduleIrrigationView.layer.cornerRadius = 4.0
        sensorsSelectionView.layer.cornerRadius = 4.0
        irrigationQueueView.layer.cornerRadius = 4.0
        scheduleSingleIrrigationView.layer.cornerRadius = 4.0
        confirmStartTimeView.layer.cornerRadius = 4.0
        deleteView.layer.cornerRadius = 4.0
        confirmEndTimeView.layer.cornerRadius = 4.0
        
        configureChart()
        
        dataModel.bed_sensorDataDownloadedCallback = {
            self.processDataCharts()
        }
        
        dataModel.bed_iFlag_Callback = {
            self.configure()
        }
        
        dataModel.bed_iSchedule_Callback = {
            DispatchQueue.main.async {
                self.scheduleCollectionView.reloadData()
            }
        }
        
        dataModel.bed_iQueueBed_Callback = {
            DispatchQueue.main.async {
                self.irrigationQueueTableView.reloadData()
            }
        }
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        manualIrrigationControlWidth.constant = ((self.view.frame.width - (16.0*7.0)) / 6.0)
        self.view.layoutIfNeeded()
    }
    
    func configure() {
        if let bedNo = self.bedNo {
            scrollView.contentOffset = CGPoint(x: 0, y: 0)
            scheduleSingleIrrigationDatePicker.date = Date()
            numberOfSensors = 0
            titleLabel.text = "Bed \(bedNo)"
            manualIrrigationControlTitle.text = "Bed \(bedNo)"
            dataModel.firebaseGet_SensorData(forBed: bedNo)
            
            if let iBool = dataModel.dashboard_iFlagData["G\(bedNo)"] {
                manualIrrigationControlStatus.text = iBool ? "ON" : "OFF"
                manualIrrigationControlStatus.textColor = iBool ? UIColor.white : UIColor.lightGray
                manualIrrigationControlTitle.textColor = iBool ? UIColor.white : UIColor.lightGray
                manualIrrigationControlView.backgroundColor = iBool ? greenColor : UIColor.white
            }
            
            DispatchQueue.main.async {
                self.scheduleCollectionView.reloadData()
                self.irrigationQueueTableView.reloadData()
                self.sensorsSelectionTableView.reloadData()
            }
        }
    }
    
    // MARK: - Chart Settings
    
    func configureChart() {
        scatterChartView = ScatterChartView()
        
        let description = Description()
        description.text = ""
        
        scatterChartView?.clipsToBounds = false
        scatterChartView?.chartDescription = description
        scatterChartView?.frame = self.chartView.frame
        scatterChartView?.xAxis.valueFormatter = self
        scatterChartView?.xAxis.labelPosition = .bottom
        scatterChartView?.xAxis.drawGridLinesEnabled = false
        scatterChartView?.xAxis.labelFont = UIFont(name: "AvenirNext-Regular", size: 12)!
        scatterChartView?.leftAxis.labelFont = UIFont(name: "AvenirNext-Regular", size: 12)!
        scatterChartView?.leftAxis.gridColor = UIColor.lightGray
        scatterChartView?.rightAxis.enabled = false
        scatterChartView?.legend.enabled = false
        scatterChartView?.noDataText = ""
        self.chartsView.addSubview(scatterChartView!)
    }
    
    func processDataCharts() {
        if let bedNo = self.bedNo {
            if let sensorData = dataModel.bed_sensorDataDictCharts["G\(bedNo)"] {
                let data = ScatterChartData()
                self.numberOfSensors = sensorData.keys.count
                
                for sensor in sensorData.keys {
                    let dataSet = ScatterChartDataSet(values: sensorData[sensor]!, label: sensor.capitalized)
                    dataSet.scatterShapeSize = 3.0
                    dataSet.colors = [NSUIColor(cgColor: redColor.cgColor)]
                    data.addDataSet(dataSet)
                }
                
                scatterChartView?.data = data
                DispatchQueue.main.async {
                    self.sensorsSelectionTableView.reloadData()
                }
                
            }
        }
        
    }
    
    // MARK: - Actions
    
    @IBAction func irrigateBed(_ sender: Any) {
        if let bedNo = self.bedNo {
            if let iSwitch = dataModel.dashboard_iFlagData["G\(bedNo)"] {
                dataModel.post_iFlag(bed: bedNo, iFlag: !iSwitch)
            }
        }
    }
    
    @IBAction func refreshChart(_ sender: Any) {
        if let bedNo = self.bedNo {
            dataModel.retrieveSensorData(forBed: bedNo)
        }
    }
    
    @IBAction func dataSettings(_ sender: Any) {
        performSegue(withIdentifier: "dataSettingsModalSegue", sender: self)
    }
    
    // MARK: - Collection View Methods
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BedScheduleCollectionViewCell", for: indexPath) as! BedScheduleIrrigationCollectionViewCell
        var dayString = ""
        
        switch indexPath.row {
        case 0:
            dayString = "MONDAY"
        case 1:
            dayString = "TUESDAY"
        case 2:
            dayString = "WEDNESDAY"
        case 3:
            dayString = "THURSDAY"
        case 4:
            dayString = "FRIDAY"
        case 5:
            dayString = "SATURDAY"
        case 6:
            dayString = "SUNDAY"
        default:
            dayString = ""
        }
        
        cell.dayLabel.text = String(dayString.prefix(3))
        cell.timeLabel.text = ""
        var cellOn = false
        
        if let bedNo = self.bedNo {
            if let dayDict = dataModel.bed_iScheduleData["G\(bedNo)"] {
                if let dayTuple = dayDict[dayString] {
                    cellOn = true
                    
                    cell.timeLabel.text = "\(dayTuple.0)\n\(dayTuple.1)"
                }
            }
        }
        
        cell.configure(on: cellOn)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        scheduleModal_dayInt = indexPath.row
        performSegue(withIdentifier: "editScheduleSegue", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var width = collectionView.frame.width
        width = (width - (6*8))/7
        return CGSize(width: width, height: collectionView.frame.height)
    }
    
    // MARK: - Table View Methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == self.sensorsSelectionTableView {
            return numberOfSensors
        } else if tableView == self.irrigationQueueTableView {
            if let bedNo = self.bedNo {
                if let iArray = dataModel.bed_iQueueDict["G\(bedNo)"] {
                    return iArray.count
                }
            }
            return 0
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == self.sensorsSelectionTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "sensorsSelectionTableViewCell") as! BedSensorsSelectionTableViewCell
            cell.selectionStyle = .none
            cell.titleLabel.text = "SENSOR \(indexPath.row+1)"
            cell.titleLabel.textColor = redColor
            return cell
        } else if tableView == self.irrigationQueueTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "irrigationQueueCell") as! DashIrrigationQueueTableViewCell
            
            let item = dataModel.bed_iQueueDict["G\(bedNo!)"]![indexPath.row]
            cell.bedLabel.text = "Bed \(bedNo!) | "
            cell.selectionStyle = .none
            if item.status == iQueueStatus.complete {
                cell.configureComplete()
                cell.deleteButton.tag = indexPath.row
                cell.deleteButton.addTarget(self, action: #selector(deleteiQueueItem(sender:)), for: .touchUpInside)
            } else {
                cell.configurePending()
            }
            
            if Calendar.current.isDate(item.end, inSameDayAs: item.start) {
                cell.detailLabel.text = "\(item.start.formatDate1()) - \(item.end.formatDate2())"
            } else {
                cell.detailLabel.text = "\(item.start.formatDate1()) - \(item.end.formatDate1())"
            }
            
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.sensorsSelectionTableView {
            return (tableView.frame.height+1)/7
        } else if tableView == self.irrigationQueueTableView {
            return (tableView.frame.height+1)/5
        } else {
            return 0
        }
    }
    
    @IBAction func deleteiQueueItem(sender: UIButton) {
        print("Bed \(sender.tag+1) delete button clicked")
        dataModel.delete_iQueueItem(bed: bedNo!, itemNo: sender.tag)
        self.irrigationQueueTableView.reloadData()
    }
    
    // MARK: - Schedule Single Irrigation Methods
    
    func configureScheduleSingleIrrigation() {
        confirmEndTimeView.isHidden = hideEndConfirm
        deleteView.isHidden = hideEndConfirm
        scheduleSingleIrrigationLabel.isHidden = hideEndConfirm
        confirmStartTimeView.isHidden = !hideEndConfirm
        
        confirmEndTimeView.alpha = hideEndConfirm ? 0 : 1
        deleteView.alpha =  hideEndConfirm ? 0 : 1
        scheduleSingleIrrigationLabel.alpha = hideEndConfirm ? 0 : 1
        confirmStartTimeView.alpha = !hideEndConfirm ? 0 : 1
    }
    
    @IBAction func didTapDelete(_ sender: Any) {
        print("Bed \(bedNo!) delete confirm clicked")
        scheduledIrrigationStartValue = nil
        
        endConfirmOrDeleteTappedConfigure()
    }
    
    @IBAction func didTapConfirmStartTime(_ sender: Any) {
        print("Bed \(bedNo!) start confirm clicked")
        startConfirmButtonTappedConfigure()
        
        var date = scheduleSingleIrrigationDatePicker.date
        let timeInterval = floor(date.timeIntervalSince1970 / 60.0) * 60
        date = Date(timeIntervalSince1970: timeInterval)
        scheduledIrrigationStartValue = date
    }
    
    @IBAction func didTapConfirmEndTime(_ sender: Any) {
        print("Bed \(bedNo!) end confirm clicked")
        endConfirmOrDeleteTappedConfigure()
        
        var date = scheduleSingleIrrigationDatePicker.date
        let timeInterval = floor(date.timeIntervalSince1970 / 60.0) * 60
        date = Date(timeIntervalSince1970: timeInterval)
        
        if date < Date() {
            // HANDLE ERROR
            print("ERROR1")
        } else if date <= scheduledIrrigationStartValue! {
            // HANDLE ERROR
            print("ERROR2")
        } else {
            print(scheduledIrrigationStartValue!)
            if let bedNo = self.bedNo {
                dataModel.post_iQueueItem(bed: bedNo, start: scheduledIrrigationStartValue!.timeIntervalSince1970*1000, end: timeInterval*1000, type: 1, status: 0)
            } else {
                print("ERROR3")
            }
        }
    }
    
    func startConfirmButtonTappedConfigure() {
        var date = self.scheduleSingleIrrigationDatePicker.date
        let timeInterval = floor(date.timeIntervalSince1970 / 60.0) * 60
        date = Date(timeIntervalSince1970: timeInterval)
        scheduleSingleIrrigationLabel.text = "Start: \(date.formatDate1())"
        
        UIView.animate(withDuration: 0.2, animations: {
            self.confirmStartTimeView.alpha = 0
        }) { (complete) in
            self.confirmStartTimeView.isHidden = true
            self.confirmEndTimeView.isHidden = false
            self.deleteView.isHidden = false
            self.scheduleSingleIrrigationLabel.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.confirmEndTimeView.alpha = 1
                self.deleteView.alpha = 1
                self.scheduleSingleIrrigationLabel.alpha = 1
            })
        }
    }
    
    func endConfirmOrDeleteTappedConfigure() {
        UIView.animate(withDuration: 0.2, animations: {
            self.confirmEndTimeView.alpha = 0
            self.deleteView.alpha = 0
            self.scheduleSingleIrrigationLabel.alpha = 0
        }) { (complete) in
            self.confirmEndTimeView.isHidden = true
            self.deleteView.isHidden = true
            self.scheduleSingleIrrigationLabel.isHidden = true
            self.confirmStartTimeView.isHidden = false
            UIView.animate(withDuration: 0.25, animations: {
                self.confirmStartTimeView.alpha = 1
            })
        }
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editScheduleSegue" {
            let destinationVC = segue.destination as! ScheduleIrrigationModalViewController
            destinationVC.dayInt = scheduleModal_dayInt
            destinationVC.bedNo = self.bedNo
        } else if segue.identifier == "dataSettingsModalSegue" {
            let destinationVC = segue.destination as! DataSettingsModalViewController
            destinationVC.bedNo = self.bedNo
        }
    }
}

extension BedViewController: IAxisValueFormatter {
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: Double(value/1000))
        return date.formatDate5()
    }
}
