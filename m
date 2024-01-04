From: Joel Granados <j.granados@samsung.com>
Date: Thu, 04 Jan 2024 16:02:31 +0100
Subject: [PATCH v2 10/10] bpf: Remove the now superfluous sentinel elements
 from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240104-jag-sysctl_remove_empty_elem_kernel-v2-10-836cc04e00ec@samsung.com>
References: <20240104-jag-sysctl_remove_empty_elem_kernel-v2-0-836cc04e00ec@samsung.com>
In-Reply-To: <20240104-jag-sysctl_remove_empty_elem_kernel-v2-0-836cc04e00ec@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=940; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=/9ILE3EKbQ2mssrD1gckEhIuv3CDk/DZxHhwPHwwEx0=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBllsiRAKw5WmSLeFL9pLCoRkD2xOQzfyE2LboDw
 7ti0+VZZtOJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZZbIkQAKCRC6l81St5ZB
 T+WWC/0RXYSdLR/7IJeBBz6p9iDgvsYnr/AK9k7hr4RjLa+NqM+EVZaGeryYzNo/F6bySHxjVV+
 yCo/sJQztfLOk+xflQF2dbpXVxt4E2GLVXuzPa+t3RnJ/cokx39+4aHygNHzHx4X7xtFEvvdWPE
 YVk42LgKRPB0L4ZZEMdIq9tHQW7izXPTf7XufBrOUuryFzhStFPaSm4t2vvYugAcHr8nv6Hgvwh
 zzkB1CJ9WSUqizPTWcvGMxjZm4SG0hxwR/jMkBM/dBWo47XY0GEGmFQPP4NKjklcQd9cfe+lMbF
 kcnj6FWGOkQmGQLiJCopj0UaNyI7NQmPXqwoglLn3oRUWHv+aPmaByl4Rfau9iD+RIoikEzC0nC
 NjMbYBfS70oxYAs/nrvCxCOVlp+4t6AS9h1QjsxPffPDrPS8ODiDJ63K3YJQNWZbZdt7xr0CPK4
 2RvIJDb3eOOIuAZ/+bSDks7jIt8APRQGbZQOnG2Qr7X+GYIMUcQ92silNWmLhqTEEi6ko=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from bpf_syscall_table.

Acked-by: Andrii Nakryiko <andrii@kernel.org>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/bpf/syscall.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/bpf/syscall.c b/kernel/bpf/syscall.c
index 0ed286b8a0f0..2790deabf639 100644
--- a/kernel/bpf/syscall.c
+++ b/kernel/bpf/syscall.c
@@ -5727,7 +5727,6 @@ static struct ctl_table bpf_syscall_table[] = {
 		.mode		= 0644,
 		.proc_handler	= bpf_stats_handler,
 	},
-	{ }
 };
 
 static int __init bpf_syscall_sysctl_init(void)

-- 
2.30.2

