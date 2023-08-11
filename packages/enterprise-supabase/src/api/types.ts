export type Pagination<T> = {
  page?: number;
  perPage?: number;
  orderBy?: keyof T;
  direction?: "asc" | "desc";
};

export type PaginatedResponse<T> = {
  page: number;
  totalPages: number;
  items: T[];
};
