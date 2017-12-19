-module(args).

-export([parse/1]).

default_context() ->
    #{ ciphertexts      => [],
       population_size  => 4096,
       max_procs        => 4 }.

parse(Args) ->
    {Context, Ciphertexts} = parse_opts(default_context(), Args),
    lists:foldl(fun add_ciphertext/2, Context, Ciphertexts).

parse_opts(Context, Args) ->
    case Args of
        ["-p", GenerationSize | Rest] ->
            parse_opts(set_population_size(GenerationSize, Context), Rest);
        ["-P", MaxProcs | Rest] ->
            parse_opts(set_max_procs(MaxProcs, Context), Rest);
        ["-h" | _] ->
            usage();
        [[$- | _] = Unknown | _] ->
            io:format(standard_error, "Unknown argument: ~s\n", [Unknown]),
            usage();
        [_, _ | _] = Ciphertexts ->
            {Context, Ciphertexts};
        _ ->
            io:format(standard_error, "At least two ciphertext files must be given.\n", []),
            usage()
    end.

add_ciphertext(Ciphertext, Context) ->
    case file:read_file(Ciphertext) of
        {ok, Data} ->
            maps:update_with(ciphertexts, fun(Ciphertexts) ->
                                                  [{Ciphertext, Data} | Ciphertexts]
                                          end, Context);
        {error, Reason} ->
            io:format(standard_error, "Failed to read ciphertext from ~s: ~s\n",
                      [Ciphertext, file:format_error(Reason)]),
            usage()
    end.

set_population_size(GenerationSize, Context) ->
    case string:to_integer(GenerationSize) of
        {N, []} when 0 < N ->
            % Round population size to next multiple of 2
            maps:put(population_size, N + (N band 1), Context);
        _ ->
            io:format(standard_error, "Invalid population size: ~s\n", [GenerationSize]),
            usage()
    end.

set_max_procs(MaxProcs, Context) ->
    case string:to_integer(MaxProcs) of
        {N, []} when 0 < N ->
            maps:put(max_procs, N, Context);
        _ ->
            io:format(standard_error, "Invalid maximum process count: ~s\n", [MaxProcs]),
            usage()
    end.
                    
usage() ->
    Message = "Usage:\n"
              "\n"
              "    taxa [options] ciphertext1 ciphertext2 ... ciphertextN\n"
              "\n"
              "Where options are:\n"
              "\n"
              "    -p <population_size> (sets population size for all generations, must be positive)  (default: 4096)\n"
              "    -P <max_procs>       (maximum number of processes computing population scores)     (default: 4)\n"
              "\n"
              "Example:\n"
              "\n"
              "     taxa -p 8192 file1.enc file2.enc file3.enc\n",
    io:format(standard_error, "\n~s\n", [Message]),
    erlang:halt(1).
