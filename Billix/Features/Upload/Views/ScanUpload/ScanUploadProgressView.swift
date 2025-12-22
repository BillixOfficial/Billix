//
//  ScanUploadProgressView.swift
//  Billix
//
//  Created by Claude Code on 11/24/25.
//

import SwiftUI

struct ScanUploadProgressView: View {
    @ObservedObject var viewModel: ScanUploadViewModel

    var body: some View {
        BouncingPigLoadingView(message: viewModel.statusMessage)
    }
}
