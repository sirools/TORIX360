import { defineConfig } from 'vite';
import basicSsl from '@vitejs/plugin-basic-ssl';

// `npm run dev:https` sert le POC en HTTPS sur le réseau local :
// WebXR exige un contexte sécurisé pour être testé depuis le Vision Pro.
export default defineConfig(({ mode }) => ({
  base: './',
  plugins: mode === 'https' ? [basicSsl()] : [],
  server: { port: 5173 },
}));
