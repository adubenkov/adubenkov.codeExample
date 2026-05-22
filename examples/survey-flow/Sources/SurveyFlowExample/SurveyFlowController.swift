import Foundation

final class SurveyFlowController {
    private let surveyService: SurveyService
    private(set) var currentQuestion: SurveyQuestion?

    init(surveyService: SurveyService) {
        self.surveyService = surveyService
    }

    func loadInitialQuestion(survey: Survey) async throws {
        currentQuestion = try await surveyService.getQuestion(surveyId: survey.id, questionId: survey.initialQuestionId)
    }

    func submitSingleSelectAnswer(selectedValue: String?) async throws -> SurveyAnswerResult {
        guard let question = currentQuestion else {
            throw SurveyError.answerRequired
        }
        let answer = try validatedSingleAnswer(for: question, value: selectedValue)
        let result = try await surveyService.answerQuestion(surveyId: question.surveyId, questionId: question.id, answer: answer)
        currentQuestion = result.nextQuestion
        return result
    }

    func submitMultiSelectAnswer(selectedValues: [String]) async throws -> SurveyAnswerResult {
        guard let question = currentQuestion else {
            throw SurveyError.answerRequired
        }
        let answers = try validatedMultiSelectAnswers(for: question, values: selectedValues)
        let result = try await surveyService.answerMultiSelectQuestion(surveyId: question.surveyId, questionId: question.id, answers: answers)
        currentQuestion = result.nextQuestion
        return result
    }

    private func validatedSingleAnswer(for question: SurveyQuestion, value: String?) throws -> String {
        if question.required && (value?.isEmpty ?? true) {
            throw SurveyError.answerRequired
        }
        return value ?? ""
    }

    private func validatedMultiSelectAnswers(for question: SurveyQuestion, values: [String]) throws -> [String] {
        if question.required && values.isEmpty {
            throw SurveyError.answerRequired
        }
        return values
    }
}
