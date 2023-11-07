From: Joel Granados <j.granados@samsung.com>
Date: Tue, 07 Nov 2023 14:45:06 +0100
Subject: [PATCH 06/10] scheduler: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231107-jag-sysctl_remove_empty_elem_kernel-v1-6-e4ce1388dfa0@samsung.com>
References: <20231107-jag-sysctl_remove_empty_elem_kernel-v1-0-e4ce1388dfa0@samsung.com>
In-Reply-To: <20231107-jag-sysctl_remove_empty_elem_kernel-v1-0-e4ce1388dfa0@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, willy@infradead.org, 
 josh@joshtriplett.org, Kees Cook <keescook@chromium.org>, 
 Eric Biederman <ebiederm@xmission.com>, Iurii Zaikin <yzaikin@google.com>, 
 Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, Mark Rutland <mark.rutland@arm.com>, 
 Thomas Gleixner <tglx@linutronix.de>, John Stultz <jstultz@google.com>, 
 Stephen Boyd <sboyd@kernel.org>, Andy Lutomirski <luto@amacapital.net>, 
 Will Drewry <wad@chromium.org>, Ingo Molnar <mingo@redhat.com>, 
 Peter Zijlstra <peterz@infradead.org>, Juri Lelli <juri.lelli@redhat.com>, 
 Vincent Guittot <vincent.guittot@linaro.org>, 
 Dietmar Eggemann <dietmar.eggemann@arm.com>, 
 Ben Segall <bsegall@google.com>, Mel Gorman <mgorman@suse.de>, 
 Daniel Bristot de Oliveira <bristot@redhat.com>, 
 Valentin Schneider <vschneid@redhat.com>, Petr Mladek <pmladek@suse.com>, 
 John Ogness <john.ogness@linutronix.de>, 
 Sergey Senozhatsky <senozhatsky@chromium.org>, 
 "Naveen N. Rao" <naveen.n.rao@linux.ibm.com>, 
 Anil S Keshavamurthy <anil.s.keshavamurthy@intel.com>, 
 "David S. Miller" <davem@davemloft.net>, 
 Balbir Singh <bsingharora@gmail.com>, Alexei Starovoitov <ast@kernel.org>, 
 Daniel Borkmann <daniel@iogearbox.net>, 
 John Fastabend <john.fastabend@gmail.com>, 
 Andrii Nakryiko <andrii@kernel.org>, 
 Martin KaFai Lau <martin.lau@linux.dev>, Song Liu <song@kernel.org>, 
 Yonghong Song <yonghong.song@linux.dev>, KP Singh <kpsingh@kernel.org>, 
 Stanislav Fomichev <sdf@google.com>, Hao Luo <haoluo@google.com>, 
 Jiri Olsa <jolsa@kernel.org>
Cc: linux-kernel@vger.kernel.org, kexec@lists.infradead.org, 
 linux-fsdevel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 bpf@vger.kernel.org, Joel Granados <j.granados@samsung.com>
X-Mailer: b4 0.13-dev-86aa5
X-Developer-Signature: v=1; a=openpgp-sha256; l=2943;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=UOabK1KMOSqe3o+Y7aCe7ychtiaGw8W/Xw+Jo5nqfNg=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlSj9m0/0KTSsPcytJAUStT6yY9/L65boJ/ucUC
 MnXsvCos+yJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZUo/ZgAKCRC6l81St5ZB
 T43TC/40Pbrt7jYF/1+ZdPMXyj2nNWxVW1FP1P/NJkejo6keYOJhjXwgGaG2lpEWjzMpUjt7bh5
 010MTB1Popmn9JWhay7E9ada95ez9cDkTPVwpKKCQLzG0PBpmJj4Wt+mES5Lr4f4MfjxA7hGYEs
 nNdsjX+vKuWJoRaLjYH4PxXczDYL+ETp2Za/MYXIO2/SbcuWj3QZoKdQdsiogP597lzsoskunnF
 UzMNGen0PbKndqqwj+SIEWhHw5xUIu2m1saG4dESLdkBZ0SD3rihdOBBCa041pHrX9f0+i6k4s2
 uc+fE+UHx/3w5toDzlBdfKcs0m8wCLfbGhPZiaNlN559n7a31xvMEzcsMSXtfc4Rg0+SFUGOqKQ
 WyP/lw5FyxU46uzO70Srud3C/eA0MsNY9toa/NwkMHowC+n11bEtLfp978W9dCpkV9ZldQbmaEE
 tYGsgxe2HrDCgnmFUjEnl5EPe2CykDFDPgD8P1z7/I+NpzkKhGIq2f8KFQxU2HjKZc0QY=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

