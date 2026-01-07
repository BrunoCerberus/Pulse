import Foundation
@_exported import llama

public typealias Batch = llama_batch
public typealias Model = OpaquePointer
public typealias Context = OpaquePointer
public typealias Token = llama_token
public typealias Position = llama_pos
public typealias SeqID = llama_seq_id
public typealias ContextParameters = llama_context_params
