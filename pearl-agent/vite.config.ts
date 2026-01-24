import path from "path";
import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, ".", "VITE_");

  return {
    base: "/", // REQUIRED for Vercel + SPA routing

    plugins: [react()],

    server: {
      port: 3000,
      host: "0.0.0.0",
    },

    resolve: {
      alias: {
        "@": path.resolve(__dirname, "."),
      },
    },

    // Only expose SAFE frontend env vars
    define: {
      __APP_ENV__: JSON.stringify(env.MODE),
    },

    build: {
      outDir: "dist",
      sourcemap: false,
      rollupOptions: {
        // keep this ONLY if taiken-story-lab is external runtime
        external: ["taiken-story-lab"],
      },
    },
  };
});
