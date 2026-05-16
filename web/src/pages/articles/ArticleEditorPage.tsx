import { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box, Typography, Paper, Button, IconButton, Tooltip,
  Stack, TextField, Divider, RadioGroup, FormControlLabel, Radio,
  Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions,
  Snackbar, Alert, LinearProgress, CircularProgress,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
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

type AutoSaveStatus = 'idle' | 'saving' | 'saved';

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

  const [isDirty, setIsDirty] = useState(false);
  const [autoSaveStatus, setAutoSaveStatus] = useState<AutoSaveStatus>('idle');
  const [uploadingCover, setUploadingCover] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);

  // ─── Dialog state ──────────────────────────────────────────────────────────

  const [videoDialogOpen, setVideoDialogOpen] = useState(false);
  const [videoUrl, setVideoUrl] = useState('');
  const [linkDialogOpen, setLinkDialogOpen] = useState(false);
  const [linkUrl, setLinkUrl] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [exitDialogOpen, setExitDialogOpen] = useState(false);
  const [exitSaving, setExitSaving] = useState(false);

  // ─── Refs ──────────────────────────────────────────────────────────────────

  const autoSaveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const autoSaveStatusTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const isInitialLoad = useRef(true);
  const imageInputRef = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  // Kept in sync with latest state so auto-save timer never reads stale values
  const editorRef = useRef<ReturnType<typeof useEditor>>(null);
  const scheduleAutoSaveRef = useRef<() => void>(() => {});
  const titleRef = useRef(title);
  const coverUrlRef = useRef(coverUrl);
  titleRef.current = title;
  coverUrlRef.current = coverUrl;

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
      if (isInitialLoad.current) return;
      setIsDirty(true);
      scheduleAutoSaveRef.current();
    },
  });

  // ─── Load existing article ─────────────────────────────────────────────────

  useEffect(() => {
    if (!isEditMode) {
      setTimeout(() => { isInitialLoad.current = false; }, 100);
      return;
    }
    if (!editor) return;
    supabase
      .from('articles')
      .select('*')
      .eq('id', articleId!)
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
  }, [articleId, isEditMode, editor]);

  // ─── Auto-save logic ───────────────────────────────────────────────────────

  // Stable callback: deps are only articleId (never changes after mount).
  // All mutable values (editor, title, coverUrl) are read from refs at timer-fire
  // time, so the closure is never stale.
  const scheduleAutoSave = useCallback(() => {
    if (!articleId) return;
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    autoSaveTimer.current = setTimeout(async () => {
      const currentEditor = editorRef.current;
      if (!currentEditor) return;
      setAutoSaveStatus('saving');
      const excerpt = currentEditor.getText().slice(0, 150) || null;
      const { error } = await supabase.from('articles').update({
        title: titleRef.current.trim() || 'ไม่มีหัวเรื่อง',
        content_html: currentEditor.getHTML(),
        content_json: currentEditor.getJSON(),
        excerpt,
        cover_image_url: coverUrlRef.current || null,
      }).eq('id', articleId);
      if (!error) {
        setIsDirty(false);
        setAutoSaveStatus('saved');
        if (autoSaveStatusTimer.current) clearTimeout(autoSaveStatusTimer.current);
        autoSaveStatusTimer.current = setTimeout(() => setAutoSaveStatus('idle'), 3000);
      } else {
        setAutoSaveStatus('idle');
      }
    }, 2000);
  }, [articleId]);

  // Keep refs pointing at latest instances
  useEffect(() => { editorRef.current = editor; }, [editor]);
  scheduleAutoSaveRef.current = scheduleAutoSave;

  useEffect(() => {
    if (isInitialLoad.current || !isEditMode) return;
    scheduleAutoSave();
  }, [title, scheduleAutoSave, isEditMode]);

  useEffect(() => {
    return () => {
      if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
      if (autoSaveStatusTimer.current) clearTimeout(autoSaveStatusTimer.current);
    };
  }, []);

  // ─── Helpers ───────────────────────────────────────────────────────────────

  function showSnackbar(message: string, severity: 'success' | 'error') {
    setSnackbar({ open: true, message, severity });
  }

  function getFileExtension(filename: string) {
    return filename.split('.').pop() ?? 'jpg';
  }

  // ─── Navigation with dirty check ──────────────────────────────────────────

  function handleBackClick() {
    if (isDirty) {
      setExitDialogOpen(true);
    } else {
      navigate('/articles');
    }
  }

  async function handleExitSaveDraft() {
    setExitSaving(true);
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    await handleSave('draft');
    setExitSaving(false);
    navigate('/articles');
  }

  function handleExitDiscard() {
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    navigate('/articles');
  }

  // ─── Image upload ──────────────────────────────────────────────────────────

  async function handleImageFileChange(file: File) {
    setUploadingImage(true);
    try {
      const ext = getFileExtension(file.name);
      const path = `content/${crypto.randomUUID()}.${ext}`;
      const { error } = await supabase.storage.from('article-assets').upload(path, file, {
        cacheControl: '3600',
        upsert: false,
      });
      if (error) { showSnackbar(`อัปโหลดรูปไม่สำเร็จ: ${error.message}`, 'error'); return; }
      const { data: { publicUrl } } = supabase.storage.from('article-assets').getPublicUrl(path);
      editor?.chain().focus().setImage({ src: publicUrl }).run();
    } catch (e) {
      showSnackbar(`อัปโหลดรูปไม่สำเร็จ: ${e instanceof Error ? e.message : 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ'}`, 'error');
    } finally {
      setUploadingImage(false);
    }
  }

  async function handleCoverFileChange(file: File) {
    setUploadingCover(true);
    try {
      const ext = getFileExtension(file.name);
      const path = `cover/${crypto.randomUUID()}.${ext}`;
      const { error } = await supabase.storage.from('article-assets').upload(path, file, {
        cacheControl: '3600',
        upsert: false,
      });
      if (error) { showSnackbar(`อัปโหลดรูปหน้าปกไม่สำเร็จ: ${error.message}`, 'error'); return; }
      const { data: { publicUrl } } = supabase.storage.from('article-assets').getPublicUrl(path);
      setCoverUrl(publicUrl);
      if (!isInitialLoad.current) setIsDirty(true);
    } catch (e) {
      showSnackbar(`อัปโหลดรูปหน้าปกไม่สำเร็จ: ${e instanceof Error ? e.message : 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ'}`, 'error');
    } finally {
      setUploadingCover(false);
    }
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
        setIsDirty(false);
        setAutoSaveStatus('idle');
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
        setIsDirty(false);
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
      <Box display="flex" alignItems="center" mb={3}>
        <IconButton onClick={handleBackClick}>
          <ArrowBackIcon />
        </IconButton>
        <Typography variant="subtitle1" fontWeight={600} color="text.secondary">
          {isEditMode ? 'แก้ไขบทความ' : 'สร้างบทความใหม่'}
        </Typography>
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
            onChange={e => {
              setTitle(e.target.value);
              if (!isInitialLoad.current) setIsDirty(true);
            }}
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
              <span>
                <IconButton
                  size="small"
                  onClick={() => imageInputRef.current?.click()}
                  disabled={uploadingImage}
                >
                  {uploadingImage
                    ? <CircularProgress size={16} />
                    : <ImageIcon fontSize="small" />}
                </IconButton>
              </span>
            </Tooltip>
            <input
              ref={imageInputRef}
              type="file"
              accept="image/jpeg,image/png,image/webp,image/gif,image/heic,image/heif,image/avif,image/bmp,image/tiff,image/svg+xml"
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

          {/* Uploading image indicator */}
          {uploadingImage && (
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, mb: 1 }}>
              <CircularProgress size={12} />
              <Typography variant="caption" color="text.secondary">กำลังอัปโหลดรูปภาพ...</Typography>
            </Box>
          )}

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

              {/* Auto-save status */}
              {isEditMode && autoSaveStatus !== 'idle' && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mt: 1.5 }}>
                  {autoSaveStatus === 'saving' ? (
                    <>
                      <CircularProgress size={12} />
                      <Typography variant="caption" color="text.secondary">กำลังบันทึกอัตโนมัติ...</Typography>
                    </>
                  ) : (
                    <>
                      <CheckCircleOutlineIcon sx={{ fontSize: 14, color: 'success.main' }} />
                      <Typography variant="caption" color="success.main">บันทึกอัตโนมัติแล้ว</Typography>
                    </>
                  )}
                </Box>
              )}

              <Stack spacing={1.5} sx={{ mt: 2 }}>
                <Button
                  variant="contained"
                  fullWidth
                  disabled={saving}
                  onClick={() => handleSave('publish')}
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
                disabled={uploadingCover}
                onClick={() => coverInputRef.current?.click()}
              >
                {uploadingCover ? 'กำลังอัปโหลด...' : 'อัปโหลดรูปหน้าปก'}
              </Button>
              {uploadingCover && (
                <LinearProgress sx={{ mt: 1, borderRadius: 1 }} />
              )}
              <input
                ref={coverInputRef}
                type="file"
                accept="image/jpeg,image/png,image/webp,image/gif,image/heic,image/heif,image/avif,image/bmp,image/tiff"
                style={{ display: 'none' }}
                onChange={e => {
                  const file = e.target.files?.[0];
                  if (file) handleCoverFileChange(file);
                  e.target.value = '';
                }}
              />
            </Paper>

            {/* Delete article */}
            {isEditMode && (
              <Button
                variant="contained"
                color="error"
                fullWidth
                startIcon={<DeleteOutlineIcon />}
                onClick={() => setDeleteDialogOpen(true)}
              >
                ลบบทความ
              </Button>
            )}
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
          <Button variant="contained" onClick={handleVideoConfirm}>แทรก</Button>
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
          <Button variant="contained" onClick={handleLinkConfirm}>แทรก</Button>
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

      {/* Exit dialog */}
      <Dialog open={exitDialogOpen} onClose={() => !exitSaving && setExitDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle fontWeight="bold">ออกจากบทความ</DialogTitle>
        <DialogContent>
          <DialogContentText>
            มีการแก้ไขที่ยังไม่ได้บันทึก ต้องการบันทึกร่างก่อนออกหรือไม่?
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={handleExitDiscard} disabled={exitSaving} color="error">
            ละทิ้ง
          </Button>
          <Box sx={{ flex: 1 }} />
          <Button onClick={() => setExitDialogOpen(false)} disabled={exitSaving}>
            อยู่ต่อ
          </Button>
          <Button variant="contained" onClick={handleExitSaveDraft} disabled={exitSaving}>
            {exitSaving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
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
