From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH RFC 0/3] pidfd: add task path ioctls
Date: Thu, 20 Aug 2026 13:45:38 +0800
Message-Id: <20260820-pidfd-get-paths-v1-0-ac3eee4003d5@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIKUhmoC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzMDC0NL3YLMlLQU3fTUEt2CxJKMYl1TSzMTgxSL5BTD1FQloK6CotS0zAq
 widFKQW7OSrEQweLSpKzU5BKQWUq1tQACpIQNeAAAAA==
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
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=2014; i=me@black-desk.cn;
 h=from:subject:message-id; bh=UY6R+FfPzasxj/Dnn81Uka4E7YYktrqvv/sImm7YIxQ=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqhpSDV8lzoXhNWvb6mCjlmhmRXIKL96NlDz9RG
 uwcg9YQkTGJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaoaUgwAKCRB2HuYUOZmu
 i5OnD/9Q2SjkQW1h+c/+qLhCrhq/tFbDRt8y4anyttX5n0ozBKY1ROAd5938lTwWrxvE2on7GH2
 Ed2SCyxk4p/eAUkUx9Pnx8Mt7wF9UxcSrv5gPlJujrDJ0ayEqcfekGWK3ilR+VjLlX52E8W0oE8
 Nsub6HhzxTJF8hA6iudjclMoQAOLRtYKbSxB9eoHfKqNsaPSSKJfWdIYYr66FmgKDTe1hmFnavD
 8m6w4oNr0pVOyIAgF6ETD/xMhFA0L3MrjtjDSDrqZFxxAHK1pPCdLBWXdO0lSRj7zV35KNNaTsd
 Kk3xNNf9ExLiO6+hvF4iqOq+0HNblbojWt/criDINke66q29D20hZcGReta1XAW4uEKYp56XWMi
 dVwZncXvkTusEUl9K1UXY4uRAkWNdOyDBv3zAHqzzAXfzPuUhYvgfZfbnJUl2sMdMiZw+cVJZjS
 uxyELiapFXp/I/yDnsmJ/+jQJcLQPpXhr7U0smvU83Lfcpom3dvOFhVQTgIJrkCHDz0Giv9RgzZ
 A5xGV4k7XSuM/A24/oZhz/ylcYTFJyxcj5gZSA6DYZbfoT7YsFVhABW5DckRCr9hzF2HA1KIDCs
 rx4LYqHEWwi84GPdEcVZMoj9GIA1S+b3UYvC8Q2MQkxF/Rga/hXhznAc679HUyG2vzXOgtHSvqS
 GnM6BZwjacrSeBA==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
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

The first patch factors out helpers for acquiring referenced task paths
and reuses them in procfs and AppArmor.  The second patch introduces
scoped cleanup for privileged pidfd task access and separates namespace
lookup from namespace fd creation.  The final patch uses these pieces to
implement the three new ioctls.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
Chen Linxuan (3):
      fs: Introduce task path helpers
      pidfd: Use scoped cleanup for task access
      pidfd: Add task path ioctls

 fs/fs_struct.c             |  44 +++++++++++++
 fs/pidfs.c                 | 161 ++++++++++++++++++++++++++++++++-------------
 fs/proc/base.c             |  34 +---------
 include/linux/fs_struct.h  |   3 +
 include/linux/mm.h         |   1 +
 include/uapi/linux/pidfd.h |   7 ++
 kernel/fork.c              |  21 ++++++
 security/apparmor/task.c   |  12 +---
 8 files changed, 196 insertions(+), 87 deletions(-)
---
base-commit: a4ff2be345d0abc943da8dd8da98151843b750dc
change-id: 20260819-pidfd-get-paths-59640d8cd1ee

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

