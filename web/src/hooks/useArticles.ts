import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface Article {
  id: string;
  title: string;
  cover_image_url: string | null;
  publish_at: string | null;
  has_draft: boolean;
  is_visible: boolean;
  created_by: string | null;
  created_at: string | null;
  updated_at: string | null;
}

// Mirrors the article_status PostgreSQL enum in Supabase
export const ARTICLE_STATUS = {
  draft: 'draft',
  scheduled: 'scheduled',
  published: 'published',
  hidden: 'hidden',
} as const;

export type ArticleStatus = typeof ARTICLE_STATUS[keyof typeof ARTICLE_STATUS];

export function getArticleStatus(article: Pick<Article, 'publish_at' | 'is_visible'>): ArticleStatus {
  if (!article.publish_at) return ARTICLE_STATUS.draft;
  if (!article.is_visible) return ARTICLE_STATUS.hidden;
  return new Date(article.publish_at) > new Date() ? ARTICLE_STATUS.scheduled : ARTICLE_STATUS.published;
}

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
        .select('id, title, cover_image_url, publish_at, has_draft, is_visible, created_by, created_at, updated_at')
        .order('updated_at', { ascending: false }),
      supabase
        .from('staff_profiles')
        .select('staff_user_id, first_name, last_name'),
    ]);

    if (articlesRes.error) {
      setError(articlesRes.error.message);
    } else {
      setArticles(articlesRes.data ?? []);
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
