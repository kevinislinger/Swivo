# Swivo App - Development Plan

This document outlines a step-by-step approach to implementing the Swivo application, starting with the backend and then moving to the iOS app.

## Phase 1: Backend Implementation (Supabase)

### Step 1: Initial Supabase Setup
- [x] Create Supabase project
- [ ] Configure project settings and environment variables
- [ ] Set up version control for Supabase migrations

### Step 2: Database Schema Implementation
- [ ] Create `users` table (id, username, apns_token, created_at)
- [ ] Create `categories` table (id, name, icon_url)
- [ ] Create `sessions` table (id, creator_id, category_id, quorum_n, status, matched_option_id, invite_code, created_at)
- [ ] Create `session_participants` table (session_id, user_id, joined_at)
- [ ] Create `options` table (id, category_id, label, image_url)
- [ ] Create `session_options` table (session_id, option_id, order_index)
- [ ] Create `likes` table (id, session_id, option_id, user_id, created_at)
- [ ] Set up foreign key constraints and indexes

### Step 3: Authentication and Security
- [ ] Configure anonymous authentication
- [ ] Set up Row Level Security (RLS) policies for each table
- [ ] Implement session membership validation checks

### Step 4: Database Triggers and Functions
- [ ] Create trigger for preventing session join when full
- [ ] Implement matching algorithm trigger on likes table
- [ ] Create helper functions for session creation and management

### Step 5: Edge Functions Implementation
- [ ] Implement `like_option` function
- [ ] Create `update_apns_token` function
- [ ] Develop `notify_match` function for push notifications
- [ ] Test edge functions with mock data

### Step 6: Seed Data and Testing
- [ ] Create seed data for categories and options
- [ ] Test database constraints and triggers
- [ ] Verify edge functions work correctly
- [ ] Document API endpoints and functions

## Phase 2: iOS App Implementation

### Step 1: Project Setup
- [ ] Create Xcode project with SwiftUI
- [ ] Set up folder structure following the project structure
- [ ] Configure build settings and deployment targets (iOS 17+)
- [ ] Add required dependencies (Supabase Swift SDK)

### Step 2: Core Infrastructure
- [ ] Implement Supabase client configuration
- [ ] Create networking layer for API calls
- [ ] Set up authentication service
- [ ] Implement push notification handling
- [ ] Create data models matching the backend schema

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

### Step 1: End-to-End Testing
- [ ] Test complete user flows with real backend
- [ ] Verify push notifications work correctly
- [ ] Test edge cases (network issues, app backgrounding)

### Step 2: Performance Optimization
- [ ] Optimize database queries
- [ ] Improve app loading and response times
- [ ] Reduce network requests

### Step 3: Deployment Preparation
- [ ] Configure production environments
- [ ] Set up APNs certificates for production
- [ ] Prepare App Store assets and screenshots

### Step 4: Documentation
- [ ] Complete API documentation
- [ ] Document known issues and limitations
- [ ] Create user guide or help documentation

### Step 5: Launch
- [ ] Deploy Supabase production instance
- [ ] Submit app to App Store
- [ ] Monitor initial usage and address issues
