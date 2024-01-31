import SwiftUI

/// SwiftUI layout that arranges provided collection of views in a table.
public struct SimpleTableLayout: Layout {
  public struct Cache: Equatable {
        var columnWidth: [Int: CGFloat]
        var rowHeight: [Int: CGFloat]
        var cellLocations: [Cell: CGPoint]
        var cellSizes: [Cell: CGSize]

        var size: CGSize {
            CGSize(
                width: columnWidth.map(\.value).reduce(0, +),
                height: rowHeight.map(\.value).reduce(0, +)
            )
        }

        func location(for cell: Cell) -> CGPoint {
            cellLocations[cell, default: .zero]
        }

        func size(for cell: Cell) -> CGSize {
            cellSizes[cell, default: .zero]
        }
    }

  struct Cell: Equatable {
    var column: Int
    var row: Int
  }

  /// SwiftUI layout that arranges provided collection of views in a table.
  ///
  /// - Parameters:
  ///   - columnsCount: Number of columns in the table.
  ///   - equalColumnWidths: If `true`, all columns will have equal width. Defaults to `false`.
  ///   - equalRowHeights: If `true`, all rows will have equal height. Defaults to `false`.
  ///   - cellAspectRatio: Constrains cell's dimensions to the specified aspect ratio. If provided,
  ///     `equalColumnWidths` and `equalRowHeights` parameters will be ignored. Defaults to `nil`.
  public init(
    columnsCount: Int,
    equalColumnWidths: Bool = false,
    equalRowHeights: Bool = false,
    cellAspectRatio: CGFloat? = nil
  ) {
    self.columnsCount = columnsCount
    self.equalColumnWidths = equalColumnWidths
    self.equalRowHeights = equalRowHeights
    self.cellAspectRatio = cellAspectRatio
  }

  public var columnsCount: Int
  public var equalColumnWidths: Bool
  public var equalRowHeights: Bool
  public var cellAspectRatio: CGFloat?

  public func makeCache(subviews: Subviews) -> Cache {
        var columnWidth: [Int: CGFloat] = [:]
        var rowHeight: [Int: CGFloat] = [:]
        var cellLocations: [Cell: CGPoint] = [:]
        var cellSizes: [Cell: CGSize] = [:]

        for index in subviews.indices {
            let subviewSize = subviews[index].sizeThatFits(.unspecified)
            let cell = cell(at: index)
            columnWidth[cell.column] = max(columnWidth[cell.column, default: 0], subviewSize.width)
            rowHeight[cell.row] = max(rowHeight[cell.row, default: 0], subviewSize.height)

            // Calculate cell location and size
            let cellLocation = CGPoint(
                x: (0..<cell.column).map { columnWidth[$0, default: 0] }.reduce(0, +),
                y: (0..<cell.row).map { rowHeight[$0, default: 0] }.reduce(0, +)
            )
            let cellSize = CGSize(
                width: columnWidth[cell.column, default: 0],
                height: rowHeight[cell.row, default: 0]
            )
            cellLocations[cell] = cellLocation
            cellSizes[cell] = cellSize
        }

        // Streamline equal widths/heights calculation
        if equalColumnWidths, cellAspectRatio == nil {
            let maxColumnWidth = columnWidth.values.max() ?? 0
            columnWidth.keys.forEach { columnWidth[$0] = maxColumnWidth }
        }

        if equalRowHeights, cellAspectRatio == nil {
            let maxRowHeight = rowHeight.values.max() ?? 0
            rowHeight.keys.forEach { rowHeight[$0] = maxRowHeight }
        }

    if let cellAspectRatio {
      var cellWidth = columnWidth.map(\.value).reduce(CGFloat.zero, max)
      var cellHeight = rowHeight.map(\.value).reduce(CGFloat.zero, max)
      if (cellWidth / cellHeight) < cellAspectRatio {
        cellWidth = cellHeight * cellAspectRatio
      } else {
        cellHeight = cellWidth / cellAspectRatio
      }
      columnWidth = columnWidth.mapValues { _ in cellWidth }
      rowHeight = rowHeight.mapValues { _ in cellHeight }
    }

            return Cache(columnWidth: columnWidth, rowHeight: rowHeight, cellLocations: cellLocations, cellSizes: cellSizes)
  }

  public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
    cache.size
  }

  public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
    for index in subviews.indices {
      let cell = cell(at: index)
      subviews[index].place(
        at: cache.location(for: cell).applying(.init(translationX: bounds.minX, y: bounds.minY)),
        anchor: .topLeading,
        proposal: .init(cache.size(for: cell))
      )
    }
  }

  func cell(at subviewIndex: Int) -> Cell {
    Cell(
      column: subviewIndex % columnsCount,
      row: Int((Float(subviewIndex) / Float(columnsCount)).rounded(.down))
    )
  }
}
