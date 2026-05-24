-- Fix get_inventory_forecast to enumerate from service_centers instead of
-- service_center_inventory, so centers without an inventory row still appear.
CREATE OR REPLACE FUNCTION public.get_inventory_forecast()
 RETURNS TABLE(service_center text, is_active boolean, condom_qty integer, lubricant_qty integer, condom_daily_burn numeric, lubricant_daily_burn numeric, condom_days_left numeric, lubricant_days_left numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  WITH burn AS (
    SELECT il.service_center,
      GREATEST(SUM(-il.condom_delta), 0)::numeric    / 30.0 AS condom_daily_burn,
      GREATEST(SUM(-il.lubricant_delta), 0)::numeric / 30.0 AS lubricant_daily_burn
    FROM inventory_logs il
    WHERE il.action = 'fulfillment' AND il.created_at >= NOW() - INTERVAL '30 days'
    GROUP BY il.service_center
  )
  SELECT sc.name                                    AS service_center,
    sc.is_active,
    COALESCE(sci.condom_qty, 0)                     AS condom_qty,
    COALESCE(sci.lubricant_qty, 0)                  AS lubricant_qty,
    COALESCE(b.condom_daily_burn, 0)                AS condom_daily_burn,
    COALESCE(b.lubricant_daily_burn, 0)             AS lubricant_daily_burn,
    CASE WHEN COALESCE(b.condom_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(COALESCE(sci.condom_qty, 0)::numeric / b.condom_daily_burn, 1) END AS condom_days_left,
    CASE WHEN COALESCE(b.lubricant_daily_burn, 0) = 0 THEN NULL
         ELSE ROUND(COALESCE(sci.lubricant_qty, 0)::numeric / b.lubricant_daily_burn, 1) END AS lubricant_days_left
  FROM service_centers sc
  LEFT JOIN service_center_inventory sci ON sci.service_center = sc.name
  LEFT JOIN burn b ON b.service_center = sc.name
  ORDER BY sc.display_order, sc.name;
END;
$function$;
