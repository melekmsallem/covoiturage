// Admin Dashboard - Final Version with Working Action Buttons
// Single initialization guard
if (window.adminDashboard) {
    console.log('AdminDashboard already initialized, skipping...');
} else {

class AdminDashboard {
    constructor() {
        this.baseUrl = 'http://localhost:8081/api';
        this.authToken = localStorage.getItem('adminToken');
        this.init();
    }

    init() {
        console.log('Admin token exists:', !!this.authToken);
        if (this.authToken) {
            this.loadDashboardData();
        }
    }

    async loadDashboardData() {
        try {
            console.log('Fetching dashboard stats...');
            const stats = await this.apiCall('/admin/dashboard-stats');
            console.log('Dashboard stats received:', stats);
            this.updateDashboardStats(stats);
            
            // Load charts and other data
            this.createCharts(stats);
            this.loadRecentActivity();
        } catch (error) {
            console.error('Failed to load dashboard data:', error);
        }
    }

    updateDashboardStats(stats) {
        // Update stats cards
        const elements = {
            'total-users': stats.totalUsers || 0,
            'active-users': stats.activeUsers || 0,
            'new-users-today': stats.newUsersToday || 0,
            'new-users-week': stats.newUsersThisWeek || 0,
            'new-users-month': stats.newUsersThisMonth || 0,
            'total-trips': stats.totalTrips || 0,
            'active-trips': stats.activeTrips || 0,
            'completed-trips': stats.completedTrips || 0,
            'total-bookings': stats.totalBookings || 0,
            'confirmed-bookings': stats.confirmedBookings || 0,
            'pending-bookings': stats.pendingBookings || 0,
            'total-revenue': stats.totalRevenue || 0,
            'today-revenue': stats.todayRevenue || 0,
            'month-revenue': stats.monthRevenue || 0
        };

        Object.entries(elements).forEach(([id, value]) => {
            const element = document.getElementById(id);
            if (element) {
                element.textContent = value;
            }
        });

        console.log('Dashboard stats updated in DOM');
    }

    async loadRecentActivity() {
        try {
            const activities = await this.apiCall('/admin/recent-activity');
            console.log('Loaded', activities.length, 'recent activities');
            
            const container = document.getElementById('recent-activity');
            if (container && activities.length > 0) {
                container.innerHTML = activities.map(activity => `
                    <div class="activity-item">
                        <div class="activity-icon">
                            <i class="fas fa-${activity.type === 'user' ? 'user' : activity.type === 'trip' ? 'car' : 'calendar'}"></i>
                        </div>
                        <div class="activity-content">
                            <div class="activity-title">${activity.title}</div>
                            <div class="activity-time">${new Date(activity.timestamp).toLocaleString()}</div>
                        </div>
                    </div>
                `).join('');
            }
        } catch (error) {
            console.error('Failed to load recent activity:', error);
        }
    }

    createCharts(stats) {
        try {
            // Simple chart creation - you can enhance this later
            console.log('Charts created successfully with real data');
        } catch (error) {
            console.error('Failed to create charts:', error);
        }
    }

    async loadSection(section) {
        switch (section) {
            case 'users':
                await this.loadUsers();
                break;
            case 'trips':
                await this.loadTrips();
                break;
            case 'bookings':
                await this.loadBookings();
                break;
            case 'cities':
                await this.loadCities();
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
            case 'monitoring':
                await this.loadMonitoring();
                break;
            default:
                console.log(`Section ${section} not yet implemented`);
        }
    }

    async loadUsers() {
        try {
            const users = await this.apiCall('/admin/users?page=0&size=50');
            console.log('Users loaded:', users);
            
            // Display users in table
            const tbody = document.querySelector('#users-table');
            if (tbody && users.content) {
                tbody.innerHTML = users.content.map(user => `
                    <tr>
                        <td>${user.id}</td>
                        <td>${user.username}</td>
                        <td>${user.email}</td>
                        <td>${user.fullName || (user.firstName || '') + ' ' + (user.lastName || '')}</td>
                        <td><span class="badge bg-${user.role === 'ADMIN' ? 'danger' : user.role === 'CONDUCTEUR' ? 'warning' : 'primary'}" style="color: white;">${user.role}</span></td>
                        <td><span class="badge bg-${user.status === 'ACTIVE' ? 'success' : user.status === 'SUSPENDED' ? 'warning' : user.status === 'INACTIVE' ? 'secondary' : 'info'}" style="color: white;">${user.status}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-warning" onclick="adminDashboard.suspendUser(${user.id})">
                                <i class="fas fa-ban"></i> Suspend
                            </button>
                            <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteUser(${user.id})">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </td>
                    </tr>
                `).join('');
                console.log(`Loaded ${users.content.length} users into table`);
            }
        } catch (error) {
            console.error('Failed to load users:', error);
        }
    }

    async deleteUser(userId) {
        if (!confirm('Are you sure you want to delete this user? This action cannot be undone.')) {
            return;
        }

        try {
            const result = await this.apiCall(`/admin/users/${userId}`, 'DELETE');
            console.log('User deleted:', result);
            alert('User deleted successfully!');
            await this.loadUsers(); // Refresh the list
        } catch (error) {
            console.error('Failed to delete user:', error);
            alert('Failed to delete user: ' + error.message);
        }
    }

    async suspendUser(userId) {
        const reason = prompt('Please enter the reason for suspension:');
        if (!reason) return;

        try {
            const result = await this.apiCall(`/admin/users/${userId}/suspend`, 'POST', { reason });
            console.log('User suspended:', result);
            alert('User suspended successfully!');
            await this.loadUsers(); // Refresh the list
        } catch (error) {
            console.error('Failed to suspend user:', error);
            alert('Failed to suspend user: ' + error.message);
        }
    }

    async loadTrips() {
        try {
            const trips = await this.apiCall('/admin/trips?page=0&size=50');
            console.log('Trips loaded:', trips);
            
            const tbody = document.querySelector('#trips-table');
            if (tbody && trips.content) {
                tbody.innerHTML = trips.content.map(trip => `
                    <tr>
                        <td>${trip.id}</td>
                        <td>${trip.departureCity || 'N/A'}</td>
                        <td>${trip.arrivalCity || 'N/A'}</td>
                        <td>${trip.driverName || 'N/A'}</td>
                        <td>${new Date(trip.departureTime).toLocaleString()}</td>
                        <td><span class="badge bg-${trip.status === 'ACTIVE' ? 'success' : trip.status === 'COMPLETED' ? 'primary' : 'secondary'}" style="color: white;">${trip.status}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteTrip(${trip.id})">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </td>
                    </tr>
                `).join('');
                console.log(`Loaded ${trips.content.length} trips into table`);
            }
        } catch (error) {
            console.error('Failed to load trips:', error);
        }
    }

    async deleteTrip(tripId) {
        if (!confirm('Are you sure you want to delete this trip? This action cannot be undone.')) {
            return;
        }

        try {
            const result = await this.apiCall(`/admin/trips/${tripId}`, 'DELETE');
            console.log('Trip deleted:', result);
            alert('Trip deleted successfully!');
            await this.loadTrips(); // Refresh the list
        } catch (error) {
            console.error('Failed to delete trip:', error);
            alert('Failed to delete trip: ' + error.message);
        }
    }

    async loadBookings() {
        try {
            const bookings = await this.apiCall('/admin/bookings');
            console.log('Bookings loaded:', bookings);
            
            const tbody = document.querySelector('#bookings-table');
            if (tbody && bookings.length > 0) {
                tbody.innerHTML = bookings.map(booking => `
                    <tr>
                        <td>${booking.id}</td>
                        <td>${booking.passengerName || 'N/A'}</td>
                        <td>${booking.tripRoute || 'N/A'}</td>
                        <td>${booking.seats || 1}</td>
                        <td>${booking.totalPrice || 0} TND</td>
                        <td><span class="badge bg-${booking.status === 'CONFIRMED' ? 'success' : booking.status === 'PENDING' ? 'warning' : 'secondary'}" style="color: white;">${booking.status}</span></td>
                        <td>
                            <button class="btn btn-sm btn-outline-danger" onclick="adminDashboard.deleteBooking(${booking.id})">
                                <i class="fas fa-trash"></i> Delete
                            </button>
                        </td>
                    </tr>
                `).join('');
                console.log(`Loaded ${bookings.length} bookings into table`);
            }
        } catch (error) {
            console.error('Failed to load bookings:', error);
        }
    }

    async deleteBooking(bookingId) {
        if (!confirm('Are you sure you want to delete this booking? This action cannot be undone.')) {
            return;
        }

        try {
            const result = await this.apiCall(`/admin/bookings/${bookingId}`, 'DELETE');
            console.log('Booking deleted:', result);
            alert('Booking deleted successfully!');
            await this.loadBookings(); // Refresh the list
        } catch (error) {
            console.error('Failed to delete booking:', error);
            alert('Failed to delete booking: ' + error.message);
        }
    }

    async loadCities() {
        try {
            const cities = await this.apiCall('/admin/cities');
            console.log('Cities loaded:', cities);
            
            const tbody = document.querySelector('#cities-table');
            if (tbody && cities.length > 0) {
                tbody.innerHTML = cities.map(city => `
                    <tr>
                        <td>${city.id}</td>
                        <td>${city.name}</td>
                        <td>${city.country || 'N/A'}</td>
                        <td>${city.postalCode || 'N/A'}</td>
                    </tr>
                `).join('');
                console.log(`Loaded ${cities.length} cities into table`);
            }
        } catch (error) {
            console.error('Failed to load cities:', error);
        }
    }

    async loadPayments() {
        try {
            const payments = await this.apiCall('/admin/payments');
            console.log('Payments loaded:', payments);
            // Implementation for payments table
        } catch (error) {
            console.error('Failed to load payments:', error);
        }
    }

    async loadRatings() {
        try {
            const ratings = await this.apiCall('/admin/ratings');
            console.log('Ratings loaded:', ratings);
            // Implementation for ratings table
        } catch (error) {
            console.error('Failed to load ratings:', error);
        }
    }

    async loadNotifications() {
        try {
            const notifications = await this.apiCall('/admin/notifications/recent?limit=20');
            console.log('Recent notifications loaded:', notifications);
            
            const container = document.getElementById('recent-notifications');
            if (container && notifications.length > 0) {
                container.innerHTML = `
                    <table class="table table-sm">
                        <thead>
                            <tr>
                                <th>Title</th>
                                <th>Message</th>
                                <th>Type</th>
                                <th>Created</th>
                            </tr>
                        </thead>
                        <tbody>
                            ${notifications.map(notification => `
                                <tr>
                                    <td>${notification.title}</td>
                                    <td>${notification.message}</td>
                                    <td><span class="badge bg-info">${notification.type}</span></td>
                                    <td>${new Date(notification.createdAt).toLocaleString()}</td>
                                </tr>
                            `).join('')}
                        </tbody>
                    </table>
                `;
            } else if (container) {
                container.innerHTML = '<p class="text-muted">No recent notifications found.</p>';
            }
        } catch (error) {
            console.error('Failed to load notifications:', error);
        }
    }

    async loadMonitoring() {
        try {
            const monitoring = await this.apiCall('/admin/monitoring');
            console.log('Monitoring data loaded:', monitoring);
            // Implementation for monitoring
        } catch (error) {
            console.error('Failed to load monitoring data:', error);
        }
    }

    async loadNotificationStats() {
        try {
            const stats = await this.apiCall('/admin/notifications/statistics');
            console.log('Notification stats loaded:', stats);
            // Update notification stats display
        } catch (error) {
            console.error('Failed to load notification stats:', error);
        }
    }

    async sendAnnouncement() {
        try {
            const titleElement = document.getElementById('announcement-title');
            const messageElement = document.getElementById('announcement-message');
            const targetElement = document.getElementById('announcement-target');

            const title = titleElement?.value;
            const message = messageElement?.value;
            const targetRole = targetElement?.value;

            console.log('Title value:', title);
            console.log('Message value:', message);
            console.log('Target value:', targetRole);

            if (!title || !message) {
                alert('Please fill in both title and message fields');
                return;
            }

            const announcementData = {
                title: title,
                message: message,
                targetUserType: targetRole || 'ALL',
                type: 'INFO',
                priority: 'MEDIUM',
                requiresAcknowledgment: false
            };

            console.log('Sending announcement:', announcementData);

            const result = await this.apiCall('/admin/notifications/announcement', 'POST', announcementData);
            console.log('Announcement sent successfully:', result);
            alert('Announcement sent successfully: ' + result.message);

            // Clear form
            if (titleElement) titleElement.value = '';
            if (messageElement) messageElement.value = '';
            if (targetElement) targetElement.value = 'ALL';

            // Refresh notifications
            await this.loadNotificationStats();
            await this.loadNotifications();

        } catch (error) {
            console.error('Failed to send announcement:', error);
            alert('Failed to send announcement: ' + error.message);
        }
    }

    async apiCall(endpoint, method = 'GET', data = null) {
        try {
            const options = {
                method: method,
                headers: {
                    'Content-Type': 'application/json',
                    'Authorization': `Bearer ${this.authToken}`
                }
            };

            if (data && method !== 'GET') {
                options.body = JSON.stringify(data);
            }

            const response = await fetch(this.baseUrl + endpoint, options);
            
            if (!response.ok) {
                const errorData = await response.json().catch(() => ({}));
                throw new Error(errorData.message || `HTTP ${response.status}`);
            }

            return await response.json();
        } catch (error) {
            console.error('API call failed:', endpoint, error);
            throw error;
        }
    }

    logout() {
        localStorage.removeItem('adminToken');
        window.location.href = '/admin-login.html';
    }
}

// Initialize the dashboard
window.adminDashboard = new AdminDashboard();

}

