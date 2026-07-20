import { createContext, useContext, useState, type ReactNode } from 'react';

type ColorMode = 'light' | 'dark';

interface ThemeContextValue {
  mode: ColorMode;
  toggleMode: () => void;
}

const ThemeContext = createContext<ThemeContextValue>({ mode: 'light', toggleMode: () => {} });

function getInitialMode(): ColorMode {
  const stored = localStorage.getItem('color_mode');
  if (stored === 'light' || stored === 'dark') return stored;
  return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
}

export function ThemeContextProvider({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<ColorMode>(getInitialMode);

  const toggleMode = () => {
    setMode(prev => {
      const next = prev === 'light' ? 'dark' : 'light';
      localStorage.setItem('color_mode', next);
      return next;
    });
  };

  return <ThemeContext.Provider value={{ mode, toggleMode }}>{children}</ThemeContext.Provider>;
}

export function useColorMode() {
  return useContext(ThemeContext);
}
