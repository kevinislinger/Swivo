#!/bin/bash

# Test script for Swivo Supabase Backend
# This script tests the core functionality of our deployed backend

# Configuration
SUPABASE_URL="https://rpexzovoebhnmvusjiug.supabase.co"  # Your Supabase URL (e.g., https://your-project-id.supabase.co)
SUPABASE_KEY="sb_publishable_uUADlx_py43dMTqtrW1ttQ_qgv70j-4"  # Your Supabase anon/public key

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Check if URL and key are provided
if [ -z "$SUPABASE_URL" ] || [ -z "$SUPABASE_KEY" ]; then
  echo -e "${RED}Error: Please set SUPABASE_URL and SUPABASE_KEY in the script.${NC}"
  exit 1
fi

# Helper function to print test results
test_result() {
  if [ $1 -eq 0 ]; then
    echo -e "${GREEN}✅ $2 passed${NC}"
  else
    echo -e "${RED}❌ $2 failed${NC}"
    if [ ! -z "$3" ]; then
      echo -e "${RED}Error: $3${NC}"
    fi
  fi
}

echo "=== Testing Swivo Backend ==="
echo "Supabase URL: $SUPABASE_URL"
echo "============================"

# Test 1: Anonymous authentication
echo -e "\n${YELLOW}[Test 1] Anonymous authentication${NC}"

AUTH_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}')

ACCESS_TOKEN=$(echo $AUTH_RESPONSE | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN" ]; then
  test_result 1 "Anonymous authentication" "Could not get access token"
  echo "Response: $AUTH_RESPONSE"
else
  test_result 0 "Anonymous authentication"
  echo "Access token: ${ACCESS_TOKEN:0:15}..." # Only show part of the token for security
fi

# Test 2: Fetch categories
echo -e "\n${YELLOW}[Test 2] Fetch categories${NC}"

CATEGORIES_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/categories?select=*" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

CATEGORIES_COUNT=$(echo $CATEGORIES_RESPONSE | grep -o "\"id\"" | wc -l)

if [ $CATEGORIES_COUNT -gt 0 ]; then
  test_result 0 "Fetch categories" 
  echo "Found $CATEGORIES_COUNT categories"
else
  test_result 1 "Fetch categories" "No categories found"
fi

# Save the first category ID for later use
CATEGORY_ID=$(echo $CATEGORIES_RESPONSE | grep -o '"id":"[^"]*' | head -1 | cut -d'"' -f4)
echo "Using category ID: $CATEGORY_ID"

# Test 3: Test create_session function
echo -e "\n${YELLOW}[Test 3] Create session${NC}"

CREATE_SESSION_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_session" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"p_category_id\": \"$CATEGORY_ID\", \"p_quorum_n\": 2}")

SESSION_ID=$(echo $CREATE_SESSION_RESPONSE | grep -o '"session_id":"[^"]*' | cut -d'"' -f4)
INVITE_CODE=$(echo $CREATE_SESSION_RESPONSE | grep -o '"invite_code":"[^"]*' | cut -d'"' -f4)

if [ -z "$SESSION_ID" ] || [ -z "$INVITE_CODE" ]; then
  test_result 1 "Create session" "Could not create session"
  echo "Response: $CREATE_SESSION_RESPONSE"
else
  test_result 0 "Create session"
  echo "Session ID: $SESSION_ID"
  echo "Invite code: $INVITE_CODE"
fi

# Test 4: Check if user was added as a participant
echo -e "\n${YELLOW}[Test 4] Check session participants${NC}"

PARTICIPANTS_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/session_participants?select=*&session_id=eq.$SESSION_ID" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

PARTICIPANT_COUNT=$(echo $PARTICIPANTS_RESPONSE | grep -o "\"user_id\"" | wc -l)

if [ $PARTICIPANT_COUNT -gt 0 ]; then
  test_result 0 "Check session participants" 
  echo "Found $PARTICIPANT_COUNT participant(s)"
