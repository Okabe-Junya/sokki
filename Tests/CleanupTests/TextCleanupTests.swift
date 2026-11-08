import Foundation
import Testing

@testable import Cleanup

struct TextCleanupTests {
  struct Case: Sendable, CustomTestStringConvertible {
    let input: String
    let expected: String

    var testDescription: String { input }

    init(_ input: String, _ expected: String) {
      self.input = input
      self.expected = expected
    }

    static func unchanged(_ text: String) -> Self {
      Self(text, text)
    }
  }

  static let whitespace: [Case] = [
    Case("こんにちは。今どんな感じで聞こえてますか ？", "こんにちは。今どんな感じで聞こえてますか？"),
    Case("  今日は  晴れ  ", "今日は晴れ"),
    Case("今日は\u{3000}晴れ", "今日は晴れ"),
    Case("はい 、 そうです 。", "はい、そうです。"),
    Case("「 こんにちは 」", "「こんにちは」"),
    Case("本当 ！", "本当！"),
    Case("hello   world", "hello world"),
    .unchanged("Swift で書く"),
    .unchanged("GitHub の PR を見る"),
    .unchanged("Is it OK?"),
  ]

  static let fillers: [Case] = [
    Case("えーと、今日は晴れです。", "今日は晴れです。"),
    Case("今日は、あのー、晴れです。", "今日は、晴れです。"),
    Case("その、えっと、資料です。", "資料です。"),
    Case("うーん。そうですね。", "そうですね。"),
    Case("そうですね、えー。", "そうですね。"),
    Case("Um, I think so.", "I think so."),
    Case("I think, uh, we should go.", "I think, we should go."),
    Case("So um we left.", "So we left."),
    Case("It was, like, huge.", "It was, huge."),
    Case("Well, you know, it works.", "Well, it works."),
    .unchanged("あの人は先生です。"),
    .unchanged("その後、帰りました。"),
    .unchanged("まあいいか。"),
    .unchanged("なんかの間違いです。"),
    .unchanged("I like it."),
    .unchanged("You know the answer."),
    .unchanged("The umbrella is here."),
  ]

  static let selfCorrections: [Case] = [
    Case("明日、いや、明後日に行きます。", "明後日に行きます。"),
    Case("東京で、明日、いや違う、明後日に会う。", "東京で、明後日に会う。"),
    Case("明日じゃなくて明後日です。", "明後日です。"),
    Case("いや、それは違います。", "それは違います。"),
    Case("明日、いや、明後日、いや、来週です。", "明後日、いや、来週です。"),
    Case("明日、いや、明後日です。東京じゃなくて大阪です。", "明後日です。大阪です。"),
    Case("Add milk, eggs, no wait, butter.", "Add milk, butter."),
    Case("Use red, scratch that, blue.", "blue."),
    Case("I mean, it works.", "it works."),
    Case("Send it to Bob, no, wait, Alice.", "Alice."),
    .unchanged("雨じゃなくても行きます。"),
    .unchanged("好きじゃなくなった。"),
    .unchanged("I mean it."),
    .unchanged("I will make that cake."),
  ]

  static let unchanged: [Case] = [
    .unchanged(""),
    .unchanged("今日は晴れです。"),
    .unchanged("This is fine."),
    .unchanged("Please review the pull request by Friday."),
    .unchanged("円周率は 3.14 です。"),
  ]

  @Test(arguments: whitespace + fillers + selfCorrections + unchanged)
  func goldenSet(_ testCase: Case) {
    #expect(TextCleanup.apply(testCase.input) == testCase.expected)
  }

  @Test func dictionaryRunsLast() throws {
    let json = Data(#"{"Kubernetes": ["クバネティス"], "PR": ["プルリク"]}"#.utf8)
    let dictionary = try PersonalDictionary.parse(json).dictionary
    let output = TextCleanup.apply(" えーと、クバネティスの プルリク です ", dictionary: dictionary)
    #expect(output == "KubernetesのPRです")
  }
}
