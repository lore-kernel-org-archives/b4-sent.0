From: Joel Granados <j.granados@samsung.com>
Date: Thu, 28 Mar 2024 16:44:10 +0100
Subject: [PATCH v3 09/10] delayacct: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240328-jag-sysctl_remove_empty_elem_kernel-v3-9-285d273912fe@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=901; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=i6rZdV8sO6keniVz/tdr/tgncwQ879+rgbNywApATf4=;
 b=owJ4nAHtARL+kA0DAAoBupfNUreWQU8ByyZiAGYFkE6p4PaxshghascUKUubW96pCKfCYMXWK
 /aBSiIGgBYe9IkBswQAAQoAHRYhBK5HCVcl5jElzssnkLqXzVK3lkFPBQJmBZBOAAoJELqXzVK3
 lkFPT5QL/jFMK8C8aAUdHmCMTOc9tNhM631bX9/8b8lUvEasqWg0CLuygFHjzAxdGGUi6f2nMno
 kUA+T74QXcgNWEfjN8VdVP/NO4Hz21SVA+aCZP0vFbtKHAWBkHmYwmnWX0fPlkGMJCrUunVQyKT
 /67OzmNJMzHHhjA/5fn7WKriT/aSjVsfwMvG4vmTR6pFuRckh3PfzYN490bT09jtp1LM5eUpmG8
 v+ea5g4zkwWid2odf83OnRVh4vdoUz5SuApM5ocoFDK7fQ6gmTKXpn9+d22D/KNKyXUPTutUE6b
 B+0o078nrfEIiOgvo4renClDzc1apR/G+d1RNpqmV8CYDBGy1C/udE8mtdW8dL14nv07BW4TQ75
 7DrHQJXonF56KDikz3C/7owWHYyRwwWaSoa3lP3hankVdZGw4kpt1l5d4Zc7t/LBDUip5/4gAew
 VC1fPxiZoxYHw1Y5wWleWrZgF2lyeO69C7f9SD9OUdRUvMTemIC3m7QuHy3ZmGO6//TXewH9oV6
 tI=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from kern_delayacct_table

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/delayacct.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/delayacct.c b/kernel/delayacct.c
index 6f0c358e73d8..e039b0f99a0b 100644
--- a/kernel/delayacct.c
+++ b/kernel/delayacct.c
@@ -74,7 +74,6 @@ static struct ctl_table kern_delayacct_table[] = {
 		.extra1         = SYSCTL_ZERO,
 		.extra2         = SYSCTL_ONE,
 	},
-	{ }
 };
 
 static __init int kernel_delayacct_sysctls_init(void)

-- 
2.43.0

