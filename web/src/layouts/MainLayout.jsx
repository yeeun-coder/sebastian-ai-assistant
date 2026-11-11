import { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Drawer,
  AppBar,
  Toolbar,
  List,
  Typography,
  Divider,
  IconButton,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Avatar,
  Menu,
  MenuItem,
  Breadcrumbs,
  Link,
  Badge,
  useTheme,
  useMediaQuery,
} from '@mui/material';
import MenuIcon from '@mui/icons-material/Menu';
import PeopleIcon from '@mui/icons-material/People';
import LockResetIcon from '@mui/icons-material/LockReset';
import LogoutIcon from '@mui/icons-material/Logout';
import NavigateNextIcon from '@mui/icons-material/NavigateNext';
import HomeIcon from '@mui/icons-material/Home';
import { useQuery } from '@tanstack/react-query';
import { useAuth } from '../auth.jsx';
import { fetchPasswordResetPendingCount } from '../api.js';

const drawerWidth = 256;
const sidebarBg = '#3c4b64';
const sidebarTextColor = 'rgba(255, 255, 255, 0.87)';
const sidebarTextMuted = 'rgba(255, 255, 255, 0.5)';
const sidebarActiveColor = '#fff';
const sidebarActiveBg = 'rgba(255, 255, 255, 0.1)';
const sidebarHoverBg = 'rgba(255, 255, 255, 0.05)';

const menuItems = [
  { text: '사용자 관리', icon: <PeopleIcon />, path: '/users' },
  {
    text: '비밀번호 초기화 요청',
    icon: <LockResetIcon />,
    path: '/password-reset-requests',
    badgeKey: 'passwordResetPending',
  },
];

