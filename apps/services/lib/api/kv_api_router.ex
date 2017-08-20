defmodule KV.Router.Api do
  use Maru.Router

  @doc """
  curl -XPOST 127.0.0.1:8080/kv -d '{"name":"bucket","num_partitions":4,"replication_factor":3}' -H 'Content-Type: application/json'
  curl -XPOST 127.0.0.1:8080/kv/bucket -d '{"key":"mykey","value":"myvalue"}' -H 'Content-Type: application/json'
  curl -XGET 127.0.0.1:8080/kv/bucket/mykey -H 'Content-Type: application/json'
  curl -XDELETE 127.0.0.1:8080/kv/bucket/mykey -H 'Content-Type: application/json'
  curl -XGET 127.0.0.1:8080/kv/bucket/mykey -H 'Content-Type: application/json'
  curl -XDELETE 127.0.0.1:8080/kv/bucket -H 'Content-Type: application/json'
  curl -XGET 127.0.0.1:8080/kv/bucket
  """

  # {host}:{port}/kv/{routes}
  namespace :kv do

    route_param :name do
      desc "gets a bucket"
        get do
          {proc_registry, _array} = KV.Router.get_state
          {_assigned_node, {:ok, bucket}} = KV.Router.lookup(proc_registry, params[:name])
          state = KV.Bucket.get_state(bucket)

          json(conn, %{name: elem(state, 0), num_partitions: elem(state, 2), replication_factor: elem(state, 3)})
        end # get


      desc "deletes a bucket"
        delete do
          {proc_registry, _array} = KV.Router.get_state
          {_assigned_node, {:ok, bucket}} = KV.Router.lookup(proc_registry, params[:name])
          GenServer.stop(bucket)

          json(conn, %{success: true})
        end # delete

      desc "creates a key"
        params do
          requires :key, type: String
          requires :value, type: String
        end
        post do
          {proc_registry, _array} = KV.Router.get_state
          {_assigned_node, {:ok, bucket}} = KV.Router.lookup(proc_registry, params[:name])
          KV.Bucket.write(bucket, {params[:key], params[:value]})

          json(conn, %{success: true})
        end

        route_param :key do
          desc "gets a key"
            get do
              {proc_registry, _array} = KV.Router.get_state
              {_assigned_node, {:ok, bucket}} = KV.Router.lookup(proc_registry, params[:name])
              value = KV.Bucket.lookup(bucket, params[:key])

              json(conn, %{value: value})
            end

            desc "deletes a key"
              delete do
                {proc_registry, _array} = KV.Router.get_state
                {_assigned_node, {:ok, bucket}} = KV.Router.lookup(proc_registry, params[:name])
                value = KV.Bucket.delete(bucket, params[:key])

                json(conn, %{success: true})
              end
        end
    end # route_param


    desc "creates a bucket"
      params do
        requires :name, type: String
        requires :num_partitions, type: Integer
        requires :replication_factor, type: Integer, default: 3
      end # params

      post do
        {proc_registry, _array} = KV.Router.get_state
        {_assigned_node, bucket} = KV.Router.create_bucket(proc_registry, params[:name], 6, 3)
        state = KV.Bucket.get_state(bucket)

        json(conn, %{name: elem(state, 0), num_partitions: elem(state, 2), replication_factor: elem(state, 3)})
      end # post

   end # namespace
 end # module
