from prometheus_client import Gauge, Info
from util import convert, get_data, get_json

health_metric = Info('health_check', 'Server health check')
web_jvm_max_memory_metric = Gauge('web_jvm_max_memory', 'Web JVM Max Memory (MB)')
web_jvm_free_memory_metric = Gauge('web_jvm_free_memory', 'Web JVM Free Memory (MB)')
web_jvm_heap_commited_metric = Gauge('web_jvm_heap_commited', 'Web JVM Heap Committed (MB)')
web_jvm_heap_init_metric = Gauge('web_jvm_heap_init', 'Web JVM Heap Init (MB)')
web_jvm_heap_max_metric = Gauge('web_jvm_heap_max', 'Web JVM Heap Max (MB)')
web_jvm_heap_used_metric = Gauge('web_jvm_heap_used', 'Web JVM Heap Used (MB)')
web_jvm_non_heap_committed_metric = Gauge('web_jvm_non_heap_committed', 'Web JVM Non Heap Committed (MB)')
web_jvm_non_heap_init_metric = Gauge('web_jvm_non_heap_init', 'Web JVM Non Heap Init (MB))')
web_jvm_non_heap_used_metric = Gauge('web_jvm_non_heap_used', 'Web JVM Non Heap Used (MB)')
web_jvm_threads_metric = Gauge('web_jvm_threads', 'Web JVM Threads')
web_pool_active_connection_metric = Gauge('web_pool_active_connection', 'Web Pool Active Connections')
web_pool_max_connection_metric = Gauge('web_pool_max_connection', 'Web Pool Max Connections')
web_pool_initial_size_metric = Gauge('web_pool_initial_size', 'Web Pool Initial Size')
web_pool_idle_connections_metric = Gauge('web_pool_idle_connections', 'Web Pool Idle Connections')
web_pool_min_idle_connections_metric = Gauge('web_pool_min_idle_connections', 'Web Pool Min Idle Connections')
web_pool_max_idle_connections_metric = Gauge('web_pool_max_idle_connections', 'Web Pool Max Idle Connections')
compute_engine_tasks_pending_metric = Gauge('compute_engine_tasks_pending', 'Compute Engine Tasks Pending')
compute_engine_tasks_inprogress_metric = Gauge('compute_engine_tasks_inprogress', 'Compute Engine Tasks In Progress')
compute_engine_tasks_error_progress_metric = Gauge('compute_engine_tasks_error_progress', 'Compute Engine Tasks Processed With Error')
compute_engine_tasks_success_progress_metric = Gauge('compute_engine_tasks_success_progress', 'Compute Engine Tasks Processed With Success')
compute_engine_tasks_progressing_time_metric = Gauge('compute_engine_tasks_progressing_time', 'Compute Engine Tasks Processing Time (ms)')
compute_engine_tasks_worker_metric = Gauge('compute_engine_tasks_worker', 'Compute Engine Tasks Worker Count')
compute_engine_jvm_state_max_memory_metric = Gauge('compute_engine_jvm_state_max_memory', 'Compute Engine Tasks Worker Count')
compute_engine_jvm_free_memory_metric = Gauge('compute_engine_jvm_free_memory', 'Compute Engine JVM Free Memory (MB)')
compute_engine_jvm_heap_commited_metric = Gauge('compute_engine_jvm_heap_commited', 'Compute Engine JVM Heap Committed (MB)')
compute_engine_jvm_heap_init_metric = Gauge('compute_engine_jvm_heap_init', 'Compute Engine JVM Heap Init (MB)')
compute_engine_jvm_heap_max_metric = Gauge('compute_engine_jvm_heap_max', 'Compute Engine JVM Heap Max (MB)')
compute_engine_jvm_heap_used_metric = Gauge('compute_engine_jvm_heap_used', 'Compute Engine JVM Heap Used (MB)')
compute_engine_jvm_non_heap_committed_metric = Gauge('compute_engine_jvm_non_heap_committed', 'Compute Engine JVM Non Heap Committed (MB)')
compute_engine_jvm_non_heap_init_metric = Gauge('compute_engine_jvm_non_heap_init', 'Compute Engine JVM Non Heap Init (MB))')
compute_engine_jvm_non_heap_used_metric = Gauge('compute_engine_jvm_non_heap_used', 'Compute Engine JVM Non Heap Used (MB)')
compute_engine_jvm_threads_metric = Gauge('compute_engine_jvm_threads', 'Compute Engine JVM Threads')
compute_engine_pool_active_connection_metric = Gauge('compute_engine_pool_active_connection', 'Compute Engine Pool Active Connections')
compute_engine_pool_max_connection_metric = Gauge('compute_engine_pool_max_connection', 'Compute Engine Pool Max Connections')
compute_engine_pool_initial_size_metric = Gauge('compute_engine_pool_initial_size', 'Compute Engine Pool Initial Size')
compute_engine_pool_idle_connections_metric = Gauge('compute_engine_pool_idle_connections', 'Compute Engine Pool Idle Connections')
compute_engine_pool_min_idle_connections_metric = Gauge('compute_engine_pool_min_idle_connections', 'Compute Engine Pool Min Idle Connections')
compute_engine_pool_max_idle_connections_metric = Gauge('compute_engine_pool_max_idle_connections', 'Compute Engine Pool Max Idle Connections')
cpu_usage_metric = Gauge('cpu_usage', 'CPU Usage (%)')
disk_available_metric = Gauge('disk_available', 'Disk Available')
store_size_metric = Gauge('store_size', 'Store Size')
translog_size_metric = Gauge('translog_size', 'Translog Size')
jvm_heap_used_metric = Gauge('jvm_heap_used', 'JVM Heap Used')
jvm_heap_max_metric = Gauge('jvm_heap_max', 'JVM Heap Max')
jvm_non_heap_used_metric = Gauge('jvm_non_heap_used', 'JVM Non Heap Used')
jvm_threads_metric = Gauge('jvm_threads', 'JVM Threads')
open_file_descriptors_metric = Gauge('open_file_descriptors', 'Open File Descriptors')
max_file_descriptors_metric = Gauge('max_file_descriptors', 'Max File Descriptors')
index_docs_metric = Gauge('index_docs', 'Index components - Docs')
sonarlint_client_metric = Gauge('sonarlint_client', 'SonarLint Connected Clients')
total_of_user_metric = Gauge('total_of_user', 'Total of user')
total_of_project_metric = Gauge('total_of_project', 'Total of project')
total_line_of_code_metric = Gauge('total_line_of_code', 'Total line of code')
total_of_plugins_metric = Gauge('total_of_plugins', 'Total of plugins')
project_count_by_language_metric = Gauge('project_count_by_language', 'Project count by language', ['language'])
ncloc_count_by_language_metric = Gauge('ncloc_count_by_language', 'Line of code count by language', ['language'])


