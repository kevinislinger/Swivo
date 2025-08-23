# Swivo App - Development Plan

This document outlines a step-by-step approach to implementing the Swivo application, starting with the backend and then moving to the iOS app.

## Phase 1: Backend Implementation (Supabase)

### Step 1: Initial Supabase Setup
- [x] Create Supabase project
- [x] Configure project settings and environment variables
- [x] Set up version control for Supabase migrations

### Step 2: Database Schema Implementation
- [x] Create `users` table (id, username, apns_token, created_at)
- [x] Create `categories` table (id, name, icon_url)
- [x] Create `sessions` table (id, creator_id, category_id, quorum_n, status, matched_option_id, invite_code, created_at)
- [x] Create `session_participants` table (session_id, user_id, joined_at)
- [x] Create `options` table (id, category_id, label, image_url)
- [x] Create `session_options` table (session_id, option_id, order_index)
- [x] Create `likes` table (id, session_id, option_id, user_id, created_at)
- [x] Set up foreign key constraints and indexes

### Step 3: Authentication and Security
- [x] Configure anonymous authentication
- [x] Set up Row Level Security (RLS) policies for each table
- [x] Implement session membership validation checks

### Step 4: Database Triggers and Functions
- [x] Create trigger for preventing session join when full
- [x] Implement matching algorithm trigger on likes table
- [x] Create helper functions for session creation and management

### Step 5: Edge Functions Implementation
- [x] Implement `like_option` function
- [x] Create `update_apns_token` function
- [x] Develop `notify_match` function for push notifications
- [ ] Test edge functions with mock data

### Step 6: Seed Data and Testing
- [x] Create seed data for categories and options
- [x] Apply database migrations 
- [x] Deploy edge functions
- [x] Document API endpoints and functions
- [ ] Test database constraints and triggers
- [ ] Verify edge functions work correctly

## Phase 2: iOS App Implementation

### Step 1: Project Setup
- [x] Create Xcode project structure
- [x] Set up folder structure following the project structure
- [x] Define core data models
- [ ] Configure build settings and deployment targets (iOS 17+)
- [ ] Add required dependencies (Supabase Swift SDK)

### Step 2: Core Infrastructure
- [x] Implement Supabase client configuration
- [x] Create networking layer for API calls
- [x] Set up authentication service
- [x] Create session management service
- [ ] Implement push notification handling
- [x] Create data models matching the backend schema

### Step 3: Feature Implementation - Landing Screen
- [ ] Create UI for Open Sessions list
- [ ] Implement session refresh logic
- [ ] Add navigation to Start Session and Join Session
- [ ] Implement session cell UI components

### Step 4: Feature Implementation - Session Management
- [ ] Implement Start Session flow
  - [ ] Category selection UI
  - [ ] Quorum setting UI
  - [ ] Invite code generation and sharing
- [ ] Implement Join Session flow
  - [ ] Invite code input UI
  - [ ] Session validation logic
  - [ ] Error handling for full or closed sessions

### Step 5: Feature Implementation - Swipe Deck
- [ ] Create card UI for options
- [ ] Implement swipe gestures and animations
- [ ] Add like/dislike functionality
- [ ] Connect to backend for recording likes
- [ ] Implement match detection and navigation

### Step 6: Feature Implementation - Results & History
- [ ] Create Results screen showing matched option
- [ ] Implement Closed Sessions list
- [ ] Add session history viewing functionality

### Step 7: Settings & Profile
- [ ] Implement username setting
- [ ] Add push notification preferences
- [ ] Create user profile management

### Step 8: Polish and Testing
- [ ] Add app icons and splash screen
- [ ] Implement error handling and retry mechanisms
- [ ] Add loading states and animations
- [ ] Implement offline mode and sync queue
- [ ] Create unit tests for core functionality
- [ ] Perform UI testing

## Phase 3: Integration and Deployment

### Step 1: CI/CD Setup
- [x] Create GitHub Actions workflow for Supabase deployment
- [ ] Configure required secrets in GitHub repository
- [ ] Set up iOS CI pipeline

### Step 2: End-to-End Testing
- [ ] Test complete user flows with real backend
- [ ] Verify push notifications work correctly
- [ ] Test edge cases (network issues, app backgrounding)

### Step 3: Performance Optimization
- [ ] Optimize database queries
- [ ] Improve app loading and response times
- [ ] Reduce network requests

### Step 4: Deployment Preparation
- [ ] Configure production environments
- [ ] Set up APNs certificates for production
- [ ] Prepare App Store assets and screenshots

### Step 5: Documentation
- [ ] Complete API documentation
- [ ] Document known issues and limitations
- [ ] Create user guide or help documentation

### Step 6: Launch
- [ ] Deploy Supabase production instance
- [ ] Submit app to App Store
- [ ] Monitor initial usage and address issues
