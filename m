From: Chen Linxuan <me@black-desk.cn>
Date: Sat, 10 Oct 2026 18:20:50 +0800
Subject: [PATCH v3 1/4] pidfd: restrict task access ioctls to the caller's
 pid namespace
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261010-pidfd-get-paths-v3-1-f245440b2b30@black-desk.cn>
References: <20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn>
In-Reply-To: <20261010-pidfd-get-paths-v3-0-f245440b2b30@black-desk.cn>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2240; i=me@black-desk.cn;
 s=20260831; h=from:subject:message-id;
 bh=ZFhe6igvJd4uMFSrgyXSrlw/Pf3UD8vwdWrIzJThCwk=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBqyhGbwdr4RORhdN9GzarNd1upM7l3SBuv2j7+5
 M5Vfu1jfYqJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCasoRmwAKCRB2HuYUOZmu
 i1ZjEADeM+TRIHmXm1K3ljsbCmJXeQECqXkRs4A1DVU3R0hrJUwIoq97CU2fSSgcJ2rl+MtEbDW
 6nX3DGAmt4fIa1MEdyoH0Bd0Z3HPIunFVu7oBNvfCdRFUPoXpJdoLLR6N2qkFTmbol406QnWGD9
 ccDtowKgDXT64e0LGg5A97UYH2tGqHpWroGsgHrg4dIPsoSDydzf9qk9M2yElfq/kCjc0X2XP7p
 rTODO1CgcXD6tdpvBhlE5xfAkxJglbbhyuB39rwv12DVL6yXuR+xxA7u3MX3XwcXim6fBCQBfQA
 BrIu0XBOAUXLvV7V/IW/5g+tbOH/zKkjlWS1CzHi3fs17Uv+GfuGbJ67YC0LzKyhpki1xsh/8IU
 lszpVys3+rnT+b3zw6FuhZhvOgqFibKezDeyieH7R8dYY+07aHp28h7RRIemZnkkQdrRG/MUBcc
 To+qPae2CpHDfzZp2QirkTGXLNIEEV6x5f6HoQlm9Elmgyc7WaGQ0fga8q4TOwVvzMTeCCmRTt4
 od7L8erLn6CwtoKvYXbLeRujmoIFFM2k1kJxeR9CubO51sJH8q4mrRJWwcMo7Tw27yMrT+Ptd9w
 F3UR/Rk1JPvbHy2Oz15U59VFqXgkuDcVyOMXgXypZKtE+ZCth1jX8UHEViu4wW5AWQVw0JV3G1C
 +hOE64bf3nsV8og==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/20260831 with auth_id=991
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

pidfds can cross pid namespace boundaries: a task may obtain one for a
process outside of its own pid namespace hierarchy through SO_PASSPIDFD
or SO_PEERPIDFD, via SCM_RIGHTS, or through file descriptor inheritance.

The namespace ioctls gate access with a ptrace check against the
target's credentials only. That check does not account for the pid
namespace relationship between the caller and the target, so a task
inside a pid namespace can use a pidfd obtained across that boundary to
acquire namespace file descriptors of a task outside of its hierarchy.

procfs exposes the equivalent information only for tasks visible in the
reader's pid namespace, and PIDFD_GET_INFO already answers with -EREMOTE
for targets outside the caller's hierarchy. Extend that policy to the
namespace ioctls: fail with -EREMOTE unless the target is visible in the
caller's active pid namespace. Callers in ancestor pid namespaces are
unaffected.

Unlike PIDFD_GET_INFO, the visibility check is performed after the task
lookup here, so reaped targets outside of the caller's pid namespace
hierarchy answer -ESRCH instead of -EREMOTE.

Link: https://lore.kernel.org/all/CAG48ez1T5-tUHVK_iHsgUtWa-inVdrZxA3E-ZCW0iENJvasKfg@mail.gmail.com
Link: https://lore.kernel.org/all/20260925-gewischt-auftrag-tierzucht-c153cb3f9f74@brauner
Suggested-by: Jann Horn <jannh@google.com>
Suggested-by: Christian Brauner <brauner@kernel.org>
Assisted-by: LLM
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 fs/pidfs.c | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/fs/pidfs.c b/fs/pidfs.c
index a6a643f15d08..791f7efceabe 100644
--- a/fs/pidfs.c
+++ b/fs/pidfs.c
@@ -556,6 +556,14 @@ static long pidfd_ioctl(struct file *file, unsigned int cmd, unsigned long arg)
 	if (arg)
 		return -EINVAL;
 
+	/*
+	 * Require the target to be visible in the caller's pid namespace
+	 * for operations that grant access to its resources, mirroring
+	 * procfs and PIDFD_GET_INFO.
+	 */
+	if (!pid_in_current_pidns(pidfd_pid(file)))
+		return -EREMOTE;
+
 	/*
 	 * We're trying to open a file descriptor to the namespace so perform a
 	 * filesystem cred ptrace check. Hold @task's exec_update_lock for the

-- 
2.55.0

