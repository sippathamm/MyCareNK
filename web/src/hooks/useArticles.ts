import { useState, useEffect, useCallback } from 'react';
import { supabase } from '../lib/supabase';

export interface Article {
  id: string;
  title: string;
  excerpt: string | null;
  cover_image_url: string | null;
  publish_at: string | null;
  created_by: string | null;
  created_at: string | null;
  updated_at: string | null;
}

export type ArticleStatus = 'draft' | 'scheduled' | 'published';

export function getArticleStatus(article: Pick<Article, 'publish_at'>): ArticleStatus {
  if (!article.publish_at) return 'draft';
  return new Date(article.publish_at) > new Date() ? 'scheduled' : 'published';
}

export function useArticles() {
  const [articles, setArticles] = useState<Article[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchArticles = useCallback(async () => {
    setLoading(true);
    setError(null);
    const { data, error } = await supabase
      .from('articles')
      .select('id, title, excerpt, cover_image_url, publish_at, created_by, created_at, updated_at')
      .order('updated_at', { ascending: false });

    if (error) {
      setError(error.message);
    } else {
      setArticles(data ?? []);
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

  return { articles, loading, error, refetch: fetchArticles, deleteArticle };
}
