import { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box, Typography, Paper, Button, IconButton, Tooltip,
  Stack, TextField, Divider, Chip,
  Dialog, DialogTitle, DialogContent, DialogActions,
  Snackbar, Alert, LinearProgress, CircularProgress,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import VisibilityOffOutlinedIcon from '@mui/icons-material/VisibilityOffOutlined';
import CheckCircleOutlineIcon from '@mui/icons-material/CheckCircleOutline';
import ConfirmDialog from '../../components/shared/ConfirmDialog';
import ErrorOutlineIcon from '@mui/icons-material/ErrorOutline';
import FormatBoldIcon from '@mui/icons-material/FormatBold';
import FormatAlignLeftIcon from '@mui/icons-material/FormatAlignLeft';
import FormatAlignCenterIcon from '@mui/icons-material/FormatAlignCenter';
import FormatAlignRightIcon from '@mui/icons-material/FormatAlignRight';
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
import { BubbleMenu } from '@tiptap/react/menus';
import { mergeAttributes } from '@tiptap/core';
import StarterKit from '@tiptap/starter-kit';
import Image from '@tiptap/extension-image';
import Link from '@tiptap/extension-link';
import Youtube from '@tiptap/extension-youtube';
import Placeholder from '@tiptap/extension-placeholder';
import CharacterCount from '@tiptap/extension-character-count';
import { supabase } from '../../lib/supabase';
import { useAuth } from '../../hooks/useAuth';
import {
  type ArticleStatus, type ArticleDetail, type ContentPayload,
  fetchArticleDetail, createArticle,
  publishArticle as publishArticleHelper,
  republishArticle as republishArticleHelper,
  hideArticle as hideArticleHelper,
  restoreArticle as restoreArticleHelper,
  autoSaveArticle,
} from '../../hooks/useArticles';

// ─── Auto-save constants ──────────────────────────────────────────────────────

const DEBOUNCE_DELAY = 2000;
const RETRY_DELAY = 5000;
const MAX_SILENT_RETRIES = 1;

// ─── Custom image extension (size + alignment) ────────────────────────────────

type ImageAlign = 'left' | 'center' | 'right';

const CustomImage = Image.extend({
  addAttributes() {
    return {
      ...this.parent?.(),
      imgWidth: {
        default: '100%',
        parseHTML: (el) => (el as HTMLImageElement).style.width || '100%',
        renderHTML: () => ({}),
      },
      imgAlign: {
        default: 'left' as ImageAlign,
        parseHTML: (el) => (el.getAttribute('data-align') as ImageAlign) || 'left',
        renderHTML: () => ({}),
      },
    };
  },

  renderHTML({ HTMLAttributes, node }) {
    const width = (node.attrs.imgWidth as string) ?? '100%';
    const align = (node.attrs.imgAlign as ImageAlign) ?? 'left';
    const ml = align === 'left' ? '0' : 'auto';
    const mr = align === 'right' ? '0' : 'auto';
    // eslint-disable-next-line @typescript-eslint/no-unused-vars
    const { style: _s, ...rest } = HTMLAttributes as Record<string, unknown>;
    return ['img', mergeAttributes(rest as Record<string, unknown>, {
      style: `width:${width};display:block;margin-left:${ml};margin-right:${mr}`,
      'data-align': align,
    })];
  },
});

const IMAGE_SIZES = [
  { width: '25%',  label: 'S',  tooltip: 'เล็ก' },
  { width: '50%',  label: 'M',  tooltip: 'ปานกลาง' },
  { width: '75%',  label: 'L',  tooltip: 'ใหญ่' },
  { width: '100%', label: 'XL', tooltip: 'ต้นฉบับ' },
] as const;

// ─── Types ────────────────────────────────────────────────────────────────────

interface SnackbarState {
  open: boolean;
  message: string;
  severity: 'success' | 'error';
}

type AutoSaveStatus = 'idle' | 'saving' | 'saved' | 'failed' | 'offline';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function getFileExtension(filename: string) {
  return filename.split('.').pop() ?? 'jpg';
}

function generateId(): string {
  return Array.from(crypto.getRandomValues(new Uint8Array(16)))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

function extractStoragePath(url: string): string | null {
  const marker = '/article-assets/';
  const idx = url.indexOf(marker);
  if (idx === -1) return null;
  return decodeURIComponent(url.slice(idx + marker.length).split('?')[0]);
}

function extractImageUrlsFromHtml(html: string): string[] {
  const urls: string[] = [];
  for (const m of html.matchAll(/<img[^>]+src="([^"]+)"/g)) {
    urls.push(m[1]);
  }
  return urls;
}

function formatTime(date: Date): string {
  return date.toLocaleTimeString('th-TH', { hour: '2-digit', minute: '2-digit', second: '2-digit' });
}

// ─── Component ────────────────────────────────────────────────────────────────

export default function ArticleEditorPage() {
  const navigate = useNavigate();
  const { id: articleId } = useParams<{ id: string }>();
  const isEditMode = !!articleId;
  const { session } = useAuth();
  const userId = session?.user?.id ?? '';

  // ─── Content state ─────────────────────────────────────────────────────────

  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('');
  const [thumbnailUrl, setThumbnailUrl] = useState<string | null>(null);

  // ─── Article status state ──────────────────────────────────────────────────

  const [articleStatus, setArticleStatus] = useState<ArticleStatus | null>(null);
  // hasDraft: draft_* columns are non-null on a published/hidden article
  const [hasDraft, setHasDraft] = useState(false);

  // ─── UI state ──────────────────────────────────────────────────────────────

  const [saving, setSaving] = useState(false);
  const [fieldErrors, setFieldErrors] = useState<{ title?: string; body?: string; category?: string }>({});
  const [autoSaveStatus, setAutoSaveStatus] = useState<AutoSaveStatus>('idle');
  const [autoSavedAt, setAutoSavedAt] = useState<Date | null>(null);
  const [uploadingCover, setUploadingCover] = useState(false);
  const [uploadingImage, setUploadingImage] = useState(false);
  const [snackbar, setSnackbar] = useState<SnackbarState>({ open: false, message: '', severity: 'success' });

  // ─── Dialog state ──────────────────────────────────────────────────────────

  const [videoDialogOpen, setVideoDialogOpen] = useState(false);
  const [videoUrl, setVideoUrl] = useState('');
  const [linkDialogOpen, setLinkDialogOpen] = useState(false);
  const [linkUrl, setLinkUrl] = useState('');
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [deleting, setDeleting] = useState(false);
  const [hideDialogOpen, setHideDialogOpen] = useState(false);

  // ─── Refs ──────────────────────────────────────────────────────────────────

  const isInitialLoad = useRef(true);
  const userIdRef = useRef(userId);
  userIdRef.current = userId;
  const navigateRef = useRef(navigate);
  navigateRef.current = navigate;
  const editorRef = useRef<ReturnType<typeof useEditor>>(null);
  const titleRef = useRef(title);
  const categoryRef = useRef(category);
  const thumbnailUrlRef = useRef(thumbnailUrl);
  const articleStatusRef = useRef(articleStatus);
  const autoSaveTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const retryTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const autoSaveRetryCount = useRef(0);
  const scheduleAutoSaveRef = useRef<() => void>(() => {});
  const imageInputRef = useRef<HTMLInputElement>(null);
  const coverInputRef = useRef<HTMLInputElement>(null);

  // Keep refs in sync with latest state
  titleRef.current = title;
  categoryRef.current = category;
  thumbnailUrlRef.current = thumbnailUrl;
  articleStatusRef.current = articleStatus;

  // ─── Editor ────────────────────────────────────────────────────────────────

  const editor = useEditor({
    extensions: [
      StarterKit,
      CustomImage,
      Link.configure({ openOnClick: false }),
      Youtube.configure({ width: 640, height: 360, nocookie: true }),
      Placeholder.configure({ placeholder: 'เริ่มเขียนบทความ...' }),
      CharacterCount,
    ],
    content: '',
    onUpdate: () => {
      if (isInitialLoad.current) return;
      setFieldErrors(prev => ({ ...prev, body: undefined }));
      // Reset retry counter on real edit so retries re-enable
      autoSaveRetryCount.current = 0;
      if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
      scheduleAutoSaveRef.current();
    },
  });

  // ─── Auto-save ─────────────────────────────────────────────────────────────

  const doAutoSave = useCallback(async () => {
    autoSaveTimer.current = null; // clear ref so handleBackClick knows timer has fired
    const currentEditor = editorRef.current;
    if (!currentEditor) return;

    setAutoSaveStatus('saving');
    const payload: ContentPayload = {
      title: titleRef.current,
      body: currentEditor.getHTML(),
      category: categoryRef.current,
      thumbnail_url: thumbnailUrlRef.current,
    };

    // ── New article: create in DB ───────────────────────────────────────────
    if (!articleId) {
      const allEmpty = !payload.title.trim() && currentEditor.isEmpty && !payload.category.trim();
      if (allEmpty) { setAutoSaveStatus('idle'); return; }
      const result = await createArticle(payload, userIdRef.current);
      if ('error' in result) {
        if (autoSaveRetryCount.current < MAX_SILENT_RETRIES) {
          autoSaveRetryCount.current++;
          setAutoSaveStatus('failed');
          retryTimer.current = setTimeout(doAutoSave, RETRY_DELAY);
        } else {
          setAutoSaveStatus('offline');
        }
      } else {
        autoSaveRetryCount.current = 0;
        setAutoSaveStatus('saved');
        setAutoSavedAt(new Date());
        navigateRef.current(`/articles/${result.id}/edit`, { replace: true });
      }
      return;
    }

    // ── Existing article ────────────────────────────────────────────────────
    if (!articleStatusRef.current) return;
    const err = await autoSaveArticle(articleId, payload, articleStatusRef.current, userIdRef.current);
    if (!err) {
      autoSaveRetryCount.current = 0;
      setAutoSaveStatus('saved');
      setAutoSavedAt(new Date());
      if (articleStatusRef.current !== 'draft') setHasDraft(true);
    } else if (autoSaveRetryCount.current < MAX_SILENT_RETRIES) {
      autoSaveRetryCount.current++;
      setAutoSaveStatus('failed');
      retryTimer.current = setTimeout(doAutoSave, RETRY_DELAY);
    } else {
      setAutoSaveStatus('offline');
    }
  }, [articleId]);

  const scheduleAutoSave = useCallback(() => {
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    if (retryTimer.current) clearTimeout(retryTimer.current);
    autoSaveTimer.current = setTimeout(doAutoSave, DEBOUNCE_DELAY);
  }, [doAutoSave]);

  useEffect(() => { editorRef.current = editor; }, [editor]);
  scheduleAutoSaveRef.current = scheduleAutoSave;

  // Trigger auto-save when title or category changes (editor changes handled in onUpdate)
  useEffect(() => {
    if (isInitialLoad.current) return;
    autoSaveRetryCount.current = 0;
    if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
    scheduleAutoSave();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [title, category, scheduleAutoSave]);

  useEffect(() => {
    return () => {
      if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
      if (retryTimer.current) clearTimeout(retryTimer.current);
    };
  }, []);

  // ─── Load article ──────────────────────────────────────────────────────────

  const applyArticleToForm = useCallback((article: ArticleDetail) => {
    const hasDraftContent =
      article.draft_title !== null ||
      article.draft_body !== null ||
      article.draft_category !== null ||
      article.draft_thumbnail_url !== null;

    const isDraft = article.status === 'draft';
    const formTitle = isDraft ? article.title : (article.draft_title ?? article.title);
    const formBody  = isDraft ? article.body  : (article.draft_body  ?? article.body);
    const formCat   = isDraft ? article.category : (article.draft_category ?? article.category);
    // When a draft exists, use draft_thumbnail_url directly (even if null = "removed").
    // ?? would incorrectly fall back to the original when draft explicitly cleared the thumbnail.
    const formThumb = isDraft
      ? article.thumbnail_url
      : hasDraftContent
        ? article.draft_thumbnail_url
        : article.thumbnail_url;

    setTitle(formTitle);
    setCategory(formCat);
    setThumbnailUrl(formThumb);
    setArticleStatus(article.status as ArticleStatus);
    setHasDraft(hasDraftContent);
    editorRef.current?.commands.setContent(formBody, { emitUpdate: false });
  }, []);

  const loadArticle = useCallback(async () => {
    if (!articleId || !editorRef.current) return null;
    const article = await fetchArticleDetail(articleId);
    if (!article) return null;
    applyArticleToForm(article);
    return article;
  }, [articleId, applyArticleToForm]);

  useEffect(() => {
    if (!isEditMode) {
      setTimeout(() => { isInitialLoad.current = false; }, 100);
      return;
    }
    if (!editor) return;

    (async () => {
      await loadArticle();
      setTimeout(() => { isInitialLoad.current = false; }, 300);
    })();
  // editor changes on mount only — no need to re-run on editor updates
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEditMode, editor]);

  // ─── Validation ────────────────────────────────────────────────────────────

  function validateForPublish(): boolean {
    const currentEditor = editorRef.current;
    const errs: { title?: string; body?: string; category?: string } = {};
    if (!titleRef.current.trim()) errs.title = 'กรุณาระบุหัวเรื่อง';
    if (!categoryRef.current.trim()) errs.category = 'กรุณาระบุหมวดหมู่';
    if (!currentEditor || currentEditor.isEmpty) errs.body = 'กรุณาระบุเนื้อหาบทความ';
    setFieldErrors(errs);
    return Object.keys(errs).length === 0;
  }

  // ─── Snackbar ──────────────────────────────────────────────────────────────

  function showSnackbar(message: string, severity: 'success' | 'error') {
    setSnackbar({ open: true, message, severity });
  }

  // ─── Get current payload from refs ────────────────────────────────────────

  function getPayload(): ContentPayload {
    return {
      title: titleRef.current,
      body: editorRef.current?.getHTML() ?? '',
      category: categoryRef.current,
      thumbnail_url: thumbnailUrlRef.current,
    };
  }

  // ─── Scenario 4A — Publish from draft ─────────────────────────────────────

  function cancelPendingAutoSave() {
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    if (retryTimer.current) clearTimeout(retryTimer.current);
    autoSaveTimer.current = null;
  }

  async function handlePublish() {
    if (!validateForPublish() || !articleId) return;
    cancelPendingAutoSave();
    setSaving(true);
    const err = await publishArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่ไม่สำเร็จ: ${err}`, 'error');
    } else {
      setAutoSaveStatus('idle');
      setArticleStatus('published');
      showSnackbar('เผยแพร่บทความเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Scenario 4B — Republish ──────────────────────────────────────────────

  async function handleRepublish() {
    if (!validateForPublish() || !articleId) return;
    cancelPendingAutoSave();
    setSaving(true);
    const err = await republishArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่ไม่สำเร็จ: ${err}`, 'error');
    } else {
      setAutoSaveStatus('idle');
      setHasDraft(false);
      showSnackbar('เผยแพร่บทความเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Scenario 5A — Hide ───────────────────────────────────────────────────

  async function handleHide() {
    if (!articleId) return;
    cancelPendingAutoSave();
    setSaving(true);
    const err = await hideArticleHelper(articleId, userId);
    if (err) {
      showSnackbar(`ซ่อนบทความไม่สำเร็จ: ${err}`, 'error');
    } else {
      setArticleStatus('hidden');
      showSnackbar('ซ่อนบทความเรียบร้อยแล้ว', 'success');
    }
    setHideDialogOpen(false);
    setSaving(false);
  }

  // ─── Scenario 5B — Restore ────────────────────────────────────────────────

  async function handleRestore() {
    if (!validateForPublish() || !articleId) return;
    cancelPendingAutoSave();
    setSaving(true);
    const err = await restoreArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่อีกครั้งไม่สำเร็จ: ${err}`, 'error');
    } else {
      setAutoSaveStatus('idle');
      setArticleStatus('published');
      setHasDraft(false);
      showSnackbar('เผยแพร่บทความอีกครั้งเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Navigation — silent save if timer pending ────────────────────────────

  async function handleBackClick() {
    cancelPendingAutoSave();

    const payload = getPayload();
    const isDraftContext = !isEditMode || articleStatusRef.current === 'draft';
    if (isDraftContext && !payload.title.trim()) payload.title = 'ไม่มีหัวเรื่อง';

    if (!isEditMode) {
      const allEmpty = !payload.title.trim() && (!editorRef.current || editorRef.current.isEmpty) && !payload.category.trim();
      if (!allEmpty) await createArticle(payload, userId);
    } else if (articleStatusRef.current) {
      await autoSaveArticle(articleId!, payload, articleStatusRef.current, userId);
    }

    navigate('/articles');
  }

  // ─── Image upload ──────────────────────────────────────────────────────────

  async function handleImageFileChange(file: File) {
    setUploadingImage(true);
    try {
      const path = `content/${generateId()}.${getFileExtension(file.name)}`;
      const { error } = await supabase.storage.from('article-assets').upload(path, file, { cacheControl: '3600', upsert: false });
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
      const path = `cover/${generateId()}.${getFileExtension(file.name)}`;
      const { error } = await supabase.storage.from('article-assets').upload(path, file, { cacheControl: '3600', upsert: false });
      if (error) { showSnackbar(`อัปโหลดรูปหน้าปกไม่สำเร็จ: ${error.message}`, 'error'); return; }
      const { data: { publicUrl } } = supabase.storage.from('article-assets').getPublicUrl(path);
      setThumbnailUrl(publicUrl);
      if (!isInitialLoad.current) {
        autoSaveRetryCount.current = 0;
        scheduleAutoSave();
      }
    } catch (e) {
      showSnackbar(`อัปโหลดรูปหน้าปกไม่สำเร็จ: ${e instanceof Error ? e.message : 'ข้อผิดพลาดที่ไม่ทราบสาเหตุ'}`, 'error');
    } finally {
      setUploadingCover(false);
    }
  }

  async function handleRemoveCover() {
    if (!thumbnailUrl) return;
    const path = extractStoragePath(thumbnailUrl);
    if (path) await supabase.storage.from('article-assets').remove([path]);
    setThumbnailUrl(null);
    if (!isInitialLoad.current) {
      autoSaveRetryCount.current = 0;
      scheduleAutoSave();
    }
  }

  // ─── Video insert ──────────────────────────────────────────────────────────

  function handleVideoConfirm() {
    if (!videoUrl.trim() || !editor) { setVideoDialogOpen(false); return; }
    if (/youtu\.be\/|youtube\.com\/watch/.test(videoUrl)) {
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

  // ─── Delete ────────────────────────────────────────────────────────────────

  async function handleDelete() {
    if (!articleId) return;
    setDeleting(true);

    const { data: saved } = await supabase
      .from('articles')
      .select('thumbnail_url, draft_thumbnail_url, body, draft_body')
      .eq('id', articleId)
      .single();

    const { error } = await supabase.from('articles').delete().eq('id', articleId);
    if (error) {
      setDeleting(false);
      setDeleteDialogOpen(false);
      showSnackbar(`ลบไม่สำเร็จ: ${error.message}`, 'error');
      return;
    }

    if (saved) {
      const paths: string[] = [];
      for (const url of [saved.thumbnail_url, saved.draft_thumbnail_url]) {
        if (url) { const p = extractStoragePath(url); if (p) paths.push(p); }
      }
      for (const html of [saved.body, saved.draft_body]) {
        if (html) extractImageUrlsFromHtml(html).forEach(url => { const p = extractStoragePath(url); if (p) paths.push(p); });
      }
      if (paths.length > 0) await supabase.storage.from('article-assets').remove(paths);
    }

    navigate('/articles', { replace: true });
  }

  // ─── Status chip label ─────────────────────────────────────────────────────

  function statusChip() {
    const map: Record<string, { label: string; color: 'warning' | 'success' | 'default' }> = {
      draft:     { label: 'ร่าง',         color: 'warning' },
      published: { label: 'เผยแพร่แล้ว',  color: 'success' },
      hidden:    { label: 'ซ่อน',          color: 'default' },
    };
    const cfg = articleStatus ? map[articleStatus] : null;
    if (!cfg) return null;
    return <Chip label={cfg.label} color={cfg.color} size="small" />;
  }

  // ─── Action buttons by scenario ────────────────────────────────────────────

  function renderActionButtons() {
    const base = { fullWidth: true, disabled: saving };

    if (!isEditMode) {
      return (
        <Button variant="contained" fullWidth disabled>เผยแพร่</Button>
      );
    }

    if (articleStatus === null) return null;

    if (articleStatus === 'draft') {
      return (
        <Button variant="contained" {...base} onClick={handlePublish}>
          {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่'}
        </Button>
      );
    }

    if (articleStatus === 'published') {
      return (
        <Stack spacing={1.5}>
          {hasDraft && (
            <Button variant="contained" {...base} onClick={handleRepublish}>
              {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่อีกครั้ง'}
            </Button>
          )}
          <Button variant="outlined" color="error" {...base} onClick={() => setHideDialogOpen(true)}>
            ซ่อนบทความ
          </Button>
        </Stack>
      );
    }

    // hidden
    return (
      <Button variant="contained" {...base} onClick={handleRestore}>
        {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่อีกครั้ง'}
      </Button>
    );
  }

  // ─── Auto-save indicator ───────────────────────────────────────────────────

  function renderAutoSaveIndicator() {
    if (autoSaveStatus === 'idle') return null;
    return (
      <Box sx={{ display: 'flex', alignItems: 'center', gap: 0.75, mt: 1.5, flexWrap: 'wrap' }}>
        {autoSaveStatus === 'saving' && (
          <><CircularProgress size={12} /><Typography variant="caption" color="text.secondary">กำลังบันทึกอัตโนมัติ...</Typography></>
        )}
        {autoSaveStatus === 'saved' && (
          <><CheckCircleOutlineIcon sx={{ fontSize: 14, color: 'success.main' }} />
          <Typography variant="caption" color="success.main">
            บันทึกอัตโนมัติเมื่อ {autoSavedAt ? formatTime(autoSavedAt) : ''}
          </Typography></>
        )}
        {autoSaveStatus === 'failed' && (
          <><ErrorOutlineIcon sx={{ fontSize: 14, color: 'warning.main' }} />
          <Typography variant="caption" color="warning.main">บันทึกอัตโนมัติไม่สำเร็จ กำลังลองใหม่...</Typography></>
        )}
        {autoSaveStatus === 'offline' && (
          <><ErrorOutlineIcon sx={{ fontSize: 14, color: 'error.main' }} />
          <Typography variant="caption" color="error.main">บันทึกอัตโนมัติไม่พร้อมใช้งาน กรุณาบันทึกด้วยตนเอง</Typography></>
        )}
      </Box>
    );
  }

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
        <Box sx={{ flex: 2, minWidth: 0, display: 'flex', flexDirection: 'column', gap: 2 }}>

          {/* Title card */}
          <Paper elevation={1} sx={{ p: 3, borderRadius: 2 }}>
            <TextField
              fullWidth
              placeholder="หัวเรื่อง"
              variant="standard"
              value={title}
              error={!!fieldErrors.title}
              helperText={fieldErrors.title}
              onChange={e => {
                setTitle(e.target.value);
                if (!isInitialLoad.current) {
                  setFieldErrors(prev => ({ ...prev, title: undefined }));
                  autoSaveRetryCount.current = 0;
                  if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
                  scheduleAutoSaveRef.current();
                }
              }}
              slotProps={{
                input: { disableUnderline: true },
                htmlInput: { style: { fontSize: 28, fontWeight: 700 } },
              }}
            />
          </Paper>

          {/* Content card */}
          <Paper elevation={1} sx={{ borderRadius: 2 }}>

            {/* Sticky toolbar */}
            <Box sx={{
              position: 'sticky', top: 64, zIndex: 10,
              bgcolor: 'background.paper', borderRadius: '8px 8px 0 0',
              borderBottom: '1px solid', borderColor: 'divider',
              px: 1.5, pt: 1, pb: 0.5,
            }}>
              <Stack direction="row" spacing={0.5} flexWrap="wrap">

                <Tooltip title="ตัวหนา">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleBold().run()}
                    sx={{ color: editor?.isActive('bold') ? 'primary.main' : 'inherit' }}>
                    <FormatBoldIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="ตัวเอียง">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleItalic().run()}
                    sx={{ color: editor?.isActive('italic') ? 'primary.main' : 'inherit' }}>
                    <FormatItalicIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="ขีดทับ">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleStrike().run()}
                    sx={{ color: editor?.isActive('strike') ? 'primary.main' : 'inherit' }}>
                    <StrikethroughSIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="หัวข้อ 1">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleHeading({ level: 1 }).run()}
                    sx={{ color: editor?.isActive('heading', { level: 1 }) ? 'primary.main' : 'inherit' }}>
                    <Typography variant="caption" fontWeight="bold" lineHeight={1}>H1</Typography>
                  </IconButton>
                </Tooltip>

                <Tooltip title="หัวข้อ 2">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleHeading({ level: 2 }).run()}
                    sx={{ color: editor?.isActive('heading', { level: 2 }) ? 'primary.main' : 'inherit' }}>
                    <Typography variant="caption" fontWeight="bold" lineHeight={1}>H2</Typography>
                  </IconButton>
                </Tooltip>

                <Tooltip title="หัวข้อ 3">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleHeading({ level: 3 }).run()}
                    sx={{ color: editor?.isActive('heading', { level: 3 }) ? 'primary.main' : 'inherit' }}>
                    <Typography variant="caption" fontWeight="bold" lineHeight={1}>H3</Typography>
                  </IconButton>
                </Tooltip>

                <Tooltip title="รายการหัวข้อ">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleBulletList().run()}
                    sx={{ color: editor?.isActive('bulletList') ? 'primary.main' : 'inherit' }}>
                    <FormatListBulletedIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="รายการลำดับ">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleOrderedList().run()}
                    sx={{ color: editor?.isActive('orderedList') ? 'primary.main' : 'inherit' }}>
                    <FormatListNumberedIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="คำพูดอ้างอิง">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleBlockquote().run()}
                    sx={{ color: editor?.isActive('blockquote') ? 'primary.main' : 'inherit' }}>
                    <FormatQuoteIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="โค้ด">
                  <IconButton size="small" onClick={() => editor?.chain().focus().toggleCodeBlock().run()}
                    sx={{ color: editor?.isActive('codeBlock') ? 'primary.main' : 'inherit' }}>
                    <CodeIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Divider orientation="vertical" flexItem />

                <Tooltip title="แทรกรูปภาพ">
                  <span>
                    <IconButton size="small" onClick={() => imageInputRef.current?.click()} disabled={uploadingImage}>
                      {uploadingImage ? <CircularProgress size={16} /> : <ImageIcon fontSize="small" />}
                    </IconButton>
                  </span>
                </Tooltip>
                <input ref={imageInputRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif"
                  style={{ display: 'none' }}
                  onChange={e => { const f = e.target.files?.[0]; if (f) handleImageFileChange(f); e.target.value = ''; }} />

                <Tooltip title="แทรกวิดีโอ">
                  <IconButton size="small" onClick={() => setVideoDialogOpen(true)}>
                    <VideoLibraryIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="แทรกลิงก์">
                  <IconButton size="small" onClick={() => setLinkDialogOpen(true)}
                    sx={{ color: editor?.isActive('link') ? 'primary.main' : 'inherit' }}>
                    <LinkIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Divider orientation="vertical" flexItem />

                <Tooltip title="เลิกทำ">
                  <IconButton size="small" onClick={() => editor?.chain().focus().undo().run()}>
                    <UndoIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

                <Tooltip title="ทำซ้ำ">
                  <IconButton size="small" onClick={() => editor?.chain().focus().redo().run()}>
                    <RedoIcon fontSize="small" />
                  </IconButton>
                </Tooltip>

              </Stack>
              {uploadingImage && (
                <Box sx={{ display: 'flex', alignItems: 'center', gap: 1, pt: 0.5 }}>
                  <CircularProgress size={12} />
                  <Typography variant="caption" color="text.secondary">กำลังอัปโหลดรูปภาพ...</Typography>
                </Box>
              )}
            </Box>

            {/* Body error */}
            {fieldErrors.body && (
              <Box sx={{ px: 2, pt: 1 }}>
                <Typography variant="caption" color="error">{fieldErrors.body}</Typography>
              </Box>
            )}

            {/* Editor content */}
            <Box sx={{
              p: 2, minHeight: 400,
              '& .ProseMirror': { outline: 'none', minHeight: 360 },
              '& .ProseMirror p.is-editor-empty:first-of-type::before': {
                content: 'attr(data-placeholder)', color: '#aaa', pointerEvents: 'none', float: 'left', height: 0,
              },
              '& .ProseMirror h1': { fontSize: '1.8rem', fontWeight: 700, mt: 2, mb: 1 },
              '& .ProseMirror h2': { fontSize: '1.4rem', fontWeight: 700, mt: 2, mb: 1 },
              '& .ProseMirror h3': { fontSize: '1.2rem', fontWeight: 600, mt: 1.5, mb: 0.5 },
              '& .ProseMirror ul, & .ProseMirror ol': { pl: 3 },
              '& .ProseMirror blockquote': { borderLeft: '3px solid #ccc', pl: 2, color: 'text.secondary' },
              '& .ProseMirror img': { maxWidth: '100%', borderRadius: 1 },
              '& .ProseMirror iframe': { maxWidth: '100%', width: '100%', aspectRatio: '16/9', border: 0 },
            }}>
              <EditorContent editor={editor} />
            </Box>
          </Paper>
        </Box>

        {/* ── Right sidebar ─────────────────────────────────────────── */}
        <Box sx={{ width: 300, flexShrink: 0 }}>
          <Stack spacing={2}>

            {/* Actions card */}
            <Paper elevation={1} sx={{ p: 2.5, borderRadius: 2 }}>
              {/* Status + unpublished badge */}
              {(!isEditMode || !!articleStatus) && (
                <Stack direction="row" spacing={1} alignItems="center" mb={1.5} flexWrap="wrap">
                  {isEditMode ? statusChip() : <Chip label="ร่าง" color="warning" size="small" />}
                  {hasDraft && articleStatus === 'published' && (
                    <Chip label="มีการแก้ไขที่ยังไม่ได้เผยแพร่" size="small" color="warning" variant="outlined" />
                  )}
                </Stack>
              )}

              {renderAutoSaveIndicator()}

              <Box sx={{ mt: 1.5 }}>
                {renderActionButtons()}
              </Box>
            </Paper>

            {/* Category card */}
            <Paper elevation={1} sx={{ p: 2.5, borderRadius: 2 }}>
              <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
                หมวดหมู่
              </Typography>
              <TextField
                fullWidth
                size="small"
                placeholder="เช่น สุขภาพ, ความปลอดภัย"
                value={category}
                error={!!fieldErrors.category}
                helperText={fieldErrors.category}
                onChange={e => {
                  setCategory(e.target.value);
                  if (!isInitialLoad.current) {
                    setFieldErrors(prev => ({ ...prev, category: undefined }));
                    autoSaveRetryCount.current = 0;
                    if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
                    scheduleAutoSaveRef.current();
                  }
                }}
              />
            </Paper>

            {/* Thumbnail card */}
            <Paper elevation={1} sx={{ p: 2.5, borderRadius: 2 }}>
              <Typography variant="subtitle2" fontWeight="bold" gutterBottom>
                รูปหน้าปก
              </Typography>
              <Box sx={{
                position: 'relative', width: '100%', aspectRatio: '16/9', borderRadius: 1, overflow: 'hidden', mb: 1.5,
                background: 'linear-gradient(135deg, #FEF1D2 0%, #FBCFB8 100%)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {thumbnailUrl
                  ? <Box component="img" src={thumbnailUrl} sx={{ width: '100%', height: '100%', objectFit: 'cover', display: 'block' }} />
                  : <ArticleIcon sx={{ fontSize: 40, color: '#FF9F6B' }} />}
                {thumbnailUrl && (
                  <Tooltip title="ลบรูปหน้าปก">
                    <IconButton
                      size="small"
                      onClick={handleRemoveCover}
                      sx={{
                        position: 'absolute', top: 4, right: 4,
                        bgcolor: 'rgba(0,0,0,0.45)', color: 'white',
                        '&:hover': { bgcolor: 'rgba(0,0,0,0.65)' },
                      }}
                    >
                      <CloseIcon sx={{ fontSize: 16 }} />
                    </IconButton>
                  </Tooltip>
                )}
              </Box>
              <Button variant="outlined" fullWidth disabled={uploadingCover} onClick={() => coverInputRef.current?.click()}>
                {uploadingCover ? 'กำลังอัปโหลด...' : 'อัปโหลดรูปหน้าปก'}
              </Button>
              {uploadingCover && <LinearProgress sx={{ mt: 1, borderRadius: 1 }} />}
              <Typography variant="caption" color="text.secondary" sx={{ display: 'block', mt: 1 }}>
                รองรับไฟล์ JPG, PNG, WEBP, GIF ขนาดไม่เกิน 5 MB
              </Typography>
              <input ref={coverInputRef} type="file" accept="image/jpeg,image/png,image/webp,image/gif"
                style={{ display: 'none' }}
                onChange={e => { const f = e.target.files?.[0]; if (f) handleCoverFileChange(f); e.target.value = ''; }} />
            </Paper>

            {/* Delete */}
            {isEditMode && (
              <Button variant="contained" color="error" fullWidth startIcon={<DeleteOutlineIcon />}
                onClick={() => setDeleteDialogOpen(true)}>
                ลบบทความ
              </Button>
            )}
          </Stack>
        </Box>
      </Box>

      {/* Image bubble menu */}
      {editor && (
        <BubbleMenu editor={editor} shouldShow={({ editor: e }) => e.isActive('image')}>
          <Paper elevation={4} sx={{ px: 0.5, py: 0.25, display: 'flex', alignItems: 'center', gap: 0.25, borderRadius: 1 }}>
            {IMAGE_SIZES.map(({ width, label, tooltip }) => (
              <Tooltip key={width} title={tooltip}>
                <IconButton size="small"
                  onClick={() => editor.chain().focus().updateAttributes('image', { imgWidth: width }).run()}
                  sx={{ fontSize: 11, fontWeight: 700, minWidth: 28, color: (editor.getAttributes('image').imgWidth ?? '100%') === width ? 'primary.main' : 'text.secondary' }}>
                  {label}
                </IconButton>
              </Tooltip>
            ))}
            <Divider orientation="vertical" flexItem />
            {([
              { align: 'left'   as const, icon: <FormatAlignLeftIcon fontSize="small" />,   tooltip: 'ซ้าย' },
              { align: 'center' as const, icon: <FormatAlignCenterIcon fontSize="small" />, tooltip: 'กลาง' },
              { align: 'right'  as const, icon: <FormatAlignRightIcon fontSize="small" />,  tooltip: 'ขวา' },
            ]).map(({ align, icon, tooltip }) => (
              <Tooltip key={align} title={tooltip}>
                <IconButton size="small"
                  onClick={() => editor.chain().focus().updateAttributes('image', { imgAlign: align }).run()}
                  sx={{ color: (editor.getAttributes('image').imgAlign ?? 'left') === align ? 'primary.main' : 'text.secondary' }}>
                  {icon}
                </IconButton>
              </Tooltip>
            ))}
          </Paper>
        </BubbleMenu>
      )}

      {/* Video dialog */}
      <Dialog open={videoDialogOpen} onClose={() => setVideoDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle fontWeight="bold">แทรกวิดีโอ</DialogTitle>
        <DialogContent>
          <TextField autoFocus fullWidth label="URL วิดีโอ (YouTube หรือ URL ตรง)" value={videoUrl}
            onChange={e => setVideoUrl(e.target.value)} sx={{ mt: 1 }}
            onKeyDown={e => { if (e.key === 'Enter') handleVideoConfirm(); }} />
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
          <TextField autoFocus fullWidth label="URL" placeholder="https://" value={linkUrl}
            onChange={e => setLinkUrl(e.target.value)} sx={{ mt: 1 }}
            onKeyDown={e => { if (e.key === 'Enter') handleLinkConfirm(); }} />
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2 }}>
          <Button onClick={() => { setLinkUrl(''); setLinkDialogOpen(false); }}>ยกเลิก</Button>
          <Button variant="contained" onClick={handleLinkConfirm}>แทรก</Button>
        </DialogActions>
      </Dialog>

      {/* Hide confirmation dialog */}
      <ConfirmDialog
        open={hideDialogOpen}
        icon={<VisibilityOffOutlinedIcon color="error" />}
        title="ยืนยันการซ่อนบทความ"
        body="บทความจะถูกซ่อนและผู้ใช้ทั่วไปจะไม่สามารถเข้าถึงได้ คุณสามารถเผยแพร่บทความอีกครั้งได้ในภายหลัง"
        confirmLabel="ซ่อนบทความ"
        confirmColor="error"
        loading={saving}
        onConfirm={handleHide}
        onCancel={() => setHideDialogOpen(false)}
      />

      {/* Delete dialog */}
      <ConfirmDialog
        open={deleteDialogOpen}
        icon={<DeleteOutlineIcon color="error" />}
        title="ยืนยันการลบบทความ"
        body={
          <Typography variant="body2" color="text.secondary">
            คุณต้องการลบบทความ <strong>"{title || 'ไม่มีหัวเรื่อง'}"</strong> ใช่หรือไม่?{' '}
            การกระทำนี้ไม่สามารถย้อนกลับได้
          </Typography>
        }
        confirmLabel="ลบบทความ"
        confirmColor="error"
        loading={deleting}
        onConfirm={handleDelete}
        onCancel={() => setDeleteDialogOpen(false)}
      />

      {/* Snackbar */}
      <Snackbar open={snackbar.open} autoHideDuration={4000}
        onClose={() => setSnackbar(s => ({ ...s, open: false }))}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}>
        <Alert severity={snackbar.severity} variant="filled"
          onClose={() => setSnackbar(s => ({ ...s, open: false }))}>
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
}
