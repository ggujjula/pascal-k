module PASCAL-STRING-SYNTAX
	syntax lexical Letter = r"([a-z]|[A-Z])"
	syntax lexical Digit = r"([0-9])"
	syntax lexical StringElement = r"(\\\"|({Letter})|({Digit}))"
	syntax String ::= r"'(({StringElement})+)'" [token]
endmodule

module PASCAL-SYNTAX-COMMON
	imports UNSIGNED-INT-SYNTAX
	imports ID-SYNTAX
	imports BOOL-SYNTAX
	imports PASCAL-STRING-SYNTAX
	imports LIST

syntax Directive ::= Id

syntax Program ::= ProgramHeading ";" ProgramBlock "."
syntax ProgramHeading ::= "program" Id
			|"program" Id "(" ProgramParameterList ")"
syntax ProgramParameterList ::= Ids
syntax ProgramBlock ::= Block

syntax Block ::= LabelPart
syntax LabelPart ::= "label" Labels ";" ConstantPart
		| ConstantPart
syntax ConstantPart ::= "const" ConstantDefinitions ";" TypePart
			| TypePart
syntax TypePart ::= "type" TypeDefinitions ";" VariablePart
			| VariablePart
syntax VariablePart ::= "var" VariableDeclarations ";" ProcedureAndFunctionPart
			| ProcedureAndFunctionPart
syntax ProcedureAndFunctionPart ::= ProcedureAndFunctions ";" CompoundStatement
				| CompoundStatement


syntax TypeDefinitions ::= List{TypeDefinition, ";"}
syntax TypeDefinition ::= Id "=" TypeDenoter [seqstrict(2)]
syntax TypeDenoter ::= TypeIdentifier
			| NewType
syntax NewType ::= NewOrdinalType | NewStructuredType | NewPointerType
syntax SimpleTypeIdentifier ::= TypeIdentifier
syntax StructuredTypeIdentifier ::= TypeIdentifier
syntax PointerTypeIdentifier ::= TypeIdentifier
syntax TypeIdentifier ::= Id

syntax SimpleType ::= OrdinalType | RealTypeIdentifier
syntax OrdinalType ::= NewOrdinalType | OrdinalTypeIdentifier
syntax NewOrdinalType ::= EnumeratedType | SubrangeType
syntax OrdinalTypeIdentifier ::= TypeIdentifier
syntax RealTypeIdentifier ::= TypeIdentifier
syntax EnumeratedType ::= "(" Ids ")"
syntax SubrangeType ::= Constant ".." Constant [seqstrict]
syntax StructuredType ::= NewStructuredType | StructuredTypeIdentifier
syntax NewStructuredType ::= UnpackedStructuredType
			| "packed" UnpackedStructuredType
syntax UnpackedStructuredType ::= ArrayType | RecordType | SetType | FileType

syntax ArrayType ::= "array" "[" IndexTypes "]" "of" ComponentType [seqstrict]
syntax IndexTypes ::= List{IndexType, ","} [seqstrict]
syntax IndexType ::= OrdinalType
syntax ComponentType ::= TypeDenoter

syntax RecordType ::= "record" FieldList "end"
syntax RecordType ::= "record" "end"
syntax FieldList ::= 	  FixedPart
			| FixedPart ";"
			| FixedPart ";" VariantPart [seqstrict]
			| FixedPart ";" VariantPart ";" [seqstrict]
			| VariantPart
			| VariantPart ";"
syntax FixedPart ::= List{RecordSection, ";"} [seqstrict]
syntax RecordSection ::= Ids ":" TypeDenoter [seqstrict(2), symbol(recordSection)]
syntax FieldIdentifier ::= Id
syntax VariantPart ::= "case" VariantSelector "of" Variants
syntax Variants ::= List{Variant, ";"}
syntax VariantSelector ::= TagField ":" TagType [seqstrict(2)] 
			| TagType
syntax TagField ::= Id
syntax Variant ::= CaseConstantList ":" "(" FieldList ")" [seqstrict]
syntax TagType ::= OrdinalTypeIdentifier
syntax CaseConstantList ::= List{CaseConstant, ","} [seqstrict]
syntax CaseConstant ::= Constant

syntax SetType ::= "set" "of" BaseType [seqstrict]
syntax BaseType ::= OrdinalType

syntax FileType ::= "file" "of" ComponentType [seqstrict]

syntax PointerType ::= NewPointerType | PointerTypeIdentifier
syntax NewPointerType ::= "^" DomainType
syntax DomainType ::= TypeIdentifier

syntax ProcedureAndFunctions ::= List{ProcedureOrFunction, ""}

syntax ProcedureOrFunction ::= ProcedureDeclaration
				| FunctionDeclaration
syntax ProcedureDeclaration ::= ProcedureHeading ";" Directive
				| ProcedureHeading ";" ProcedureBlock
