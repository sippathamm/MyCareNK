import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { CssBaseline, ThemeProvider } from '@mui/material';
import App from './App.tsx';
import { createAppTheme } from './theme.ts';
import { ThemeContextProvider, useColorMode } from './contexts/ThemeContext.tsx';
import { AuthProvider } from './contexts/AuthContext.tsx';
import '@fontsource/roboto/300.css';
import '@fontsource/roboto/400.css';
import '@fontsource/roboto/500.css';
import '@fontsource/roboto/700.css';

function ThemedApp() {
  const { mode } = useColorMode();
  return (
    <ThemeProvider theme={createAppTheme(mode)}>
      <CssBaseline />
      <AuthProvider>
        <App />
      </AuthProvider>
    </ThemeProvider>
  );
}

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <BrowserRouter>
      <ThemeContextProvider>
        <ThemedApp />
      </ThemeContextProvider>
    </BrowserRouter>
  </React.StrictMode>,
);