export default function MainLayout({ children }) {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('md'));
  const [mobileOpen, setMobileOpen] = useState(false);
  const [anchorEl, setAnchorEl] = useState(null);
  const navigate = useNavigate();
  const location = useLocation();
  const { logout } = useAuth();

  const { data: pendingCountData } = useQuery({
    queryKey: ['admin-password-reset-pending-count'],
    queryFn: fetchPasswordResetPendingCount,
    refetchInterval: 30000,
  });
  const badgeValues = {
    passwordResetPending: pendingCountData?.count ?? 0,
  };

  const currentPage = menuItems.find((item) => item.path === location.pathname);

  const handleDrawerToggle = () => setMobileOpen(!mobileOpen);
  const handleMenuOpen = (e) => setAnchorEl(e.currentTarget);
  const handleMenuClose = () => setAnchorEl(null);

  const handleLogout = () => {
    handleMenuClose();
    logout();
    navigate('/login');
  };

  const renderNavItem = (item) => {
    const isActive = location.pathname === item.path;
    const badgeValue = item.badgeKey ? badgeValues[item.badgeKey] ?? 0 : 0;
    return (
      <ListItem key={item.text} disablePadding sx={{ mb: 0.25 }}>
        <ListItemButton
          selected={isActive}
          onClick={() => {
            navigate(item.path);
            if (isMobile) setMobileOpen(false);
          }}
          sx={{
            borderRadius: 0,
            minHeight: 44,
            px: 2.5,
            color: isActive ? sidebarActiveColor : sidebarTextColor,
            backgroundColor: isActive ? sidebarActiveBg : 'transparent',
            borderLeft: isActive
              ? '3px solid #321fdb'
              : '3px solid transparent',
            '&:hover': { backgroundColor: sidebarHoverBg },
            '&.Mui-selected': {
              backgroundColor: sidebarActiveBg,
              '&:hover': { backgroundColor: sidebarActiveBg },
            },
          }}
        >
          <ListItemIcon
            sx={{
              minWidth: 36,
              color: isActive ? sidebarActiveColor : sidebarTextMuted,
              '& .MuiSvgIcon-root': { fontSize: 20 },
            }}
          >
            {item.icon}
          </ListItemIcon>
          <ListItemText
            primary={item.text}
            primaryTypographyProps={{
              fontSize: '0.875rem',
              fontWeight: isActive ? 600 : 400,
            }}
          />
          {badgeValue > 0 && (
            <Badge
              badgeContent={badgeValue}
              color="error"
              sx={{
                ml: 1,
                mr: 0.5,
                '& .MuiBadge-badge': {
                  position: 'static',
                  transform: 'none',
                },
              }}
            />
          )}
        </ListItemButton>
      </ListItem>
    );
  };

  const drawer = (
    <Box
      sx={{
        height: '100%',
        display: 'flex',
        flexDirection: 'column',
        backgroundColor: sidebarBg,
        color: sidebarTextColor,
      }}
    >
      <Box
        sx={{
          height: 56,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          borderBottom: '1px solid rgba(255,255,255,0.1)',
        }}
      >
        <Typography
          variant="h6"
          noWrap
          sx={{
            fontWeight: 700,
            color: '#fff',
            letterSpacing: 2,
            fontSize: '1.25rem',
          }}
        >
          SEBASTIAN
        </Typography>
      </Box>

      <Box sx={{ flex: 1, overflow: 'auto', py: 1 }}>
        <List disablePadding>{menuItems.map(renderNavItem)}</List>
      </Box>

      <Box
        sx={{
          borderTop: '1px solid rgba(255,255,255,0.1)',
          p: 2,
          display: 'flex',
          alignItems: 'center',
          gap: 1.5,
        }}
      >
        <Avatar
          sx={{
            width: 36,
            height: 36,
            bgcolor: '#321fdb',
            fontSize: '0.875rem',
            fontWeight: 600,
          }}
        >
          A
        </Avatar>
        <Box sx={{ overflow: 'hidden' }}>
          <Typography
            variant="body2"
            noWrap
            sx={{ color: '#fff', fontWeight: 500, fontSize: '0.8rem' }}
          >
            admin
          </Typography>
          <Typography
            variant="caption"
            noWrap
            sx={{ color: sidebarTextMuted, fontSize: '0.7rem' }}
          >
            관리자
          </Typography>
        </Box>
      </Box>
    </Box>
  );

  const drawerPaperSx = {
    boxSizing: 'border-box',
    width: drawerWidth,
    border: 'none',
    backgroundColor: sidebarBg,
  };

  return (
    <Box sx={{ display: 'flex', minHeight: '100vh' }}>
      <AppBar
        position="fixed"
        sx={{
          width: { md: `calc(100% - ${drawerWidth}px)` },
          ml: { md: `${drawerWidth}px` },
          backgroundColor: '#fff',
          color: '#3c4b64',
          borderBottom: '1px solid #d8dbe0',
        }}
        elevation={0}
      >
        <Toolbar sx={{ minHeight: { xs: 56, sm: 56 } }}>
          <IconButton
            aria-label="open drawer"
            edge="start"
            onClick={handleDrawerToggle}
            sx={{ mr: 2, display: { md: 'none' }, color: '#3c4b64' }}
          >
            <MenuIcon />
          </IconButton>
          <Box sx={{ flexGrow: 1 }} />
          <Typography
            variant="body2"
            sx={{
              mr: 1.5,
              color: '#768192',
              display: { xs: 'none', sm: 'block' },
            }}
          >
            admin
          </Typography>
          <IconButton onClick={handleMenuOpen} size="small">
            <Avatar
              sx={{
                width: 36,
                height: 36,
                bgcolor: '#321fdb',
                fontSize: '0.875rem',
                fontWeight: 600,
              }}
            >
              A
            </Avatar>
          </IconButton>
          <Menu
            anchorEl={anchorEl}
            open={Boolean(anchorEl)}
            onClose={handleMenuClose}
            transformOrigin={{ horizontal: 'right', vertical: 'top' }}
            anchorOrigin={{ horizontal: 'right', vertical: 'bottom' }}
            PaperProps={{
              sx: {
                mt: 1,
                minWidth: 180,
                border: '1px solid #d8dbe0',
                boxShadow: '0 0.5rem 1rem rgba(8,10,12,0.15)',
              },
            }}
          >
            <MenuItem disabled>
              <Typography variant="body2" sx={{ fontWeight: 500 }}>
                admin
              </Typography>
            </MenuItem>
            <Divider />
            <MenuItem onClick={handleLogout}>
              <ListItemIcon>
                <LogoutIcon fontSize="small" />
              </ListItemIcon>
              로그아웃
            </MenuItem>
          </Menu>
        </Toolbar>
      </AppBar>

      <Box component="nav" sx={{ width: { md: drawerWidth }, flexShrink: { md: 0 } }}>
        <Drawer
          variant="temporary"
          open={mobileOpen}
          onClose={handleDrawerToggle}
          ModalProps={{ keepMounted: true }}
          sx={{
            display: { xs: 'block', md: 'none' },
            '& .MuiDrawer-paper': drawerPaperSx,
          }}
        >
          {drawer}
        </Drawer>
        <Drawer
          variant="permanent"
          sx={{
            display: { xs: 'none', md: 'block' },
            '& .MuiDrawer-paper': drawerPaperSx,
          }}
          open
        >
          {drawer}
        </Drawer>
      </Box>

      <Box
        component="main"
        sx={{
          flexGrow: 1,
          width: { xs: '100%', md: `calc(100% - ${drawerWidth}px)` },
          minHeight: '100vh',
          backgroundColor: '#ebedef',
          overflow: 'auto',
        }}
      >
        <Toolbar sx={{ minHeight: { xs: 56, sm: 56 } }} />
        <Box
          sx={{
            backgroundColor: '#fff',
            borderBottom: '1px solid #d8dbe0',
            px: 3,
            py: 1,
          }}
        >
          <Breadcrumbs
            separator={
              <NavigateNextIcon sx={{ fontSize: 16, color: '#9da5b1' }} />
            }
            sx={{ fontSize: '0.875rem' }}
          >
            <Link
              underline="hover"
              sx={{
                display: 'flex',
                alignItems: 'center',
                color: '#768192',
                cursor: 'pointer',
                fontSize: '0.875rem',
              }}
              onClick={() => navigate('/users')}
            >
              <HomeIcon sx={{ mr: 0.5, fontSize: 18 }} />
              Home
            </Link>
            {currentPage && (
              <Typography
                sx={{
                  color: '#3c4b64',
                  fontWeight: 500,
                  fontSize: '0.875rem',
                }}
              >
                {currentPage.text}
              </Typography>
            )}
          </Breadcrumbs>
        </Box>
        <Box sx={{ p: 3 }}>{children}</Box>
      </Box>
    </Box>
  );
}
