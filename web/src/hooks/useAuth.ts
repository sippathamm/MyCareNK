// Re-export from AuthContext so all callers share the same singleton auth state.
// Previously this file contained the hook logic directly, which caused a new
// independent state instance to be created on every useAuth() call — resulting
// in duplicate Supabase session fetches and slow page loads.
export { useAuth } from '../contexts/AuthContext';
