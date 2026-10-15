module Application.Domain
    (
      Pesos (..)
    , Situacao (..)
    , Conceito (..)
    , ErroValidacao (..)
    , mediaPonderada
    , pesosPadrao
    , comporAV
    , mediaSimples
    , notaAV1
    , notaAV2
    , notaAV3
    , mediaParcial
    , mediaFinal
    , notaMinimaParcial
    , notaMinimaAV3
    , notaMinimaFinal
    , classificarMedia
    , situacaoDaMatricula
    , validarNota
    , validarStudent
    , validarCourse
    , validarGrade
    , boletim
    , nomesAprovados
    , matriculasAtivasPorCurso
    , mediaDaTurma
    ) where

import IHP.Prelude
import Generated.Types
import qualified Data.Text as Text


-- Pesos da composição de uma AV: Prova Escrita (PE) e Avaliação Formativa (AVf).
data Pesos = Pesos
    { pesoProva     :: Double
    , pesoFormativa :: Double
    } deriving (Eq, Show)

-- Situação acadêmica de um aluno numa disciplina.
data Situacao
    = Aprovado
    | Reprovado
    | AguardandoAV3   -- média de AV1 e AV2 >= 4,0, mas AV3 ainda não foi lançada
    | Trancado
    deriving (Eq, Show)

-- Faixas de desempenho
data Conceito
    = Insuficiente
    | Regular
    | Bom
    | Otimo
    | Excelente
    deriving (Eq, Show, Ord, Enum, Bounded)

-- Tipo de erro de validação
data ErroValidacao
    = CampoVazio Text
    | EmailInvalido Text
    | NotaForaDoIntervalo Text Double
    | CargaHorariaInvalida Int
    deriving (Eq, Show)


-- Regras da disciplina
-- Média entre AV1 e AV2 abaixo disso: reprovação por nota.
notaMinimaParcial :: Double
notaMinimaParcial = 4.0

-- AV3 abaixo disso: reprovação por nota.
notaMinimaAV3 :: Double
notaMinimaAV3 = 4.0

-- Nota final (NF) a partir da qual o aluno é aprovado.
notaMinimaFinal :: Double
notaMinimaFinal = 5.0


-- Currying e closures

mediaPonderada :: Pesos -> Double -> Double -> Double
mediaPonderada Pesos { pesoProva, pesoFormativa } = \pe avf ->
    arredondar ((pe * pesoProva + avf * pesoFormativa) / (pesoProva + pesoFormativa))

-- PE vale 70%, AVf vale 30%.
pesosPadrao :: Pesos
pesosPadrao = Pesos { pesoProva = 0.7, pesoFormativa = 0.3 }

-- AVn = 70% PEn + 30% AVfn
comporAV :: Double -> Double -> Double
comporAV = mediaPonderada pesosPadrao

-- Média aritmética de dois valores (pesos iguais).
mediaSimples :: Double -> Double -> Double
mediaSimples = mediaPonderada (Pesos 1 1)

-- Arredonda para 2 casas decimais, evitando que erros de ponto flutuante
arredondar :: Double -> Double
arredondar x = fromIntegral (round (x * 100) :: Integer) / 100


-- Composição das AVs e da nota final
notaAV1 :: Grade -> Double
notaAV1 grade = comporAV grade.pe1 grade.avf1

notaAV2 :: Grade -> Double
notaAV2 grade = comporAV grade.pe2 grade.avf2

-- AV3 só existe depois que PE3 e AVf3 forem lançadas.
notaAV3 :: Grade -> Maybe Double
notaAV3 grade = comporAV <$> grade.pe3 <*> grade.avf3

-- (AV1 + AV2) / 2
mediaParcial :: Grade -> Double
mediaParcial grade = mediaSimples (notaAV1 grade) (notaAV2 grade)

-- NF = ((AV1 + AV2) / 2 + AV3) / 2.
-- Enquanto a AV3 não é lançada, devolve a média parcial.
mediaFinal :: Grade -> Double
mediaFinal grade = case notaAV3 grade of
    Nothing  -> mediaParcial grade
    Just av3 -> mediaSimples (mediaParcial grade) av3


