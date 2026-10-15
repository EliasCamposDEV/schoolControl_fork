# School Control - Sistema de Gestão Académica (IHP + Haskell)


## Sobre o Projeto

O **School Control** é um sistema de gestão académica para controlo de alunos, cursos, matrículas e avaliação de desempenho académico. A lógica de negócio foca-se nos princípios do paradigma funcional puro, aplicando tipos algébricos de dados, imutabilidade, funções puras, currying, closures, pattern matching e list comprehensions.

---

## Tecnologias Utilizadas

* **Linguagem:** Haskell (GHC)
* **Framework Web:** IHP (Integrated Haskell Platform)
* **Base de Dados:** PostgreSQL
* **Gestão de Ambiente:** Nix / Devenv / Direnv
* **Gestão de Dependências:** Cabal

---

## Arquitetura do Domínio Funcional

O núcleo de regras de negócio fica no módulo puro `Application.Domain` (sem IO). Ele trabalha sobre os
modelos que o IHP gera a partir de `Application/Schema.sql`: `Student`, `Course`, `Enrollment` e `Grade`.

### Regra de notas 

* `AVn = 70% PEn + 30% AVfn` (prova escrita + avaliação formativa)
* `(AV1 + AV2) / 2 < 4,0` → reprovado; caso contrário, aguarda a AV3
* `AV3 < 4,0` → reprovado
* `NF = ((AV1 + AV2) / 2 + AV3) / 2`; aprovado se `NF >= 5,0`

### Conceitos aplicados

* **Tipos algébricos & records:** `Pesos` (record), `Situacao`, `Conceito`, `ErroValidacao` (sum types) e
  `EnrollmentStatus` (gerado pelo IHP a partir de um ENUM do Postgres).
* **Currying e closures:** `mediaPonderada` devolve uma função que captura os pesos; `comporAV` e
  `mediaSimples` são aplicações parciais dela.
* **Pattern matching:** `situacaoDaMatricula` (enum + `Maybe`), `emailValido`.
* **Functor/Applicative em `Maybe`:** `notaAV3` só existe se PE3 e AVf3 foram lançadas.
* **IMC adaptado:** `classificarMedia` enquadra a média em faixas com guards.
* **Validações puras:** `validarNota` (`Either`), `validarStudent`, `validarCourse`, `validarGrade`.
* **List comprehensions:** `boletim` (JOIN entre alunos, matrículas e notas), `nomesAprovados`,
  `matriculasAtivasPorCurso`.
* **Recursão em cauda:** `mediaDaTurma`.

## Equipe

* João Pedro de Almeida Floriano - 2420377
* Elias Sousa Campos - 2619080
* Felipe Cavalcante - 2210374
* Nicolly Feitosa Barroso - 2420363
* Carlos Huan Celestino de Brito - 2320478