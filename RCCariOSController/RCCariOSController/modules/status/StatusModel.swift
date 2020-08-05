//
//  StatusModel.swift
//  RCCariOSController
//
//  Created by Michal Fousek on 04/08/2020.
//  Copyright © 2020 Chlup. All rights reserved.
//

import Foundation
import RxSwift

enum StatusData {
    case loading
    case loaded(Statuses, Int16)
}

protocol StatusModel {
    var statusStream: Observable<StatusData> { get }

    func start()
    func stop()
}

class StatusModelImpl {

    struct Dependencies {
        let btManager = DI.getBTManager()
        let commandsManager = DI.getCommandsManager()
    }

    private let deps = Dependencies()

    init() { }
}

extension StatusModelImpl: StatusModel {
    var statusStream: Observable<StatusData> {
        let statusStream = deps.btManager.statusDataStream
            .map { Statuses(data: $0.data) }

        let hdopStream = deps.btManager.hdopDataStream
            .map { $0.data.withUnsafeBytes { $0.load(as: Int16.self) } }

        return Observable.combineLatest(statusStream, hdopStream) { .loaded($0, $1) }
            .startWith(.loading)
    }

    func start() {
        deps.commandsManager.startReceivingHDOP()
        deps.commandsManager.startReceivingStatus()
        deps.commandsManager.commit()
    }

    func stop() {
        deps.commandsManager.stopReceivingHDOP()
        deps.commandsManager.stopReceivingStatus()
        deps.commandsManager.commit()

    }
}
