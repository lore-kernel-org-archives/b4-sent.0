From: Joel Granados <j.granados@samsung.com>
Date: Thu, 04 Jan 2024 16:02:24 +0100
Subject: [PATCH v2 03/10] ftrace: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240104-jag-sysctl_remove_empty_elem_kernel-v2-3-836cc04e00ec@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1508;
 i=j.granados@samsung.com; h=from:subject:message-id;
 bh=I9hNdzlwwvGhli848fLvwLS5D8HcBUTWZ1m3n0fKYkE=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBllsiQ+iIfUGpB6FEaBvtcGH6q/CsuMZch60gJQ
 GICfiR4okWJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZZbIkAAKCRC6l81St5ZB
 TxGhDACSRjgkbQ3wyuVeDzSykMrr5lCOo9YiD3YURRMPSxtcjn2ZwMGtvvb9K01XglDnxom8qpf
 gkhHSC6F/JUcVQRlFec9ZrsljdYBKC07mRU3OUdovVNtj+X19130gU+RwSZzyGEIebnVoGWTC3u
 QXIQ8LdsMdFcPySwC1GF7gr2FfmN26XY8D66vwgagg0sdathOv1qvd0X0+rkEZil+FEii16d9h0
 Rn50vRm5eZKB7m6Ujtn+lqnIMCFGjEV4+cNDr0qjos40HXX0j2na5VJMeA7lNnZYOsGxEGc0+jb
 WtcsNHjV+Kezh3JdK+buz/bfvW0VEZZF+9rrrZhmNKJ/3RB6rEFab08nh0NNeOxMqbFxnFgzz4B
 eMc7OZoq/3a4GnDYtZvmosVz5RjQSfkIEMUyob4C5jqeq+kRdlpa0TkwGj0DXmK+hTR9Ka+dc0B
 43l0TNu/GDEm1Ptt+VDnmGRclsw4zk+hK5stlbFKJLJYHJG4L5c2PMsnmMfE/VkbbYzx0=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel elements from ftrace_sysctls and user_event_sysctls

Acked-by: "Masami Hiramatsu (Google)" <mhiramat@kernel.org>
Acked-by: "Steven Rostedt (Google)" <rostedt@goodmis.org>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/trace/ftrace.c            | 1 -
 kernel/trace/trace_events_user.c | 1 -
 2 files changed, 2 deletions(-)

diff --git a/kernel/trace/ftrace.c b/kernel/trace/ftrace.c
index 8de8bec5f366..fd40d02a23c7 100644
--- a/kernel/trace/ftrace.c
+++ b/kernel/trace/ftrace.c
@@ -8264,7 +8264,6 @@ static struct ctl_table ftrace_sysctls[] = {
 		.mode           = 0644,
 		.proc_handler   = ftrace_enable_sysctl,
 	},
-	{}
 };
 
 static int __init ftrace_sysctl_init(void)
diff --git a/kernel/trace/trace_events_user.c b/kernel/trace/trace_events_user.c
index 9365ce407426..b15a103bb11d 100644
--- a/kernel/trace/trace_events_user.c
+++ b/kernel/trace/trace_events_user.c
@@ -2746,7 +2746,6 @@ static struct ctl_table user_event_sysctls[] = {
 		.mode		= 0644,
 		.proc_handler	= set_max_user_events_sysctl,
 	},
-	{}
 };
 
 static int __init trace_events_user_init(void)

-- 
2.30.2

