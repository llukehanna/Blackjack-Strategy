enum PreferenceLabels {
    static func speedTimer(_ seconds: Double) -> String {
        "\(seconds.formatted(.number.precision(.fractionLength(1)))) s"
    }

    static func shoeCheck(_ rounds: Int) -> String { "Every \(rounds) rounds" }
}