def safe_convert(value, fallback='0MB'):
    target = value if value not in (None, 0, '') else fallback
    try:
        return convert(target)
    except Exception:
        return 0


def ensure_sequence(value):
    if isinstance(value, list):
        return value
    if value in (None, 0, {}):
        return []
    if isinstance(value, dict):
        return [value]
    return []


def system_metric(sonarqube_server, sonarqube_token):
  url = sonarqube_server + "/api/system/info"
  data = get_data(url, sonarqube_token)

  health = get_json('Health', data, 'UNKNOWN')
  health_metric.info({'health': health})

# Web JVM State
  web_jvm_state = get_json('Web JVM State', data, {})
  web_jvm_max_memory_metric.set(get_json('Max Memory (MB)', web_jvm_state, 0))
  web_jvm_free_memory_metric.set(get_json('Free Memory (MB)', web_jvm_state, 0))
  web_jvm_heap_commited_metric.set(get_json('Heap Committed (MB)', web_jvm_state, 0))
  web_jvm_heap_init_metric.set(get_json('Heap Init (MB)', web_jvm_state, 0))
  web_jvm_heap_max_metric.set(get_json('Heap Max (MB)', web_jvm_state, 0))
  web_jvm_heap_used_metric.set(get_json('Heap Used (MB)', web_jvm_state, 0))
  web_jvm_non_heap_committed_metric.set(get_json('Non Heap Committed (MB)', web_jvm_state, 0))
  web_jvm_non_heap_init_metric.set(get_json('Non Heap Init (MB)', web_jvm_state, 0))
  web_jvm_non_heap_used_metric.set(get_json('Non Heap Used (MB)', web_jvm_state, 0))
  web_jvm_threads_metric.set(get_json('Threads', web_jvm_state, 0))

# Web Database Connection
  web_database_connection = get_json('Web Database Connection', data, {})
  web_pool_active_connection_metric.set(get_json('Pool Active Connections', web_database_connection, 0))
  web_pool_max_connection_metric.set(get_json('Pool Max Connections', web_database_connection, 0))
  web_pool_initial_size_metric.set(get_json('Pool Initial Size', web_database_connection, 0))
  web_pool_idle_connections_metric.set(get_json('Pool Idle Connections', web_database_connection, 0))
  web_pool_min_idle_connections_metric.set(get_json('Pool Min Idle Connections', web_database_connection, 0))
  web_pool_max_idle_connections_metric.set(get_json('Pool Max Idle Connections', web_database_connection, 0))

