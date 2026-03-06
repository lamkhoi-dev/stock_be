import { useState, useEffect } from 'react';
import { adminApi } from '../api';
import {
  Settings,
  Key,
  Eye,
  EyeOff,
  AlertTriangle,
  Save,
  RotateCcw,
  CheckCircle,
  Lock,
} from 'lucide-react';

export default function ConfigPage() {
  const [config, setConfig] = useState(null);
  const [original, setOriginal] = useState(null);
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

  const isDirty =
    config &&
    original &&
    JSON.stringify(config.aiKeys) !== JSON.stringify(original.aiKeys);

  const handleSave = async () => {
    if (!isDirty) return;
    try {
      setSaving(true);
      setSaveMsg(null);
      const payload = {};
      const aiKeysPayload = {};
      if (
        config.aiKeys?.geminiApiKey !== original.aiKeys?.geminiApiKey &&
        !config.aiKeys?.geminiApiKey?.includes('••••')
      ) {
        aiKeysPayload.geminiApiKey = config.aiKeys.geminiApiKey;
      }
      if (
        config.aiKeys?.groqApiKey !== original.aiKeys?.groqApiKey &&
        !config.aiKeys?.groqApiKey?.includes('••••')
      ) {
        aiKeysPayload.groqApiKey = config.aiKeys.groqApiKey;
      }
      if (Object.keys(aiKeysPayload).length > 0) {
        payload.aiKeys = aiKeysPayload;
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

  return (
    <div className="space-y-6 max-w-3xl">
      {/* Header */}
      <div className="flex items-center justify-between flex-wrap gap-2">
        <h1 className="text-xl font-bold text-white flex items-center gap-2">
          <Settings size={20} /> Configuration
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

      {/* AI API Keys — active */}
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
          Keys are masked for security. Enter a new key to replace the existing one.
          Changes take effect immediately after save.
        </p>
      </div>

      {/* Dimmed System Config sections */}
      <div className="relative rounded-xl overflow-hidden">
        <div className="absolute inset-0 bg-navy-900/60 z-10 flex flex-col items-center justify-center gap-2 backdrop-blur-[1px]">
          <Lock size={24} className="text-gray-500" />
          <p className="text-sm text-gray-400 font-medium">System Configuration</p>
          <p className="text-xs text-gray-500">Coming soon</p>
        </div>
        <div className="opacity-30 pointer-events-none select-none space-y-4 p-1">
          <div className="bg-navy-800 border border-navy-600 rounded-xl p-4">
            <p className="text-sm text-gray-400">Feature Toggles</p>
            <div className="mt-2 space-y-2">
              {['AI Analysis', 'Pro Analysis', 'News Tab', 'WebSocket', 'Registration', 'Watchlist'].map(
                (f) => (
                  <div key={f} className="flex items-center justify-between py-1.5">
                    <span className="text-xs text-gray-500">{f}</span>
                    <div className="w-8 h-4 bg-navy-600 rounded-full" />
                  </div>
                ),
              )}
            </div>
          </div>
          <div className="bg-navy-800 border border-navy-600 rounded-xl p-4">
            <p className="text-sm text-gray-400">Plan Limits & Maintenance</p>
            <div className="mt-2 grid grid-cols-2 gap-2">
              {['Free Plan', 'Pro Plan', 'Credit Packages', 'Cache'].map((s) => (
                <div
                  key={s}
                  className="h-8 bg-navy-700 rounded-lg flex items-center px-3"
                >
                  <span className="text-xs text-gray-500">{s}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ApiKeyRow({ label, value, isActive, onChange }) {
  const [show, setShow] = useState(false);
  const isMasked = value?.includes('••••');

  return (
    <div className="space-y-1.5">
      <div className="flex items-center justify-between flex-wrap gap-1">
        <div className="flex items-center gap-2">
          <div
            className={`w-2 h-2 rounded-full ${isActive ? 'bg-green-400' : 'bg-red-400'}`}
          />
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
        onFocus={() => {
          if (isMasked) onChange('');
        }}
        placeholder="Enter API key..."
        className="w-full bg-navy-700 border border-navy-600 rounded-lg px-3 py-2 text-sm text-gray-200 placeholder-gray-500 font-mono focus:outline-none focus:border-accent"
      />
    </div>
  );
}
