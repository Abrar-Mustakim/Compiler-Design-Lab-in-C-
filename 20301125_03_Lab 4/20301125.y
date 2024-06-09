%{

#include "symbol_table.h"
using namespace std;
#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;



vector<string> split(const string& str, char delim) {
    vector<string> tokens;
    stringstream ss(str);
    string token;
    while (getline(ss, token, delim)) {
        tokens.push_back(token);
    }
    return tokens;
}


// create your symbol table here.
// You can store the pointer to your symbol table in a global variable
// or you can create an object
symbol_table* sym_table;
int lines = 1;
int error_count;
ofstream outlog;
ofstream errorlog;

// you may declare other necessary variables here to store necessary info
// such as current variable type, variable list, function name, return type, function parameter types, parameters names etc.
string current_variable_type, current_function_name;
string current_type;
string array_size;
vector<string> current_parameter_types, current_parameter_names;

void yyerror(char *s=NULL)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
	error_count++;
    // you may need to reinitialize variables if you find an error

}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		// Print your whole symbol table here
		sym_table->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		
		$$ = new symbol_info($1->get_name(),"unit");
	 }
	 | error {
		errorlog<<"Syntax error at unit ";
		$$ = new symbol_info("", "unit");
		$$->set_name("");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN func_enter compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"("+$4->get_name()+")\n"<<$6->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$6->get_name(),"func_def");	
			
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
			outlog << "New ScopeTable with ID " << sym_table->getCurrentScopeID() << " created" << endl << endl;
			sym_table->enter_scope();
			
    


			sym_table->insert(new symbol_info($2->get_name(), $1->get_type(), "function", $4->get_param_types(), $4->get_param_names()));
			
			//current_variable_type="Variable";
    		//sym_table->insert(new symbol_info($5->get_name(), current_type, current_variable_type));
			
    		sym_table->exit_scope();
			outlog << "Scopetable with ID " << sym_table->getCurrentScopeID() + 1 << " removed" << endl << endl;
			
			bool insertion = sym_table->insert($2);
			if(!insertion) {
				errorlog<<"Multiple declaration of function "<< $2->get_name() << endl;
				yyerror();
			}
			
    		
    		
		}
		| type_specifier ID LPAREN RPAREN func_enter compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$5->get_name(),"func_def");	
			
			// The function definition is complete.
            // You can now insert necessary information about the function into the symbol table
            // However, note that the scope of the function and the scope of the compound statement are different.
			
			//sym_table->enter_scope();
        	//sym_table->insert(new symbol_info($2->get_name(), current_type, current_variable_type));
			//current_variable_type="Function";
        	//sym_table->insert(new symbol_info($1->get_name(), $4->get_type(), current_variable_type));
			sym_table->insert(new symbol_info($2->get_name(), current_type, current_variable_type));
			sym_table->exit_scope();



			bool insertion = sym_table->insert($2);
			if(!insertion) {
				errorlog<<"Multiple declaration of function "<< $2->get_name() <<endl;
				yyerror();
			}
			
			
			
		}
 		;
func_enter:
		{

			sym_table->enter_scope();
			
			

		}
parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;
					
			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			$$->set_param_types($1->get_param_types()); 
    		$$->set_param_names($1->get_param_names()); 
    		$$->add_parameter($3->get_name(), $4->get_name());
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			$$ = new symbol_info($1->get_name() + "," + $3->get_name(), "param_list");
    		$$->set_param_types($1->get_param_types()); 
    		$$->set_param_names($1->get_param_names()); 
    		$$->add_parameter($3->get_name(), ""); 
		
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			$$->add_parameter($1->get_name(), $2->get_name());

		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"param_list");
			
            // store the necessary information about the function parameters
            // They will be needed when you want to enter the function into the symbol table
			$$->add_parameter($1->get_name(), "");
		}
 		;

compound_statement : LCURL statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");
				
                // The compound statement is complete.
		
				//sym_table->enter_scope();
				current_variable_type="Variable";
				//sym_table->insert(new symbol_info($1->get_name(), current_type, current_variable_type));
    			sym_table->insert(new symbol_info($2->get_name(), current_type, current_variable_type));
	
	
                // Print the symbol table here and exit the scope
                // Note that function parameters should be in the current scope
				sym_table->print_all_scopes(outlog); 
    			sym_table->exit_scope();
			}
 		    | LCURL RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				// The compound statement is complete.
                // Print the symbol table here and exit the scope
				sym_table->print_all_scopes(outlog);
    			sym_table->exit_scope();
			}
 		    ;

 		    
