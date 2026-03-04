import axios from 'axios';

// Use env variable or default to production backend
const BASE_URL = import.meta.env.VITE_API_URL || 'https://stock-be-sv3n.onrender.com/api';

const api = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: { 'Content-Type': 'application/json' },
});

// Attach token to all requests
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('admin_token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Handle 401 → redirect to login
api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('admin_token');
      localStorage.removeItem('admin_user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  },
);

// ─── Auth ─────────────────────────────────────────
export const authApi = {
  login: (email, password) => api.post('/auth/login', { email, password }),
  getMe: () => api.get('/auth/me'),
};

// ─── Admin ────────────────────────────────────────
export const adminApi = {
  // Dashboard
  getStats: () => api.get('/admin/stats'),

  // Users
  getUsers: (params) => api.get('/admin/users', { params }),
  getUserDetail: (id) => api.get(`/admin/users/${id}`),
  blockUser: (id, blocked, reason) =>
    api.put(`/admin/users/${id}/block`, { blocked, reason }),
  updateSubscription: (id, data) =>
    api.put(`/admin/users/${id}/subscription`, data),

  // Config
  getConfig: () => api.get('/admin/config'),

  // Logs
  getLogs: (params) => api.get('/admin/logs', { params }),
  exportLogs: (params) => api.get('/admin/logs/export', { params, responseType: 'blob' }),
};

export default api;
