import { useState, useEffect, useRef, useCallback } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  Box, Typography, Paper, Button, IconButton, Tooltip,
  Stack, TextField, Divider, Chip,
  Dialog, DialogTitle, DialogContent, DialogContentText, DialogActions,
  Snackbar, Alert, LinearProgress, CircularProgress,
} from '@mui/material';
import ArrowBackIcon from '@mui/icons-material/ArrowBack';
import CloseIcon from '@mui/icons-material/Close';
import DeleteOutlineIcon from '@mui/icons-material/DeleteOutline';
import ExitToAppIcon from '@mui/icons-material/ExitToApp';
import HistoryIcon from '@mui/icons-material/History';
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
  saveDraft as saveDraftHelper,
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
  const [isDirty, setIsDirty] = useState(false);
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
  const [exitDialogOpen, setExitDialogOpen] = useState(false);
  const [exitSaving, setExitSaving] = useState(false);
  const [recoveryDialogOpen, setRecoveryDialogOpen] = useState(false);
  const [recoveryTime, setRecoveryTime] = useState<string | null>(null);
  const [recoveryDismissing, setRecoveryDismissing] = useState(false);

  // ─── Refs ──────────────────────────────────────────────────────────────────

  const isInitialLoad = useRef(true);
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
      setIsDirty(true);
      setFieldErrors(prev => ({ ...prev, body: undefined }));
      // Reset retry counter on real edit so retries re-enable
      autoSaveRetryCount.current = 0;
      if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
      scheduleAutoSaveRef.current();
    },
  });

  // ─── Auto-save ─────────────────────────────────────────────────────────────

  const doAutoSave = useCallback(async () => {
    const currentEditor = editorRef.current;
    if (!articleId || !currentEditor || !articleStatusRef.current) return;

    setAutoSaveStatus('saving');
    const payload: ContentPayload = {
      title: titleRef.current,
      body: currentEditor.getHTML(),
      category: categoryRef.current,
      thumbnail_url: thumbnailUrlRef.current,
    };

    const err = await autoSaveArticle(articleId, payload, articleStatusRef.current);

    if (!err) {
      autoSaveRetryCount.current = 0;
      setAutoSaveStatus('saved');
      setAutoSavedAt(new Date());
      setIsDirty(false);
    } else if (autoSaveRetryCount.current < MAX_SILENT_RETRIES) {
      autoSaveRetryCount.current++;
      setAutoSaveStatus('failed');
      retryTimer.current = setTimeout(doAutoSave, RETRY_DELAY);
    } else {
      setAutoSaveStatus('offline');
    }
  }, [articleId]);

  const scheduleAutoSave = useCallback(() => {
    if (!articleId) return;
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);
    if (retryTimer.current) clearTimeout(retryTimer.current);
    autoSaveTimer.current = setTimeout(doAutoSave, DEBOUNCE_DELAY);
  }, [articleId, doAutoSave]);

  useEffect(() => { editorRef.current = editor; }, [editor]);
  scheduleAutoSaveRef.current = scheduleAutoSave;

  // Trigger auto-save when title or category changes (editor changes handled in onUpdate)
  useEffect(() => {
    if (isInitialLoad.current || !isEditMode) return;
    autoSaveRetryCount.current = 0;
    if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
    scheduleAutoSave();
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [title, category, scheduleAutoSave, isEditMode]);

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
    const formThumb = isDraft ? article.thumbnail_url : (article.draft_thumbnail_url ?? article.thumbnail_url);

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
      const article = await loadArticle();
      if (!article) return;

      const needsRecovery =
        !!article.autosave_saved_at &&
        !!article.updated_at &&
        new Date(article.autosave_saved_at) > new Date(article.updated_at);

      if (needsRecovery) {
        setRecoveryTime(formatTime(new Date(article.autosave_saved_at!)));
        setRecoveryDialogOpen(true);
        // isInitialLoad stays true until dialog is dismissed / confirmed
      } else {
        setTimeout(() => { isInitialLoad.current = false; }, 300);
      }
    })();
  // editor changes on mount only — no need to re-run on editor updates
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [isEditMode, editor]);

  // ─── Recovery handlers ─────────────────────────────────────────────────────

  function handleRecoveryConfirm() {
    setRecoveryDialogOpen(false);
    setTimeout(() => { isInitialLoad.current = false; }, 100);
  }

  async function handleRecoveryDismiss() {
    if (!articleId) return;
    setRecoveryDismissing(true);
    // For published/hidden: clear draft_* + autosave_saved_at; for draft: only autosave_saved_at
    const clearPayload =
      articleStatusRef.current === 'draft'
        ? { autosave_saved_at: null }
        : { draft_title: null, draft_body: null, draft_category: null, draft_thumbnail_url: null, autosave_saved_at: null };
    await supabase.from('articles').update(clearPayload).eq('id', articleId);
    // Re-fetch and reload live content
    isInitialLoad.current = true;
    await loadArticle();
    setRecoveryDialogOpen(false);
    setHasDraft(false);
    setRecoveryDismissing(false);
    setTimeout(() => { isInitialLoad.current = false; }, 300);
  }

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

  // ─── Scenario 1 / 2 — Save draft ──────────────────────────────────────────

  async function performSaveDraft(): Promise<boolean> {
    if (!editor) return false;
    if (autoSaveTimer.current) clearTimeout(autoSaveTimer.current);

    const payload = getPayload();

    if (!isEditMode) {
      // Scenario 1: create new article
      const allEmpty = !payload.title.trim() && editor.isEmpty && !payload.category.trim();
      if (allEmpty) {
        showSnackbar('กรุณาระบุข้อมูลอย่างน้อยหนึ่งรายการก่อนบันทึก', 'error');
        return false;
      }
      const result = await createArticle(payload, userId);
      if ('error' in result) {
        showSnackbar(`สร้างบทความไม่สำเร็จ: ${result.error}`, 'error');
        return false;
      }
      setIsDirty(false);
      navigate(`/articles/${result.id}/edit`, { replace: true });
      showSnackbar('สร้างบทความเรียบร้อยแล้ว', 'success');
      return true;
    }

    const status = articleStatusRef.current!;
    const err = await saveDraftHelper(articleId!, payload, status, userId);
    if (err) {
      showSnackbar(`บันทึกร่างไม่สำเร็จ: ${err}`, 'error');
      return false;
    }

    setIsDirty(false);
    setAutoSaveStatus('idle');
    if (status !== 'draft') setHasDraft(true);
    showSnackbar('บันทึกร่างเรียบร้อยแล้ว', 'success');
    return true;
  }

  // ─── Scenario 4A — Publish from draft ─────────────────────────────────────

  async function handlePublish() {
    if (!validateForPublish() || !articleId) return;
    setSaving(true);
    const err = await publishArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่ไม่สำเร็จ: ${err}`, 'error');
    } else {
      setIsDirty(false);
      setAutoSaveStatus('idle');
      setArticleStatus('published');
      showSnackbar('เผยแพร่บทความเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Scenario 4B — Republish ──────────────────────────────────────────────

  async function handleRepublish() {
    if (!validateForPublish() || !articleId) return;
    setSaving(true);
    const err = await republishArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่ไม่สำเร็จ: ${err}`, 'error');
    } else {
      setIsDirty(false);
      setAutoSaveStatus('idle');
      setHasDraft(false);
      showSnackbar('เผยแพร่บทความเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Scenario 5A — Hide ───────────────────────────────────────────────────

  async function handleHide() {
    if (!articleId) return;
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
    setSaving(true);
    const err = await restoreArticleHelper(articleId, getPayload(), userId);
    if (err) {
      showSnackbar(`เผยแพร่อีกครั้งไม่สำเร็จ: ${err}`, 'error');
    } else {
      setIsDirty(false);
      setAutoSaveStatus('idle');
      setArticleStatus('published');
      setHasDraft(false);
      showSnackbar('เผยแพร่บทความอีกครั้งเรียบร้อยแล้ว', 'success');
    }
    setSaving(false);
  }

  // ─── Navigation with dirty check ──────────────────────────────────────────

  function handleBackClick() {
    if (isDirty || autoSaveStatus !== 'idle') {
      setExitDialogOpen(true);
    } else {
      navigate('/articles');
    }
  }

  async function handleExitSaveDraft() {
    setExitSaving(true);
    await performSaveDraft();
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
        setIsDirty(true);
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
      setIsDirty(true);
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

    if (!isEditMode || articleStatus === null) {
      // New article or loading — only Save Draft available
      return (
        <Button variant="outlined" {...base} onClick={() => performSaveDraft()}>
          {saving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
        </Button>
      );
    }

    if (articleStatus === 'draft') {
      return (
        <Stack spacing={1.5}>
          <Button variant="contained" {...base} onClick={handlePublish}>
            {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่'}
          </Button>
          <Button variant="outlined" {...base} onClick={() => { setSaving(true); performSaveDraft().finally(() => setSaving(false)); }}>
            {saving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
          </Button>
        </Stack>
      );
    }

    if (articleStatus === 'published') {
      return (
        <Stack spacing={1.5}>
          {hasDraft ? (
            <Button variant="contained" {...base} onClick={handleRepublish}>
              {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่อีกครั้ง'}
            </Button>
          ) : null}
          <Button variant={hasDraft ? 'outlined' : 'contained'} {...base}
            onClick={() => { setSaving(true); performSaveDraft().finally(() => setSaving(false)); }}>
            {saving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
          </Button>
          <Button variant="outlined" color="error" {...base} onClick={() => setHideDialogOpen(true)}>
            ซ่อนบทความ
          </Button>
        </Stack>
      );
    }

    // hidden
    return (
      <Stack spacing={1.5}>
        <Button variant="contained" {...base} onClick={handleRestore}>
          {saving ? 'กำลังเผยแพร่...' : 'เผยแพร่อีกครั้ง'}
        </Button>
        <Button variant="outlined" {...base}
          onClick={() => { setSaving(true); performSaveDraft().finally(() => setSaving(false)); }}>
          {saving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
        </Button>
      </Stack>
    );
  }

  // ─── Auto-save indicator ───────────────────────────────────────────────────

  function renderAutoSaveIndicator() {
    if (!isEditMode || autoSaveStatus === 'idle') return null;
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
                  setIsDirty(true);
                  setFieldErrors(prev => ({ ...prev, title: undefined }));
                  autoSaveRetryCount.current = 0;
                  if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
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
              {isEditMode && articleStatus && (
                <Stack direction="row" spacing={1} alignItems="center" mb={1.5} flexWrap="wrap">
                  {statusChip()}
                  {hasDraft && articleStatus === 'published' && (
                    <Chip label="มีการแก้ไขที่ยังไม่ได้เผยแพร่" size="small" color="warning" variant="outlined" />
                  )}
                </Stack>
              )}

              {renderAutoSaveIndicator()}

              <Box sx={{ mt: isEditMode ? 1.5 : 0 }}>
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
                    setIsDirty(true);
                    setFieldErrors(prev => ({ ...prev, category: undefined }));
                    autoSaveRetryCount.current = 0;
                    if (autoSaveStatus === 'offline') setAutoSaveStatus('idle');
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

      {/* Exit dialog */}
      <Dialog open={exitDialogOpen} onClose={() => !exitSaving && setExitDialogOpen(false)} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
          <ExitToAppIcon color="warning" />
          <Typography component="div" variant="h6" fontWeight="bold">ออกจากบทความ</Typography>
        </DialogTitle>
        <Divider />
        <DialogContent sx={{ pt: 2.5 }}>
          <DialogContentText>มีการแก้ไขที่ยังไม่ได้บันทึก ต้องการบันทึกก่อนออกหรือไม่?</DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          <Button onClick={handleExitDiscard} disabled={exitSaving} color="error">ละทิ้ง</Button>
          <Box sx={{ flex: 1 }} />
          <Button onClick={() => setExitDialogOpen(false)} disabled={exitSaving} color="inherit">อยู่ต่อ</Button>
          <Button variant="contained" onClick={handleExitSaveDraft} disabled={exitSaving}
            endIcon={exitSaving ? <CircularProgress size={16} color="inherit" /> : null}>
            {exitSaving ? 'กำลังบันทึก...' : 'บันทึกร่าง'}
          </Button>
        </DialogActions>
      </Dialog>

      {/* Auto-save recovery dialog */}
      <Dialog open={recoveryDialogOpen} onClose={() => {}} maxWidth="xs" fullWidth>
        <DialogTitle sx={{ display: 'flex', alignItems: 'center', gap: 1.5, pb: 1 }}>
          <HistoryIcon color="primary" />
          <Typography component="div" variant="h6" fontWeight="bold">พบการบันทึกอัตโนมัติ</Typography>
        </DialogTitle>
        <Divider />
        <DialogContent sx={{ pt: 2.5 }}>
          <DialogContentText>
            มีข้อมูลที่บันทึกอัตโนมัติเมื่อ {recoveryTime} ต้องการนำข้อมูลนั้นกลับมาหรือไม่?
          </DialogContentText>
        </DialogContent>
        <DialogActions sx={{ px: 3, pb: 2.5, gap: 1 }}>
          <Button onClick={handleRecoveryDismiss} disabled={recoveryDismissing} color="error"
            endIcon={recoveryDismissing ? <CircularProgress size={16} color="inherit" /> : null}>
            {recoveryDismissing ? 'กำลังยกเลิก...' : 'ทิ้งการเปลี่ยนแปลง'}
          </Button>
          <Button variant="contained" onClick={handleRecoveryConfirm} disabled={recoveryDismissing}>
            นำกลับมา
          </Button>
        </DialogActions>
      </Dialog>

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
