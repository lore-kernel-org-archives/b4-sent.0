From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v5 0/3] pidfd: Add task path ioctls
Date: Fri, 06 Nov 2026 15:12:20 +0800
Message-Id: <20261106-pidfd-get-paths-v5-0-3147ce6571cb@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/23R207DMAwG4Fepck1QjuvhivdAu3AcdwtjbWmyC
 jT13Uk7NE10l5acz87vK4s0BoqsKa5spCnE0He5sC8FwyN0B+LB55opoXaikjUfgm89P1DiA6R
 j5LbeGeEr9JKI5VfDSG34XsX3/a2OF/dBmBZm6TiGmPrxZx05yaXvT1dio0+SCw6oicgIob19c
 5+AJ+4pnl6xY8uEST0YWm4NlQ20NcEOlHSlembouyGFfLKHzkarjDVGOOW0eGaYB0OVW8Nkg1T
 ewpSksd78Zb7FNdLXJd8h3TJkDiJx7M/nkJrCS23BGauhzHmANrUWznuQ1BrnsQJsASuxXuJ+v
 6b4t1OCeMqpIsXIXVmXhC5nB6bJ59jP8y90/dO+FQIAAA==
X-Change-ID: 20260819-pidfd-get-paths-59640d8cd1ee
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Ingo Molnar <mingo@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, Kees Cook <kees@kernel.org>, 
 John Johansen <john.johansen@canonical.com>, 
 Georgia Garcia <georgia.garcia@canonical.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, apparmor@lists.ubuntu.com, 
 linux-security-module@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=4196; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=wgKnE8AT6zpqmdbQXKjfkpLb58iWgrFhxz3SEzzfreA=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBq7X3o6Ky5NtuZHI7eJbXQEVN+9Nq8XbqFkVBdO
 8jaSwhvpUSJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCau196AAKCRB2HuYUOZmu
 i09oD/9d2F1RAOVF0ehGGa3AE4njnpiPsiT80fknzuhT1hJ7a67xlavnz4/+JAWndScNFA9E/48
 tx6ItTLkqhPIWwmjIvmQVrNG5+JBVoX0E7KwAU+/I38w3r4r3Kv8kUrxsAtjRXSKvKY1MZeg0E1
 GI7FUxgc8VX2zrmfJqR4CfT0IyEPp4FRJ39rxM5whQFfVsMx7Nt5kgfvVG0wK6D9s7kfzfuICPw
 odaxYeCSLDor6nuvxEoonHOw6LCsWaOezdl9vtHcchQj/BYbp8Uv0XWj7lbzdTNmTwWG4oxxzV/
 BuXIHcgkznW+xvBlEKt7RvsmURt6Vv5iE1wh5l7dDZZw8gLKzGkq6QeKnvdhCyoXKNkGIj2KIgo
 l/GkyZD4ysSXUl47gVsSye6noyB2H5u+OTojO1COV+0YvsH4Je3eplF6BazgbcaqlS9CziVgRRw
 vUd3RfL4ptcVxwKg1nhBebybrE3EkgHlfg9q0nP2UnefKX2WB/nk6cChGivjOHge4fuppyLrB4u
 xrWdja/usdKvVQ6y1Ot3INkX5s6Md7A4znqNZEFM7gHv5eHP/Yc/xGanTUFS/X5rHztkGPwva6s
 Gp2qWU/r09zcUxpOZqYTHJa+5smlNTQUey5kqx5F4LpNpoXgm6ZShEKkuDqDKE2czYXDHmcnq82
 DZJFI4vAMkaG1KA==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Obtaining a target task's executable, working directory or root
currently requires following /proc/<pid>/{exe,cwd,root}. Add
PIDFD_GET_EXE, PIDFD_GET_CWD and PIDFD_GET_ROOT so callers holding a
pidfd can obtain these paths without requiring procfs to be mounted or
visible.

Each ioctl takes a zero argument and returns an O_PATH file descriptor
with FD_CLOEXEC set. Targets must be visible in the caller's active pid
namespace. Reuse the procfs path getters and hold exec_update_lock
across PTRACE_MODE_READ_FSCREDS authorization and path acquisition.

