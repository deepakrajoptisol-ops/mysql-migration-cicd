// Migration Management System - Frontend JavaScript

class MigrationManager {
    constructor() {
        this.apiBase = '';
        this.loadingModal = new bootstrap.Modal(document.getElementById('loadingModal'));
        this.successModal = new bootstrap.Modal(document.getElementById('successModal'));
        this.errorModal = new bootstrap.Modal(document.getElementById('errorModal'));
        
        this.init();
    }

    async init() {
        // Load initial data
        await this.loadDashboardData();
        await this.loadVersions();
        await this.loadBackups();
        
        // Set up form handlers
        this.setupFormHandlers();
        
        // Auto-refresh every 30 seconds
        setInterval(() => this.loadDashboardData(), 30000);
    }

    setupFormHandlers() {
        // Upload form
        document.getElementById('uploadForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.uploadMigration();
        });

        // Rollback form
        document.getElementById('rollbackForm').addEventListener('submit', (e) => {
            e.preventDefault();
            this.executeRollback();
        });

        // Auto-fill commit message when migration ID or description changes
        const updateCommitMessage = () => {
            const id = document.getElementById('migrationId').value;
            const desc = document.getElementById('description').value;
            if (id && desc) {
                document.getElementById('commitMessage').value = `Add migration ${id}: ${desc}`;
            }
        };
        
