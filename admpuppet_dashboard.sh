#!/bin/bash

<< '--Comentario--'
 Objetivo: Gerenciar a API do Puppet Enterprise.
 O Dashboard do Puppet é utilizado para gerenciar as salas de   aula da 4Linux para preparar o curso no Virtual Box, sendo cada sala composto por um grupo e as variaveis com o valor do curso e período da turma.
 Por Rafael Mendonca.
 É necessário instalar o comando "dig" para que o script funcione perfeitamente!
 Data: Mon Nov 18 17:07:57 BRST 2013
 Ultimo update: Thu Nov 21 17:47:02 BRST 2013

 Regras
 1 - Verificar se existe curso em andamento, antes de modificar ou apagar. 
 2 - Evitar erros ao digitar o periodo. 
 3 - Confirmacao de alteracao. 
--Comentario--


# DECLARACOES
BIN_RAKE="/opt/puppet/bin/rake -f /opt/puppet/share/puppet-dashboard/Rakefile RAILS_ENV=production"
BIN_DIALOG="/usr/bin/dialog"
TMP_DIR="/var/log/pe-manager-api"

########################################################
# FUNCOES PARA UTILIZACAO DAS TAREFAS
#########################################################

limpa_variaveis(){
# Limpando as variaveis
unset $OPT
unset $MENU_CURSOS
unset $OPT_SALA
unset $OPT_PERIODO
unset $OPT_CURSO
unset $LOG_LISTAR_TURMA
unset $LOG_REMOVER_TURMA
unset $LOG_MODIFICAR_TURMAS
}
#
# Menu de listar turmas
#
puppet_menu_listar_turmas(){
limpa_variaveis
			OPT_SALA=$( $BIN_DIALOG --stdout --menu 'Escolha a sala para listar:' 0 0 0   1 'Maddog' 2 'Linus' 3 'Tux' 4 'Ian Murdock' 5 'Freedom' 6 'Sala de Aula Nova')

test ! -z $OPT_SALA 
	if [ $? == 0 ] ; then 
					case $OPT_SALA in 
						1)
						 OPT_SALA="Sala\ Maddog"
						;;
						2)
						 OPT_SALA="Sala\ Linus"
						;;
						6)
						 OPT_SALA="Sala\ de\ Aula\ Nova"
						 LOG_LISTAR_TURMA="$TMP_DIR/puppet_listar_turma_teste.log"
						 puppet_listar_turmas
						;;
					esac
	else
		menu_puppet
	fi
}


#
# ACAO PARA LISTAR TURMAS
#
puppet_listar_turmas(){ 
	# NOTIFICANDO O QUE ESTA OCORRENDO.. 
	$BIN_DIALOG --title 'Aguarde' --infobox '\nCarregando as variaveis declaradas no Dashboard...\n\n' 0 0

	# Criando titulo para exibicao
	/bin/echo -e "\n\t$(echo $OPT_SALA | sed 's/\\//g')\nUltima consulta:\n$(date +%d-%m-%Y\ %H:%M:%S)\n\n\tCursos em Andamento\n" > $LOG_LISTAR_TURMA

	# LISTANDO VARIABEIS DO DASHBOARD 
	$BIN_RAKE nodegroup:variables["$OPT_SALA"] >> $LOG_LISTAR_TURMA

	# EXIBINDO AS VARIAVEIS QUE FORAM DECLARADAS
	$BIN_DIALOG --title "Puppet" --textbox $LOG_LISTAR_TURMA 25 35

	# VOLTANDO PARA O MENU PUPPET
	menu_puppet
}


#
# MENU PARA MODIFICAR TURMAS 
#
puppet_menu_modificar_turmas(){
limpa_variaveis
OPT_SALA=$( $BIN_DIALOG --stdout --menu 'Escolha a Sala:' 0 0 0   1 Maddog 2 Linus 3 Tux 4 Ian\ Murdock 5 Freedom 6 Sala\ de\ Aula\ Nova)

test ! -z $OPT_SALA 
	if [ $? == 0  ] ; then 
					case $OPT_SALA in 
						1)  
						
						;;

						6)
						OPT_SALA="Sala\ de\ Aula\ Nova"
						LOG_MODIFICAR_TURMA="$TMP_DIR/puppet_modificar_turma_teste.log"
						puppet_modificar_turmas
						;;
					esac
	else
		menu_puppet
	fi
}


