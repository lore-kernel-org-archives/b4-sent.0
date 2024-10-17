From: Daniel Gomez <da.gomez@samsung.com>
Date: Thu, 17 Oct 2024 14:42:47 +0200
Subject: [PATCH 5/5] sysbench: add postgresql native TPS variablity support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20241017-add-postgresql-tps-var-v1-5-4996d45426af@samsung.com>
References: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
In-Reply-To: <20241017-add-postgresql-tps-var-v1-0-4996d45426af@samsung.com>
To: kdevops@lists.linux.dev, mcgrof@kernel.org
Cc: d+samsung@kruces.com, Daniel Gomez <da.gomez@samsung.com>
X-Mailer: b4 0.14.1
X-Developer-Signature: v=1; a=ed25519-sha256; t=1729168974; l=99045;
 i=da.gomez@samsung.com; s=20240621; h=from:subject:message-id;
 bh=jLSW3SQOCU1g1QU2pluLgamXD+Ad3lAeCmyTNccjYf8=;
 b=bP4SHunviaCMh8M5pw4KtFmNFFRUnQBDElMbnLcKSTSAjV7rE2CZfcIu1R/iNJWburlmTESei
 x0SwF0x7AmRDcUTELGk7yA3Xez2bShSLYioCAE0xSUWvTT1SW4UFv+a
X-Developer-Key: i=da.gomez@samsung.com; a=ed25519;
 pk=BqYk31UHkmv0WZShES6pIZcdmPPGay5LbzifAdZ2Ia4=
X-Endpoint-Received: by B4 Relay for da.gomez@samsung.com/20240621 with auth_id=175
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add PostgreSQL TPS variability benchmark support.

Signed-off-by: Daniel Gomez <da.gomez@samsung.com>
---
 playbooks/roles/sysbench/defaults/main.yml         |  15 +
 .../sysbench/tasks/install-deps/debian/main.yml    |  47 ++
 playbooks/roles/sysbench/tasks/main.yaml           |   4 +
 .../sysbench/tasks/postgresql-native/main.yaml     | 708 ++++++++++++++++++
 .../sysbench/templates/postgresql-conf-000.conf.j2 | 820 +++++++++++++++++++++
 .../templates/postgresql-conf-default.conf.j2      | 820 +++++++++++++++++++++
 workflows/sysbench/Kconfig                         |  47 ++
 workflows/sysbench/Kconfig.fs                      |  30 +
 workflows/sysbench/Kconfig.native                  | 120 +++
 9 files changed, 2611 insertions(+)

diff --git a/playbooks/roles/sysbench/defaults/main.yml b/playbooks/roles/sysbench/defaults/main.yml
index cf62a1f..ea198ad 100644
--- a/playbooks/roles/sysbench/defaults/main.yml
+++ b/playbooks/roles/sysbench/defaults/main.yml
@@ -55,3 +55,18 @@ sysbench_docker_telemetry_path: "/data/sysbench-telemetry"
 
 sysbench_disable_doublewrite_auto: False
 sysbench_disable_doublewrite_always: False
+
+sysbench_type_postgresql_native: false
+
+sysbench_postgresql_repo_path: "{{ data_path }}/postgresql"
+sysbench_postgresql_pgdata: "{{ sysbench_mnt }}/postgresql"
+sysbench_postgresql_logfile: "{{ sysbench_mnt }}/postgresql/postgresql.log"
+sysbench_postgresql_configuration: postgresql-conf-default.conf
+sysbench_postgresql_user: postgres
+
+# pg_controldata
+# https://www.postgresql.org/docs/current/app-pgcontroldata.html
+sysbench_postgresql_controldata_logfile: "{{ sysbench_telemetry_path }}/controldata.log"
+
+sysbench_disable_full_page_writes_auto: false
+sysbench_disable_full_page_writes_always: false
diff --git a/playbooks/roles/sysbench/tasks/install-deps/debian/main.yml b/playbooks/roles/sysbench/tasks/install-deps/debian/main.yml
index 9c7d745..005d1f6 100644
--- a/playbooks/roles/sysbench/tasks/install-deps/debian/main.yml
+++ b/playbooks/roles/sysbench/tasks/install-deps/debian/main.yml
@@ -28,3 +28,50 @@
     state: present
     update_cache: yes
   tags: [ 'deps' ]
+  when: 'sysbench_type_mysql_docker|bool'
+
+- name: Install PosgreSQL build deps
+  become: yes
+  become_method: sudo
+  ansible.builtin.apt:
+    name:
+      - bison
+      - build-essential
+      - flex
+      - git
+      - libicu-dev
+      - libreadline-dev
+      - pkgconf
+      - sysbench
+      - zlib1g-dev
+    state: present
+    update_cache: yes
+  tags: [ 'deps' ]
+  when: 'sysbench_type_postgresql_native|bool'
+
+# acl - Required for running Ansible with unpriviledge user (sysbench_postgresql_user)
+# https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_privilege_escalation.html#risks-of-becoming-an-unprivileged-user
+- name: Install PosgreSQL runtime deps
+  become: yes
+  become_method: sudo
+  ansible.builtin.apt:
+    name:
+      - acl
+      - xfsprogs
+      - nvme-cli
+    state: present
+    update_cache: yes
+  tags: [ 'deps' ]
+  when: 'sysbench_type_postgresql_native|bool'
+
+- name: Install sysbench deps
+  become: yes
+  become_method: sudo
+  ansible.builtin.apt:
+    name:
+      - locales
+      - rsync
+    state: present
+    update_cache: yes
+  tags: [ 'deps' ]
+  when: 'sysbench_type_postgresql_native|bool'
diff --git a/playbooks/roles/sysbench/tasks/main.yaml b/playbooks/roles/sysbench/tasks/main.yaml
index 4f4ab51..e0f7d85 100644
--- a/playbooks/roles/sysbench/tasks/main.yaml
+++ b/playbooks/roles/sysbench/tasks/main.yaml
@@ -34,3 +34,7 @@
 - name: MySQL Docker
   ansible.builtin.import_tasks: mysql-docker/main.yml
   when: sysbench_type_mysql_docker | bool
