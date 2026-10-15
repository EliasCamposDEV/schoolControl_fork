module Web.Routes where
import IHP.RouterPrelude
import Generated.Types
import Web.Types

-- The welcome page at '/' is served by the static controller below.
-- Additional [routes|...|] blocks get appended by `new-controller`.
[routes|StaticController
GET /    WelcomeAction
|]

[routes|StudentsController
GET /Students StudentsAction
GET /NewStudent NewStudentAction
POST /CreateStudent CreateStudentAction
GET /ShowStudent?studentId ShowStudentAction
GET /EditStudent?studentId EditStudentAction
POST /UpdateStudent?studentId UpdateStudentAction
DELETE /DeleteStudent?studentId DeleteStudentAction
|]


[routes|CoursesController
GET /Courses CoursesAction
GET /NewCourse NewCourseAction
POST /CreateCourse CreateCourseAction
GET /ShowCourse?courseId ShowCourseAction
GET /EditCourse?courseId EditCourseAction
POST /UpdateCourse?courseId UpdateCourseAction
DELETE /DeleteCourse?courseId DeleteCourseAction
|]

