import { useState } from 'react';
import {
  Box,
  Paper,
  Typography,
  Button,
  IconButton,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  TextField,
  Alert,
  CircularProgress,
  MenuItem,
  Stack,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import AddIcon from '@mui/icons-material/Add';
import LockResetIcon from '@mui/icons-material/LockReset';
import EditIcon from '@mui/icons-material/Edit';
import DeleteIcon from '@mui/icons-material/Delete';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  fetchUsers,
  createUser,
  resetPassword,
  updateUser,
  deleteUser,
} from '../api.js';

const formatDate = (iso) => {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('ko-KR');
  } catch {
    return String(iso);
  }
};

const emptyCreateForm = {
  email: '',
  password: '',
  nickname: '',
  birthDate: '',
  gender: '남',
};

const errorMessage = (err, fallback) => {
  const msg = err?.response?.data?.message || err?.message || fallback;
  return Array.isArray(msg) ? msg.join(', ') : msg;
};

export default function UserList() {
  const queryClient = useQueryClient();

  const [createOpen, setCreateOpen] = useState(false);
  const [createForm, setCreateForm] = useState(emptyCreateForm);
  const [createError, setCreateError] = useState(null);

  const [resetTarget, setResetTarget] = useState(null);
  const [newPw, setNewPw] = useState('');
  const [newPw2, setNewPw2] = useState('');
  const [resetError, setResetError] = useState(null);

  const [editTarget, setEditTarget] = useState(null);
  const [editForm, setEditForm] = useState({
    email: '',
    nickname: '',
    birthDate: '',
    gender: '남',
  });
  const [editError, setEditError] = useState(null);

  const [deleteTarget, setDeleteTarget] = useState(null);
  const [deleteError, setDeleteError] = useState(null);

  const {
    data: users = [],
    isLoading,
    error,
  } = useQuery({
    queryKey: ['admin-users'],
    queryFn: fetchUsers,
  });

  const createMutation = useMutation({
    mutationFn: createUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      setCreateOpen(false);
      setCreateForm(emptyCreateForm);
      setCreateError(null);
    },
    onError: (err) => setCreateError(errorMessage(err, '사용자 생성에 실패했습니다.')),
  });

  const resetMutation = useMutation({
    mutationFn: ({ id, newPassword }) => resetPassword(id, newPassword),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      setResetTarget(null);
      setNewPw('');
      setNewPw2('');
      setResetError(null);
    },
    onError: (err) =>
      setResetError(errorMessage(err, '비밀번호 초기화에 실패했습니다.')),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, payload }) => updateUser(id, payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      setEditTarget(null);
      setEditError(null);
    },
    onError: (err) =>
      setEditError(errorMessage(err, '사용자 정보 수정에 실패했습니다.')),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteUser,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-users'] });
      setDeleteTarget(null);
      setDeleteError(null);
    },
    onError: (err) =>
      setDeleteError(errorMessage(err, '사용자 삭제에 실패했습니다.')),
  });

  const openEditDialog = (row) => {
    setEditTarget(row);
    setEditForm({
      email: row.email ?? '',
      nickname: row.nickname ?? '',
      birthDate: row.birthDate ?? '',
      gender: row.gender ?? '남',
    });
    setEditError(null);
  };

  const handleCreateSubmit = (e) => {
    e.preventDefault();
    setCreateError(null);
    if (
      !createForm.email ||
      !createForm.password ||
      !createForm.nickname ||
      !createForm.birthDate
    ) {
      setCreateError('필수 항목을 모두 입력해주세요.');
      return;
    }
    if (createForm.password.length < 6) {
      setCreateError('비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    createMutation.mutate(createForm);
  };

  const handleResetSubmit = (e) => {
    e.preventDefault();
    setResetError(null);
    if (newPw.length < 6) {
      setResetError('비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (newPw !== newPw2) {
      setResetError('비밀번호 확인이 일치하지 않습니다.');
      return;
    }
    resetMutation.mutate({ id: resetTarget.id, newPassword: newPw });
  };

  const handleEditSubmit = (e) => {
    e.preventDefault();
    setEditError(null);
    if (!editForm.email || !editForm.nickname || !editForm.birthDate) {
      setEditError('필수 항목을 모두 입력해주세요.');
      return;
    }
    const payload = {};
    if (editForm.email !== editTarget.email) payload.email = editForm.email;
    if (editForm.nickname !== editTarget.nickname)
      payload.nickname = editForm.nickname;
    if (editForm.birthDate !== editTarget.birthDate)
      payload.birthDate = editForm.birthDate;
    if (editForm.gender !== editTarget.gender) payload.gender = editForm.gender;

    if (Object.keys(payload).length === 0) {
      setEditTarget(null);
      return;
    }
    updateMutation.mutate({ id: editTarget.id, payload });
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 80 },
    { field: 'email', headerName: '이메일', flex: 1, minWidth: 200 },
    { field: 'nickname', headerName: '닉네임', width: 160 },
    { field: 'birthDate', headerName: '생년월일', width: 130 },
    { field: 'gender', headerName: '성별', width: 80 },
    {
      field: 'createdAt',
      headerName: '가입일',
      width: 180,
      valueFormatter: (value) => formatDate(value),
    },
    {
      field: 'actions',
      headerName: '작업',
      width: 170,
      sortable: false,
      renderCell: (params) => (
        <Stack direction="row" spacing={0.5} alignItems="center" height="100%">
          <IconButton
            size="small"
            color="primary"
            title="수정"
            onClick={() => openEditDialog(params.row)}
          >
            <EditIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            color="info"
            title="비밀번호 초기화"
            onClick={() => {
              setResetTarget(params.row);
              setNewPw('');
              setNewPw2('');
              setResetError(null);
            }}
          >
            <LockResetIcon fontSize="small" />
          </IconButton>
          <IconButton
            size="small"
            color="error"
            title="삭제"
            onClick={() => {
              setDeleteTarget(params.row);
              setDeleteError(null);
            }}
          >
            <DeleteIcon fontSize="small" />
          </IconButton>
        </Stack>
      ),
    },
  ];

  return (
    <Box>
      <Box
        sx={{
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center',
          mb: 3,
        }}
      >
        <Typography variant="h5" sx={{ fontWeight: 'bold' }}>
          사용자 관리
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={() => {
            setCreateForm(emptyCreateForm);
            setCreateError(null);
            setCreateOpen(true);
          }}
        >
          사용자 등록
        </Button>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {errorMessage(error, '사용자 목록을 불러오지 못했습니다.')}
        </Alert>
      )}

      <Paper
        sx={{
          width: '100%',
          border: '1px solid #c4c9d0',
          borderTop: '3px solid #3c4b64',
          height: 'calc(100vh - 240px)',
          minHeight: 400,
        }}
      >
        <DataGrid
          rows={users}
          columns={columns}
          loading={isLoading}
          disableRowSelectionOnClick
          rowHeight={44}
          columnHeaderHeight={44}
          pageSizeOptions={[10, 20, 50]}
          initialState={{ pagination: { paginationModel: { pageSize: 20 } } }}
          sx={{
            border: 'none',
            height: '100%',
            fontSize: '0.813rem',
            '& .MuiDataGrid-columnHeaders': {
              backgroundColor: '#f8f9fa',
              borderBottom: '1px solid #d8dbe0',
            },
            '& .MuiDataGrid-columnHeaderTitle': {
              fontWeight: 700,
              color: '#333',
              fontSize: '0.813rem',
            },
            '& .MuiDataGrid-columnSeparator': { color: '#d8dbe0' },
            '& .MuiDataGrid-cell': {
              borderBottom: '1px solid #e8e8e8',
              color: '#333',
              fontSize: '0.813rem',
              padding: '0 12px',
            },
            '& .MuiDataGrid-row': {
              '&:nth-of-type(even)': { backgroundColor: '#f7f8fa' },
              '&:hover': { backgroundColor: '#e8edf3' },
            },
            '& .MuiDataGrid-footerContainer': {
              borderTop: '1px solid #d8dbe0',
              backgroundColor: '#f8f9fa',
              minHeight: 40,
            },
            '& .MuiDataGrid-overlay': {
              backgroundColor: 'rgba(255,255,255,0.9)',
            },
          }}
        />
      </Paper>

      {/* 사용자 등록 */}
      <Dialog
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        maxWidth="sm"
        fullWidth
      >
        <form onSubmit={handleCreateSubmit}>
          <DialogTitle>사용자 등록</DialogTitle>
          <DialogContent>
            {createError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {createError}
              </Alert>
            )}
            <TextField
              margin="normal"
              required
              fullWidth
              label="이메일"
              type="email"
              value={createForm.email}
              onChange={(e) =>
                setCreateForm({ ...createForm, email: e.target.value })
              }
            />
            <TextField
              margin="normal"
              required
              fullWidth
              type="password"
              label="비밀번호 (6자 이상)"
              value={createForm.password}
              onChange={(e) =>
                setCreateForm({ ...createForm, password: e.target.value })
              }
            />
            <TextField
              margin="normal"
              required
              fullWidth
              label="닉네임"
              value={createForm.nickname}
              onChange={(e) =>
                setCreateForm({ ...createForm, nickname: e.target.value })
              }
            />
            <TextField
              margin="normal"
              required
              fullWidth
              type="date"
              label="생년월일"
              InputLabelProps={{ shrink: true }}
              value={createForm.birthDate}
              onChange={(e) =>
                setCreateForm({ ...createForm, birthDate: e.target.value })
              }
            />
            <TextField
              margin="normal"
              select
              fullWidth
              label="성별"
              value={createForm.gender}
              onChange={(e) =>
                setCreateForm({ ...createForm, gender: e.target.value })
              }
            >
              <MenuItem value="남">남</MenuItem>
              <MenuItem value="여">여</MenuItem>
            </TextField>
          </DialogContent>
          <DialogActions>
            <Button
              onClick={() => setCreateOpen(false)}
              disabled={createMutation.isPending}
            >
              취소
            </Button>
            <Button
              type="submit"
              variant="contained"
              disabled={createMutation.isPending}
            >
              {createMutation.isPending ? <CircularProgress size={20} /> : '등록'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* 사용자 정보 수정 */}
      <Dialog
        open={!!editTarget}
        onClose={() => setEditTarget(null)}
        maxWidth="sm"
        fullWidth
      >
        <form onSubmit={handleEditSubmit}>
          <DialogTitle>사용자 정보 수정</DialogTitle>
          <DialogContent>
            {editTarget && (
              <Typography variant="body2" color="text.secondary" sx={{ mb: 1 }}>
                ID #{editTarget.id}
              </Typography>
            )}
            {editError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {editError}
              </Alert>
            )}
            <TextField
              margin="normal"
              required
              fullWidth
              label="이메일"
              type="email"
              value={editForm.email}
              onChange={(e) =>
                setEditForm({ ...editForm, email: e.target.value })
              }
            />
            <TextField
              margin="normal"
              required
              fullWidth
              label="닉네임"
              value={editForm.nickname}
              onChange={(e) =>
                setEditForm({ ...editForm, nickname: e.target.value })
              }
            />
            <TextField
              margin="normal"
              required
              fullWidth
              type="date"
              label="생년월일"
              InputLabelProps={{ shrink: true }}
              value={editForm.birthDate}
              onChange={(e) =>
                setEditForm({ ...editForm, birthDate: e.target.value })
              }
            />
            <TextField
              margin="normal"
              select
              fullWidth
              label="성별"
              value={editForm.gender}
              onChange={(e) =>
                setEditForm({ ...editForm, gender: e.target.value })
              }
            >
              <MenuItem value="남">남</MenuItem>
              <MenuItem value="여">여</MenuItem>
            </TextField>
            <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
              비밀번호 변경은 별도의 "비밀번호 초기화" 기능을 사용하세요.
            </Typography>
          </DialogContent>
          <DialogActions>
            <Button
              onClick={() => setEditTarget(null)}
              disabled={updateMutation.isPending}
            >
              취소
            </Button>
            <Button
              type="submit"
              variant="contained"
              disabled={updateMutation.isPending}
            >
              {updateMutation.isPending ? <CircularProgress size={20} /> : '저장'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* 비밀번호 초기화 */}
      <Dialog
        open={!!resetTarget}
        onClose={() => setResetTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <form onSubmit={handleResetSubmit}>
          <DialogTitle>비밀번호 초기화</DialogTitle>
          <DialogContent>
            {resetTarget && (
              <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                {resetTarget.email} ({resetTarget.nickname})
              </Typography>
            )}
            {resetError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {resetError}
              </Alert>
            )}
            <TextField
              margin="normal"
              required
              fullWidth
              type="password"
              label="새 비밀번호 (6자 이상)"
              value={newPw}
              onChange={(e) => setNewPw(e.target.value)}
              autoFocus
            />
            <TextField
              margin="normal"
              required
              fullWidth
              type="password"
              label="비밀번호 확인"
              value={newPw2}
              onChange={(e) => setNewPw2(e.target.value)}
            />
          </DialogContent>
          <DialogActions>
            <Button
              onClick={() => setResetTarget(null)}
              disabled={resetMutation.isPending}
            >
              취소
            </Button>
            <Button
              type="submit"
              variant="contained"
              disabled={resetMutation.isPending}
            >
              {resetMutation.isPending ? <CircularProgress size={20} /> : '저장'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* 사용자 삭제 확인 */}
      <Dialog
        open={!!deleteTarget}
        onClose={() => setDeleteTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <DialogTitle>사용자 삭제</DialogTitle>
        <DialogContent>
          {deleteError && (
            <Alert severity="error" sx={{ mb: 2 }}>
              {deleteError}
            </Alert>
          )}
          <DialogContentText>
            다음 사용자를 정말 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.
          </DialogContentText>
          {deleteTarget && (
            <Box
              sx={{
                mt: 2,
                p: 1.5,
                border: '1px solid #d8dbe0',
                borderRadius: 1,
                backgroundColor: '#f8f9fa',
              }}
            >
              <Typography variant="body2" sx={{ fontWeight: 600 }}>
                #{deleteTarget.id} · {deleteTarget.email}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {deleteTarget.nickname}
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button
            onClick={() => setDeleteTarget(null)}
            disabled={deleteMutation.isPending}
          >
            취소
          </Button>
          <Button
            variant="contained"
            color="error"
            onClick={() => deleteMutation.mutate(deleteTarget.id)}
            disabled={deleteMutation.isPending}
          >
            {deleteMutation.isPending ? <CircularProgress size={20} /> : '삭제'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
}
