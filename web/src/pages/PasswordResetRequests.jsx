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
  Chip,
  Stack,
  ToggleButton,
  ToggleButtonGroup,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import LockResetIcon from '@mui/icons-material/LockReset';
import BlockIcon from '@mui/icons-material/Block';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  fetchPasswordResetRequests,
  resolvePasswordResetRequest,
  rejectPasswordResetRequest,
} from '../api.js';

const formatDate = (iso) => {
  if (!iso) return '—';
  try {
    return new Date(iso).toLocaleString('ko-KR');
  } catch {
    return String(iso);
  }
};

const errorMessage = (err, fallback) => {
  const msg = err?.response?.data?.message || err?.message || fallback;
  return Array.isArray(msg) ? msg.join(', ') : msg;
};

const STATUS_LABEL = {
  pending: { label: '대기 중', color: 'warning' },
  done: { label: '처리 완료', color: 'success' },
  rejected: { label: '거절됨', color: 'default' },
};

export default function PasswordResetRequests() {
  const queryClient = useQueryClient();
  const [statusFilter, setStatusFilter] = useState('pending');

  const [resolveTarget, setResolveTarget] = useState(null);
  const [newPw, setNewPw] = useState('');
  const [newPw2, setNewPw2] = useState('');
  const [resolveMemo, setResolveMemo] = useState('');
  const [resolveError, setResolveError] = useState(null);

  const [rejectTarget, setRejectTarget] = useState(null);
  const [rejectMemo, setRejectMemo] = useState('');
  const [rejectError, setRejectError] = useState(null);

  const {
    data: rows = [],
    isLoading,
    error,
  } = useQuery({
    queryKey: ['admin-password-reset-requests', statusFilter],
    queryFn: () => fetchPasswordResetRequests(statusFilter || undefined),
  });

  const resolveMutation = useMutation({
    mutationFn: ({ id, newPassword, memo }) =>
      resolvePasswordResetRequest(id, newPassword, memo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-password-reset-requests'] });
      queryClient.invalidateQueries({ queryKey: ['admin-password-reset-pending-count'] });
      setResolveTarget(null);
      setNewPw('');
      setNewPw2('');
      setResolveMemo('');
      setResolveError(null);
    },
    onError: (err) =>
      setResolveError(errorMessage(err, '요청 처리에 실패했습니다.')),
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, memo }) => rejectPasswordResetRequest(id, memo),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['admin-password-reset-requests'] });
      queryClient.invalidateQueries({ queryKey: ['admin-password-reset-pending-count'] });
      setRejectTarget(null);
      setRejectMemo('');
      setRejectError(null);
    },
    onError: (err) =>
      setRejectError(errorMessage(err, '요청 거절에 실패했습니다.')),
  });

  const handleResolveSubmit = (e) => {
    e.preventDefault();
    setResolveError(null);
    if (newPw.length < 6) {
      setResolveError('비밀번호는 6자 이상이어야 합니다.');
      return;
    }
    if (newPw !== newPw2) {
      setResolveError('비밀번호 확인이 일치하지 않습니다.');
      return;
    }
    resolveMutation.mutate({
      id: resolveTarget.id,
      newPassword: newPw,
      memo: resolveMemo.trim() || undefined,
    });
  };

  const handleRejectSubmit = (e) => {
    e.preventDefault();
    setRejectError(null);
    rejectMutation.mutate({
      id: rejectTarget.id,
      memo: rejectMemo.trim() || undefined,
    });
  };

  const columns = [
    { field: 'id', headerName: 'ID', width: 70 },
    { field: 'email', headerName: '요청 이메일', flex: 1, minWidth: 220 },
    {
      field: 'nickname',
      headerName: '회원',
      width: 140,
      valueGetter: (_, row) => row.nickname ?? '—',
    },
    {
      field: 'status',
      headerName: '상태',
      width: 110,
      renderCell: (params) => {
        const def = STATUS_LABEL[params.value] ?? { label: params.value, color: 'default' };
        return <Chip size="small" label={def.label} color={def.color} variant="outlined" />;
      },
    },
    {
      field: 'createdAt',
      headerName: '요청 일시',
      width: 170,
      valueFormatter: (value) => formatDate(value),
    },
    {
      field: 'resolvedAt',
      headerName: '처리 일시',
      width: 170,
      valueFormatter: (value) => formatDate(value),
    },
    {
      field: 'resolvedBy',
      headerName: '처리자',
      width: 110,
      valueGetter: (_, row) => row.resolvedBy ?? '—',
    },
    {
      field: 'memo',
      headerName: '메모',
      flex: 1,
      minWidth: 160,
      valueGetter: (_, row) => row.memo ?? '',
    },
    {
      field: 'actions',
      headerName: '작업',
      width: 140,
      sortable: false,
      renderCell: (params) => {
        if (params.row.status !== 'pending') {
          return (
            <Typography variant="caption" color="text.secondary">
              처리됨
            </Typography>
          );
        }
        return (
          <Stack direction="row" spacing={0.5} alignItems="center" height="100%">
            <IconButton
              size="small"
              color="primary"
              title="비밀번호 초기화"
              onClick={() => {
                setResolveTarget(params.row);
                setNewPw('');
                setNewPw2('');
                setResolveMemo('');
                setResolveError(null);
              }}
            >
              <LockResetIcon fontSize="small" />
            </IconButton>
            <IconButton
              size="small"
              color="error"
              title="요청 거절"
              onClick={() => {
                setRejectTarget(params.row);
                setRejectMemo('');
                setRejectError(null);
              }}
            >
              <BlockIcon fontSize="small" />
            </IconButton>
          </Stack>
        );
      },
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
          비밀번호 초기화 요청
        </Typography>
        <ToggleButtonGroup
          value={statusFilter}
          exclusive
          size="small"
          onChange={(_, v) => v !== null && setStatusFilter(v)}
        >
          <ToggleButton value="pending">대기 중</ToggleButton>
          <ToggleButton value="done">처리 완료</ToggleButton>
          <ToggleButton value="rejected">거절됨</ToggleButton>
          <ToggleButton value="">전체</ToggleButton>
        </ToggleButtonGroup>
      </Box>

      {error && (
        <Alert severity="error" sx={{ mb: 2 }}>
          {errorMessage(error, '요청 목록을 불러오지 못했습니다.')}
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
          rows={rows}
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

      {/* 비밀번호 초기화 처리 */}
      <Dialog
        open={!!resolveTarget}
        onClose={() => setResolveTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <form onSubmit={handleResolveSubmit}>
          <DialogTitle>비밀번호 초기화 처리</DialogTitle>
          <DialogContent>
            {resolveTarget && (
              <Box
                sx={{
                  mb: 2,
                  p: 1.5,
                  border: '1px solid #d8dbe0',
                  borderRadius: 1,
                  backgroundColor: '#f8f9fa',
                }}
              >
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  #{resolveTarget.id} · {resolveTarget.email}
                </Typography>
                {resolveTarget.nickname && (
                  <Typography variant="body2" color="text.secondary">
                    {resolveTarget.nickname}
                  </Typography>
                )}
                <Typography variant="caption" color="text.secondary">
                  요청 일시: {formatDate(resolveTarget.createdAt)}
                </Typography>
              </Box>
            )}
            {resolveError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {resolveError}
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
            <TextField
              margin="normal"
              fullWidth
              label="메모 (선택)"
              value={resolveMemo}
              onChange={(e) => setResolveMemo(e.target.value)}
              multiline
              minRows={2}
            />
          </DialogContent>
          <DialogActions>
            <Button
              onClick={() => setResolveTarget(null)}
              disabled={resolveMutation.isPending}
            >
              취소
            </Button>
            <Button
              type="submit"
              variant="contained"
              disabled={resolveMutation.isPending}
            >
              {resolveMutation.isPending ? <CircularProgress size={20} /> : '처리'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>

      {/* 요청 거절 */}
      <Dialog
        open={!!rejectTarget}
        onClose={() => setRejectTarget(null)}
        maxWidth="xs"
        fullWidth
      >
        <form onSubmit={handleRejectSubmit}>
          <DialogTitle>요청 거절</DialogTitle>
          <DialogContent>
            <DialogContentText sx={{ mb: 2 }}>
              이 요청을 거절 처리하시겠습니까?
            </DialogContentText>
            {rejectTarget && (
              <Box
                sx={{
                  mb: 2,
                  p: 1.5,
                  border: '1px solid #d8dbe0',
                  borderRadius: 1,
                  backgroundColor: '#f8f9fa',
                }}
              >
                <Typography variant="body2" sx={{ fontWeight: 600 }}>
                  #{rejectTarget.id} · {rejectTarget.email}
                </Typography>
              </Box>
            )}
            {rejectError && (
              <Alert severity="error" sx={{ mb: 2 }}>
                {rejectError}
              </Alert>
            )}
            <TextField
              margin="normal"
              fullWidth
              label="사유 메모 (선택)"
              value={rejectMemo}
              onChange={(e) => setRejectMemo(e.target.value)}
              multiline
              minRows={2}
              autoFocus
            />
          </DialogContent>
          <DialogActions>
            <Button
              onClick={() => setRejectTarget(null)}
              disabled={rejectMutation.isPending}
            >
              취소
            </Button>
            <Button
              type="submit"
              variant="contained"
              color="error"
              disabled={rejectMutation.isPending}
            >
              {rejectMutation.isPending ? <CircularProgress size={20} /> : '거절'}
            </Button>
          </DialogActions>
        </form>
      </Dialog>
    </Box>
  );
}
