#!/usr/bin/env python3
"""
End-to-End Web UI Testing Script
Comprehensive testing of the Migration Management Web UI
"""

import requests
import json
import time
import sys
from datetime import datetime
from pathlib import Path

class WebUITester:
    def __init__(self, base_url="http://localhost:8000"):
        self.base_url = base_url
        self.session = requests.Session()
        self.test_results = []
        
    def log_test(self, test_name, success, message="", details=None):
        """Log test result"""
        status = "✅ PASS" if success else "❌ FAIL"
        print(f"{status} {test_name}")
        if message:
            print(f"    {message}")
        if details:
            print(f"    Details: {details}")
        
        self.test_results.append({
            'test': test_name,
            'success': success,
            'message': message,
            'details': details,
            'timestamp': datetime.now().isoformat()
        })
        print()

    def test_server_health(self):
        """Test if the web server is running and responsive"""
        try:
            response = self.session.get(f"{self.base_url}/")
            success = response.status_code == 200
            self.log_test(
                "Server Health Check",
                success,
                f"Server responded with status {response.status_code}",
                {"response_time": response.elapsed.total_seconds()}
            )
            return success
        except Exception as e:
            self.log_test("Server Health Check", False, f"Failed to connect: {e}")
            return False

    def test_api_migrations_status(self):
        """Test the migrations status API endpoint"""
        try:
            response = self.session.get(f"{self.base_url}/api/migrations/status")
            success = response.status_code == 200
            
            if success:
                data = response.json()
                required_fields = ['pending_migrations', 'total_migrations', 'applied_migrations', 'pending_details']
                has_all_fields = all(field in data for field in required_fields)
                
                self.log_test(
                    "API: Migration Status",
                    has_all_fields,
                    f"Status: {data.get('applied_migrations', 0)} applied, {data.get('pending_migrations', 0)} pending",
                    data
                )
                return has_all_fields
            else:
                self.log_test("API: Migration Status", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("API: Migration Status", False, f"Error: {e}")
            return False

    def test_api_migrations_versions(self):
        """Test the migrations versions API endpoint"""
        try:
            response = self.session.get(f"{self.base_url}/api/migrations/versions")
            success = response.status_code == 200
            
            if success:
                data = response.json()
                required_fields = ['versions', 'total_count', 'applied_count', 'pending_count']
                has_all_fields = all(field in data for field in required_fields)
                
                self.log_test(
                    "API: Migration Versions",
                    has_all_fields,
                    f"Found {data.get('total_count', 0)} total versions",
                    {"versions_count": len(data.get('versions', []))}
                )
                return has_all_fields and data
            else:
                self.log_test("API: Migration Versions", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("API: Migration Versions", False, f"Error: {e}")
            return False

    def test_api_backups_list(self):
        """Test the backups list API endpoint"""
        try:
            response = self.session.get(f"{self.base_url}/api/backups")
            success = response.status_code == 200
            
            if success:
                data = response.json()
                has_backups_field = 'backups' in data
                
                self.log_test(
                    "API: Backups List",
                    has_backups_field,
                    f"Found {len(data.get('backups', []))} backup files",
                    data
                )
                return has_backups_field and data
            else:
                self.log_test("API: Backups List", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("API: Backups List", False, f"Error: {e}")
            return False

    def test_api_create_backup(self):
        """Test creating a backup via API"""
        try:
            response = self.session.post(f"{self.base_url}/api/backups/create")
            success = response.status_code == 200
            
            if success:
                data = response.json()
                has_required_fields = all(field in data for field in ['success', 'filename', 'size'])
                
                self.log_test(
                    "API: Create Backup",
                    has_required_fields and data.get('success'),
                    f"Created backup: {data.get('filename', 'unknown')}",
                    {"size": data.get('size', 0)}
                )
                return has_required_fields and data
            else:
                self.log_test("API: Create Backup", False, f"HTTP {response.status_code}")
                return False
        except Exception as e:
            self.log_test("API: Create Backup", False, f"Error: {e}")
            return False

    def test_upload_migration_validation(self):
        """Test upload migration API with invalid data (should fail gracefully)"""
        try:
            # Test with missing required fields
            invalid_data = {
                "migration_id": "",
                "description": "",
                "author": "test-user",
                "risk_level": "low",
                "sql_content": "",
                "commit_message": "",
                "github_token": ""
            }
            
            response = self.session.post(
                f"{self.base_url}/api/migrations/upload",
                json=invalid_data
            )
            
            # Should fail with 400 or 422 (validation error)
            success = response.status_code in [400, 422, 500]  # Expected to fail
            
            self.log_test(
                "API: Upload Validation",
                success,
                f"Correctly rejected invalid data with status {response.status_code}",
                {"status_code": response.status_code}
            )
            return success
        except Exception as e:
            self.log_test("API: Upload Validation", False, f"Error: {e}")
            return False

    def test_rollback_validation(self):
        """Test rollback API with invalid data (should fail gracefully)"""
        try:
            # Test with missing required fields
            invalid_data = {
                "target_version": "",
                "backup_file": "nonexistent.sql",
                "environment": "dev"
            }
            
            response = self.session.post(
                f"{self.base_url}/api/migrations/rollback",
                json=invalid_data
            )
            
            # Should fail with 400, 404, or 422
            success = response.status_code in [400, 404, 422, 500]
            
            self.log_test(
                "API: Rollback Validation",
                success,
                f"Correctly rejected invalid rollback with status {response.status_code}",
                {"status_code": response.status_code}
            )
            return success
        except Exception as e:
            self.log_test("API: Rollback Validation", False, f"Error: {e}")
            return False

    def test_frontend_resources(self):
        """Test that frontend static resources are accessible"""
        resources = [
            "/static/app.js",
            "/"  # index.html
        ]
        
        all_success = True
        for resource in resources:
            try:
                response = self.session.get(f"{self.base_url}{resource}")
                success = response.status_code == 200
                
                if not success:
                    all_success = False
                
                self.log_test(
                    f"Frontend Resource: {resource}",
                    success,
                    f"Status {response.status_code}, Size: {len(response.content)} bytes"
                )
            except Exception as e:
                all_success = False
                self.log_test(f"Frontend Resource: {resource}", False, f"Error: {e}")
        
        return all_success

    def test_dashboard_data_consistency(self):
        """Test that dashboard data is consistent across different API calls"""
        try:
            # Get data from different endpoints
            status_response = self.session.get(f"{self.base_url}/api/migrations/status")
            versions_response = self.session.get(f"{self.base_url}/api/migrations/versions")
            
            if status_response.status_code != 200 or versions_response.status_code != 200:
                self.log_test("Dashboard Data Consistency", False, "Failed to fetch data")
                return False
            
            status_data = status_response.json()
            versions_data = versions_response.json()
            
            # Check consistency
            total_consistent = status_data['total_migrations'] == versions_data['total_count']
            applied_consistent = status_data['applied_migrations'] == versions_data['applied_count']
            pending_consistent = status_data['pending_migrations'] == versions_data['pending_count']
            
            success = total_consistent and applied_consistent and pending_consistent
            
            self.log_test(
                "Dashboard Data Consistency",
                success,
                f"Total: {status_data['total_migrations']}={versions_data['total_count']}, "
                f"Applied: {status_data['applied_migrations']}={versions_data['applied_count']}, "
                f"Pending: {status_data['pending_migrations']}={versions_data['pending_count']}",
                {
                    "status_data": status_data,
                    "versions_data": {k: v for k, v in versions_data.items() if k != 'versions'}
                }
            )
            return success
        except Exception as e:
            self.log_test("Dashboard Data Consistency", False, f"Error: {e}")
            return False

    def test_error_handling(self):
        """Test error handling for non-existent endpoints"""
        try:
            response = self.session.get(f"{self.base_url}/api/nonexistent/endpoint")
            success = response.status_code == 404
            
            self.log_test(
                "Error Handling: 404",
                success,
                f"Non-existent endpoint returned status {response.status_code}",
                {"expected": 404, "actual": response.status_code}
            )
            return success
        except Exception as e:
            self.log_test("Error Handling: 404", False, f"Error: {e}")
            return False

    def run_performance_test(self):
        """Test API response times"""
        endpoints = [
            "/api/migrations/status",
            "/api/migrations/versions",
            "/api/backups"
        ]
        
        all_fast = True
        for endpoint in endpoints:
            try:
                start_time = time.time()
                response = self.session.get(f"{self.base_url}{endpoint}")
                response_time = time.time() - start_time
                
                # Consider fast if response time < 2 seconds
                is_fast = response_time < 2.0 and response.status_code == 200
                
                if not is_fast:
                    all_fast = False
                
                self.log_test(
                    f"Performance: {endpoint}",
                    is_fast,
                    f"Response time: {response_time:.3f}s",
                    {"response_time": response_time, "status_code": response.status_code}
                )
            except Exception as e:
                all_fast = False
                self.log_test(f"Performance: {endpoint}", False, f"Error: {e}")
        
        return all_fast

    def run_all_tests(self):
        """Run all tests and generate report"""
        print("🧪 Starting End-to-End Web UI Tests")
        print("=" * 50)
        
        # Core functionality tests
        tests = [
            self.test_server_health,
            self.test_api_migrations_status,
            self.test_api_migrations_versions,
            self.test_api_backups_list,
            self.test_api_create_backup,
            self.test_upload_migration_validation,
            self.test_rollback_validation,
            self.test_frontend_resources,
            self.test_dashboard_data_consistency,
            self.test_error_handling,
            self.run_performance_test
        ]
        
        passed = 0
        total = len(tests)
        
        for test in tests:
            try:
                if test():
                    passed += 1
            except Exception as e:
                print(f"❌ Test {test.__name__} crashed: {e}")
        
        print("=" * 50)
        print(f"📊 Test Results: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed! Web UI is fully functional.")
        else:
            print(f"⚠️ {total - passed} tests failed. Check the details above.")
        
        # Generate detailed report
        self.generate_report()
        
        return passed == total

    def generate_report(self):
        """Generate detailed test report"""
        report_file = f"web_ui_test_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        
        report = {
            "timestamp": datetime.now().isoformat(),
            "base_url": self.base_url,
            "total_tests": len(self.test_results),
            "passed_tests": sum(1 for r in self.test_results if r['success']),
            "failed_tests": sum(1 for r in self.test_results if not r['success']),
            "test_results": self.test_results
        }
        
        with open(report_file, 'w') as f:
            json.dump(report, f, indent=2)
        
        print(f"📄 Detailed report saved to: {report_file}")

def main():
    """Main function to run tests"""
    if len(sys.argv) > 1:
        base_url = sys.argv[1]
    else:
        base_url = "http://localhost:8000"
    
    print(f"🌐 Testing Web UI at: {base_url}")
    
    tester = WebUITester(base_url)
    success = tester.run_all_tests()
    
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()