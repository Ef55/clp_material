case Times(lhs, rhs) => IntValue(
  interpret(lhs).asInt * 
  interpret(rhs).asInt
)