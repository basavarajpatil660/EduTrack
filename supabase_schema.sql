-- SUPABASE SQL SCHEMA FOR EDUTRACK

-- 1. USERS TABLE (if not already created)
CREATE TABLE IF NOT EXISTS public.users (
    id UUID REFERENCES auth.users(id) ON DELETE CASCADE PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('student', 'teacher')),
    class TEXT,
    semester INTEGER
);

-- Enable RLS for users
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

-- 2. SUBJECTS TABLE
CREATE TABLE IF NOT EXISTS public.subjects (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    code TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    teacher_id UUID REFERENCES public.users(id) ON DELETE SET NULL,
    semester INTEGER NOT NULL
);

ALTER TABLE public.subjects ENABLE ROW LEVEL SECURITY;

-- 3. ATTENDANCE TABLE
CREATE TABLE IF NOT EXISTS public.attendance (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE NOT NULL,
    date DATE NOT NULL DEFAULT CURRENT_DATE,
    status TEXT NOT NULL CHECK (status IN ('present', 'absent')),
    UNIQUE(student_id, subject_id, date) -- prevent duplicate attendance for same subject on same date
);

ALTER TABLE public.attendance ENABLE ROW LEVEL SECURITY;

-- 4. MARKS TABLE
CREATE TABLE IF NOT EXISTS public.marks (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    student_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    subject_id UUID REFERENCES public.subjects(id) ON DELETE CASCADE NOT NULL,
    internal INTEGER DEFAULT 0,
    external INTEGER DEFAULT 0,
    total INTEGER DEFAULT 0,
    UNIQUE(student_id, subject_id)
);

ALTER TABLE public.marks ENABLE ROW LEVEL SECURITY;

-- 5. NOTICES TABLE (Missing as per prompt)
CREATE TABLE IF NOT EXISTS public.notices (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title TEXT NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.notices ENABLE ROW LEVEL SECURITY;

-- 6. TEACHER ACTIVITY TABLE (Missing as per prompt)
CREATE TABLE IF NOT EXISTS public.teacher_activity (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    teacher_id UUID REFERENCES public.users(id) ON DELETE CASCADE NOT NULL,
    action TEXT NOT NULL,
    target TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.teacher_activity ENABLE ROW LEVEL SECURITY;

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- USERS Table Policies
-- Teachers can view all users. Students can only view themselves and teachers.
CREATE POLICY "Users can view themselves" ON public.users FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Teachers can view all users" ON public.users FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);
CREATE POLICY "Students can view teachers" ON public.users FOR SELECT USING (role = 'teacher');

-- SUBJECTS Table Policies
-- Everyone can view subjects
CREATE POLICY "Everyone can view subjects" ON public.subjects FOR SELECT USING (true);

-- ATTENDANCE Table Policies
-- Students can only view their own attendance
CREATE POLICY "Students can view their own attendance" ON public.attendance FOR SELECT USING (
    student_id = auth.uid()
);

-- Teachers can view, insert, and update all attendance
CREATE POLICY "Teachers can view all attendance" ON public.attendance FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can insert attendance" ON public.attendance FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can update attendance" ON public.attendance FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

-- MARKS Table Policies
-- Students can only view their own marks
CREATE POLICY "Students can view their own marks" ON public.marks FOR SELECT USING (
    student_id = auth.uid()
);

-- Teachers can view, insert, and update all marks
CREATE POLICY "Teachers can view all marks" ON public.marks FOR SELECT USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can insert marks" ON public.marks FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can update marks" ON public.marks FOR UPDATE USING (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

-- NOTICES Table Policies
-- Everyone can view notices
CREATE POLICY "Everyone can view notices" ON public.notices FOR SELECT USING (true);

-- TEACHER ACTIVITY Table Policies
-- Teachers can only view their own activity
CREATE POLICY "Teachers can view their own activity" ON public.teacher_activity FOR SELECT USING (
    teacher_id = auth.uid() AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);

CREATE POLICY "Teachers can insert their own activity" ON public.teacher_activity FOR INSERT WITH CHECK (
    teacher_id = auth.uid() AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
);
