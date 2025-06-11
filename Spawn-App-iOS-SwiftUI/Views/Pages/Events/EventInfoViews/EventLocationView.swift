//
//  EventLocation.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/10/25.
//

import SwiftUI

struct EventLocationView: View {
    @ObservedObject var viewModel: ActivityInfoViewModel
    static let fontSize: CGFloat = 14
    let capsuleColor: Color = Color.black.opacity(0.18)
    let font: Font = .onestSemiBold(size: fontSize)

    init(event: FullFeedEventDTO) {
        self.viewModel = ActivityInfoViewModel(
            activity: event)
    }
    
    var body: some View {
        HStack {
            Text(Image(systemName: "mappin.and.ellipse"))
                .foregroundColor(.white)
                .font(.onestSemiBold(size: EventLocationView.fontSize-2))
            Text(viewModel.getDisplayString(activityInfoType: .location))
                .foregroundColor(.white)
                .font(font) +
            Text(" • \(viewModel.getDisplayString(activityInfoType: .distance))")
                .foregroundColor(.white)
                .font(font)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(capsuleColor)
        .cornerRadius(100)
    }
}