else
  test_result 1 "Check session participants" "No participants found"
fi

# Test 5: Get session options
echo -e "\n${YELLOW}[Test 5] Get session options${NC}"

SESSION_OPTIONS_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/session_options?select=option_id,order_index&session_id=eq.$SESSION_ID" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN")

OPTIONS_COUNT=$(echo $SESSION_OPTIONS_RESPONSE | grep -o "\"option_id\"" | wc -l)

if [ $OPTIONS_COUNT -gt 0 ]; then
  test_result 0 "Get session options" 
  echo "Found $OPTIONS_COUNT options"
  
  # Save the first option ID for like test
  OPTION_ID=$(echo $SESSION_OPTIONS_RESPONSE | grep -o '"option_id":"[^"]*' | head -1 | cut -d'"' -f4)
  echo "Using option ID: $OPTION_ID"
else
  test_result 1 "Get session options" "No options found"
  OPTION_ID=""
fi

# Test 6: Test liking an option
if [ ! -z "$OPTION_ID" ]; then
  echo -e "\n${YELLOW}[Test 6] Like option${NC}"
  
  LIKE_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/like_option" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"p_session_id\": \"$SESSION_ID\", \"p_option_id\": \"$OPTION_ID\"}")
  
  LIKE_SUCCESS=$(echo $LIKE_RESPONSE | grep -o '"success":[^,}]*' | cut -d':' -f2)
  
  if [ "$LIKE_SUCCESS" = "true" ]; then
    test_result 0 "Like option"
    
    # Check match status
    MATCH_FOUND=$(echo $LIKE_RESPONSE | grep -o '"match_found":[^,}]*' | cut -d':' -f2)
    echo "Match found: $MATCH_FOUND (should be false since only one user has liked)"
  else
    test_result 1 "Like option" "Could not like option"
    echo "Response: $LIKE_RESPONSE"
  fi
else
  echo -e "\n${YELLOW}[Test 6] Like option - Skipped (no option ID available)${NC}"
fi

# Test 7: Join session with a second user to test matching
echo -e "\n${YELLOW}[Test 7] Create second user for testing${NC}"

AUTH_RESPONSE_2=$(curl -s -X POST "$SUPABASE_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Content-Type: application/json" \
  -d '{}')

ACCESS_TOKEN_2=$(echo $AUTH_RESPONSE_2 | grep -o '"access_token":"[^"]*' | cut -d'"' -f4)

if [ -z "$ACCESS_TOKEN_2" ]; then
  test_result 1 "Create second user" "Could not get access token"
  echo "Response: $AUTH_RESPONSE_2"
