import RealityKit
import ARKit.hand_skeleton

/// A component that tracks the hand skeleton.
struct HandTrackingComponent: Component {
    /// The chirality for the hand this component tracks.
    let chirality: AnchoringComponent.Target.Chirality

    /// A lookup that maps each joint name to the entity that represents it.
    var fingers: [HandSkeleton.JointName: Entity] = [:]
    
    /// Whether joints/entities have been created for this hand already.
    var hasInitialized: Bool = false

    /// Creates a new hand-tracking component.
    /// - Parameter chirality: The chirality of the hand target.
    init(chirality: AnchoringComponent.Target.Chirality) {
        self.chirality = chirality
    }
}
