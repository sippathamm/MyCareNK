export function createThGridLocale(noRowsLabel: string) {
  return {
    noRowsLabel,
    noResultsOverlayLabel: 'ไม่พบข้อมูล',
    MuiTablePagination: {
      labelRowsPerPage: 'จำนวนต่อหน้า:',
      labelDisplayedRows: ({ from, to, count }: { from: number; to: number; count: number }) =>
        `${from}–${to} จาก ${count !== -1 ? count : `มากกว่า ${to}`}`,
    },
  };
}
