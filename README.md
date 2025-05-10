
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
    - Para se deslocar mais rapidamente pelo mundo, o personagem pode começar a correr, cansando ao longo do tempo através de uma barra de estamina.

- Lanterna
    - O personagem usará o telefone como lanterna, e, ao ficar assustado começará a tremer, o que poderá desligar a lanterna.

- Usar Item (Inventário)
    - O jogador terá acesso a um inventário que permite o uso de itens coletados durante a jornada. Com um sistema simples e eficiente, o jogador pode consumir ou equipar itens rapidamente, adaptando-se às situações e aprimorando sua experiência de jogo.

## Stack Tecnológico
### Engine
- Godot
  
### Modelos 3D
- Blender (Personagens)
- Trenchbroom (Mapa)
### Técnicas
- Iluminação e Sombras em Tempo Real
    - Utilizado na lanterna e em outros pontos de iluminação que haverá no mapa.
- Sistemas de Partículas
    - Utilizado na interação das armas com o ambiente (faiscas ao bater em paredes) e ao acertar inimigos.
- Visualização de IA
    - Utilziado na segunda fase (segundo andar), onde o chefe conseguirá realizar path fiding para o jogador caso esteja em seu campo de visão.

## Fases
O mapa consiste em diversas áreas da faculdade com inimigos espalhados, separados por andar e bloco, nem todas as partes estarão desbloqueadas desde o começo.

## História
O protagonista chega no seu primeiro dia de aula e é oferecido alguma substância estranha, ao provar, ele apaga e acorda no gramado em frente ao letreiro da Rural desnorteado. Ao olhar os arredores, ele percebe a faculdade estranha, está de noite, com uma neblina intensa e a saída está trancada, ele escuta barulhos amedrontadores saindo dos prédios da universidade e percebe que terá que encará-los para conseguir sair dali.

## Objetivos
O jogador deverá resolver diversos puzzles para desbloquear áreas novas do mapa e finalmente escapar da área

## Progressão
- Primeiro objetivo: Entrar no bandejão
    - Ao escutar um barulho saindo do bandejão, o jogador resolve investigar. Porém a porta esta trancada, com isso será necessário explorar o térreo e resolver um puzzle no auditório. Quando ele conseguir entrar no bandejão, haverá uma cutscene apresentando o primeiro boss. Após isso, o jogador deverá se esconder e o segundo andar será liberado.
- Segundo objetivo: Investigar o segundo andar
    - O segundo andar será uma fase de stealth e exploração, o primeiro boss perseguirá o jogador enquanto ele explora, após explorar, ele encontrará a chave da biblioteca e lá será o combate com o boss. Ao final a chave para o terceiro andar.
- Terceiro objetivo: Investigar o terceiro andar
    - O terceiro andar será uma fase de exploração onde haverá um puzzle para desbloquear o laboratório de informática. Ao entrar no laboratório ele descobrirá que ele deve ir para o prédio da pós.
- Objetivo Final: Enfrentar o boss final na pós
    - Após derrotar o boss final, aparecerá uma cutscene mostrando o final do jogo.

## Personagens
### Protagonista: Helcio

### Inimigos
- Cachorro satânico
- Zumbi 
- Monstro grande e forte
- Peixe-Aranha satânico

### Chefes
-   Primeiro: Homem urso comilão
-   Segundo (final): Porco humanóide


## Armas/Skills
- Cano (Melee)
	- Dano baixo
- Faca (Melee)
	- Dano alto
- Revólver 
	- Alcance médio, dano médio
- Espingarda
	- Alcance curto, dano por distância

## Pontuação
O jogo não apresentará sistema de pontuação

## Game Over/Continue
O jogo apresentará pontos de salvamento (banheiro de cada andar) onde o jogador poderá salvar seu progresso, ao morrer o último salvamento será carregado.

## Vida/Mana/Níveis
O jogador possuirá vida e estamina que não serão visíveis durante o jogo, haverão indicativos visuais de que elas estão baixas. A vida poderá ser recuperada utilizando kits médicos, a estamina se recuperará automaticamente quando não estiver correndo nem batendo.

## Mecânica de Itens/armas
Cada item terá uma forma única de ser utilizado para progredir na história, alguns outros itens como consumíveis serão empilháveis, podendo existir mais de uma unidade do mesmo no inventário do jogador.