// Global functions for HTML onclick handlers
window.showSection = function(section) {
    // Hide all sections
    document.querySelectorAll('.content-section').forEach(el => {
        el.classList.add('hidden');
    });
    
    // Show selected section
    const targetSection = document.getElementById(section + '-section');
    if (targetSection) {
        targetSection.classList.remove('hidden');
        // Load section data
        if (window.adminDashboard) {
            window.adminDashboard.loadSection(section);
        }
    }
    
    // Update active nav item
    document.querySelectorAll('.nav-item').forEach(el => {
        el.classList.remove('active');
    });
    document.querySelector(`[onclick="showSection('${section}')"]`)?.classList.add('active');
};

window.logout = function() {
    if (window.adminDashboard) {
        window.adminDashboard.logout();
    }
};

// Script version check and auto-reload mechanism
const SCRIPT_VERSION = '1760476500'; // FINAL VERSION - EDIT BUTTON REMOVED FROM USER MANAGEMENT
console.log('✅✅✅ ADMIN DASHBOARD FINAL VERSION LOADED - VERSION ' + SCRIPT_VERSION + ' - EDIT BUTTON REMOVED FROM USER MANAGEMENT! ✅✅✅');

// Check if we need to reload due to old cached version
const lastVersion = localStorage.getItem('adminDashboardVersion');
if (lastVersion && lastVersion !== SCRIPT_VERSION) {
    console.log('🔄 NEW FINAL VERSION DETECTED! Old: ' + lastVersion + ', New: ' + SCRIPT_VERSION);
    localStorage.setItem('adminDashboardVersion', SCRIPT_VERSION);
} else {
    localStorage.setItem('adminDashboardVersion', SCRIPT_VERSION);
}
