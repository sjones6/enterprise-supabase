import {
  PostgrestSingleResponse,
  PostgrestResponse,
} from "@supabase/supabase-js";
import { Pagination, PaginatedResponse } from "./types";

export const unwrapPostgrestSingleReponse = <T>(
  res: PostgrestSingleResponse<T>
  // eslint-disable-next-line @typescript-eslint/no-non-null-assertion
): T => res.data!;

type Range = {
  from: number;
  to: number;
  page: number;
  perPage: number;
};

export const calculatePagination = <T = Record<string, never>>(
  pagination: Pagination<T> = {}
): Range => {
  const page = Math.max(pagination.page || 0, 0);
  const perPage = Math.max(pagination.perPage || 20, 1);
  return {
    from: perPage * page,
    to: perPage * (page + 1),
    page,
    perPage,
  };
};

export const paginateResponse = <T>(
  res: PostgrestResponse<T>,
  pagination: Pagination<T> = {}
): PaginatedResponse<T> => {
  const { page, perPage } = calculatePagination(pagination);
  const count = res.count ?? 0;

  return {
    totalPages: Math.ceil(count / perPage),
    items: res.data || [],
    page,
  };
};
