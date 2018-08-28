//
//  ViewController.swift
//  SMCheckProject
//
//  Created by daiming on 2016/10/13.
//  Copyright © 2016年 Starming. All rights reserved.
//

import Cocoa
import RxSwift
import SnapKit

class ViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate, DragViewDelegate {
    @IBOutlet var parsingIndicator: NSProgressIndicator!
    @IBOutlet var desLb: NSTextField!
    @IBOutlet var pathDes: NSTextField!
    @IBOutlet var cleanBt: NSButton!
    @IBOutlet var resultTb: NSTableView!
    @IBOutlet var dragView: DragView!
    @IBOutlet var seachBt: NSButtonCell!
    @IBOutlet var detailTv: NSScrollView!
    @IBOutlet var detailTxv: NSTextView!
    @IBOutlet var projectTitle: NSTextField!
    @IBOutlet var unUseMethodTitle: NSTextField!
    @IBOutlet var scrollView: NSScrollView!
    @IBOutlet weak var searchButton: NSButton!
    @IBOutlet weak var searchIndicator: NSProgressIndicator!
    
    @IBOutlet weak var addPathBuuton: NSButton!
    @IBOutlet weak var dragTextField: NSTextField!
    var unusedMethods = [Method]() // 无用方法
    var selectedPath: String = "" {
        didSet {
            if selectedPath.count > 0 {
                let ud = UserDefaults()
                ud.set(selectedPath, forKey: "selectedPath")
                ud.synchronize()
                pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
            }
        }
    }

    var filesDic = [String: File]() // 遍历后文件集
    var parsingLog = "" // 遍历后的日志

    func setupUIAutoLayout() {

        projectTitle.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(5)
            make.left.equalToSuperview().offset(20)
            make.width.equalTo(70)
            make.height.equalTo(20)
        }

        pathDes.snp.makeConstraints { make in
            make.left.equalTo(addPathBuuton.snp.right).offset(15)
            make.top.equalTo(projectTitle.snp.top)
            make.height.equalTo(projectTitle.snp.height)
            make.right.equalTo(self.view.snp.right).offset(-20)
        }

        addPathBuuton.snp.makeConstraints { (make) in
            make.left.equalTo(self.projectTitle.snp.right)
            make.centerY.equalTo(self.projectTitle)
            make.height.equalTo(20)
            make.width.equalTo(20)
        }

        unUseMethodTitle.snp.makeConstraints { (make) in
            make.top.equalTo(self.projectTitle.snp.bottom).offset(10)
            make.left.equalTo(self.projectTitle)
            make.height.equalTo(self.projectTitle)
            make.width.equalTo(200)
        }

