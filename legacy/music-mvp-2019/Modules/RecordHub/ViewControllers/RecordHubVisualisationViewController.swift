//
//  RecordHubVisualisationViewController.swift
//  
//
//  Created by Andrey Dubenkov on 12/05/2018.
//  Copyright © 2018 . All rights reserved.
//

import AudioKit
import AudioKitUI
import DeviceKit
import Foundation
import QuartzCore
import UIKit

class WindowLayer: CAShapeLayer {
    @NSManaged var hideWidth: CGFloat
    @NSManaged var showWidth: CGFloat

    override class func needsDisplay(forKey key: String) -> Bool {
        if key == "hideWidth" || key == "showWidth" {
            return true
        }
        return super.needsDisplay(forKey: key)
    }

    override func draw(in ctx: CGContext) {
        let mutablePath = CGMutablePath()
        let path = CGRect(width: hideWidth, height: frame.height)
        let hole = CGRect(width: showWidth, height: frame.height)
        mutablePath.addRect(hole)
        mutablePath.addRect(path)
        self.path = mutablePath
        fillRule = CAShapeLayerFillRule.evenOdd
//        self.backgroundColor = UIColor.red.withAlphaComponent(0.5).cgColor
        self.backgroundColor = UIColor.clear.cgColor
//        self.fillColor = UIColor.blue.withAlphaComponent(0.5).cgColor
        self.fillColor = UIColor.recordPlotBackgroundGray.cgColor
    }
}

class LayerContainerView: UIView {

    var windowLayer: WindowLayer!
    var showWidth: CGFloat = 0.0 {
        didSet {
            windowLayer.showWidth = showWidth
        }
    }
    var hideWidth: CGFloat = 0.0 {
        didSet {
            windowLayer.hideWidth = hideWidth
        }
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    open func commonInit() {
        self.backgroundColor = .clear
        windowLayer = WindowLayer()
        windowLayer.showWidth = showWidth
        windowLayer.hideWidth = hideWidth
        self.layer.addSublayer(windowLayer)
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        windowLayer.frame = self.bounds
        windowLayer.setNeedsDisplay()
    }

    func bringSublayerToFront() {
        windowLayer.bringToFront()
    }
}

extension CALayer {

   func bringToFront() {
      guard let sLayer = superlayer else {
         return
      }
      removeFromSuperlayer()
      sLayer.insertSublayer(self, at: UInt32(sLayer.sublayers?.count ?? 0))
   }

   func sendToBack() {
      guard let sLayer = superlayer else {
         return
      }
      removeFromSuperlayer()
      sLayer.insertSublayer(self, at: 0)
   }
}

protocol RecordHubVisualisationViewInput: class {
    func blockScrolling(foo: Bool)
    func addMusicPlot(duration: Double, data: EZAudioFloatData)
    func addRecordPlot(plot: AKNodeOutputPlot)
    func addVocalPlot(duration: Double,
                      clipDuration: Double,
                      time: Double,
                      offset: Double,
                      data: EZAudioFloatData,
                      identifire: ObjectIdentifier)
    func playhead(contentOffset: Double)
    func clearMusicPlot()
    func clearVocalPlot(completion: @escaping () -> Void)
    func removeLastClipPlot(identifire: ObjectIdentifier)

    func recordStarted(position: Double)
    func recordEnded()
}

protocol RecordHubVisualisationViewOutput {
    var input: RecordHubVisualisationViewInput? { get set }
    func scrollViewDidScrollToOffset(position: Double)
    func scrollViewWillBeginDragging()
    func scrollViewWillEndDragging()
    func scrollViewDidEndDraggingAt(position: Double)
    func scrollViewDidEndDecelerating(position: Double)
    func frameForRecordingPlotSeted(frame: CGRect)
}

class RecordHubVisualisationViewController: BaseViewController {
    @IBOutlet private var vocalScrollView: UIScrollView!
    @IBOutlet private var vocalPlotView: UIView!

    @IBOutlet private var reveal: UIView!
    @IBOutlet private var revealWidthConstraint: NSLayoutConstraint!

