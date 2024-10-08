defmodule Electric.ShapeCache.Storage do
  alias Electric.Shapes.Querying
  alias Electric.LogItems
  alias Electric.Shapes.Shape
  alias Electric.Replication.LogOffset

  @type shape_id :: String.t()
  @type compiled_opts :: term()

  @typedoc """
  Prepared change that will be passed to the storage layer from the replication log.
  """
  @type log_header :: map()
  @type log_entry :: %{
          key: String.t(),
          value: map(),
          headers: log_header(),
          offset: LogOffset.t()
        }
  @type log :: Enumerable.t(log_entry())

  @type serialised_log_entry :: %{
          key: String.t(),
          value: map(),
          headers: log_header(),
          offset: String.t()
        }

  @type row :: list()

  @doc "Initialize shared options that will be passed to every other callback"
  @callback shared_opts(term()) :: {:ok, compiled_opts()} | {:error, term()}
  @doc "Start any processes required to run the storage backend"
  @callback start_link(compiled_opts()) :: GenServer.on_start()
  @callback initialise(storage()) :: :ok
  @callback list_shapes(storage()) :: [
              shape_id: shape_id(),
              shape: Shape.t(),
              latest_offset: LogOffset.t(),
              snapshot_xmin: non_neg_integer()
            ]
  @callback add_shape(shape_id(), Shape.t(), storage()) :: :ok
  @callback set_snapshot_xmin(shape_id(), non_neg_integer(), storage()) :: :ok
  @doc "Check if snapshot for a given shape id already exists"
  @callback snapshot_started?(shape_id(), compiled_opts()) :: boolean()
  @doc "Get the full snapshot for a given shape, also returning the offset this snapshot includes"
  @callback get_snapshot(shape_id(), compiled_opts()) :: {offset :: LogOffset.t(), log()}
  @doc """
  Make a new snapshot for a shape ID based on the meta information about the table and a stream of plain string rows

  Should raise an error if making the snapshot had failed for any reason.
  """
  @callback make_new_snapshot!(
              shape_id(),
              Querying.json_result_stream(),
              compiled_opts()
            ) :: :ok
  @callback mark_snapshot_as_started(shape_id, compiled_opts()) :: :ok
  @doc "Append log items from one transaction to the log"
  @callback append_to_log!(
              shape_id(),
              [LogItems.log_item()],
              compiled_opts()
            ) :: :ok
  @doc "Get stream of the log for a shape since a given offset"
  @callback get_log_stream(shape_id(), LogOffset.t(), LogOffset.t(), compiled_opts()) ::
              Enumerable.t()
  @doc "Check if log entries for given shape ID exist"
  @callback has_shape?(shape_id(), compiled_opts()) :: boolean()
  @doc "Store a relation containing information about the schema of a table"
  @callback store_relation(Relation.t(), compiled_opts()) :: :ok
  @doc "Get all stored relations"
  @callback get_relations(compiled_opts()) :: Enumerable.t(Relation.t())
  @doc "Clean up snapshots/logs for a shape id"
  @callback cleanup!(shape_id(), compiled_opts()) :: :ok

  @type storage() :: {module(), compiled_opts()}

  @spec initialise(storage()) :: :ok
  def initialise({mod, opts}),
    do: apply(mod, :initialise, [opts])

  @spec list_shapes(storage()) :: [
          shape_id: shape_id(),
          shape: Shape.t(),
          latest_offset: non_neg_integer(),
          snapshot_xmin: non_neg_integer()
        ]
  def list_shapes({mod, opts}), do: apply(mod, :list_shapes, [opts])

  @spec add_shape(shape_id(), Shape.t(), storage()) :: :ok
  def add_shape(shape_id, shape, {mod, opts}),
    do: apply(mod, :add_shape, [shape_id, shape, opts])

  @spec set_snapshot_xmin(shape_id(), non_neg_integer(), storage()) :: :ok
  def set_snapshot_xmin(shape_id, xmin, {mod, opts}),
    do: apply(mod, :set_snapshot_xmin, [shape_id, xmin, opts])

  @doc "Check if snapshot for a given shape id already exists"
  @spec snapshot_started?(shape_id(), storage()) :: boolean()
  def snapshot_started?(shape_id, {mod, opts}), do: mod.snapshot_started?(shape_id, opts)
  @doc "Get the full snapshot for a given shape, also returning the offset this snapshot includes"
  @spec get_snapshot(shape_id(), storage()) :: {offset :: LogOffset.t(), log()}
  def get_snapshot(shape_id, {mod, opts}), do: mod.get_snapshot(shape_id, opts)

  @doc """
  Make a new snapshot for a shape ID based on the meta information about the table and a stream of plain string rows
  """
  @spec make_new_snapshot!(shape_id(), Querying.json_result_stream(), storage()) :: :ok
  def make_new_snapshot!(shape_id, stream, {mod, opts}),
    do: mod.make_new_snapshot!(shape_id, stream, opts)

  @spec mark_snapshot_as_started(shape_id, compiled_opts()) :: :ok
  def mark_snapshot_as_started(shape_id, {mod, opts}),
    do: mod.mark_snapshot_as_started(shape_id, opts)

  @doc """
  Append log items from one transaction to the log
  """
  @spec append_to_log!(shape_id(), [LogItems.log_item()], storage()) :: :ok
  def append_to_log!(shape_id, log_items, {mod, opts}),
    do: mod.append_to_log!(shape_id, log_items, opts)

  import LogOffset, only: :macros
  @doc "Get stream of the log for a shape since a given offset"
  @spec get_log_stream(shape_id(), LogOffset.t(), LogOffset.t(), storage()) ::
          Enumerable.t()
  def get_log_stream(shape_id, offset, max_offset \\ LogOffset.last(), {mod, opts})
      when max_offset == :infinity or not is_log_offset_lt(max_offset, offset),
      do: mod.get_log_stream(shape_id, offset, max_offset, opts)

  @doc "Check if log entries for given shape ID exist"
  @spec has_shape?(shape_id(), storage()) :: boolean()
  def has_shape?(shape_id, {mod, opts}),
    do: mod.has_shape?(shape_id, opts)

  @doc "Store a relation containing information about the schema of a table"
  @spec store_relation(Relation.t(), storage()) :: :ok
  def store_relation(relation, {mod, opts}),
    do: mod.store_relation(relation, opts)

  @doc "Get all stored relations"
  @spec get_relations(storage()) :: Enumerable.t(Relation.t())
  def get_relations({mod, opts}), do: mod.get_relations(opts)

  @doc "Clean up snapshots/logs for a shape id"
  @spec cleanup!(shape_id(), storage()) :: :ok
  def cleanup!(shape_id, {mod, opts}), do: mod.cleanup!(shape_id, opts)
end
