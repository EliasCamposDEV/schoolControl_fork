module Web.Controller.Courses where

import Web.Controller.Prelude
import Web.View.Courses.Index
import Web.View.Courses.New
import Web.View.Courses.Edit
import Web.View.Courses.Show

instance Controller CoursesController where
    action CoursesAction = do
        courses <- query @Course |> fetch
        render IndexView { .. }

    action NewCourseAction = do
        let course = newRecord
        render NewView { .. }

    action ShowCourseAction { courseId } = do
        course <- fetch courseId
        render ShowView { .. }

    action EditCourseAction { courseId } = do
        course <- fetch courseId
        render EditView { .. }

    action UpdateCourseAction { courseId } = do
        course <- fetch courseId
        course
            |> buildCourse
            |> ifValid \case
                Left course -> render EditView { .. }
                Right course -> do
                    course <- course |> updateRecord
                    setSuccessMessage "Course updated"
                    redirectTo EditCourseAction { .. }

    action CreateCourseAction = do
        let course = newRecord @Course
        course
            |> buildCourse
            |> ifValid \case
                Left course -> render NewView { .. } 
                Right course -> do
                    course <- course |> createRecord
                    setSuccessMessage "Course created"
                    redirectTo CoursesAction

    action DeleteCourseAction { courseId } = do
        course <- fetch courseId
        deleteRecord course
        setSuccessMessage "Course deleted"
        redirectTo CoursesAction

buildCourse course = course
    |> fill @'["name", "workload"]
    |> validateField #name nonEmpty