    @IBOutlet private var playhead: UIView!

    @IBOutlet private var musicScrollView: UIScrollView!
    @IBOutlet private var musicPlotView: UIView!
    @IBOutlet private var musicPlotWidthConstraint: NSLayoutConstraint!

    @IBOutlet private var recordView: LayerContainerView!

    @IBOutlet private var recordXPosition: NSLayoutConstraint!

    // MARK: - Properties

    var output: RecordHubVisualisationViewOutput?

    var plotScale = 16.0
    let plotGain = Float(1.7)

    var musicPlot: EZAudioPlot?
    var vocalPlots = [EZAudioPlot]()

    var recording: Bool = false
    var maskPlot: UIView?

    var center: Double {
        return Double(view.frame.width / 2.0)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - GUI funcs

    func configView() {
        if #available(iOS 11.0, *) {
            musicScrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
            vocalScrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
//        recordView.backgroundColor = .white
        musicScrollView.bounces = false
        musicScrollView.delegate = self
        vocalScrollView.bounces = false
        vocalScrollView.isUserInteractionEnabled = false
        musicScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.0)
        vocalScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.0)
    }

    private func playheadFromUiPosition() -> Double {
        let visibleRect = CGRect(origin: musicScrollView.contentOffset, size: musicScrollView.frame.size)
        let startPoint = Double(visibleRect.origin.x) / plotScale
        return startPoint
    }
}

// MARK: - Scroll View Delegate

extension RecordHubVisualisationViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        vocalScrollView.contentOffset.x = musicScrollView.contentOffset.x
        output?.scrollViewDidScrollToOffset(position: playheadFromUiPosition())
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        output?.scrollViewWillBeginDragging()
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView,
                                   withVelocity velocity: CGPoint,
                                   targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        output?.scrollViewWillEndDragging()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        output?.scrollViewDidEndDraggingAt(position: playheadFromUiPosition())
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        output?.scrollViewDidEndDecelerating(position: playheadFromUiPosition())
    }
}

// MARK: - RecordHubVisualisationViewInput

extension RecordHubVisualisationViewController: RecordHubVisualisationViewInput {
    func blockScrolling(foo: Bool) {
        musicScrollView.isUserInteractionEnabled = !foo
    }

    func addMusicPlot(duration: Double, data: EZAudioFloatData) {
        clearMusicPlot()
        let width = duration * plotScale
        let height = musicPlotView.bounds.height
        musicPlotWidthConstraint.constant = CGFloat(width + center * 2)
        let rect = CGRect(x: center, y: 0, width: width, height: Double(height))
        let plot = EZAudioPlot(frame: rect)
        DispatchQueue.global().async {
            plot.updateBuffer(data.buffers[0], withBufferSize: data.bufferSize)
            plot.gain = self.plotGain
            plot.plotType = .rolling
            plot.shouldFill = true
            plot.shouldCenterYAxis = true
            plot.shouldMirror = true
            plot.color = UIColor(hexString: "#1e6c7f")
            plot.backgroundColor = .clear

            self.musicPlot = plot
            DispatchQueue.main.async {
                self.musicPlotView.addSubview(plot)
            }
        }
    }

