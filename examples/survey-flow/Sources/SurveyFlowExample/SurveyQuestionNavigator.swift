import Foundation

enum SurveyQuestionNavigator {
    static func nextQuestionId(for question: SurveyQuestion, selectedAnswer: String) -> String? {
        if let rules = question.nextRules {
            for rule in rules {
                if rule.when == selectedAnswer, let next = rule.next {
                    return next
                }
            }
        }
        return question.nextDefault
    }

    static func isFinishAction(for question: SurveyQuestion) -> Bool {
        let hasNextRules = question.nextRules?.isEmpty == false
        let hasNextDefault = question.nextDefault != nil
        return !hasNextRules && !hasNextDefault
    }
}
