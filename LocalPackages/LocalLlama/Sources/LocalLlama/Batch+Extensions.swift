import Foundation
import llama

extension Batch {
    mutating func clear() {
        n_tokens = 0
    }

    mutating func add(token: Token,
                      position: Position,
                      seqIDs: [SeqID],
                      logit: Bool)
    {
        let nextIndex = Int(n_tokens)
        self.token[nextIndex] = token
        pos[nextIndex] = position
        n_seq_id[nextIndex] = Int32(seqIDs.count)
        for (index, id) in seqIDs.enumerated() {
            seq_id[nextIndex]?[index] = id
        }
        logits[nextIndex] = logit ? 1 : 0
        n_tokens += 1
    }
}