else
  test_result 0 "Create second user"
  echo "Second user access token: ${ACCESS_TOKEN_2:0:15}..." # Only show part of the token for security

  # Test joining session
  echo -e "\n${YELLOW}[Test 8] Join session with second user${NC}"
  
  JOIN_RESPONSE=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/join_session" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN_2" \
    -H "Content-Type: application/json" \
    -d "{\"p_invite_code\": \"$INVITE_CODE\"}")
  
  JOIN_SUCCESS=$(echo $JOIN_RESPONSE | grep -o '"success":[^,}]*' | cut -d':' -f2)
  
  if [ "$JOIN_SUCCESS" = "true" ]; then
    test_result 0 "Join session"
    
    # Check if second user was added as participant
    PARTICIPANTS_RESPONSE_2=$(curl -s -X GET "$SUPABASE_URL/rest/v1/session_participants?select=*&session_id=eq.$SESSION_ID" \
      -H "apikey: $SUPABASE_KEY" \
      -H "Authorization: Bearer $ACCESS_TOKEN_2")
    
    PARTICIPANT_COUNT_2=$(echo $PARTICIPANTS_RESPONSE_2 | grep -o "\"user_id\"" | wc -l)
    
    if [ $PARTICIPANT_COUNT_2 -gt 1 ]; then
      echo "Session now has $PARTICIPANT_COUNT_2 participants"
      
      # Test the matching algorithm by having the second user like the same option
      if [ ! -z "$OPTION_ID" ]; then
        echo -e "\n${YELLOW}[Test 9] Test match algorithm - Second user likes same option${NC}"
        
        LIKE_RESPONSE_2=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/like_option" \
          -H "apikey: $SUPABASE_KEY" \
          -H "Authorization: Bearer $ACCESS_TOKEN_2" \
          -H "Content-Type: application/json" \
          -d "{\"p_session_id\": \"$SESSION_ID\", \"p_option_id\": \"$OPTION_ID\"}")
        
        MATCH_FOUND_2=$(echo $LIKE_RESPONSE_2 | grep -o '"match_found":[^,}]*' | cut -d':' -f2)
        
        if [ "$MATCH_FOUND_2" = "true" ]; then
          test_result 0 "Match algorithm" 
          echo "Match found! Trigger worked correctly."
          
          # Check if session status was updated
          SESSION_STATUS=$(curl -s -X GET "$SUPABASE_URL/rest/v1/sessions?select=status&id=eq.$SESSION_ID" \
            -H "apikey: $SUPABASE_KEY" \
            -H "Authorization: Bearer $ACCESS_TOKEN_2")
          
          echo "Session status: $SESSION_STATUS"
        else
          test_result 1 "Match algorithm" "No match found when it should have been"
          echo "Response: $LIKE_RESPONSE_2"
        fi
      fi
    else
      test_result 1 "Session participants check" "Second user not added as participant"
    fi
  else
    test_result 1 "Join session" "Could not join session"
    echo "Response: $JOIN_RESPONSE"
  fi
fi

# Test final: Create a session with a different category to test RLS policies
echo -e "\n${YELLOW}[Test 10] RLS test - Create another session with different category${NC}"

# Get a different category ID
CATEGORY_ID_2=$(echo $CATEGORIES_RESPONSE | grep -o '"id":"[^"]*' | tail -1 | cut -d'"' -f4)
echo "Using different category ID: $CATEGORY_ID_2"

CREATE_SESSION_RESPONSE_2=$(curl -s -X POST "$SUPABASE_URL/rest/v1/rpc/create_session" \
  -H "apikey: $SUPABASE_KEY" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"p_category_id\": \"$CATEGORY_ID_2\", \"p_quorum_n\": 3}")

SESSION_ID_2=$(echo $CREATE_SESSION_RESPONSE_2 | grep -o '"session_id":"[^"]*' | cut -d'"' -f4)
INVITE_CODE_2=$(echo $CREATE_SESSION_RESPONSE_2 | grep -o '"invite_code":"[^"]*' | cut -d'"' -f4)

if [ -z "$SESSION_ID_2" ] || [ -z "$INVITE_CODE_2" ]; then
  test_result 1 "Create second session" "Could not create second session"
else
  test_result 0 "Create second session"
  echo "Second session ID: $SESSION_ID_2"
  
  # Try to access first user's session with second user when not a participant
  echo -e "\n${YELLOW}[Test 11] RLS policy test${NC}"
  
  RLS_TEST_RESPONSE=$(curl -s -X GET "$SUPABASE_URL/rest/v1/session_options?select=*&session_id=eq.$SESSION_ID_2" \
    -H "apikey: $SUPABASE_KEY" \
    -H "Authorization: Bearer $ACCESS_TOKEN_2")
  
  if [ "$RLS_TEST_RESPONSE" = "[]" ]; then
    test_result 0 "RLS policy"
    echo "Second user cannot access first user's session options until they join - RLS working correctly"
  else
    test_result 1 "RLS policy" "Second user can access session they didn't join"
    echo "Response: $RLS_TEST_RESPONSE"
  fi
fi

echo -e "\n${GREEN}===== Testing completed =====${NC}"
