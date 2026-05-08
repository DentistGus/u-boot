/**
 * @kind path-problem
 */

import cpp
import semmle.code.cpp.dataflow.TaintTracking

class NetworkByteSwap extends Expr {
    NetworkByteSwap () {
    exists(MacroInvocation m |
        m.getMacroName() in ["ntohl", "ntohll", "ntohs"]
        and this = m.getExpr()
    )
    }
}

module MyConfig implements DataFlow::ConfigSig {

  predicate isSource(DataFlow::Node source) {
    source.asExpr() instanceof NetworkByteSwap
  }
  predicate isSink(DataFlow::Node sink) {
    exists(FunctionCall f |
      f.getTarget().hasName("memcpy") and 
      sink.asExpr() = f.getArgument(2)
    )
  }

  predicate isBarrier(DataFlow::Node barrier){
    exists(IfStmt ifs | 
      barrier.asExpr().getBasicBlock() = ifs
    )
  }
}

module MyTaint = TaintTracking::Global<MyConfig>;
import MyTaint::PathGraph

from MyTaint::PathNode source, MyTaint::PathNode sink
where MyTaint::flowPath(source, sink) 
select sink, source, sink, "Network byte swap flows to memcpy"