rm sentinel element from ctl_table arrays

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/sched/autogroup.c | 1 -
 kernel/sched/core.c      | 1 -
 kernel/sched/deadline.c  | 1 -
 kernel/sched/fair.c      | 1 -
 kernel/sched/rt.c        | 1 -
 kernel/sched/topology.c  | 1 -
 6 files changed, 6 deletions(-)

diff --git a/kernel/sched/autogroup.c b/kernel/sched/autogroup.c
index 991fc9002535..db68a964e34e 100644
--- a/kernel/sched/autogroup.c
+++ b/kernel/sched/autogroup.c
@@ -19,7 +19,6 @@ static struct ctl_table sched_autogroup_sysctls[] = {
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
 	},
-	{}
 };
 
 static void __init sched_autogroup_sysctl_init(void)
diff --git a/kernel/sched/core.c b/kernel/sched/core.c
index 2299a5cfbfb9..d45cd41f08b5 100644
--- a/kernel/sched/core.c
+++ b/kernel/sched/core.c
@@ -4712,7 +4712,6 @@ static struct ctl_table sched_core_sysctls[] = {
 		.extra2		= SYSCTL_FOUR,
 	},
 #endif /* CONFIG_NUMA_BALANCING */
-	{}
 };
 static int __init sched_core_sysctl_init(void)
 {
diff --git a/kernel/sched/deadline.c b/kernel/sched/deadline.c
index 58b542bf2893..11f6e9a279d0 100644
--- a/kernel/sched/deadline.c
+++ b/kernel/sched/deadline.c
@@ -43,7 +43,6 @@ static struct ctl_table sched_dl_sysctls[] = {
 		.proc_handler   = proc_douintvec_minmax,
 		.extra2         = (void *)&sysctl_sched_dl_period_max,
 	},
-	{}
 };
 
 static int __init sched_dl_sysctl_init(void)
diff --git a/kernel/sched/fair.c b/kernel/sched/fair.c
index cb225921bbca..8fd5b8435a9e 100644
--- a/kernel/sched/fair.c
+++ b/kernel/sched/fair.c
@@ -172,7 +172,6 @@ static struct ctl_table sched_fair_sysctls[] = {
 		.extra1		= SYSCTL_ZERO,
 	},
 #endif /* CONFIG_NUMA_BALANCING */
-	{}
 };
 
 static int __init sched_fair_sysctl_init(void)
diff --git a/kernel/sched/rt.c b/kernel/sched/rt.c
index 0597ba0f85ff..a6bcbef33e68 100644
--- a/kernel/sched/rt.c
+++ b/kernel/sched/rt.c
@@ -52,7 +52,6 @@ static struct ctl_table sched_rt_sysctls[] = {
 		.mode           = 0644,
 		.proc_handler   = sched_rr_handler,
 	},
-	{}
 };
 
 static int __init sched_rt_sysctl_init(void)
diff --git a/kernel/sched/topology.c b/kernel/sched/topology.c
index 05a5bc678c08..af998dbe097f 100644
--- a/kernel/sched/topology.c
+++ b/kernel/sched/topology.c
@@ -250,7 +250,6 @@ static struct ctl_table sched_energy_aware_sysctls[] = {
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
 	},
-	{}
 };
 
 static int __init sched_energy_aware_sysctl_init(void)

-- 
2.30.2

