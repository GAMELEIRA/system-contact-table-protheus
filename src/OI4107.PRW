#include 'Protheus.ch'

#include 'FWMVCDef.ch'

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 08/06/2020
* HORA:12:20
* FINALIDADE DA FUNCAO: ESTA FUNCAO E UTILIZADA PARA CRIAR UMA TELA COM OS CAMPOS DA SLJ
*/
User Function OI4107()

	Local oBrowse //ARMAZENARA A INSTANCIA DO BROWSE

	oBrowse := FWMBrowse():New() //INSTANCIA O BROWSE 

	oBrowse:SetAlias("SLJ") //ABRE A TABELA SLJ PARA SER UTILIZADA NO BROWSE

	oBrowse:SetDescription("SLJ / CONTATOS") //A DESCRICAO DA TABELA
	
	oBrowse:Activate() //ATIVA O BROWSE NA ROTINA

Return Nil

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 08/06/2020
* HORA:12:53
* FINALIDADE DA FUNCAO: ESTA FUNCAO E UTILIZADA PARA CRIAR AS OPCOES POSSIVEIS PARA SEREM UTILIZADAS NA ROTINA
*/
Static Function MenuDef()

	Local aRot 		:= {}
	
	ADD OPTION aRot TITLE 'Visualizar' 	ACTION 'VIEWDEF.OI4107' 	OPERATION MODEL_OPERATION_VIEW   	ACCESS 0 //CRIA UM BOTAO DE VISUALIZACAO

	ADD OPTION aRot TITLE 'Importe CSV'	ACTION 'u_OI41071()'   		OPERATION 1                      	ACCESS 0 //CRIA UMA OPCAO DE IMPORT

	ADD OPTION aRot TITLE 'Incluir'	ACTION 'VIEWDEF.OI4107'   		OPERATION 3                      	ACCESS 0 //CRIA UMA OPCAO DE IMPORT

	ADD OPTION aRot TITLE 'Alterar'    	ACTION 'VIEWDEF.OI4107' 	OPERATION MODEL_OPERATION_UPDATE 	ACCESS 0 //CRIA UM BOTAO PARA ALTERACAO

Return aRot //RETORNA AS OPCOES CRIADAS

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 08/06/2020
* HORA:12:53
* FINALIDADE DA FUNCAO: ESTA FUNCAO E UTILIZADA PARA CRIAR A ESTRUTURA 
*/

Static Function ModelDef()

	Local oModel

	Local oStr1:= FWFormStruct(1,'SLJ')

	Local oStr2:= FWFormStruct(1,'ZA1')

	Local oStr3:= FWFormStruct(1,'ZA2')

	oModel := MPFormModel():New('OI4107M')

	oModel:SetDescription('Contatos')

	oModel:addFields('FLDSLJ',,oStr1)

	oModel:addGrid('GRDZA1','FLDSLJ',oStr2)

	oModel:addGrid('GRDZA2','FLDSLJ',oStr3)

	oModel:SetPrimaryKey({ 'L1_FILIAL', 'L1_NUM' })

	oModel:SetRelation('GRDZA1',{{'ZA1_CODFIL', 'LJ_RPCFIL'}}, ZA1->(IndexKey(5)))

	oModel:SetRelation('GRDZA2', {{ 'ZA2_CODFIL', 'LJ_RPCFIL'}}, ZA2->(IndexKey(5)))

	oModel:getModel('FLDSLJ'):SetDescription('Header')

	oModel:getModel('GRDZA1'):SetDescription('Itens Cupom')

	oModel:getModel('GRDZA2'):SetDescription('Forma de Pagamento')

	// oStr1:SetProperty("*", MODEL_FIELD_WHEN, {|| .F.})

    // oStr2:SetProperty("*", MODEL_FIELD_WHEN, {|| .F.})

Return oModel

