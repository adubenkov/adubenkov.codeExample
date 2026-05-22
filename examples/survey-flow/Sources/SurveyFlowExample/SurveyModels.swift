import Foundation

enum SurveyQuestionType: String {
    case infoText = "info-text"
    case selectGrid = "select-grid"
    case select
    case multiSelect = "multi-select"
    case surveySearch = "survey-search"
    case freeText = "free-text"
}

struct SurveyQuestion: Equatable, Hashable {
    let id: String
    let surveyId: String
    let version: Int?
    let type: SurveyQuestionType
    let question: String
    let description: String?
    let placeholderText: String?
    let required: Bool
    let options: [SurveyQuestionOption]?
    let randomizeOptions: Bool
    let nextRules: [SurveyQuestionNextRule]?
    let nextDefault: String?
}

struct SurveyQuestionOption: Equatable, Hashable {
    let value: String?
    let label: String?
    let description: String?
    let allowsCustomText: Bool?
}

struct SurveyQuestionNextRule: Equatable, Hashable {
    let when: String?
    let next: String?
}

struct Survey {
    let id: String
    let name: String?
    let category: String?
    let initialQuestionId: String
    let active: Bool
}

struct SurveyAnswerResult {
    let nextQuestion: SurveyQuestion?
    let completed: Bool
}

enum SurveyError: Error {
    case answerRequired
}
