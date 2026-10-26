// addapted from https://wiki.redmodding.org/redscript/references-and-examples/logging#improve-logging 
// no author was listed, copyright attributed to wiki personell

module PerkAdditionFramework.Logging

// public func PAFLog(message : script_ref<String>) -> Void
// {
//   ModLog(n"PerkAdditionFramework", s"DEBUG: \(message)");
// }

public func PAFLogWarning(message: script_ref<String>) -> Void 
{
  ModLog(n"PerkAdditionFramework", s"WARNING: \(message)");
}

// public func PAFLogError(message: script_ref<String>) -> Void 
// {
//   ModLog(n"PerkAdditionFramework", s"ERROR: \(message)");
// }


