//
//  AssessmentResult.swift
//  
//

import Foundation
import JsonModel

/// An ``AssessmentResult`` is the top-level ``ResultData`` for an assessment.
public protocol AssessmentResult : BranchNodeResult {

    /// A unique identifier for this run of the assessment. This property is defined as readwrite
    /// to allow the controller for the task to set this on the ``AssessmentResult`` children
    /// included in this run.
    var taskRunUUID: UUID { get set }

    /// The ``versionString`` may be a semantic version, timestamp, or sequential revision integer.
    var versionString: String? { get }
    
    /// An identifier for the assessment model associated with this result. If included, this
    /// is intended to match the identifier used by the services that requested running the
    /// assessment. This could be a schedule identifier or an identifier in a different namespace
    /// than the "task identifier" used by the assessment developers to identify their assessments.
    var assessmentIdentifier: String? { get }
    
    /// An identifier that can be used either by the assessment developers or scientists as needed.
    var schemaIdentifier: String?  { get }
}

/// Abstract implementation to allow extending an assessment result while retaining the serializable type.
open class AbstractAssessmentResultObject : AbstractBranchNodeResultObject {
    private enum CodingKeys : String, OrderedEnumCodingKey, OpenOrderedCodingKey {
        case assessmentIdentifier, versionString, taskRunUUID, schemaIdentifier, jsonSchema = "$schema"
        var relativeIndex: Int { 1 }
    }

    public let versionString: String?
    public var assessmentIdentifier: String?
    public var schemaIdentifier: String?
    public var taskRunUUID: UUID

    /// Default initializer for this object.
    public init(identifier: String,
                versionString: String? = nil,
                assessmentIdentifier: String? = nil,
                schemaIdentifier: String? = nil,
                startDate: Date = Date(),
                endDate: Date? = nil,
                taskRunUUID: UUID = UUID(),
                stepHistory: [ResultData] = [],
                asyncResults: [ResultData]? = nil,
                path: [PathMarker] = []) {
        self.versionString = versionString
        self.assessmentIdentifier = assessmentIdentifier
        self.schemaIdentifier = schemaIdentifier
        self.taskRunUUID = taskRunUUID
        super.init(identifier: identifier, startDate: startDate, endDate: endDate, stepHistory: stepHistory, asyncResults: asyncResults, path: path)
    }

    /// Initialize from a `Decoder`. This decoding method will use the ``SerializationFactory`` instance associated
    /// with the decoder to decode the `stepHistory` and `asyncResults`.
    ///
    /// - parameter decoder: The decoder to use to decode this instance.
    /// - throws: `DecodingError`
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.taskRunUUID = try container.decode(UUID.self, forKey: .taskRunUUID)
        self.versionString = try container.decodeIfPresent(String.self, forKey: .versionString)
        self.assessmentIdentifier = try container.decodeIfPresent(String.self, forKey: .assessmentIdentifier)
        self.schemaIdentifier = try container.decodeIfPresent(String.self, forKey: .schemaIdentifier)
        try super.init(from: decoder)
    }

    /// Encode the result to the given encoder.
    /// - parameter encoder: The encoder to use to encode this instance.
    /// - throws: `EncodingError`
    override open func encode(to encoder: Encoder) throws {
        try super.encode(to: encoder)
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(taskRunUUID, forKey: .taskRunUUID)
        try container.encodeIfPresent(self.assessmentIdentifier, forKey: .assessmentIdentifier)
        try container.encodeIfPresent(self.schemaIdentifier, forKey: .schemaIdentifier)
        try container.encodeIfPresent(self.versionString, forKey: .versionString)
        if let root = self as? DocumentableRootObject {
            try container.encodeIfPresent(root.jsonSchema, forKey: .jsonSchema)
        }
    }
    
    override open class func codingKeys() -> [CodingKey] {
        var keys = super.codingKeys()
        keys.append(contentsOf: CodingKeys.allCases)
        return keys
    }

    override open class func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else {
            return super.isRequired(codingKey)
        }
        return key == .taskRunUUID
    }

    override open class func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            return try super.documentProperty(for: codingKey)
        }
        switch key {
        case .assessmentIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
            """
            An identifier for the assessment model associated with this result. If included, this
            is intended to match the identifier used by the services that requested running the
            assessment. This could be a schedule identifier or an identifier in a different namespace
            than the "task identifier" used by the assessment developers to identify their assessments.
            """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n"))
        case .schemaIdentifier:
            return .init(propertyType: .primitive(.string), propertyDescription:
            "An identifier that can be used either by the developer or researcher for custom mapping.")
        case .versionString:
            return .init(propertyType: .primitive(.string), propertyDescription:
            "The versioning key used by the developer to version this assessment.")
        case .taskRunUUID:
            return .init(propertyType: .primitive(.string), propertyDescription:
            """
            A unique identifier for this run of the assessment. This property is defined as readwrite
            to allow the controller for the task to set this on the ``AssessmentResult`` children
            included in this run.
            """.replacingOccurrences(of: "\n", with: " ").replacingOccurrences(of: "  ", with: "\n"))
        case .jsonSchema:
            return .init(propertyType: .format(.uri), propertyDescription: "The json schema URI for this result.")
        }
    }
}

