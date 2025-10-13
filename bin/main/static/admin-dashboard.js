// Admin Dashboard JavaScript
class AdminDashboard {
    constructor() {
        this.baseUrl = 'http://localhost:8081/api';
        this.authToken = localStorage.getItem('adminToken');
        this.currentSection = 'dashboard';
        this.currentPage = 1;
        this.pageSize = 10;
        
        this.init();
    }

    init() {
        this.setupEventListeners();
        this.checkAuthentication();
        this.loadDashboardData();
    }

    setupEventListeners() {
        // Sidebar navigation
        document.querySelectorAll('.sidebar-menu a').forEach(link => {
            link.addEventListener('click', (e) => {
                e.preventDefault();
                const section = e.currentTarget.dataset.section;
                this.showSection(section);
            });
        });

        // Search functionality
        document.getElementById('user-search')?.addEventListener('input', (e) => {
            this.searchUsers(e.target.value);
        });

        document.getElementById('trip-search')?.addEventListener('input', (e) => {
            this.searchTrips(e.target.value);
        });

        document.getElementById('city-search')?.addEventListener('input', (e) => {
            this.searchCities(e.target.value);
        });
    }

    checkAuthentication() {
        if (!this.authToken) {
            this.showLoginModal();
        }
    }

    showLoginModal() {
        const loginHtml = `
            <div class="modal fade" id="loginModal" tabindex="-1" data-bs-backdrop="static">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title">Admin Login</h5>
                        </div>
                        <div class="modal-body">
                            <form id="loginForm">
                                <div class="mb-3">
                                    <label class="form-label">Username</label>
                                    <input type="text" class="form-control" name="username" required>
                                </div>
                                <div class="mb-3">
                                    <label class="form-label">Password</label>
                                    <input type="password" class="form-control" name="password" required>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-primary" onclick="adminDashboard.login()">Login</button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', loginHtml);
        const loginModal = new bootstrap.Modal(document.getElementById('loginModal'));
        loginModal.show();
    }

    async login() {
        const form = document.getElementById('loginForm');
        const formData = new FormData(form);
        
        const loginData = {
            usernameOrEmail: formData.get('username'),
            password: formData.get('password')
        };

        try {
            const response = await fetch(`${this.baseUrl}/auth/signin`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(loginData)
            });

            if (response.ok) {
                const data = await response.json();
                this.authToken = data.token;
                localStorage.setItem('adminToken', this.authToken);
                
                // Close login modal
                const loginModal = bootstrap.Modal.getInstance(document.getElementById('loginModal'));
                loginModal.hide();
                
                // Load dashboard data
                this.loadDashboardData();
            } else {
                this.showAlert('Login failed. Please check your credentials.', 'danger');
            }
        } catch (error) {
            this.showAlert('Login error: ' + error.message, 'danger');
        }
    }

    logout() {
        localStorage.removeItem('adminToken');
        this.authToken = null;
        location.reload();
    }

    showSection(section) {
        // Hide all sections
        document.querySelectorAll('.content-section').forEach(el => {
            el.classList.add('hidden');
        });

        // Show selected section
        document.getElementById(`${section}-section`).classList.remove('hidden');

        // Update active menu item
        document.querySelectorAll('.sidebar-menu a').forEach(link => {
            link.classList.remove('active');
        });
        document.querySelector(`[data-section="${section}"]`).classList.add('active');

        // Update page title
        document.querySelector('.page-title').textContent = this.capitalizeFirst(section);

        // Load section data
        this.currentSection = section;
        this.loadSectionData(section);
    }

    async loadSectionData(section) {
        switch (section) {
            case 'dashboard':
                await this.loadDashboardData();
                break;
            case 'users':
                await this.loadUsers();
                break;
            case 'trips':
                await this.loadTrips();
                break;
            case 'cities':
                await this.loadCities();
                break;
            case 'bookings':
                await this.loadBookings();
                break;
            case 'payments':
                await this.loadPayments();
                break;
            case 'ratings':
                await this.loadRatings();
                break;
            case 'notifications':
                await this.loadNotifications();
                break;
        }
    }

    async loadDashboardData() {
        try {
            this.showLoading();
            
            // Load dashboard statistics
            const statsResponse = await this.apiCall('/admin/dashboard/stats');
            if (statsResponse) {
                this.updateDashboardStats(statsResponse);
            }

            // Load analytics data for charts
            const analyticsResponse = await this.apiCall('/admin/analytics/revenue');
            if (analyticsResponse) {
                this.updateAnalyticsCharts(analyticsResponse);
            }

            // Create charts with real data
            await this.createCharts();

            // Load recent activity
            await this.loadRecentActivity();

        } catch (error) {
            console.error('Failed to load dashboard data:', error);
            this.showAlert('Failed to load dashboard data: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    updateDashboardStats(stats) {
        // Update stat cards
        document.getElementById('total-users').textContent = stats.totalUsers || 0;
        document.getElementById('total-trips').textContent = stats.totalTrips || 0;
        document.getElementById('total-bookings').textContent = stats.totalBookings || 0;
        
        // Calculate and display revenue
        const totalRevenue = stats.totalRevenue || 0;
        document.getElementById('total-revenue').textContent = `${totalRevenue.toFixed(2)} TND`;
        
        // Update additional stats if elements exist
        if (document.getElementById('active-users')) {
            document.getElementById('active-users').textContent = stats.activeUsers || 0;
        }
        if (document.getElementById('active-trips')) {
            document.getElementById('active-trips').textContent = stats.activeTrips || 0;
        }
        if (document.getElementById('completed-trips')) {
            document.getElementById('completed-trips').textContent = stats.completedTrips || 0;
        }
        if (document.getElementById('confirmed-bookings')) {
            document.getElementById('confirmed-bookings').textContent = stats.confirmedBookings || 0;
        }
    }
    
    updateAnalyticsCharts(analytics) {
        // Update the charts with real analytics data
        this.analyticsData = analytics;
    }

    async createCharts() {
        try {
            // Load user statistics for the chart
            const userStats = await this.apiCall('/admin/users/statistics');
            
            // User Activity Chart - Show user growth
            const userCtx = document.getElementById('userActivityChart');
            if (userCtx && userStats) {
                const ctx = userCtx.getContext('2d');
                if (this.userChart) {
                    this.userChart.destroy();
                }
                
                this.userChart = new Chart(ctx, {
                    type: 'line',
                    data: {
                        labels: ['Total', 'Active', 'Verified', 'Inactive', 'Suspended'],
                        datasets: [{
                            label: 'Users',
                            data: [
                                userStats.total || 0,
                                userStats.active || 0,
                                userStats.verified || 0,
                                (userStats.total - userStats.active) || 0,
                                userStats.suspended || 0
                            ],
                            borderColor: '#3498db',
                            backgroundColor: 'rgba(52, 152, 219, 0.2)',
                            tension: 0.4,
                            fill: true
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                display: true,
                                position: 'top'
                            }
                        },
                        scales: {
                            y: {
                                beginAtZero: true
                            }
                        }
                    }
                });
            }

            // Load trip statistics for the chart
            const tripStats = await this.apiCall('/admin/trips/statistics');
            
            // Trip Statistics Chart - Show trip status distribution
            const tripCtx = document.getElementById('tripStatsChart');
            if (tripCtx && tripStats) {
                const ctx = tripCtx.getContext('2d');
                if (this.tripChart) {
                    this.tripChart.destroy();
                }
                
                this.tripChart = new Chart(ctx, {
                    type: 'doughnut',
                    data: {
                        labels: ['Completed', 'Active', 'Cancelled', 'Planned'],
                        datasets: [{
                            data: [
                                tripStats.completed || 0,
                                tripStats.active || 0,
                                tripStats.cancelled || 0,
                                tripStats.planned || 0
                            ],
                            backgroundColor: [
                                '#27ae60',
                                '#3498db',
                                '#e74c3c',
                                '#f39c12'
                            ]
                        }]
                    },
                    options: {
                        responsive: true,
                        maintainAspectRatio: false,
                        plugins: {
                            legend: {
                                position: 'bottom'
                            }
                        }
                    }
                });
            }
        } catch (error) {
            console.error('Failed to create charts:', error);
        }
    }

    async loadRecentActivity() {
        try {
            const activities = await this.apiCall('/admin/recent-activity');
            
            if (!activities || activities.length === 0) {
                const tbody = document.getElementById('recent-activity');
                tbody.innerHTML = '<tr><td colspan="5" class="text-center">No recent activity</td></tr>';
                return;
            }

            const tbody = document.getElementById('recent-activity');
            tbody.innerHTML = activities.map(activity => {
                const timestamp = this.formatTimestamp(activity.timestamp);
                const statusClass = activity.status ? activity.status.toLowerCase() : 'unknown';
                
                return `
                    <tr>
                        <td><span class="badge bg-primary">${activity.type || 'Activity'}</span></td>
                        <td>${activity.description || 'No description'}</td>
                        <td>System</td>
                        <td>${timestamp}</td>
                        <td><span class="status-badge status-${statusClass}">${activity.status || 'N/A'}</span></td>
                    </tr>
                `;
            }).join('');
        } catch (error) {
            console.error('Failed to load recent activity:', error);
            const tbody = document.getElementById('recent-activity');
            tbody.innerHTML = '<tr><td colspan="5" class="text-center text-danger">Failed to load activity</td></tr>';
        }
    }
    
    formatTimestamp(timestamp) {
        if (!timestamp) return 'Unknown';
        
        try {
            const date = new Date(timestamp);
            const now = new Date();
            const diffMs = now - date;
            const diffMins = Math.floor(diffMs / 60000);
            const diffHours = Math.floor(diffMs / 3600000);
            const diffDays = Math.floor(diffMs / 86400000);
            
            if (diffMins < 1) return 'Just now';
            if (diffMins < 60) return `${diffMins} minute${diffMins > 1 ? 's' : ''} ago`;
            if (diffHours < 24) return `${diffHours} hour${diffHours > 1 ? 's' : ''} ago`;
            if (diffDays < 7) return `${diffDays} day${diffDays > 1 ? 's' : ''} ago`;
            
            return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
        } catch (error) {
            return timestamp;
        }
    }

    async loadUsers() {
        try {
            this.showLoading();
            const response = await this.apiCall('/admin/users?page=0&size=10');
            if (response && response.content) {
                this.renderUsersTable(response.content);
                this.renderPagination(response, 'users');
            }
        } catch (error) {
            this.showAlert('Failed to load users: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderUsersTable(users) {
        const tbody = document.getElementById('users-table');
        tbody.innerHTML = users.map(user => `
            <tr>
                <td>${user.id}</td>
                <td>${user.username}</td>
                <td>${user.email}</td>
                <td>${user.firstName} ${user.lastName}</td>
                <td><span class="badge bg-info">${user.role}</span></td>
                <td><span class="status-badge status-${user.isActive ? 'active' : 'inactive'}">${user.isActive ? 'Active' : 'Inactive'}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="adminDashboard.editUser(${user.id})">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-${user.isActive ? 'warning' : 'success'}" onclick="adminDashboard.toggleUserStatus(${user.id}, ${user.isActive})">
                        <i class="fas fa-${user.isActive ? 'ban' : 'check'}"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="adminDashboard.deleteUser(${user.id})">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadTrips() {
        try {
            this.showLoading();
            const response = await this.apiCall('/trips/available');
            if (response) {
                this.renderTripsTable(response);
            }
        } catch (error) {
            this.showAlert('Failed to load trips: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderTripsTable(trips) {
        const tbody = document.getElementById('trips-table');
        tbody.innerHTML = trips.map(trip => `
            <tr>
                <td>${trip.id}</td>
                <td>${trip.driver?.firstName} ${trip.driver?.lastName}</td>
                <td>${trip.points?.[0]?.address} → ${trip.points?.[1]?.address}</td>
                <td>${new Date(trip.departureTime).toLocaleDateString()}</td>
                <td>$${trip.pricePerSeat}</td>
                <td>${trip.availableSeats}/${trip.maxSeats}</td>
                <td><span class="status-badge status-${trip.status?.toLowerCase()}">${trip.status}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="adminDashboard.editTrip(${trip.id})">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="adminDashboard.deleteTrip(${trip.id})">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadCities() {
        try {
            this.showLoading();
            const response = await this.apiCall('/cities');
            if (response) {
                this.renderCitiesTable(response);
            }
        } catch (error) {
            this.showAlert('Failed to load cities: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderCitiesTable(cities) {
        const tbody = document.getElementById('cities-table');
        tbody.innerHTML = cities.map(city => `
            <tr>
                <td>${city.id}</td>
                <td>${city.name}</td>
                <td>${city.codePostal}</td>
                <td>${city.pays}</td>
                <td>${city.latitude}, ${city.longitude}</td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="adminDashboard.editCity(${city.id})">
                        <i class="fas fa-edit"></i>
                    </button>
                    <button class="btn btn-sm btn-danger" onclick="adminDashboard.deleteCity(${city.id})">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadBookings() {
        try {
            this.showLoading();
            const bookings = await this.apiCall('/admin/bookings');
            if (bookings) {
                this.renderBookingsTable(bookings);
            }
        } catch (error) {
            this.showAlert('Failed to load bookings: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }
    
    renderBookingsTable(bookings) {
        const tbody = document.getElementById('bookings-table');
        if (!tbody) return;
        
        tbody.innerHTML = bookings.map(booking => `
            <tr>
                <td>${booking.id}</td>
                <td>${booking.tripId || 'N/A'}</td>
                <td>${booking.passengerName || 'Unknown'}</td>
                <td>${booking.seats || 0}</td>
                <td>${booking.totalPrice || 0} TND</td>
                <td>${this.formatTimestamp(booking.timestamp)}</td>
                <td><span class="status-badge status-${booking.status?.toLowerCase()}">${booking.status}</span></td>
            </tr>
        `).join('');
    }

    async loadPayments() {
        try {
            this.showLoading();
            const stats = await this.apiCall('/admin/payments/statistics');
            if (stats) {
                this.displayPaymentStats(stats);
            }
        } catch (error) {
            this.showAlert('Failed to load payments: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }
    
    displayPaymentStats(stats) {
        const container = document.getElementById('payments-stats');
        if (!container) return;
        
        container.innerHTML = `
            <div class="row">
                <div class="col-md-3">
                    <div class="stat-card">
                        <h5>Total Revenue</h5>
                        <h3>${stats.totalRevenue || 0} TND</h3>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="stat-card">
                        <h5>Successful</h5>
                        <h3>${stats.successful || 0}</h3>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="stat-card">
                        <h5>Failed</h5>
                        <h3>${stats.failed || 0}</h3>
                    </div>
                </div>
                <div class="col-md-3">
                    <div class="stat-card">
                        <h5>Pending</h5>
                        <h3>${stats.pending || 0}</h3>
                    </div>
                </div>
            </div>
        `;
    }

    async loadRatings() {
        try {
            this.showLoading();
            const stats = await this.apiCall('/admin/ratings/statistics');
            if (stats) {
                this.displayRatingStats(stats);
            }
            
            const pending = await this.apiCall('/admin/ratings/pending');
            if (pending) {
                this.renderPendingRatings(pending);
            }
        } catch (error) {
            this.showAlert('Failed to load ratings: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }
    
    displayRatingStats(stats) {
        console.log('Rating stats:', stats);
    }
    
    renderPendingRatings(ratings) {
        console.log('Pending ratings:', ratings);
    }

    async loadNotifications() {
        try {
            this.showLoading();
            const stats = await this.apiCall('/admin/notifications/statistics');
            if (stats) {
                this.displayNotificationStats(stats);
            }
        } catch (error) {
            this.showAlert('Failed to load notifications: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }
    
    displayNotificationStats(stats) {
        console.log('Notification stats:', stats);
    }
    
    // Report Generation Functions
    async generateReport(type, format) {
        try {
            this.showLoading();
            const endpoint = `/admin/reports/${type}`;
            const params = new URLSearchParams({
                startDate: document.getElementById('report-start-date')?.value || '',
                endDate: document.getElementById('report-end-date')?.value || ''
            });
            
            if (format === 'csv') {
                await this.downloadCSVReport(type, params);
            } else if (format === 'pdf') {
                await this.downloadPDFReport(type, params);
            } else {
                const report = await this.apiCall(`${endpoint}?${params}`);
                this.displayReport(report);
            }
            
            this.showAlert(`${type} report generated successfully!`, 'success');
        } catch (error) {
            this.showAlert('Failed to generate report: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }
    
    async downloadCSVReport(type, params) {
        const endpoint = `/admin/export/csv/${type}?${params}`;
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            headers: {
                'Authorization': `Bearer ${this.authToken}`
            }
        });
        
        if (!response.ok) throw new Error('Failed to download CSV');
        
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${type}-report.csv`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }
    
    async downloadPDFReport(type, params) {
        const endpoint = `/admin/export/pdf/${type}?${params}`;
        const response = await fetch(`${this.baseUrl}${endpoint}`, {
            headers: {
                'Authorization': `Bearer ${this.authToken}`
            }
        });
        
        if (!response.ok) throw new Error('Failed to download PDF');
        
        const blob = await response.blob();
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${type}-report.pdf`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        window.URL.revokeObjectURL(url);
    }
    
    displayReport(report) {
        const container = document.getElementById('report-content');
        if (!container) return;
        
        container.innerHTML = `
            <div class="report-preview">
                <h4>Report Generated</h4>
                <pre>${JSON.stringify(report, null, 2)}</pre>
            </div>
        `;
    }

    // User Management Functions
    showAddUserModal() {
        const modal = new bootstrap.Modal(document.getElementById('addUserModal'));
        modal.show();
    }

    async addUser() {
        const form = document.getElementById('addUserForm');
        const formData = new FormData(form);
        
        const userData = {
            username: formData.get('username'),
            email: formData.get('email'),
            password: formData.get('password'),
            firstName: formData.get('firstName'),
            lastName: formData.get('lastName'),
            phoneNumber: formData.get('phoneNumber'),
            role: formData.get('role')
        };

        try {
            const response = await this.apiCall('/auth/signup', 'POST', userData);
            if (response) {
                this.showAlert('User added successfully!', 'success');
                const modal = bootstrap.Modal.getInstance(document.getElementById('addUserModal'));
                modal.hide();
                form.reset();
                this.loadUsers();
            }
        } catch (error) {
            this.showAlert('Failed to add user: ' + error.message, 'danger');
        }
    }

    async toggleUserStatus(userId, isActive) {
        const action = isActive ? 'suspend' : 'activate';
        const actionText = isActive ? 'suspend' : 'activate';
        
        if (confirm(`Are you sure you want to ${actionText} this user?`)) {
            try {
                const response = await this.apiCall(`/admin/users/${userId}/${action}`, 'POST');
                if (response) {
                    this.showAlert(`User ${actionText}ed successfully!`, 'success');
                    this.loadUsers();
                }
            } catch (error) {
                this.showAlert(`Failed to ${actionText} user: ` + error.message, 'danger');
            }
        }
    }

    async deleteUser(userId) {
        if (confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
            try {
                const response = await this.apiCall(`/admin/users/${userId}`, 'DELETE');
                if (response) {
                    this.showAlert('User deleted successfully!', 'success');
                    this.loadUsers();
                }
            } catch (error) {
                this.showAlert('Failed to delete user: ' + error.message, 'danger');
            }
        }
    }

    // City Management Functions
    showAddCityModal() {
        const modal = new bootstrap.Modal(document.getElementById('addCityModal'));
        modal.show();
    }

    async addCity() {
        const form = document.getElementById('addCityForm');
        const formData = new FormData(form);
        
        const cityData = {
            name: formData.get('name'),
            codePostal: formData.get('codePostal'),
            pays: formData.get('pays'),
            latitude: parseFloat(formData.get('latitude')),
            longitude: parseFloat(formData.get('longitude'))
        };

        try {
            const response = await this.apiCall('/cities', 'POST', cityData);
            if (response) {
                this.showAlert('City added successfully!', 'success');
                const modal = bootstrap.Modal.getInstance(document.getElementById('addCityModal'));
                modal.hide();
                form.reset();
                this.loadCities();
            }
        } catch (error) {
            this.showAlert('Failed to add city: ' + error.message, 'danger');
        }
    }

    // Utility Functions
    async apiCall(endpoint, method = 'GET', data = null) {
        const options = {
            method: method,
            headers: {
                'Content-Type': 'application/json'
            }
        };

        if (this.authToken) {
            options.headers['Authorization'] = `Bearer ${this.authToken}`;
        }

        if (data) {
            options.body = JSON.stringify(data);
        }

        try {
            const response = await fetch(`${this.baseUrl}${endpoint}`, options);
            
            if (!response.ok) {
                if (response.status === 401) {
                    this.logout();
                    throw new Error('Unauthorized');
                }
                throw new Error(`HTTP ${response.status}: ${response.statusText}`);
            }

            return await response.json();
        } catch (error) {
            console.error('API call failed:', error);
            throw error;
        }
    }

    showLoading() {
        document.getElementById('loading').style.display = 'block';
    }

    hideLoading() {
        document.getElementById('loading').style.display = 'none';
    }

    showAlert(message, type = 'info') {
        const alertHtml = `
            <div class="alert alert-${type} alert-dismissible fade show" role="alert">
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
        
        const container = document.querySelector('.main-content');
        container.insertAdjacentHTML('afterbegin', alertHtml);
        
        // Auto-dismiss after 5 seconds
        setTimeout(() => {
            const alert = container.querySelector('.alert');
            if (alert) {
                const bsAlert = new bootstrap.Alert(alert);
                bsAlert.close();
            }
        }, 5000);
    }

    renderPagination(response, type) {
        const pagination = document.getElementById(`${type}-pagination`);
        if (!pagination) return;

        const totalPages = response.totalPages || 1;
        const currentPage = response.number || 0;
        
        let paginationHtml = '';
        
        // Previous button
        paginationHtml += `
            <li class="page-item ${currentPage === 0 ? 'disabled' : ''}">
                <a class="page-link" href="#" onclick="adminDashboard.changePage('${type}', ${currentPage - 1})">Previous</a>
            </li>
        `;
        
        // Page numbers
        for (let i = 0; i < totalPages; i++) {
            paginationHtml += `
                <li class="page-item ${i === currentPage ? 'active' : ''}">
                    <a class="page-link" href="#" onclick="adminDashboard.changePage('${type}', ${i})">${i + 1}</a>
                </li>
            `;
        }
        
        // Next button
        paginationHtml += `
            <li class="page-item ${currentPage === totalPages - 1 ? 'disabled' : ''}">
                <a class="page-link" href="#" onclick="adminDashboard.changePage('${type}', ${currentPage + 1})">Next</a>
            </li>
        `;
        
        pagination.innerHTML = paginationHtml;
    }

    async changePage(type, page) {
        this.currentPage = page;
        await this.loadSectionData(type);
    }

    searchUsers(query) {
        // Implementation for user search
        console.log('Searching users:', query);
    }

    searchTrips(query) {
        // Implementation for trip search
        console.log('Searching trips:', query);
    }

    searchCities(query) {
        // Implementation for city search
        console.log('Searching cities:', query);
    }

    capitalizeFirst(str) {
        return str.charAt(0).toUpperCase() + str.slice(1);
    }
}

// Global functions for onclick handlers
function refreshData() {
    adminDashboard.loadSectionData(adminDashboard.currentSection);
}

function logout() {
    adminDashboard.logout();
}

function showAddUserModal() {
    adminDashboard.showAddUserModal();
}

function addUser() {
    adminDashboard.addUser();
}

function showAddCityModal() {
    adminDashboard.showAddCityModal();
}

function addCity() {
    adminDashboard.addCity();
}

function generateReport(type, format) {
    adminDashboard.generateReport(type, format);
}

function exportData(type, format) {
    if (format === 'csv') {
        adminDashboard.downloadCSVReport(type, new URLSearchParams());
    } else if (format === 'pdf') {
        adminDashboard.downloadPDFReport(type, new URLSearchParams());
    }
}

// Initialize the dashboard when the page loads
let adminDashboard;
document.addEventListener('DOMContentLoaded', () => {
    adminDashboard = new AdminDashboard();
});
