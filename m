From: Joel Granados <j.granados@samsung.com>
Date: Tue, 07 Nov 2023 14:45:04 +0100
Subject: [PATCH 04/10] timekeeping: Remove the now superfluous sentinel
 elements from ctl_table array
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231107-jag-sysctl_remove_empty_elem_kernel-v1-4-e4ce1388dfa0@samsung.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=864; i=j.granados@samsung.com;
 h=from:subject:message-id; bh=rOgjyk+y2sTTf7UpdfCg7T7N07f0Drf2bm8cuUCjmf0=;
 b=owEB7QES/pANAwAKAbqXzVK3lkFPAcsmYgBlSj9lo4lHq3W7DTuFj5cG9c2hzwCA1qpfvT7ET
 DbdUecCRu2JAbMEAAEKAB0WIQSuRwlXJeYxJc7LJ5C6l81St5ZBTwUCZUo/ZQAKCRC6l81St5ZB
 T4l5C/0crurghG7p8vkJdWnAocoHgECRX54CsB63XQcpAUcwN6D3li2qOQ9xTGuPXbQ7gAqbJ4z
 iDEag+GTNufuTyGWM9fOV/cr750yQYoRv2CUBrmWmt774ir7jMqweCCXAk+Lk4hNjmCPHCwU0Kh
 ls61PcywEqFj6ebTD/ux6pFErLrNVI4Cd1XXbyZKY98lGZFmS41eBEgN3KbacG4g6PZXipFGqr1
 kKRa3xzpUR5ZOsF8eeWMeHY3vkAl/YtF7Zt1dwFsOPiqcvYA/0SM+BMVdHDH//iZmWLhahKwD/W
 vvEwSFu2i/AKoccgpVJJfFJQ+/LHD9/RFb2V7qoXgo/8tTYAT3s6VkPjuHXRdCDEwVPbY8Z07N3
 Oi+9iP4azjPvUTcmYcOHqPRaD4OPmqv6UNbce12jqoHR8WNscwxkNs9mXgDI4/pM9gN61UL2n8N
 GFYoJeOf9EJS0IDLS3Q6VRC2XVLIfaTyAxkQtYLPpE2/KEdCoLpn+nxRsQWqKzmXkTWYc=
X-Developer-Key: i=j.granados@samsung.com; a=openpgp;
 fpr=F1F8E46D30F0F6C4A45FF4465895FAAC338C6E77
X-Endpoint-Received: by B4 Relay for j.granados@samsung.com/default with auth_id=70
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit comes at the tail end of a greater effort to remove the
empty elements at the end of the ctl_table arrays (sentinels) which
will reduce the overall build time size of the kernel and run time
memory bloat by ~64 bytes per sentinel (further information Link :
https://lore.kernel.org/all/ZO5Yx5JFogGi%2FcBo@bombadil.infradead.org/)

Remove sentinel element from time_sysctl

Signed-off-by: Joel Granados <j.granados@samsung.com>
---
 kernel/time/timer.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/kernel/time/timer.c b/kernel/time/timer.c
index 63a8ce7177dd..475826ad78df 100644
--- a/kernel/time/timer.c
+++ b/kernel/time/timer.c
@@ -260,7 +260,6 @@ static struct ctl_table timer_sysctl[] = {
 		.extra1		= SYSCTL_ZERO,
 		.extra2		= SYSCTL_ONE,
 	},
-	{}
 };
 
 static int __init timer_sysctl_init(void)

-- 
2.30.2

