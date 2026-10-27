From: Chen Linxuan <me@black-desk.cn>
Subject: [PATCH v4 0/3] pidfd: add task path ioctls
Date: Tue, 27 Oct 2026 16:46:06 +0800
Message-Id: <20261027-pidfd-get-paths-v4-0-e2a6a47e3c95@black-desk.cn>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22Qy26DMBBFfwV5XVd+8Vz1P6osxuMhuGmAYge1i
 vj3GoiiqsnySjPnPq4s0OQpsCa7solmH/zQJ2FeMoYd9Efi3iXNlFCFqGTNR+9ax48U+QixCzy
 vCyNchU4SsfQ1TtT67434fth1uNgPwrhi1ovOhzhMP5vlLNe7G12JB/osueCAmoiMENrlb/YT8
 MQdhdMr9mx1mNUfhpaPDJUYmNcEBShpS/WMoe8MKeSTHDoxWmVyY4RVVov/jGWvOtHXJW0Y9/7
 MQiCOw/nsY5M5qXOwJtdQpi6gTa2FdQ4ktcY6rABbwEpsK963b7I9kypvmSKEU1oEKQRuy7okt
 Kk3mCZNeViWX+e7sBbRAQAA
X-Change-ID: 20260819-pidfd-get-paths-59640d8cd1ee
To: Alexander Viro <viro@zeniv.linux.org.uk>, 
 Christian Brauner <brauner@kernel.org>, Jan Kara <jack@suse.cz>, 
 Andrew Morton <akpm@linux-foundation.org>, 
 David Hildenbrand <david@kernel.org>, Lorenzo Stoakes <ljs@kernel.org>, 
 "Liam R. Howlett" <liam@infradead.org>, Vlastimil Babka <vbabka@kernel.org>, 
 Mike Rapoport <rppt@kernel.org>, Suren Baghdasaryan <surenb@google.com>, 
 Michal Hocko <mhocko@suse.com>, Kees Cook <kees@kernel.org>, 
 Ingo Molnar <mingo@redhat.com>, Peter Zijlstra <peterz@infradead.org>, 
 Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Steven Rostedt <rostedt@goodmis.org>, Ben Segall <bsegall@google.com>, 
 Mel Gorman <mgorman@suse.de>, Valentin Schneider <vschneid@redhat.com>, 
 K Prateek Nayak <kprateek.nayak@amd.com>, 
 John Johansen <john.johansen@canonical.com>, 
 Georgia Garcia <georgia.garcia@canonical.com>, 
 Paul Moore <paul@paul-moore.com>, James Morris <jmorris@namei.org>, 
 "Serge E. Hallyn" <serge@hallyn.com>
Cc: linux-fsdevel@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mm@kvack.org, apparmor@lists.ubuntu.com, 
 linux-security-module@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=5058; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=7K5N7zpkceKer48CAY5KA1GcflvVMOjT02wequ/ZwwI=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBq4GTRzWFjBBYAkSoCfyF35AnP2cJOwvLQDzp8U
 +FdmKrC1qaJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCauBk0QAKCRB2HuYUOZmu
 i6eMD/wIVN7mWr/rDzRl5O+QhfFzRIu+DC5RKcqCwGYOYKRt4RGz6JA4tr1o1zT+zz9A1sZws1h
 9b4YrzUGpT/3BtQOjfMF55pk5nbOX/5yzi84hAKSvav8bDzx060JGv5aebg6oQdNKoWfgVAvbnw
 V0BUaVIh/n2a0FJ5yA+0JxhzV8VnnYMT1lpNAecXFYtsdchX9N0awErBeoRO11SYyc8QPK9WLOo
 VbwOkbuXV+JsXntvqNo8fG6lmgQK/B7WRFLB1wm9MBn7+vcQq0h3Wv394taZkfmVU0TS/tLTiSd
 HRr7D4EYJQzBwZW+a77Ox98emfT79T1oI1izhm1lfaUWBmTd+hwjmObBNYKLyPDRC++0t6mAgLC
 R8sXkEEsJTI9N5I6/MJgL30dkvhr24qAKHtlT27fa2pe8oLRRGxhMox5VWPS/V9dpG1f/mHHE0e
 cGXD6rCMJJE+TUe6VIsYIHntIJpUDNhpWyL4PZqB2SSJuk/6aob1nZC5EMNE2cYR3KIdl3yPbTX
 uLMcRAzh7ECWZyVoCiJpONNHL3cCbSZ+CbaeU6V01xlu07yP1En/LpVIMST91ly3DqN4vNzOdFZ
 UoLDJZ2tFGHHiqA68/QJ8PiShql662WFt9gtu+UrNtnAwzIEic+mtKlNtDdnDUnHrkrncT24SGT
 wB+p0vvoHzqPRBQ==
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

The first patch factors out helpers for acquiring referenced task paths
and reuses them in procfs and AppArmor. The second patch introduces
scoped cleanup for privileged pidfd task access and separates namespace
lookup from namespace fd creation. The final patch uses these pieces to
implement the three new ioctls.

This series depends on the separately submitted patch:
  pidfd: restrict task access ioctls to the caller's pid namespace
  https://lore.kernel.org/all/20261027-pidfd-task-access-v1-1-d46cf0fa4ca1@black-desk.cn/

That patch was patch 1/4 in v3. It restricts the existing namespace
ioctls to targets visible in the caller's active pid namespace, following
feedback from Jann Horn and Christian Brauner. Apply it on the base
commit recorded below before applying this series.

---
Changes in v4:
- Submit the pid namespace visibility restriction separately and make
  this three-patch series depend on that submission.
- Rebase onto the prerequisite patch on current mainline; no changes
  to the implementation of the three remaining patches.
- Remove Assisted-by trailers following the updated contribution
  guidelines and describe tool assistance in this cover letter.
- Link to v3: https://patch.msgid.link/20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn

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
To: Kees Cook <kees@kernel.org>
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
 fs/pidfs.c                 | 158 ++++++++++++++++++++++++++++++++-------------
 fs/proc/base.c             |  34 +---------
 include/linux/fs_struct.h  |   3 +
 include/linux/mm.h         |   1 +
 include/uapi/linux/pidfd.h |   7 ++
 kernel/fork.c              |  22 +++++++
 security/apparmor/task.c   |  12 +---
 8 files changed, 194 insertions(+), 87 deletions(-)
---
base-commit: d135ab453a7400a34930bdda1ef4bdc8acfac80e
change-id: 20260819-pidfd-get-paths-59640d8cd1ee
prerequisite-change-id: 20261027-pidfd-task-access-b797ecb260a4:v1
prerequisite-patch-id: 021f6b0840ced7fe967a849b99c366257160c005

Best regards,
--  
Chen Linxuan <me@black-desk.cn>

