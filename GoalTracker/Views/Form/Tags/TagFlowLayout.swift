//
//  TagFlowLayout.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftUI

// MARK: - TagFlowLayout

/// A lightweight wrapping layout for tag chips that fills each row before continuing on the next line.
struct TagFlowLayout: Layout {
	var spacing: CGFloat = 8

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Void,
	) -> CGSize {
		let rows = makeRows(
			for: subviews,
			availableWidth: proposal.width ?? 0,
		)
		return CGSize(
			width: proposal.width ?? rows.map(\.width).max() ?? 0,
			height: rows.reduce(0) { height, row in
				height + row.height
			} + CGFloat(max(rows.count - 1, 0)) * spacing,
		)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Void,
	) {
		var y = bounds.minY
		for row in makeRows(for: subviews, availableWidth: bounds.width) {
			var x = bounds.minX
			for item in row.items {
				subviews[item.index]
					.place(
						at: CGPoint(x: x, y: y),
						proposal: ProposedViewSize(item.size),
					)
				x += item.size.width + spacing
			}
			y += row.height + spacing
		}
	}

	private func makeRows(
		for subviews: Subviews,
		availableWidth: CGFloat,
	) -> [Row] {
		let items = subviews.indices.map { index in
			MeasuredItem(
				index: index,
				size: subviews[index].sizeThatFits(.unspecified),
			)
		}

		guard availableWidth > 0 else {
			return [
				Row(
					items: items,
					width: items.reduce(0) { totalWidth, item in
						totalWidth + item.size.width
					},
					height:
						items.map { item in
							item.size.height
						}
						.max() ?? 0,
				)
			]
		}

		var rows: [Row] = []
		var currentItems: [MeasuredItem] = []
		var currentWidth: CGFloat = 0
		var currentHeight: CGFloat = 0

		for item in items {
			let proposedWidth =
				currentItems.isEmpty ? item.size.width : currentWidth + spacing + item.size.width

			if proposedWidth > availableWidth, currentItems.isEmpty == false {
				appendRow(
					items: currentItems,
					width: currentWidth,
					height: currentHeight,
					to: &rows,
				)
				currentItems = [item]
				currentWidth = item.size.width
				currentHeight = item.size.height
			} else {
				currentItems.append(item)
				currentWidth = proposedWidth
				currentHeight = max(currentHeight, item.size.height)
			}
		}

		appendRow(
			items: currentItems,
			width: currentWidth,
			height: currentHeight,
			to: &rows,
		)

		return rows
	}

	private func appendRow(
		items: [MeasuredItem],
		width: CGFloat,
		height: CGFloat,
		to rows: inout [Row],
	) {
		guard items.isEmpty == false else {
			return
		}
		rows.append(
			Row(
				items: items,
				width: width,
				height: height,
			),
		)
	}

	// MARK: - MeasuredItem

	private struct MeasuredItem {
		var index: Int
		var size: CGSize
	}

	// MARK: - Row

	private struct Row {
		var items: [MeasuredItem]
		var width: CGFloat
		var height: CGFloat
	}
}