# Compute Engine Tasks
  compute_engine_tasks = get_json('Compute Engine Tasks', data, {})
  compute_engine_tasks_pending_metric.set(get_json('Pending', compute_engine_tasks, 0))
  compute_engine_tasks_inprogress_metric.set(get_json('In Progress', compute_engine_tasks, 0))
  compute_engine_tasks_error_progress_metric.set(get_json('Processed With Error', compute_engine_tasks, 0))
  compute_engine_tasks_success_progress_metric.set(get_json('Processed With Success', compute_engine_tasks, 0))
  compute_engine_tasks_progressing_time_metric.set(get_json('Processing Time (ms)', compute_engine_tasks, 0))
  compute_engine_tasks_worker_metric.set(get_json('Worker Count', compute_engine_tasks, 0))

# Compute Engine JVM State
  compute_engine_jvm_state = get_json('Compute Engine JVM State', data, {})
  compute_engine_jvm_state_max_memory_metric.set(get_json('Worker Count', compute_engine_jvm_state, 0))
  compute_engine_jvm_free_memory_metric.set(get_json('Max Memory (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_heap_commited_metric.set(get_json('Heap Committed (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_heap_init_metric.set(get_json('Heap Init (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_heap_max_metric.set(get_json('Heap Max (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_heap_used_metric.set(get_json('Heap Used (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_non_heap_committed_metric.set(get_json('Non Heap Committed (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_non_heap_init_metric.set(get_json('Non Heap Init (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_non_heap_used_metric.set(get_json('Non Heap Used (MB)', compute_engine_jvm_state, 0))
  compute_engine_jvm_threads_metric.set(get_json('Threads', compute_engine_jvm_state, 0))

# Compute Engine Database Connection
  compute_engine_database_connection = get_json('Compute Engine Database Connection', data, {})
  compute_engine_pool_active_connection_metric.set(get_json('Pool Active Connections', compute_engine_database_connection, 0))
  compute_engine_pool_max_connection_metric.set(get_json('Pool Max Connections', compute_engine_database_connection, 0))
  compute_engine_pool_initial_size_metric.set(get_json('Pool Initial Size', compute_engine_database_connection, 0))
  compute_engine_pool_idle_connections_metric.set(get_json('Pool Idle Connections', compute_engine_database_connection, 0))
  compute_engine_pool_min_idle_connections_metric.set(get_json('Pool Min Idle Connections', compute_engine_database_connection, 0))
  compute_engine_pool_max_idle_connections_metric.set(get_json('Pool Max Idle Connections', compute_engine_database_connection, 0))

# Search State
  search_state = get_json('Search State', data, {})
  cpu_usage_metric.set(get_json('CPU Usage (%)', search_state, 0))
  disk_available_metric.set(safe_convert(get_json('Disk Available', search_state, '0B')))
  store_size_metric.set(safe_convert(get_json('Store Size', search_state, '0B')))
  translog_size_metric.set(safe_convert(get_json('Translog Size', search_state, '0B')))
  jvm_heap_used_metric.set(safe_convert(get_json('JVM Heap Used', search_state, '0MB')))
  jvm_heap_max_metric.set(safe_convert(get_json('JVM Heap Max', search_state, '0MB')))
  jvm_non_heap_used_metric.set(safe_convert(get_json('JVM Non Heap Used', search_state, '0MB')))
  jvm_threads_metric.set(get_json('JVM Threads', search_state, 0))
  open_file_descriptors_metric.set(get_json('Open File Descriptors', search_state, 0))
  max_file_descriptors_metric.set(get_json('Max File Descriptors', search_state, 0))

# Search Indexes
  search_indexes = get_json('Search Indexes', data, {})
  index_docs_metric.set(get_json('Index components - Docs', search_indexes, 0))

# Server Push Connections
  server_push_connections = get_json('Server Push Connections', data, {})
  sonarlint_client_metric.set(get_json('SonarLint Connected Clients', server_push_connections, 0))

# Statistics
  statistics = get_json('Statistics', data, {})
  total_of_user_metric.set(get_json('userCount', statistics, 0))
  total_of_project_metric.set(get_json('projectCount', statistics, 0))
  total_line_of_code_metric.set(get_json('ncloc', statistics, 0))

  total_of_plugins = get_json('plugins', statistics, [])
  if isinstance(total_of_plugins, int):
    total_of_plugins_metric.set(total_of_plugins)
  else:
    total_of_plugins_metric.set(len(ensure_sequence(total_of_plugins)))

  project_count_by_language = ensure_sequence(get_json('projectCountByLanguage', statistics, []))
  for c in project_count_by_language:
    language = c.get('language', 'unknown')
    count = c.get('count', 0)
    project_count_by_language_metric.labels(language=language).set(count)

  ncloc_count_by_language = ensure_sequence(get_json('nclocByLanguage', statistics, []))
  for c in ncloc_count_by_language:
    language = c.get('language', 'unknown')
    ncloc = c.get('ncloc', 0)
    ncloc_count_by_language_metric.labels(language=language).set(ncloc)

