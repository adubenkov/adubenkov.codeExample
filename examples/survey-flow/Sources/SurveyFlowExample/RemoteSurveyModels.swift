import Foundation

struct RemoteSurveyQuestionOption: Codable {
    let value: String?
    let label: String?
    let description: String?
    let allowsCustomText: Bool?
}

struct RemoteSurveyQuestionNextRule: Codable {
    let when: String?
    let next: String?
}

struct RemoteSurveyQuestion: Codable {
    let id: String?
    let surveyId: String?
    let version: Int?
    let type: String?
    let question: String?
    let description: String?
    let placeholderText: String?
    let required: Bool?
    let options: [RemoteSurveyQuestionOption]?
    let randomizeOptions: Bool?
    let nextRules: [RemoteSurveyQuestionNextRule]?
    let nextDefault: String?
}

struct RemoteSurveyAnswerData: Codable {
    let nextQuestion: RemoteSurveyQuestion?
    let completed: Bool?
}

struct RemoteSurveyAnswerResponse: Codable {
    let data: RemoteSurveyAnswerData?
}

struct RemoteSurveyListData: Codable {
    let surveys: [RemoteSurvey]?
}

struct RemoteSurveyListResponse: Codable {
    let data: RemoteSurveyListData?
}

struct RemoteSurvey: Codable {
    let id: String?
    let name: String?
    let category: String?
    let initialQuestionId: String?
    let active: Bool?
}

struct RemoteSurveyQuestionData: Codable {
    let question: RemoteSurveyQuestion?
}

struct RemoteSurveyQuestionResponse: Codable {
    let data: RemoteSurveyQuestionData?
}

struct RemoteAnswerQuestionRequest: Codable {
    let answer: String?
}

struct RemoteAnswerMultiSelectRequest: Codable {
    let answer: [String]
}
