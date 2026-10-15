module Main where

import Test.Hspec
import IHP.Prelude
import IHP.ModelSupport (newRecord)
import Generated.Types
import Application.Domain
import System.IO (hSetEncoding, stdout, stderr, utf8)

-- Monta nota sem tocar no banco TESTEEES
nota :: Double -> Double -> Maybe Double -> Grade
nota av1 av2 av3 = newRecord @Grade
    |> set #pe1 av1 |> set #avf1 av1
    |> set #pe2 av2 |> set #avf2 av2
    |> set #pe3 av3 |> set #avf3 av3

main :: IO ()
main = do
    -- Os nomes dos testes têm acentos; garante UTF-8 mesmo em locale "C" (CI)
    hSetEncoding stdout utf8
    hSetEncoding stderr utf8
    hspec specs

specs :: Spec
specs = do
    describe "mediaPonderada (currying e closures)" do
        it "compõe a AV com 70% PE + 30% AVf" do
            comporAV 8 6 `shouldBe` 7.4
        it "mediaSimples é a mesma função com outros pesos" do
            mediaSimples 5 10 `shouldBe` 7.5
        it "a aplicação parcial pode ser guardada e reutilizada" do
            let pesoDobradoNaFormativa = mediaPonderada (Pesos 1 2)
            map (uncurry pesoDobradoNaFormativa) [(3, 6), (9, 0)] `shouldBe` [5, 3]

    describe "composição das notas" do
        let grade = newRecord @Grade
                |> set #pe1 8 |> set #avf1 6
                |> set #pe2 6 |> set #avf2 10
        it "calcula AV1, AV2 e a média parcial" do
            (notaAV1 grade, notaAV2 grade, mediaParcial grade) `shouldBe` (7.4, 7.2, 7.3)
        it "AV3 só existe quando PE3 e AVf3 foram lançadas" do
            notaAV3 grade `shouldBe` Nothing
            notaAV3 (grade |> set #pe3 (Just 5)) `shouldBe` Nothing
            notaAV3 (grade |> set #pe3 (Just 5) |> set #avf3 (Just 5)) `shouldBe` Just 5
        it "NF = (média parcial + AV3) / 2" do
            mediaFinal (nota 6 6 (Just 5)) `shouldBe` 5.5
            mediaFinal (nota 6 8 Nothing) `shouldBe` 7

    describe "classificarMedia (IMC adaptado)" do
        it "enquadra a média em faixas" do
            map classificarMedia [2, 5, 7, 8, 9.5]
                `shouldBe` [Insuficiente, Regular, Bom, Otimo, Excelente]

    describe "situacaoDaMatricula (pattern matching)" do
        it "reprova se a média de AV1 e AV2 for menor que 4" do
            situacaoDaMatricula Ativa (nota 3 3 Nothing) `shouldBe` Reprovado
        it "aguarda a AV3 enquanto ela não for lançada" do
            situacaoDaMatricula Ativa (nota 6 6 Nothing) `shouldBe` AguardandoAV3
        it "reprova se a AV3 for menor que 4" do
            situacaoDaMatricula Ativa (nota 6 6 (Just 3)) `shouldBe` Reprovado
        it "aprova com NF >= 5" do
            situacaoDaMatricula Ativa (nota 6 6 (Just 5)) `shouldBe` Aprovado
        it "reprova com NF < 5 mesmo com AV3 >= 4" do
            situacaoDaMatricula Ativa (nota 4 4 (Just 4)) `shouldBe` Reprovado
        it "matrícula trancada ignora as notas" do
            situacaoDaMatricula Trancada (nota 10 10 (Just 10)) `shouldBe` Trancado

    describe "validações" do
        it "aceita notas entre 0 e 10" do
            validarNota "pe1" 7 `shouldBe` Right 7
            validarNota "pe1" 11 `shouldBe` Left (NotaForaDoIntervalo "pe1" 11)
        it "valida todas as notas de uma Grade" do
            validarGrade (nota 7 7 Nothing |> set #pe2 (-1) |> set #pe3 (Just 12))
                `shouldBe` [NotaForaDoIntervalo "pe2" (-1), NotaForaDoIntervalo "pe3" 12]
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
            notaAna   = nota 8 9 (Just 7) |> set #enrollmentId matAna.id
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
