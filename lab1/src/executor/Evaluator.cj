package cjcj.executor

import cjcj.visitor.*
import cjcj.scanner.TokenKind
import cjcj.scanner.Token
import std.convert.*
import std.collection.ArrayList

class Lab1TodoException <: Exception {
    public init(message: String) {
        super("Lab 1 TODO: " + message)
    }
}

private class BreakSignal <: Exception {}

private class ContinueSignal <: Exception {}

/** 
 * Evaluator Visitor
 *
 * Lab1 TODO: We have given the simplest form, each `Node` will return a `Value` after evaluation.
 * But is this sufficient? Do you need to add something new to handle ASTs that don't return a value?
 *
 * You may need to modify the member variables and/or generic parameters of the Evaluator class.
 */
public open class Evaluator <: Visitor<Value> {
    // How do you get and set the context when executing an expression?
    // You might need to add some member variables to do this.
    // 当前的静态作用域
    private var context = Environment<String, Binding>()  
    // 全部的静态作用域
    private var static_scope = ArrayList<Environment<String, Binding>>()
    // 当前所处循环的层数，处理 break / continue 的合法性
    private var loopDepth: Int64 = 0

    public init() {
        static_scope.add(context)
    }

    public open override func visit(_: Program): Value {
        
        throw UnsupportedException("Unimplemented method for Visitor : Program")
    }