#
# ACAO MODIFICAR TURMAS 
#
puppet_modificar_turmas(){
	OPT_PERIODO=$( $BIN_DIALOG --stdout --menu 'Escolha o Periodo:' 0 0 0 matutino '' vespertino '' noturno '' diurno '' sabado '' domingo '' )
		
	# CHECANDO SE FOI INSERIDO ALGUM VALOR NA VARIAVEL 
	/usr/bin/test -z $OPT_PERIODO
	if [ $? == 0 ]; then
		$BIN_DIALOG --title "IMPORTANTE" --msgbox "Nenhum periodo foi especificado, voltando para o menu Puppet." 0 0
		menu_puppet
	else
		OPT_CURSO=$( dialog --stdout --inputbox 'Digite somente o numero do curso, (Exemplo: 450) :' 0 0 )
	fi
	
 	/usr/bin/test -z $OPT_CURSO
	if [ $? != 0 ] ; then	
		# Verifica se tem turma ja em andamento 
		$BIN_DIALOG --title 'Aguarde' --infobox '\nVerificando se existe curso em andamento...\n\n' 0 0
		$BIN_RAKE nodegroup:variables["$OPT_SALA"] | /bin/grep "${OPT_PERIODO}=null" > /dev/null

		if [ $? == 0 ] ; then
		# CASO NAO TENHA CURSO FACA A MODIFICAO DA VARIAVEL
			$BIN_DIALOG --title 'Aguarde' --infobox "\nModificando variavel $OPT_PERIODO para $OPT_CURSO...\n\n" 0 0
			$BIN_RAKE nodegroup:variables["$OPT_SALA","$OPT_PERIODO"="$OPT_CURSO"] > $LOG_MODIFICAR_TURMA
			$BIN_DIALOG --title 'Resultado' --textbox $LOG_MODIFICAR_TURMA 0 0
			menu_puppet
		else
		# CASO TENHA CURSO EM ANDAMENTO NOTIFIQUE-O DO MESMO. E PERGUNTE SE DESEJA CONTINUAR! 
			$BIN_DIALOG --title "ATENCAO!!" --msgbox "\n$(echo $OPT_SALA | sed 's/\\//g')\nCurso $OPT_PERIODO em andamento\n\n" 0 0
			$BIN_DIALOG --title 'IMPORTANTE' --yesno 'Deseja continuar?' 0 0
				if [ $? == 0 ] ; then
					$BIN_DIALOG --title 'Aguarde' --infobox "\nModificando variavel $OPT_PERIODO para $OPT_CURSO..\n\n" 0 0
					$BIN_RAKE nodegroup:variables["$OPT_SALA","$OPT_PERIODO"="$OPT_CURSO"] > $LOG_MODIFICAR_TURMA
					$BIN_DIALOG --title 'Resultado' --textbox $LOG_MODIFICAR_TURMA
					menu_puppet
				else
					$BIN_DIALOG --title "IMPORTANTE" --msgbox "No! voltando para o menu Puppet." 0 0
					menu_puppet
				fi
		fi
	else
		$BIN_DIALOG --title "IMPORTANTE" --msgbox "\nNenhum curso foi inserido. Voltando para o menu principal.\n\n" 0 0
		menu_puppet
	fi
}

