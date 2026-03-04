import { useState, useEffect } from 'react';
import { adminApi } from '../api';
import {
  Settings,
  Crown,
  Zap,
  BrainCircuit,
  Wifi,
  CreditCard,
  Database,
  AlertTriangle,
} from 'lucide-react';

export default function ConfigPage() {
  const [config, setConfig] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    try {
      setLoading(true);
      const res = await adminApi.getConfig();
      setConfig(res.data.data);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to load config');
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
          onClick={loadConfig}
          className="mt-3 px-4 py-2 bg-accent/10 text-accent rounded-lg text-sm"
        >
          Retry
        </button>
      </div>
    );
  }

  return (
    <div className="space-y-6 max-w-3xl">
      <h1 className="text-xl font-bold text-white flex items-center gap-2">
        <Settings size={20} /> System Configuration
      </h1>

      {/* Free Plan */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Zap size={16} className="text-gray-400" /> Free Plan
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <ConfigRow label="Daily Basic Limit" value={config.free.dailyBasicLimit} />
          <ConfigRow label="Max Watchlist" value={config.free.maxWatchlist} />
          <ConfigRow label="WS Poll Interval" value={config.free.wsPollInterval} />
          <ConfigRow label="Max WS Subscriptions" value={config.free.maxWsSubscriptions} />
        </div>
      </div>

      {/* Pro Plan */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Crown size={16} className="text-yellow-400" /> Pro Plan
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <ConfigRow label="Daily Basic Limit" value={config.pro.dailyBasicLimit} />
          <ConfigRow label="Max Watchlist" value={config.pro.maxWatchlist} />
          <ConfigRow label="WS Poll Interval" value={config.pro.wsPollInterval} />
          <ConfigRow label="Max WS Subscriptions" value={config.pro.maxWsSubscriptions} />
        </div>
        <div className="mt-4 pt-4 border-t border-navy-600">
          <h4 className="text-xs text-gray-500 mb-2 flex items-center gap-1">
            <CreditCard size={12} /> Credit Costs (per analysis)
          </h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <ConfigRow label="Gemini Pro" value={`${config.pro.creditCost?.geminiPro ?? 0} credits`} />
            <ConfigRow label="OpenAI" value={`${config.pro.creditCost?.openai ?? 0} credits`} />
          </div>
        </div>
      </div>

      {/* Credit Packages */}
      {config.creditPackages?.length > 0 && (
        <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
          <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
            <CreditCard size={16} className="text-accent" /> Credit Packages
          </h3>
          <div className="space-y-2">
            {config.creditPackages.map((pkg, i) => (
              <div
                key={i}
                className="flex items-center justify-between py-2 px-3 bg-navy-700/50 rounded-lg"
              >
                <span className="text-gray-200">{pkg.credits} credits</span>
                <span className="text-gray-400">
                  ₩{pkg.price.toLocaleString()} {pkg.currency}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* AI Services */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <BrainCircuit size={16} className="text-purple-400" /> AI Services
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <div className="flex items-center gap-2">
            <div
              className={`w-2 h-2 rounded-full ${
                config.ai?.hasGemini ? 'bg-green-400' : 'bg-red-400'
              }`}
            />
            <span className="text-gray-400">Google Gemini</span>
            <span className={config.ai?.hasGemini ? 'text-green-400' : 'text-red-400'}>
              {config.ai?.hasGemini ? 'Active' : 'Not Configured'}
            </span>
          </div>
          <div className="flex items-center gap-2">
            <div
              className={`w-2 h-2 rounded-full ${
                config.ai?.hasOpenAI ? 'bg-green-400' : 'bg-red-400'
              }`}
            />
            <span className="text-gray-400">OpenAI</span>
            <span className={config.ai?.hasOpenAI ? 'text-green-400' : 'text-red-400'}>
              {config.ai?.hasOpenAI ? 'Active' : 'Not Configured'}
            </span>
          </div>
        </div>
      </div>

      {/* Cache */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Database size={16} className="text-cyan-400" /> Cache
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <ConfigRow label="Entries" value={config.cache?.size ?? 0} />
          <ConfigRow label="Hit Rate" value={config.cache?.hitRate ? `${config.cache.hitRate}%` : 'N/A'} />
        </div>
      </div>
    </div>
  );
}

function ConfigRow({ label, value }) {
  return (
    <div className="flex items-center justify-between py-1.5">
      <span className="text-gray-400">{label}</span>
      <span className="text-gray-200 font-medium">{value}</span>
    </div>
  );
}