/// ``AssessmentResultObject`` is a result associated with a task. This object includes a step history,
/// task run UUID,  and asynchronous results.
public final class AssessmentResultObject : AbstractAssessmentResultObject, SerializableResultData, AssessmentResult {
    
    public override class func defaultType() -> SerializableResultType {
        .StandardTypes.assessment.resultType
    }
    
    public func deepCopy() -> AssessmentResultObject {
        let copy = AssessmentResultObject(identifier: self.identifier,
                                          versionString: self.versionString,
                                          assessmentIdentifier: self.assessmentIdentifier,
                                          schemaIdentifier: self.schemaIdentifier)
        copy.startDateTime = self.startDateTime
        copy.endDateTime = self.endDateTime
        copy.taskRunUUID = self.taskRunUUID
        copy.stepHistory = self.stepHistory.map { $0.deepCopy() }
        copy.asyncResults = self.asyncResults?.map { $0.deepCopy() }
        copy.path = self.path
        return copy
    }
}

extension AssessmentResultObject : DocumentableRootObject {

    public convenience init() {
        self.init(identifier: "example")
    }

    public var jsonSchema: URL {
        URL(string: "\(self.className).json", relativeTo: kBDHJsonSchemaBaseURL)!
    }

    public var documentDescription: String? {
        "A top-level result for this assessment."
    }
}

extension AssessmentResultObject : DocumentableStruct {

    public static func examples() -> [AssessmentResultObject] {

        let result = AssessmentResultObject(identifier: "example")

        var introStepResult = ResultObject(identifier: "introduction")
        introStepResult.startDateTime = ISO8601TimestampFormatter.date(from: "2017-10-16T22:28:09.000-07:00")!
        introStepResult.endDateTime = introStepResult.startDateTime.addingTimeInterval(20)
        
        let collectionResult = CollectionResultObject.examples().first!
        collectionResult.startDateTime = introStepResult.endDateTime!
        collectionResult.endDateTime = collectionResult.startDateTime.addingTimeInterval(2 * 60)
        
        var conclusionStepResult = ResultObject(identifier: "conclusion")
        conclusionStepResult.startDateTime = collectionResult.endDateTime!
        conclusionStepResult.endDateTime = conclusionStepResult.startDateTime.addingTimeInterval(20)

        var fileResult = FileResultObject.examples().first!
        fileResult.startDateTime = collectionResult.startDateTime
        fileResult.endDateTime = collectionResult.endDateTime
        
        result.stepHistory = [introStepResult, collectionResult, conclusionStepResult]
        result.asyncResults = [fileResult]

        result.startDateTime = introStepResult.startDateTime
        result.endDateTime = conclusionStepResult.endDateTime
        result.path = [
            .init(identifier: "introduction", direction: .forward),
            .init(identifier: collectionResult.identifier, direction: .forward),
            .init(identifier: "conclusion", direction: .forward)
        ]

        return [result]
    }
}