Static Function ViewDef()
	
	Local oView //ARMAZENARA A INSTANCIA DA VIEW

	Local oModel := ModelDef() //BUSCA O RETORNO DO MODEL DEF

	Local oStr1:= FWFormStruct(2, 'SLJ') 

	Local oStr2:= FWFormStruct(2, 'ZA1')

	Local oStr3:= FWFormStruct(2, 'ZA2')
	
	oView := FWFormView():New()

	oView:SetModel(oModel)
	
	oView:AddField('head' , oStr1,'FLDSLJ' )
	
	oView:AddGrid('det' , oStr2,'GRDZA1')
	
	oView:AddGrid('pay' , oStr3,'GRDZA2')   
	
	oView:CreateHorizontalBox( 'BOXFORM1', 33) //OCUPARA 33 PORCENTO DA TELA
	
	oView:CreateHorizontalBox( 'BOXFORM3', 33) //OCUPARA 33 PORCENTO DA TELA
	
	oView:CreateHorizontalBox( 'BOXFORM5', 34) //OCUPARA 34 PORCENTO DA TELA

	oView:SetOwnerView('head','BOXFORM1') 
	
	oView:SetOwnerView('det','BOXFORM3') 
	
	oView:SetOwnerView('pay','BOXFORM5')
	
Return oView

User Function OI41071()

    Local cDiret

    Local cLinha 	:= ""

    Local lPLinha 	:= .T.

    Local aCampos 	:= {} 

    Local aDados 	:= {}

	Local nI		:= 0

	Local nJ		:= 0

	Local nTamFil		:= TAMSX3("ZA1_CODFIL")[1]           

    Private aErro := {}

     cDiret:= cGetFile('*|*.csv' , 'Importe CSV', 1, '', .T.,( GETF_LOCALHARD),.T.)
    
     If Len(AllTrim(cDiret)) == 0

	 	MsgInfo("Nennhum arquivo selecionado")

		 Return

	 EndIf

	FT_FUSE(cDiret)

    ProcRegua(FT_FLASTREC())

    FT_FGOTOP()

    While !FT_FEOF()

        cLinha := FT_FREADLN()

		aVar:= {}

        If lPLinha
            
			aCampos := Separa(cLinha,";",.T.)

            lPLinha := .F.
        
		Else

			aVar:= Separa(cLinha,";",.T.)

			aVar[3]:= validarCaracter(aVar[3])
			
			aVar[4]:= validarCaracter(aVar[4])
			
			aVar[5]:= validarNumero(aVar[5])

            AADD(aDados,aVar);

        EndIf

        FT_FSKIP()
		
    EndDo

    Begin Transaction

	ProcRegua(Len(aDados))

	dropZa1()

	dbSelectArea("ZA1")

	dbSetOrder(5)

	ZA1->(dbGoTop())

    For nI :=1 to Len(aDados)

        IncProc("Importando Registros...")

		_cCodFil := SUBSTR(aDados[nI,1]+SPACE( 12 ),1,nTamFil)

		DBSELECTAREA("ZA1")
			
			Reclock("ZA1",.T.)

			ZA1->ZA1_FILIAL := xFilial("ZA1")

        	ZA1->ZA1_ID := GETSXENUM('ZA1','ZA1_ID')
			
			For nJ:=1 to Len(aCampos)
			
				ZA1->&(aCampos[nJ]) := (aDados[nI][nJ])
        	
			Next nJ
			
			ZA1->(MsUnlock()) 

    Next nI

    End Transaction

    FT_FUSE()

    ApMsgInfo("Importe dos contatos finalizado com sucesso!","[AEST901] - SUCESSO")

Return

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 04/06/2020
* HORA:11:24
* FINALIDADE DA FUNCAO: ESTA FUNCAO VALIDA SE UM NUMERO DE TELEFONE POSSUI APENAS NUMEROS
* E REMOVE CARACTERES DE LETRAS E ESPECIAIS. ISTO IRA PERMITIR MAIOR INTEGRIDADE NOS DADOS ANTES DE SUBIR PARA O DB
*/

