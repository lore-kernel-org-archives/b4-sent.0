From: Joel Granados <j.granados@samsung.com>
Date: Thu, 04 Jan 2024 16:02:26 +0100
Subject: [PATCH v2 05/10] seccomp: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240104-jag-sysctl_remove_empty_elem_kernel-v2-5-836cc04e00ec@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=933; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=z6EeWSeb/wAILeyqvWIX8FMlRbwGB4xwjlfltNsIiys=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBllsiQF0oBNt6LJkb+zVY5GGJCeSKg2G1eOlNY/
 U9hMugX/3qJAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZZbIkAAKCRC6l81St5ZB
 T7e6DACU+v+qIRdOgR0Vmu/bybMMTZLCFfSEqP2vKHZSh37Ah76SyGQpohwFYIlyBeOBBnPNVyJ
 w8p0UWOfIBTtC+RGTtt2n0ijQHCmzEUBwd2OS+8KyEGACtGvfQ/HTz0ohTLF+dkeSuN36ne0Pc/
 5e7X+WCLZT9/SrcD0xsDhmm1eBnRUVHbBwQVfRVipKlX1xm3KrnZmSfeC5RrFvx0C5HJrJeJ/lA
 /hKTvsd4Lz3IMWylzkkAgqXGSjXjftqgJUEkAHGjptsRIAFAOuOvPq/UN6RctFRocbfHGq4y2is
 jGLLoDYRoLk43HuSXfJlB2y+a4pRp77W8ZH2uzwJkinqJpEMfHIHKB4zlq/sXgYIpyt0m7FMEK+
 diaryq9MeBCXKGs6k1+XLcyj/vWSI1KAYrB2xLVuKd2dsT+dFwovPvTkPayLoVRQusHMPEWXJAg
 /b49Ubys+BjHCNculOLNQoH4Nm+SfvkyVDsf6IrMme51A2DKU3QkWmvfzwebLsO9PnjAE=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from seccomp_sysctl_table.

Acked-by: Kees Cook <keescook@chromium.org>
Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/seccomp.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/seccomp.c b/kernel/seccomp.c
index 255999ba9190..b727b4351c1b 100644
--- a/kernel/seccomp.c
+++ b/kernel/seccomp.c
@@ -2445,7 +2445,6 @@ static struct ctl_table seccomp_sysctl_table[] = {
 		.mode		= 0644,
 		.proc_handler	= seccomp_actions_logged_handler,
 	},
-	{ }
 };
 
 static int __init seccomp_sysctl_init(void)

-- 
2.30.2

