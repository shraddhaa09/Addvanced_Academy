# Addvanced Academy

A Flutter-based smart learning platform designed for MHT-CET preparation, providing dedicated dashboards for Students, Faculty, and Administrators.

The platform enables content delivery, video lectures, study materials, announcements, schedule management, and academic interactions through a role-based architecture powered by Supabase.

## Project Type

Academic Team Project

This project was developed as part of a college software development course. Multiple team members contributed to different modules of the application.

## My Contribution

I was primarily responsible for designing, developing, integrating, and maintaining the Faculty Module.

### Features Implemented

#### Faculty Dashboard

* Faculty landing dashboard
* Quick access actions
* Recent uploads section
* Statistics and activity overview

#### Study Material Management

* Upload study materials
* Edit uploaded content
* Visibility controls
* Upload history tracking
* Material browsing and filtering

#### Video Lecture Management

* Upload video lectures
* Video metadata management
* Visibility toggling
* Upload validation
* Upload progress tracking

#### Faculty Profile Management

* Faculty profile display
* Personal details management
* Qualification and profile updates

#### Schedule & Academic Management

* Faculty schedule view
* Subject assignment view
* Timetable integration

#### Support System

* Faculty help and support screen
* FAQ and support workflow

#### State Management & Architecture

* Riverpod-based state management
* Service-layer architecture
* Reusable widgets and UI components
* Model-driven data layer

## Technical Contributions

### Firebase Crashlytics Integration

Implemented production-ready crash monitoring:

* Flutter framework error capture
* Uncaught async error capture
* Firebase Crashlytics reporting
* Production monitoring support

### Upload Deduplication System

Implemented duplicate-content prevention:

* Duplicate video detection
* Duplicate material detection
* Custom exception handling
* User-friendly error feedback
* Supabase validation checks

### Recent Upload Navigation

Implemented interactive dashboard uploads:

* Clickable recent uploads
* Direct video navigation
* Direct material navigation
* GoRouter integration
* Improved faculty workflow

### Connectivity Monitoring

Implemented global connectivity awareness:

* Real-time offline detection
* Global connectivity banner
* Non-intrusive user feedback

## Architecture

The Faculty Module follows a layered architecture:

* Presentation Layer (Screens & Widgets)
* State Layer (Riverpod Providers)
* Service Layer (Business Logic)
* Data Layer (Supabase)
* Model Layer (Typed Data Models)

## Technology Stack

### Frontend

* Flutter
* Dart

### State Management

* Riverpod

### Navigation

* GoRouter

### Backend

* Supabase Authentication
* Supabase Database
* Supabase Storage

### Media Handling

* Video Player
* Chewie
* PDF Viewer

### Monitoring

* Firebase Crashlytics

## Faculty Module Components

### Screens

* Faculty Dashboard
* Materials Management
* Upload Material
* Upload Video
* Upload History
* Faculty Profile
* Personal Details
* Faculty Schedule
* Faculty Subjects
* Faculty Announcements
* Support Center
* Material Viewer
* Video Player

### Services

* FacultyService
* FacultyUploadService

### Models

* FacultyModel
* FacultyUploadModel

### Widgets

* FacultyScaffold
* RecentUploadTile
* UploadProgressWidget
* StatCard
* UploadCard

## Key Highlights

* Role-based architecture
* Faculty content management
* Video and document uploads
* Dashboard analytics
* Upload validation
* Error monitoring
* Responsive Flutter UI
* Supabase integration
* Riverpod state management

## Note

This repository represents a collaborative academic project. The Faculty Module and related functionality listed above were my primary areas of contribution and ownership.
