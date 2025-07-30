//
//  EventLocation.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/10/25.
//

import SwiftUI

struct ActivityLocationView: View {
    @StateObject private var viewModel: ActivityInfoViewModel
    static let fontSize: CGFloat = 14
    let font: Font = .onestSemiBold(size: fontSize)
    @Environment(\.colorScheme) private var colorScheme

    init(activity: FullFeedActivityDTO, locationManager: LocationManager) {
        self._viewModel = StateObject(
            wrappedValue: ActivityInfoViewModel(
                activity: activity, 
                locationManager: locationManager
            )
        )
    }
    
    // Theme-aware capsule background color
    private var capsuleColor: Color {
        switch colorScheme {
        case .dark:
            return Color.white.opacity(0.15)
        case .light:
            return Color.black.opacity(0.18)
        @unknown default:
            return Color.black.opacity(0.18)
        }
    }
    
    var body: some View {
        HStack {
            Text(Image(systemName: "mappin.and.ellipse"))
                .foregroundColor(.white)
                .font(.onestSemiBold(size: ActivityLocationView.fontSize-2))
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