-- Classificação
--   1. (AV1 + AV2) / 2 < 4,0            -> Reprovado
--   2. AV3 ainda não lançada            -> AguardandoAV3
--   3. AV3 < 4,0                        -> Reprovado
--   4. NF >= 5,0                        -> Aprovado
--   5. NF < 5,0                         -> Reprovado

classificarMedia :: Double -> Conceito
classificarMedia media
    | media < 4.0 = Insuficiente
    | media < 6.0 = Regular
    | media < 7.5 = Bom
    | media < 9.0 = Otimo
    | otherwise   = Excelente


situacaoDaMatricula :: EnrollmentStatus -> Grade -> Situacao
situacaoDaMatricula Trancada _ = Trancado
situacaoDaMatricula _ grade
    | mediaParcial grade < notaMinimaParcial = Reprovado
    | otherwise = case notaAV3 grade of
        Nothing -> AguardandoAV3
        Just av3
            | av3 < notaMinimaAV3                  -> Reprovado
            | mediaFinal grade >= notaMinimaFinal -> Aprovado
            | otherwise                            -> Reprovado


-- ---------------------------------------------------------------------------
-- Validações (funções puras que devolvem Either ou lista de erros)
-- ---------------------------------------------------------------------------

-- Uma nota é válida se estiver entre 0 e 10.
validarNota :: Text -> Double -> Either ErroValidacao Double
validarNota campo nota
    | nota >= 0 && nota <= 10 = Right nota
    | otherwise               = Left (NotaForaDoIntervalo campo nota)

validarStudent :: Student -> [ErroValidacao]
validarStudent student =
    [ CampoVazio "name" | Text.null (Text.strip student.name) ]
    <> [ EmailInvalido student.email | not (emailValido student.email) ]

validarCourse :: Course -> [ErroValidacao]
validarCourse course =
    [ CampoVazio "name" | Text.null (Text.strip course.name) ]
    <> [ CargaHorariaInvalida course.workload | course.workload <= 0 ]

-- Valida todas as notas parciais de uma vez
validarGrade :: Grade -> [ErroValidacao]
validarGrade grade = lefts
    ( [ validarNota "pe1"  grade.pe1
      , validarNota "avf1" grade.avf1
      , validarNota "pe2"  grade.pe2
      , validarNota "avf2" grade.avf2
      ]
    <> opcional "pe3"  grade.pe3
    <> opcional "avf3" grade.avf3
    )
  where
    opcional campo = maybe [] (\nota -> [validarNota campo nota])

-- Um e-mail precisa de exatamente um "@", com algo antes e um domínio com ponto depois.
emailValido :: Text -> Bool
emailValido email = case Text.splitOn "@" email of
    [usuario, dominio] -> not (Text.null usuario) && "." `Text.isInfixOf` dominio
    _                  -> False


-- Coleções: list comprehensions, pattern matching e recursão em cauda

boletim :: [Student] -> [Enrollment] -> [Grade] -> [(Text, Double, Situacao)]
boletim students enrollments grades =
    [ (student.name, mediaFinal grade, situacaoDaMatricula enrollment.status grade)
    | student    <- students
    , enrollment <- enrollments
    , enrollment.studentId == student.id
    , grade      <- grades
    , grade.enrollmentId == enrollment.id
    ]

nomesAprovados :: [(Text, Double, Situacao)] -> [Text]
nomesAprovados linhas = [ nome | (nome, _, Aprovado) <- linhas ]

matriculasAtivasPorCurso :: [Course] -> [Enrollment] -> [(Text, Int)]
matriculasAtivasPorCurso courses enrollments =
    [ (course.name, length ativas)
    | course <- courses
    , let ativas = [ e | e@Enrollment { status = Ativa } <- enrollments
                       , e.courseId == course.id ]
    ]

mediaDaTurma :: [Double] -> Maybe Double
mediaDaTurma = go 0 0
  where
    go :: Double -> Int -> [Double] -> Maybe Double
    go _ 0 [] = Nothing
    go !soma !qtd [] = Just (soma / fromIntegral qtd)
    go !soma !qtd (x:xs) = go (soma + x) (qtd + 1) xs