    // This is just an example of how to implement the visit method for BinaryExpr.
    // You may need to modify, split, or completely rewrite it depending on your design.
    public open override func visit(expr: BinaryExpr): Value {
        let left = expr.left.traverse(this)
        let right = expr.right.traverse(this)

        try {
            match (expr.oper.kind) {
                case TokenKind.ADD => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a + b)
                    case (VString(a), VString(b)) => Value.from(a + b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.ADD_TYPE_MISMATCH,
                        "cannot add left = ${left}, right = ${right}", expr)
                }
                case TokenKind.SUB => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a - b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.SUB_TYPE_MISMATCH,
                        "cannot subtract left = ${left}, right = ${right}", expr)
                }
                case TokenKind.MUL => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a * b)
                    case (VString(a), VInteger(b)) => Value.from(a * b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.MUL_TYPE_MISMATCH,
                        "cannot multiply left = ${left}, right = ${right}", expr)
                }       
                case TokenKind.DIV => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) =>
                        if (b == 0) {
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.DIV_BY_ZERO,
                                "divide by zero: left = ${left}, right = ${right}", expr)
                        }
                        Value.from(a / b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.DIV_TYPE_MISMATCH,
                        "cannot divide left = ${left}, right = ${right}", expr)
                }
                case TokenKind.MOD => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) =>
                        if (b == 0) {
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.MOD_BY_ZERO,
                                "modulo by zero: left = ${left}, right = ${right}", expr)
                        }
                        Value.from(a % b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.MOD_TYPE_MISMATCH,
                        "cannot modulo left = ${left}, right = ${right}", expr)
                }
                case TokenKind.EXP => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) =>
                        if (b < 0) {
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.EXP_NEGATIVE_POWER,
                                "negative exponent: left = ${left}, right = ${right}", expr)
                        }
                        Value.from(a ** UInt64(b))
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.EXP_TYPE_MISMATCH,
                        "cannot exponentiate left = ${left}, right = ${right}", expr)
                }
                case TokenKind.GT => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a > b)
                    case (VString(a), VString(b)) => Value.from(a > b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CMP_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }
                case TokenKind.LT => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a < b)
                    case (VString(a), VString(b)) => Value.from(a < b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CMP_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }
                case TokenKind.GE => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a >= b)
                    case (VString(a), VString(b)) => Value.from(a >= b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CMP_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }
                case TokenKind.LE => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a <= b)
                    case (VString(a), VString(b)) => Value.from(a <= b)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.CMP_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }   
                case TokenKind.EQUAL => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a == b)
                    case (VString(a), VString(b)) => Value.from(a == b)
                    case (VBoolean(a), VBoolean(b)) => Value.from(a == b)
                    case (VUnit, VUnit) => Value.from(true)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.EQ_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }
                case TokenKind.NOTEQ => match ((left, right)) {
                    case (VInteger(a), VInteger(b)) => Value.from(a != b)
                    case (VString(a), VString(b)) => Value.from(a != b)
                    case (VBoolean(a), VBoolean(b)) => Value.from(a != b)
                    case (VUnit, VUnit) => Value.from(false)
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.NEQ_TYPE_MISMATCH,
                        "cannot compare left = ${left}, right = ${right}", expr)
                }
                case TokenKind.AND => match ((left, right)) {
                    // 左边必须是布尔；右边接受任意 Value 并按 "truthiness" 规则转换为布尔
                    case (VBoolean(a), _) =>
                        if (!a) {
                            return Value.from(false)
                        } else {
                            match (right) {
                                case VBoolean(b) => Value.from(b)
                                case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.AND_TYPE_MISMATCH,
                                    "cannot AND left = ${left}, right = ${right}", expr)
                            }
                        }
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.AND_TYPE_MISMATCH,
                        "cannot AND left = ${left}, right = ${right}", expr)
                }
                case TokenKind.OR => match ((left, right)) {
                    // 左边必须是布尔；右边接受任意 Value 并按 "truthiness" 规则转换为布尔
                    case (VBoolean(a), _) =>
                        if (a) {
                            return Value.from(true)
                        } else {
                            match (right) {
                                case VBoolean(b) => Value.from(b)
                                case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.OR_TYPE_MISMATCH,
                                    "cannot OR left = ${left}, right = ${right}", expr)
                            }
                        }
                    case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.OR_TYPE_MISMATCH,
                        "cannot OR left = ${left}, right = ${right}", expr)
                }
                case _ => throw Lab1TodoException("Unimplemented Binary Operator `${expr.oper.kind}`")
            }
        } catch (e: OverflowException) {
            match (e.message) {
                case "add" => throw CjcjRuntimeErrorWithLocation(ErrorCode.ADD_OVERFLOW,
                    "overflow add: left = ${left}, right = ${right}", expr)
                case "sub" => throw CjcjRuntimeErrorWithLocation(ErrorCode.SUB_OVERFLOW,
                    "overflow sub: left = ${left}, right = ${right}", expr)
                case "mul" => throw CjcjRuntimeErrorWithLocation(ErrorCode.MUL_OVERFLOW,
                    "overflow mul: left = ${left}, right = ${right}", expr)
                case "exp" => throw CjcjRuntimeErrorWithLocation(ErrorCode.EXP_OVERFLOW,
                    "overflow exp: left = ${left}, right = ${right}", expr)
                case _ => throw Lab1TodoException("You need to handle overflow of ${e.message}")
            }
        }
    }

    public open override func visit(expr: UnaryExpr): Value {
        let value = expr.right.traverse(this)   

        try {
            match (expr.oper.kind) {
                case TokenKind.SUB => 
                    match (value) {
                        case VInteger(a) => return Value.from(-a)
                        case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.NEG_TYPE_MISMATCH,
                            "cannot negate value = ${value}", expr)
                    }
                case TokenKind.NOT => 
                    match (value) {
                        case VBoolean(a) => return Value.from(!a)
                        case _ => throw CjcjRuntimeErrorWithLocation(ErrorCode.NOT_TYPE_MISMATCH,
                            "cannot NOT value = ${value}", expr)
                    }
                case _ => throw Lab1TodoException("Unimplemented Unary Operator `${expr.oper.kind}`")
            }
        } catch (e: OverflowException) {
            match (e.message) {
                case "neg" => throw CjcjRuntimeErrorWithLocation(ErrorCode.NEG_OVERFLOW,
                    "overflow negation: value = ${value}", expr)
                case _ => throw Lab1TodoException("You need to handle overflow of ${e.message}")
            }
        }

        throw Lab1TodoException("Unary Expression Evaluation Not Implemented")
    }

    public open override func visit(par: ParenExpr): Value {
        return par.parenthesizedExpr.traverse(this)

        throw Lab1TodoException("Parenthesized Expression Evaluation Not Implemented")
    }

    public open override func visit(lit: LitConstExpr): Value {
        match (lit.literal.kind) {
            case TokenKind.INTEGER_LITERAL => Value.from(Int64.parse(lit.literal.value))
            case TokenKind.STRING_LITERAL => Value.from(lit.literal.value)
            case TokenKind.BOOL_LITERAL => Value.from(Bool.parse(lit.literal.value))      
            case TokenKind.UNIT_LITERAL => Value.VUnit
            case _ => throw Lab1TodoException("There are more literal types to implement")
        }
    }

    public open override func visit(expr: AssignExpr): Value {
        let value = expr.right.traverse(this)
        // 试图读取未初始化的变量
        if (isUnit(value)) {
            throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR,
                "try to visit unassigned variable", expr)
        }

        if (let Some(refExpr) <- (expr.left as RefExpr)) {
            let name = refExpr.identifier.value

            match (context.getGlobal(name)) {
                case None =>
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR,
                        "assign to undefined variable `${name}`", expr)
                case Some(binding) =>
                    match (binding) {
                        case Binding.VAR_Initialized(previous) =>
                            if (!isSameValueType(previous, value)) {
                                throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                    "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                            } else {
                                setValueInContext(name, Binding.VAR_Initialized(value))
                            }
                        case Binding.VAR_Uninitialized(previous) =>
                        //查看是否定义类型
                            match (previous) {
                                case VInteger(_) =>
                                    if (!isSameValueType(Value.VInteger(0), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VString(_) =>
                                    if (!isSameValueType(Value.VString(""), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VBoolean(_) =>
                                    if (!isSameValueType(Value.VBoolean(false), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VUnit =>
                                    if (!isSameValueType(Value.VUnit, value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                            }
                            setValueInContext(name, Binding.VAR_Initialized(value))
                        case Binding.LET_Initialized(Value) =>
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSGIN_IMMUT_VAR,
                                "cannot assign to constant variable `${name}`", expr)
                        case Binding.LET_Uninitialized(previous) =>
                        // 查看是否定义类型
                            match (previous) {
                                case VInteger(_) =>
                                    if (!isSameValueType(Value.VInteger(0), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VString(_) =>
                                    if (!isSameValueType(Value.VString(""), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VBoolean(_) =>
                                    if (!isSameValueType(Value.VBoolean(false), value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                                case VUnit =>
                                    if (!isSameValueType(Value.VUnit, value)) {
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
                                            "type mismatch: cannot assign ${value.toValueString()} to `${name}`", expr)
                                    }
                            }
                            setValueInContext(name, Binding.LET_Initialized(value))
                    }
    
                return Value.VUnit
            }
        }
        throw CjcjRuntimeErrorWithLocation(ErrorCode.ASSIGN_TYPE_MISMATCH,
            "left-hand side of assignment must be a variable reference",expr)
    }

    public open override func visit(ref: RefExpr): Value {
        let name = ref.identifier.value
        match (context.getGlobal(name)) {
            case None =>
                throw CjcjRuntimeErrorWithLocation(ErrorCode.UNDEFINED_VAR,
                    "try to visit undefined variable `${name}`", ref)
            case Some(binding) =>
                match (binding) {
                    // 这里逻辑比较难理解，到这步的已经是访问值的情况了
                    case Binding.VAR_Uninitialized(value) =>
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.UNINITIALIZED_VAR,
                            "try to read uninitialized variable `${name}`", ref)
                    case Binding.LET_Uninitialized(value) =>
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.UNINITIALIZED_VAR,
                            "try to read uninitialized constant variable `${name}`", ref)
                    case Binding.VAR_Initialized(value) =>
                        return value
                    case Binding.LET_Initialized(value) =>
                        return value
                }
        }
    }

    public open override func visit(block: Block): Value {
        var ret = Value.VUnit
        for (stmt in block.nodes.iterator()) {
            ret = stmt.traverse(this)
        }
        return ret
    }

    public open override func visit(expr: IfExpr): Value {
        let cond = expr.condition.traverse(this)

        if (isDefaultElseBranch(expr.elseBranch)) {
            match (cond) {
                case VBoolean(b) =>
                    if (b) {
                        var new_scope = Environment<String, Binding>(Some(context))
                        static_scope.add(new_scope)
                        context = new_scope
                        expr.ifBlock.traverse(this)
                        // 恢复上下文
                        if (let Some(enclosing) <- new_scope.enclosing) {
                            context = enclosing
                        }
                    }
                    return Value.VUnit
                case _ =>
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.IF_TYPE_MISMATCH,
                        "if condition must be boolean, got ${cond.toValueString()}", expr)
            }
        }
        else {
            match (cond) {
                case VBoolean(b) =>
                    if (b) {
                        var new_scope = Environment<String, Binding>(Some(context))
                        static_scope.add(new_scope)
                        context = new_scope
                        let result = expr.ifBlock.traverse(this)
                        // 恢复上下文
                        if (let Some(enclosing) <- new_scope.enclosing) {
                            context = enclosing
                        }
                        return result
                    }
                    else {
                        var new_scope = Environment<String, Binding>(Some(context))
                        static_scope.add(new_scope)
                        context = new_scope
                        let result = expr.elseBranch.traverse(this)
                        // 恢复上下文
                        if (let Some(enclosing) <- new_scope.enclosing) {
                            context = enclosing
                        }
                        return result
                    }
                case _ =>
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.IF_TYPE_MISMATCH,
                        "if condition must be boolean, got ${cond.toValueString()}", expr)
            }
        }
    }

    public open override func visit(expr: WhileExpr): Value {
        var cond = expr.condition.traverse(this)

        match (cond) {
            case VBoolean(b) =>
                loopDepth += 1
                var check = b
                while (check) {
                    // 新建作用域
                    var new_scope = Environment<String, Binding>(Some(context))
                    static_scope.add(new_scope)
                    context = new_scope
                    var breaking = false
                    try {
                        expr.block.traverse(this)
                    } catch (_: BreakSignal) {
                        breaking = true
                    } catch (_: ContinueSignal) {
                        // continue to next iteration
                    } catch (e: Exception) {
                        if (let Some(enclosing) <- new_scope.enclosing) {
                            context = enclosing
                        }
                        loopDepth -= 1
                        throw e
                    }
                    // 恢复上下文
                    if (let Some(enclosing) <- new_scope.enclosing) {
                        context = enclosing
                    }

                    if (breaking) {
                        loopDepth -= 1
                        return Value.VUnit
                    }

                    cond = expr.condition.traverse(this)

                    match (cond) {
                        case VBoolean(nCheck) => check = nCheck
                        case _ =>
                            loopDepth -= 1
                            throw CjcjRuntimeErrorWithLocation(ErrorCode.WHILE_TYPE_MISMATCH,
                                "while condition must be boolean, got ${cond.toValueString()}", expr)
                    }
                }
                loopDepth -= 1
                return Value.VUnit
            case _ =>
                throw CjcjRuntimeErrorWithLocation(ErrorCode.WHILE_TYPE_MISMATCH,
                    "while condition must be boolean, got ${cond.toValueString()}", expr)
        }

        return Value.VUnit
    }

    public open override func visit(call: CallExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call Expression")
    }

    public open override func visit(_: ReturnExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Return Expression")
    }

    public open override func visit(jmp: JumpExpr): Value {
        let kind = jmp.keyword.kind
        match (kind) {
            case TokenKind.BREAK =>
                if (loopDepth == 0) {
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.BREAK_OUTSIDE_LOOP,
                        "break statement not within a loop", jmp)
                }
                throw BreakSignal()
            case TokenKind.CONTINUE =>
                if (loopDepth == 0) {
                    throw CjcjRuntimeErrorWithLocation(ErrorCode.CONTINUE_OUTSIDE_LOOP,
                        "continue statement not within a loop", jmp)
                }
                throw ContinueSignal()
            case _ =>
                throw Lab1TodoException("UnSupported jump kind `${kind}`")
        }

        throw Lab1TodoException("Jump Expression Evaluation Not Implemented")
    }

    public open override func visit(decl: VarDecl): Value {
        // decl.keyword_.kind  //VAR or LET    
        // decl.identifier_.kind   //IDENTIFIER always
        // decl.declType   //TypeNode or None
        // decl.initializer    //Expr or None

        let name = decl.identifier.value
        let isLet = (decl.keyword.kind == TokenKind.LET)

        match (decl.initializer) {
            // 有初始值：计算右值并直接初始化
            case Some(initExpr) =>
                let v = initExpr.traverse(this)
                if (isLet) {
                    // let 带初始值
                    // 重复定义
                    if (context.getLocal(name).isSome()) {
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF,
                            "redeclared variable `${name}`", decl)
                    }
                    else {
                        match (decl.declType) {
                            case Some(typeNode) =>
                                // 有类型标注，检查类型是否匹配
                                if (!isSameTypeAnnotationAndValue(typeNode, v)) {
                                    throw CjcjRuntimeErrorWithLocation(ErrorCode.DEF_TYPE_MISMATCH,
                                        "type annotation does not match initializer for `${name}`", decl)
                                }
                                context.declare(name, Binding.LET_Initialized(v))
                            case None =>
                                // 无类型标注，直接初始化
                                context.declare(name, Binding.LET_Initialized(v))
                            }
                        }   
                } else {
                    // var 带初始值
                    // 重复定义
                    if (context.getLocal(name).isSome()) {
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF,
                            "redeclared variable `${name}`", decl)
                    }
                    else {
                        match (decl.declType) {
                            case Some(typeNode) =>
                                // 有类型标注，检查类型是否匹配
                                if (!isSameTypeAnnotationAndValue(typeNode, v)) {
                                    throw CjcjRuntimeErrorWithLocation(ErrorCode.DEF_TYPE_MISMATCH,
                                        "type annotation does not match initializer for `${name}`", decl)
                                }
                                context.declare(name, Binding.VAR_Initialized(v))
                            case None =>
                                // 无类型标注，直接初始化
                                context.declare(name, Binding.VAR_Initialized(v))
                        }
                    }
                }
            // 无初始值：根据关键字与类型标注处理
            case None =>
                if (isLet) {
                    if (context.getLocal(name).isSome()) {
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF,
                            "redeclared variable `${name}`", decl)
                    } else {
                        match (decl.declType) {
                            case Some(typeNode) =>
                                match (getAnnotatedTypeName(typeNode)) {
                                    case "Int64" => context.declare(name, Binding.LET_Uninitialized(Value.VInteger(0)))
                                    case "String" => context.declare(name, Binding.LET_Uninitialized(Value.VString("")))
                                    case "Bool" => context.declare(name, Binding.LET_Uninitialized(Value.VBoolean(false)))
                                    case "Unit" => context.declare(name, Binding.LET_Uninitialized(Value.VUnit))
                                    case _ =>
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DEF_TYPE_MISMATCH,
                                            "unsupported type annotation for uninitialized constant `${name}`", decl)
                                }
                            case None =>
                                context.declare(name, Binding.LET_Uninitialized(Value.VUnit))
                        }
                    }
                } else {
                    if (context.getLocal(name).isSome()) {
                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DUPLICATED_DEF,
                            "redeclared variable `${name}`", decl)
                    } else {
                        match (decl.declType) {
                            case Some(typeNode) =>
                                match (getAnnotatedTypeName(typeNode)) {
                                    // Uninitialized variable 默认值设为对应类型的“零值”
                                    case "Int64" => context.declare(name, Binding.VAR_Uninitialized(Value.VInteger(0)))
                                    case "String" => context.declare(name, Binding.VAR_Uninitialized(Value.VString("")))
                                    case "Bool" => context.declare(name, Binding.VAR_Uninitialized(Value.VBoolean(false)))
                                    case "Unit" => context.declare(name, Binding.VAR_Uninitialized(Value.VUnit))
                                    case _ =>
                                        throw CjcjRuntimeErrorWithLocation(ErrorCode.DEF_TYPE_MISMATCH,
                                            "unsupported type annotation for uninitialized constant `${name}`", decl)
                                }
                            case None =>
                                context.declare(name, Binding.VAR_Uninitialized(Value.VUnit))
                        }
                    }
                }
        }
        return Value.VUnit
        throw Lab1TodoException("Variable Declaration Evaluation Not Implemented")
    }


    public open override func visit(_: FuncParam): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Paramters")
    }

    public open override func visit(_: FuncDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Declaration")
    }

    public open override func visit(_: MainDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Main Declaration")
    }

    public open override func visit(_: ClassDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Declaration")
    }

    public open override func visit(_: Body): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Body")
    }

    public open override func visit(arg: Argument): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Argument")
    }

    public open override func visit(_: TypeNode): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Type Node")
    }

    public open override func visit(_: PrimitiveType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive Types")
    }

    public open override func visit(_: RefType): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference Type")
    }

    public open override func visit(_: VariableReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Variable Reference (ASG)")
    }

    public open override func visit(_: FuncReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Function Reference (ASG)")
    }

    public open override func visit(_: ClassReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Class Reference (ASG)")
    }

    public open override func visit(_: VarDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Variable Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: FuncDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Function Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MainDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Main Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: ClassDeclWithRef): Value {
        throw UnsupportedException(
            "Unimplemented method for Visitor : Class Declaration with" + "References Stored (ASG)")
    }

    public open override func visit(_: MemberAccess): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member Access")
    }

    public open override func visit(_: PrimitiveTypeExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Primitive type expression")
    }

    public open override func visit(_: RefExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Reference expression with reference")
    }

    public open override func visit(_: ThisSuperExpr): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super expression")
    }

    public open override func visit(_: ThisSuperReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : This Super reference")
    }

    public open override func visit(_: CallExprWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Call expression with reference")
    }

    public open override func visit(_: MemberAccessWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Member access with reference")
    }

    public open override func visit(_: InterfaceDecl): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration")
    }

    public open override func visit(_: InterfaceDeclWithRef): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Declaration with reference")
    }

    public open override func visit(_: InterfaceReference): Value {
        throw UnsupportedException("Unimplemented method for Visitor : Interface Reference")
    }

    private func isDefaultElseBranch(branch: Expr): Bool {
        if (let Some(block) <- (branch as Block)) {
            let blockNodes = block.nodes
            if (blockNodes.size == 1) {
                let firstNode = blockNodes[0]
                if (let Some(literal) <- (firstNode as LitConstExpr)) {
                    return literal.literal.kind == TokenKind.UNIT_LITERAL
                }
            }
        }
        false
    }

    private func isSameValueType(lhs: Value, rhs: Value): Bool {
        match ((lhs, rhs)) {
            case (VInteger(_), VInteger(_)) => true
            case (VString(_), VString(_)) => true
            case (VBoolean(_), VBoolean(_)) => true
            case (VUnit, VUnit) => true
            case _ => false
        }
    }

    private func isUnit(value: Value): Bool {
        match (value) {
            case VUnit => true
            case _ => false
        }
    }

    private func setValueInContext(name: String, binding: Binding): Bool {
        var env = context
        while (true) {
            if (env.elements.contains(name)) {
                env.elements.remove(name)
                env.elements.add(name, binding)
                return true
            }
            env = match (env.enclosing) {
                case None => return false
                case Some(e) => e
            }
        }
        false
    }

    private func isSameTypeAnnotationAndValue(typeNode: TypeNode, value: Value): Bool {
        // 原生类型：Bool、Unit、各数值类型(Int8/16/32/64/…)
        if (let Some(p) <- (typeNode as PrimitiveType)) {
            let tk = p.typeName.kind
            match (value) {
                // 本运行时只有 VInteger(Int64)，把所有“数值型”都视为可接受
                case VInteger(_) =>
                    tk == TokenKind.INT64
                case VBoolean(_) =>
                    tk == TokenKind.BOOLEAN
                case VUnit =>
                    tk == TokenKind.UNIT
                case VString(_) =>
                    false
            }
        // 引用类型：这里处理 String
        } else if (let Some(r) <- (typeNode as RefType)) {
            let tn = r.typeName.value
            match (value) {
                case VString(_) => tn == "String"
                case _ => false
            }
        } else {
            false
        }
    }
    
    private func getAnnotatedTypeName(typeNode: TypeNode): String {
        // 原生类型：Bool、Unit、各数值类型(Int8/16/32/64/…)
        if (let Some(p) <- (typeNode as PrimitiveType)) {
            let tk = p.typeName.kind
            match (tk) {
                case TokenKind.INT8 => "Int8"
                case TokenKind.INT16 => "Int16"
                case TokenKind.INT32 => "Int32"
                case TokenKind.INT64 => "Int64"
                case TokenKind.BOOLEAN => "Bool"
                case TokenKind.UNIT => "Unit"
                case _ => "UnknownPrimitiveType"
            }
        // 引用类型：这里处理 String
        } else if (let Some(r) <- (typeNode as RefType)) {
            let tn = r.typeName.value
            match (tn) {
                case "String" => "String"
                case _ => "UnknownRefType"
            }
        } else {
            "UnknownType"
        }
    }
}
