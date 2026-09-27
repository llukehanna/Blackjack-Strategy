import Testing
import BJSCore
@testable import BJS

@MainActor
struct CardValuesViewModelTests {

    @Test("A correct answer scores, extends the streak, flashes the toast and deals the next card")
    func correct() {
        let vm = CardValuesViewModel(seed: 1)
        vm.answer(vm.card.rank.hiLoValue)
        #expect(vm.answered == 1)
        #expect(vm.correct == 1)
        #expect(vm.streak == 1)
        #expect(vm.toastCount == 1)
        #expect(vm.mistake == nil)
    }

    @Test("A wrong answer resets the streak and holds the card until NEXT")
    func wrong() {
        let vm = CardValuesViewModel(seed: 2)
        vm.answer(vm.card.rank.hiLoValue)
        let card = vm.card
        let wrong = card.rank.hiLoValue == 1 ? -1 : 1
        vm.answer(wrong)
        #expect(vm.answered == 2)
        #expect(vm.correct == 1)
        #expect(vm.streak == 0)
        #expect(vm.mistake == card)
        vm.answer(card.rank.hiLoValue)
        #expect(vm.answered == 2)
        vm.next()
        #expect(vm.mistake == nil)
    }

    @Test("Two consecutive correct answers extend the streak to 2")
    func streakExtends() {
        let vm = CardValuesViewModel(seed: 5)
        vm.answer(vm.card.rank.hiLoValue)
        vm.answer(vm.card.rank.hiLoValue)
        #expect(vm.streak == 2)
    }

    @Test("NEXT does nothing without a mistake")
    func nextWithoutMistake() {
        let vm = CardValuesViewModel(seed: 3)
        let card = vm.card
        vm.next()
        #expect(vm.card == card)
    }

    @Test("Cards cover every rank over many draws")
    func coverage() {
        let vm = CardValuesViewModel(seed: 4)
        var ranks = Set<Rank>()
        for _ in 0..<300 {
            ranks.insert(vm.card.rank)
            vm.answer(vm.card.rank.hiLoValue)
        }
        #expect(ranks.count == Rank.allCases.count)
    }
}