        searchButton.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(0)
            make.right.equalToSuperview().offset(0)
            make.width.equalTo(100)
            make.height.equalTo(40)
        }

        searchIndicator.snp.makeConstraints { (make) in
            make.height.equalTo(searchButton)
            make.width.equalTo(searchButton.snp.height)
            make.centerY.equalTo(searchButton)
            make.right.equalTo(searchButton.snp.left).offset(-5)
        }
        

        dragView.snp.makeConstraints { make in
            make.edges.equalTo(self.view).inset(NSEdgeInsetsMake(40, 20, 20, 20))
        }

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(self.dragView).offset(40)
            make.left.equalTo(self.dragView).offset(20)
            make.bottom.equalTo(self.dragView.snp.bottom).offset(-60)
            make.right.equalTo(self.dragView.snp.centerX).offset(-15)
        }

        detailTv.snp.makeConstraints { make in
            make.top.equalTo(self.dragView).offset(40)
            make.right.equalTo(self.dragView).offset(20)
            make.bottom.equalTo(self.dragView.snp.bottom).offset(-60)
            make.left.equalTo(self.dragView.snp.centerX).offset(15)
        }

        dragTextField.snp.makeConstraints { (make) in
            make.centerX.equalTo(dragView)
            make.top.equalTo(dragView.snp.top).offset(10)
            make.width.equalTo(200)
            make.height.equalTo(40)
        }
        dragTextField.alignment = NSTextAlignment.center


        desLb.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.dragView.snp.bottom).offset(-10)
            make.left.equalTo(self.dragView.snp.left).offset(15)
            make.width.equalTo(self.dragView.snp.width).offset(-100)
            make.height.equalTo(30)
        }

        cleanBt.snp.makeConstraints { (make) in
            make.bottom.equalTo(self.dragView.snp.bottom).offset(-10)
            make.right.equalTo(self.dragView.snp.right).offset(-15)
            make.width.equalTo(100)
            make.height.equalTo(30)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        detailTxv.string = ""
        detailTxv.textColor = NSColor.gray
        parsingIndicator.isHidden = true
        desLb.stringValue = ""
        pathDes.stringValue = "请选择工程目录--------------------------"
        cleanBt.isEnabled = false
        resultTb.doubleAction = #selector(cellDoubleClick)
        if UserDefaults().object(forKey: "selectedPath") != nil {
            selectedPath = UserDefaults().value(forKey: "selectedPath") as! String
        }

        self.setupUIAutoLayout()
    }

    override func awakeFromNib() {
        dragView.delegate = self
    }

    // 查找按钮
    @IBAction func searchMethodAction(_ sender: Any) {
        if selectedPath.count > 0 {
            searchingUnusedMethods()
        }
    }

    // 清理按钮
    @IBAction func cleanMethodsAction(_ sender: AnyObject) {
        desLb.stringValue = "清理中..."
        cleanBt.isEnabled = false
        parsingIndicator.startAnimation(nil)
        DispatchQueue.global().async {
            CleanUnusedMethods().clean(methods: self.unusedMethods)
            DispatchQueue.main.async {
                self.cleanBt.isEnabled = true
                self.parsingIndicator.stopAnimation(nil)
                self.parsingIndicator.isHidden = true
                self.desLb.stringValue = "完成清理"
                self.detailTxv.string = ""
            }
        }
    }

    // Priavte
    private func searchingUnusedMethods() {
        parsingIndicator.isHidden = false
        parsingIndicator.startAnimation(nil)
        desLb.stringValue = "查找中..."
        cleanBt.isEnabled = false
        seachBt.isEnabled = false
        pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
        detailTxv.string = ""
        parsingLog = ""
        DispatchQueue.global().async {
//            self.unusedMethods = CleanUnusedMethods().find(path: self.selectedPath)
            _ = CleanUnusedMethods().find(path: self.selectedPath).subscribe(onNext: { result in
                if result is String {
                    DispatchQueue.main.async {
                        self.desLb.stringValue = result as! String
                    }

                } else if result is [Method] {
                    self.unusedMethods = result as! [Method]
                } else if result is File {
                    DispatchQueue.main.async {
                        let aFile = result as! File
                        self.filesDic[aFile.path] = aFile
                        self.parsingLog = self.parsingLog + aFile.des() + "\n"
                    }
                }
            })
            DispatchQueue.main.async {
                self.cleanBt.isEnabled = true
                self.seachBt.isEnabled = true
                self.parsingIndicator.stopAnimation(nil)
                self.parsingIndicator.isHidden = true
                self.desLb.stringValue = "完成查找"
                self.resultTb.reloadData()

                self.detailTxv.string = self.parsingLog
                self.detailTv.contentView.scroll(to: NSPoint(x: 0, y: ((self.detailTv.documentView?.frame.size.height)! - self.detailTv.contentSize.height)))

                // 处理无用import
                DispatchQueue.global().async {
                    _ = CleanUnusedImports().find(files: self.filesDic).subscribe(onNext: { result in
                        if result is [String: File] {
                            // 接受更新后的全部文件
                            self.filesDic = result as! [String: File]
                        } else if result is [String: Object] {
                            // 接受全部无用import字典
                        }
                    })
                }
            }
        }
    }

    // 选择一个文件夹
    @IBAction func openFinderSelectPath(_ sender: Any) {
        self.selectFolder()
    }

    private func selectFolder() -> String {
        let openPanel = NSOpenPanel()
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        if openPanel.runModal() == NSModalResponseOK {
            // print(openPanel.url?.absoluteString)
            let path = openPanel.url?.absoluteString
            // print("选择文件夹路径: \(path)")
            selectedPath = "file://" + path! + "/"
            pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
            return path!
        }

        return ""
    }

    // TableView
    // Cell DoubleClick
    func cellDoubleClick() {
        let aMethod = unusedMethods[self.resultTb.clickedRow]
        let filePathString = aMethod.filePath.replacingOccurrences(of: "file://", with: "")
        // 双击打开finder到指定的文件
        NSWorkspace.shared().openFile(filePathString, withApplication: "Xcode")
    }

    // Cell OneClick
    func cellOneClick() {
        let aMethod = unusedMethods[self.resultTb.selectedRow]
        let cFile = filesDic[aMethod.filePath]
        detailTxv.string = cFile?.content
    }

    // NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return unusedMethods.count
    }

    // NSTableViewDelegate
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        let aMethod = unusedMethods[row]

        let columnId = tableColumn?.identifier
        if columnId == "MethodId" {
            return aMethod.pnameId
        } else if columnId == "MethodPath" {
            let filePathString = aMethod.filePath.replacingOccurrences(of: "file://", with: "")
            return filePathString
        }

        return nil
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        cellOneClick()
    }

    // DragViewDelegate
    func dragExit() {
        //
    }

    func dragEnter() {
        //
    }

    func dragFileOk(filePath: String) {
        print("\(filePath)")
        selectedPath = "file://" + filePath + "/"
        pathDes.stringValue = selectedPath.replacingOccurrences(of: "file://", with: "")
    }
}