+
+- name: PostgreSQL Native
+  ansible.builtin.import_tasks: postgresql-native/main.yaml
+  when: sysbench_type_postgresql_native | bool
diff --git a/playbooks/roles/sysbench/tasks/postgresql-native/main.yaml b/playbooks/roles/sysbench/tasks/postgresql-native/main.yaml
new file mode 100644
index 0000000..663f8ab
--- /dev/null
+++ b/playbooks/roles/sysbench/tasks/postgresql-native/main.yaml
@@ -0,0 +1,708 @@
+---
+- name: Get the latest PostgreSQL ref
+  ansible.builtin.shell: |
+    set -o pipefail && \
+    git ls-remote --tags --sort="-version:refname" \
+    https://git.postgresql.org/git/postgresql.git {{ sysbench_postgresql_ref_string }}* \
+    | grep -E 'refs/tags/REL_[0-9]+_[0-9]+$' \
+    | head -n 1 \
+    | awk '{print $2}' \
+    | sed 's#refs/tags/##'
+  args:
+    executable: /bin/bash
+  register: _sysbench_postgresql_ref
+  changed_when: false
+  tags: ['setup']
+
+- name: Git clone PostgreSQL
+  ansible.builtin.git:
+    repo: "https://git.postgresql.org/git/postgresql.git"
+    dest: "{{ sysbench_postgresql_repo_path }}"
+    update: true
+    version: "{{ _sysbench_postgresql_ref.stdout }}"
+  tags: ['setup']
+  environment:
+    GIT_SSL_NO_VERIFY: "true"
+
+- name: Get number of processing units available
+  ansible.builtin.command: nproc --all
+  register: _sysbench_punits
+  changed_when: _sysbench_punits.rc != 0
+  tags: ['always']
+
+- name: Set threads using nproc output
+  ansible.builtin.set_fact:
+    _sysbench_threads: "{{ _sysbench_punits.stdout }}"
+  when:
+    - sysbench_threads == 0
+  tags: ['always']
+
+- name: Set threads manually
+  ansible.builtin.set_fact:
+    _sysbench_threads: "{{ sysbench_threads }}"
+  when:
+    - sysbench_threads != 0
+  tags: ['always']
+
+- name: Check if clean is required for PostgreSQL builddir
+  ansible.builtin.stat:
+    path: "{{ sysbench_postgresql_repo_path }}/GNUmakefile"
+  register: _sysbench_postgresql_cleanup
+  tags: ['setup']
+
+- name: Clean PostgreSQL builddir
+  ansible.builtin.command:
+    cmd: |
+      make clean
+      make distclean
+  args:
+    chdir: "{{ sysbench_postgresql_repo_path }}"
+  register: _sysbench_postgresql_clean
+  changed_when: _sysbench_postgresql_clean.rc != 0
+  when:
+    - _sysbench_postgresql_cleanup.stat.exists|bool
+  ignore_errors: true
+  tags: ['setup']
+
+- name: Configure PostgreSQL
+  ansible.builtin.command:
+    cmd: >
+      ./configure
+      --with-blocksize={{ sysbench_postgresql_blocksize }}
+      --with-wal-blocksize={{ sysbench_postgresql_wal_blocksize }}
+  args:
+    chdir: "{{ sysbench_postgresql_repo_path }}"
+  register: _sysbench_postgresql_configure
+  changed_when: _sysbench_postgresql_configure.rc != 0
+  tags: ['setup']
+
+- name: Build PostgreSQL
+  community.general.make:
+    jobs: "{{ _sysbench_punits.stdout }}"
+  args:
+    chdir: "{{ sysbench_postgresql_repo_path }}"
+  changed_when: false
+  tags: ['setup']
+
+- name: Install PostgreSQL
+  become: true
+  become_method: sudo
+  community.general.make:
+    target: install
+  args:
+    chdir: "{{ sysbench_postgresql_repo_path }}"
+  tags: ['setup']
+
+- name: Create PostgreSQL benchmark user
+  become: true
+  become_method: sudo
+  ansible.builtin.user:
+    name: "{{ sysbench_postgresql_user }}"
+  tags: ['setup']
+
+- name: Ensure telemetry data directory exists
+  become: true
+  become_flags: 'su - -c'
+  become_method: sudo
+  ansible.builtin.file:
+    path: "{{ sysbench_telemetry_path }}"
+    state: directory
+    mode: "u=rwx,g=rx,o=rx"
+  tags: ['setup']
+
+- name: Check if PostgreSQL Server is Running
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.stat:
+    path: "{{ sysbench_postgresql_pgdata }}/postmaster.pid"
+  register: _sysbench_postgresql_stop
+
+- name: Stop the PostgreSQL Server
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_ctl
+    --pgdata={{ sysbench_postgresql_pgdata }}
+    --log={{ sysbench_postgresql_logfile }}
+    stop
+    --mode=immediate
+  retries: 5
+  delay: 10
+  changed_when: false
+  when:
+    - _sysbench_postgresql_stop.stat.exists | bool
+
+- name: Determine filesystem setting used and db page size
+  vars:
+    fs_type_variable: "{{ ansible_host | regex_replace('^' + kdevops_host_prefix + '-', '') | regex_replace('-.+', '') }}"
+    fs_command_variable_simple: "sysbench_{{ ansible_host | regex_replace('^' + kdevops_host_prefix + '-', '') | regex_replace('-dev$', '') }}_cmd"
+    fs_command_variable: "{{ fs_command_variable_simple | regex_replace('-', '_') | regex_replace('^sysbench_' + fs_type_variable, fs_type_variable + '_section') }}"
+    db_page_size_simple: "sysbench_{{ ansible_host | regex_replace('^' + kdevops_host_prefix + '-', '') | regex_replace('-dev$', '') }}_db_page_size"
+    db_page_size_variable: "{{ db_page_size_simple | regex_replace('-', '_') | regex_replace('^sysbench_' + fs_type_variable, fs_type_variable + '_section') }}"
+    fs_sector_size_variable: "sysbench_{{ fs_type_variable }}_sector_size"
+    fs_cmd: "{{ lookup('vars', 'sysbench_' + fs_command_variable) }}"
+    sect_size: "{{ lookup('vars', fs_sector_size_variable) }}"
+    db_page_size: "{{ sysbench_postgresql_blocksize }}"
+  ansible.builtin.set_fact:
+    filesystem_command_for_host: "{{ fs_cmd }}"
+    sysbench_fs_sector_size: "{{ sect_size }}"
+    sysbench_fstype: "{{ fs_type_variable }}"
+    sysbench_fs_opts_without_sector_size: "{{ fs_cmd | regex_replace('^[^ ]+ ', '') }}"
+    sysbench_db_page_size: "{{ db_page_size }}"
+  tags: ['vars']
+
+- name: Set filesystem options for XFS with sector size
+  ansible.builtin.set_fact:
+    sysbench_fs_opts: "{{ sysbench_fs_opts_without_sector_size }} -s size={{ sysbench_fs_sector_size }} -L {{ sysbench_label }}"
+  when: sysbench_fstype != 'ext4'
+  tags: ['mkfs']
+
+- name: Set filesystem options for ext4 without sector size
+  ansible.builtin.set_fact:
+    sysbench_fs_opts: "{{ sysbench_fs_opts_without_sector_size }} -L {{ sysbench_label }}"
+  when: sysbench_fstype == 'ext4'
+  tags: ['mkfs']
+
+- name: Set environment variable for sector size for ext4
+  ansible.builtin.set_fact:
+    sysbench_fs_env:
+      MKE2FS_DEVICE_SECTSIZE: "{{ sysbench_fs_sector_size }}"
+  when: sysbench_fstype == 'ext4'
+  tags: ['mkfs']
+
+- name: Clear environment variable for non-ext4 filesystems
+  ansible.builtin.set_fact:
+    sysbench_fs_env: {}
+  when: sysbench_fstype != 'ext4'
+  tags: ['mkfs']
+
+- name: Display the filesystem options and environment variable for the current host
+  ansible.builtin.debug:
+    msg: |
+      Sysbench device:    {{ sysbench_device }}
+      Sysbench fstype:    {{ sysbench_fstype }}
+      Sysbench fs opts:   {{ sysbench_fs_opts }}
+      Sysbench label:     {{ sysbench_label }}
+      Sysbench mount:     {{ sysbench_mnt }}
+      Sysbench env:       {{ sysbench_fs_env }}
+  tags: ['debug']
+
+- name: Fail if no filesystem command is found for the host
+  ansible.builtin.fail:
+    msg: "No filesystem configuration command found for the current host: {{ ansible_host }}"
+  when: filesystem_command_for_host is undefined
+  tags: ['mkfs']
+
+- name: Unmount {{ sysbench_mnt }}
+  become: true
+  become_flags: 'su - -c'
+  become_method: sudo
+  ansible.posix.mount:
+    path: "{{ sysbench_mnt }}"
+    state: unmounted
+  tags: ['clean', 'mkfs']
+
+- name: Wipe filesystem signatures from the device
+  become: true
+  become_flags: 'su - -c'
+  become_method: sudo
+  ansible.builtin.command:
+    cmd: "wipefs --all {{ sysbench_device }}"
+  register: _sysbench_postgresql_wipefs
+  changed_when: _sysbench_postgresql_wipefs.rc != 0
+  tags: ['clean', 'mkfs']
+
+- name: Create the filesystem we'll use to place the database under test
+  ansible.builtin.include_role:
+    name: create_partition
+  vars:
+    disk_setup_device: "{{ sysbench_device }}"
+    disk_setup_fstype: "{{ sysbench_fstype }}"
+    disk_setup_label: "{{ sysbench_label }}"
+    disk_setup_path: "{{ sysbench_mnt }}"
+    disk_setup_fs_opts: "{{ sysbench_fs_opts }}"
+    disk_setup_env: "{{ sysbench_fs_env }}"
+  tags: ['clean', 'mkfs']
+
+- name: Change ownership of PostgreSQL database under test mount directory
+  become: true
+  become_method: sudo
+  ansible.builtin.file:
+    path: "{{ sysbench_mnt }}"
+    owner: "{{ sysbench_postgresql_user }}"
+    group: "{{ sysbench_postgresql_user }}"
+    recurse: true
+
+- name: Initialize the PostgreSQL database
+  become: true
+  become_method: sudo
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/initdb
+    --pgdata={{ sysbench_postgresql_pgdata }}
+  register: _sysbench_postgresql_initdb
+  changed_when: _sysbench_postgresql_initdb.rc != 0
+
+- name: Set sysbench_postgresql_full_page_writes based on ansible_host
+  tags: ['vars']
+  ansible.builtin.set_fact:
+    sysbench_host_is_baseline: "{{ False if ansible_host is search('-dev$') else True }}"
+    sysbench_postgresql_full_page_writes: "{{ 'off' if ansible_host is search('-dev$') else 'on' }}"
+  when:
+    - sysbench_disable_full_page_writes_auto|bool
+
+- name: Set sysbench_postgresql_full_page_writes based on ansible_host
+  tags: ['vars']
+  ansible.builtin.set_fact:
+    sysbench_postgresql_full_page_writes: 'off'
+  when:
+    - sysbench_disable_full_page_writes_always|bool
+
+- name: Generate PostgreSQL configuration file from template
+  tags: ['setup']
+  become: true
+  become_method: sudo
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.template:
+    src: "{{ sysbench_postgresql_configuration }}.j2"
+    dest: "{{ sysbench_postgresql_pgdata }}/postgresql.conf"
+    mode: "u=rw,g=r,o=r"
+
+- name: Get used target kernel version
+  tags: ['db_start']
+  ansible.builtin.command: "uname -r"
+  changed_when: false
+  register: _uname_cmd
+
+- name: Store last kernel variable
+  ansible.builtin.set_fact:
+    last_kernel: "{{ _uname_cmd.stdout_lines | regex_replace('\\]') | regex_replace('\\[') | replace(\"'\", '') }}"
+  tags: ['db_start']
+  run_once: true
+
+- name: Ensure the results directory exists on the localhost
+  tags: ['db_start']
+  delegate_to: localhost
+  ansible.builtin.file:
+    path: "{{ topdir_path }}/workflows/sysbench/results/"
+    state: directory
+    mode: '0755'
+  run_once: true
+
+- name: Ensure the results directory exists on the localhost for each node locally
+  tags: ['db_start']
+  delegate_to: localhost
+  ansible.builtin.file:
+    path: "{{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/"
+    state: directory
+    mode: '0755'
+
+- name: Document used target kernel version
+  delegate_to: localhost
+  ansible.builtin.shell: |
+    echo {{ last_kernel }} > {{ topdir_path }}/workflows/sysbench/results/last-kernel.txt
+  changed_when: false
+  tags: ['db_start']
+  run_once: true
+
+- name: Document full_page_writes setting on node
+  delegate_to: localhost
+  ansible.builtin.shell: |
+    echo {{ sysbench_postgresql_full_page_writes }} > {{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/full_page_writes.txt
+  changed_when: false
+  tags: ['db_start']
+
+- name: Document db blocksize setting on node
+  delegate_to: localhost
+  ansible.builtin.shell: |
+    echo {{ sysbench_db_page_size }} > {{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/postgresql_blocksize.txt
+  changed_when: false
+  tags: ['db_start']
+
+- name: Start the PostgreSQL server
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_ctl
+    --pgdata={{ sysbench_postgresql_pgdata }}
+    --log={{ sysbench_postgresql_logfile }}
+    start
+  changed_when: false
+  tags: ['setup']
+
+- name: Create PostgreSQL database USER
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/psql
+    --command="CREATE USER {{ sysbench_db_username }} WITH PASSWORD '{{ sysbench_db_password }}';"
+  changed_when: false
+  tags: ['setup']
+
+- name: Create PostgreSQL database DATABASE
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/psql
+    --command="CREATE DATABASE {{ sysbench_db_name }};"
+  changed_when: false
+  tags: ['setup']
+
+- name: Grant USER privileges to DATABASE
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/psql
+    --command="GRANT ALL PRIVILEGES ON DATABASE {{ sysbench_db_name }} TO {{ sysbench_db_username }};"
+  changed_when: false
+  tags: ['setup']
+
+- name: Grant ALL public Privileges to DATABASE
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/psql
+    --host=localhost
+    --port={{ sysbench_local_db_port }}
+    --dbname={{ sysbench_db_name }}
+    --username={{ sysbench_postgresql_user }}
+    --no-password
+    --command="GRANT ALL ON SCHEMA public TO {{ sysbench_db_name }};"
+  changed_when: false
+  tags: ['setup']
+
+- name: Test and Ensure Permissions are Set Correctly
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/psql
+    --host=localhost
+    --port={{ sysbench_local_db_port }}
+    --dbname={{ sysbench_db_name }}
+    --username={{ sysbench_postgresql_user }}
+    --no-password
+    --command="create table xyz(a varchar(100));"
+  changed_when: false
+  tags: ['setup']
+
+# Keep this at threads=1 as multiple threads don't work when building the
+# initial database.
+- name: Populate sysbench database
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    sysbench
+    --db-driver={{ sysbench_db_type }}
+    --table-size={{ sysbench_oltp_table_size }}
+    --tables={{ sysbench_oltp_table_count }}
+    --threads=1
+    --pgsql-host=127.0.0.1
+    --pgsql-port={{ sysbench_local_db_port }}
+    --pgsql-user={{ sysbench_db_username }}
+    --pgsql-password={{ sysbench_db_password }}
+    --pgsql-db={{ sysbench_db_name }}
+    --db-debug
+    --verbosity=5
+    /usr/share/sysbench/oltp_read_write.lua prepare
+  register: sysbench_init_pop
+  tags: ['setup']
+  changed_when: false
+
+- name: Save the output of populating the initial sysbench database
+  become: true
+  become_method: sudo
+  ansible.builtin.copy:
+    content: "{{ sysbench_init_pop.stdout }}"
+    dest: "{{ sysbench_telemetry_path }}/sysbench_populate.txt"
+    mode: '0755'
+  tags: ['setup']
+
+- name: Start sysbench run
+  tags: ['run_sysbench']
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    sysbench
+    --db-driver={{ sysbench_db_type }}
+    --table-size={{ sysbench_oltp_table_size }}
+    --tables={{ sysbench_oltp_table_count }}
+    --threads={{ _sysbench_threads }}
+    --pgsql-host=127.0.0.1
+    --pgsql-port={{ sysbench_local_db_port }}
+    --pgsql-user={{ sysbench_db_username }}
+    --pgsql-password={{ sysbench_db_password }}
+    --pgsql-db={{ sysbench_db_name }}
+    --debug=on
+    --db-debug
+    --verbosity=5
+    --time={{ sysbench_test_duration }}
+    --report-interval={{ sysbench_report_interval }}
+    --histogram=on
+    /usr/share/sysbench/oltp_read_write.lua run
+  changed_when: false
+  register: sysbench_postgresql_run_output
+
+- name: Stop the PostgreSQL server (Smart Mode)
+  tags: ['run_sysbench']
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_ctl
+    --pgdata={{ sysbench_postgresql_pgdata }}
+    --log={{ sysbench_postgresql_logfile }}
+    stop
+    --mode=smart
+    --timeout=6000
+  register: _sysbench_postgresql_stop_smart
+  changed_when: _sysbench_postgresql_stop_smart != '0'
+  retries: 100
+  delay: 60
+  ignore_errors: true
+
+- name: Stop the PostgreSQL server (Fast Mode)
+  tags: ['run_sysbench']
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_ctl
+    --pgdata={{ sysbench_postgresql_pgdata }}
+    --log={{ sysbench_postgresql_logfile }}
+    stop
+    --mode=fast
+  register: _sysbench_postgresql_stop_fast
+  changed_when: _sysbench_postgresql_stop_fast != '0'
+  retries: 1
+  delay: 10
+  when:
+    - _sysbench_postgresql_stop_smart.rc != 0
+  ignore_errors: true
+
+- name: Stop the PostgreSQL server (Immediate Mode)
+  tags: ['run_sysbench']
+  become: true
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_ctl
+    --pgdata={{ sysbench_postgresql_pgdata }}
+    --log={{ sysbench_postgresql_logfile }}
+    stop
+    --mode=immediate
+  register: _sysbench_postgresql_stop_immediate
+  changed_when: _sysbench_postgresql_stop_immediate != '0'
+  retries: 1
+  delay: 10
+  when:
+    - _sysbench_postgresql_stop_fast.rc | default(0) != 0
+
+- name: Write sysbench run output to log file
+  become: true
+  become_flags: 'su - -c'
+  become_method: sudo
+  ansible.builtin.copy:
+    content: "{{ sysbench_postgresql_run_output.stdout }}"
+    dest: "{{ sysbench_telemetry_path }}/sysbench_tps.txt"
+    mode: '0755'
+  tags: ['run_sysbench']
+
+- name: Collect PostgreSQL database cluster control information
+  become: true
+  become_method: sudo
+  become_user: "{{ sysbench_postgresql_user }}"
+  ansible.builtin.command: >
+    /usr/local/pgsql/bin/pg_controldata
+    --pgdata={{ sysbench_postgresql_pgdata }}
+  register: _sysbench_postgresql_controldata_output
+  changed_when: false
+  tags: ['logs']
+
+- name: Write PostgreSQL database cluster control information to log file
+  become: true
+  become_method: sudo
+  become_user: root
+  ansible.builtin.copy:
+    content: "{{ _sysbench_postgresql_controldata_output.stdout }}"
+    dest: "{{ sysbench_postgresql_controldata_logfile }}"
+    mode: '0755'
+    owner: "{{ sysbench_postgresql_user }}"
+    group: "{{ sysbench_postgresql_user }}"
+    remote_src: true
+  tags: ['logs']
+
+- name: Copy telemetry data from each node to the localhost
+  tags: ['results']
+  ansible.posix.synchronize:
+    src: "{{ sysbench_telemetry_path }}/"
+    dest: "{{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/"
+    mode: pull
+    recursive: true
+    rsync_opts:
+      - "--ignore-existing"
+  delegate_to: localhost
+  become: false
+
+- name: Gather kernel logs from each node
+  tags: ['results']
+  become: true
+  become_method: sudo
+  ansible.builtin.command: journalctl -k
+  changed_when: false
+  register: journal_cmd
+
+- name: Save kernel logs to local file per node
+  ansible.builtin.copy:
+    content: "{{ journal_cmd.stdout }}"
+    dest: "{{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/dmesg.txt"
+    mode: '0755'
+  delegate_to: localhost
+  tags: ['results']
+
+- name: Gather memory fragmentation index on each node
+  tags: ['results']
+  become: true
+  become_method: sudo
+  ansible.builtin.command: cat /sys/kernel/debug/extfrag/extfrag_index
+  changed_when: false
+  register: extfrag_index_cmd
+
+- name: Save memory fragmentation index per node
+  ansible.builtin.copy:
+    content: "{{ extfrag_index_cmd.stdout }}"
+    dest: "{{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/extfrag_index.txt"
+    mode: '0755'
+  delegate_to: localhost
+  tags: ['results']
+
+- name: Gather memory unusable index on each node
+  tags: ['results']
+  become: true
+  become_method: sudo
+  ansible.builtin.command: cat /sys/kernel/debug/extfrag/unusable_index
+  changed_when: false
+  register: unusable_index_cmd
+
+- name: Save memory unusable index per node
+  ansible.builtin.copy:
+    content: "{{ unusable_index_cmd.stdout }}"
+    dest: "{{ topdir_path }}/workflows/sysbench/results/{{ inventory_hostname }}/unusable_index.txt"
+    mode: '0755'
+  delegate_to: localhost
+  tags: ['results']
+
+- name: Remove all results and telemetry directories on the node
+  become: true
+  become_flags: 'su - -c'
+  become_method: sudo
+  ansible.builtin.file:
+    path: "{{ item }}"
+    state: absent
+    mode: '0755'
+  loop:
+    - "{{ sysbench_telemetry_path }}/"
+  loop_control:
+    label: "Removing {{ item }}"
+  # tags: ['clean']
+  tags: ['results']
+
+- name: Remove all results and telemetry directories on the host
+  become: true
+  ansible.builtin.file:
+    path: "{{ item }}"
+    state: absent
+    mode: '0755'
+  loop:
+    - "{{ topdir_path }}/workflows/sysbench/results/"
+  delegate_to: localhost
+  # tags: ['clean']
+  tags: ['results']
+
+- name: Find directories under sysbench results target
+  vars:
+    sysbench_results_target: "{{ topdir_path }}/workflows/sysbench/results/"
+  ansible.builtin.find:
+    paths: "{{ sysbench_results_target }}"
+    recurse: false
+    file_type: directory
+  register: sysbench_results_dirs
+  delegate_to: localhost
+  tags: ['plot']
+
+- name: Check if sysbench_tps.txt exists in each directory
+  vars:
+    sysbench_results_target: "{{ topdir_path }}/workflows/sysbench/results/"
+  ansible.builtin.stat:
+    path: "{{ sysbench_results_target }}/{{ item.path | basename }}/sysbench_tps.txt"
+  register: sysbench_tps_exists
+  with_items: "{{ sysbench_results_dirs.files }}"
+  loop_control:
+    label: "Checking sysbench tps output file exists  {{ item.path }}/sysbench_tps.txt"
+  delegate_to: localhost
+  tags: ['plot']
+
+- name: Plot sysbench tps plot for each node
+  vars:
+    sysbench_results_target: "{{ topdir_path }}/workflows/sysbench/results/"
+    host_dir: "{{ item.item.path | basename }}"
+    output_image: "{{ sysbench_results_target }}/{{ host_dir }}/sysbench_tps_plot.png"
+  ansible.builtin.command: >
+    ./python/workflows/sysbench/sysbench-tps-plot.py
+    {{ sysbench_results_target }}/{{ host_dir }}/sysbench_tps.txt
+    --output {{ output_image }}
+  changed_when: false
+  tags: ['plot']
+  delegate_to: localhost
+  with_items: "{{ sysbench_tps_exists.results }}"
+  loop_control:
+    label: "Generating plot for {{ output_image }}"
+  when:
+    - "item.stat.exists"
+
+- name: Plot sysbench tps non-atomic Vs atomic
+  vars:
+    sysbench_results_target: "{{ topdir_path }}/workflows/sysbench/results/"
+    fs_type: "{{ item | regex_replace('^' + kdevops_host_prefix + '-', '') }}"
+    baseline_host: "{{ item }}"
+    legend1: "{{ fs_type }} innodb_doublewrite=ON"
+    file1: "{{ sysbench_results_target }}/{{ baseline_host }}/sysbench_tps.txt"
+    dev_host: "{{ item }}-dev"
+    legend2: "{{ fs_type }} innodb_doublewrite=OFF"
+    file2: "{{ sysbench_results_target }}/{{ dev_host }}/sysbench_tps.txt"
+    output_image: "{{ sysbench_results_target }}a_vs_b.png"
+  ansible.builtin.command: >
+    ./python/workflows/sysbench/sysbench-tps-compare.py
+    --legend1 \"{{ legend1 }}\"
+    --legend2 \"{{ legend2 }}\"
+    --output {{ output_image }}
+    {{ file1 }} {{ file2 }}
+  changed_when: false
+  tags: ['plot']
+  delegate_to: localhost
+  with_items:
+    - "{{ hostvars[inventory_hostname]['groups']['baseline'] }}"
+  when:
+    - 'kdevops_baseline_and_dev|bool'
+    - 'sysbench_host_is_baseline|bool'
+
+- name: Plot sysbench TPS variance
+  vars:
+    sysbench_results_target: "{{ topdir_path }}/workflows/sysbench/results/"
+    fs_type: "{{ item | regex_replace('^' + kdevops_host_prefix + '-', '') }}"
+    legend1: "{{ fs_type }} innodb_doublewrite=ON"
+    baseline_host: "{{ item }}"
+    file1: "{{ sysbench_results_target }}/{{ baseline_host }}/sysbench_tps.txt"
+    dev_host: "{{ item }}-dev"
+    legend2: "{{ fs_type }} innodb_doublewrite=OFF"
+    file2: "{{ sysbench_results_target }}/{{ dev_host }}/sysbench_tps.txt"
+  ansible.builtin.command: >
+    ./python/workflows/sysbench/sysbench-tps-variance.py
+    --legend1 \"{{ legend1 }}\"
+    --legend2 \"{{ legend2 }}\"
+    --dir {{ sysbench_results_target }}
+    {{ file1 }} {{ file2 }}
+  changed_when: false
+  tags: ['plot']
+  delegate_to: localhost
+  with_items:
+    - "{{ hostvars[inventory_hostname]['groups']['baseline'] }}"
+  when:
+    - 'kdevops_baseline_and_dev|bool'
+    - 'sysbench_host_is_baseline|bool'
diff --git a/playbooks/roles/sysbench/templates/postgresql-conf-000.conf.j2 b/playbooks/roles/sysbench/templates/postgresql-conf-000.conf.j2
new file mode 100644
index 0000000..8625116
--- /dev/null
+++ b/playbooks/roles/sysbench/templates/postgresql-conf-000.conf.j2
@@ -0,0 +1,820 @@
+# -----------------------------
+# PostgreSQL configuration file
+# -----------------------------
+#
+# This file consists of lines of the form:
+#
+#   name = value
+#
+# (The "=" is optional.)  Whitespace may be used.  Comments are introduced with
+# "#" anywhere on a line.  The complete list of parameter names and allowed
+# values can be found in the PostgreSQL documentation.
+#
+# The commented-out settings shown in this file represent the default values.
+# Re-commenting a setting is NOT sufficient to revert it to the default value;
+# you need to reload the server.
+#
+# This file is read on server startup and when the server receives a SIGHUP
+# signal.  If you edit the file on a running system, you have to SIGHUP the
+# server for the changes to take effect, run "pg_ctl reload", or execute
+# "SELECT pg_reload_conf()".  Some parameters, which are marked below,
+# require a server shutdown and restart to take effect.
+#
+# Any parameter can also be given as a command-line option to the server, e.g.,
+# "postgres -c log_connections=on".  Some parameters can be changed at run time
+# with the "SET" SQL command.
+#
+# Memory units:  B  = bytes            Time units:  us  = microseconds
+#                kB = kilobytes                     ms  = milliseconds
+#                MB = megabytes                     s   = seconds
+#                GB = gigabytes                     min = minutes
+#                TB = terabytes                     h   = hours
+#                                                   d   = days
+
+
+#------------------------------------------------------------------------------
+# FILE LOCATIONS
+#------------------------------------------------------------------------------
+
+# The default values of these variables are driven from the -D command-line
+# option or PGDATA environment variable, represented here as ConfigDir.
+
+#data_directory = 'ConfigDir'		# use data in another directory
+					# (change requires restart)
+#hba_file = 'ConfigDir/pg_hba.conf'	# host-based authentication file
+					# (change requires restart)
+#ident_file = 'ConfigDir/pg_ident.conf'	# ident configuration file
+					# (change requires restart)
+
+# If external_pid_file is not explicitly set, no extra PID file is written.
+#external_pid_file = ''			# write an extra PID file
+					# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# CONNECTIONS AND AUTHENTICATION
+#------------------------------------------------------------------------------
+
+# - Connection Settings -
+
+listen_addresses = '*'		# what IP address(es) to listen on;
+					# comma-separated list of addresses;
+					# defaults to 'localhost'; use '*' for all
+					# (change requires restart)
+port = {{ sysbench_local_db_port }}				# (change requires restart)
+max_connections = 200			# (change requires restart)
+#reserved_connections = 0		# (change requires restart)
+#superuser_reserved_connections = 3	# (change requires restart)
+#unix_socket_directories = '/tmp'	# comma-separated list of directories
+					# (change requires restart)
+#unix_socket_group = ''			# (change requires restart)
+#unix_socket_permissions = 0777		# begin with 0 to use octal notation
+					# (change requires restart)
+#bonjour = off				# advertise server via Bonjour
+					# (change requires restart)
+#bonjour_name = ''			# defaults to the computer name
+					# (change requires restart)
+
+# - TCP settings -
+# see "man tcp" for details
+
+#tcp_keepalives_idle = 0		# TCP_KEEPIDLE, in seconds;
+					# 0 selects the system default
+#tcp_keepalives_interval = 0		# TCP_KEEPINTVL, in seconds;
+					# 0 selects the system default
+#tcp_keepalives_count = 0		# TCP_KEEPCNT;
+					# 0 selects the system default
+#tcp_user_timeout = 0			# TCP_USER_TIMEOUT, in milliseconds;
+					# 0 selects the system default
+
+#client_connection_check_interval = 0	# time between checks for client
+					# disconnection while running queries;
+					# 0 for never
+
+# - Authentication -
+
+#authentication_timeout = 1min		# 1s-600s
+#password_encryption = scram-sha-256	# scram-sha-256 or md5
+#scram_iterations = 4096
+#db_user_namespace = off
+
+# GSSAPI using Kerberos
+#krb_server_keyfile = 'FILE:${sysconfdir}/krb5.keytab'
+#krb_caseins_users = off
+#gss_accept_delegation = off
+
+# - SSL -
+
+#ssl = off
+#ssl_ca_file = ''
+#ssl_cert_file = 'server.crt'
+#ssl_crl_file = ''
+#ssl_crl_dir = ''
+#ssl_key_file = 'server.key'
+#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
+#ssl_prefer_server_ciphers = on
+#ssl_ecdh_curve = 'prime256v1'
+#ssl_min_protocol_version = 'TLSv1.2'
+#ssl_max_protocol_version = ''
+#ssl_dh_params_file = ''
+#ssl_passphrase_command = ''
+#ssl_passphrase_command_supports_reload = off
+
+
+#------------------------------------------------------------------------------
+# RESOURCE USAGE (except WAL)
+#------------------------------------------------------------------------------
+
+# - Memory -
+
+shared_buffers = 8GB			# min 128kB
+					# (change requires restart)
+#huge_pages = try			# on, off, or try
+					# (change requires restart)
+#huge_page_size = 0			# zero for system default
+					# (change requires restart)
+temp_buffers = 4GB			# min 800kB
+#max_prepared_transactions = 0		# zero disables the feature
+					# (change requires restart)
+# Caution: it is not advisable to set max_prepared_transactions nonzero unless
+# you actively intend to use prepared transactions.
+work_mem = 512MB				# min 64kB
+#hash_mem_multiplier = 2.0		# 1-1000.0 multiplier on hash table work_mem
+maintenance_work_mem = 1GB		# min 1MB
+autovacuum_work_mem = -1		# min 1MB, or -1 to use maintenance_work_mem
+#logical_decoding_work_mem = 64MB	# min 64kB
+max_stack_depth = 7MB			# min 100kB
+#shared_memory_type = mmap		# the default is the first option
+					# supported by the operating system:
+					#   mmap
+					#   sysv
+					#   windows
+					# (change requires restart)
+dynamic_shared_memory_type = posix	# the default is usually the first option
+					# supported by the operating system:
+					#   posix
+					#   sysv
+					#   windows
+					#   mmap
+					# (change requires restart)
+#min_dynamic_shared_memory = 0MB	# (change requires restart)
+#vacuum_buffer_usage_limit = 256kB	# size of vacuum and analyze buffer access strategy ring;
+					# 0 to disable vacuum buffer access strategy;
+					# range 128kB to 16GB
+
+# - Disk -
+
+#temp_file_limit = -1			# limits per-process temp file space
+					# in kilobytes, or -1 for no limit
+
+# - Kernel Resources -
+
+#max_files_per_process = 1000		# min 64
+					# (change requires restart)
+
+# - Cost-Based Vacuum Delay -
+
+#vacuum_cost_delay = 0			# 0-100 milliseconds (0 disables)
+#vacuum_cost_page_hit = 1		# 0-10000 credits
+#vacuum_cost_page_miss = 2		# 0-10000 credits
+#vacuum_cost_page_dirty = 20		# 0-10000 credits
+vacuum_cost_limit = 500		# 1-10000 credits
+
+# - Background Writer -
+
+#bgwriter_delay = 200ms			# 10-10000ms between rounds
+#bgwriter_lru_maxpages = 100		# max buffers written/round, 0 disables
+#bgwriter_lru_multiplier = 2.0		# 0-10.0 multiplier on buffers scanned/round
+#bgwriter_flush_after = 0		# measured in pages, 0 disables
+
+# - Asynchronous Behavior -
+
+#backend_flush_after = 0		# measured in pages, 0 disables
+effective_io_concurrency = 1000		# 1-1000; 0 disables prefetching
+#maintenance_io_concurrency = 10	# 1-1000; 0 disables prefetching
+max_worker_processes = 128		# (change requires restart)
+max_parallel_workers_per_gather = 64	# limited by max_parallel_workers
+max_parallel_maintenance_workers = 16	# limited by max_parallel_workers
+max_parallel_workers = 128		# number of max_worker_processes that
+					# can be used in parallel operations
+#parallel_leader_participation = on
+#old_snapshot_threshold = -1		# 1min-60d; -1 disables; 0 is immediate
+					# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# WRITE-AHEAD LOG
+#------------------------------------------------------------------------------
+
+# - Settings -
+
+#wal_level = replica			# minimal, replica, or logical
+					# (change requires restart)
+#fsync = on				# flush data to disk for crash safety
+					# (turning this off can cause
+					# unrecoverable data corruption)
+synchronous_commit = off		# synchronization level;
+					# off, local, remote_write, remote_apply, or on
+wal_sync_method = fdatasync		# the default is the first option
+					# supported by the operating system:
+					#   open_datasync
+					#   fdatasync (default on Linux and FreeBSD)
+					#   fsync
+					#   fsync_writethrough
+					#   open_sync
+full_page_writes = {{ sysbench_postgresql_full_page_writes }}			# recover from partial page writes
+#wal_log_hints = off			# also do full page writes of non-critical updates
+					# (change requires restart)
+wal_compression = off			# enables compression of full-page writes;
+					# off, pglz, lz4, zstd, or on
+#wal_init_zero = on			# zero-fill new WAL files
+#wal_recycle = on			# recycle WAL files
+#wal_buffers = -1			# min 32kB, -1 sets based on shared_buffers
+					# (change requires restart)
+#wal_writer_delay = 200ms		# 1-10000 milliseconds
+#wal_writer_flush_after = 1MB		# measured in pages, 0 disables
+#wal_skip_threshold = 2MB
+
+#commit_delay = 0			# range 0-100000, in microseconds
+#commit_siblings = 5			# range 1-1000
+
+# - Checkpoints -
+
+checkpoint_timeout = 30min		# range 30s-1d
+checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
+#checkpoint_flush_after = 0		# measured in pages, 0 disables
+#checkpoint_warning = 30s		# 0 disables
+max_wal_size = 16GB
+min_wal_size = 1GB
+
+# - Prefetching during recovery -
+
+#recovery_prefetch = try		# prefetch pages referenced in the WAL?
+#wal_decode_buffer_size = 512kB		# lookahead window used for prefetching
+					# (change requires restart)
+
+# - Archiving -
+
+#archive_mode = off		# enables archiving; off, on, or always
+				# (change requires restart)
+#archive_library = ''		# library to use to archive a WAL file
+				# (empty string indicates archive_command should
+				# be used)
+#archive_command = ''		# command to use to archive a WAL file
+				# placeholders: %p = path of file to archive
+				#               %f = file name only
+				# e.g. 'test ! -f /mnt/server/archivedir/%f && cp %p /mnt/server/archivedir/%f'
+#archive_timeout = 0		# force a WAL file switch after this
+				# number of seconds; 0 disables
+
+# - Archive Recovery -
+
+# These are only used in recovery mode.
+
+#restore_command = ''		# command to use to restore an archived WAL file
+				# placeholders: %p = path of file to restore
+				#               %f = file name only
+				# e.g. 'cp /mnt/server/archivedir/%f %p'
+#archive_cleanup_command = ''	# command to execute at every restartpoint
+#recovery_end_command = ''	# command to execute at completion of recovery
+
+# - Recovery Target -
+
+# Set these only when performing a targeted recovery.
+
+#recovery_target = ''		# 'immediate' to end recovery as soon as a
+                                # consistent state is reached
+				# (change requires restart)
+#recovery_target_name = ''	# the named restore point to which recovery will proceed
+				# (change requires restart)
+#recovery_target_time = ''	# the time stamp up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_xid = ''	# the transaction ID up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_lsn = ''	# the WAL LSN up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_inclusive = on # Specifies whether to stop:
+				# just after the specified recovery target (on)
+				# just before the recovery target (off)
+				# (change requires restart)
+#recovery_target_timeline = 'latest'	# 'current', 'latest', or timeline ID
+				# (change requires restart)
+#recovery_target_action = 'pause'	# 'pause', 'promote', 'shutdown'
+				# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# REPLICATION
+#------------------------------------------------------------------------------
+
+# - Sending Servers -
+
+# Set these on the primary and on any standby that will send replication data.
+
+#max_wal_senders = 10		# max number of walsender processes
+				# (change requires restart)
+#max_replication_slots = 10	# max number of replication slots
+				# (change requires restart)
+#wal_keep_size = 0		# in megabytes; 0 disables
+#max_slot_wal_keep_size = -1	# in megabytes; -1 disables
+#wal_sender_timeout = 60s	# in milliseconds; 0 disables
+#track_commit_timestamp = off	# collect timestamp of transaction commit
+				# (change requires restart)
+
+# - Primary Server -
+
+# These settings are ignored on a standby server.
+
+#synchronous_standby_names = ''	# standby servers that provide sync rep
+				# method to choose sync standbys, number of sync standbys,
+				# and comma-separated list of application_name
+				# from standby(s); '*' = all
+
+# - Standby Servers -
+
+# These settings are ignored on a primary server.
+
+#primary_conninfo = ''			# connection string to sending server
+#primary_slot_name = ''			# replication slot on sending server
+#hot_standby = on			# "off" disallows queries during recovery
+					# (change requires restart)
+#max_standby_archive_delay = 30s	# max delay before canceling queries
+					# when reading WAL from archive;
+					# -1 allows indefinite delay
+#max_standby_streaming_delay = 30s	# max delay before canceling queries
+					# when reading streaming WAL;
+					# -1 allows indefinite delay
+#wal_receiver_create_temp_slot = off	# create temp slot if primary_slot_name
+					# is not set
+#wal_receiver_status_interval = 10s	# send replies at least this often
+					# 0 disables
+#hot_standby_feedback = off		# send info from standby to prevent
+					# query conflicts
+#wal_receiver_timeout = 60s		# time that receiver waits for
+					# communication from primary
+					# in milliseconds; 0 disables
+#wal_retrieve_retry_interval = 5s	# time to wait before retrying to
+					# retrieve WAL after a failed attempt
+#recovery_min_apply_delay = 0		# minimum delay for applying changes during recovery
+
+# - Subscribers -
+
+# These settings are ignored on a publisher.
+
+#max_logical_replication_workers = 4	# taken from max_worker_processes
+					# (change requires restart)
+#max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers
+#max_parallel_apply_workers_per_subscription = 2	# taken from max_logical_replication_workers
+
+
+#------------------------------------------------------------------------------
+# QUERY TUNING
+#------------------------------------------------------------------------------
+
+# - Planner Method Configuration -
+
+#enable_async_append = on
+#enable_bitmapscan = on
+#enable_gathermerge = on
+#enable_hashagg = on
+#enable_hashjoin = on
+#enable_incremental_sort = on
+#enable_indexscan = on
+#enable_indexonlyscan = on
+#enable_material = on
+#enable_memoize = on
+#enable_mergejoin = on
+#enable_nestloop = on
+#enable_parallel_append = on
+#enable_parallel_hash = on
+#enable_partition_pruning = on
+#enable_partitionwise_join = off
+#enable_partitionwise_aggregate = off
+#enable_presorted_aggregate = on
+#enable_seqscan = on
+#enable_sort = on
+#enable_tidscan = on
+
+# - Planner Cost Constants -
+
+#seq_page_cost = 1.0			# measured on an arbitrary scale
+random_page_cost = 1.1			# same scale as above
+#cpu_tuple_cost = 0.01			# same scale as above
+#cpu_index_tuple_cost = 0.005		# same scale as above
+#cpu_operator_cost = 0.0025		# same scale as above
+#parallel_setup_cost = 1000.0	# same scale as above
+#parallel_tuple_cost = 0.1		# same scale as above
+#min_parallel_table_scan_size = 8MB
+#min_parallel_index_scan_size = 512kB
+effective_cache_size = 16GB
+
+#jit_above_cost = 100000		# perform JIT compilation if available
+					# and query more expensive than this;
+					# -1 disables
+#jit_inline_above_cost = 500000		# inline small functions if query is
+					# more expensive than this; -1 disables
+#jit_optimize_above_cost = 500000	# use expensive JIT optimizations if
+					# query is more expensive than this;
+					# -1 disables
+
+# - Genetic Query Optimizer -
+
+#geqo = on
+#geqo_threshold = 12
+#geqo_effort = 5			# range 1-10
+#geqo_pool_size = 0			# selects default based on effort
+#geqo_generations = 0			# selects default based on effort
+#geqo_selection_bias = 2.0		# range 1.5-2.0
+#geqo_seed = 0.0			# range 0.0-1.0
+
+# - Other Planner Options -
+
+#default_statistics_target = 100	# range 1-10000
+#constraint_exclusion = partition	# on, off, or partition
+#cursor_tuple_fraction = 0.1		# range 0.0-1.0
+#from_collapse_limit = 8
+#jit = on				# allow JIT compilation
+#join_collapse_limit = 8		# 1 disables collapsing of explicit
+					# JOIN clauses
+#plan_cache_mode = auto			# auto, force_generic_plan or
+					# force_custom_plan
+#recursive_worktable_factor = 10.0	# range 0.001-1000000
+
+
+#------------------------------------------------------------------------------
+# REPORTING AND LOGGING
+#------------------------------------------------------------------------------
+
+# - Where to Log -
+
+#log_destination = 'stderr'		# Valid values are combinations of
+					# stderr, csvlog, jsonlog, syslog, and
+					# eventlog, depending on platform.
+					# csvlog and jsonlog require
+					# logging_collector to be on.
+
+# This is used when logging to stderr:
+#logging_collector = off		# Enable capturing of stderr, jsonlog,
+					# and csvlog into log files. Required
+					# to be on for csvlogs and jsonlogs.
+					# (change requires restart)
+
+# These are only used if logging_collector is on:
+#log_directory = 'log'			# directory where log files are written,
+					# can be absolute or relative to PGDATA
+#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern,
+					# can include strftime() escapes
+#log_file_mode = 0600			# creation mode for log files,
+					# begin with 0 to use octal notation
+#log_rotation_age = 1d			# Automatic rotation of logfiles will
+					# happen after that time.  0 disables.
+#log_rotation_size = 10MB		# Automatic rotation of logfiles will
+					# happen after that much log output.
+					# 0 disables.
+#log_truncate_on_rotation = off		# If on, an existing log file with the
+					# same name as the new log file will be
+					# truncated rather than appended to.
+					# But such truncation only occurs on
+					# time-driven rotation, not on restarts
+					# or size-driven rotation.  Default is
+					# off, meaning append to existing files
+					# in all cases.
+
+# These are relevant when logging to syslog:
+#syslog_facility = 'LOCAL0'
+#syslog_ident = 'postgres'
+#syslog_sequence_numbers = on
+#syslog_split_messages = on
+
+# This is only relevant when logging to eventlog (Windows):
+# (change requires restart)
+#event_source = 'PostgreSQL'
+
+# - When to Log -
+
+#log_min_messages = warning		# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   info
+					#   notice
+					#   warning
+					#   error
+					#   log
+					#   fatal
+					#   panic
+
+#log_min_error_statement = error	# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   info
+					#   notice
+					#   warning
+					#   error
+					#   log
+					#   fatal
+					#   panic (effectively off)
+
+#log_min_duration_statement = -1	# -1 is disabled, 0 logs all statements
+					# and their durations, > 0 logs only
+					# statements running at least this number
+					# of milliseconds
+
+#log_min_duration_sample = -1		# -1 is disabled, 0 logs a sample of statements
+					# and their durations, > 0 logs only a sample of
+					# statements running at least this number
+					# of milliseconds;
+					# sample fraction is determined by log_statement_sample_rate
+
+#log_statement_sample_rate = 1.0	# fraction of logged statements exceeding
+					# log_min_duration_sample to be logged;
+					# 1.0 logs all such statements, 0.0 never logs
+
+
+#log_transaction_sample_rate = 0.0	# fraction of transactions whose statements
+					# are logged regardless of their duration; 1.0 logs all
+					# statements from all transactions, 0.0 never logs
+
+#log_startup_progress_interval = 10s	# Time between progress updates for
+					# long-running startup operations.
+					# 0 disables the feature, > 0 indicates
+					# the interval in milliseconds.
+
+# - What to Log -
+
+#debug_print_parse = off
+#debug_print_rewritten = off
+#debug_print_plan = off
+#debug_pretty_print = on
+#log_autovacuum_min_duration = 10min	# log autovacuum activity;
+					# -1 disables, 0 logs all actions and
+					# their durations, > 0 logs only
+					# actions running at least this number
+					# of milliseconds.
+#log_checkpoints = on
+#log_connections = off
+#log_disconnections = off
+#log_duration = off
+#log_error_verbosity = default		# terse, default, or verbose messages
+#log_hostname = off
+#log_line_prefix = '%m [%p] '		# special values:
+					#   %a = application name
+					#   %u = user name
+					#   %d = database name
+					#   %r = remote host and port
+					#   %h = remote host
+					#   %b = backend type
+					#   %p = process ID
+					#   %P = process ID of parallel group leader
+					#   %t = timestamp without milliseconds
+					#   %m = timestamp with milliseconds
+					#   %n = timestamp with milliseconds (as a Unix epoch)
+					#   %Q = query ID (0 if none or not computed)
+					#   %i = command tag
+					#   %e = SQL state
+					#   %c = session ID
+					#   %l = session line number
+					#   %s = session start timestamp
+					#   %v = virtual transaction ID
+					#   %x = transaction ID (0 if none)
+					#   %q = stop here in non-session
+					#        processes
+					#   %% = '%'
+					# e.g. '<%u%%%d> '
+#log_lock_waits = off			# log lock waits >= deadlock_timeout
+#log_recovery_conflict_waits = off	# log standby recovery conflict waits
+					# >= deadlock_timeout
+#log_parameter_max_length = -1		# when logging statements, limit logged
+					# bind-parameter values to N bytes;
+					# -1 means print in full, 0 disables
+#log_parameter_max_length_on_error = 0	# when logging an error, limit logged
+					# bind-parameter values to N bytes;
+					# -1 means print in full, 0 disables
+#log_statement = 'none'			# none, ddl, mod, all
+#log_replication_commands = off
+#log_temp_files = -1			# log temporary files equal or larger
+					# than the specified size in kilobytes;
+					# -1 disables, 0 logs all temp files
+#log_timezone = 'GMT'
+
+# - Process Title -
+
+#cluster_name = ''			# added to process titles if nonempty
+					# (change requires restart)
+#update_process_title = on
+
+
+#------------------------------------------------------------------------------
+# STATISTICS
+#------------------------------------------------------------------------------
+
+# - Cumulative Query and Index Statistics -
+
+#track_activities = on
+#track_activity_query_size = 1024	# (change requires restart)
+#track_counts = on
+#track_io_timing = off
+#track_wal_io_timing = off
+#track_functions = none			# none, pl, all
+#stats_fetch_consistency = cache	# cache, none, snapshot
+
+
+# - Monitoring -
+
+#compute_query_id = auto
+#log_statement_stats = off
+#log_parser_stats = off
+#log_planner_stats = off
+#log_executor_stats = off
+
+
+#------------------------------------------------------------------------------
+# AUTOVACUUM
+#------------------------------------------------------------------------------
+
+#autovacuum = on			# Enable autovacuum subprocess?  'on'
+					# requires track_counts to also be on.
+#autovacuum_max_workers = 3		# max number of autovacuum subprocesses
+					# (change requires restart)
+autovacuum_naptime = 10s		# time between autovacuum runs
+#autovacuum_vacuum_threshold = 50	# min number of row updates before
+					# vacuum
+#autovacuum_vacuum_insert_threshold = 1000	# min number of row inserts
+					# before vacuum; -1 disables insert
+					# vacuums
+#autovacuum_analyze_threshold = 50	# min number of row updates before
+					# analyze
+autovacuum_vacuum_scale_factor = 0.05	# fraction of table size before vacuum
+autovacuum_vacuum_insert_scale_factor = 0.05	# fraction of inserts over table
+					# size before insert vacuum
+#autovacuum_analyze_scale_factor = 0.1	# fraction of table size before analyze
+#autovacuum_freeze_max_age = 200000000	# maximum XID age before forced vacuum
+					# (change requires restart)
+#autovacuum_multixact_freeze_max_age = 400000000	# maximum multixact age
+					# before forced vacuum
+					# (change requires restart)
+#autovacuum_vacuum_cost_delay = 2ms	# default vacuum cost delay for
+					# autovacuum, in milliseconds;
+					# -1 means use vacuum_cost_delay
+#autovacuum_vacuum_cost_limit = -1	# default vacuum cost limit for
+					# autovacuum, -1 means use
+					# vacuum_cost_limit
+
+
+#------------------------------------------------------------------------------
+# CLIENT CONNECTION DEFAULTS
+#------------------------------------------------------------------------------
+
+# - Statement Behavior -
+
+#client_min_messages = notice		# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   log
+					#   notice
+					#   warning
+					#   error
+#search_path = '"$user", public'	# schema names
+#row_security = on
+#default_table_access_method = 'heap'
+#default_tablespace = ''		# a tablespace name, '' uses the default
+#default_toast_compression = 'pglz'	# 'pglz' or 'lz4'
+#temp_tablespaces = ''			# a list of tablespace names, '' uses
+					# only default tablespace
+#check_function_bodies = on
+#default_transaction_isolation = 'read committed'
+#default_transaction_read_only = off
+#default_transaction_deferrable = off
+#session_replication_role = 'origin'
+#statement_timeout = 0			# in milliseconds, 0 is disabled
+#lock_timeout = 0			# in milliseconds, 0 is disabled
+#idle_in_transaction_session_timeout = 0	# in milliseconds, 0 is disabled
+#idle_session_timeout = 0		# in milliseconds, 0 is disabled
+#vacuum_freeze_table_age = 150000000
+#vacuum_freeze_min_age = 50000000
+#vacuum_failsafe_age = 1600000000
+#vacuum_multixact_freeze_table_age = 150000000
+#vacuum_multixact_freeze_min_age = 5000000
+#vacuum_multixact_failsafe_age = 1600000000
+#bytea_output = 'hex'			# hex, escape
+#xmlbinary = 'base64'
+#xmloption = 'content'
+#gin_pending_list_limit = 4MB
+#createrole_self_grant = ''		# set and/or inherit
+
+# - Locale and Formatting -
+
+#datestyle = 'iso, mdy'
+#intervalstyle = 'postgres'
+#timezone = 'GMT'
+#timezone_abbreviations = 'Default'     # Select the set of available time zone
+					# abbreviations.  Currently, there are
+					#   Default
+					#   Australia (historical usage)
+					#   India
+					# You can create your own file in
+					# share/timezonesets/.
+#extra_float_digits = 1			# min -15, max 3; any value >0 actually
+					# selects precise output mode
+#client_encoding = sql_ascii		# actually, defaults to database
+					# encoding
+
+# These settings are initialized by initdb, but they can be changed.
+#lc_messages = ''			# locale for system error message
+					# strings
+#lc_monetary = 'C'			# locale for monetary formatting
+#lc_numeric = 'C'			# locale for number formatting
+#lc_time = 'C'				# locale for time formatting
+
+#icu_validation_level = warning		# report ICU locale validation
+					# errors at the given level
+
+# default configuration for text search
+#default_text_search_config = 'pg_catalog.simple'
+
+# - Shared Library Preloading -
+
+#local_preload_libraries = ''
+#session_preload_libraries = ''
+#shared_preload_libraries = ''	# (change requires restart)
+#jit_provider = 'llvmjit'		# JIT library to use
+
+# - Other Defaults -
+
+#dynamic_library_path = '$libdir'
+#gin_fuzzy_search_limit = 0
+
+
+#------------------------------------------------------------------------------
+# LOCK MANAGEMENT
+#------------------------------------------------------------------------------
+
+#deadlock_timeout = 1s
+#max_locks_per_transaction = 64		# min 10
+					# (change requires restart)
+#max_pred_locks_per_transaction = 64	# min 10
+					# (change requires restart)
+#max_pred_locks_per_relation = -2	# negative values mean
+					# (max_pred_locks_per_transaction
+					#  / -max_pred_locks_per_relation) - 1
+#max_pred_locks_per_page = 2            # min 0
+
+
+#------------------------------------------------------------------------------
+# VERSION AND PLATFORM COMPATIBILITY
+#------------------------------------------------------------------------------
+
+# - Previous PostgreSQL Versions -
+
+#array_nulls = on
+#backslash_quote = safe_encoding	# on, off, or safe_encoding
+#escape_string_warning = on
+#lo_compat_privileges = off
+#quote_all_identifiers = off
+#standard_conforming_strings = on
+#synchronize_seqscans = on
+
+# - Other Platforms and Clients -
+
+#transform_null_equals = off
+
+
+#------------------------------------------------------------------------------
+# ERROR HANDLING
+#------------------------------------------------------------------------------
+
+#exit_on_error = off			# terminate session on any error?
+#restart_after_crash = on		# reinitialize after backend crash?
+#data_sync_retry = off			# retry or panic on failure to fsync
+					# data?
+					# (change requires restart)
+#recovery_init_sync_method = fsync	# fsync, syncfs (Linux 5.8+)
+
+
+#------------------------------------------------------------------------------
+# CONFIG FILE INCLUDES
+#------------------------------------------------------------------------------
+
+# These options allow settings to be loaded from files other than the
+# default postgresql.conf.  Note that these are directives, not variable
+# assignments, so they can usefully be given more than once.
+
+#include_dir = '...'			# include files ending in '.conf' from
+					# a directory, e.g., 'conf.d'
+#include_if_exists = '...'		# include file only if it exists
+#include = '...'			# include file
+
+
+#------------------------------------------------------------------------------
+# CUSTOMIZED OPTIONS
+#------------------------------------------------------------------------------
+
+# Add settings for extensions here
diff --git a/playbooks/roles/sysbench/templates/postgresql-conf-default.conf.j2 b/playbooks/roles/sysbench/templates/postgresql-conf-default.conf.j2
new file mode 100644
index 0000000..9297d8a
--- /dev/null
+++ b/playbooks/roles/sysbench/templates/postgresql-conf-default.conf.j2
@@ -0,0 +1,820 @@
+# -----------------------------
+# PostgreSQL configuration file
+# -----------------------------
+#
+# This file consists of lines of the form:
+#
+#   name = value
+#
+# (The "=" is optional.)  Whitespace may be used.  Comments are introduced with
+# "#" anywhere on a line.  The complete list of parameter names and allowed
+# values can be found in the PostgreSQL documentation.
+#
+# The commented-out settings shown in this file represent the default values.
+# Re-commenting a setting is NOT sufficient to revert it to the default value;
+# you need to reload the server.
+#
+# This file is read on server startup and when the server receives a SIGHUP
+# signal.  If you edit the file on a running system, you have to SIGHUP the
+# server for the changes to take effect, run "pg_ctl reload", or execute
+# "SELECT pg_reload_conf()".  Some parameters, which are marked below,
+# require a server shutdown and restart to take effect.
+#
+# Any parameter can also be given as a command-line option to the server, e.g.,
+# "postgres -c log_connections=on".  Some parameters can be changed at run time
+# with the "SET" SQL command.
+#
+# Memory units:  B  = bytes            Time units:  us  = microseconds
+#                kB = kilobytes                     ms  = milliseconds
+#                MB = megabytes                     s   = seconds
+#                GB = gigabytes                     min = minutes
+#                TB = terabytes                     h   = hours
+#                                                   d   = days
+
+
+#------------------------------------------------------------------------------
+# FILE LOCATIONS
+#------------------------------------------------------------------------------
+
+# The default values of these variables are driven from the -D command-line
+# option or PGDATA environment variable, represented here as ConfigDir.
+
+#data_directory = 'ConfigDir'		# use data in another directory
+					# (change requires restart)
+#hba_file = 'ConfigDir/pg_hba.conf'	# host-based authentication file
+					# (change requires restart)
+#ident_file = 'ConfigDir/pg_ident.conf'	# ident configuration file
+					# (change requires restart)
+
+# If external_pid_file is not explicitly set, no extra PID file is written.
+#external_pid_file = ''			# write an extra PID file
+					# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# CONNECTIONS AND AUTHENTICATION
+#------------------------------------------------------------------------------
+
+# - Connection Settings -
+
+#listen_addresses = 'localhost'		# what IP address(es) to listen on;
+					# comma-separated list of addresses;
+					# defaults to 'localhost'; use '*' for all
+					# (change requires restart)
+port = {{ sysbench_local_db_port }}				# (change requires restart)
+#max_connections = 100			# (change requires restart)
+#reserved_connections = 0		# (change requires restart)
+#superuser_reserved_connections = 3	# (change requires restart)
+#unix_socket_directories = '/tmp'	# comma-separated list of directories
+					# (change requires restart)
+#unix_socket_group = ''			# (change requires restart)
+#unix_socket_permissions = 0777		# begin with 0 to use octal notation
+					# (change requires restart)
+#bonjour = off				# advertise server via Bonjour
+					# (change requires restart)
+#bonjour_name = ''			# defaults to the computer name
+					# (change requires restart)
+
+# - TCP settings -
+# see "man tcp" for details
+
+#tcp_keepalives_idle = 0		# TCP_KEEPIDLE, in seconds;
+					# 0 selects the system default
+#tcp_keepalives_interval = 0		# TCP_KEEPINTVL, in seconds;
+					# 0 selects the system default
+#tcp_keepalives_count = 0		# TCP_KEEPCNT;
+					# 0 selects the system default
+#tcp_user_timeout = 0			# TCP_USER_TIMEOUT, in milliseconds;
+					# 0 selects the system default
+
+#client_connection_check_interval = 0	# time between checks for client
+					# disconnection while running queries;
+					# 0 for never
+
+# - Authentication -
+
+#authentication_timeout = 1min		# 1s-600s
+#password_encryption = scram-sha-256	# scram-sha-256 or md5
+#scram_iterations = 4096
+#db_user_namespace = off
+
+# GSSAPI using Kerberos
+#krb_server_keyfile = 'FILE:${sysconfdir}/krb5.keytab'
+#krb_caseins_users = off
+#gss_accept_delegation = off
+
+# - SSL -
+
+#ssl = off
+#ssl_ca_file = ''
+#ssl_cert_file = 'server.crt'
+#ssl_crl_file = ''
+#ssl_crl_dir = ''
+#ssl_key_file = 'server.key'
+#ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL' # allowed SSL ciphers
+#ssl_prefer_server_ciphers = on
+#ssl_ecdh_curve = 'prime256v1'
+#ssl_min_protocol_version = 'TLSv1.2'
+#ssl_max_protocol_version = ''
+#ssl_dh_params_file = ''
+#ssl_passphrase_command = ''
+#ssl_passphrase_command_supports_reload = off
+
+
+#------------------------------------------------------------------------------
+# RESOURCE USAGE (except WAL)
+#------------------------------------------------------------------------------
+
+# - Memory -
+
+#shared_buffers = 128MB			# min 128kB
+					# (change requires restart)
+#huge_pages = try			# on, off, or try
+					# (change requires restart)
+#huge_page_size = 0			# zero for system default
+					# (change requires restart)
+#temp_buffers = 8MB			# min 800kB
+#max_prepared_transactions = 0		# zero disables the feature
+					# (change requires restart)
+# Caution: it is not advisable to set max_prepared_transactions nonzero unless
+# you actively intend to use prepared transactions.
+#work_mem = 4MB				# min 64kB
+#hash_mem_multiplier = 2.0		# 1-1000.0 multiplier on hash table work_mem
+#maintenance_work_mem = 64MB		# min 1MB
+#autovacuum_work_mem = -1		# min 1MB, or -1 to use maintenance_work_mem
+#logical_decoding_work_mem = 64MB	# min 64kB
+#max_stack_depth = 2MB			# min 100kB
+#shared_memory_type = mmap		# the default is the first option
+					# supported by the operating system:
+					#   mmap
+					#   sysv
+					#   windows
+					# (change requires restart)
+#dynamic_shared_memory_type = posix	# the default is usually the first option
+					# supported by the operating system:
+					#   posix
+					#   sysv
+					#   windows
+					#   mmap
+					# (change requires restart)
+#min_dynamic_shared_memory = 0MB	# (change requires restart)
+#vacuum_buffer_usage_limit = 256kB	# size of vacuum and analyze buffer access strategy ring;
+					# 0 to disable vacuum buffer access strategy;
+					# range 128kB to 16GB
+
+# - Disk -
+
+#temp_file_limit = -1			# limits per-process temp file space
+					# in kilobytes, or -1 for no limit
+
+# - Kernel Resources -
+
+#max_files_per_process = 1000		# min 64
+					# (change requires restart)
+
+# - Cost-Based Vacuum Delay -
+
+#vacuum_cost_delay = 0			# 0-100 milliseconds (0 disables)
+#vacuum_cost_page_hit = 1		# 0-10000 credits
+#vacuum_cost_page_miss = 2		# 0-10000 credits
+#vacuum_cost_page_dirty = 20		# 0-10000 credits
+#vacuum_cost_limit = 200		# 1-10000 credits
+
+# - Background Writer -
+
+#bgwriter_delay = 200ms			# 10-10000ms between rounds
+#bgwriter_lru_maxpages = 100		# max buffers written/round, 0 disables
+#bgwriter_lru_multiplier = 2.0		# 0-10.0 multiplier on buffers scanned/round
+#bgwriter_flush_after = 0		# measured in pages, 0 disables
+
+# - Asynchronous Behavior -
+
+#backend_flush_after = 0		# measured in pages, 0 disables
+#effective_io_concurrency = 1		# 1-1000; 0 disables prefetching
+#maintenance_io_concurrency = 10	# 1-1000; 0 disables prefetching
+#max_worker_processes = 8		# (change requires restart)
+#max_parallel_workers_per_gather = 2	# limited by max_parallel_workers
+#max_parallel_maintenance_workers = 2	# limited by max_parallel_workers
+#max_parallel_workers = 8		# number of max_worker_processes that
+					# can be used in parallel operations
+#parallel_leader_participation = on
+#old_snapshot_threshold = -1		# 1min-60d; -1 disables; 0 is immediate
+					# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# WRITE-AHEAD LOG
+#------------------------------------------------------------------------------
+
+# - Settings -
+
+#wal_level = replica			# minimal, replica, or logical
+					# (change requires restart)
+#fsync = on				# flush data to disk for crash safety
+					# (turning this off can cause
+					# unrecoverable data corruption)
+#synchronous_commit = on		# synchronization level;
+					# off, local, remote_write, remote_apply, or on
+#wal_sync_method = fsync		# the default is the first option
+					# supported by the operating system:
+					#   open_datasync
+					#   fdatasync (default on Linux and FreeBSD)
+					#   fsync
+					#   fsync_writethrough
+					#   open_sync
+full_page_writes = {{ sysbench_postgresql_full_page_writes }}			# recover from partial page writes
+#wal_log_hints = off			# also do full page writes of non-critical updates
+					# (change requires restart)
+#wal_compression = off			# enables compression of full-page writes;
+					# off, pglz, lz4, zstd, or on
+#wal_init_zero = on			# zero-fill new WAL files
+#wal_recycle = on			# recycle WAL files
+#wal_buffers = -1			# min 32kB, -1 sets based on shared_buffers
+					# (change requires restart)
+#wal_writer_delay = 200ms		# 1-10000 milliseconds
+#wal_writer_flush_after = 1MB		# measured in pages, 0 disables
+#wal_skip_threshold = 2MB
+
+#commit_delay = 0			# range 0-100000, in microseconds
+#commit_siblings = 5			# range 1-1000
+
+# - Checkpoints -
+
+#checkpoint_timeout = 5min		# range 30s-1d
+#checkpoint_completion_target = 0.9	# checkpoint target duration, 0.0 - 1.0
+#checkpoint_flush_after = 0		# measured in pages, 0 disables
+#checkpoint_warning = 30s		# 0 disables
+#max_wal_size = 1GB
+#min_wal_size = 80MB
+
+# - Prefetching during recovery -
+
+#recovery_prefetch = try		# prefetch pages referenced in the WAL?
+#wal_decode_buffer_size = 512kB		# lookahead window used for prefetching
+					# (change requires restart)
+
+# - Archiving -
+
+#archive_mode = off		# enables archiving; off, on, or always
+				# (change requires restart)
+#archive_library = ''		# library to use to archive a WAL file
+				# (empty string indicates archive_command should
+				# be used)
+#archive_command = ''		# command to use to archive a WAL file
+				# placeholders: %p = path of file to archive
+				#               %f = file name only
+				# e.g. 'test ! -f /mnt/server/archivedir/%f && cp %p /mnt/server/archivedir/%f'
+#archive_timeout = 0		# force a WAL file switch after this
+				# number of seconds; 0 disables
+
+# - Archive Recovery -
+
+# These are only used in recovery mode.
+
+#restore_command = ''		# command to use to restore an archived WAL file
+				# placeholders: %p = path of file to restore
+				#               %f = file name only
+				# e.g. 'cp /mnt/server/archivedir/%f %p'
+#archive_cleanup_command = ''	# command to execute at every restartpoint
+#recovery_end_command = ''	# command to execute at completion of recovery
+
+# - Recovery Target -
+
+# Set these only when performing a targeted recovery.
+
+#recovery_target = ''		# 'immediate' to end recovery as soon as a
+                                # consistent state is reached
+				# (change requires restart)
+#recovery_target_name = ''	# the named restore point to which recovery will proceed
+				# (change requires restart)
+#recovery_target_time = ''	# the time stamp up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_xid = ''	# the transaction ID up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_lsn = ''	# the WAL LSN up to which recovery will proceed
+				# (change requires restart)
+#recovery_target_inclusive = on # Specifies whether to stop:
+				# just after the specified recovery target (on)
+				# just before the recovery target (off)
+				# (change requires restart)
+#recovery_target_timeline = 'latest'	# 'current', 'latest', or timeline ID
+				# (change requires restart)
+#recovery_target_action = 'pause'	# 'pause', 'promote', 'shutdown'
+				# (change requires restart)
+
+
+#------------------------------------------------------------------------------
+# REPLICATION
+#------------------------------------------------------------------------------
+
+# - Sending Servers -
+
+# Set these on the primary and on any standby that will send replication data.
+
+#max_wal_senders = 10		# max number of walsender processes
+				# (change requires restart)
+#max_replication_slots = 10	# max number of replication slots
+				# (change requires restart)
+#wal_keep_size = 0		# in megabytes; 0 disables
+#max_slot_wal_keep_size = -1	# in megabytes; -1 disables
+#wal_sender_timeout = 60s	# in milliseconds; 0 disables
+#track_commit_timestamp = off	# collect timestamp of transaction commit
+				# (change requires restart)
+
+# - Primary Server -
+
+# These settings are ignored on a standby server.
+
+#synchronous_standby_names = ''	# standby servers that provide sync rep
+				# method to choose sync standbys, number of sync standbys,
+				# and comma-separated list of application_name
+				# from standby(s); '*' = all
+
+# - Standby Servers -
+
+# These settings are ignored on a primary server.
+
+#primary_conninfo = ''			# connection string to sending server
+#primary_slot_name = ''			# replication slot on sending server
+#hot_standby = on			# "off" disallows queries during recovery
+					# (change requires restart)
+#max_standby_archive_delay = 30s	# max delay before canceling queries
+					# when reading WAL from archive;
+					# -1 allows indefinite delay
+#max_standby_streaming_delay = 30s	# max delay before canceling queries
+					# when reading streaming WAL;
+					# -1 allows indefinite delay
+#wal_receiver_create_temp_slot = off	# create temp slot if primary_slot_name
+					# is not set
+#wal_receiver_status_interval = 10s	# send replies at least this often
+					# 0 disables
+#hot_standby_feedback = off		# send info from standby to prevent
+					# query conflicts
+#wal_receiver_timeout = 60s		# time that receiver waits for
+					# communication from primary
+					# in milliseconds; 0 disables
+#wal_retrieve_retry_interval = 5s	# time to wait before retrying to
+					# retrieve WAL after a failed attempt
+#recovery_min_apply_delay = 0		# minimum delay for applying changes during recovery
+
+# - Subscribers -
+
+# These settings are ignored on a publisher.
+
+#max_logical_replication_workers = 4	# taken from max_worker_processes
+					# (change requires restart)
+#max_sync_workers_per_subscription = 2	# taken from max_logical_replication_workers
+#max_parallel_apply_workers_per_subscription = 2	# taken from max_logical_replication_workers
+
+
+#------------------------------------------------------------------------------
+# QUERY TUNING
+#------------------------------------------------------------------------------
+
+# - Planner Method Configuration -
+
+#enable_async_append = on
+#enable_bitmapscan = on
+#enable_gathermerge = on
+#enable_hashagg = on
+#enable_hashjoin = on
+#enable_incremental_sort = on
+#enable_indexscan = on
+#enable_indexonlyscan = on
+#enable_material = on
+#enable_memoize = on
+#enable_mergejoin = on
+#enable_nestloop = on
+#enable_parallel_append = on
+#enable_parallel_hash = on
+#enable_partition_pruning = on
+#enable_partitionwise_join = off
+#enable_partitionwise_aggregate = off
+#enable_presorted_aggregate = on
+#enable_seqscan = on
+#enable_sort = on
+#enable_tidscan = on
+
+# - Planner Cost Constants -
+
+#seq_page_cost = 1.0			# measured on an arbitrary scale
+#random_page_cost = 4.0			# same scale as above
+#cpu_tuple_cost = 0.01			# same scale as above
+#cpu_index_tuple_cost = 0.005		# same scale as above
+#cpu_operator_cost = 0.0025		# same scale as above
+#parallel_setup_cost = 1000.0	# same scale as above
+#parallel_tuple_cost = 0.1		# same scale as above
+#min_parallel_table_scan_size = 8MB
+#min_parallel_index_scan_size = 512kB
+#effective_cache_size = 4GB
+
+#jit_above_cost = 100000		# perform JIT compilation if available
+					# and query more expensive than this;
+					# -1 disables
+#jit_inline_above_cost = 500000		# inline small functions if query is
+					# more expensive than this; -1 disables
+#jit_optimize_above_cost = 500000	# use expensive JIT optimizations if
+					# query is more expensive than this;
+					# -1 disables
+
+# - Genetic Query Optimizer -
+
+#geqo = on
+#geqo_threshold = 12
+#geqo_effort = 5			# range 1-10
+#geqo_pool_size = 0			# selects default based on effort
+#geqo_generations = 0			# selects default based on effort
+#geqo_selection_bias = 2.0		# range 1.5-2.0
+#geqo_seed = 0.0			# range 0.0-1.0
+
+# - Other Planner Options -
+
+#default_statistics_target = 100	# range 1-10000
+#constraint_exclusion = partition	# on, off, or partition
+#cursor_tuple_fraction = 0.1		# range 0.0-1.0
+#from_collapse_limit = 8
+#jit = on				# allow JIT compilation
+#join_collapse_limit = 8		# 1 disables collapsing of explicit
+					# JOIN clauses
+#plan_cache_mode = auto			# auto, force_generic_plan or
+					# force_custom_plan
+#recursive_worktable_factor = 10.0	# range 0.001-1000000
+
+
+#------------------------------------------------------------------------------
+# REPORTING AND LOGGING
+#------------------------------------------------------------------------------
+
+# - Where to Log -
+
+#log_destination = 'stderr'		# Valid values are combinations of
+					# stderr, csvlog, jsonlog, syslog, and
+					# eventlog, depending on platform.
+					# csvlog and jsonlog require
+					# logging_collector to be on.
+
+# This is used when logging to stderr:
+#logging_collector = off		# Enable capturing of stderr, jsonlog,
+					# and csvlog into log files. Required
+					# to be on for csvlogs and jsonlogs.
+					# (change requires restart)
+
+# These are only used if logging_collector is on:
+#log_directory = 'log'			# directory where log files are written,
+					# can be absolute or relative to PGDATA
+#log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'	# log file name pattern,
+					# can include strftime() escapes
+#log_file_mode = 0600			# creation mode for log files,
+					# begin with 0 to use octal notation
+#log_rotation_age = 1d			# Automatic rotation of logfiles will
+					# happen after that time.  0 disables.
+#log_rotation_size = 10MB		# Automatic rotation of logfiles will
+					# happen after that much log output.
+					# 0 disables.
+#log_truncate_on_rotation = off		# If on, an existing log file with the
+					# same name as the new log file will be
+					# truncated rather than appended to.
+					# But such truncation only occurs on
+					# time-driven rotation, not on restarts
+					# or size-driven rotation.  Default is
+					# off, meaning append to existing files
+					# in all cases.
+
+# These are relevant when logging to syslog:
+#syslog_facility = 'LOCAL0'
+#syslog_ident = 'postgres'
+#syslog_sequence_numbers = on
+#syslog_split_messages = on
+
+# This is only relevant when logging to eventlog (Windows):
+# (change requires restart)
+#event_source = 'PostgreSQL'
+
+# - When to Log -
+
+#log_min_messages = warning		# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   info
+					#   notice
+					#   warning
+					#   error
+					#   log
+					#   fatal
+					#   panic
+
+#log_min_error_statement = error	# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   info
+					#   notice
+					#   warning
+					#   error
+					#   log
+					#   fatal
+					#   panic (effectively off)
+
+#log_min_duration_statement = -1	# -1 is disabled, 0 logs all statements
+					# and their durations, > 0 logs only
+					# statements running at least this number
+					# of milliseconds
+
+#log_min_duration_sample = -1		# -1 is disabled, 0 logs a sample of statements
+					# and their durations, > 0 logs only a sample of
+					# statements running at least this number
+					# of milliseconds;
+					# sample fraction is determined by log_statement_sample_rate
+
+#log_statement_sample_rate = 1.0	# fraction of logged statements exceeding
+					# log_min_duration_sample to be logged;
+					# 1.0 logs all such statements, 0.0 never logs
+
+
+#log_transaction_sample_rate = 0.0	# fraction of transactions whose statements
+					# are logged regardless of their duration; 1.0 logs all
+					# statements from all transactions, 0.0 never logs
+
+#log_startup_progress_interval = 10s	# Time between progress updates for
+					# long-running startup operations.
+					# 0 disables the feature, > 0 indicates
+					# the interval in milliseconds.
+
+# - What to Log -
+
+#debug_print_parse = off
+#debug_print_rewritten = off
+#debug_print_plan = off
+#debug_pretty_print = on
+#log_autovacuum_min_duration = 10min	# log autovacuum activity;
+					# -1 disables, 0 logs all actions and
+					# their durations, > 0 logs only
+					# actions running at least this number
+					# of milliseconds.
+#log_checkpoints = on
+#log_connections = off
+#log_disconnections = off
+#log_duration = off
+#log_error_verbosity = default		# terse, default, or verbose messages
+#log_hostname = off
+#log_line_prefix = '%m [%p] '		# special values:
+					#   %a = application name
+					#   %u = user name
+					#   %d = database name
+					#   %r = remote host and port
+					#   %h = remote host
+					#   %b = backend type
+					#   %p = process ID
+					#   %P = process ID of parallel group leader
+					#   %t = timestamp without milliseconds
+					#   %m = timestamp with milliseconds
+					#   %n = timestamp with milliseconds (as a Unix epoch)
+					#   %Q = query ID (0 if none or not computed)
+					#   %i = command tag
+					#   %e = SQL state
+					#   %c = session ID
+					#   %l = session line number
+					#   %s = session start timestamp
+					#   %v = virtual transaction ID
+					#   %x = transaction ID (0 if none)
+					#   %q = stop here in non-session
+					#        processes
+					#   %% = '%'
+					# e.g. '<%u%%%d> '
+#log_lock_waits = off			# log lock waits >= deadlock_timeout
+#log_recovery_conflict_waits = off	# log standby recovery conflict waits
+					# >= deadlock_timeout
+#log_parameter_max_length = -1		# when logging statements, limit logged
+					# bind-parameter values to N bytes;
+					# -1 means print in full, 0 disables
+#log_parameter_max_length_on_error = 0	# when logging an error, limit logged
+					# bind-parameter values to N bytes;
+					# -1 means print in full, 0 disables
+#log_statement = 'none'			# none, ddl, mod, all
+#log_replication_commands = off
+#log_temp_files = -1			# log temporary files equal or larger
+					# than the specified size in kilobytes;
+					# -1 disables, 0 logs all temp files
+#log_timezone = 'GMT'
+
+# - Process Title -
+
+#cluster_name = ''			# added to process titles if nonempty
+					# (change requires restart)
+#update_process_title = on
+
+
+#------------------------------------------------------------------------------
+# STATISTICS
+#------------------------------------------------------------------------------
+
+# - Cumulative Query and Index Statistics -
+
+#track_activities = on
+#track_activity_query_size = 1024	# (change requires restart)
+#track_counts = on
+#track_io_timing = off
+#track_wal_io_timing = off
+#track_functions = none			# none, pl, all
+#stats_fetch_consistency = cache	# cache, none, snapshot
+
+
+# - Monitoring -
+
+#compute_query_id = auto
+#log_statement_stats = off
+#log_parser_stats = off
+#log_planner_stats = off
+#log_executor_stats = off
+
+
+#------------------------------------------------------------------------------
+# AUTOVACUUM
+#------------------------------------------------------------------------------
+
+#autovacuum = on			# Enable autovacuum subprocess?  'on'
+					# requires track_counts to also be on.
+#autovacuum_max_workers = 3		# max number of autovacuum subprocesses
+					# (change requires restart)
+#autovacuum_naptime = 1min		# time between autovacuum runs
+#autovacuum_vacuum_threshold = 50	# min number of row updates before
+					# vacuum
+#autovacuum_vacuum_insert_threshold = 1000	# min number of row inserts
+					# before vacuum; -1 disables insert
+					# vacuums
+#autovacuum_analyze_threshold = 50	# min number of row updates before
+					# analyze
+#autovacuum_vacuum_scale_factor = 0.2	# fraction of table size before vacuum
+#autovacuum_vacuum_insert_scale_factor = 0.2	# fraction of inserts over table
+					# size before insert vacuum
+#autovacuum_analyze_scale_factor = 0.1	# fraction of table size before analyze
+#autovacuum_freeze_max_age = 200000000	# maximum XID age before forced vacuum
+					# (change requires restart)
+#autovacuum_multixact_freeze_max_age = 400000000	# maximum multixact age
+					# before forced vacuum
+					# (change requires restart)
+#autovacuum_vacuum_cost_delay = 2ms	# default vacuum cost delay for
+					# autovacuum, in milliseconds;
+					# -1 means use vacuum_cost_delay
+#autovacuum_vacuum_cost_limit = -1	# default vacuum cost limit for
+					# autovacuum, -1 means use
+					# vacuum_cost_limit
+
+
+#------------------------------------------------------------------------------
+# CLIENT CONNECTION DEFAULTS
+#------------------------------------------------------------------------------
+
+# - Statement Behavior -
+
+#client_min_messages = notice		# values in order of decreasing detail:
+					#   debug5
+					#   debug4
+					#   debug3
+					#   debug2
+					#   debug1
+					#   log
+					#   notice
+					#   warning
+					#   error
+#search_path = '"$user", public'	# schema names
+#row_security = on
+#default_table_access_method = 'heap'
+#default_tablespace = ''		# a tablespace name, '' uses the default
+#default_toast_compression = 'pglz'	# 'pglz' or 'lz4'
+#temp_tablespaces = ''			# a list of tablespace names, '' uses
+					# only default tablespace
+#check_function_bodies = on
+#default_transaction_isolation = 'read committed'
+#default_transaction_read_only = off
+#default_transaction_deferrable = off
+#session_replication_role = 'origin'
+#statement_timeout = 0			# in milliseconds, 0 is disabled
+#lock_timeout = 0			# in milliseconds, 0 is disabled
+#idle_in_transaction_session_timeout = 0	# in milliseconds, 0 is disabled
+#idle_session_timeout = 0		# in milliseconds, 0 is disabled
+#vacuum_freeze_table_age = 150000000
+#vacuum_freeze_min_age = 50000000
+#vacuum_failsafe_age = 1600000000
+#vacuum_multixact_freeze_table_age = 150000000
+#vacuum_multixact_freeze_min_age = 5000000
+#vacuum_multixact_failsafe_age = 1600000000
+#bytea_output = 'hex'			# hex, escape
+#xmlbinary = 'base64'
+#xmloption = 'content'
+#gin_pending_list_limit = 4MB
+#createrole_self_grant = ''		# set and/or inherit
+
+# - Locale and Formatting -
+
+#datestyle = 'iso, mdy'
+#intervalstyle = 'postgres'
+#timezone = 'GMT'
+#timezone_abbreviations = 'Default'     # Select the set of available time zone
+					# abbreviations.  Currently, there are
+					#   Default
+					#   Australia (historical usage)
+					#   India
+					# You can create your own file in
+					# share/timezonesets/.
+#extra_float_digits = 1			# min -15, max 3; any value >0 actually
+					# selects precise output mode
+#client_encoding = sql_ascii		# actually, defaults to database
+					# encoding
+
+# These settings are initialized by initdb, but they can be changed.
+#lc_messages = ''			# locale for system error message
+					# strings
+#lc_monetary = 'C'			# locale for monetary formatting
+#lc_numeric = 'C'			# locale for number formatting
+#lc_time = 'C'				# locale for time formatting
+
+#icu_validation_level = warning		# report ICU locale validation
+					# errors at the given level
+
+# default configuration for text search
+#default_text_search_config = 'pg_catalog.simple'
+
+# - Shared Library Preloading -
+
+#local_preload_libraries = ''
+#session_preload_libraries = ''
+#shared_preload_libraries = ''	# (change requires restart)
+#jit_provider = 'llvmjit'		# JIT library to use
+
+# - Other Defaults -
+
+#dynamic_library_path = '$libdir'
+#gin_fuzzy_search_limit = 0
+
+
+#------------------------------------------------------------------------------
+# LOCK MANAGEMENT
+#------------------------------------------------------------------------------
+
+#deadlock_timeout = 1s
+#max_locks_per_transaction = 64		# min 10
+					# (change requires restart)
+#max_pred_locks_per_transaction = 64	# min 10
+					# (change requires restart)
+#max_pred_locks_per_relation = -2	# negative values mean
+					# (max_pred_locks_per_transaction
+					#  / -max_pred_locks_per_relation) - 1
+#max_pred_locks_per_page = 2            # min 0
+
+
+#------------------------------------------------------------------------------
+# VERSION AND PLATFORM COMPATIBILITY
+#------------------------------------------------------------------------------
+
+# - Previous PostgreSQL Versions -
+
+#array_nulls = on
+#backslash_quote = safe_encoding	# on, off, or safe_encoding
+#escape_string_warning = on
+#lo_compat_privileges = off
+#quote_all_identifiers = off
+#standard_conforming_strings = on
+#synchronize_seqscans = on
+
+# - Other Platforms and Clients -
+
+#transform_null_equals = off
+
+
+#------------------------------------------------------------------------------
+# ERROR HANDLING
+#------------------------------------------------------------------------------
+
+#exit_on_error = off			# terminate session on any error?
+#restart_after_crash = on		# reinitialize after backend crash?
+#data_sync_retry = off			# retry or panic on failure to fsync
+					# data?
+					# (change requires restart)
+#recovery_init_sync_method = fsync	# fsync, syncfs (Linux 5.8+)
+
+
+#------------------------------------------------------------------------------
+# CONFIG FILE INCLUDES
+#------------------------------------------------------------------------------
+
+# These options allow settings to be loaded from files other than the
+# default postgresql.conf.  Note that these are directives, not variable
+# assignments, so they can usefully be given more than once.
+
+#include_dir = '...'			# include files ending in '.conf' from
+					# a directory, e.g., 'conf.d'
+#include_if_exists = '...'		# include file only if it exists
+#include = '...'			# include file
+
+
+#------------------------------------------------------------------------------
+# CUSTOMIZED OPTIONS
+#------------------------------------------------------------------------------
+
+# Add settings for extensions here
diff --git a/workflows/sysbench/Kconfig b/workflows/sysbench/Kconfig
index 35ff821..0b94c81 100644
--- a/workflows/sysbench/Kconfig
+++ b/workflows/sysbench/Kconfig
@@ -2,6 +2,10 @@ config SYSBENCH_DB_TYPE_MYSQL
 	bool
 	output yaml
 
+config SYSBENCH_DB_TYPE_POSTGRESQL
+	bool
+	output yaml
+
 source "workflows/sysbench/Kconfig.fs"
 
 choice
@@ -15,16 +19,28 @@ config SYSBENCH_DOCKER
 	help
 	  Run sysbench inside Docker containers.
 
+config SYSBENCH_NATIVE
+	bool "Run Sysbench natively in the Guest OS"
+	output yaml
+	select SYSBENCH_TYPE_POSTGRESQL_NATIVE
+	help
+	  Run sysbench natively in the Guest OS.
+
 endchoice
 
 if SYSBENCH_DOCKER
 source "workflows/sysbench/Kconfig.docker"
 endif # SYSBENCH_DOCKER
 
+if SYSBENCH_NATIVE
+source "workflows/sysbench/Kconfig.native"
+endif # SYSBENCH_NATIVE
+
 config SYSBENCH_DB_TYPE
 	string
 	output yaml
 	default "mysql" if SYSBENCH_DB_TYPE_MYSQL
+	default "pgsql" if SYSBENCH_DB_TYPE_POSTGRESQL
 
 if SYSBENCH_DB_TYPE_MYSQL
 
@@ -101,6 +117,25 @@ config SYSBENCH_OLTP_TABLE_COUNT
 	output yaml
 	default "24"
 
+choice
+	prompt "Number of threads?"
+	default SYSBENCH_THREADS_INTEGER if SYSBENCH_DB_TYPE_MYSQL
+	default SYSBENCH_THREADS_AUTO if SYSBENCH_DB_TYPE_POSTGRESQL
+
+config SYSBENCH_THREADS_INTEGER
+	bool "Manual"
+	help
+	  Configure the number of threads manually
+
+config SYSBENCH_THREADS_AUTO
+	bool "Auto"
+	help
+	  Configure the number of threads automatically using nproc
+
+endchoice
+
+if SYSBENCH_THREADS_INTEGER
+
 config SYSBENCH_THREADS
 	int "Sysbench number of threads"
 	output yaml
@@ -108,6 +143,18 @@ config SYSBENCH_THREADS
 	help
 	  Set the number of threads for the sysbench test. Default is 128.
 
+endif # SYSBENCH_THREADS_INTEGER
+
+if SYSBENCH_THREADS_AUTO
+
+config SYSBENCH_THREADS
+	output yaml
+	default "0"
+	help
+	  Set the number of threads using nproc.
+
+endif # SYSBENCH_THREADS_AUTO
+
 config SYSBENCH_TEST_DURATION
 	int "Sysbench Test Duration (seconds)"
 	default 3600
diff --git a/workflows/sysbench/Kconfig.fs b/workflows/sysbench/Kconfig.fs
index b0f6e61..5a911c6 100644
--- a/workflows/sysbench/Kconfig.fs
+++ b/workflows/sysbench/Kconfig.fs
@@ -55,6 +55,9 @@ config SYSBENCH_TEST_ATOMICS_TPS_VARIABILITY
 
 endchoice
 
+
+if SYSBENCH_DB_TYPE_MYSQL
+
 choice
 	prompt "When do you want to disable innodb_doublewrite?"
 	default SYSBENCH_DISABLE_DOUBLEWRITE_AUTO
@@ -76,6 +79,33 @@ config SYSBENCH_DISABLE_DOUBLEWRITE_ALWAYS
 
 endchoice
 
+endif # SYSBENCH_DB_TYPE_MYSQL
+
+if SYSBENCH_DB_TYPE_POSTGRESQL
+
+choice
+	prompt "When do you want to disable full_page_writes?"
+	default SYSBENCH_DISABLE_FULL_PAGE_WRITES_AUTO
+
+config SYSBENCH_DISABLE_FULL_PAGE_WRITES_AUTO
+	bool "Use hostname postfix"
+	output yaml
+	help
+	  To allow for A/B testing this option will only disable the
+	  full_page_writes on nodes which have a hostname which end
+	  with "-dev".
+
+config SYSBENCH_DISABLE_FULL_PAGE_WRITES_ALWAYS
+	bool "Disable it always"
+	output yaml
+	help
+	  If you don't want to spawn nodes to do A/B testing and just want
+	  to test disabling the full_page_writes enable this.
+
+endchoice
+
+endif # SYSBENCH_DB_TYPE_MYSQL
+
 config SYSBENCH_TEST_ATOMICS_XFS_16K_4KS_LBS
 	bool "XFS 16k LBS - 4k sector size"
 	select SYSBENCH_FS_XFS
diff --git a/workflows/sysbench/Kconfig.native b/workflows/sysbench/Kconfig.native
new file mode 100644
index 0000000..343c0dd
--- /dev/null
+++ b/workflows/sysbench/Kconfig.native
@@ -0,0 +1,120 @@
+choice
+	prompt "What type of sysbench do you want to use?"
+	default SYSBENCH_TYPE_POSTGRESQL_NATIVE
+
+config SYSBENCH_TYPE_POSTGRESQL_NATIVE
+	bool "Use PostgreSQL natively for Sysbench"
+	output yaml
+	select SYSBENCH_DB_TYPE_POSTGRESQL
+	help
+	  Enable this option to run sysbench using PostgreSQL natively
+	  in the Guest OS.
+
+endchoice
+
+if SYSBENCH_TYPE_POSTGRESQL_NATIVE
+
+choice
+	prompt "Which PostgreSQL version to use?"
+	default SYSBENCH_POSTGRESQL_VERSION_REL_17
+
+config SYSBENCH_POSTGRESQL_VERSION_REL_17
+	bool "PostgreSQL 17.m"
+	output yaml
+	help
+	  Uses latest 17 release available (e.g. 17.0).
+
+config SYSBENCH_POSTGRESQL_VERSION_REL_16
+	bool "PostgreSQL 16.m"
+	output yaml
+	help
+	  Uses latest 16 release available (e.g. 16.4).
+
+config SYSBENCH_POSTGRESQL_VERSION_REL_15
+	bool "PostgreSQL 15.m"
+	output yaml
+	help
+	  Uses latest 15 release available (e.g. 15.8).
+
+endchoice
+
+config SYSBENCH_POSTGRESQL_REF_STRING
+	string
+	output yaml
+	default "REL_17" if SYSBENCH_POSTGRESQL_VERSION_REL_17
+	default "REL_16" if SYSBENCH_POSTGRESQL_VERSION_REL_16
+	default "REL_15" if SYSBENCH_POSTGRESQL_VERSION_REL_15
+
+config SYSBENCH_POSTGRESQL_BLOCKSIZE
+	string "PostgreSQL Block Size"
+	default "8"
+	output yaml
+	help
+	  PostgreSQL block size in kilobytes (--with-blocksize=BLOCKSIZE).
+	  The value must be a power of 2 between 1 and 32 (kilobytes).
+	  This is a build configuration option.
+	  https://www.postgresql.org/docs/16/install-make.html#CONFIGURE-OPTION-WITH-BLOCKSIZE
+
+config SYSBENCH_POSTGRESQL_WAL_BLOCKSIZE
+	string "PostgreSQL WAL Block Size"
+	default "8"
+	output yaml
+	help
+	  PostgreSQL WAL block size in kilobytes (--with-wal-blocksize=BLOCKSIZE).
+	  The value must be a power of 2 between 1 and 64 (kilobytes).
+	  This is a build configuration option.
+	  https://www.postgresql.org/docs/16/install-make.html#CONFIGURE-OPTION-WITH-WAL-BLOCKSIZE
+
+config SYSBENCH_POSTGRESQL_USER
+	string "PostgreSQL benchmark user"
+	default "postgres"
+	output yaml
+	help
+	  User to run PostgreSQL database and benchmark.
+
+config SYSBENCH_POSTGRESQL_LOGDIR
+	string "PostgreSQL Log Directory"
+	default "/var/log/postgresql"
+	output yaml
+	help
+	  Where to place the database logs.
+
+config SYSBENCH_POSTGRESQL_USER
+	string "PostgreSQL User"
+	default "postgres"
+	output yaml
+	help
+	  PostgreSQL user running database daemon.
+
+config SYSBENCH_LOCAL_DB_PORT
+	int "The actual local database port to use"
+	default "5432"
+	output yaml
+	help
+	  PostgreSQL Database Port
+
+choice
+	prompt "What PostgreSQL configuration to use?"
+	default SYSBENCH_POSTGRESQL_CONF_DEFAULT
+
+config SYSBENCH_POSTGRESQL_CONF_DEFAULT
+	bool "Default"
+	help
+	  Use default configuration file.
+	  Check playbooks/roles/sysbench/templates/postgresql-conf-default.conf.j2.
+
+config SYSBENCH_POSTGRESQL_CONF_000
+	bool "Configuration-000"
+	help
+	  Use configuration file nr 0.
+	  Check playbooks/roles/sysbench/templates/postgresql-conf-000.conf.j2.
+
+endchoice
+
+config SYSBENCH_POSTGRESQL_CONFIGURATION
+	string
+	output yaml
+	default "postgresql-conf-default.conf" if SYSBENCH_POSTGRESQL_CONF_DEFAULT
+	default "postgresql-conf-000.conf" if SYSBENCH_POSTGRESQL_CONF_000
+
+endif # SYSBENCH_TYPE_POSTGRESQL_NATIVE

-- 
2.39.2

