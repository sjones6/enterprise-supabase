import {
  PostgrestMaybeSingleResponse,
  PostgrestSingleResponse,
} from "@supabase/supabase-js";

export const unwrapPostgrestSingleReponse = <T>(
  res: PostgrestMaybeSingleResponse<T> | PostgrestSingleResponse<T>
): T => res.data;
