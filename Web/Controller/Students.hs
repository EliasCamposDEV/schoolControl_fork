module Web.Controller.Students where

import Web.Controller.Prelude
import Web.View.Students.Index
import Web.View.Students.New
import Web.View.Students.Edit
import Web.View.Students.Show

instance Controller StudentsController where
    action StudentsAction = do
        students <- query @Student |> fetch
        render IndexView { .. }

    action NewStudentAction = do
        let student = newRecord
        render NewView { .. }

    action ShowStudentAction { studentId } = do
        student <- fetch studentId
        render ShowView { .. }

    action EditStudentAction { studentId } = do
        student <- fetch studentId
        render EditView { .. }

    action UpdateStudentAction { studentId } = do
        student <- fetch studentId
        student
            |> buildStudent
            |> ifValid \case
                Left student -> render EditView { .. }
                Right student -> do
                    student <- student |> updateRecord
                    setSuccessMessage "Student updated"
                    redirectTo EditStudentAction { .. }

    action CreateStudentAction = do
        let student = newRecord @Student
        student
            |> buildStudent
            |> ifValid \case
                Left student -> render NewView { .. } 
                Right student -> do
                    student <- student |> createRecord
                    setSuccessMessage "Student created"
                    redirectTo StudentsAction

    action DeleteStudentAction { studentId } = do
        student <- fetch studentId
        deleteRecord student
        setSuccessMessage "Student deleted"
        redirectTo StudentsAction

buildStudent student = student
    |> fill @'["name", "email"]
    |> validateField #name nonEmpty
    |> validateField #email nonEmpty
    |> validateField #email isEmail
