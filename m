From: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
Date: Tue, 25 Aug 2026 12:52:50 -0400
Subject: [PATCH v2 2/2] ring-buffer: Stop remote reader update when page
 swap fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-kernel-patch-1-v2-2-bb3461807a32@gmail.com>
References: <20260825-kernel-patch-1-v2-0-bb3461807a32@gmail.com>
In-Reply-To: <20260825-kernel-patch-1-v2-0-bb3461807a32@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Vincent Donnefort <vdonnefort@google.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787676803; l=1736;
 i=ivanimmanuel1234@gmail.com; s=20260825; h=from:subject:message-id;
 bh=LNL2ffJz8llLBy4R+x3iJYnTiH9lI0OfoRC4hz5apiw=;
 b=QJKEN/5hZjtWkMBMH/i//qnraPVZXGGRR6NaiSx4oqq97BchClSXatijJio6RkkoNRwlXovwC
 VCPjsCR5Th5DCwPrek+JH9QfoB5TYU6QQAzsDO/Dc1D+/dccnIybkcB
X-Developer-Key: i=ivanimmanuel1234@gmail.com; a=ed25519;
 pk=Wx8O3UUs3XneDkbqbOJJnlNdWSpEf2tWbTAoE7/vnqE=
X-Endpoint-Received: by B4 Relay for ivanimmanuel1234@gmail.com/20260825 with auth_id=975
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The remote swap_reader_page callback can return -EBUSY when the writer
moves the head before the remote catches it, particularly during an event
storm on a small buffer. __rb_get_reader_page_from_remote() currently
warns about that failure but continues with the unchanged reader ID and
rearranges the local page list as though the swap succeeded.

Handle the callback failure as a recoverable error. Report it with
pr_warn_ratelimited() and return NULL. Callers already handle a NULL reader
page as a failed attempt. This avoids splicing the same page as both the
previous and new reader without flooding the log under contention.

Fixes: 2e67fabd8b77 ("ring-buffer: Introduce ring-buffer remotes")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse
Signed-off-by: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
---
 kernel/trace/ring_buffer.c | 7 +++++--
 1 file changed, 5 insertions(+), 2 deletions(-)

diff --git a/kernel/trace/ring_buffer.c b/kernel/trace/ring_buffer.c
index 3c3ed639923d..b0963ac6fd16 100644
--- a/kernel/trace/ring_buffer.c
+++ b/kernel/trace/ring_buffer.c
@@ -5805,8 +5805,11 @@ __rb_get_reader_page_from_remote(struct ring_buffer_per_cpu *cpu_buffer)
 
 	prev_reader = cpu_buffer->subbuf_ids[cpu_buffer->meta_page->reader.id];
 
-	WARN_ON_ONCE(cpu_buffer->remote->swap_reader_page(cpu_buffer->cpu,
-							  cpu_buffer->remote->priv));
+	if (cpu_buffer->remote->swap_reader_page(cpu_buffer->cpu,
+						 cpu_buffer->remote->priv)) {
+		pr_warn_ratelimited("Remote reader page swap failed\n");
+		return NULL;
+	}
 	/* nr_pages doesn't include the reader page */
 	if (WARN_ON_ONCE(cpu_buffer->meta_page->reader.id > cpu_buffer->nr_pages))
 		return NULL;

-- 
2.53.0

