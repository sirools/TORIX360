import GameController

/// Lit le clavier (Bluetooth, ou celui du Mac dans le simulateur) et la manette (PS5 / Xbox)
/// à chaque image.
///
/// Les touches de déplacement sont lues par **position physique** : sur un clavier AZERTY,
/// Z/Q/S/D tombent exactement là où sont W/A/S/D sur un QWERTY.
@MainActor
final class PlayerInput {
    enum Command: Hashable {
        case inventory
        case map
        case spell(Int)
        case turnLeft
        case turnRight
    }

    struct State {
        /// x = droite, y = avant (de -1 à 1).
        var move: SIMD2<Float> = .zero
        var run = false
        /// Commandes déclenchées pendant cette image (front montant).
        var commands: [Command] = []
    }

    private var previous: Set<Command> = []

    func poll() -> State {
        var state = State()
        var held: Set<Command> = []

        if let keyboard = GCKeyboard.coalesced?.keyboardInput {
            func down(_ key: GCKeyCode) -> Bool { keyboard.button(forKeyCode: key)?.isPressed ?? false }

            if down(.keyW) || down(.upArrow) { state.move.y += 1 }
            if down(.keyS) || down(.downArrow) { state.move.y -= 1 }
            if down(.keyA) { state.move.x -= 1 }
            if down(.keyD) { state.move.x += 1 }
            state.run = down(.leftShift) || down(.rightShift)

            if down(.keyI) { held.insert(.inventory) }
            if down(.keyM) { held.insert(.map) }
            if down(.leftArrow) { held.insert(.turnLeft) }
            if down(.rightArrow) { held.insert(.turnRight) }
            let digits: [GCKeyCode] = [.one, .two, .three, .four, .five, .six]
            for (index, key) in digits.enumerated() where down(key) {
                held.insert(.spell(index))
            }
        }

        if let pad = GCController.current?.extendedGamepad {
            state.move += SIMD2(pad.leftThumbstick.xAxis.value, pad.leftThumbstick.yAxis.value)
            state.run = state.run || pad.leftThumbstickButton?.isPressed == true
            let turn = pad.rightThumbstick.xAxis.value
            if turn < -0.7 { held.insert(.turnLeft) }
            if turn > 0.7 { held.insert(.turnRight) }
            if pad.buttonY.isPressed { held.insert(.inventory) }
            if pad.buttonB.isPressed { held.insert(.map) }
            if pad.buttonA.isPressed { held.insert(.spell(0)) }
            if pad.buttonX.isPressed { held.insert(.spell(1)) }
            if pad.rightShoulder.isPressed { held.insert(.spell(2)) }
            if pad.leftShoulder.isPressed { held.insert(.spell(5)) }
        }

        if simd_length(state.move) > 1 { state.move = simd_normalize(state.move) }
        state.commands = Array(held.subtracting(previous))
        previous = held
        return state
    }
}
