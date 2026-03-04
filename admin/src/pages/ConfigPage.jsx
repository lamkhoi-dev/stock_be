import { useState, useEffect, useCallback } from 'react';
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
  Save,
  RotateCcw,
  Power,
  ToggleLeft,
  ToggleRight,
  Shield,
  Newspaper,
  UserPlus,
  Star,
  Wrench,
  CheckCircle,
  Key,
  Eye,
  EyeOff,
} from 'lucide-react';

export default function ConfigPage() {
  const [config, setConfig] = useState(null);
  const [original, setOriginal] = useState(null); // track original for dirty check
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [saveMsg, setSaveMsg] = useState(null);

  useEffect(() => {
    loadConfig();
  }, []);

  const loadConfig = async () => {
    try {
      setLoading(true);
      setError(null);
      const res = await adminApi.getConfig();
      setConfig(res.data.data);
      setOriginal(JSON.parse(JSON.stringify(res.data.data)));
    } catch (err) {
      setError(err.response?.data?.error?.message || 'Failed to load config');
    } finally {
      setLoading(false);
    }
  };

  const isDirty = config && original && JSON.stringify(config) !== JSON.stringify(original);

  const handleSave = async () => {
    if (!isDirty) return;
    try {
      setSaving(true);
      setSaveMsg(null);
      const payload = {};
      // Only send changed sections
      if (JSON.stringify(config.features) !== JSON.stringify(original.features)) {
        payload.features = config.features;
      }
      if (JSON.stringify(config.free) !== JSON.stringify(original.free)) {
        payload.free = config.free;
      }
      if (JSON.stringify(config.pro) !== JSON.stringify(original.pro)) {
        payload.pro = config.pro;
      }
      if (JSON.stringify(config.creditPackages) !== JSON.stringify(original.creditPackages)) {
        payload.creditPackages = config.creditPackages;
      }
      if (JSON.stringify(config.maintenance) !== JSON.stringify(original.maintenance)) {
        payload.maintenance = config.maintenance;
      }
      // Only send aiKeys if user actually typed new keys (not masked values)
      if (JSON.stringify(config.aiKeys) !== JSON.stringify(original.aiKeys)) {
        const aiKeysPayload = {};
        if (config.aiKeys?.geminiApiKey !== original.aiKeys?.geminiApiKey && !config.aiKeys?.geminiApiKey?.includes('••••')) {
          aiKeysPayload.geminiApiKey = config.aiKeys.geminiApiKey;
        }
        if (config.aiKeys?.groqApiKey !== original.aiKeys?.groqApiKey && !config.aiKeys?.groqApiKey?.includes('••••')) {
          aiKeysPayload.groqApiKey = config.aiKeys.groqApiKey;
        }
        if (Object.keys(aiKeysPayload).length > 0) {
          payload.aiKeys = aiKeysPayload;
        }
      }

      const res = await adminApi.updateConfig(payload);
      setConfig(res.data.data);
      setOriginal(JSON.parse(JSON.stringify(res.data.data)));
      setSaveMsg('Configuration saved successfully!');
      setTimeout(() => setSaveMsg(null), 3000);
    } catch (err) {
      alert(err.response?.data?.error?.message || 'Failed to save');
    } finally {
      setSaving(false);
    }
  };

  const handleReset = () => {
    setConfig(JSON.parse(JSON.stringify(original)));
  };

  const toggleFeature = (key) => {
    setConfig((prev) => ({
      ...prev,
      features: { ...prev.features, [key]: !prev.features[key] },
    }));
  };

  const updateFree = (key, value) => {
    setConfig((prev) => ({
      ...prev,
      free: { ...prev.free, [key]: value },
    }));
  };

  const updatePro = (key, value) => {
    setConfig((prev) => ({
      ...prev,
      pro: { ...prev.pro, [key]: value },
    }));
  };

  const updateProCredit = (key, value) => {
    setConfig((prev) => ({
      ...prev,
      pro: {
        ...prev.pro,
        creditCost: { ...prev.pro.creditCost, [key]: value },
      },
    }));
  };

  const toggleMaintenance = () => {
    setConfig((prev) => ({
      ...prev,
      maintenance: { ...prev.maintenance, enabled: !prev.maintenance?.enabled },
    }));
  };

  const updateMaintenanceMsg = (msg) => {
    setConfig((prev) => ({
      ...prev,
      maintenance: { ...prev.maintenance, message: msg },
    }));
  };

  const updateAiKey = (key, value) => {
    setConfig((prev) => ({
      ...prev,
      aiKeys: { ...prev.aiKeys, [key]: value },
    }));
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

  const featureList = [
    { key: 'aiAnalysis', label: 'AI Analysis', desc: 'Enable free AI stock analysis', icon: BrainCircuit, color: 'text-purple-400' },
    { key: 'proAnalysis', label: 'Pro AI Analysis', desc: 'Enable premium Pro-level analysis', icon: Crown, color: 'text-yellow-400' },
    { key: 'newsTab', label: 'News Tab', desc: 'Show news tab in stock detail', icon: Newspaper, color: 'text-blue-400' },
    { key: 'websocket', label: 'WebSocket Real-time', desc: 'Real-time price updates via WebSocket', icon: Wifi, color: 'text-green-400' },
    { key: 'registration', label: 'New Registration', desc: 'Allow new user sign-ups', icon: UserPlus, color: 'text-cyan-400' },
    { key: 'watchlist', label: 'Watchlist', desc: 'Enable watchlist feature', icon: Star, color: 'text-yellow-300' },
  ];

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Header */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold text-white flex items-center gap-2">
          <Settings size={20} /> System Configuration
        </h1>
        <div className="flex items-center gap-2">
          {isDirty && (
            <button
              onClick={handleReset}
              className="px-3 py-1.5 bg-navy-700 text-gray-400 hover:text-white rounded-lg text-sm flex items-center gap-1.5 transition-colors"
            >
              <RotateCcw size={14} /> Reset
            </button>
          )}
          <button
            onClick={handleSave}
            disabled={!isDirty || saving}
            className="px-4 py-1.5 bg-accent text-white rounded-lg text-sm font-medium flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed hover:bg-accent/90 transition-colors"
          >
            <Save size={14} /> {saving ? 'Saving...' : 'Save Changes'}
          </button>
        </div>
      </div>

      {/* Save Success */}
      {saveMsg && (
        <div className="flex items-center gap-2 px-4 py-2 bg-green-500/10 border border-green-500/20 rounded-lg text-green-400 text-sm">
          <CheckCircle size={16} /> {saveMsg}
        </div>
      )}

      {/* Dirty indicator */}
      {isDirty && (
        <div className="flex items-center gap-2 px-4 py-2 bg-yellow-500/10 border border-yellow-500/20 rounded-lg text-yellow-400 text-sm">
          <AlertTriangle size={14} /> You have unsaved changes
        </div>
      )}

      {/* Maintenance Mode */}
      <div className={`border rounded-xl p-5 ${config.maintenance?.enabled ? 'bg-red-500/5 border-red-500/30' : 'bg-navy-800 border-navy-600'}`}>
        <div className="flex items-center justify-between mb-3">
          <h3 className="text-sm font-semibold text-gray-300 flex items-center gap-2">
            <Wrench size={16} className="text-orange-400" /> Maintenance Mode
          </h3>
          <button onClick={toggleMaintenance} className="focus:outline-none">
            {config.maintenance?.enabled ? (
              <ToggleRight size={32} className="text-red-400" />
            ) : (
              <ToggleLeft size={32} className="text-gray-600" />
            )}
          </button>
        </div>
        {config.maintenance?.enabled && (
          <input
            type="text"
            value={config.maintenance.message || ''}
            onChange={(e) => updateMaintenanceMsg(e.target.value)}
            placeholder="Maintenance message..."
            className="w-full bg-navy-700 border border-navy-600 rounded-lg px-3 py-2 text-sm text-gray-200 placeholder-gray-500 focus:outline-none focus:border-accent"
          />
        )}
        {config.maintenance?.enabled && (
          <p className="text-xs text-red-400 mt-2">
            App clients will see the maintenance message and cannot access features.
          </p>
        )}
      </div>

      {/* Feature Toggles */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Power size={16} className="text-green-400" /> Feature Toggles
        </h3>
        <div className="space-y-1">
          {featureList.map(({ key, label, desc, icon: Icon, color }) => (
            <div
              key={key}
              className="flex items-center justify-between py-3 px-2 rounded-lg hover:bg-navy-700/50 transition-colors"
            >
              <div className="flex items-center gap-3">
                <Icon size={18} className={color} />
                <div>
                  <p className="text-sm text-gray-200">{label}</p>
                  <p className="text-xs text-gray-500">{desc}</p>
                </div>
              </div>
              <button onClick={() => toggleFeature(key)} className="focus:outline-none">
                {config.features?.[key] ? (
                  <ToggleRight size={28} className="text-green-400" />
                ) : (
                  <ToggleLeft size={28} className="text-gray-600" />
                )}
              </button>
            </div>
          ))}
        </div>
      </div>

      {/* Free Plan */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Zap size={16} className="text-gray-400" /> Free Plan Limits
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <EditableRow
            label="Daily Basic Limit"
            value={config.free?.dailyBasicLimit}
            type="number"
            onChange={(v) => updateFree('dailyBasicLimit', parseInt(v) || 0)}
          />
          <EditableRow
            label="Max Watchlist"
            value={config.free?.maxWatchlist}
            type="number"
            onChange={(v) => updateFree('maxWatchlist', parseInt(v) || 0)}
          />
          <EditableRow
            label="WS Poll Interval"
            value={config.free?.wsPollInterval}
            onChange={(v) => updateFree('wsPollInterval', v)}
          />
          <EditableRow
            label="Max WS Subscriptions"
            value={config.free?.maxWsSubscriptions}
            type="number"
            onChange={(v) => updateFree('maxWsSubscriptions', parseInt(v) || 0)}
          />
        </div>
      </div>

      {/* Pro Plan */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Crown size={16} className="text-yellow-400" /> Pro Plan Limits
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <EditableRow
            label="Daily Basic Limit"
            value={config.pro?.dailyBasicLimit}
            onChange={(v) => updatePro('dailyBasicLimit', v)}
          />
          <EditableRow
            label="Max Watchlist"
            value={config.pro?.maxWatchlist}
            onChange={(v) => updatePro('maxWatchlist', v)}
          />
          <EditableRow
            label="WS Poll Interval"
            value={config.pro?.wsPollInterval}
            onChange={(v) => updatePro('wsPollInterval', v)}
          />
          <EditableRow
            label="Max WS Subscriptions"
            value={config.pro?.maxWsSubscriptions}
            type="number"
            onChange={(v) => updatePro('maxWsSubscriptions', parseInt(v) || 0)}
          />
        </div>
        <div className="mt-4 pt-4 border-t border-navy-600">
          <h4 className="text-xs text-gray-500 mb-3 flex items-center gap-1">
            <CreditCard size={12} /> Credit Costs (per analysis)
          </h4>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <EditableRow
              label="Gemini Pro"
              value={config.pro?.creditCost?.geminiPro ?? 0}
              type="number"
              suffix="credits"
              onChange={(v) => updateProCredit('geminiPro', parseInt(v) || 0)}
            />
            <EditableRow
              label="OpenAI"
              value={config.pro?.creditCost?.openai ?? 0}
              type="number"
              suffix="credits"
              onChange={(v) => updateProCredit('openai', parseInt(v) || 0)}
            />
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
                  ₩{pkg.price?.toLocaleString()} {pkg.currency}
                </span>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* AI API Keys */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Key size={16} className="text-purple-400" /> AI API Keys
        </h3>
        <div className="space-y-4">
          <ApiKeyRow
            label="Google Gemini API Key"
            value={config.aiKeys?.geminiApiKey || ''}
            isActive={config.aiKeys?.hasGemini}
            onChange={(v) => updateAiKey('geminiApiKey', v)}
          />
          <ApiKeyRow
            label="Groq API Key"
            value={config.aiKeys?.groqApiKey || ''}
            isActive={config.aiKeys?.hasGroq}
            onChange={(v) => updateAiKey('groqApiKey', v)}
          />
        </div>
        <p className="text-xs text-gray-500 mt-3">
          Keys are masked for security. Enter a new key to replace the existing one. Changes take effect immediately after save.
        </p>
      </div>

      {/* Cache */}
      <div className="bg-navy-800 border border-navy-600 rounded-xl p-5">
        <h3 className="text-sm font-semibold text-gray-300 mb-4 flex items-center gap-2">
          <Database size={16} className="text-cyan-400" /> Cache
        </h3>
        <div className="grid grid-cols-2 gap-4 text-sm">
          <ConfigRow label="Entries" value={config.cache?.size ?? 0} />
          <ConfigRow
            label="Hit Rate"
            value={config.cache?.hitRate ? `${config.cache.hitRate}%` : 'N/A'}
          />
        </div>
      </div>
    </div>
  );
}

function EditableRow({ label, value, type = 'text', suffix, onChange }) {
  return (
    <div className="flex items-center justify-between py-1.5 gap-2">
      <span className="text-gray-400 whitespace-nowrap">{label}</span>
      <div className="flex items-center gap-1.5">
        <input
          type={type}
          value={value ?? ''}
          onChange={(e) => onChange(e.target.value)}
          className="w-24 bg-navy-700 border border-navy-600 rounded-md px-2 py-1 text-sm text-gray-200 text-right focus:outline-none focus:border-accent"
        />
        {suffix && <span className="text-xs text-gray-500">{suffix}</span>}
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

function ApiKeyRow({ label, value, isActive, onChange }) {
  const [show, setShow] = useState(false);
  const isMasked = value?.includes('••••');

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-2">
          <div className={`w-2 h-2 rounded-full ${isActive ? 'bg-green-400' : 'bg-red-400'}`} />
          <span className="text-sm text-gray-300">{label}</span>
          <span className={`text-xs ${isActive ? 'text-green-400' : 'text-red-400'}`}>
            {isActive ? 'Active' : 'Not Set'}
          </span>
        </div>
        <button
          onClick={() => setShow(!show)}
          className="text-gray-500 hover:text-gray-300 transition-colors"
          title={show ? 'Hide' : 'Show'}
        >
          {show ? <EyeOff size={14} /> : <Eye size={14} />}
        </button>
      </div>
      <input
        type={show ? 'text' : 'password'}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        onFocus={() => { if (isMasked) onChange(''); }}
        placeholder="Enter API key..."
        className="w-full bg-navy-700 border border-navy-600 rounded-lg px-3 py-2 text-sm text-gray-200 placeholder-gray-500 font-mono focus:outline-none focus:border-accent"
      />
    </div>
  );
}