Following Christian Brauner's review, use a dedicated task_path_open()
helper after releasing exec_update_lock. It calls ->d_weak_revalidate()
with flags zero when the filesystem provides it, propagates a negative
error, maps a zero result to ESTALE, and otherwise opens the path with
O_PATH. This gives filesystems such as failfs the opportunity to refuse
an O_PATH descriptor without starting a pathname lookup.

The first patch factors out the task path getters. The second prepares
scoped task access for the pidfd ioctls. The third adds the three ioctls
and task_path_open().

This series depends on the separately submitted pid-namespace visibility
restriction:
  https://lore.kernel.org/all/20261027-pidfd-task-access-v1-1-d46cf0fa4ca1@black-desk.cn/

Tested with virtme-ng.

Sashiko AI review reported the missing weak revalidation in v4.
This entire patch series was generated with LLM assistance. I defined
the requirements, guided the implementation, reviewed the changes, and
made the design decisions.

---
Changes in v5:
- Add task_path_open() as suggested by Christian Brauner, replacing the
  direct dentry_open() call from v4. Revalidate with flags zero outside
  exec_update_lock and return filesystem errors without lookup retries.
- Link to v4:
  https://lore.kernel.org/all/20261027-pidfd-get-paths-v4-0-e2a6a47e3c95@black-desk.cn/

To: Alexander Viro <viro@zeniv.linux.org.uk>
To: Christian Brauner <brauner@kernel.org>
To: Jan Kara <jack@suse.cz>
To: Andrew Morton <akpm@linux-foundation.org>
To: David Hildenbrand <david@kernel.org>
To: Lorenzo Stoakes <ljs@kernel.org>
To: "Liam R. Howlett" <liam@infradead.org>
To: Vlastimil Babka <vbabka@kernel.org>
To: Mike Rapoport <rppt@kernel.org>
To: Suren Baghdasaryan <surenb@google.com>
To: Michal Hocko <mhocko@suse.com>
To: Ingo Molnar <mingo@redhat.com>
To: Peter Zijlstra <peterz@infradead.org>
To: Juri Lelli <juri.lelli@redhat.com>
To: Vincent Guittot <vincent.guittot@linaro.org>
To: Dietmar Eggemann <dietmar.eggemann@arm.com>
To: Steven Rostedt <rostedt@goodmis.org>
To: Ben Segall <bsegall@google.com>
To: Mel Gorman <mgorman@suse.de>
To: Valentin Schneider <vschneid@redhat.com>
To: K Prateek Nayak <kprateek.nayak@amd.com>
To: Kees Cook <kees@kernel.org>
To: John Johansen <john.johansen@canonical.com>
To: Georgia Garcia <georgia.garcia@canonical.com>
To: Paul Moore <paul@paul-moore.com>
To: James Morris <jmorris@namei.org>
To: "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-fsdevel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-mm@kvack.org
Cc: apparmor@lists.ubuntu.com
Cc: linux-security-module@vger.kernel.org

---
Chen Linxuan (3):
      fs: Introduce task path helpers
      pidfd: Use scoped cleanup for task access
      pidfd: Add task path ioctls

 fs/fs_struct.c             |  44 +++++++++++++
 fs/internal.h              |   1 +
 fs/open.c                  |  30 +++++++++
 fs/pidfs.c                 | 157 ++++++++++++++++++++++++++++++++-------------
 fs/proc/base.c             |  34 +---------
 include/linux/fs_struct.h  |   3 +
 include/linux/mm.h         |   1 +
 include/uapi/linux/pidfd.h |   7 ++
 kernel/fork.c              |  22 +++++++
 security/apparmor/task.c   |  12 +---
 10 files changed, 224 insertions(+), 87 deletions(-)
---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20260819-pidfd-get-paths-59640d8cd1ee
prerequisite-change-id: 20261027-pidfd-task-access-b797ecb260a4:v1
prerequisite-patch-id: 021f6b0840ced7fe967a849b99c366257160c005

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

