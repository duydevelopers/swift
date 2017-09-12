// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -typecheck -verify -o - -primary-file %s -swift-version 3
// RUN: %target-swift-frontend(mock-sdk: %clang-importer-sdk) -typecheck -verify -o - -primary-file %s -swift-version 4

// REQUIRES: objc_interop

import Foundation

func takesDefaultArgProtocol(p: DefaultArgProtocol) {
  p.runce()
  p.runceTwice!()
}