var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");
			
			// Insert necessary information about the variables in the symbol table
		 	current_type = $1->get_name();
			current_variable_type="Variable";
    		vector<string> vars = split($2->get_name(), ',');
    		for (string var : vars) {
        		sym_table->insert(new symbol_info(var, current_type, current_variable_type));
    		}

			bool insertion = sym_table->insert($2);
			if(!insertion) {
				errorlog<<"Multiple declaration of variable "<< $2->get_name()<< endl;
				yyerror();
			}


		 }
		 | type_specifier error SEMICOLON
		 {
			$$=new symbol_info("", "var_declaration");
			$$->set_name("");
			errorlog<<"Syntax error at var_declaration"<<endl;
			yyerror();
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			current_variable_type = "int";
			$$ = new symbol_info("int","INT");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			current_variable_type = "float";
			$$ = new symbol_info("float","FLOAT");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			current_variable_type = "void";
			$$ = new symbol_info("void","VOID");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			symbol_info* new_symbol = new symbol_info($3->get_name(), current_type);
			sym_table->insert(new_symbol);
			$$ = new symbol_info($1->get_name() + "," + $3->get_name(), "declaration_list");
	        
		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD //array after some declaration
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			//sym_table->insert($3->get_name(), current_type, "array", stoi($5->get_value()));
			//sym_table->insert($3->get_name());
			current_variable_type="Array";
    		symbol_info* new_symbol = new symbol_info($3->get_name(), current_type);
    		new_symbol->set_array_size(stoi($5->get_name()));  
    		sym_table->insert(new_symbol);
			
			$$ = new symbol_info($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]", "declaration_list");

		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			symbol_info* new_symbol = new symbol_info($1->get_name(), current_type);
			sym_table->insert(new_symbol);
    		$$ = new symbol_info($1->get_name(), "declaration_list");
 		  
		  }
 		  | ID LTHIRD CONST_INT RTHIRD //array
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

            // you may need to store the variable names to insert them in symbol table here or later
			//symbol_info* new_symbol = new symbol_info($1->get_name(), current_type);
			//sym_table->insert(new_symbol);
            symbol_info* new_symbol = new symbol_info($3->get_name(), current_type);
			sym_table->insert(new_symbol);
    		$$ = new symbol_info($1->get_name() + "[" + $3->get_name() + "]", "declaration_list");
 		  
		  	
		  
		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;
	   
statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->get_name()<<endl<<endl;

            $$ = new symbol_info($1->get_name(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl; 
			
			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");
			
	  		bool insertion = sym_table->lookup($3);
			if(!insertion) {
				errorlog<<"Undeclared variable of  "<< $3->get_name()<< endl;
				yyerror();
			}
		
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        } 
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
			
		$$ = new symbol_info($1->get_name(),"varbl");
		bool insertion = sym_table->insert($1);
		if(insertion) {
			errorlog<<"Undeclared variable "<< $1->get_name() <<endl;
			yyerror();
		} 


		auto searchedSymbol = sym_table->lookup($1);
		if( !searchedSymbol ){
			errorlog<<"Undeclared variable "<<$1->get_name()<<endl;
			yyerror();
			$$->setTypeSpecifier("error");
		}else if(searchedSymbol->isArray()){
			errorlog<<"Type mismatch,"<<$1->get_name()<<" is an array"<<endl;
			yyerror();
			$$->setTypeSpecifier("error");
		}else {
			$$->setTypeSpecifier(searchedSymbol->getTypeSpecifier());
			$$->setArray(searchedSymbol->isArray());
		}
		

		
		
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;
		
		auto searchedSymbol = sym_table->lookup($1);
		if( !searchedSymbol ){
			errorlog<<"Undeclared variable "<<$1->get_name()<<endl;
			$$->setTypeSpecifier("error");
		}else if(searchedSymbol->isArray()){
			errorlog<<"Type mismatch,"<<$1->get_name()<<" is an array"<<endl;
			$$->setTypeSpecifier("error");
		}else {
			$$->setTypeSpecifier(searchedSymbol->getTypeSpecifier());
			$$->setArray(searchedSymbol->isArray());
		}

	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"expr");
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");


			if( $3->getTypeSpecifier() == "VOID" ){
				errorlog<<"Void function used in expression"<<endl;
				yyerror();
			}else if( $1->getTypeSpecifier()== "FLOAT" and $3->getTypeSpecifier() == "INT" ){
				errorlog<<"Void function used in expression"<<endl;
				yyerror();
			}else if( $1->getTypeSpecifier()!=$3->getTypeSpecifier() and $3->getTypeSpecifier()!="error" and $1->getTypeSpecifier()!="error"){
				errorlog<<"Type mismatch"<<endl;
				yyerror();
			}
	   
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"lgc_expr");
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"rel_expr");
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");

	    	if( $1->getTypeSpecifier() == "VOID" or $3->getTypeSpecifier() == "VOID" ){
				errorlog<<"Void function used in expression"<<endl;
				yyerror();
				$$->setTypeSpecifier("error");
			}else{
				$$->setTypeSpecifier("INT");
			}
		
		
		
		}
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"simp_expr");
			
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");
	      }
		  ;
					
