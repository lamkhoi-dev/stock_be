import { useState, useEffect } from 'react';
import { adminApi } from '../api';
import {
  Users,
  UserCheck,
  UserX,
  Crown,
  BrainCircuit,
  Wifi,
  AlertTriangle,
  Clock,
  HardDrive,
  Database,
} from 'lucide-react';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
} from 'recharts';

function StatCard({ icon: Icon, label, value, color = 'accent', sub }) {
  const colors = {
    accent: 'bg-accent/10 text-accent',
    green: 'bg-green-500/10 text-green-400',
    red: 'bg-red-500/10 text-red-400',
    gold: 'bg-yellow-500/10 text-yellow-400',
    purple: 'bg-purple-500/10 text-purple-400',
    cyan: 'bg-cyan-500/10 text-cyan-400',
  };
  return (
    <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
      <div className="flex items-center gap-3 mb-3">
        <div className={`w-9 h-9 rounded-lg flex items-center justify-center ${colors[color]}`}>
          <Icon size={18} />
        </div>
        <span className="text-sm text-gray-400">{label}</span>
      </div>
      <p className="text-2xl font-bold text-white">{value ?? '—'}</p>
      {sub && <p className="text-xs text-gray-500 mt-1">{sub}</p>}
    </div>
  );
}

export default function DashboardPage() {
  const [stats, setStats] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadStats();
  }, []);

  const loadStats = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getStats();
      setStats(res.data.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to load stats');
    } finally {
      setLoading(false);
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
        <p className="text-red-400">{error}</p>
        <button
          onClick={loadStats}
          className="mt-3 px-4 py-2 bg-accent/10 text-accent rounded-lg text-sm hover:bg-accent/20 transition-colors"
        >
          Retry
        </button>
      </div>
    );
  }

  const { users, ai, websocket, system } = stats;

  const uptimeHours = Math.floor(system.uptime / 3600);
  const uptimeMinutes = Math.floor((system.uptime % 3600) / 60);

  // Build chart data for overview
  const chartData = [
    { name: 'Total Users', value: users.total },
    { name: 'Pro Users', value: users.pro },
    { name: 'Blocked', value: users.blocked },
    { name: 'AI Today', value: ai.todayAnalyses },
    { name: 'Errors', value: system.todayErrors },
  ];

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-xl font-bold text-white">Dashboard</h1>
        <button
          onClick={loadStats}
          className="px-3 py-1.5 bg-navy-700 hover:bg-navy-600 text-gray-300 rounded-lg text-xs transition-colors"
        >
          Refresh
        </button>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-4">
        <StatCard
          icon={Users}
          label="Total Users"
          value={users.total}
          color="accent"
          sub={`+${users.todaySignups} today`}
        />
        <StatCard
          icon={UserCheck}
          label="Active Users"
          value={users.active}
          color="green"
        />
        <StatCard
          icon={UserX}
          label="Blocked"
          value={users.blocked}
          color="red"
        />
        <StatCard
          icon={Crown}
          label="Pro Users"
          value={users.pro}
          color="gold"
        />
        <StatCard
          icon={BrainCircuit}
          label="AI Analyses Today"
          value={ai.todayAnalyses}
          color="purple"
          sub={`${ai.totalAnalyses} total`}
        />
        <StatCard
          icon={Wifi}
          label="WS Connections"
          value={websocket.totalConnections || 0}
          color="cyan"
          sub={`${websocket.uniqueSymbolsWatched || 0} symbols`}
        />
        <StatCard
          icon={AlertTriangle}
          label="Errors Today"
          value={system.todayErrors}
          color="red"
        />
        <StatCard
          icon={Clock}
          label="Uptime"
          value={`${uptimeHours}h ${uptimeMinutes}m`}
          color="green"
        />
      </div>

      {/* System Info */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        {/* Quick Chart */}
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-300 mb-4">Overview</h3>
          <ResponsiveContainer width="100%" height={200}>
            <BarChart data={chartData}>
              <XAxis
                dataKey="name"
                tick={{ fontSize: 11, fill: '#8B8FA3' }}
                axisLine={false}
                tickLine={false}
              />
              <YAxis
                tick={{ fontSize: 11, fill: '#8B8FA3' }}
                axisLine={false}
                tickLine={false}
              />
              <Tooltip
                contentStyle={{
                  background: '#1C1F2E',
                  border: '1px solid #2A2D3A',
                  borderRadius: 8,
                  fontSize: 12,
                }}
                labelStyle={{ color: '#E8EAED' }}
              />
              <Bar dataKey="value" fill="#3B82F6" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>

        {/* System Details */}
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-300 mb-4">System</h3>
          <div className="space-y-3">
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-400 flex items-center gap-2">
                <HardDrive size={14} /> Memory (RSS)
              </span>
              <span className="text-gray-200">{system.memoryUsage.rss} MB</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-400 flex items-center gap-2">
                <HardDrive size={14} /> Heap Used
              </span>
              <span className="text-gray-200">{system.memoryUsage.heap} MB</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-400 flex items-center gap-2">
                <Database size={14} /> Cache Entries
              </span>
              <span className="text-gray-200">{system.cache?.size ?? 0}</span>
            </div>
            <div className="flex items-center justify-between text-sm">
              <span className="text-gray-400 flex items-center gap-2">
                <Wifi size={14} /> WS Auth'd
              </span>
              <span className="text-gray-200">{websocket.authenticatedConnections || 0}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
