
# Game Design Document - Loud Depression
## Grupo 1 - Integrantes
- Helcio Duarte Dantas
- Pedro Henrique Silva de Albuquerque
- Rafael França de Araujo
- Rafael Vieira da Silva
## Core Gameplay

- Andar
	- O personagem pode se mover livremente pelo ambiente, explorando diferentes áreas e interagindo com o mundo ao seu redor.

- Bater 
	- Em situações de combate corpo a corpo, o jogador pode realizar ataques rápidos com armas que serão encontradas no cenário.

- Atirar 
	- O personagem possui a habilidade de atirar com armas de fogo. O controle de mira é automático.

- Correr  
	- Para se deslocar mais rapidamente pelo mundo, o personagem pode começar a correr.

- Usar Item (Inventário)
	- O jogador terá acesso a um inventário que permite o uso de itens coletados durante a jornada. Com um sistema simples e eficiente, o jogador pode consumir ou equipar itens rapidamente, adaptando-se às situações e aprimorando sua experiência de jogo.

## Stack Tecnológico
### Engine
- Godot
  
### Modelos 3D
- Blender (Personagens)
- Trenchbroom (Mapa)
### Técnicas
- Visualização de IA
	- Apertando uma tecla, o jogador poderá abrir uma tela de debug, onde é possível ver dados de navegação dos inimigos
- Sistemas de Partículas
	- Utilizado na interação das armas com o ambiente (faiscas ao bater em paredes) e ao acertar inimigos.
- Inventário
	- Utilizado para gerenciar os itens coletados pelo jogador, permitindo o uso e a troca de armas.
	- Itens coletáveis brilharão quando o jogador estiver próximo.

## Fases
O mapa consiste em diversas áreas da faculdade com inimigos espalhados, separados por andar e bloco.

## História
O protagonista chega no seu primeiro dia de aula e é oferecido alguma substância estranha, ao provar, ele apaga e acorda no gramado em frente ao letreiro da Rural desnorteado. Ao olhar os arredores, ele percebe a faculdade estranha, está de noite, com uma neblina intensa e a saída está trancada, ele escuta barulhos amedrontadores saindo dos prédios da universidade e percebe que terá que encará-los para conseguir sair dali.

## Objetivos
O jogador deverá resolver diversos puzzles para escapar da área da faculdade

## Progressão
- Ojetivo Principal: Entrar no bandejão
	- Ao escutar um barulho saindo do bandejão, o jogador resolve investigar. Porém a porta esta trancada, com isso será necessário explorar o térreo e resolver um puzzle no auditório. Quando ele conseguir entrar no bandejão, haverá uma cutscene apresentando o boss. Após isso, o jogador deverá lutar pela sua vida.
- Objetivos secundários: Investigar os andares da faculdade em busca de recursos
	- O segundo andar e terceiro andares serão fases de exploração, Contendo itens chave para progressão na história, recursos e armas para facilitar no combate.

## Personagens
### Protagonista: Else Duarte

### Inimigos
- Cachorro satânico
- Monstro grande e forte

### Chefe
-   Primeiro: Homem urso comilão

## Armas/Skills
- Cano (Melee)
	- Dano baixo
- Faca (Melee)
	- Dano médio
- Revólver 
	- Alcance médio, dano alto

## Pontuação
O jogo não apresentará sistema de pontuação

## Game Over/Continue
O jogo apresentará pontos de salvamento (banheiro de cada andar) onde o jogador poderá salvar seu progresso, ao morrer o último salvamento será carregado.

## Vida/Mana/Níveis
O jogador possuirá vida que não será visível durante o jogo, haverá indicativos visuais de que elas estão baixas. A vida poderá ser recuperada utilizando kits médicos e ervas medicinais.

## Mecânica de Itens/armas
Cada item terá uma forma única de ser utilizado para progredir na história, alguns outros itens como consumíveis serão empilháveis, podendo existir mais de uma unidade do mesmo no inventário do jogador.
