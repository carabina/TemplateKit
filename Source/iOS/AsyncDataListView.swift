//
//  AsyncDataListView.swift
//  TemplateKit
//
//  Created by Matias Cudich on 9/12/16.
//  Copyright © 2016 Matias Cudich. All rights reserved.
//

import Foundation

protocol AsyncDataListView: class {
  var operationQueue: AsyncQueue<AsyncOperation> { get }
  var context: Context { get set }
  weak var eventTarget: Node? { get set }
  var nodeCache: [[Node?]] { get set }

  func insertItems(at indexPaths: [IndexPath], completion: @escaping () -> Void)
  func deleteItems(at indexPaths: [IndexPath], completion: @escaping () -> Void)
  func insertSections(_ sections: IndexSet, completion: @escaping () -> Void)
  func deleteSections(_ sections: IndexSet, completion: @escaping () -> Void)
  func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, completion: @escaping () -> Void)
  func moveSection(_ section: Int, toSection newSection: Int, completion: @escaping () -> Void)
  func reloadItems(at indexPaths: [IndexPath], completion: @escaping () -> Void)
  func reloadSections(_ sections: IndexSet, completion: @escaping () -> Void)
  func reloadData(completion: @escaping () -> Void)

  func element(at indexPath: IndexPath) -> Element?
  func node(at indexPath: IndexPath) -> Node?
  func totalNumberOfSections() -> Int
  func totalNumberOfRows(in section: Int) -> Int?
}

extension AsyncDataListView {
  func insertItems(at indexPaths: [IndexPath], completion: @escaping () -> Void) {
    precacheNodes(at: indexPaths)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func deleteItems(at indexPaths: [IndexPath], completion: @escaping () -> Void) {
    purgeNodes(at: indexPaths)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func insertSections(_ sections: IndexSet, completion: @escaping () -> Void) {
    precacheNodes(in: sections)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func deleteSections(_ sections: IndexSet, completion: @escaping () -> Void) {
    purgeNodes(in: sections)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func moveItem(at indexPath: IndexPath, to newIndexPath: IndexPath, completion: @escaping () -> Void) {
    let node = nodeCache[indexPath.section].remove(at: indexPath.row)
    nodeCache[newIndexPath.section].insert(node, at: newIndexPath.row)

    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func moveSection(_ section: Int, toSection newSection: Int, completion: @escaping () -> Void) {
    let section = nodeCache.remove(at: section)
    nodeCache.insert(section, at: newSection)

    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func reloadItems(at indexPaths: [IndexPath], completion: @escaping () -> Void) {
    precacheNodes(at: indexPaths)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func reloadSections(_ sections: IndexSet, completion: @escaping () -> Void) {
    precacheNodes(in: sections)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func reloadData(completion: @escaping () -> Void) {
    let sectionCount = totalNumberOfSections()
    let indexPaths: [IndexPath] = (0..<sectionCount).reduce([]) { previous, section in
      return previous + self.indexPaths(forSection: section)
    }

    nodeCache.removeAll()
    precacheNodes(at: indexPaths)
    operationQueue.enqueueOperation { done in
      DispatchQueue.main.async {
        completion()
        done()
      }
    }
  }

  func node(at indexPath: IndexPath) -> Node? {
    return nodeCache[indexPath.section][indexPath.row]
  }

  private func indexPaths(forSection section: Int) -> [IndexPath] {
    let expectedRowCount = totalNumberOfRows(in: section) ?? 0
    return (0..<expectedRowCount).map { row in
      return IndexPath(row: row, section: section)
    }
  }

  private func precacheNodes(at indexPaths: [IndexPath]) {
    operationQueue.enqueueOperation { done in
      self.performPrecache(for: indexPaths, done: done)
    }
  }

  private func precacheNodes(in sections: IndexSet) {
    operationQueue.enqueueOperation { done in
      let indexPaths: [IndexPath] = sections.reduce([]) { previous, section in
        return previous + self.indexPaths(forSection: section)
      }
      self.performPrecache(for: indexPaths, done: done)
    }
  }

  private func performPrecache(for indexPaths: [IndexPath], done: @escaping () -> Void) {
    if indexPaths.count == 0 {
      return done()
    }

    var pending = indexPaths.count
    for indexPath in indexPaths.sorted(by: { $0.row < $1.row }) {
      guard let element = self.element(at: indexPath) else {
        continue
      }

      UIKitRenderer.render(element, context: context as Context) { node in
        self.cacheNode(node, at: indexPath)
        pending -= 1
        if pending == 0 {
          done()
        }
      }
    }
  }

  private func cacheNode(_ node: Node, at indexPath: IndexPath) {
    if nodeCache.count <= indexPath.section {
      nodeCache.append([Node?]())
    }
    node.owner = eventTarget

    var delta = indexPath.row - nodeCache[indexPath.section].count
    while delta >= 0 {
      nodeCache[indexPath.section].append(nil)
      delta -= 1
    }
    nodeCache[indexPath.section][indexPath.row] = node
  }

  private func purgeNodes(at indexPaths: [IndexPath]) {
    operationQueue.enqueueOperation { done in
      self.performPurge(for: indexPaths, done: done)
    }
  }

  private func purgeNodes(in sections: IndexSet) {
    operationQueue.enqueueOperation { done in
      let indexPaths: [IndexPath] = sections.reduce([]) { previous, section in
        return previous + self.indexPaths(forSection: section)
      }
      self.performPurge(for: indexPaths, done: done)
    }
  }

  private func performPurge(for indexPaths: [IndexPath], done: @escaping () -> Void) {
   if indexPaths.count == 0 {
      return done()
    }

    for indexPath in indexPaths {
      nodeCache[indexPath.section].remove(at: indexPath.row)
    }

    done()
  }
}
