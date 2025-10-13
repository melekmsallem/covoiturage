// Admin Dashboard JavaScript
class AdminDashboard {
    constructor() {
        this.baseUrl = 'http://localhost:8081/api';
        this.authToken = localStorage.getItem('adminToken');
        this.currentSection = 'dashboard';
        this.currentPage = 1;
        this.pageSize = 10;
        this.userActivityChart = null;
        this.tripStatsChart = null;
        
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
        this.authToken = localStorage.getItem('adminToken');
        if (!this.authToken) {
            // Redirect to login page if no token
            window.location.href = '/admin-login.html';
            return;
        }
        
        // Verify token is still valid
        this.verifyToken();
    }

    async verifyToken() {
        try {
            const response = await fetch(`${this.baseUrl}/admin/auth/verify`, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`
                }
            });
            
            if (!response.ok) {
                // Token invalid, redirect to login
                localStorage.removeItem('adminToken');
                localStorage.removeItem('adminUser');
                window.location.href = '/admin-login.html';
            }
        } catch (error) {
            console.error('Token verification failed:', error);
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
            window.location.href = '/admin-login.html';
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
            const response = await fetch(`${this.baseUrl}/admin/auth/signin`, {
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
            case 'analytics':
                await loadAnalytics();
                break;
            case 'monitoring':
                await loadSystemHealth();
                await loadPendingTransfers();
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

            // Load charts
            this.createCharts();

            // Load recent activity
            await this.loadRecentActivity();

        } catch (error) {
            this.showAlert('Failed to load dashboard data: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    updateDashboardStats(stats) {
        document.getElementById('total-users').textContent = stats.totalUsers || 0;
        document.getElementById('total-trips').textContent = stats.totalTrips || 0;
        document.getElementById('total-bookings').textContent = stats.totalBookings || 0;
        document.getElementById('total-revenue').textContent = `$${stats.totalRevenue || 0}`;
    }

    createCharts() {
        // Destroy existing charts if they exist
        if (this.userActivityChart) {
            this.userActivityChart.destroy();
        }
        if (this.tripStatsChart) {
            this.tripStatsChart.destroy();
        }

        // User Activity Chart - Show empty state since we have no real data
        const userCtx = document.getElementById('userActivityChart');
        if (userCtx) {
            this.userActivityChart = new Chart(userCtx, {
                type: 'line',
                data: {
                    labels: ['No Data'],
                    datasets: [{
                        label: 'No Data Available',
                        data: [0],
                        borderColor: '#e0e0e0',
                        backgroundColor: 'rgba(224, 224, 224, 0.1)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        // Trip Statistics Chart - Show empty state since we have no real data
        const tripCtx = document.getElementById('tripStatsChart');
        if (tripCtx) {
            this.tripStatsChart = new Chart(tripCtx, {
                type: 'doughnut',
                data: {
                    labels: ['No Data'],
                    datasets: [{
                        data: [1],
                        backgroundColor: [
                            '#e0e0e0'
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
    }

    async loadRecentActivity() {
        try {
            // Try to load real recent activity data
            const response = await this.apiCall('/admin/recent-activity');
            if (response && response.length > 0) {
                const tbody = document.getElementById('recent-activity');
                tbody.innerHTML = response.map(activity => `
                    <tr>
                        <td><span class="badge bg-primary">${activity.type}</span></td>
                        <td>${activity.description}</td>
                        <td>${activity.user}</td>
                        <td>${activity.time}</td>
                        <td><span class="status-badge status-${activity.status}">${activity.status}</span></td>
                    </tr>
                `).join('');
            } else {
                // Show empty state if no real data
                const tbody = document.getElementById('recent-activity');
                tbody.innerHTML = `
                    <tr>
                        <td colspan="5" class="text-center text-muted">No recent activity</td>
                    </tr>
                `;
            }
        } catch (error) {
            // Show empty state if API call fails
            const tbody = document.getElementById('recent-activity');
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center text-muted">No recent activity</td>
                </tr>
            `;
        }
    }

    async loadUsers() {
        try {
            this.showLoading();
            // Use real admin endpoint with authentication
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
        tbody.innerHTML = users.map(user => {
            const suspensionInfo = !user.isActive && user.suspensionReason ? 
                `<br><small class="text-danger">Reason: ${user.suspensionReason}</small>` : '';
            return `
            <tr>
                <td>${user.id}</td>
                <td>${user.username}</td>
                <td>${user.email}</td>
                <td>${user.firstName} ${user.lastName}</td>
                <td><span class="badge bg-info">${user.role}</span></td>
                <td>
                    <span class="status-badge status-${user.isActive ? 'active' : 'inactive'}">
                        ${user.isActive ? 'Active' : 'Suspended'}
                    </span>
                    ${suspensionInfo}
                </td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="adminDashboard.editUser(${user.id})" title="Edit">
                        <i class="fas fa-edit"></i>
                    </button>
                    ${user.isActive ? 
                        `<button class="btn btn-sm btn-warning" onclick="adminDashboard.showSuspendModal(${user.id})" title="Suspend">
                            <i class="fas fa-ban"></i> Suspend
                        </button>` :
                        `<button class="btn btn-sm btn-success" onclick="adminDashboard.activateUser(${user.id})" title="Activate">
                            <i class="fas fa-check"></i> Activate
                        </button>`
                    }
                    <button class="btn btn-sm btn-danger" onclick="adminDashboard.deleteUser(${user.id})" title="Delete">
                        <i class="fas fa-trash"></i>
                    </button>
                </td>
            </tr>
        `}).join('');
    }

    async loadTrips() {
        try {
            this.showLoading();
            // Use real admin endpoint for trips
            const response = await this.apiCall('/admin/trips?page=0&size=10');
            if (response && response.content) {
                this.renderTripsTable(response.content);
                this.renderPagination(response, 'trips');
            }
        } catch (error) {
            this.showAlert('Failed to load trips: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderTripsTable(trips) {
        const tbody = document.getElementById('trips-table');
        if (!trips || !Array.isArray(trips)) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">No trips available</td></tr>';
            return;
        }
        tbody.innerHTML = trips.map(trip => `
            <tr>
                <td>${trip.id}</td>
                <td>${trip.driver?.firstName || 'Unknown'} ${trip.driver?.lastName || ''}</td>
                <td>${trip.points?.[0]?.address || 'Unknown'} → ${trip.points?.[1]?.address || 'Unknown'}</td>
                <td>${new Date(trip.departureTime).toLocaleDateString()}</td>
                <td>${trip.pricePerSeat} TND</td>
                <td>${trip.availableSeats}/${trip.maxSeats}</td>
                <td><span class="status-badge status-${trip.status?.toLowerCase()}">${trip.status}</span></td>
                <td>
                    <button class="btn btn-sm btn-danger" onclick="forceDeleteTrip(${trip.id})" title="Delete Trip">
                        <i class="fas fa-trash"></i> Delete
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadCities() {
        try {
            this.showLoading();
            // Use real admin endpoint for cities
            const response = await this.apiCall('/admin/cities');
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
            const response = await fetch(`${this.baseUrl}/admin/bookings`, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.ok) {
                const bookings = await response.json();
                this.renderBookingsTable(bookings);
            } else {
                this.showAlert('Failed to load bookings', 'danger');
            }
        } catch (error) {
            this.showAlert('Error loading bookings: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderBookingsTable(bookings) {
        const tbody = document.getElementById('bookings-table');
        if (!bookings || bookings.length === 0) {
            tbody.innerHTML = '<tr><td colspan="9" class="text-center">No bookings found</td></tr>';
            return;
        }
        tbody.innerHTML = bookings.map(booking => `
            <tr>
                <td>${booking.id}</td>
                <td>#${booking.voyageId || 'N/A'}</td>
                <td>${booking.passengerName || 'Unknown'}</td>
                <td>${booking.departureCity || 'N/A'} → ${booking.arrivalCity || 'N/A'}</td>
                <td>${booking.seatsReserved || 0}</td>
                <td>${booking.totalPrice ? parseFloat(booking.totalPrice).toFixed(2) : '0'} TND</td>
                <td>${booking.reservationDate ? new Date(booking.reservationDate).toLocaleDateString() : 'N/A'}</td>
                <td><span class="status-badge status-${booking.status?.toLowerCase()}">${booking.status}</span></td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="viewBookingDetails(${booking.id})">
                        <i class="fas fa-eye"></i>
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadPayments() {
        try {
            this.showLoading();
            const response = await fetch(`${this.baseUrl}/payments/admin/all`, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });
            
            if (response.ok) {
                const payments = await response.json();
                this.renderPaymentsTable(payments);
            } else {
                this.showAlert('Failed to load payments', 'danger');
            }
        } catch (error) {
            this.showAlert('Error loading payments: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    renderPaymentsTable(payments) {
        const tbody = document.getElementById('payments-table');
        if (!payments || payments.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">No payments found</td></tr>';
            return;
        }
        
        // Update stats
        const completed = payments.filter(p => p.status === 'COMPLETED').length;
        const pending = payments.filter(p => p.status === 'PENDING').length;
        const failed = payments.filter(p => p.status === 'FAILED').length;
        
        if (document.getElementById('completed-payments')) {
            document.getElementById('completed-payments').textContent = completed;
            document.getElementById('pending-payments').textContent = pending;
            document.getElementById('failed-payments').textContent = failed;
        }
        
        tbody.innerHTML = payments.map(payment => `
            <tr>
                <td>${payment.id}</td>
                <td>#${payment.reservationId}</td>
                <td>${payment.amount ? payment.amount.toFixed(2) : '0'} TND</td>
                <td>${payment.paymentMethod}</td>
                <td><span class="status-badge status-${payment.status?.toLowerCase()}">${payment.status}</span></td>
                <td>${payment.transactionId || 'N/A'}</td>
                <td>${payment.paymentDate ? new Date(payment.paymentDate).toLocaleDateString() : 'N/A'}</td>
                <td>
                    <button class="btn btn-sm btn-info" onclick="downloadReceipt(${payment.id})">
                        <i class="fas fa-download"></i> PDF
                    </button>
                </td>
            </tr>
        `).join('');
    }

    async loadRatings() {
        try {
            // Load rating statistics
            await this.loadRatingStatistics();
            
            // Load pending ratings
            await this.loadPendingRatings();
            
            // Setup rating event listeners
            this.setupRatingEventListeners();
            
        } catch (error) {
            console.error('Error loading ratings:', error);
            this.showAlert('Error loading ratings data', 'danger');
        }
    }

    async loadRatingStatistics() {
        try {
            const response = await fetch(`${this.baseUrl}/admin/ratings/statistics`, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                const stats = await response.json();
                document.getElementById('total-ratings').textContent = stats.totalRatings || 0;
                document.getElementById('approved-ratings').textContent = stats.approvedRatings || 0;
                document.getElementById('pending-ratings').textContent = stats.pendingRatings || 0;
                document.getElementById('rejected-ratings').textContent = stats.rejectedRatings || 0;
            }
        } catch (error) {
            console.error('Error loading rating statistics:', error);
        }
    }

    async loadPendingRatings() {
        try {
            const response = await fetch(`${this.baseUrl}/admin/ratings/pending`, {
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                const ratings = await response.json();
                this.displayRatings(ratings);
            }
        } catch (error) {
            console.error('Error loading pending ratings:', error);
        }
    }

    displayRatings(ratings) {
        const tbody = document.getElementById('ratings-table-body');
        tbody.innerHTML = '';

        if (ratings.length === 0) {
            tbody.innerHTML = '<tr><td colspan="8" class="text-center">No ratings found</td></tr>';
            return;
        }

        ratings.forEach(rating => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${rating.id}</td>
                <td>${rating.userName || 'Unknown'}</td>
                <td>Trip #${rating.tripId || 'N/A'}</td>
                <td>
                    <div class="d-flex align-items-center">
                        ${this.generateStars(rating.rating)}
                        <span class="ms-2">${rating.rating}/5</span>
                    </div>
                </td>
                <td>
                    <div class="text-truncate" style="max-width: 200px;" title="${rating.comment || 'No comment'}">
                        ${rating.comment || 'No comment'}
                    </div>
                </td>
                <td>
                    <span class="status-badge status-${rating.status.toLowerCase()}">
                        ${rating.status}
                    </span>
                </td>
                <td>${this.formatDate(rating.createdAt)}</td>
                <td>
                    <div class="btn-group" role="group">
                        ${rating.status === 'PENDING' ? `
                            <button class="btn btn-success btn-sm" onclick="adminDashboard.approveRating(${rating.id})" title="Approve">
                                <i class="fas fa-check"></i>
                            </button>
                            <button class="btn btn-danger btn-sm" onclick="adminDashboard.rejectRating(${rating.id})" title="Reject">
                                <i class="fas fa-times"></i>
                            </button>
                        ` : ''}
                        <button class="btn btn-info btn-sm" onclick="adminDashboard.viewRatingDetails(${rating.id})" title="View Details">
                            <i class="fas fa-eye"></i>
                        </button>
                    </div>
                </td>
            `;
            tbody.appendChild(row);
        });
    }

    generateStars(rating) {
        let stars = '';
        for (let i = 1; i <= 5; i++) {
            if (i <= rating) {
                stars += '<i class="fas fa-star text-warning"></i>';
            } else {
                stars += '<i class="far fa-star text-muted"></i>';
            }
        }
        return stars;
    }

    async approveRating(ratingId) {
        if (!confirm('Are you sure you want to approve this rating?')) {
            return;
        }

        try {
            const response = await fetch(`${this.baseUrl}/admin/ratings/${ratingId}/approve`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                }
            });

            if (response.ok) {
                this.showAlert('Rating approved successfully', 'success');
                await this.loadRatings(); // Refresh the ratings
            } else {
                this.showAlert('Failed to approve rating', 'danger');
            }
        } catch (error) {
            console.error('Error approving rating:', error);
            this.showAlert('Error approving rating', 'danger');
        }
    }

    async rejectRating(ratingId) {
        const reason = prompt('Please enter the reason for rejection:');
        if (!reason) {
            return;
        }

        try {
            const response = await fetch(`${this.baseUrl}/admin/ratings/${ratingId}/reject`, {
                method: 'POST',
                headers: {
                    'Authorization': `Bearer ${this.authToken}`,
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify({ reason: reason })
            });

            if (response.ok) {
                this.showAlert('Rating rejected successfully', 'success');
                await this.loadRatings(); // Refresh the ratings
            } else {
                this.showAlert('Failed to reject rating', 'danger');
            }
        } catch (error) {
            console.error('Error rejecting rating:', error);
            this.showAlert('Error rejecting rating', 'danger');
        }
    }

    viewRatingDetails(ratingId) {
        // Implementation for viewing rating details
        console.log('Viewing rating details for ID:', ratingId);
        // You can implement a modal or redirect to a details page
    }

    setupRatingEventListeners() {
        // Search functionality
        document.getElementById('rating-search')?.addEventListener('input', (e) => {
            this.searchRatings(e.target.value);
        });

        // Status filter
        document.getElementById('rating-status-filter')?.addEventListener('change', (e) => {
            this.filterRatingsByStatus(e.target.value);
        });
    }

    searchRatings(query) {
        // Implementation for searching ratings
        console.log('Searching ratings:', query);
    }

    filterRatingsByStatus(status) {
        // Implementation for filtering ratings by status
        console.log('Filtering ratings by status:', status);
    }

    async refreshRatings() {
        await this.loadRatings();
        this.showAlert('Ratings refreshed', 'success');
    }

    async loadNotifications() {
        // Implementation for notifications
        console.log('Loading notifications...');
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

    showSuspendModal(userId) {
        document.getElementById('suspend-user-id').value = userId;
        document.getElementById('suspension-reason').value = '';
        document.getElementById('suspension-end-date').value = '';
        const modal = new bootstrap.Modal(document.getElementById('suspendUserModal'));
        modal.show();
    }

    async suspendUser() {
        const userId = document.getElementById('suspend-user-id').value;
        const reason = document.getElementById('suspension-reason').value.trim();
        const endDate = document.getElementById('suspension-end-date').value;

        if (!reason) {
            this.showAlert('Please provide a reason for suspension', 'warning');
            return;
        }

        const suspensionData = {
            reason: reason,
            suspensionEndDate: endDate ? new Date(endDate).toISOString() : null
        };

        try {
            const response = await this.apiCall(`/admin/users/${userId}/suspend`, 'POST', suspensionData);
            if (response) {
                this.showAlert('User suspended successfully!', 'success');
                const modal = bootstrap.Modal.getInstance(document.getElementById('suspendUserModal'));
                modal.hide();
                this.loadUsers();
            }
        } catch (error) {
            this.showAlert('Failed to suspend user: ' + error.message, 'danger');
        }
    }

    async activateUser(userId) {
        if (confirm('Are you sure you want to activate this user?')) {
            try {
                const response = await this.apiCall(`/admin/users/${userId}/activate`, 'POST');
                if (response) {
                    this.showAlert('User activated successfully!', 'success');
                    this.loadUsers();
                }
            } catch (error) {
                this.showAlert('Failed to activate user: ' + error.message, 'danger');
            }
        }
    }

    async filterUsersByStatus() {
        const statusFilter = document.getElementById('user-status-filter').value;
        try {
            this.showLoading();
            let url = '/admin/users?page=0&size=10';
            
            if (statusFilter === 'active') {
                url = '/admin/users/status/active?page=0&size=10';
            } else if (statusFilter === 'suspended') {
                url = '/admin/users/status/inactive?page=0&size=10';
            }
            
            const response = await this.apiCall(url);
            if (response && response.content) {
                this.renderUsersTable(response.content);
                this.renderPagination(response, 'users');
            }
        } catch (error) {
            this.showAlert('Failed to filter users: ' + error.message, 'danger');
        } finally {
            this.hideLoading();
        }
    }

    // Trip Management Functions
    async deleteTrip(tripId) {
        if (confirm('Are you sure you want to delete this trip? This action cannot be undone.')) {
            try {
                const response = await this.apiCall(`/admin/trips/${tripId}`, 'DELETE');
                if (response) {
                    this.showAlert('Trip deleted successfully!', 'success');
                    this.loadTrips();
                }
            } catch (error) {
                this.showAlert('Failed to delete trip: ' + error.message, 'danger');
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

    // Mock data creation methods
    createMockUsers(stats) {
        const mockUsers = [];
        const totalUsers = stats.totalUsers || 50;
        const roles = ['USER', 'DRIVER', 'ADMIN'];
        const statuses = ['ACTIVE', 'INACTIVE', 'PENDING', 'SUSPENDED'];
        
        for (let i = 1; i <= Math.min(totalUsers, 10); i++) {
            mockUsers.push({
                id: i,
                firstName: `User${i}`,
                lastName: `LastName${i}`,
                email: `user${i}@example.com`,
                phoneNumber: `+216 12 345 67${i}`,
                role: roles[i % 3],
                isActive: i % 4 !== 3,
                isVerified: i % 3 !== 0,
                createdAt: new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000).toISOString(),
                status: statuses[i % 4]
            });
        }
        return mockUsers;
    }

    createMockTrips(stats) {
        const mockTrips = [];
        const totalTrips = stats.totalTrips || 25;
        const cities = ['Tunis', 'Sfax', 'Sousse', 'Monastir', 'Bizerte', 'Gabès'];
        const statuses = ['AVAILABLE', 'COMPLETED', 'CANCELLED', 'IN_PROGRESS'];
        
        for (let i = 1; i <= Math.min(totalTrips, 10); i++) {
            const departure = cities[Math.floor(Math.random() * cities.length)];
            let arrival = cities[Math.floor(Math.random() * cities.length)];
            while (arrival === departure) {
                arrival = cities[Math.floor(Math.random() * cities.length)];
            }
            
            mockTrips.push({
                id: i,
                driver: {
                    firstName: `Driver${i}`,
                    lastName: `LastName${i}`
                },
                points: [
                    { address: departure },
                    { address: arrival }
                ],
                departureTime: new Date(Date.now() + Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
                pricePerSeat: Math.floor(Math.random() * 50) + 10,
                availableSeats: Math.floor(Math.random() * 4) + 1,
                maxSeats: 4,
                status: statuses[i % 4]
            });
        }
        return mockTrips;
    }

    createMockCities() {
        const cities = [
            { id: 1, name: 'Tunis', codePostal: '1000', pays: 'Tunisie', latitude: 36.8065, longitude: 10.1815 },
            { id: 2, name: 'Sfax', codePostal: '3000', pays: 'Tunisie', latitude: 34.7406, longitude: 10.7603 },
            { id: 3, name: 'Sousse', codePostal: '4000', pays: 'Tunisie', latitude: 35.8256, longitude: 10.6411 },
            { id: 4, name: 'Monastir', codePostal: '5000', pays: 'Tunisie', latitude: 35.7833, longitude: 10.8333 },
            { id: 5, name: 'Bizerte', codePostal: '7000', pays: 'Tunisie', latitude: 37.2744, longitude: 9.8739 },
            { id: 6, name: 'Gabès', codePostal: '6000', pays: 'Tunisie', latitude: 33.8815, longitude: 10.0982 }
        ];
        return cities;
    }

    // City management methods
    editCity(cityId) {
        console.log('Editing city:', cityId);
        // For now, just show an alert
        this.showAlert(`Edit city functionality for ID ${cityId} - Coming soon!`, 'info');
    }

    deleteCity(cityId) {
        if (confirm('Are you sure you want to delete this city?')) {
            console.log('Deleting city:', cityId);
            // For now, just show an alert
            this.showAlert(`Delete city functionality for ID ${cityId} - Coming soon!`, 'info');
        }
    }

    // Authentication methods
    logout() {
        if (confirm('Êtes-vous sûr de vouloir vous déconnecter ?')) {
            localStorage.removeItem('adminToken');
            localStorage.removeItem('adminUser');
            window.location.href = '/admin-login.html';
        }
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

// Global functions for new features
async function runCleanup(dryRun) {
    const confirmed = dryRun || confirm('Are you sure you want to execute cleanup? This will permanently delete old trips and related data.');
    if (!confirmed) return;
    
    try {
        const response = await fetch(`http://localhost:8081/api/admin/maintenance/cleanup?dryRun=${dryRun}`, {
            method: 'POST',
            headers: { 'Authorization': `Bearer ${localStorage.getItem('adminToken')}` }
        });
        const result = await response.json();
        document.getElementById('cleanup-results').innerHTML = `
            <div class="alert alert-${dryRun ? 'info' : 'success'}">
                <h6>${dryRun ? 'Dry Run' : 'Cleanup'} Results:</h6>
                <p>Cutoff: ${result.cutoff || 'N/A'}</p>
                <p>Voyages to delete: ${result.voyages || result.deletedVoyages || 0}</p>
                <p>Reservations to delete: ${result.reservations || result.deletedReservations || 0}</p>
            </div>
        `;
    } catch (e) {
        document.getElementById('cleanup-results').innerHTML = `<div class="alert alert-danger">Error: ${e.message}</div>`;
    }
}

async function loadPendingTransfers() {
    try {
        const response = await fetch('http://localhost:8081/api/payments/admin/pending-transfers', {
            headers: { 'Authorization': `Bearer ${localStorage.getItem('adminToken')}` }
        });
        const transfers = await response.json();
        const tbody = document.getElementById('pending-transfers-table');
        if (transfers.length === 0) {
            tbody.innerHTML = '<tr><td colspan="5" class="text-center">No pending transfers</td></tr>';
            return;
        }
        tbody.innerHTML = transfers.map(t => `
            <tr>
                <td>#${t.id}</td>
                <td>Reservation #${t.reservationId}</td>
                <td>${t.amount.toFixed(2)} TND</td>
                <td>${new Date(t.paymentDate || Date.now()).toLocaleDateString()}</td>
                <td><button class="btn btn-sm btn-success" onclick="approveTransfer(${t.id})">Approve</button></td>
            </tr>
        `).join('');
    } catch (e) {
        console.error('Failed to load pending transfers:', e);
    }
}

async function approveTransfer(paymentId) {
    const transactionId = prompt('Enter bank transaction reference (optional):');
    const notes = prompt('Enter approval notes (optional):');
    
    try {
        const response = await fetch(`http://localhost:8081/api/payments/admin/${paymentId}/approve-transfer`, {
            method: 'POST',
            headers: {
                'Authorization': `Bearer ${localStorage.getItem('adminToken')}`,
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ transactionId, notes })
        });
        
        if (response.ok) {
            alert('Transfer approved successfully!');
            loadPendingTransfers();
        } else {
            alert('Failed to approve transfer');
        }
    } catch (e) {
        alert('Error: ' + e.message);
    }
}

async function loadSystemHealth() {
    try {
        const response = await fetch('http://localhost:8081/api/admin/monitoring/health');
        const health = await response.json();
        
        document.getElementById('db-status').textContent = health.database?.status || 'Unknown';
        document.getElementById('stripe-status').textContent = health.stripe?.status || 'Unknown';
        document.getElementById('email-status').textContent = health.email?.status || 'Unknown';
        
        const cleanupResp = await fetch('http://localhost:8081/api/admin/maintenance/cleanup/stats');
        const cleanupStats = await cleanupResp.json();
        document.getElementById('cleanup-status').textContent = cleanupStats.lastRunTime ? 'OK' : 'Never';
    } catch (e) {
        console.error('Failed to load system health:', e);
    }
}

async function loadAnalytics() {
    try {
        const [revenue, routes, userStats] = await Promise.all([
            fetch('http://localhost:8081/api/admin/analytics/revenue').then(r => r.json()),
            fetch('http://localhost:8081/api/admin/analytics/popular-routes').then(r => r.json()),
            fetch('http://localhost:8081/api/admin/analytics/user-stats').then(r => r.json())
        ]);
        
        document.getElementById('analytics-revenue').textContent = (revenue.totalRevenue || 0).toFixed(2);
        document.getElementById('analytics-growth').textContent = revenue.periodRevenue ? 
            `+${((revenue.periodRevenue / revenue.totalRevenue) * 100).toFixed(1)}%` : 'N/A';
        document.getElementById('analytics-drivers').textContent = userStats.totalDrivers || 0;
        document.getElementById('analytics-passengers').textContent = userStats.totalPassengers || 0;
        
        const tbody = document.getElementById('popular-routes-table');
        tbody.innerHTML = routes.map(r => `
            <tr>
                <td>${r.departure_city} → ${r.arrival_city}</td>
                <td>${r.trip_count}</td>
                <td>${r.avg_price ? r.avg_price.toFixed(2) : '0'} TND</td>
                <td>${r.total_passengers || 0}</td>
            </tr>
        `).join('');
    } catch (e) {
        console.error('Failed to load analytics:', e);
    }
}

function viewBookingDetails(bookingId) {
    alert('Booking details for #' + bookingId + ' - Full details view coming soon');
}

function downloadReceipt(paymentId) {
    window.open(`http://localhost:8081/api/payments/${paymentId}/receipt`, '_blank');
}

function downloadPaymentsExport() {
    window.open('http://localhost:8081/api/payments/admin/export', '_blank');
}

// Initialize the dashboard when the page loads
let adminDashboard;
document.addEventListener('DOMContentLoaded', () => {
    adminDashboard = new AdminDashboard();
    
    // Auto-refresh monitoring every 30 seconds if on monitoring page
    setInterval(() => {
        if (adminDashboard.currentSection === 'monitoring') {
            loadSystemHealth();
        }
    }, 30000);
});


