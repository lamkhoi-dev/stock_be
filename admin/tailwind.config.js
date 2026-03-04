/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,jsx}'],
  theme: {
    extend: {
      colors: {
        navy: {
          900: '#0B0D17',
          800: '#141620',
          700: '#1C1F2E',
          600: '#2A2D3A',
        },
        accent: '#3B82F6',
        up: '#22C55E',
        down: '#EF4444',
        gold: '#F59E0B',
      },
    },
  },
  plugins: [],
};
