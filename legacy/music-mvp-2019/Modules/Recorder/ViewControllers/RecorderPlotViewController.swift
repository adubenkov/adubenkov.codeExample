//
//  RecorderPlotViewController.swift
//
//
//  Created by Andrey Dubenkov on 02.04.2020.
//

import AudioKit
import AudioKitUI
import UIKit

protocol RecorderPlotViewInput: class {
    var isRecording: Bool { get set }
    func movePlayhead(_ position: Double)
    func removeLastClipPlot(identifire: ObjectIdentifier)
    func recordStarted(position: Double)
    func recordEnded()
    func addVocalPlot(duration: Double,
                      clipDuration: Double,
                      time: Double,
                      offset: Double,
                      data: EZAudioFloatData,
                      identifire: ObjectIdentifier)
    func clearVocalPlot(completion: @escaping () -> Void)
    func addRecordPlot(plot: AKNodeOutputPlot)
}

protocol RecorderPlotViewOutput: class {
    var input: RecorderPlotViewInput? { get set }
    func frameForRecordingPlotSeted(frame: CGRect)
    func scrollViewWillBeginDragging()
    func scrollViewWillEndDragging()
    func scrollViewDidScrollToOffset(position: Double)
    func scrollViewDidEndDraggingAt(position: Double)
    func scrollViewDidEndDecelerating(position: Double)
}

class RecorderPlotViewController: UIViewController {
    @IBOutlet var recorderScrollView: UIScrollView!
    @IBOutlet var vocalPlotView: UIView!
    @IBOutlet var recordView: LayerContainerView!
    @IBOutlet var playhead: UIView!
    @IBOutlet var recordXPosition: NSLayoutConstraint!
    @IBOutlet var vocalPlotWidthConstraint: NSLayoutConstraint!

    var output: RecorderPlotViewOutput?

    var vocalPlots = [EZAudioPlot]()

    var isRecording: Bool = false

    var plotScale = 16.0
    let plotGain = Float(1.7)

    var center: Double {
        return Double(view.frame.width / 2.0)
    }

    // MARK: - Lifecycle

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configView()
    }

    // MARK: - Private

    private func configView() {
        if #available(iOS 11.0, *) {
            recorderScrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        }
        recorderScrollView.delegate = self
        recorderScrollView.bounces = false
        recorderScrollView.contentSize.width = 800
        recorderScrollView.decelerationRate = UIScrollView.DecelerationRate(rawValue: 0.0)
    }

    private func playheadFromUiPosition() -> Double {
        let visibleRect = CGRect(origin: recorderScrollView.contentOffset, size: recorderScrollView.frame.size)
        let startPoint = Double(visibleRect.origin.x) / plotScale
        return startPoint
    }
}

// MARK: - UIScrollViewDelegate

extension RecorderPlotViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

// MARK: - RecorderPlotViewInput

extension RecorderPlotViewController: RecorderPlotViewInput {
    func addRecordPlot(plot: AKNodeOutputPlot) {
        DispatchQueue.main.async {
            self.recordView.addSubview(plot)
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

    func removeLastClipPlot(identifire: ObjectIdentifier) {
        let plot = vocalPlotView.subviews.filter { $0.tag != identifire.hashValue }.first
        plot?.removeFromSuperview()
        vocalPlots = vocalPlots.filter { $0.tag != identifire.hashValue }
        vocalPlotView.layoutIfNeeded()
    }

    func recordStarted(position: Double) {
        recordView.layoutIfNeeded()
        recordView.hideWidth = 0.01
        recordView.showWidth = 0.0
        output?.frameForRecordingPlotSeted(frame: recordView.frame)
    }

    func recordEnded() {
        DispatchQueue.main.async {
            self.recordView.hideWidth = self.recordView.frame.width
            self.recordView.showWidth = self.recordView.frame.width
            self.recordXPosition.constant = 0.0
            self.recordView.subviews.forEach {
                $0.removeFromSuperview()
            }
            self.recordView.layoutIfNeeded()
        }
    }

    func addVocalPlot(duration: Double, clipDuration: Double, time: Double, offset: Double, data: EZAudioFloatData, identifire: ObjectIdentifier) {
        var width = 0.0
        for plot in vocalPlots {
            width += Double(plot.frame.size.width)
        }
        let clipWidth = clipDuration * plotScale
        width += clipWidth
        vocalPlotWidthConstraint.constant = CGFloat(width + center * 2)
        let height = Double(vocalPlotView.bounds.height)
        // Full file rect
        let fullWidth = duration * plotScale
        let fullPos = time - offset
        let fullXPos = center + (fullPos * plotScale)
        let fullRect = CGRect(x: fullXPos, y: 0, width: fullWidth, height: height)
        // Clip rect

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

    func movePlayhead(_ position: Double) {
        func move() {
            let offset = CGFloat(position * plotScale)
            recorderScrollView.contentOffset.x = offset

            if isRecording {
                recordView.showWidth = abs(recordXPosition.constant)
                recordView.hideWidth = 0.0
                if recordXPosition.constant >= CGFloat(center) * -1 {
                    let delta = CGFloat(plotScale * 0.1)
                    recordXPosition.constant -= delta
                }
            }
        }
        UIView.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction], animations: {
            move()
        })
    }
}
