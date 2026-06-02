import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export const ARTICLE_STATUS = {
  draft: 'draft',
  published: 'published',
  hidden: 'hidden',
} as const;

export type ArticleStatus = typeof ARTICLE_STATUS[keyof typeof ARTICLE_STATUS];

// Used by ArticlesPage (#200) — column names kept stable, do not rename.
export interface Article {
  id: string;
  title: string;
  cover_image_url: string | null;
  publish_at: string | null;
  has_draft: boolean;
  is_visible: boolean;
  status: ArticleStatus;
  created_by: string | null;
  created_at: string | null;
  updated_at: string | null;
}

// Full article row for the editor.
export interface ArticleDetail {
  id: string;
  title: string;
  body: string;
  category: string;
  thumbnail_url: string | null;
  status: ArticleStatus;
  draft_title: string | null;
  draft_body: string | null;
  draft_category: string | null;
  draft_thumbnail_url: string | null;
  created_by: string | null;
  created_at: string | null;
  updated_by: string | null;
  updated_at: string | null;
  published_by: string | null;
  published_at: string | null;
  hidden_by: string | null;
  hidden_at: string | null;
  autosave_saved_at: string | null;
}

export interface ContentPayload {
  title: string;
  body: string;
  category: string;
  thumbnail_url: string | null;
}

// ─── Article detail fetch ─────────────────────────────────────────────────────

export async function fetchArticleDetail(id: string): Promise<ArticleDetail | null> {
  const { data, error } = await supabase
    .from('articles')
    .select([
      'id', 'title', 'body', 'category', 'thumbnail_url', 'status',
      'draft_title', 'draft_body', 'draft_category', 'draft_thumbnail_url',
      'created_by', 'created_at', 'updated_by', 'updated_at',
      'published_by', 'published_at', 'hidden_by', 'hidden_at', 'autosave_saved_at',
    ].join(', '))
    .eq('id', id)
    .single();
  if (error || !data) return null;
  return data as unknown as ArticleDetail;
}

// ─── Scenario 1 — Create article ──────────────────────────────────────────────

export async function createArticle(
  payload: ContentPayload,
  userId: string,
): Promise<{ id: string } | { error: string }> {
  const { data, error } = await supabase
    .from('articles')
    .insert({
      title: payload.title,
      body: payload.body,
      category: payload.category,
      thumbnail_url: payload.thumbnail_url,
      status: 'draft',
      created_by: userId,
    })
    .select('id')
    .single();
  if (error) return { error: error.message };
  return { id: (data as { id: string }).id };
}

// ─── Scenario 2 & 3 — Save draft ─────────────────────────────────────────────
// Draft article   → writes to main columns (title/body/category/thumbnail_url)
// Published/hidden → writes to draft_* columns

export async function saveDraft(
  id: string,
  payload: ContentPayload,
  articleStatus: ArticleStatus,
  userId: string,
): Promise<string | null> {
  const now = new Date().toISOString();
  const base = { updated_by: userId, updated_at: now, autosave_saved_at: null };
  const update =
    articleStatus === 'draft'
      ? { title: payload.title, body: payload.body, category: payload.category, thumbnail_url: payload.thumbnail_url, ...base }
      : { draft_title: payload.title, draft_body: payload.body, draft_category: payload.category, draft_thumbnail_url: payload.thumbnail_url, ...base };
  const { error } = await supabase.from('articles').update(update).eq('id', id);
  return error ? error.message : null;
}

// ─── Scenario 4A — Publish from draft ────────────────────────────────────────

export async function publishArticle(
  id: string,
  payload: ContentPayload,
  userId: string,
): Promise<string | null> {
  const now = new Date().toISOString();
  const { error } = await supabase.from('articles').update({
    title: payload.title,
    body: payload.body,
    category: payload.category,
    thumbnail_url: payload.thumbnail_url,
    status: 'published',
    published_by: userId,
    published_at: now,
    updated_by: userId,
    updated_at: now,
    autosave_saved_at: null,
  }).eq('id', id);
  return error ? error.message : null;
}

// ─── Scenario 4B — Republish (promote draft_* to live) ───────────────────────

