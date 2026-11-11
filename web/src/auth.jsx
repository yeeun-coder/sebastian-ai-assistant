import { createContext, useContext, useState } from 'react';
import { loadToken, saveToken } from './api';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [token, setToken] = useState(loadToken());

  const login = (t) => {
    saveToken(t);
    setToken(t);
  };

  const logout = () => {
    saveToken('');
    setToken('');
  };

  return (
    <AuthContext.Provider
      value={{ token, login, logout, isAuthenticated: !!token }}
    >
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
