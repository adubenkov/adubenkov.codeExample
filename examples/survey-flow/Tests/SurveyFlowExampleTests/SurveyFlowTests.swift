import XCTest

@testable import SurveyFlowExample

final class SurveyQuestionNavigatorTests: XCTestCase {
    func testNextQuestionIdMatchesRule() {
        let question = SurveyQuestion(
            id: "q1",
            surveyId: "s1",
            version: nil,
            type: .select,
            question: "Pick one",
            description: nil,
            placeholderText: nil,
            required: true,
            options: nil,
            randomizeOptions: false,
            nextRules: [SurveyQuestionNextRule(when: "yes", next: "q2")],
            nextDefault: "q-default"
        )

        XCTAssertEqual(SurveyQuestionNavigator.nextQuestionId(for: question, selectedAnswer: "yes"), "q2")
        XCTAssertEqual(SurveyQuestionNavigator.nextQuestionId(for: question, selectedAnswer: "no"), "q-default")
    }

    func testIsFinishActionWhenNoBranching() {
        let question = SurveyQuestion(
            id: "q1",
            surveyId: "s1",
            version: nil,
            type: .freeText,
            question: "Feedback",
            description: nil,
            placeholderText: nil,
            required: false,
            options: nil,
            randomizeOptions: false,
            nextRules: nil,
            nextDefault: nil
        )

        XCTAssertTrue(SurveyQuestionNavigator.isFinishAction(for: question))
    }
}

final class AppSurveyServiceTests: XCTestCase {
    private var mockAPIService: MockSurveyAPIService!
    private var service: AppSurveyService!

    override func setUp() {
        super.setUp()
        mockAPIService = MockSurveyAPIService()
        service = AppSurveyService(surveyAPIService: mockAPIService)
    }

    func testRandomizeOptionsKeepsOtherLast() async throws {
        mockAPIService.mockGetQuestionResponse = RemoteSurveyQuestionResponse(
            data: RemoteSurveyQuestionData(
                question: RemoteSurveyQuestion(
                    id: "q1",
                    surveyId: "s1",
                    version: nil,
                    type: "select",
                    question: "Q",
                    description: nil,
                    placeholderText: nil,
                    required: true,
                    options: [
                        RemoteSurveyQuestionOption(value: "a", label: "A", description: nil, allowsCustomText: nil),
                        RemoteSurveyQuestionOption(value: "other", label: "Other", description: nil, allowsCustomText: true),
                        RemoteSurveyQuestionOption(value: "b", label: "B", description: nil, allowsCustomText: nil)
                    ],
                    randomizeOptions: true,
                    nextRules: nil,
                    nextDefault: nil
                )
            )
        )

        let question = try await XCTUnwrap(try await service.getQuestion(surveyId: "s1", questionId: "q1"))
        let options = try XCTUnwrap(question.options)

        XCTAssertEqual(options.last?.value, "other")
    }
}

final class SurveyFlowControllerTests: XCTestCase {
    private var mockAPIService: MockSurveyAPIService!
    private var service: AppSurveyService!
    private var controller: SurveyFlowController!

    override func setUp() {
        super.setUp()
        mockAPIService = MockSurveyAPIService()
        service = AppSurveyService(surveyAPIService: mockAPIService)
        controller = SurveyFlowController(surveyService: service)
    }

    func testSubmitSingleSelectAnswerUpdatesCurrentQuestion() async throws {
        mockAPIService.mockGetQuestionResponse = RemoteSurveyQuestionResponse(
            data: RemoteSurveyQuestionData(
                question: RemoteSurveyQuestion(
                    id: "q1",
                    surveyId: "s1",
                    version: nil,
                    type: "select",
                    question: "Q",
                    description: nil,
                    placeholderText: nil,
                    required: true,
                    options: nil,
                    randomizeOptions: false,
                    nextRules: nil,
                    nextDefault: nil
                )
            )
        )
        mockAPIService.mockAnswerResponse = RemoteSurveyAnswerResponse(
            data: RemoteSurveyAnswerData(
                nextQuestion: RemoteSurveyQuestion(
                    id: "q2",
                    surveyId: "s1",
                    version: nil,
                    type: "free-text",
                    question: "Q2",
                    description: nil,
                    placeholderText: nil,
                    required: false,
                    options: nil,
                    randomizeOptions: false,
                    nextRules: nil,
                    nextDefault: nil
                ),
                completed: false
            )
        )
        try await controller.loadInitialQuestion(survey: Survey(id: "s1", name: nil, category: "postPurchase", initialQuestionId: "q1", active: true))

        let result = try await controller.submitSingleSelectAnswer(selectedValue: "yes")

        XCTAssertFalse(result.completed)
        XCTAssertEqual(controller.currentQuestion?.id, "q2")
        XCTAssertEqual(mockAPIService.lastAnswerRequest?.answer, "yes")
    }

    func testSubmitRequiredAnswerThrowsWhenEmpty() async throws {
        mockAPIService.mockGetQuestionResponse = RemoteSurveyQuestionResponse(
            data: RemoteSurveyQuestionData(
                question: RemoteSurveyQuestion(
                    id: "q1",
                    surveyId: "s1",
                    version: nil,
                    type: "select",
                    question: "Q",
                    description: nil,
                    placeholderText: nil,
                    required: true,
                    options: nil,
                    randomizeOptions: false,
                    nextRules: nil,
                    nextDefault: nil
                )
            )
        )
        try await controller.loadInitialQuestion(survey: Survey(id: "s1", name: nil, category: "postPurchase", initialQuestionId: "q1", active: true))

        do {
            _ = try await controller.submitSingleSelectAnswer(selectedValue: nil)
            XCTFail("Expected answerRequired")
        } catch {
            guard case SurveyError.answerRequired = error else {
                return XCTFail("Expected answerRequired")
            }
        }
    }
}
