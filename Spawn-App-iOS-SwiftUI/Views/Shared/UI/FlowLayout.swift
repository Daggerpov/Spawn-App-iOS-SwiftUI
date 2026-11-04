//
//  FlowLayout.swift
//  Spawn-App-iOS-SwiftUI
//

import SwiftUI

/// Lays out subviews left to right at their natural size and wraps onto a new row
/// when the next one doesn't fit (e.g. interest chips that size to their text)
struct FlowLayout: Layout {
	var spacing: CGFloat = 8

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
		let rows = arrangeRows(maxWidth: proposal.width ?? .infinity, subviews: subviews)
		let width = rows.map(\.width).max() ?? 0
		let height = rows.reduce(0) { $0 + $1.height } + spacing * CGFloat(max(rows.count - 1, 0))
		return CGSize(width: width, height: height)
	}

	func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
		var y = bounds.minY
		for row in arrangeRows(maxWidth: bounds.width, subviews: subviews) {
			var x = bounds.minX
			for (index, size) in zip(row.indices, row.sizes) {
				// Vertically center items within the row
				subviews[index].place(
					at: CGPoint(x: x, y: y + (row.height - size.height) / 2),
					proposal: ProposedViewSize(size)
				)
				x += size.width + spacing
			}
			y += row.height + spacing
		}
	}

	private struct Row {
		var indices: [Int] = []
		var sizes: [CGSize] = []
		var width: CGFloat = 0
		var height: CGFloat = 0
	}

	private func arrangeRows(maxWidth: CGFloat, subviews: Subviews) -> [Row] {
		var rows: [Row] = []
		var current = Row()

		for (index, subview) in subviews.enumerated() {
			// Use the natural size, but never wider than a full row
			var size = subview.sizeThatFits(.unspecified)
			if size.width > maxWidth {
				size = subview.sizeThatFits(ProposedViewSize(width: maxWidth, height: nil))
			}

			if !current.indices.isEmpty && current.width + spacing + size.width > maxWidth {
				rows.append(current)
				current = Row()
			}

			current.width += (current.indices.isEmpty ? 0 : spacing) + size.width
			current.height = max(current.height, size.height)
			current.indices.append(index)
			current.sizes.append(size)
		}

		if !current.indices.isEmpty {
			rows.append(current)
		}
		return rows
	}
}