        document.getElementById('migrationId').addEventListener('input', updateCommitMessage);
        document.getElementById('description').addEventListener('input', updateCommitMessage);
    }

    async apiCall(endpoint, options = {}) {
        try {
            const response = await fetch(this.apiBase + endpoint, {
                headers: {
                    'Content-Type': 'application/json',
                    ...options.headers
                },
                ...options
            });

            if (!response.ok) {
                const error = await response.json();
                throw new Error(error.detail || `HTTP ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('API call failed:', error);
            throw error;
        }
    }

    showLoading(message = 'Processing...') {
        document.getElementById('loadingMessage').textContent = message;
        this.loadingModal.show();
    }

    hideLoading() {
        this.loadingModal.hide();
    }

    showSuccess(message) {
        document.getElementById('successMessage').innerHTML = message;
        this.successModal.show();
    }

    showError(message) {
        document.getElementById('errorMessage').innerHTML = message;
        this.errorModal.show();
    }

    async loadDashboardData() {
        try {
            const [versionsData, statusData, backupsData] = await Promise.all([
                this.apiCall('/api/migrations/versions'),
                this.apiCall('/api/migrations/status'),
                this.apiCall('/api/backups')
            ]);

            // Update dashboard cards
            document.getElementById('appliedCount').textContent = versionsData.applied_count;
            document.getElementById('pendingCount').textContent = versionsData.pending_count;
            document.getElementById('totalCount').textContent = versionsData.total_count;
            document.getElementById('backupCount').textContent = backupsData.backups.length;

            // Enable/disable apply button
            const applyBtn = document.getElementById('applyBtn');
            if (statusData.pending_migrations > 0) {
                applyBtn.disabled = false;
                applyBtn.innerHTML = `<i class="fas fa-play"></i> Apply ${statusData.pending_migrations} Pending`;
            } else {
                applyBtn.disabled = true;
                applyBtn.innerHTML = '<i class="fas fa-check"></i> All Up to Date';
            }

            // Update next available ID
            const nextId = String(versionsData.total_count + 1).padStart(3, '0');
            const nextIdElement = document.getElementById('nextAvailableId');
            if (nextIdElement) {
                nextIdElement.textContent = nextId;
                document.getElementById('migrationId').value = nextId;
            }

        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        }
    }

    async loadVersions() {
        try {
            const data = await this.apiCall('/api/migrations/versions');
            this.renderVersionsTimeline(data.versions);
            this.populateRollbackVersions(data.versions);
        } catch (error) {
            console.error('Failed to load versions:', error);
            this.showError('Failed to load migration versions: ' + error.message);
        }
    }

    renderVersionsTimeline(versions) {
        const timeline = document.getElementById('versionsTimeline');
        timeline.innerHTML = '';

        if (versions.length === 0) {
            timeline.innerHTML = '<p class="text-muted">No migrations found.</p>';
            return;
        }

        versions.forEach(version => {
            const item = document.createElement('div');
            item.className = `timeline-item ${version.status}`;
            
            const statusIcon = version.status === 'applied' ? 'fa-check-circle text-success' :
                             version.status === 'pending' ? 'fa-clock text-warning' :
                             'fa-times-circle text-danger';

            const riskBadge = `<span class="badge risk-badge ${version.risk_level}">${version.risk_level.toUpperCase()}</span>`;
            
            const appliedDate = version.applied_at ? 
                new Date(version.applied_at).toLocaleString() : 'Not applied';

            const rollbackBtn = version.can_rollback_to ? 
                `<button class="btn btn-outline-danger btn-sm" onclick="migrationManager.prepareRollback('${version.id}')">
                    <i class="fas fa-undo"></i> Rollback to here
                </button>` : '';

            item.innerHTML = `
                <div class="card migration-card ${version.status}">
                    <div class="card-body">
                        <div class="d-flex justify-content-between align-items-start">
                            <div>
                                <h6 class="card-title">
                                    <i class="fas ${statusIcon}"></i>
                                    Migration ${version.id}: ${version.description}
                                </h6>
                                <p class="card-text text-muted mb-2">
                                    <small>
                                        <i class="fas fa-user"></i> ${version.author} | 
                                        <i class="fas fa-file"></i> ${version.filename} |
                                        <i class="fas fa-calendar"></i> ${appliedDate}
                                    </small>
                                </p>
                                <div class="d-flex align-items-center gap-2">
                                    ${riskBadge}
                                    <span class="badge bg-secondary">${version.status}</span>
                                </div>
                            </div>
                            <div>
                                ${rollbackBtn}
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            timeline.appendChild(item);
        });
    }

    populateRollbackVersions(versions) {
        const select = document.getElementById('targetVersion');
        select.innerHTML = '<option value="">Select version to rollback to...</option>';
        
        versions.filter(v => v.can_rollback_to).forEach(version => {
            const option = document.createElement('option');
            option.value = version.id;
            option.textContent = `${version.id} - ${version.description} (${version.author})`;
            select.appendChild(option);
        });
    }

    async loadBackups() {
        try {
            const data = await this.apiCall('/api/backups');
            this.renderBackupsTable(data.backups);
            this.populateBackupSelect(data.backups);
        } catch (error) {
            console.error('Failed to load backups:', error);
        }
    }

    renderBackupsTable(backups) {
        const tbody = document.getElementById('backupsTableBody');
        tbody.innerHTML = '';

        if (backups.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-muted">No backups found</td></tr>';
            return;
        }

        backups.forEach(backup => {
            const row = document.createElement('tr');
            const sizeFormatted = this.formatFileSize(backup.size);
            const dateFormatted = new Date(backup.created_at).toLocaleString();
            
            row.innerHTML = `
                <td><code>${backup.filename}</code></td>
                <td>${sizeFormatted}</td>
                <td>${dateFormatted}</td>
                <td><span class="badge bg-info">${backup.type}</span></td>
                <td>
                    <button class="btn btn-outline-primary btn-sm" onclick="migrationManager.useBackupForRollback('${backup.filename}')">
                        <i class="fas fa-undo"></i> Use for Rollback
                    </button>
                </td>
            `;
            
            tbody.appendChild(row);
        });
    }

    populateBackupSelect(backups) {
        const select = document.getElementById('backupFile');
        select.innerHTML = '<option value="">Select backup file...</option>';
        
        backups.forEach(backup => {
            const option = document.createElement('option');
            option.value = backup.filename;
            const sizeFormatted = this.formatFileSize(backup.size);
            const dateFormatted = new Date(backup.created_at).toLocaleDateString();
            option.textContent = `${backup.filename} (${sizeFormatted}, ${dateFormatted})`;
            select.appendChild(option);
        });
    }

    formatFileSize(bytes) {
        if (bytes === 0) return '0 Bytes';
        const k = 1024;
        const sizes = ['Bytes', 'KB', 'MB', 'GB'];
        const i = Math.floor(Math.log(bytes) / Math.log(k));
        return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
    }

    async uploadMigration() {
        const formData = {
            migration_id: document.getElementById('migrationId').value,
            description: document.getElementById('description').value,
            author: document.getElementById('author').value,
            risk_level: document.getElementById('riskLevel').value,
            sql_content: document.getElementById('sqlContent').value,
            commit_message: document.getElementById('commitMessage').value,
            github_token: document.getElementById('githubToken').value
        };

        // Validate form
        if (!formData.migration_id || !formData.description || !formData.sql_content || !formData.github_token) {
            this.showError('Please fill in all required fields.');
            return;
        }

        try {
            this.showLoading('Uploading migration to GitHub...');
            
            const result = await this.apiCall('/api/migrations/upload', {
                method: 'POST',
                body: JSON.stringify(formData)
            });

            this.hideLoading();
            
            this.showSuccess(`
                <h6>Migration uploaded successfully!</h6>
                <p><strong>File:</strong> ${result.filename}</p>
                <p><strong>Branch:</strong> ${result.branch}</p>
                <p><strong>Pull Request:</strong> <a href="${result.pr_url}" target="_blank">#${result.pr_number}</a></p>
                <p>The CI workflow will automatically validate and test your migration.</p>
            `);

            // Reset form
            document.getElementById('uploadForm').reset();
            
            // Reload data
            setTimeout(() => {
                this.loadDashboardData();
                this.loadVersions();
            }, 2000);

        } catch (error) {
            this.hideLoading();
            this.showError('Failed to upload migration: ' + error.message);
        }
    }

    async applyPendingMigrations() {
        if (!confirm('Are you sure you want to apply all pending migrations? A backup will be created automatically.')) {
            return;
        }

        try {
            this.showLoading('Applying pending migrations...');
            
            const result = await this.apiCall('/api/migrations/apply', {
                method: 'POST'
            });

            this.hideLoading();
            
            this.showSuccess(`
                <h6>Migrations applied successfully!</h6>
                <p>${result.message}</p>
                <p><strong>Backup created:</strong> ${result.backup_file}</p>
            `);

            // Reload data
            this.loadDashboardData();
            this.loadVersions();
            this.loadBackups();

        } catch (error) {
            this.hideLoading();
            this.showError('Failed to apply migrations: ' + error.message);
        }
    }

    prepareRollback(versionId) {
        // Switch to rollback tab and pre-select the version
        const rollbackTab = new bootstrap.Tab(document.getElementById('rollback-tab'));
        rollbackTab.show();
        
        document.getElementById('targetVersion').value = versionId;
    }

    useBackupForRollback(filename) {
        // Switch to rollback tab and pre-select the backup
        const rollbackTab = new bootstrap.Tab(document.getElementById('rollback-tab'));
        rollbackTab.show();
        
        document.getElementById('backupFile').value = filename;
    }

    async executeRollback() {
        const formData = {
            target_version: document.getElementById('targetVersion').value,
            backup_file: document.getElementById('backupFile').value,
            environment: document.getElementById('environment').value
        };

        // Validate form
        if (!formData.target_version || !formData.backup_file) {
            this.showError('Please select both target version and backup file.');
            return;
        }

        const confirmed = document.getElementById('confirmRollback').checked;
        if (!confirmed) {
            this.showError('Please confirm that you understand this operation is destructive.');
            return;
        }

        // Double confirmation for production
        if (formData.environment === 'prod') {
            const prodConfirm = confirm(
                'WARNING: You are about to rollback the PRODUCTION database. ' +
                'This will restore the database from a backup and any data written after ' +
                'the backup timestamp will be PERMANENTLY LOST. Are you absolutely sure?'
            );
            if (!prodConfirm) return;
        }

        try {
            this.showLoading(`Rolling back to version ${formData.target_version}...`);
            
            const result = await this.apiCall('/api/migrations/rollback', {
                method: 'POST',
                body: JSON.stringify(formData)
            });

            this.hideLoading();
            
            this.showSuccess(`
                <h6>Rollback completed successfully!</h6>
                <p>${result.message}</p>
                <p><strong>Backup used:</strong> ${result.backup_used}</p>
                <p><strong>Environment:</strong> ${formData.environment}</p>
            `);

            // Reset form
            document.getElementById('rollbackForm').reset();
            
            // Reload data
            this.loadDashboardData();
            this.loadVersions();

        } catch (error) {
            this.hideLoading();
            this.showError('Rollback failed: ' + error.message);
        }
    }

    async createBackup() {
        try {
            this.showLoading('Creating database backup...');
            
            const result = await this.apiCall('/api/backups/create', {
                method: 'POST'
            });

            this.hideLoading();
            
            this.showSuccess(`
                <h6>Backup created successfully!</h6>
                <p><strong>Filename:</strong> ${result.filename}</p>
                <p><strong>Size:</strong> ${this.formatFileSize(result.size)}</p>
                <p><strong>Created:</strong> ${new Date(result.created_at).toLocaleString()}</p>
            `);

            // Reload backups
            this.loadBackups();

        } catch (error) {
            this.hideLoading();
            this.showError('Failed to create backup: ' + error.message);
        }
    }

    async refreshVersions() {
        await this.loadVersions();
        await this.loadDashboardData();
    }
}

// Global functions for onclick handlers
let migrationManager;

document.addEventListener('DOMContentLoaded', () => {
    migrationManager = new MigrationManager();
});

// Global functions accessible from HTML
function refreshVersions() {
    migrationManager.refreshVersions();
}

function applyPendingMigrations() {
    migrationManager.applyPendingMigrations();
}

function createBackup() {
    migrationManager.createBackup();
}