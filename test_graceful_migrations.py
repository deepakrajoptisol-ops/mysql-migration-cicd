#!/usr/bin/env python3
"""
Test script to verify graceful migration handling works correctly.
"""

import os
import tempfile
from src.migrate.policy import should_handle_gracefully

def test_graceful_config():
    """Test that graceful handling configuration works."""
    
    # Test default (should be True)
    if 'GRACEFUL_MIGRATIONS' in os.environ:
        del os.environ['GRACEFUL_MIGRATIONS']
    assert should_handle_gracefully() == True, "Default should be graceful"
    
    # Test explicit True
    os.environ['GRACEFUL_MIGRATIONS'] = 'true'
    assert should_handle_gracefully() == True, "Explicit true should work"
    
    # Test explicit False
    os.environ['GRACEFUL_MIGRATIONS'] = 'false'
    assert should_handle_gracefully() == False, "Explicit false should work"
    
    # Test case insensitive
    os.environ['GRACEFUL_MIGRATIONS'] = 'TRUE'
    assert should_handle_gracefully() == True, "Case insensitive should work"
    
    print("✅ All graceful migration configuration tests passed!")

if __name__ == "__main__":
    test_graceful_config()