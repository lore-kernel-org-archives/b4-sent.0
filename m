From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:44:09 +0100
Subject: [PATCH v3 08/10] kprobes: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remove_empty_elem_kernel-v3-8-285d273912fe@samsung.com>
References: <20240328-jag-sysctl_remove_empty_elem_kernel-v3-0-285d273912fe@samsung.com>
In-Reply-To: <20240328-jag-sysctl_remove_empty_elem_kernel-v3-0-285d273912fe@samsung.com>
To: Luis Chamberlain <mcgrof@kernel.org>, josh@joshtriplett.org, 
 Kees Cook <keescook@chromium.org>, Eric Biederman <ebiederm@xmission.com>, 
 Iurii Zaikin <yzaikin@google.com>, Steven Rostedt <rostedt@goodmis.org>, 
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
X-Mailer: b4 0.13-dev-2d940
X-Developer-Signature: v=1; a=openpgp-sha256; l=918; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=W9k8f49EwG/feirGtDw1FHGcG6plJdUzpOL5hpVCueM=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFkE0ZcrBDVAp4O3SfOrgyc8WUlGwe1ykjS
 ABM/79ogIBhtIkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZBNAAoJELqXzVK3
 lkFPIp4L/2jEVev1Ry+FHuhUOpPE5D5ElBE2orb/y33yGm7mtGXFzKAMW8bq+PtlQw5Pu4SBw3g
 ujwQmB3s4n3ZRJ2YfYwPdHaPKJNFYvJbf24y9Aa58BDtW92sRNapggll7sLkDoWHaUehAMmC3ht
 LV89vSfFhng6Bzrz/MoTAtl8qyy1IM1RF7ASwOu1Q1jgEgyMw5/xpYlDksNUd/HP3GEjOl27I/U
 IfF77tqPAX4oGhcI5ZI8l/2Js13SrNFOspXDoD3ctfuVJQ8mD5E4+uUrSaWyIqlMOMVCzvcSM8L
 7kkRm8s1XoX/pwKolO2w0dr2q3M5Wzm7L/ycTsrKH0sAqSS5DAXZ3aFwUmg0Xbs25N7LMsVNQ4/
 l1BPYwsVLL7928+A+Ly/vfxMheOUkkSS5fiMY7kMh1cdoU4JqjjruiM0SeFQFjXwmSl7mVBt2GV
 /b/2YR1FuOR2ptrzCF46iDCBOkpZZ4CyiuHZE1kNBenIZZDgZgZQ5alrbrswjTB0PEIzApN/2I4
 BQ=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from kprobe_sysclts

Acked-by: "Masami Hiramatsu (Google)" <mhiramat@kernel.org>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/kprobes.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/kprobes.c b/kernel/kprobes.c
index 9d9095e81792..85af0e05a38f 100644
--- a/kernel/kprobes.c
+++ b/kernel/kprobes.c
@@ -968,7 +968,6 @@ static struct ctl_table kprobe_sysctls[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{}
 };
 
 static void __init kprobe_sysctls_init(void)

-- 
2.43.0

