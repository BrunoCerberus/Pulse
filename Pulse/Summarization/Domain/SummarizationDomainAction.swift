import Foundation

enum SummarizationDomainAction: Equatable {
    case startSummarization
    case cancelSummarization
    case summarizationStateChanged(SummarizationState)
    case summarizationTokenReceived(String)
    case modelStatusChanged(LLMModelStatus)
}