Static Function validarNumero(cNumero)

Local cRet := "" //IRA CONTER O CONJUNTO DE CARACACTERES VALIDOS

Local nCont //USADO PARA CONTROLAR O FLUXO DE EXEC DO FOR

    for nCont := 1 to LEN(cNumero) STEP 1 //EXECUTA ATE CONT ATINGIR O TAMANHO DA STRING

		If SUBSTR(cNumero,nCont, 1) $ "0|1|2|3|4|5|6|7|8|9" //SE ESTIVER CONTIDO UM NUMERO NATURAL

				cRet += SUBSTR(cNumero,nCont, 1) //CONCATENA NA STRING FORMATADA

		EndIf
		
	NEXT

Return cRet //RETORNA STRING FORMATADA

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 08/06/2020
* HORA:11:20
* FINALIDADE DA FUNCAO: ESTA FUNCAO VALIDA SE UM CAMPO POSSUI APENAS LETRAS
* E REMOVE CARACTERES ESPECIAIS E NUMEROS. ISTO IRA PERMITIR MAIOR INTEGRIDADE NOS DADOS ANTES DE SUBIR PARA O DB.
*/

Static Function  validarCaracter(cCaracter)
    
LOCAL cRet := "" //IRA CONTER O CONJUNTO DE CARACACTERES VALIDOS

Local nCont //USADO PARA CONTROLAR O FLUXO DE EXEC DO FOR

        for nCont := 1 to LEN(cCaracter) STEP 1 //EXECUTA ATE CONT ATINGIR O TAMANHO DO CONJUNTO DE CARACTERES 

            IF ISALPHA(SUBSTR(cCaracter, nCont, 1)) .OR. SUBSTR(cCaracter, nCont, 1) == " " //SE FOR ALGUMA LETRA DO ALFABETO OU ESPACO EM BRANCO
            
            cRet += SUBSTR(cCaracter,nCont, 1) //CONCATENA NA STRING FORMATADA

            ENDIF

        NEXT

Return cRet //RETORNA STRING FORMATADA

/**
* AUTOR: GABRIEL GAMELEIRA DOS SANTOS
* DATA 08/06/2020
* HORA:11:20
* FINALIDADE DA FUNCAO: ESTA FUNCAO MARCA TODOS OS REGISTROS DA TABELA ZA1 COMO DELETADOS. 
* POREM, OS REGISTROS DA ZA1 N�O S�O EXCLUIDOS DE FORMA FISICA APENAS SAO MARCADOS PARA N�O SEREM MAIS UTLIZADOS NAS ROTINAS
*/

Static Function dropZa1()

	DBSELECTAREA("ZA1") //SELECIONANDO A ZA1 PARA REALIZAR OPERACOES DE MANIPULACAO

	DBSETORDER(1) //POSICIONANDO REGISTROS BASEADO NO INDICE 1 DA ZA1

	ZA1->(DBGOTOP()) //POSICIONA PONTEIRO PARA O TOPO DA TABELA OU SEJA NO PRIMEIRO REGISTRO 

	WHILE ZA1->(!EOF()) //ENQUANTO NAO FOR O FINAL DA TABELA ZA1 EXECUTE

		RecLock("ZA1", .F.) //PROTEJO A ZA1 PARA QUE EU TENHA ACESSO EXCLUSIVO PARA A TABELA

		ZA1->(DBDelete()) //DELETA O REGISTRO POSICIONADO 

		ZA1->(MsUnLock()) //LIBERA O BLOQUEIO DO REGISTRO POSICIONADO

		ZA1->(DBSKIP()) //PULA PARA O PROXIMO REGISTRO

	ENDDO

	ZA1->(DBCloseArea()) //FECHA A OPERACAO E DESALOCA A OPERACAO COM A TABELA

Return Nil