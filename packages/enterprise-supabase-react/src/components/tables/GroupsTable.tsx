import {
  ColumnDef,
  PaginationState,
  createColumnHelper,
  flexRender,
  getCoreRowModel,
  useReactTable,
} from "@tanstack/react-table";
import { Group, Pagination } from "enterprise-supabase";
import { useMemo, useState } from "react";
import { useGroups } from "../../hooks/useGroups";
import { DataTablePagination } from "../ui/table-pagination";
import { DotsHorizontalIcon } from "@radix-ui/react-icons";
import { Row } from "@tanstack/react-table";
import { Button } from "../ui/button";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "../ui/dropdown-menu";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "../ui/table";

type DataTableRowActionsProps = {
  row: Row<Group>;
};

function DataTableRowActions({ row }: DataTableRowActionsProps) {
  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button
          variant="ghost"
          className="flex h-8 w-8 p-0 data-[state=open]:bg-muted"
        >
          <DotsHorizontalIcon className="h-4 w-4" />
          <span className="sr-only">Open menu</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end" className="w-[160px]">
        <DropdownMenuItem>Edit</DropdownMenuItem>
        <DropdownMenuSeparator />
        <DropdownMenuItem
          onClick={() => {
            console.log("delete", row.id);
          }}
        >
          Delete
        </DropdownMenuItem>
      </DropdownMenuContent>
    </DropdownMenu>
  );
}

export const groupTableColumnHelper = createColumnHelper<Group>();

export type UseGroupTableProps = {
  columns: ColumnDef<Group, string>[];
  order?: Pick<Pagination<Group>, "orderBy" | "direction">;
};

export const useGroupTable = ({ order, columns }: UseGroupTableProps) => {
  const [{ pageIndex, pageSize }, setPagination] = useState<PaginationState>({
    pageIndex: 0,
    pageSize: 20,
  });

  const pagination = useMemo(
    () => ({
      pageIndex,
      pageSize,
    }),
    [pageIndex, pageSize]
  );

  const { data } = useGroups({
    page: pageIndex,
    perPage: pageSize,
    ...order,
  });

  return useReactTable({
    data: data?.items || [],
    columns,
    pageCount: data?.totalPages || 1,
    state: {
      pagination,
    },
    onPaginationChange: (p) => {
      console.log(typeof p === "function" ? p(pagination) : { p });
      setPagination(p);
    },
    getCoreRowModel: getCoreRowModel(),
    manualPagination: true,
  });
};

export const GroupsTable = (): JSX.Element => {
  const columns: ColumnDef<Group, string>[] = useMemo(() => {
    const columns: ColumnDef<Group, string>[] = [
      groupTableColumnHelper.accessor("name", {
        header: "Name",
        cell: (group) => group.getValue(),
      }),
      groupTableColumnHelper.accessor("description", {
        header: "Description",
      }),
      groupTableColumnHelper.accessor("updated_at", {
        header: "Last updated",
      }),
      {
        id: "actions",
        cell: ({ row }) => <DataTableRowActions row={row} />,
      },
    ];
    return columns;
  }, []);

  const table = useGroupTable({
    columns,
    order: {
      orderBy: "updated_at",
      direction: "desc",
    },
  });

  return (
    <div className="rounded-md border">
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => {
                return (
                  <TableHead key={header.id}>
                    {header.isPlaceholder
                      ? null
                      : flexRender(
                          header.column.columnDef.header,
                          header.getContext()
                        )}
                  </TableHead>
                );
              })}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.length ? (
            table.getRowModel().rows.map((row) => (
              <TableRow
                key={row.id}
                data-state={row.getIsSelected() && "selected"}
              >
                {row.getVisibleCells().map((cell) => (
                  <TableCell key={cell.id}>
                    {flexRender(cell.column.columnDef.cell, cell.getContext())}
                  </TableCell>
                ))}
              </TableRow>
            ))
          ) : (
            <TableRow>
              <TableCell colSpan={columns.length} className="h-24 text-center">
                No results.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
      <DataTablePagination table={table} />
    </div>
  );
};
