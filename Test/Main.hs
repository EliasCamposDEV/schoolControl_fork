module Main where

import Test.Hspec
import IHP.Prelude
import IHP.ModelSupport (newRecord)
import Generated.Types
import Application.Domain
import System.IO (hSetEncoding, stdout, stderr, utf8)

-- | Monta uma nota sem tocar no banco.
nota :: Double -> Double -> Maybe Double -> Grade
nota n1 n2 exame = newRecord @Grade
    |> set #p1 n1
    |> set #p2 n2
    |> set #finalExam exame

main :: IO ()
main = do
    -- Os nomes dos testes têm acentos; garante UTF-8 mesmo em locale "C" (CI)
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    hspec specs

specs :: Spec
specs = do
    describe "mediaPonderada (currying e closures)" do
        it "aplica os pesos padrão 40/60" do
            mediaPadrao 5 10 `shouldBe` 8
        it "mediaSimples é a mesma função com outros pesos" do
            mediaSimples 5 10 `shouldBe` 7.5
        it "a aplicação parcial pode ser guardada e reutilizada" do
            let pesoDobradoNaP2 = mediaPonderada (Pesos 1 2)
            map (uncurry pesoDobradoNaP2) [(3, 6), (9, 0)] `shouldBe` [5, 3]

    describe "classificarMedia (IMC adaptado)" do
        it "enquadra a média em faixas" do
            map classificarMedia [2, 5, 7, 8, 9.5]
                `shouldBe` [Insuficiente, Regular, Bom, Otimo, Excelente]

    describe "situacaoDaMatricula (pattern matching)" do
        it "aprova com média >= 7" do
            situacaoDaMatricula Ativa (nota 7 7 Nothing) `shouldBe` Aprovado
        it "manda para exame com média entre 4 e 7" do
            situacaoDaMatricula Ativa (nota 5 5 Nothing) `shouldBe` EmExame
        it "reprova com média < 4" do
            situacaoDaMatricula Ativa (nota 2 3 Nothing) `shouldBe` Reprovado
        it "usa o exame final quando existe" do
            situacaoDaMatricula Ativa (nota 5 5 (Just 6)) `shouldBe` Aprovado
            situacaoDaMatricula Ativa (nota 5 5 (Just 2)) `shouldBe` Reprovado
        it "matrícula trancada ignora as notas" do
            situacaoDaMatricula Trancada (nota 10 10 Nothing) `shouldBe` Trancado

    describe "validações" do
        it "aceita notas entre 0 e 10" do
            validarNota "p1" 7 `shouldBe` Right 7
            validarNota "p1" 11 `shouldBe` Left (NotaForaDoIntervalo "p1" 11)
        it "valida todas as notas de uma Grade" do
            validarGrade (nota 7 (-1) (Just 12))
                `shouldBe` [NotaForaDoIntervalo "p2" (-1), NotaForaDoIntervalo "finalExam" 12]
        it "valida nome e e-mail do estudante" do
            let student = newRecord @Student |> set #name " " |> set #email "ana.com"
            validarStudent student `shouldBe` [CampoVazio "name", EmailInvalido "ana.com"]
            validarStudent (student |> set #name "Ana" |> set #email "ana@unifor.br")
                `shouldBe` []
        it "valida carga horária do curso" do
            let course = newRecord @Course |> set #name "Haskell" |> set #workload 0
            validarCourse course `shouldBe` [CargaHorariaInvalida 0]

    describe "coleções (list comprehensions)" do
        let ana    = newRecord @Student |> set #id "11111111-1111-1111-1111-111111111111" |> set #name "Ana"
            bruno  = newRecord @Student |> set #id "22222222-2222-2222-2222-222222222222" |> set #name "Bruno"
            curso  = newRecord @Course  |> set #id "33333333-3333-3333-3333-333333333333" |> set #name "Haskell"
            matAna   = newRecord @Enrollment
                |> set #id "44444444-4444-4444-4444-444444444444"
                |> set #studentId ana.id |> set #courseId curso.id |> set #status Ativa
            matBruno = newRecord @Enrollment
                |> set #id "55555555-5555-5555-5555-555555555555"
                |> set #studentId bruno.id |> set #courseId curso.id |> set #status Trancada
            notaAna   = nota 8 9 Nothing |> set #enrollmentId matAna.id
            notaBruno = nota 3 3 Nothing |> set #enrollmentId matBruno.id
            linhas = boletim [ana, bruno] [matAna, matBruno] [notaAna, notaBruno]

        it "monta o boletim cruzando alunos, matrículas e notas" do
            map (\(nome, _, situacao) -> (nome, situacao)) linhas
                `shouldBe` [("Ana", Aprovado), ("Bruno", Trancado)]
        it "filtra os aprovados" do
            nomesAprovados linhas `shouldBe` ["Ana"]
        it "conta matrículas ativas por curso" do
            matriculasAtivasPorCurso [curso] [matAna, matBruno] `shouldBe` [("Haskell", 1)]

    describe "mediaDaTurma (recursão em cauda)" do
        it "calcula a média" do
            mediaDaTurma [6, 8, 10] `shouldBe` Just 8
        it "turma vazia não tem média" do
            mediaDaTurma [] `shouldBe` Nothing
