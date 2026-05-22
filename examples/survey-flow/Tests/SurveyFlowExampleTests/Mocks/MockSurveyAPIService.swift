import Foundation

@testable import SurveyFlowExample

final class MockSurveyAPIService: SurveyAPIService {
    var mockGetQuestionResponse: RemoteSurveyQuestionResponse?
    var mockGetSurveysResponse: RemoteSurveyListResponse?
    var mockAnswerResponse: RemoteSurveyAnswerResponse?
    var mockGetQuestionError: Error?
    var mockAnswerError: Error?
    var lastAnswerRequest: RemoteAnswerQuestionRequest?

    func getQuestion(surveyId: String, questionId: String) async throws -> RemoteSurveyQuestionResponse {
        if let mockGetQuestionError {
            throw mockGetQuestionError
        }
        return mockGetQuestionResponse ?? RemoteSurveyQuestionResponse(data: nil)
    }

    func getSurveys(platform: String, category: String) async throws -> RemoteSurveyListResponse {
        return mockGetSurveysResponse ?? RemoteSurveyListResponse(data: nil)
    }

    func answerQuestion(surveyId: String, questionId: String, request: RemoteAnswerQuestionRequest) async throws -> RemoteSurveyAnswerResponse {
        lastAnswerRequest = request
        if let mockAnswerError {
            throw mockAnswerError
        }
        return mockAnswerResponse ?? RemoteSurveyAnswerResponse(data: nil)
    }

    func answerMultiSelectQuestion(surveyId: String, questionId: String, request: RemoteAnswerMultiSelectRequest) async throws -> RemoteSurveyAnswerResponse {
        if let mockAnswerError {
            throw mockAnswerError
        }
        return mockAnswerResponse ?? RemoteSurveyAnswerResponse(data: nil)
    }
}
