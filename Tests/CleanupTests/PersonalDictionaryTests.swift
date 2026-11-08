import Foundation
import Testing

@testable import Cleanup

struct PersonalDictionaryTests {
  private static let sample = """
    {"Kubernetes": ["クバネティス", "くばねてぃす"], "GitHub": ["ギットハブ", "github"], \
    "PR": ["プルリク", "プルリクエスト"]}
    """

  private func parse(_ json: String) throws -> (
    dictionary: PersonalDictionary, warnings: [PersonalDictionary.Warning]
  ) {
    try PersonalDictionary.parse(Data(json.utf8))
  }

  @Test func parsesSampleWithoutWarnings() throws {
    let (dictionary, warnings) = try parse(Self.sample)
    #expect(warnings.isEmpty)
    #expect(dictionary.apply(to: "くばねてぃすとギットハブ") == "KubernetesとGitHub")
  }

  @Test func emptyChangesNothing() {
    #expect(PersonalDictionary.empty.apply(to: "github") == "github")
  }

  @Test func prefersLongestSpokenForm() throws {
    let dictionary = try parse(Self.sample).dictionary
    #expect(dictionary.apply(to: "プルリクエストを出す") == "PRを出す")
    #expect(dictionary.apply(to: "プルリクを出す") == "PRを出す")
  }

  @Test func latinFormsIgnoreCase() throws {
    let dictionary = try parse(Self.sample).dictionary
    #expect(dictionary.apply(to: "Push to GITHUB and github.") == "Push to GitHub and GitHub.")
    #expect(dictionary.apply(to: "githubで見る") == "GitHubで見る")
  }

  @Test func latinFormsMatchWholeWordsOnly() throws {
    let dictionary = try parse(#"{"PR": ["pr"]}"#).dictionary
    #expect(dictionary.apply(to: "print a pr") == "print a PR")
  }

  @Test func cjkFormsMatchExactly() throws {
    let dictionary = try parse(Self.sample).dictionary
    #expect(dictionary.apply(to: "クバネテイス") == "クバネテイス")
    #expect(dictionary.apply(to: "クバネティス") == "Kubernetes")
  }

  @Test func doesNotRescanItsOutput() throws {
    let (dictionary, warnings) = try parse(#"{"B": ["A"], "C": ["B"]}"#)
    #expect(dictionary.apply(to: "A") == "B")
    #expect(warnings == [.chainedSpokenForm("B", replacement: "C")])
  }

  @Test func repeatedParsesAreIdentical() throws {
    let first = try parse(Self.sample)
    let second = try parse(Self.sample)
    #expect(first.dictionary == second.dictionary)
    #expect(first.warnings == second.warnings)
  }

  @Test func duplicateSpokenFormKeepsFirstSortedKey() throws {
    let (dictionary, warnings) = try parse(#"{"Zed": ["ぜっと"], "Alpha": ["ぜっと"]}"#)
    #expect(dictionary.apply(to: "ぜっと") == "Alpha")
    #expect(warnings == [.duplicateSpokenForm("ぜっと", kept: "Alpha", ignored: "Zed")])
  }

  @Test func emptyStringsAreSkipped() throws {
    let (dictionary, warnings) = try parse(#"{"": ["から"], "Go": ["", "ごー"]}"#)
    #expect(dictionary.apply(to: "からごー") == "からGo")
    #expect(warnings == [.emptyReplacement, .emptySpokenForm(replacement: "Go")])
  }

  @Test func spokenFormEqualToReplacementIsSkipped() throws {
    let (dictionary, warnings) = try parse(#"{"Swift": ["Swift"]}"#)
    #expect(dictionary == .empty)
    #expect(warnings == [.spokenFormIsReplacement("Swift")])
  }

  @Test func malformedJSONThrows() {
    #expect(throws: PersonalDictionary.ParseError.self) { try parse("{\"a\": [") }
  }

  @Test func nonObjectRootThrows() {
    #expect(throws: PersonalDictionary.ParseError.notAnObject) { try parse(#"["a"]"#) }
  }

  @Test func nonStringArrayValueThrows() {
    #expect(throws: PersonalDictionary.ParseError.notAStringArray(replacement: "A")) {
      try parse(#"{"A": "b"}"#)
    }
  }

  @Test func warningsDescribeThemselves() {
    let warning = PersonalDictionary.Warning.duplicateSpokenForm("x", kept: "A", ignored: "B")
    #expect(warning.description.contains("\"A\""))
  }
}
