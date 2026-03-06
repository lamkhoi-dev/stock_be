import { useState, useEffect, useCallback } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { adminApi } from '../api';
import { Search, ChevronLeft, ChevronRight, Crown, Shield, Ban } from 'lucide-react';
import { format } from 'date-fns';

export default function UsersPage() {
  const navigate = useNavigate();
  const [searchParams, setSearchParams] = useSearchParams();

  const [users, setUsers] = useState([]);
  const [pagination, setPagination] = useState({ page: 1, pages: 1, total: 0 });
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState(searchParams.get('search') || '');
  const [planFilter, setPlanFilter] = useState(searchParams.get('plan') || '');
  const [statusFilter, setStatusFilter] = useState(searchParams.get('status') || '');

  const page = parseInt(searchParams.get('page')) || 1;

  const loadUsers = useCallback(async () => {
    try {
      setLoading(true);
      const params = { page, limit: 20 };
      if (search) params.search = search;
      if (planFilter) params.plan = planFilter;
      if (statusFilter) params.status = statusFilter;

      const res = await adminApi.getUsers(params);
      setUsers(res.data.data.users);
      setPagination(res.data.data.pagination);
    } catch (err) {
      console.error('Failed to load users:', err);
    } finally {
      setLoading(false);
    }
  }, [page, search, planFilter, statusFilter]);

  useEffect(() => {
    loadUsers();
  }, [loadUsers]);

  const updateParams = (updates) => {
    const params = Object.fromEntries(searchParams.entries());
    Object.assign(params, updates);
    // Remove empty params
    Object.keys(params).forEach((k) => {
      if (!params[k]) delete params[k];
    });
    setSearchParams(params);
  };

  const handleSearch = (e) => {
    e.preventDefault();
    updateParams({ search, page: '1' });
  };

  return (
    <div className="space-y-4">
      <h1 className="text-xl font-bold text-white">Users</h1>

      {/* Filters */}
      <div className="flex flex-wrap items-center gap-3">
        <form onSubmit={handleSearch} className="flex-1 min-w-[200px] max-w-sm">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search by name or email..."
              className="w-full pl-9 pr-4 py-2 bg-navy-800 border border-navy-600 rounded-lg text-sm text-gray-200 focus:outline-none focus:border-accent"
            />
          </div>
        </form>

        <select
          value={planFilter}
          onChange={(e) => {
            setPlanFilter(e.target.value);
            updateParams({ plan: e.target.value, page: '1' });
          }}
          className="px-3 py-2 bg-navy-800 border border-navy-600 rounded-lg text-sm text-gray-300 focus:outline-none focus:border-accent"
        >
          <option value="">All Plans</option>
          <option value="free">Free</option>
          <option value="pro">Pro</option>
        </select>

        <select
          value={statusFilter}
          onChange={(e) => {
            setStatusFilter(e.target.value);
            updateParams({ status: e.target.value, page: '1' });
          }}
          className="px-3 py-2 bg-navy-800 border border-navy-600 rounded-lg text-sm text-gray-300 focus:outline-none focus:border-accent"
        >
          <option value="">All Status</option>
          <option value="active">Active</option>
          <option value="blocked">Blocked</option>
        </select>

        <span className="text-xs text-gray-500">{pagination.total} users</span>
      </div>

      {/* Table */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-sm">
            <thead>
              <tr className="border-b border-navy-600 text-gray-400 text-left">
                <th className="px-4 py-3 font-medium">User</th>
                <th className="px-4 py-3 font-medium">Plan</th>
                <th className="px-4 py-3 font-medium hidden md:table-cell">Role</th>
                <th className="px-4 py-3 font-medium">Status</th>
                <th className="px-4 py-3 font-medium hidden lg:table-cell">Credits</th>
                <th className="px-4 py-3 font-medium hidden lg:table-cell">Last Login</th>
                <th className="px-4 py-3 font-medium hidden md:table-cell">Joined</th>
              </tr>
            </thead>
            <tbody>
              {loading ? (
                Array.from({ length: 5 }).map((_, i) => (
                  <tr key={i} className="border-b border-navy-600/50">
                    <td colSpan={7} className="px-4 py-3">
                      <div className="h-4 bg-navy-700 rounded animate-pulse" />
                    </td>
                  </tr>
                ))
              ) : users.length === 0 ? (
                <tr>
                  <td colSpan={7} className="text-center py-12 text-gray-500">
                    No users found
                  </td>
                </tr>
              ) : (
                users.map((u) => (
                  <tr
                    key={u._id}
                    onClick={() => navigate(`/users/${u._id}`)}
                    className="border-b border-navy-600/50 hover:bg-navy-700/50 cursor-pointer transition-colors"
                  >
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-accent/20 flex items-center justify-center text-accent text-xs font-semibold">
                          {u.name?.[0]?.toUpperCase() || '?'}
                        </div>
                        <div>
                          <p className="text-gray-200 font-medium">{u.name || '—'}</p>
                          <p className="text-gray-500 text-xs">{u.email}</p>
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3">
                      {u.subscription?.plan === 'pro' ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-yellow-500/10 text-yellow-400 rounded-full text-xs">
                          <Crown size={12} /> Pro
                        </span>
                      ) : (
                        <span className="text-gray-500 text-xs">Free</span>
                      )}
                    </td>
                    <td className="px-4 py-3 hidden md:table-cell">
                      {u.role === 'admin' ? (
                        <span className="inline-flex items-center gap-1 text-accent text-xs">
                          <Shield size={12} /> Admin
                        </span>
                      ) : (
                        <span className="text-gray-500 text-xs">User</span>
                      )}
                    </td>
                    <td className="px-4 py-3">
                      {u.isBlocked ? (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-500/10 text-red-400 rounded-full text-xs">
                          <Ban size={12} /> Blocked
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-green-500/10 text-green-400 rounded-full text-xs">
                          Active
                        </span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-gray-400 hidden lg:table-cell">
                      {u.subscription?.credits ?? 0}
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-xs hidden lg:table-cell">
                      {u.lastLoginAt ? format(new Date(u.lastLoginAt), 'MMM dd, HH:mm') : '—'}
                    </td>
                    <td className="px-4 py-3 text-gray-400 text-xs hidden md:table-cell">
                      {u.createdAt ? format(new Date(u.createdAt), 'MMM dd, yyyy') : '—'}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>

        {/* Pagination */}
        {pagination.pages > 1 && (
          <div className="flex items-center justify-between px-4 py-3 border-t border-navy-600">
            <span className="text-xs text-gray-500">
              Page {pagination.page} of {pagination.pages}
            </span>
            <div className="flex gap-2">
              <button
                disabled={page <= 1}
                onClick={() => updateParams({ page: String(page - 1) })}
                className="p-1.5 rounded-lg bg-navy-700 disabled:opacity-30 hover:bg-navy-600 transition-colors"
              >
                <ChevronLeft size={16} />
              </button>
              <button
                disabled={page >= pagination.pages}
                onClick={() => updateParams({ page: String(page + 1) })}
                className="p-1.5 rounded-lg bg-navy-700 disabled:opacity-30 hover:bg-navy-600 transition-colors"
              >
                <ChevronRight size={16} />
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
