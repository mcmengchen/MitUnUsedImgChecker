//
//  ViewController.swift
//  MitImgChecker
//
//  Created by MENGCHEN on 2019/8/21.
//  Copyright © 2019 Mitchell. All rights reserved.
//

import Cocoa
import ScriptingBridge


class ViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,NSWindowDelegate,NSTextFieldDelegate,NSControlTextEditingDelegate {

    @IBOutlet weak var chooseFileBtn: NSButton!
    @IBOutlet weak var projectLabel: NSTextField!
    @IBOutlet weak var imageTypeTable: NSTableView!
    @IBOutlet weak var addTypeBtn: NSButton!
    @IBOutlet weak var plusTypeBtn: NSButton!
    @IBOutlet weak var codePrefixTable: NSTableView!
    @IBOutlet weak var outputTable: NSTableView!
    @IBOutlet weak var blackListTable: NSTableView!
    @IBOutlet weak var addBlackBtn: NSButton!
    @IBOutlet weak var minusBlackBtn: NSButton!
    @IBOutlet weak var scanFilesTable: NSTableView!
    let kImgColumName = "kImgColumName"
    let kCodePrefixName = "kCodePrefixName"
    let kBlackListName = "kBlackListName"
    let kScanFileName = "kScanFileName"
    var imgPrefixDataSource = ["jpg","jpeg","png","pdf","gif","bmp","webp"]
    var scanFileDataSource = ["m","mm"]
    var selectedScanFileTypeIndex = -1
    var selectedImageIndex = -1
    var codePrefixDataSource = NSMutableArray.init(array: [])
    var selectedCodePrefixDataIndex = -1
    var outputDataSource = NSMutableArray.init(array: [])
    var selectedOutputDataIndex = -1
    var blackListDataSource = NSMutableArray.init(array: [])
    var selectedBlackListDataIndex = -1
    var filePath = ""
    private var myContext = 0
    
    var checker = MitChecker.init()
    override func viewDidLoad() {
        super.viewDidLoad()
        projectLabel.backgroundColor = .clear;
        projectLabel.alignment = .center;
        projectLabel.addObserver(self, forKeyPath: "stringValue", options: .new, context: &myContext)
        projectLabel?.delegate = self
        initialImageTypeTable()
        initialCodePrefixTable()
        initialOutputTable()
        initialBlackListTable()
        initialScanFileType()
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        
    }
    func textDidChange(_ notification: Notification){
        
    }
    
    func controlTextDidChange(_ obj: Notification) {
        if (obj.object  as! NSTextField? == projectLabel) {
            filePath = projectLabel.stringValue
        }
    }
    
