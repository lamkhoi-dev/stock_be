import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { adminApi } from '../api';
import {
  ArrowLeft,
  Crown,
  Shield,
  Ban,
  CheckCircle,
  Mail,
  Calendar,
  Clock,
  Star,
  BrainCircuit,
  AlertTriangle,
} from 'lucide-react';
import { format } from 'date-fns';

export default function UserDetailPage() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [actionLoading, setActionLoading] = useState('');

  useEffect(() => {
    loadUser();
  }, [id]);

  const loadUser = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getUserDetail(id);
      setData(res.data.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to load user');
    } finally {
      setLoading(false);
    }
  };

  const handleBlock = async () => {
    if (!data) return;
    const shouldBlock = !data.user.isBlocked;
    const reason = shouldBlock ? prompt('Block reason (optional):') : null;
    if (shouldBlock && reason === null) return; // Cancelled

    try {
      setActionLoading('block');
      await adminApi.blockUser(id, shouldBlock, reason || undefined);
      await loadUser();
    } catch (err) {
      alert(err.response?.data?.message || 'Action failed');
    } finally {
      setActionLoading('');
    }
  };

  const handlePlanChange = async (plan) => {
    try {
      setActionLoading('plan');
      await adminApi.updateSubscription(id, { plan });
      await loadUser();
    } catch (err) {
      alert(err.response?.data?.message || 'Action failed');
    } finally {
      setActionLoading('');
    }
  };

  const handleAddCredits = async () => {
    const amount = prompt('Add credits:');
    if (!amount || isNaN(amount) || parseInt(amount) <= 0) return;

    try {
      setActionLoading('credits');
      await adminApi.updateSubscription(id, { addCredits: parseInt(amount) });
      await loadUser();
    } catch (err) {
      alert(err.response?.data?.message || 'Action failed');
    } finally {
      setActionLoading('');
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent" />
      </div>
    );
  }

  if (error) {
    return (
      <div className="text-center py-20">
        <AlertTriangle className="mx-auto mb-3 text-red-400" size={32} />
        <p className="text-red-400 mb-3">{error}</p>
        <button
          onClick={() => navigate('/users')}
          className="px-4 py-2 bg-navy-700 text-gray-300 rounded-lg text-sm"
        >
          Back to Users
        </button>
      </div>
    );
  }

  const { user: u, stats } = data;

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Back */}
      <button
        onClick={() => navigate('/users')}
        className="flex items-center gap-2 text-gray-400 hover:text-white text-sm transition-colors"
      >
        <ArrowLeft size={16} /> Back to Users
      </button>

      {/* Header Card */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-6">
        <div className="flex items-start gap-4">
          <div className="w-14 h-14 rounded-full bg-accent/20 flex items-center justify-center text-accent text-xl font-bold">
            {u.name?.[0]?.toUpperCase() || '?'}
          </div>
          <div className="flex-1">
            <div className="flex items-center gap-2 flex-wrap">
              <h2 className="text-lg font-bold text-white">{u.name || 'Unnamed'}</h2>
              {u.role === 'admin' && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-accent/10 text-accent rounded-full text-xs">
                  <Shield size={12} /> Admin
                </span>
              )}
              {u.subscription?.plan === 'pro' && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-yellow-500/10 text-yellow-400 rounded-full text-xs">
                  <Crown size={12} /> Pro
                </span>
              )}
              {u.isBlocked && (
                <span className="inline-flex items-center gap-1 px-2 py-0.5 bg-red-500/10 text-red-400 rounded-full text-xs">
                  <Ban size={12} /> Blocked
                </span>
              )}
            </div>
            <div className="flex items-center gap-1 mt-1 text-gray-400 text-sm">
              <Mail size={14} /> {u.email}
              {u.emailVerified && (
                <CheckCircle size={14} className="text-green-400 ml-1" />
              )}
            </div>
          </div>
        </div>

        <div className="grid grid-cols-2 sm:grid-cols-4 gap-4 mt-5 text-sm">
          <div>
            <span className="text-gray-500">Provider</span>
            <p className="text-gray-200 capitalize">{u.provider || 'local'}</p>
          </div>
          <div>
            <span className="text-gray-500">Credits</span>
            <p className="text-gray-200">{u.subscription?.credits ?? 0}</p>
          </div>
          <div className="flex items-center gap-1">
            <Calendar size={14} className="text-gray-500" />
            <div>
              <span className="text-gray-500">Joined</span>
              <p className="text-gray-200">
                {u.createdAt ? format(new Date(u.createdAt), 'MMM dd, yyyy') : '—'}
              </p>
            </div>
          </div>
          <div className="flex items-center gap-1">
            <Clock size={14} className="text-gray-500" />
            <div>
              <span className="text-gray-500">Last Login</span>
              <p className="text-gray-200">
                {u.lastLoginAt ? format(new Date(u.lastLoginAt), 'MMM dd, HH:mm') : '—'}
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-3 gap-4">
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-4 text-center">
          <Star className="mx-auto mb-2 text-yellow-400" size={20} />
          <p className="text-lg font-bold text-white">{stats.watchlistCount}</p>
          <p className="text-xs text-gray-500">Watchlist Items</p>
        </div>
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-4 text-center">
          <BrainCircuit className="mx-auto mb-2 text-purple-400" size={20} />
          <p className="text-lg font-bold text-white">{stats.analysisCount}</p>
          <p className="text-xs text-gray-500">AI Analyses</p>
        </div>
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-4 text-center">
          <Crown className="mx-auto mb-2 text-accent" size={20} />
          <p className="text-lg font-bold text-white capitalize">{u.subscription?.plan || 'free'}</p>
          <p className="text-xs text-gray-500">Current Plan</p>
        </div>
      </div>

      {/* Recent Analyses */}
      {stats.recentAnalyses?.length > 0 && (
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-300 mb-3">Recent AI Analyses</h3>
          <div className="space-y-2">
            {stats.recentAnalyses.map((a) => (
              <div
                key={a._id}
                className="flex items-center justify-between py-2 border-b border-navy-600/50 last:border-0"
              >
                <div className="flex items-center gap-3">
                  <span className="text-gray-200 font-mono text-sm">{a.symbol}</span>
                  <span className={`text-xs px-2 py-0.5 rounded-full ${
                    a.level === 'pro'
                      ? 'bg-yellow-500/10 text-yellow-400'
                      : 'bg-accent/10 text-accent'
                  }`}>
                    {a.level}
                  </span>
                </div>
                <span className="text-xs text-gray-500">
                  {a.createdAt ? format(new Date(a.createdAt), 'MMM dd, HH:mm') : ''}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Actions */}
      {u.role !== 'admin' && (
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-300 mb-4">Admin Actions</h3>
          <div className="flex flex-wrap gap-3">
            {/* Block/Unblock */}
            <button
              onClick={handleBlock}
              disabled={actionLoading === 'block'}
              className={`px-4 py-2 rounded-lg text-sm font-medium transition-colors ${
                u.isBlocked
                  ? 'bg-green-500/10 text-green-400 hover:bg-green-500/20'
                  : 'bg-red-500/10 text-red-400 hover:bg-red-500/20'
              } disabled:opacity-50`}
            >
              {actionLoading === 'block'
                ? '...'
                : u.isBlocked
                ? 'Unblock User'
                : 'Block User'}
            </button>

            {/* Plan toggle */}
            <button
              onClick={() =>
                handlePlanChange(u.subscription?.plan === 'pro' ? 'free' : 'pro')
              }
              disabled={actionLoading === 'plan'}
              className="px-4 py-2 bg-yellow-500/10 text-yellow-400 hover:bg-yellow-500/20 rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
            >
              {actionLoading === 'plan'
                ? '...'
                : u.subscription?.plan === 'pro'
                ? 'Downgrade to Free'
                : 'Upgrade to Pro'}
            </button>

            {/* Add Credits */}
            <button
              onClick={handleAddCredits}
              disabled={actionLoading === 'credits'}
              className="px-4 py-2 bg-accent/10 text-accent hover:bg-accent/20 rounded-lg text-sm font-medium transition-colors disabled:opacity-50"
            >
              {actionLoading === 'credits' ? '...' : 'Add Credits'}
            </button>
          </div>

          {u.isBlocked && u.blockReason && (
            <div className="mt-3 px-3 py-2 bg-red-500/5 border border-red-500/10 rounded-lg text-sm text-red-400">
              Block reason: {u.blockReason}
            </div>
          )}
        </div>
      )}
    </div>
  );
}
