    08:28:17.820 WARNI… watchfiles.main    process has not terminated, sending SIGKILL  
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/usr/lib/python3.12/multiprocessing/spawn.py", line 122, in spawn_main
    exitcode = _main(fd, parent_sentinel)
               ^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/usr/lib/python3.12/multiprocessing/spawn.py", line 131, in _main
    prepare(preparation_data)
  File "/usr/lib/python3.12/multiprocessing/spawn.py", line 246, in prepare
    _fixup_main_from_path(data['init_main_from_path'])
  File "/usr/lib/python3.12/multiprocessing/spawn.py", line 297, in _fixup_main_from_path
    main_content = runpy.run_path(main_path,
                   ^^^^^^^^^^^^^^^^^^^^^^^^^
  File "<frozen runpy>", line 286, in run_path
  File "<frozen runpy>", line 98, in _run_module_code
  File "<frozen runpy>", line 88, in _run_code
  File "/home/ubuntu/develop/live-kit/agent-starter-python/src/agent.py", line 16, in <module>
    from livekit.plugins import noise_cancellation, silero, openai
  File "/home/ubuntu/develop/live-kit/agent-starter-python/.venv/lib/python3.12/site-packages/livekit/plugins/noise_cancellation/__init__.py", line 30, in <module>
    load()
  File "/home/ubuntu/develop/live-kit/agent-starter-python/.venv/lib/python3.12/site-packages/livekit/plugins/noise_cancellation/__init__.py", line 28, in load
    plugin = rtc.AudioFilter(module_id, plugin_path(), dependencies_path())
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ubuntu/develop/live-kit/agent-starter-python/.venv/lib/python3.12/site-packages/livekit/rtc/audio_filter.py", line 18, in __init__
    resp = FfiClient.instance.request(req)
           ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
  File "/home/ubuntu/develop/live-kit/agent-starter-python/.venv/lib/python3.12/site-packages/livekit/rtc/_ffi_client.py", line 236, in request
    handle = ffi_lib.livekit_ffi_request(
             ^^^^^^^^^^^^^^^^^^^^^^^^^^^^