    func initialImageTypeTable() {
        imageTypeTable?.delegate = self
        imageTypeTable?.dataSource = self
        imageTypeTable?.target = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: kImgColumName))
        column.width = imageTypeTable?.bounds.width ?? 0;
        column.minWidth = imageTypeTable?.bounds.width ?? 0
        column.maxWidth = imageTypeTable?.bounds.width ?? 0
        column.title = "Scan Type Name"
        imageTypeTable?.addTableColumn(column);
        imageTypeTable?.reloadData()
        imageTypeTable?.scroll(NSPoint(x: 0, y: 0))
    }
    
    func initialBlackListTable() {
        blackListTable?.delegate = self
        blackListTable?.dataSource = self
        blackListTable?.target = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: kBlackListName))
        column.width = blackListTable?.bounds.width ?? 0
        column.minWidth = blackListTable?.bounds.width ?? 0
        column.maxWidth = blackListTable?.bounds.width ?? 0
        column.title = "Black List Element Name"
        blackListTable?.addTableColumn(column);
        blackListTable?.reloadData()
        blackListTable?.scroll(NSPoint(x: 0, y: 0))
    }
    
    func initialCodePrefixTable() {
        codePrefixTable?.delegate = self
        codePrefixTable?.dataSource = self
        codePrefixTable?.target = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: kCodePrefixName))
        column.width = codePrefixTable?.bounds.width ?? 0
        column.minWidth = codePrefixTable?.bounds.width ?? 0
        column.maxWidth = codePrefixTable?.bounds.width ?? 0
        column.title = "Code Prefix String"
        codePrefixTable?.addTableColumn(column);
        codePrefixTable?.reloadData()
        codePrefixTable?.scroll(NSPoint(x: 0, y: 0))
    }
    
    func initialOutputTable() {
        outputTable?.delegate = self
        outputTable?.dataSource = self
        outputTable?.target = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: kCodePrefixName))
        column.width = outputTable?.bounds.width ?? 0
        column.minWidth = outputTable?.bounds.width ?? 0
        column.maxWidth = outputTable?.bounds.width ?? 0
        column.title = " Output. Double click to check the files"
        outputTable?.addTableColumn(column);
        outputTable?.reloadData()
        outputTable?.scroll(NSPoint(x: 0, y: 0))
        outputTable.doubleAction = #selector(outputTableDoubleClick(_:))
    }
    
    @objc func outputTableDoubleClick(_ sender:AnyObject) {
        guard outputTable.selectedRow >= 0,
            let item:NSDictionary = outputDataSource[outputTable.selectedRow] as? NSDictionary else {
            return
        }
        let path:String = item.object(forKey: "path") as! String
        guard shell(command: """
            open -R "\(path)"
            """) else {
                print("打开\(path)失败")
                return
        }
    }
    @objc public var evalError = {
        (_ message: String) -> Error in
        print("💉 *** \(message) ***")
        return NSError(domain: "SwiftEval", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
    }
    @objc public var tmpDir = "/tmp" {
        didSet {
        }
    }
    private func debug(_ str: String) {
        print(str)
    }
    func shell(command: String) -> Bool {
        try? command.write(toFile: "\(tmpDir)/command.sh", atomically: false, encoding: .utf8)
        debug(command)
        
        #if !(os(iOS) || os(tvOS))
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]
        task.launch()
        task.waitUntilExit()
        return task.terminationStatus == EXIT_SUCCESS
        #else
        let pid = fork()
        if pid == 0 {
            var args = [UnsafeMutablePointer<Int8>?](repeating: nil, count: 4)
            args[0] = strdup("/bin/bash")!
            args[1] = strdup("-c")!
            args[2] = strdup(command)!
            args.withUnsafeMutableBufferPointer {
                _ = execve($0.baseAddress![0], $0.baseAddress!, nil) // _NSGetEnviron().pointee)
                fatalError("execve() fails \(String(cString: strerror(errno)))")
            }
        }
        
        var status: Int32 = 0
        while waitpid(pid, &status, 0) == -1 {}
        return status >> 8 == EXIT_SUCCESS
        #endif
    }

    
    
    func initialScanFileType () {
        scanFilesTable?.delegate = self
        scanFilesTable?.dataSource = self
        scanFilesTable?.target = self
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: kScanFileName))
        column.width = scanFilesTable?.bounds.width ?? 0
        column.minWidth = scanFilesTable?.bounds.width ?? 0
        column.maxWidth = scanFilesTable?.bounds.width ?? 0
        column.title = "Scan File Type"
        scanFilesTable?.addTableColumn(column);
        scanFilesTable?.reloadData()
        scanFilesTable?.scroll(NSPoint(x: 0, y: 0))
    }
    
    override func viewDidLayout() {
        super.viewDidLayout()
    }
    
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &myContext {
            if let newValue = change?[NSKeyValueChangeKey.newKey] {
                print("\(filePath)")
                filePath = newValue as! String
            }
        }
    }
    
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    //Delegate
    func numberOfRows(in tableView: NSTableView) -> Int {
        if tableView==imageTypeTable {
            return imgPrefixDataSource.count
        } else if (tableView == codePrefixTable){
            return codePrefixDataSource.count
        } else if (tableView == blackListTable){
            return blackListDataSource.count
        } else if (tableView == outputTable){
            return outputDataSource.count
        } else {
            return scanFileDataSource.count
        }
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 20
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        var rowStr = ""
        if tableView == imageTypeTable {
            rowStr = imgPrefixDataSource[row]
        } else if (tableView == codePrefixTable){
            rowStr = codePrefixDataSource[row] as! String
        } else  if (tableView == blackListTable){
            rowStr = blackListDataSource[row] as! String
        } else if (tableView == scanFilesTable){
            rowStr = scanFileDataSource[row]
        } else if (tableView == outputTable) {
            let dict:NSDictionary = outputDataSource[row] as! NSDictionary
            rowStr = dict["path"] as! String
        }
        return rowStr
    }
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        print("oldDescriptors[0] -> (sortDescriptorPrototyp, descending, compare:)")
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if (notification.object as! NSTableView? == imageTypeTable ) {
            //格式
            selectedImageIndex = imageTypeTable.selectedRow
        } else if (notification.object as! NSTableView? == codePrefixTable) {
            //代码前缀
            selectedCodePrefixDataIndex = codePrefixTable.selectedRow
        } else if (notification.object as! NSTableView? == outputTable) {
            //输出
            selectedOutputDataIndex = outputTable.selectedRow
        } else if (notification.object as! NSTableView? == blackListTable) {
            //黑名单
            selectedBlackListDataIndex = blackListTable.selectedRow
        } else if (notification.object as! NSTableView? == scanFilesTable) {
            //选择文件序号
            selectedScanFileTypeIndex = scanFilesTable.selectedRow
        }
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        
    }
    //增加扫描类型
    @IBAction func plusScanTypeClick(_ sender: Any) {
        let myNib = NSNib(nibNamed: "MitTextView", bundle: nil)
        var objectArray:NSArray?
        myNib?.instantiate(withOwner: self, topLevelObjects: &objectArray)
        for item in objectArray! {
            if item is MitTextView {
                let window = item as! MitTextView
                window.delegate = self
                window.makeKeyAndOrderFront(self)
                window.title = "Add Scan Type"
                window.sureClickCallback { (str) in
                    if (str.count>0)&&(!self.imgPrefixDataSource.contains(str)){
                        self.imgPrefixDataSource.append(str)
                        self.imageTypeTable.reloadData()
                    }
                }
            }
        }
    }
    //删除扫描类型
    @IBAction func minusScanTypeClick(_ sender: Any) {
        if selectedImageIndex<0||imgPrefixDataSource.count<=0 {
            return
        }
        deleteScanWithIndex()
//        let typeString = imgPrefixDataSource[imageTypeTable.selectedRow]
//        let myNib = NSNib(nibNamed: "MitSureWindow", bundle: nil)
//        var objectArray:NSArray?
//        myNib?.instantiate(withOwner: self, topLevelObjects: &objectArray)
//        for item in objectArray! {
//            if item is MitSureWindow {
//                let window = item as! MitSureWindow
//                window.delegate = self
//                window.text = "确认删除 \(typeString) 类型?"
//                window.makeKeyAndOrderFront(self)
//                window.sureClickCallback {
//                    self.deleteScanWithIndex()
//                }
//            }
//        }
    }
    func deleteScanWithIndex(){
        self.imgPrefixDataSource.remove(at: self.imageTypeTable.selectedRow)
        if (!(imgPrefixDataSource.count >= 0 && self.selectedImageIndex < imgPrefixDataSource.count)) {
            self.selectedImageIndex = -1
        }
        self.imageTypeTable.reloadData()
    }
    ///选择工程路径
    @IBAction func filePathTexFieldAction(_ sender: Any) {
        
        

    }
    ///点击选择工程路径
    @IBAction func chooseFile(_ sender: Any) {
        
    }
    ///添加图片名前缀
    @IBAction func addPrefix(_ sender: Any) {
        let myNib = NSNib(nibNamed: "MitTextView", bundle: nil)
        var objectArray:NSArray?
        myNib?.instantiate(withOwner: self, topLevelObjects: &objectArray)
        for item in objectArray! {
            if item is MitTextView {
                let window = item as! MitTextView
                window.delegate = self
                window.makeKeyAndOrderFront(self)
                window.title = "Add Code Prefix String"
                window.sureClickCallback { (str) in
                    if (str.count>0)&&(!self.codePrefixDataSource.contains(str)){
                        self.codePrefixDataSource.add(str)
                        self.codePrefixTable.reloadData()
                    }
                }
            }
        }
    }
    ///删除图片名前缀
    @IBAction func deletePrefix(_ sender: Any) {
        if selectedCodePrefixDataIndex<0||codePrefixDataSource.count<=0 {
            return
        }
        deletePrefixWithIndex()
    }
    ///删除前缀
    func deletePrefixWithIndex() {
        self.codePrefixDataSource.removeObject(at: self.codePrefixTable.selectedRow)
        if (!(codePrefixDataSource.count >= 0 && self.selectedCodePrefixDataIndex < codePrefixDataSource.count)) {
            self.selectedCodePrefixDataIndex = -1
        }
        self.codePrefixTable.reloadData()
    }
    
    @IBAction func addBlackList(_ sender: Any) {
        let myNib = NSNib(nibNamed: "MitTextView", bundle: nil)
        var objectArray:NSArray?
        myNib?.instantiate(withOwner: self, topLevelObjects: &objectArray)
        for item in objectArray! {
            if item is MitTextView {
                let window = item as! MitTextView
                window.delegate = self
                window.makeKeyAndOrderFront(self)
                window.title = "Add Black List String"
                window.sureClickCallback { (str) in
                    if (str.count>0)&&(!self.blackListDataSource.contains(str)){
                        self.blackListDataSource.add(str)
                        self.blackListTable.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func deleteBlackList(_ sender: Any) {
        if selectedBlackListDataIndex<0||blackListDataSource.count<=0 {
            return
        }
        deleteBlackListWithIndex()
    }
    ///删除前缀
    func deleteBlackListWithIndex() {
        self.blackListDataSource.removeObject(at: self.blackListTable.selectedRow)
        if (!(blackListDataSource.count >= 0 && self.selectedCodePrefixDataIndex < blackListDataSource.count)) {
            self.selectedCodePrefixDataIndex = -1
        }
        self.blackListTable.reloadData()
    }
    
    @IBAction func addScanFileType(_ sender: Any) {
        let myNib = NSNib(nibNamed: "MitTextView", bundle: nil)
        var objectArray:NSArray?
        myNib?.instantiate(withOwner: self, topLevelObjects: &objectArray)
        for item in objectArray! {
            if item is MitTextView {
                let window = item as! MitTextView
                window.delegate = self
                window.makeKeyAndOrderFront(self)
                window.title = "Add Scan File Type"
                window.sureClickCallback { (str) in
                    if (str.count>0)&&(!self.scanFileDataSource.contains(str)){
                        self.scanFileDataSource.append(str)
                        self.scanFilesTable.reloadData()
                    }
                }
            }
        }
    }
    
    @IBAction func deleteScanFileType(_ sender: Any) {
        if selectedScanFileTypeIndex<0||scanFileDataSource.count<=0 {
            return
        }
        deleteScanFileWithIndex()
    }
    ///删除前缀
    func deleteScanFileWithIndex() {
        self.scanFileDataSource.remove(at: self.scanFilesTable.selectedRow)
        if (!(scanFileDataSource.count >= 0 && self.selectedScanFileTypeIndex < scanFileDataSource.count)) {
            self.selectedScanFileTypeIndex = -1
        }
        self.scanFilesTable.reloadData()
    }
    
    
    
    ///开始检查
    @IBAction func startCheck(_ sender: Any) {
        if filePath.count>0 {
            checker.getAllImages(atPath: filePath, imgType: imgPrefixDataSource,blackList: blackListDataSource as! [String])
            print("\(checker.kImgDataArr)")
            checker.getFiles(atPath: filePath, fileType: scanFileDataSource)
            print("\(checker.kFileDataMap)")
            outputDataSource = checker.startCheck() as! NSMutableArray
            outputTable.reloadData()
        }
    }
    ///停止检查
    @IBAction func stopCheck(_ sender: Any) {
        
    }
    
    
    
    
}
