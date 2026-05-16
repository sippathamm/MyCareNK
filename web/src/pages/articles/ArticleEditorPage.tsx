import { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box, Typography, Paper, Button, IconButton, Tooltip,
  Stack, TextField, Divider, RadioGroup, FormControlLabel, Radio,
  Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions,
  Snackbar, Alert,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import FormatBoldIcon from '@mui/icons-material/FormatBold';
import FormatItalicIcon from '@mui/icons-material/FormatItalic';
import StrikethroughSIcon from '@mui/icons-material/StrikethroughS';
import FormatListBulletedIcon from '@mui/icons-material/FormatListBulleted';
import FormatListNumberedIcon from '@mui/icons-material/FormatListNumbered';
import FormatQuoteIcon from '@mui/icons-material/FormatQuote';
import CodeIcon from '@mui/icons-material/Code';
import ImageIcon from '@mui/icons-material/Image';
import VideoLibraryIcon from '@mui/icons-material/VideoLibrary';
import LinkIcon from '@mui/icons-material/Link';
import UndoIcon from '@mui/icons-material/Undo';
import RedoIcon from '@mui/icons-material/Redo';
import ArticleIcon from '@mui/icons-material/Article';
import { useEditor, EditorContent } from '@tiptap/react';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import Link from '@tiptap/extension-link';
import Youtube from '@tiptap/extension-youtube';
import Placeholder from '@tiptap/extension-placeholder';
import CharacterCount from '@tiptap/extension-character-count';
import { supabase } from '../../lib/supabase';

// ─── Types ────────────────────────────────────────────────────────────────────

interface SnackbarState {
  open: boolean;
  message: string;
  severity: 'success' | 'error';
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function ArticleEditorPage() {
  const navigate = useNavigate();
  const { id: articleId } = useParams<{ id: string }>();
  const isEditMode = !!articleId;

  // ─── State ─────────────────────────────────────────────────────────────────

  const [title, setTitle] = useState('');
  const [coverUrl, setCoverUrl] = useState<string | null>(null);
  const [publishMode, setPublishMode] = useState<'immediate' | 'scheduled'>('immediate');
  const [scheduledAt, setScheduledAt] = useState<Date | null>(null);
  const [saving, setSaving] = useState(false);
  const [snackbar, setSnackbar] = useState<SnackbarState>({ open: false, message: '', severity: 'success' });

  // ─── Dialog state ──────────────────────────────────────────────────────────

  const [videoDialogOpen, setVideoDialogOpen] = useState(false);
  const [videoUrl, setVideoUrl] = useState('');
  const [linkDialogOpen, setLinkDialogOpen] = useState(false);
  const [linkUrl, setLinkUrl] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);

  // ─── Auto-save ─────────────────────────────────────────────────────────────

  const autoSaveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isInitialLoad = useRef(true);

  // ─── File input refs ───────────────────────────────────────────────────────

  const imageInputRef = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  // ─── Editor ────────────────────────────────────────────────────────────────

  const editor = useEditor({
    extensions: [
      StarterKit,
      Image,
      Link.configure({ openOnClick: false }),
      Youtube.configure({ width: 640, height: 360, nocookie: true }),
      Placeholder.configure({ placeholder: 'เริ่มเขียนบทความ...' }),
      CharacterCount,
    ],
    content: '',
    onUpdate: () => {
      if (isInitialLoad.current || !isEditMode) return;
      scheduleAutoSave();
    },
  });

  // ─── Load existing article ─────────────────────────────────────────────────

  useEffect(() => {
    if (!articleId || !editor) return;
    supabase
      .from('articles')
      .select('*')
      .eq('id', articleId)
      .single()
      .then(({ data, error }) => {
        if (error || !data) return;
        setTitle(data.title);
        setCoverUrl(data.cover_image_url);
        if (data.publish_at) {
          const d = new Date(data.publish_at);
          if (d > new Date()) {
            setPublishMode('scheduled');
            setScheduledAt(d);
          } else {
            setPublishMode('immediate');
          }
        }
        editor.commands.setContent(data.content_json as object);
        setTimeout(() => { isInitialLoad.current = false; }, 300);
      });
  }, [articleId, editor]);

  // ─── Auto-save logic ───────────────────────────────────────────────────────

  const scheduleAutoSave = useCallback(() => {
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    autoSaveTimer.current = setTimeout(async () => {
      if (!editor || !articleId) return;
      const excerpt = editor.getText().slice(0, 150) || null;
      await supabase.from('articles').update({
        title: title.trim() || 'ไม่มีหัวเรื่อง',
        content_html: editor.getHTML(),
        content_json: editor.getJSON(),
        excerpt,
        cover_image_url: coverUrl || null,
      }).eq('id', articleId);
    }, 2000);
  }, [editor, articleId, title, coverUrl]);

  useEffect(() => {
    if (isInitialLoad.current || !isEditMode) return;
    scheduleAutoSave();
  }, [title, scheduleAutoSave, isEditMode]);

  useEffect(() => {
    return () => { if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current); };
  }, []);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  function showSnackbar(message: string, severity: 'success' | 'error') {
    setSnackbar({ open: true, message, severity });
  }

  function getFileExtension(filename: string) {
    return filename.split('.').pop() ?? 'jpg';
  }

  // ─── Image upload ──────────────────────────────────────────────────────────

  async function handleImageFileChange(file: File) {
    const ext = getFileExtension(file.name);
    const path = `content/${crypto.randomUUID()}.${ext}`;
    const { error } = await supabase.storage.from('article-assets').upload(path, file, {
      cacheControl: '3600',
      upsert: false,
    });
    if (error) { showSnackbar(`อัปโหลดรูปไม่สำเร็จ: ${error.message}`, 'error'); return; }
    const { data: { publicUrl } } = supabase.storage.from('article-assets').getPublicUrl(path);
    editor?.chain().focus().setImage({ src: publicUrl }).run();
  }

  async function handleCoverFileChange(file: File) {
    const ext = getFileExtension(file.name);
    const path = `cover/${crypto.randomUUID()}.${ext}`;
    const { error } = await supabase.storage.from('article-assets').upload(path, file, {
      cacheControl: '3600',
      upsert: false,
    });
    if (error) { showSnackbar(`อัปโหลดรูปหน้าปกไม่สำเร็จ: ${error.message}`, 'error'); return; }
    const { data: { publicUrl } } = supabase.storage.from('article-assets').getPublicUrl(path);
    setCoverUrl(publicUrl);
  }

  // ─── Video insert ──────────────────────────────────────────────────────────

  function handleVideoConfirm() {
    if (!videoUrl.trim() || !editor) { setVideoDialogOpen(false); return; }
    const isYoutube = /youtu\.be\/|youtube\.com\/watch/.test(videoUrl);
    if (isYoutube) {
      editor.commands.setYoutubeVideo({ src: videoUrl });
    } else {
      editor.chain().focus().insertContent(
        `<iframe src="${videoUrl}" style="width:100%;aspect-ratio:16/9;border:0;" allowfullscreen></iframe>`
      ).run();
    }
    setVideoUrl('');
    setVideoDialogOpen(false);
  }

  // ─── Link insert ───────────────────────────────────────────────────────────

  function handleLinkConfirm() {
    if (!linkUrl.trim() || !editor) { setLinkDialogOpen(false); return; }
    editor.chain().focus().setLink({ href: linkUrl }).run();
    setLinkUrl('');
    setLinkDialogOpen(false);
  }

  // ─── Save ──────────────────────────────────────────────────────────────────

  async function handleSave(mode: 'draft' | 'publish') {
    if (!editor) return;
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    setSaving(true);

    const excerpt = editor.getText().slice(0, 150) || null;

    const payload = {
      title: title.trim() || 'ไม่มีหัวเรื่อง',
      content_html: editor.getHTML(),
      content_json: editor.getJSON(),
      excerpt,
      cover_image_url: coverUrl || null,
      publish_at:
        mode === 'draft'
          ? null
          : publishMode === 'immediate'
          ? new Date().toISOString()
          : scheduledAt?.toISOString() ?? null,
    };

    if (articleId) {
      const { error } = await supabase.from('articles').update(payload).eq('id', articleId);
      if (error) {
        showSnackbar(`บันทึกไม่สำเร็จ: ${error.message}`, 'error');
      } else {
        showSnackbar('บันทึกบทความเรียบร้อยแล้ว', 'success');
      }
    } else {
      const userRes = await supabase.auth.getUser();
      const { data, error } = await supabase
        .from('articles')
        .insert({ ...payload, created_by: userRes.data.user?.id ?? null })
        .select('id')
        .single();
      if (error) {
        showSnackbar(`สร้างบทความไม่สำเร็จ: ${error.message}`, 'error');
      } else if (data) {
        navigate(`/articles/${data.id}/edit`, { replace: true });
        showSnackbar('สร้างบทความเรียบร้อยแล้ว', 'success');
      }
    }

    setSaving(false);
  }

  // ─── Delete ────────────────────────────────────────────────────────────────

  async function handleDelete() {
    if (!articleId) return;
    setDeleting(true);
    const { error } = await supabase.from('articles').delete().eq('id', articleId);
    setDeleting(false);
    if (error) {
      setDeleteDialogOpen(false);
      showSnackbar(`ลบไม่สำเร็จ: ${error.message}`, 'error');
    } else {
      navigate('/articles', { replace: true });
    }
  }

  // ─── Scheduled datetime local string ──────────────────────────────────────

  function toDatetimeLocalString(date: Date | null): string {
    if (!date) return '';
    const pad = (n: number) => String(n).padStart(2, '0');
    return (
      `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}` +
      `T${pad(date.getHours())}:${pad(date.getMinutes())}`
    );
  }

  const publishButtonLabel = publishMode === 'scheduled' ? 'เผยแพร่ภายหลัง' : 'เผยแพร่';

  // ─── Render ────────────────────────────────────────────────────────────────

  return (
    <Box sx={{ width: '100%', maxWidth: 1400, margin: '0 auto' }}>
      {/* Page header */}
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Box display="flex" alignItems="center" gap={1}>
          <IconButton onClick={() => navigate('/articles')}>
            <ArrowBackIcon />
          </IconButton>
          <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
            {isEditMode ? 'แก้ไขบทความ' : 'สร้างบทความใหม่'}
          </Typography>
        </Box>
        {isEditMode && (
          <Button
            variant="outlined"
            color="error"
            startIcon={<DeleteOutlineIcon />}
            onClick={() => setDeleteDialogOpen(true)}
            size="small"
          >
            ลบบทความ
          </Button>
        )}
      </Box>

      {/* 2-column layout */}
      <Box sx={{ display: 'flex', gap: 3, alignItems: 'flex-start' }}>
        {/* ── Left column ───────────────────────────────────────────── */}
        <Paper elevation={1} sx={{ flex: 2, minWidth: 0, p: 3, borderRadius: 2 }}>
          {/* Title */}
          <TextField
            fullWidth
            placeholder="หัวเรื่อง"
            variant="standard"
            value={title}
            onChange={e => setTitle(e.target.value)}
            slotProps={{
              input: { disableUnderline: true },
              htmlInput: { style: { fontSize: 28, fontWeight: 700 } },
            }}
            sx={{ mb: 2 }}
          />
          <Divider sx={{ mb: 1 }} />

          {/* Toolbar */}
          <Stack direction="row" spacing={0.5} flexWrap="wrap" sx={{ mb: 1 }}>
            {/* Bold */}
            <Tooltip title="ตัวหนา">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleBold().run()}
                sx={{ color: editor?.isActive('bold') ? 'primary.main' : 'inherit' }}
              >
                <FormatBoldIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Italic */}
            <Tooltip title="ตัวเอียง">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleItalic().run()}
                sx={{ color: editor?.isActive('italic') ? 'primary.main' : 'inherit' }}
              >
                <FormatItalicIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Strikethrough */}
            <Tooltip title="ขีดทับ">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleStrike().run()}
                sx={{ color: editor?.isActive('strike') ? 'primary.main' : 'inherit' }}
              >
                <StrikethroughSIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* H1 */}
            <Tooltip title="หัวข้อ 1">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleHeading({ level: 1 }).run()}
                sx={{ color: editor?.isActive('heading', { level: 1 }) ? 'primary.main' : 'inherit' }}
              >
                <Typography variant="caption" fontWeight="bold" lineHeight={1}>H1</Typography>
              </IconButton>
            </Tooltip>

            {/* H2 */}
            <Tooltip title="หัวข้อ 2">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleHeading({ level: 2 }).run()}
                sx={{ color: editor?.isActive('heading', { level: 2 }) ? 'primary.main' : 'inherit' }}
              >
                <Typography variant="caption" fontWeight="bold" lineHeight={1}>H2</Typography>
              </IconButton>
            </Tooltip>

            {/* H3 */}
            <Tooltip title="หัวข้อ 3">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleHeading({ level: 3 }).run()}
                sx={{ color: editor?.isActive('heading', { level: 3 }) ? 'primary.main' : 'inherit' }}
              >
                <Typography variant="caption" fontWeight="bold" lineHeight={1}>H3</Typography>
              </IconButton>
            </Tooltip>

            {/* Bullet list */}
            <Tooltip title="รายการหัวข้อ">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleBulletList().run()}
                sx={{ color: editor?.isActive('bulletList') ? 'primary.main' : 'inherit' }}
              >
                <FormatListBulletedIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Ordered list */}
            <Tooltip title="รายการลำดับ">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleOrderedList().run()}
                sx={{ color: editor?.isActive('orderedList') ? 'primary.main' : 'inherit' }}
              >
                <FormatListNumberedIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Blockquote */}
            <Tooltip title="คำพูดอ้างอิง">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleBlockquote().run()}
                sx={{ color: editor?.isActive('blockquote') ? 'primary.main' : 'inherit' }}
              >
                <FormatQuoteIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Code block */}
            <Tooltip title="โค้ด">
              <IconButton
                size="small"
                onClick={() => editor?.chain().focus().toggleCodeBlock().run()}
                sx={{ color: editor?.isActive('codeBlock') ? 'primary.main' : 'inherit' }}
              >
                <CodeIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            <Divider orientation="vertical" flexItem />

            {/* Insert image */}
            <Tooltip title="แทรกรูปภาพ">
              <IconButton size="small" onClick={() => imageInputRef.current?.click()}>
                <ImageIcon fontSize="small" />
              </IconButton>
            </Tooltip>
            <input
              ref={imageInputRef}
              type="file"
              accept="image/*"
              style={{ display: 'none' }}
              onChange={e => {
                const file = e.target.files?.[0];
                if (file) handleImageFileChange(file);
                e.target.value = '';
              }}
            />

            {/* Insert video */}
            <Tooltip title="แทรกวิดีโอ">
              <IconButton size="small" onClick={() => setVideoDialogOpen(true)}>
                <VideoLibraryIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Insert link */}
            <Tooltip title="แทรกลิงก์">
              <IconButton
                size="small"
                onClick={() => setLinkDialogOpen(true)}
                sx={{ color: editor?.isActive('link') ? 'primary.main' : 'inherit' }}
              >
                <LinkIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            <Divider orientation="vertical" flexItem />

            {/* Undo */}
            <Tooltip title="เลิกทำ">
              <IconButton size="small" onClick={() => editor?.chain().focus().undo().run()}>
                <UndoIcon fontSize="small" />
              </IconButton>
            </Tooltip>

            {/* Redo */}
            <Tooltip title="ทำซ้ำ">
              <IconButton size="small" onClick={() => editor?.chain().focus().redo().run()}>
                <RedoIcon fontSize="small" />
              </IconButton>
            </Tooltip>
          </Stack>

          {/* Editor content */}
          <Box
            sx={{
              border: '1px solid',
              borderColor: 'divider',
              borderRadius: 1,
              p: 2,
              minHeight: 400,
              '& .ProseMirror': { outline: 'none', minHeight: 360 },
              '& .ProseMirror p.is-editor-empty:first-of-type::before': {
                content: 'attr(data-placeholder)',
                color: '#aaa',
                pointerEvents: 'none',
                float: 'left',
                height: 0,
              },
              '& .ProseMirror h1': { fontSize: '1.8rem', fontWeight: 700, mt: 2, mb: 1 },
              '& .ProseMirror h2': { fontSize: '1.4rem', fontWeight: 700, mt: 2, mb: 1 },
              '& .ProseMirror h3': { fontSize: '1.2rem', fontWeight: 600, mt: 1.5, mb: 0.5 },
              '& .ProseMirror ul, & .ProseMirror ol': { pl: 3 },
              '& .ProseMirror blockquote': { borderLeft: '3px solid #ccc', pl: 2, color: 'text.secondary' },
              '& .ProseMirror img': { maxWidth: '100%', borderRadius: 1 },
              '& .ProseMirror iframe': { maxWidth: '100%', width: '100%', aspectRatio: '16/9', border: 0 },
            }}
          >
            <EditorContent editor={editor} />
          </Box>
        </Paper>

        {/* ── Right sidebar ─────────────────────────────────────────── */}
        <Box sx={{ width: 320, flexShrink: 0 }}>
          <Stack spacing={2}>
            {/* Publish settings */}
            <Paper elevation={1} sx={{ p: 2.5, borderRadius: 2 }}>
              <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
                ตั้งค่าการเผยแพร่
              </Typography>
              <RadioGroup
                value={publishMode}
                onChange={e => setPublishMode(e.target.value as 'immediate' | 'scheduled')}
              >
                <FormControlLabel value="immediate" control={<Radio size="small" />} label="เผยแพร่ทันที" />
                <FormControlLabel value="scheduled" control={<Radio size="small" />} label="ตั้งเวลา" />
              </RadioGroup>

              {publishMode === 'scheduled' && (
                <TextField
                  type="datetime-local"
                  fullWidth
                  size="small"
                  sx={{ mt: 1 }}
                  value={toDatetimeLocalString(scheduledAt)}
                  onChange={e => setScheduledAt(e.target.value ? new Date(e.target.value) : null)}
                  slotProps={{ inputLabel: { shrink: true } }}
                  label="วันและเวลาเผยแพร่"
                />
              )}

              <Stack spacing={1.5} sx={{ mt: 2 }}>
                <Button
                  variant="contained"
                  fullWidth
                  disabled={saving}
                  onClick={() => handleSave('publish')}
                  sx={{
                    bgcolor: '#FF9F6B',
                    '&:hover': { bgcolor: '#E07A42' },
                    fontWeight: 'bold',
                  }}
                >
                  {saving ? 'กำลังบันทึก...' : publishButtonLabel}
                </Button>
                <Button
                  variant="outlined"
                  fullWidth
                  disabled={saving}
                  onClick={() => handleSave('draft')}
                >
                  บันทึกร่าง
                </Button>
              </Stack>
            </Paper>

            {/* Cover image */}
            <Paper elevation={1} sx={{ p: 2.5, borderRadius: 2 }}>
              <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
                รูปหน้าปก
              </Typography>
              {/* 16:9 preview */}
              <Box
                sx={{
                  width: '100%',
                  aspectRatio: '16/9',
                  borderRadius: 1,
                  overflow: 'hidden',
                  mb: 1.5,
                  background: 'linear-gradient(135deg, #FEF1D2 0%, #FBCFB8 100%)',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                }}
              >
                {coverUrl ? (
                  <Box
                    component="img"
                    src={coverUrl}
                    sx={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }}
                  />
                ) : (
                  <ArticleIcon sx={{ fontSize: 40, color: '#FF9F6B' }} />
                )}
              </Box>
              <Button
                variant="outlined"
                fullWidth
                onClick={() => coverInputRef.current?.click()}
              >
                อัปโหลดรูปหน้าปก
              </Button>
              <input
                ref={coverInputRef}
                type="file"
                accept="image/*"
                style={{ display: 'none' }}
                onChange={e => {
                  const file = e.target.files?.[0];
                  if (file) handleCoverFileChange(file);
                  e.target.value = '';
                }}
              />
            </Paper>
          </Stack>
        </Box>
      </Box>

      {/* Video dialog */}
      <Dialog open={videoDialogOpen} onClose={() => setVideoDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle fontWeight="bold">แทรกวิดีโอ</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="URL วิดีโอ (YouTube หรือ URL ตรง)"
            value={videoUrl}
            onChange={e => setVideoUrl(e.target.value)}
            sx={{ mt: 1 }}
            onKeyDown={e => { if (e.key === 'Enter') handleVideoConfirm(); }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => { setVideoUrl(''); setVideoDialogOpen(false); }}>ยกเลิก</Button>
          <Button variant="contained" onClick={handleVideoConfirm}
            sx={{ bgcolor: '#FF9F6B', '&:hover': { bgcolor: '#E07A42' } }}>
            แทรก
          </Button>
        </DialogActions>
      </Dialog>

      {/* Link dialog */}
      <Dialog open={linkDialogOpen} onClose={() => setLinkDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle fontWeight="bold">แทรกลิงก์</DialogTitle>
        <DialogContent>
          <TextField
            autoFocus
            fullWidth
            label="URL"
            placeholder="https://"
            value={linkUrl}
            onChange={e => setLinkUrl(e.target.value)}
            sx={{ mt: 1 }}
            onKeyDown={e => { if (e.key === 'Enter') handleLinkConfirm(); }}
          />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => { setLinkUrl(''); setLinkDialogOpen(false); }}>ยกเลิก</Button>
          <Button variant="contained" onClick={handleLinkConfirm}
            sx={{ bgcolor: '#FF9F6B', '&:hover': { bgcolor: '#E07A42' } }}>
            แทรก
          </Button>
        </DialogActions>
      </Dialog>

      {/* Delete dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => !deleting && setDeleteDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle fontWeight="bold">ยืนยันการลบบทความ</DialogTitle>
        <DialogContent>
          <DialogContentText>
            คุณต้องการลบบทความ <strong>"{title || 'ไม่มีหัวเรื่อง'}"</strong> ใช่หรือไม่?
            การกระทำนี้ไม่สามารถย้อนกลับได้
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => setDeleteDialogOpen(false)} disabled={deleting}>ยกเลิก</Button>
          <Button variant="contained" color="error" onClick={handleDelete} disabled={deleting}>
            {deleting ? 'กำลังลบ...' : 'ลบบทความ'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={4000}
        onClose={() => setSnackbar(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert
          severity={snackbar.severity}
          variant="filled"
          onClose={() => setSnackbar(s => ({ ...s, open: false }))}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