#
# MENU PARA REMOVER AS TURMAS 
#
puppet_menu_remover_turmas(){
limpa_variaveis
OPT_SALA=$( $BIN_DIALOG --stdout --menu 'Escolha a Sala:' 0 0 0   1 Maddog 2 Linus 3 Tux 4 Ian\ Murdock 5 Freedom 6 Sala\ de\ Aula\ Nova)

test ! -z $OPT_SALA 
	if [ $? == 0  ] ; then 
					case $OPT_SALA in 
						1)  
						
						;;

						6)
						OPT_SALA="Sala\ de\ Aula\ Nova"
						LOG_REMOVER_TURMAS="$TMP_DIR/puppet_remover_turmas_teste.log"
						puppet_remover_turmas
						;;
					esac
	else
		menu_puppet
	fi

}

#
# ACAO PARA REMOVER 
# 
puppet_remover_turmas(){
	OPT_PERIODO=$( $BIN_DIALOG --stdout --menu 'Escolha o Periodo:' 0 0 0 matutino '' vespertino '' noturno '' diurno '' sabado '' domingo '' )
	
	/usr/bin/test ! -z $OPT_PERIODO 
	if [ $? == 0 ] ; then

		$BIN_DIALOG --title 'Aguarde' --infobox "\n$(echo $OPT_SALA | sed 's/\\//g')\nVerificando se existe curso $OPT_PERIODO em andamento...\n\n" 0 0
		$BIN_RAKE nodegroup:variables["$OPT_SALA"] | /bin/grep "${OPT_PERIODO}=null" > /dev/null

		if [ $? == 0 ] ; then
			$BIN_DIALOG --title 'Aguarde' --infobox "\n$(echo $OPT_SALA | sed 's/\\//g')\nNenhum curso em andamendo.\nRemovendo variavel do periodo $OPT_PERIODO...\n\n" 0 0
			$BIN_RAKE nodegroup:variables["$OPT_SALA","$OPT_PERIODO"="null"] > $LOG_REMOVER_TURMAS
			$BIN_DIALOG --title 'Resultado' --textbox $LOG_REMOVER_TURMAS 0 0
			menu_puppet
		else
	
			 $BIN_DIALOG --title "ATENCAO!!" --msgbox "\n$(echo $OPT_SALA | sed 's/\\//g')\nCurso $OPT_PERIODO em andamento.\n\n" 0 0
			$BIN_DIALOG --title 'ATENCAO!!' --yesno "\n$(echo $OPT_SALA | sed 's/\\//g')\nContinuar com a remocao do $OPT_PERIODO?\n\n" 0 0
				if [ $? == 0 ] ; then
						$BIN_DIALOG --title 'Aguarde' --infobox "\nRemovendo variavel $OPT_SALA_PERIODO...\n\n" 0 0
						$BIN_RAKE nodegroup:variables["$OPT_SALA","$OPT_PERIODO"="null"] > $LOG_REMOVER_TURMAS
						$BIN_DIALOG --title 'Resultado' --textbox $LOG_REMOVER_TURMAS 0 0
						menu_puppet
				else
						$BIN_DIALOG --title "IMPORTANTE" --msgbox "\nNo! voltando para o menu Puppet.\n\n" 0 0
						menu_puppet
				fi
		fi
	else
		$BIN_DIALOG --title "IMPORTANTE" --msgbox "\nNenhum periodo foi escolhido. Voltando para o menu principal.\n\n" 0 0
		menu_puppet
		
	fi
}


#
# Menu Principal
#


menu_puppet(){ 
limpa_variaveis

# Menu para escolha de acoes sobre os cursos
MENU_CURSOS=$( $BIN_DIALOG --stdout --menu 'O que deseja?' 0 0 0   1 'Listar Turmas em Andamento' 2 'Adicionar/Alterar' 3 'Remover Turmas' )

/usr/bin/test ! -z $MENU_CURSOS 
if [ $? == 0 ] ; then
	case $MENU_CURSOS in 
		# Chmando menu para Listar Turmas em Andamento
				1)
					puppet_menu_listar_turmas
				;;
 		# Chamando menu Modificar Turma
				2)
					puppet_menu_modificar_turmas
          	;;
		# Chamando menu 
				3)  
					puppet_menu_remover_turmas
				;;
 	esac
else
	/srv/pe-manager-api/principal.sh
fi
}
menu_puppet