export async function republishArticle(
  id: string,
  resolvedPayload: ContentPayload,
  userId: string,
): Promise<string | null> {
  const now = new Date().toISOString();
  const { error } = await supabase.from('articles').update({
    title: resolvedPayload.title,
    body: resolvedPayload.body,
    category: resolvedPayload.category,
    thumbnail_url: resolvedPayload.thumbnail_url,
    draft_title: null,
    draft_body: null,
    draft_category: null,
    draft_thumbnail_url: null,
    status: 'published',
    published_by: userId,
    published_at: now,
    updated_by: userId,
    updated_at: now,
    autosave_saved_at: null,
  }).eq('id', id);
  return error ? error.message : null;
}

// ─── Scenario 5A — Hide ───────────────────────────────────────────────────────

export async function hideArticle(id: string, userId: string): Promise<string | null> {
  const now = new Date().toISOString();
  const { error } = await supabase.from('articles').update({
    status: 'hidden',
    hidden_by: userId,
    hidden_at: now,
    updated_by: userId,
    updated_at: now,
  }).eq('id', id);
  return error ? error.message : null;
}

// ─── Scenario 5B — Restore hidden → published ────────────────────────────────

export async function restoreArticle(
  id: string,
  resolvedPayload: ContentPayload,
  userId: string,
): Promise<string | null> {
  const now = new Date().toISOString();
  const { error } = await supabase.from('articles').update({
    title: resolvedPayload.title,
    body: resolvedPayload.body,
    category: resolvedPayload.category,
    thumbnail_url: resolvedPayload.thumbnail_url,
    draft_title: null,
    draft_body: null,
    draft_category: null,
    draft_thumbnail_url: null,
    status: 'published',
    published_by: userId,
    published_at: now,
    hidden_by: null,
    hidden_at: null,
    updated_by: userId,
    updated_at: now,
    autosave_saved_at: null,
  }).eq('id', id);
  return error ? error.message : null;
}

// ─── Scenario 6 — Auto-save ───────────────────────────────────────────────────
// Does NOT touch updated_by / updated_at — only autosave_saved_at.

export async function autoSaveArticle(
  id: string,
  payload: ContentPayload,
  articleStatus: ArticleStatus,
): Promise<string | null> {
  const now = new Date().toISOString();
  const update =
    articleStatus === 'draft'
      ? { title: payload.title, body: payload.body, category: payload.category, thumbnail_url: payload.thumbnail_url, autosave_saved_at: now }
      : { draft_title: payload.title, draft_body: payload.body, draft_category: payload.category, draft_thumbnail_url: payload.thumbnail_url, autosave_saved_at: now };
  const { error } = await supabase.from('articles').update(update).eq('id', id);
  return error ? error.message : null;
}

// ─── useArticles hook (ArticlesPage / #200 — column names kept stable) ────────

export function useArticles() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [staffMap, setStaffMap] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchArticles = useCallback(async () => {
    setLoading(true);
    setError(null);

    const [articlesRes, staffRes] = await Promise.all([
      supabase
        .from('articles')
        .select('id, title, cover_image_url, publish_at, has_draft, is_visible, status, created_by, created_at, updated_at')
        .order('updated_at', { ascending: false }),
      supabase
        .from('staff_profiles')
        .select('staff_user_id, first_name, last_name'),
    ]);

    if (articlesRes.error) {
      setError(articlesRes.error.message);
    } else {
      setArticles((articlesRes.data ?? []) as unknown as Article[]);
    }

    if (!staffRes.error && staffRes.data) {
      const map: Record<string, string> = {};
      for (const s of staffRes.data) {
        map[s.staff_user_id] = `${s.first_name ?? ''} ${s.last_name ?? ''}`.trim();
      }
      setStaffMap(map);
    }

    setLoading(false);
  }, []);

  useEffect(() => {
    // eslint-disable-next-line react-hooks/set-state-in-effect
    fetchArticles();
  }, [fetchArticles]);

  const deleteArticle = useCallback(async (id: string): Promise<string | null> => {
    const { error } = await supabase.from('articles').delete().eq('id', id);
    if (error) return error.message;
    setArticles(prev => prev.filter(a => a.id !== id));
    return null;
  }, []);

  return { articles, staffMap, loading, error, refetch: fetchArticles, deleteArticle };
}
