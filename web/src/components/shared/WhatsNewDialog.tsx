import {
  Dialog, DialogTitle, DialogContent, DialogActions,
  Button, Typography, Divider, List, ListItem, Box,
} from '@mui/material';
import NewReleasesIcon from '@mui/icons-material/NewReleases';

export interface WhatsNewData {
  version: string;
  release_date: string;
  additions: string[];
  fixes: string[];
  improvements: string[];
  others: string[];
}

interface WhatsNewDialogProps {
  open: boolean;
  onClose: () => void;
  data: WhatsNewData;
}

const formatThaiDate = (dateStr: string) =>
  new Date(dateStr).toLocaleDateString('th-TH-u-ca-buddhist', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  });

interface SectionProps {
  label: string;
  items: string[];
}

function Section({ label, items }: SectionProps) {
  if (items.length === 0) return null;
  return (
    <Box sx={{ mt: 2 }}>
      <Typography variant="body2" fontWeight="bold" sx={{ mb: 0.5 }}>
        {label}
      </Typography>
      <List dense disablePadding>
        {items.map((item, i) => (
          <ListItem key={i} sx={{ py: 0.25, px: 0, alignItems: 'flex-start' }}>
            <Typography variant="body2" color="text.secondary">
              {'• '}{item}
            </Typography>
          </ListItem>
        ))}
      </List>
    </Box>
  );
}

export default function WhatsNewDialog({ open, onClose, data }: WhatsNewDialogProps) {
  return (
    <Dialog open={open} onClose={onClose} maxWidth="xs" fullWidth>
      <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
        <NewReleasesIcon color="primary" />
        <Typography component="div" variant="h6" fontWeight="bold">มีอะไรใหม่</Typography>
      </DialogTitle>
      <Divider />
      <DialogContent sx={{ pt: 2.5 }}>
        <Typography variant="body1" color="text.secondary">
          {data.version} – {formatThaiDate(data.release_date)}
        </Typography>
        <Section label="เพิ่ม" items={data.additions} />
        <Section label="แก้ไข" items={data.fixes} />
        <Section label="ปรับปรุง" items={data.improvements} />
        <Section label="อื่น ๆ" items={data.others} />
      </DialogContent>
      <DialogActions sx={{ px: 3, pb: 2.5 }}>
        <Button variant="contained" onClick={onClose}>ปิด</Button>
      </DialogActions>
    </Dialog>
  );
}