//NOTE: There is a grammar ambiguity in the standard!
//If no params are given, a definition of a forward declared function
//and a definition of a fresh function look identical. However, the
//standard states that the former be parsed as a ProcedureIdentification,
//while the latter be parsed as a ProcedureHeading. This is not possible
//without walking a symbol table to find previously forward declared functions.
//We can't do that here!
//As a workaround, we only use ProcedureHeading, and define semantic rules to
//disallow param lists for definitions of forward declared functions.
//				| ProcedureIdentification ";" ProcedureBlock
//
syntax ProcedureHeading ::= "procedure" Id
			| "procedure" Id FormalParameterList
syntax ProcedureIdentification ::= "procedure" ProcedureIdentifier
syntax ProcedureIdentifier ::= Id
syntax ProcedureBlock ::= Block

syntax FunctionDeclaration ::= FunctionHeading ";" Directive
				| FunctionIdentification ";" FunctionBlock
				| FunctionHeading ";" FunctionBlock
syntax FunctionHeading ::= "function" Id ":" ResultType
			| "function" Id FormalParameterList ":" ResultType
syntax FunctionIdentification ::= "function" FunctionIdentifier
syntax FunctionIdentifier ::= Id
syntax ResultType ::= SimpleTypeIdentifier
			| PointerTypeIdentifier
syntax FunctionBlock ::= Block

syntax FormalParameterList ::= "(" ")"
syntax FunctionDeclaration ::= Id

syntax Labels ::= List{Label, ","}
syntax Label ::= Int

syntax ConstantDefinitions ::= List{ConstantDefinition, ";"}
syntax ConstantDefinition ::= Id "=" Constant [seqstrict(2)]
syntax Constant ::= ConstantIdentifier
		| "+" ConstantIdentifier [seqstrict]
		| "-" ConstantIdentifier [seqstrict]
		| "+" Int [seqstrict]
		| "-" Int [seqstrict]
		| Int
		| String

syntax VariableDeclarations ::= List{VariableDeclaration, ";"}
syntax VariableDeclaration ::= Ids ":" TypeDenoter [seqstrict(2), symbol(variableDeclaration)]

syntax ConstantIdentifier ::= Id

syntax Ids ::= List{Id, ","}

syntax CompoundStatement ::= "begin" StatementSequence "end"

syntax StatementSequence ::= NeList{Statement, ";"}

syntax Expr ::= Int | Bool | String
		> Id
		> left: Expr "[" Expr "]" [seqstrict, symbol(exprArray)]
		> left: Expr "." Id [seqstrict]
		> left: "not" Expr
		> left: Expr "*" Expr [seqstrict]
		| Expr "/" Expr [seqstrict]
		| Expr "div" Expr [seqstrict]
		| Expr "mod" Expr [seqstrict]
		| Expr "and" Expr [seqstrict]
		> left: Expr "+" Expr [seqstrict]
		| Expr "-" Expr [seqstrict]
		| Expr "or" Expr [seqstrict]
		| "+" Expr [seqstrict]
		| "-" Expr [seqstrict]
		> left: Expr "=" Expr [seqstrict]
		| Expr "<>" Expr [seqstrict]
		| Expr "<" Expr [seqstrict]
		| Expr ">" Expr [seqstrict]
		| Expr "<=" Expr [seqstrict]
		| Expr ">=" Expr [seqstrict]
		> left: Id ":=" Expr [seqstrict(2)]
		> left: Expr ";" Expr

syntax Statement ::= SimpleStatement | StructuredStatement
syntax SimpleStatement ::= EmptyStatement
syntax EmptyStatement ::= ""

syntax StructuredStatement ::= CompoundStatement | RepetitiveStatement | ConditionalStatement

syntax ConditionalStatement ::= IfStatement
syntax IfStatement ::= "if" BooleanExpression "then" Statement [prefer, symbol(ifNoElse)]
			|"if" BooleanExpression "then" Statement "else" Statement [symbol(ifWithElse)]

syntax RepetitiveStatement ::= RepeatStatement | WhileStatement
syntax RepeatStatement ::= "repeat" StatementSequence "until" BooleanExpression

syntax BooleanExpression ::= Expr

syntax WhileStatement ::= "while" BooleanExpression "do" Statement

rule while B:BooleanExpression do S:Statement => if B then repeat S until not B
rule ifNoElse(B:BooleanExpression, S:Statement) => ifWithElse(B, S, begin end)
rule array [ I:IndexType , I2:IndexType, I3:IndexTypes ] of C:ComponentType => array [I] of array [I2, I3] of C

endmodule

module PASCAL-SYNTAX
	imports PASCAL-SYNTAX-COMMON


syntax lexical CommentStart = r"(\\{)"
syntax lexical CommentEnd = r"(\\})"
//syntax lexical CommentStart = r"(\\{|(\\(\\*))"
//syntax lexical CommentEnd = r"(\\}|(\\*\\)))"

syntax #Layout ::= r"({CommentStart}([^}]*){CommentEnd})"    // Semi-colon comments
                 | r"([\\ \\n\\r\\t])" // Whitespace

endmodule


