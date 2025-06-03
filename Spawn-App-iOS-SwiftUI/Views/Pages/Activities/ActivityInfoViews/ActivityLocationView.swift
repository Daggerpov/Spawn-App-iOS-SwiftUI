//
//  ActivityLocationView.swift
//  Spawn-App-iOS-SwiftUI
//
//  Created by Shane on 5/10/25.
//

import SwiftUI

struct ActivityLocationView: View {
    @ObservedObject var viewModel: ActivityInfoViewModel

    init(activity: FullFeedActivityDTO) {
        self.viewModel = ActivityInfoViewModel(
            activity: activity, activityInfoType: .location)
    }
    
    var body: some View {
        HStack {
            Image(systemName: "mappin.and.ellipse")
                .foregroundColor(.white)
            Text(viewModel.activityInfoDisplayString)
                .foregroundColor(.white)
                .font(.onestRegular(size: 13))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 3)
        .background(Color.white.opacity(0.18))
        .cornerRadius(12)
    }
}