term :	unary_expression //term can be void because of un_expr->factor
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"term");
			
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");
			if( $3->getTypeSpecifier() == "VOID" ){
				errorlog<<"Void function used in expression"<<endl;
				yyerror();
			}else if( $2->get_name() == "%" and $3->get_name() == "0" ){
				errorlog<<"Modulus by Zero"<<endl;
				yyerror();
				$$->setTypeSpecifier("error");
			}else if($2->get_name() == "%" and ( $1->getTypeSpecifier() != "INT" or $3->getTypeSpecifier() != "INT") ){
				errorlog<<"Non-Integer operand on modulus operator"<<endl;
				yyerror();
				$$->setTypeSpecifier("error");
			}
			
	 }
     ;

unary_expression : ADDOP unary_expression  // un_expr can be void because of factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
	     
		 	if( $2->getTypeSpecifier() == "VOID" ){
				errorlog<<"Void function used in expression"<<endl;
				yyerror();
				$$->setTypeSpecifier("error");
			}else{
				$$->setTypeSpecifier($2->getTypeSpecifier());
			}
		 
		 }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
	     }
		 | factor 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;
			
			$$ = new symbol_info($1->get_name(),"un_expr");
	     }
		 ;
	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		current_variable_type="Variable";
			
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

		auto searchedSymbol = sym_table->lookup($1);
		if( !searchedSymbol ){
			errorlog<<"Undeclared function"<<$1->get_name()<<endl;
			yyerror();
		}else{
			$$->setTypeSpecifier(searchedSymbol->getTypeSpecifier());
			if( !searchedSymbol->isFunctionDeclaration() and !searchedSymbol->isFunctionDefinition()){
				errorlog<<$1->get_name()<<"is not a function"<<endl;
				yyerror();
			}else if( $3->getParameterList().size()!= searchedSymbol->getParameterList().size()){
				errorlog<<"Total number of arguments mismatch in function"<<$1->get_name()<<endl;
				yyerror();
			}else{
				auto callerParameterList = $3->getParameterList();
				auto calledParameterList = searchedSymbol->getParameterList();
				for(int i=0;i<callerParameterList.size();i++){
					if( callerParameterList[i]->getTypeSpecifier()!= calledParameterList[i]->getTypeSpecifier()){
						errorlog<<to_string(i+1)<<"th argument mismatch in function"<<$1->get_name()<<endl;
						yyerror();
					}
					if( callerParameterList[i]->isArray() and !calledParameterList[i]->isArray() ){
						errorlog<<"Type mismatch,"<<callerParameterList[i]->get_name()<<" is an array"<<endl;
						yyerror();
					}else if( !callerParameterList[i]->isArray() and calledParameterList[i]->isArray() ){
						errorlog<<"Type mismatch,"<<callerParameterList[i]->get_name()<<" is not an array"<<endl;
						yyerror();
					}
				}
			}}


	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->get_name()+")","fctr");
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		current_variable_type="CONST_INT";
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;
		current_variable_type="CONST_INT";
		$$ = new symbol_info($1->get_name(),"fctr");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"++","fctr");
		if( $1->getTypeSpecifier() == "VOID" ){
			errorlog<<"Void function used in expression"<<endl;
			yyerror();
			$$->setTypeSpecifier("error");
		}else{
			$$->setTypeSpecifier($1->getTypeSpecifier());
		}
		
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->get_name()+"--","fctr");
		if( $1->getTypeSpecifier() == "VOID" ){
			errorlog<<"Void function used in expression"<<endl;
			yyerror();
			$$->setTypeSpecifier("error");
		}else{
			$$->setTypeSpecifier($1->getTypeSpecifier());
		}
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;
						
					$$ = new symbol_info($1->get_name(),"arg_list");
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;
						
				$$ = new symbol_info($1->get_name(),"arg");
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("my_log.txt", ios::trunc);
	errorlog.open("error.txt", ios::trunc);
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}
	// Enter the global or the first scope here
	sym_table = new symbol_table(100); 
    sym_table->enter_scope(); 
	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	errorlog<<endl<<"Total Error: "<<error_count<<endl;
	
	outlog.close();
	errorlog.close();
	
	fclose(yyin);
	
	return 0;
}