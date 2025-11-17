// lib/config/permission_mapping.dart

const defaultPermissions = {
  // Dashboard Tabs
  'dashboard.keuangan': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': false,
  },
  'dashboard.transaksi': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': true,
  },

  // Footer Menus
  'footer.beranda': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': true,
  },
  'footer.pesanan': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': true,
  },
  'footer.order': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': false,
  },
  'footer.laporan': {
    'owner': true,
    'admin': true,
    'kasir': true,
    'produksi': false,
  },

  // App Bar Icons
  'appbar.settings': {
    'owner': true,
    'admin': false,
    'kasir': false,
    'produksi': false,
  },
};
