import Foundation

protocol SurveyAPIService: AnyObject {
    func getQuestion(surveyId: String, questionId: String) async throws -> RemoteSurveyQuestionResponse
    func getSurveys(platform: String, category: String) async throws -> RemoteSurveyListResponse
    func answerQuestion(surveyId: String, questionId: String, request: RemoteAnswerQuestionRequest) async throws -> RemoteSurveyAnswerResponse
    func answerMultiSelectQuestion(surveyId: String, questionId: String, request: RemoteAnswerMultiSelectRequest) async throws -> RemoteSurveyAnswerResponse
}

protocol SurveyService: AnyObject {
    func getQuestion(surveyId: String, questionId: String) async throws -> SurveyQuestion?
    func getSurveys(platform: String, category: String) async throws -> [Survey]
    func answerQuestion(surveyId: String, questionId: String, answer: String?) async throws -> SurveyAnswerResult
    func answerMultiSelectQuestion(surveyId: String, questionId: String, answers: [String]) async throws -> SurveyAnswerResult
}
