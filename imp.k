requires "syntax.k"

module IMP
	imports IMP-SYNTAX-COMMON
	imports INT
	imports BOOL
	imports ID
	imports MAP
	imports SET
	imports STRING
	imports K-EQUAL
	imports BASIC-K
	imports RANGEMAP

configuration
	<k> $PGM </k>
	<consts>
		SetItem(String2Id("false"))
		SetItem(String2Id("true"))
		SetItem(String2Id("maxint"))
	 </consts>
	<state>
		String2Id("integer") |-> Ordinal(0 -Int $MAXINT:Int, $MAXINT:Int)
		String2Id("real") |-> Simple()
		String2Id("Boolean") |-> Ordinal(0, 1)
		String2Id("char") |-> Ordinal(0, $MAXCHAR:Int)
		String2Id("false") |-> 0
		String2Id("true") |-> 1
		String2Id("maxint") |-> $MAXINT:Int
	 </state>
	<labels> .Set </labels>
	<procs> .Map </procs>
	<funcs> .Map </funcs>
	<meta> .Map </meta>
	<type-builder> .Map </type-builder>

syntax KItem ::= "undefined"
syntax OrdinalTypeSimpl ::= Ordinal(Int, Int)
syntax Type ::= OrdinalTypeSimpl
		| Simple()
syntax EnumBuilder ::= EBuilder(Ids, Int)
syntax TypeDenoter ::= Type
syntax OrdinalType ::= OrdinalTypeSimpl

syntax Array ::= "(" RangeMap ")" [symbol(arrayVal)]
syntax Expr ::= Array

rule <k> P:ProgramHeading ; B:ProgramBlock . => P ~> B ...</k>
rule <k> program I:Id ( P:ProgramParameterList ) => .K ...</k> <meta> .Map => "name" |-> I "params" |-> P </meta>
rule <k> program I:Id => .K ...</k> <meta> .Map => "name" |-> I </meta>

//Block part decomposition
rule <k> label L:Labels ; C:ConstantPart  => L ~> C ...</k>
rule <k> const C:ConstantDefinitions ; T:TypePart => C ~> T ...</k>
rule <k> type T:TypeDefinitions ; V:VariablePart  => T ~> V ...</k>
rule <k> var V:VariableDeclarations ; C:ProcedureAndFunctionPart  => V ~> C ...</k>
rule <k> P:ProcedureAndFunctions ; C:CompoundStatement  => P ~> C ...</k>

//Label evaluation
rule <k> L:Int , LS:Labels => LS ...</k> <labels> LSET => LSET |Set SetItem(L) </labels>
	requires notBool (L in LSET)
rule <k> .Labels => .K ...</k>

//Type evaluation
rule <k> .TypeDefinitions => .K ...</k>
rule <k> TD:TypeDefinition ; TS:TypeDefinitions => TD ~> TS ...</k>
rule <k> I:Id = T:TypeDenoter => .K ...</k> <state> STATE => STATE I |-> T </state>
	requires (notBool (I in_keys (STATE))) andBool isKResult(T)
rule <k> array [I1:IndexType, I2:IndexType, I:IndexTypes] of C:ComponentType => array [I1] of array [I2, I] of C ...</k>
rule <k> (C1:Int .. C2:Int):OrdinalType => Ordinal(C1, C2) ...</k>
rule <k> ( I:Ids ):EnumeratedType => EBuilder(I, 0) ...</k>
rule <k> EBuilder(I:Id , IS:Ids, INDEX:Int) => EBuilder(IS, INDEX +Int 1) ...</k> <state> STATE => STATE [I <- INDEX] </state>
	requires notBool (I in_keys (STATE))
rule <k> EBuilder(.Ids, INDEX:Int) => Ordinal(0, INDEX) ...</k>

//Function/procedure evaluation
rule <k> .ProcedureAndFunctions => .K ...</k>
//Forward declare without params
rule <k> procedure I:Id ; D:Directive P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- undefined ]</procs>
	requires notBool( I in_keys (PROCS:Map) ) andBool (Id2String(D) ==String "forward")
//Forward declare with params
rule <k> procedure I:Id (); D:Directive P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- undefined ]</procs>
	requires notBool( I in_keys (PROCS:Map) ) andBool (Id2String(D) ==String "forward")
//Direct definition with params
rule <k> procedure I:Id () ; B:Block P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- B ]</procs>
	requires notBool(I in_keys (PROCS))
//Direct definition or define foward declared function (both without params)
rule <k> procedure I:Id; B:Block P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- B ]</procs>
	requires (notBool(I in_keys (PROCS))) orBool (PROCS[I] ==K undefined)
//Forward declare without params
rule <k> function I:Id : _R:ResultType ; D:Directive P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- undefined ]</procs>
	requires notBool( I in_keys (PROCS:Map) ) andBool (Id2String(D) ==String "forward")
//Forward declare with params
rule <k> function I:Id () : _R:ResultType ; D:Directive P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- undefined ]</procs>
	requires notBool( I in_keys (PROCS:Map) ) andBool (Id2String(D) ==String "forward")
