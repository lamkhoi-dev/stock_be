import { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { adminApi } from '../api';
import {
  Search,
  ChevronLeft,
  ChevronRight,
  Download,
  AlertCircle,
  AlertTriangle,
  Info,
  Bug,
} from 'lucide-react';
import { format } from 'date-fns';

const LEVEL_STYLES = {
  error: { icon: AlertCircle, bg: 'bg-red-500/10', text: 'text-red-400', dot: 'bg-red-400' },
  warn: { icon: AlertTriangle, bg: 'bg-yellow-500/10', text: 'text-yellow-400', dot: 'bg-yellow-400' },
  info: { icon: Info, bg: 'bg-blue-500/10', text: 'text-blue-400', dot: 'bg-blue-400' },
  debug: { icon: Bug, bg: 'bg-gray-500/10', text: 'text-gray-400', dot: 'bg-gray-400' },
};

export default function LogsPage() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [logs, setLogs] = useState([]);
  const [pagination, setPagination] = useState({ page: 1, pages: 1, total: 0 });
  const [loading, setLoading] = useState(true);
  const [exporting, setExporting] = useState(false);

  const page = parseInt(searchParams.get('page')) || 1;
  const level = searchParams.get('level') || '';
  const source = searchParams.get('source') || '';

  const loadLogs = useCallback(async () => {
    try {
      setLoading(true);
      const params = { page, limit: 50 };
      if (level) params.level = level;
      if (source) params.source = source;

      const res = await adminApi.getLogs(params);
      setLogs(res.data.data.logs);
      setPagination(res.data.data.pagination);
    } catch (err) {
      console.error('Failed to load logs:', err);
    } finally {
      setLoading(false);
    }
  }, [page, level, source]);

  useEffect(() => {
    loadLogs();
  }, [loadLogs]);

  const updateParams = (updates) => {
    const params = Object.fromEntries(searchParams.entries());
    Object.assign(params, updates);
    Object.keys(params).forEach((k) => {
      if (!params[k]) delete params[k];
    });
    setSearchParams(params);
  };

  const handleExport = async () => {
    try {
      setExporting(true);
      const params = { days: 7 };
      if (level) params.level = level;
      if (source) params.source = source;

      const res = await adminApi.exportLogs(params);
      const blob = new Blob([res.data], { type: 'text/csv' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `logs_${Date.now()}.csv`;
      a.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      alert('Export failed');
    } finally {
      setExporting(false);
    }
  };

  const [expandedLog, setExpandedLog] = useState(null);

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-xl font-bold text-white">System Logs</h1>
        <button
          onClick={handleExport}
          disabled={exporting}
          className="flex items-center gap-2 px-3 py-1.5 bg-navy-700 hover:bg-navy-600 text-gray-300 rounded-lg text-xs transition-colors disabled:opacity-50"
        >
          <Download size={14} />
          {exporting ? 'Exporting...' : 'Export CSV'}
        </button>
      </div>

      {/* Filters */}
      <div className="flex flex-wrap gap-3">
        <select
          value={level}
          onChange={(e) => updateParams({ level: e.target.value, page: '1' })}
          className="px-3 py-2 bg-navy-800 border border-navy-600 rounded-lg text-sm text-gray-300 focus:outline-none focus:border-accent"
        >
          <option value="">All Levels</option>
          <option value="error">Error</option>
          <option value="warn">Warning</option>
          <option value="info">Info</option>
          <option value="debug">Debug</option>
        </select>

        <div className="relative flex-1 min-w-[180px] max-w-xs">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
          <input
            type="text"
            value={source}
            onChange={(e) => updateParams({ source: e.target.value, page: '1' })}
            placeholder="Filter by source..."
            className="w-full pl-9 pr-4 py-2 bg-navy-800 border border-navy-600 rounded-lg text-sm text-gray-200 focus:outline-none focus:border-accent"
          />
        </div>

        <span className="self-center text-xs text-gray-500">{pagination.total} logs</span>
      </div>

      {/* Logs List */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl overflow-hidden">
        {loading ? (
          <div className="p-8 text-center">
            <div className="animate-spin rounded-full h-6 w-6 border-b-2 border-accent mx-auto" />
          </div>
        ) : logs.length === 0 ? (
          <div className="p-12 text-center text-gray-500">No logs found</div>
        ) : (
          <div className="divide-y divide-navy-600/50">
            {logs.map((log) => {
              const style = LEVEL_STYLES[log.level] || LEVEL_STYLES.info;
              const Icon = style.icon;
              const isExpanded = expandedLog === log._id;

              return (
                <div
                  key={log._id}
                  className="px-4 py-3 hover:bg-navy-700/30 cursor-pointer transition-colors"
                  onClick={() => setExpandedLog(isExpanded ? null : log._id)}
                >
                  <div className="flex items-start gap-3">
                    <div className={`w-7 h-7 rounded-md flex items-center justify-center mt-0.5 ${style.bg}`}>
                      <Icon size={14} className={style.text} />
                    </div>
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-2 mb-0.5">
                        <span className={`text-xs font-semibold uppercase ${style.text}`}>
                          {log.level}
                        </span>
                        {log.source && (
                          <span className="text-xs text-gray-500 font-mono">{log.source}</span>
                        )}
                        <span className="text-xs text-gray-600 ml-auto whitespace-nowrap">
                          {log.createdAt
                            ? format(new Date(log.createdAt), 'MMM dd, HH:mm:ss')
                            : ''}
                        </span>
                      </div>
                      <p className="text-sm text-gray-300 break-all line-clamp-2">
                        {log.message}
                      </p>
                      {isExpanded && log.stack && (
                        <pre className="mt-2 p-3 bg-navy-900 rounded-lg text-xs text-gray-400 overflow-x-auto whitespace-pre-wrap">
                          {log.stack}
                        </pre>
                      )}
                      {isExpanded && log.meta && (
                        <pre className="mt-2 p-3 bg-navy-900 rounded-lg text-xs text-gray-400 overflow-x-auto">
                          {JSON.stringify(log.meta, null, 2)}
                        </pre>
                      )}
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}

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
