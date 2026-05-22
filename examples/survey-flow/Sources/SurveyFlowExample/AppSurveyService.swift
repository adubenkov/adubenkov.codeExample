import Foundation

final class AppSurveyService: SurveyService {
    private let surveyAPIService: SurveyAPIService

    private enum Constants {
        static let otherOptionValue = "other"
    }

    init(surveyAPIService: SurveyAPIService) {
        self.surveyAPIService = surveyAPIService
    }

    func getSurveys(platform: String, category: String) async throws -> [Survey] {
        let response = try await surveyAPIService.getSurveys(platform: platform, category: category)
        let surveys = response.data?.surveys ?? []
        return surveys.compactMap { mapSurvey($0) }.filter { $0.active }
    }

    func getQuestion(surveyId: String, questionId: String) async throws -> SurveyQuestion? {
        let response = try await surveyAPIService.getQuestion(surveyId: surveyId, questionId: questionId)
        return mapQuestion(response.data?.question)
    }

    func answerQuestion(surveyId: String, questionId: String, answer: String?) async throws -> SurveyAnswerResult {
        let request = RemoteAnswerQuestionRequest(answer: answer)
        let response = try await surveyAPIService.answerQuestion(surveyId: surveyId, questionId: questionId, request: request)
        return SurveyAnswerResult(
            nextQuestion: mapQuestion(response.data?.nextQuestion),
            completed: response.data?.completed ?? false
        )
    }

    func answerMultiSelectQuestion(surveyId: String, questionId: String, answers: [String]) async throws -> SurveyAnswerResult {
        let request = RemoteAnswerMultiSelectRequest(answer: answers)
        let response = try await surveyAPIService.answerMultiSelectQuestion(surveyId: surveyId, questionId: questionId, request: request)
        return SurveyAnswerResult(
            nextQuestion: mapQuestion(response.data?.nextQuestion),
            completed: response.data?.completed ?? false
        )
    }

    private func mapSurvey(_ remoteSurvey: RemoteSurvey) -> Survey? {
        guard let id = remoteSurvey.id,
              let initialQuestionId = remoteSurvey.initialQuestionId,
              let active = remoteSurvey.active else {
            return nil
        }
        return Survey(
            id: id,
            name: remoteSurvey.name,
            category: remoteSurvey.category,
            initialQuestionId: initialQuestionId,
            active: active
        )
    }

    private func mapQuestion(_ remoteQuestion: RemoteSurveyQuestion?) -> SurveyQuestion? {
        guard let remoteQuestion,
              let id = remoteQuestion.id,
              let surveyId = remoteQuestion.surveyId,
              let typeString = remoteQuestion.type,
              let type = SurveyQuestionType(rawValue: typeString),
              let question = remoteQuestion.question,
              let required = remoteQuestion.required else {
            return nil
        }
        return SurveyQuestion(
            id: id,
            surveyId: surveyId,
            version: remoteQuestion.version,
            type: type,
            question: question,
            description: remoteQuestion.description,
            placeholderText: remoteQuestion.placeholderText,
            required: required,
            options: createSurveyQuestionOptions(from: remoteQuestion.options, randomize: remoteQuestion.randomizeOptions ?? false),
            randomizeOptions: remoteQuestion.randomizeOptions ?? false,
            nextRules: remoteQuestion.nextRules?.map {
                SurveyQuestionNextRule(when: $0.when, next: $0.next)
            },
            nextDefault: remoteQuestion.nextDefault
        )
    }

    private func createSurveyQuestionOptions(from options: [RemoteSurveyQuestionOption]?, randomize: Bool) -> [SurveyQuestionOption]? {
        guard let options else {
            return nil
        }
        let mappedOptions = options.map {
            SurveyQuestionOption(
                value: $0.value,
                label: $0.label,
                description: $0.description,
                allowsCustomText: $0.allowsCustomText
            )
        }
        guard randomize else {
            return mappedOptions
        }
        let (otherOptions, nonOtherOptions) = mappedOptions.reduce(into: ([SurveyQuestionOption](), [SurveyQuestionOption]())) { result, option in
            if isOtherOption(option: option) {
                result.0.append(option)
            } else {
                result.1.append(option)
            }
        }
        return nonOtherOptions.shuffled() + otherOptions
    }

    private func isOtherOption(option: SurveyQuestionOption) -> Bool {
        let value = option.value?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        return value == Constants.otherOptionValue
    }
}