//Direct definition without params
rule <k> function I:Id : _R:ResultType  ; B:Block P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- B ]</procs>
	requires notBool(I in_keys (PROCS))
//Direct definition with params
rule <k> function I:Id () : _R:ResultType  ; B:Block P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- B ]</procs>
	requires notBool(I in_keys (PROCS))
//Define foward declared function
rule <k> function I:Id; B:Block P:ProcedureAndFunctions => P ...</k> <procs> PROCS => PROCS [ I <- B ]</procs>
	requires (PROCS[I] ==K undefined)

//rule <k> program P:CompoundStatement => P ...</k>
//

//Constant definition evaluation
rule <k> .ConstantDefinitions => .K ...</k>
rule <k> I:Id = E:Constant ; L:ConstantDefinitions => L ...</k>
	<state>S:Map => S [I <- E]</state>
	<consts> CS => CS |Set SetItem(I) </consts>
	requires (notBool I in_keys (S)) andBool (notBool I in CS)

//Variable evaluation
rule <k> .VariableDeclarations => .K ...</k>
rule <k> V1:VariableDeclaration; V:VariableDeclarations =>  V1 ~> V ...</k>
rule <k> variableDeclaration((I:Id, IS:Ids), T:TypeDenoter) => variableDeclaration(I, T) ; variableDeclaration(IS, T) ...</k>
rule <k> variableDeclaration(.Ids , _:TypeDenoter) => .K ...</k>
rule <k> variableDeclaration(I:Id, (array [Ordinal(START:Int, END:Int)] of _:ComponentType)) => .K ...</k>
	<state>S:Map => S [I <- ([START, END) r|-> undefined)]</state>
	requires notBool I in_keys (S)
rule <k> variableDeclaration((I:Id, .Ids), T:NewType) => .K ...</k>
	<state>S:Map => S [I <- undefined]</state>
	requires (notBool (I in_keys (S:Map))) andBool (notBool isArrayType(T))
rule <k> E1:Expr ; E2:Expr => E1 ~> E2 ...</k>
rule <k> I:Id => V ...</k>
	<state>... I |-> V ...</state>
	requires (isKResult(V))
rule <k> I:Id := E:Expr => .K ...</k> <state>S:Map => S [I <- E]</state>
	requires I in_keys (S)

//Compound statement evaluation
rule <k> begin S:StatementSequence end => S ...</k>

//Constant evaluation
rule <k> (+ I:Int):Constant => I ...</k>
rule <k> (- I:Int):Constant => 0 -Int I ...</k>

//Integer evaluation
rule <k> I1:Int * I2:Int => I1 *Int I2 ...</k>
rule <k> I1:Int / I2:Int => I1 /Int I2 ...</k>
	requires notBool I2 ==Int 0
rule <k> I1:Int + I2:Int => I1 +Int I2 ...</k>
rule <k> I1:Int - I2:Int => I1 -Int I2 ...</k>
rule <k> (+ I:Int):Expr => I ...</k>
rule <k> (- I:Int):Expr => 0 -Int I ...</k>

//Integer comparison
rule <k> I1:Int = I2:Int => I1 ==Int I2 ...</k>
rule <k> I1:Int <> I2:Int => I1 =/=Int I2 ...</k>
rule <k> I1:Int < I2:Int => I1 <Int I2 ...</k>
rule <k> I1:Int > I2:Int => I1 >Int I2 ...</k>
rule <k> I1:Int <= I2:Int => I1 <=Int I2 ...</k>
rule <k> I1:Int >= I2:Int => I1 >=Int I2 ...</k>

//Boolean evaluation
rule <k> not B:Bool => notBool B ...</k>
rule <k> B1:Bool and B2:Bool => B1 andBool B2 ...</k>
rule <k> B1:Bool or B2:Bool => B1 orBool B2 ...</k>
rule <k> B1:Bool = B2:Bool => B1 ==Bool B2 ...</k>
rule <k> B1:Bool <> B2:Bool => B1 =/=Bool B2 ...</k>

//Array dereferencing
rule <k> arrayVal(R:RangeMap)[I:Int] => R[I] ...</k>

syntax Bool ::= isKResult(K) [function, symbol(isKResult)]
rule isKResult(_:Int) => true
rule isKResult(_:Bool) => true
rule isKResult(_:String) => true
rule isKResult(_:Array) => true
rule isKResult(_:Type) => true
rule isKResult(.IndexTypes) => true
rule isKResult(T:IndexType , TS:IndexTypes) => isKResult(T) andBool isKResult(TS)
rule isKResult(array [ T:IndexType ] of C:ComponentType) => isKResult(T) andBool isKResult(C)
rule isKResult(file of C:ComponentType) => isKResult(C)
rule isKResult(set of C:BaseType) => isKResult(C)
rule isKResult((^ _:Id):NewPointerType) => true
rule isKResult(_:RecordType) => true
rule isKResult(_) => false [owise]

syntax Bool ::= allFresh(Ids, Map) [function, total]
rule allFresh(.Ids, _) => true
rule allFresh((X:Id, Xs:Ids), Rho) => notBool (X in_keys(Rho)) andBool allFresh(Xs, Rho)

endmodule