    func addRecordPlot(plot: AKNodeOutputPlot) {
        DispatchQueue.main.async {
            self.recordView.addSubview(plot)
//            self.recordView.bringSublayerToFront()
            plot.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                NSLayoutConstraint(item: plot,
                                   attribute: .width,
                                   relatedBy: .equal,
                                   toItem: nil,
                                   attribute: .width,
                                   multiplier: 1.0,
                                   constant: self.recordView.frame.width),
                NSLayoutConstraint(item: plot,
                                   attribute: .height,
                                   relatedBy: .equal,
                                   toItem: nil,
                                   attribute: .height,
                                   multiplier: 1.0,
                                   constant: self.recordView.frame.height),
                NSLayoutConstraint(item: plot,
                                   attribute: .centerX,
                                   relatedBy: .equal,
                                   toItem: self.recordView,
                                   attribute: .centerX,
                                   multiplier: 1.0,
                                   constant: 0),
                NSLayoutConstraint(item: plot,
                                   attribute: .centerY,
                                   relatedBy: .equal,
                                   toItem: self.recordView,
                                   attribute: .centerY,
                                   multiplier: 1.0,
                                   constant: 0)
            ])
        }
    }

    func playhead(contentOffset: Double) {
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
            let offset = CGFloat(contentOffset * self.plotScale)
            self.musicScrollView.contentOffset.x = offset

            if self.recording {
                self.recordView.showWidth = abs(self.recordXPosition.constant)
                self.recordView.hideWidth = 0.0
                if self.recordXPosition.constant >= CGFloat(self.center) * -1 {
                    let delta = CGFloat(self.plotScale * 0.1)
                    self.recordXPosition.constant -= delta
//                    print("Position: \(self.recordXPosition.constant) , \(delta), Bounds: \(self.recordView.bounds.size), \(self.recordView.bounds.origin)")
                }
            }
        }, completion: { (_: Bool) in
        })
    }

    func clearMusicPlot() {
        if let view = musicPlot {
            view.removeFromSuperview()
            musicPlot = nil
            self.view.layoutIfNeeded()
        }
    }

    func removeLastClipPlot(identifire: ObjectIdentifier) {
        let plot = vocalPlotView.subviews.filter { $0.tag != identifire.hashValue }.first
        plot?.removeFromSuperview()
        vocalPlots = vocalPlots.filter { $0.tag != identifire.hashValue }
        vocalPlotView.layoutIfNeeded()
    }

    func recordStarted(position: Double) {
        self.recording = true
        recordView.layoutIfNeeded()
        self.recordView.hideWidth = 0.01
        self.recordView.showWidth = 0.0
        output?.frameForRecordingPlotSeted(frame: recordView.frame)
    }

    func recordEnded() {
        DispatchQueue.main.async {
            self.recordView.hideWidth = self.recordView.frame.width
            self.recordView.showWidth = self.recordView.frame.width
            self.recording = false
            self.recordXPosition.constant = 0.0
            self.recordView.subviews.forEach {
                $0.removeFromSuperview()
            }
            self.recordView.layoutIfNeeded()
        }
    }

    func addVocalPlot(duration: Double,
                      clipDuration: Double,
                      time: Double,
                      offset: Double,
                      data: EZAudioFloatData,
                      identifire: ObjectIdentifier) {

        let height = Double(vocalPlotView.bounds.height)
        // Full file rect
        let fullWidth = duration * plotScale
        let fullPos = time - offset
        let fullXPos = center + (fullPos * plotScale)
        let fullRect = CGRect(x: fullXPos, y: 0, width: fullWidth, height: height)
        // Clip rect
        let clipWidth = clipDuration * plotScale
        let clipPos = time
        let clipXpos = clipPos * plotScale
        let clipRect = CGRect(x: clipXpos, y: 0.0, width: clipWidth, height: height)

        let plot = EZAudioPlot(frame: fullRect)
        DispatchQueue.global().async {
            plot.updateBuffer(data.buffers[0], withBufferSize: data.bufferSize)
            plot.gain = self.plotGain
            plot.plotType = .rolling
            plot.shouldFill = true
            plot.shouldCenterYAxis = true
            plot.shouldMirror = true
            plot.color = .red
            if offset != 0 {
                plot.mask(withRect: clipRect, inverse: false)
            }

            DispatchQueue.main.async {
                plot.clipsToBounds = true
                plot.backgroundColor = .clear
                plot.tag = identifire.hashValue
                self.vocalPlotView.addSubview(plot)
                self.vocalPlots.append(plot)
            }
        }
    }

    func clearVocalPlot(completion: @escaping () -> Void) {
        DispatchQueue.main.async {
            self.vocalPlots = []
            for view in self.vocalPlotView.subviews where view != self.recordView {
                view.removeFromSuperview()
            }
            self.view.layoutIfNeeded()
            completion()
        }
    }
}
