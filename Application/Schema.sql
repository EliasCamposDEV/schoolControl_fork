-- Your database schema. Use the Schema Designer at http://localhost:8001/ to add some tables.
CREATE TYPE enrollment_status AS ENUM ('ativa', 'trancada', 'concluida');

CREATE TABLE students (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE courses (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    name TEXT NOT NULL,
    workload INT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

CREATE TABLE enrollments (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    student_id UUID NOT NULL,
    course_id UUID NOT NULL,
    status enrollment_status DEFAULT 'ativa' NOT NULL
);

-- AVn = 70% PE(prova escrita) + 30% AVf(avaliação formativa).
-- pe3/avf3 são opcionais: a AV3 só é lançada se a média de AV1 e AV2 for >= 4,0.
CREATE TABLE grades (
    id UUID DEFAULT uuid_generate_v4() PRIMARY KEY NOT NULL,
    enrollment_id UUID NOT NULL,
    pe1 DOUBLE PRECISION NOT NULL,
    avf1 DOUBLE PRECISION NOT NULL,
    pe2 DOUBLE PRECISION NOT NULL,
    avf2 DOUBLE PRECISION NOT NULL,
    pe3 DOUBLE PRECISION DEFAULT NULL,
    avf3 DOUBLE PRECISION DEFAULT NULL
);

CREATE INDEX enrollments_student_id_index ON enrollments (student_id);
CREATE INDEX enrollments_course_id_index ON enrollments (course_id);
CREATE INDEX grades_enrollment_id_index ON grades (enrollment_id);

ALTER TABLE enrollments ADD CONSTRAINT enrollments_ref_student_id FOREIGN KEY (student_id) REFERENCES students (id) ON DELETE CASCADE;
ALTER TABLE enrollments ADD CONSTRAINT enrollments_ref_course_id FOREIGN KEY (course_id) REFERENCES courses (id) ON DELETE CASCADE;
ALTER TABLE grades ADD CONSTRAINT grades_ref_enrollment_id FOREIGN KEY (enrollment_id) REFERENCES enrollments (id) ON DELETE CASCADE;
