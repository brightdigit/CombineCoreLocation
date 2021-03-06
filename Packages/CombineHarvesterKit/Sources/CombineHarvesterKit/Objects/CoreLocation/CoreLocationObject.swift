import Combine
import CoreLocation
import SwiftUI

public class CoreLocationObject: ObservableObject {
  @Published var authorizationStatus = CLAuthorizationStatus.notDetermined
  @Published var location: CLLocation?

  public let manager: CLLocationManager
  public let publicist: CLLocationManagerCombineDelegate

  public var cancellables = [AnyCancellable]()

  public init() {
    let manager = CLLocationManager()
    let publicist = CLLocationManagerPublicist()

    manager.delegate = publicist

    self.manager = manager
    self.publicist = publicist

    // trigger an update when authorization changes
    publicist.authorizationPublisher
      .filter { $0.isAuthorized }
      .map { _ in () }
      .sink(receiveValue: beginUpdates)
      .store(in: &cancellables)

    // set authorization status when authorization changes
    publicist.authorizationPublisher
      // since this is used in the UI,
      //  it needs to be on the main DispatchQueue
      .receive(on: DispatchQueue.main)
      // store the value in the authorizationStatus property
      .assign(to: &$authorizationStatus)

    publicist.locationPublisher
      // convert the array of CLLocation into a Publisher itself
      .flatMap(Publishers.Sequence.init(sequence:))
      // in order to match the property map to Optional
      .map { $0 as CLLocation? }
      // since this is used in the UI,
      //  it needs to be on the main DispatchQueue
      .receive(on: DispatchQueue.main)
      // store the value in the location property
      .assign(to: &$location)
  }

  func authorize() {
    if manager.authorizationStatus == .notDetermined {
      manager.requestWhenInUseAuthorization()
    }
  }

  func beginUpdates() {
    manager.startUpdatingLocation()
  }
}
