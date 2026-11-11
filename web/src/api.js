import axios from 'axios';

const TOKEN_KEY = 'sebastian_admin_token';

export const loadToken = () => sessionStorage.getItem(TOKEN_KEY) || '';
export const saveToken = (t) => {
  if (t) sessionStorage.setItem(TOKEN_KEY, t);
  else sessionStorage.removeItem(TOKEN_KEY);
};

const api = axios.create({ baseURL: '/admin' });

api.interceptors.request.use((config) => {
  const token = loadToken();
  if (token) config.headers['x-admin-key'] = token;
  return config;
});

export async function adminLogin(username, password) {
  const { data } = await axios.post('/admin/login', { username, password });
  return data;
}

export async function fetchUsers() {
  const { data } = await api.get('/users');
  return data;
}

export async function createUser(payload) {
  const { data } = await api.post('/users', payload);
  return data;
}

export async function resetPassword(userId, newPassword) {
  const { data } = await api.post(`/users/${userId}/reset-password`, {
    newPassword,
  });
  return data;
}

export async function updateUser(userId, payload) {
  const { data } = await api.patch(`/users/${userId}`, payload);
  return data;
}

export async function deleteUser(userId) {
  const { data } = await api.delete(`/users/${userId}`);
  return data;
}

export async function fetchPasswordResetRequests(status) {
  const { data } = await api.get('/password-reset-requests', {
    params: status ? { status } : {},
  });
  return data;
}

export async function fetchPasswordResetPendingCount() {
  const { data } = await api.get('/password-reset-requests/pending-count');
  return data;
}

export async function resolvePasswordResetRequest(id, newPassword, memo) {
  const body = { newPassword };
  if (memo) body.memo = memo;
  const { data } = await api.patch(
    `/password-reset-requests/${id}/resolve`,
    body,
  );
  return data;
}

export async function rejectPasswordResetRequest(id, memo) {
  const body = {};
  if (memo) body.memo = memo;
  const { data } = await api.patch(
    `/password-reset-requests/${id}/reject`,
    body,
  );
  return data;
}
