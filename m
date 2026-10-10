From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v3 0/4] pidfd: add task path ioctls
Date: Sat, 10 Oct 2026 18:20:49 +0800
Message-Id: <20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIERymoC/2XNTQ6CMBQE4KuQrn2mP4DgynsYF6V9QNUAaWujI
 dzdFl0YWU4y881MHFqDjhyzmVgMxplxiEHsMqJ6OXQIRsdMOOUlrVgNk9Gthg49TNL3Doq6zKm
 ulGaIJK4mi615ruL58snu0VxR+cSkRm+cH+1rvQws9b46pxs9MKAglUDEnFKhi1Nzl+oGGt1tr
 waSHgL/MQTbGjwaqqhRlpKz5sD/jWVZ3uBuq0sIAQAA
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
 "Serge E. Hallyn" <serge@hallyn.com>, Jann Horn <jannh@google.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, apparmor@lists.ubuntu.com, 
 linux-security-module@vger.kernel.org, linux-api@vger.kernel.org, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=4362; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=TgTd211oqhG5HGYlI973E8KqCDKc5Oeemvo00Ob4OL8=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqyhGFlEg1oLTbVChctiMxydeM+7PjwrFf6BR74
 5jDCIlEhsuJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCasoRhQAKCRB2HuYUOZmu
 i7vJD/9Hrm25jbDpfUc64kgjy8iRATYE2TMYLB6diuEQCIz7H1iL2mW93MuWwP3X989ErNtXZhk
 wcdjNkfx5ClKKnS0eJM0n+WBqP2H88p4GLPSk5PfFmg2l1TX6E0S0OkkCKCP8Ks+zewv69+YP+z
 BGOgltFVJWtyxPIAcXtn2nSby8bLmCDNgqvFzy9+QuvYSVQ7o5SD3XKcRAxX2w/RSRZBf3yvRLj
 Zci55BEaFRJRWhN6zFoT8IbyPRh2CxCsr0leOa/HFSPxqSFuHB/wWmt9ZDDP7qv4BATDXckxKbt
 Pv7iF/dYQJxN+rh/7deQ/KEn6lBD3oklYjxgIUMxRkDmVZsvOUZ5TkO0rJefnM5J5MdoFcg/aaV
 I7GoucITJWlMlX1bkXTzAiBsoCApkZ4B6M7t2ka2vnBNceKiHNowSMnoNgg2z5uDdGCXFZdYqie
 MxLe0Od2DPXHqKGj4NxoR2rQljt+3yF4h2Vd0Uw2cclXrsU+S17cr78INgv7hHTD9c5AjYjPO8h
 e0lDzLSxjUh/s93HeXNSkpjvZQRB+kW8oifAQ/dasIFjm3sqWu9LsmHwjK1RrPM5YRGWCuboCoj
 z16jxKJV5IMOv1xa1w2+oJs3blCF8aDd+X5KC4ig1N282vKrm66q8IjZvQlsPG+RmJ3TAnheECG
 urAVptAhXAnOCTw==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Obtaining a target task's executable, working directory, or root
currently requires walking procfs symlinks such as /proc/<pid>/exe,
/proc/<pid>/cwd, and /proc/<pid>/root.  That makes the operation depend
on procfs being mounted and visible to the caller, even when it already
holds a pidfd for the target.

This series adds PIDFD_GET_EXE, PIDFD_GET_CWD, and PIDFD_GET_ROOT. Each
ioctl takes no argument and returns a close-on-exec O_PATH file
descriptor referencing the corresponding task path.  The new ioctls use
the same ptrace permission check and nonzero-argument rejection as the
existing pidfd namespace ioctls.

The target task is sampled while holding its exec_update_lock. This
keeps the access decision and the task-state read in the same exec
critical section, preventing a concurrent execve() from changing the
credentials or target state between the check and the use.

Since pidfds can cross pid namespace boundaries, the first patch
restricts the existing namespace ioctls to targets visible in the
caller's active pid namespace, failing with -EREMOTE like
PIDFD_GET_INFO.  The second patch factors out helpers for acquiring
referenced task paths and reuses them in procfs and AppArmor.  The
third patch introduces scoped cleanup for privileged pidfd task
access, carries the visibility check into the shared task acquisition
helper, and separates namespace lookup from namespace fd creation.
The final patch uses these pieces to implement the three new ioctls.

---
Changes in v3:
- Restrict the pidfd task access ioctls to targets visible in the
  caller's pid namespace, failing with -EREMOTE consistent with
  PIDFD_GET_INFO, following review feedback from Jann Horn and
  Christian Brauner.
- Document that get_task_exe_path() leaves the output path unchanged
  on failure, as suggested by Jann Horn.
- Link to v2: https://patch.msgid.link/20260831-pidfd-get-paths-v2-0-c59ea6a21b72@black-desk.cn

Changes in v2:
- Make pidfd_get_task_locked() own the task reference until it is
  transferred to the pidfd_task_locked cleanup class.
- Link to v1: https://patch.msgid.link/20260820-pidfd-get-paths-v1-0-ac3eee4003d5@black-desk.cn

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
To: Jann Horn <jannh@google.com>
Cc: linux-fsdevel@vger.kernel.org
Cc: linux-kernel@vger.kernel.org
Cc: linux-mm@kvack.org
Cc: apparmor@lists.ubuntu.com
Cc: linux-security-module@vger.kernel.org
Cc: linux-api@vger.kernel.org

---
Chen Linxuan (4):
      pidfd: restrict task access ioctls to the caller's pid namespace
      fs: Introduce task path helpers
      pidfd: Use scoped cleanup for task access
      pidfd: Add task path ioctls

 fs/fs_struct.c             |  44 +++++++++++++
 fs/pidfs.c                 | 158 +++++++++++++++++++++++++++++++++------------
 fs/proc/base.c             |  34 +---------
 include/linux/fs_struct.h  |   3 +
 include/linux/mm.h         |   1 +
 include/uapi/linux/pidfd.h |   7 ++
 kernel/fork.c              |  22 +++++++
 security/apparmor/task.c   |  12 +---
 8 files changed, 198 insertions(+), 83 deletions(-)
---
base-commit: cee9395acd8043be0644b25c34bfa86623f2b935
change-id: 20260819-pidfd-get-paths-59640d8cd1ee

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

