//
//  TagFlowLayout.swift
//  GoalTracker
//
//  Created by Samuel Yanez on 5/19/26.
//

import SwiftUI

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
            proposalWidth: proposal.width ?? 0,
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
        for row in makeRows(for: subviews, proposalWidth: bounds.width) {
            var x = bounds.minX
            for index in row.itemIndices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    proposal: ProposedViewSize(size),
                )
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private func makeRows(
        for subviews: Subviews,
        proposalWidth: CGFloat,
    ) -> [Row] {
        guard proposalWidth > 0 else {
            return [
                Row(
                    itemIndices: subviews.indices.map { $0 },
                    width: subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width },
                    height: subviews.map { $0.sizeThatFits(.unspecified).height }.max() ?? 0,
                )
            ]
        }

        var rows: [Row] = []
        var currentIndices: [Subviews.Index] = []
        var currentWidth: CGFloat = 0
        var currentHeight: CGFloat = 0

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let proposedWidth =
                currentIndices.isEmpty ? size.width : currentWidth + spacing + size.width

            if proposedWidth > proposalWidth, currentIndices.isEmpty == false {
                appendRow(
                    itemIndices: currentIndices,
                    width: currentWidth,
                    height: currentHeight,
                    to: &rows,
                )
                currentIndices = [index]
                currentWidth = size.width
                currentHeight = size.height
            } else {
                currentIndices.append(index)
                currentWidth = proposedWidth
                currentHeight = max(currentHeight, size.height)
            }
        }

        appendRow(
            itemIndices: currentIndices,
            width: currentWidth,
            height: currentHeight,
            to: &rows,
        )

        return rows
    }

    private func appendRow(
        itemIndices: [Subviews.Index],
        width: CGFloat,
        height: CGFloat,
        to rows: inout [Row],
    ) {
        guard itemIndices.isEmpty == false else {
            return
        }
        rows.append(
            Row(
                itemIndices: itemIndices,
                width: width,
                height: height,
            ),
        )
    }

    // MARK: - Row

    private struct Row {
        var itemIndices: [Int]
        var width: CGFloat
        var height: CGFloat
    }
}
