From: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
Date: Tue, 25 Aug 2026 12:52:49 -0400
Subject: [PATCH v2 1/2] tracing: Fix retry exhaustion in simple ring buffer
 reader swap
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-kernel-patch-1-v2-1-bb3461807a32@gmail.com>
References: <20260825-kernel-patch-1-v2-0-bb3461807a32@gmail.com>
In-Reply-To: <20260825-kernel-patch-1-v2-0-bb3461807a32@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Vincent Donnefort <vdonnefort@google.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787676803; l=1669;
 i=ivanimmanuel1234@gmail.com; s=20260825; h=from:subject:message-id;
 bh=0wlmuiqSThih8CNT0Jea/HbIHZ739kvpr2URRAfi46Y=;
 b=R2DpCEXju5XYQhQ2OyLBs0xLycXPVX5jRLVbIskDnXkcQD5sSsTRK67g0iwBxw7xpkTviX/o3
 9ly37jhgzggAXm1tVCvEcC0k1OgHoBNUAtqzvrMvu7BgQznSAN4nOoP
X-Developer-Key: i=ivanimmanuel1234@gmail.com; a=ed25519;
 pk=Wx8O3UUs3XneDkbqbOJJnlNdWSpEf2tWbTAoE7/vnqE=
X-Endpoint-Received: by B4 Relay for ivanimmanuel1234@gmail.com/20260825 with auth_id=975
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

simple_ring_buffer_swap_reader_page() starts with retry set to 8 and
post-decrements it only after a failed link replacement. On the final
attempt, a successful replacement leaves retry at zero, while a failed
replacement leaves it at -1.

The current !retry test reverses both outcomes. It returns an error after
a successful final replacement, leaving the link update complete but the
reader bookkeeping unfinished. After a failed final replacement, it
falls through and updates the head and reader pointers as though the
replacement succeeded, which can corrupt the ring.

Treat only a negative counter as exhaustion and return the documented
-EBUSY error.

Fixes: 34e5b958bdad ("tracing: Introduce simple_ring_buffer")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse
Reviewed-by: Vincent Donnefort <vdonnefort@google.com>
Signed-off-by: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
---
 kernel/trace/simple_ring_buffer.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/kernel/trace/simple_ring_buffer.c b/kernel/trace/simple_ring_buffer.c
index f4642f5adda3..49913bb0057a 100644
--- a/kernel/trace/simple_ring_buffer.c
+++ b/kernel/trace/simple_ring_buffer.c
@@ -160,8 +160,8 @@ int simple_ring_buffer_swap_reader_page(struct simple_rb_per_cpu *cpu_buffer)
 		overrun = cpu_buffer->meta->overrun;
 	} while (!simple_bpage_unset_head_link(last, reader, SIMPLE_RB_LINK_NORMAL) && retry--);
 
-	if (!retry)
-		return -EINVAL;
+	if (retry < 0)
+		return -EBUSY;
 
 	cpu_buffer->head_page = simple_bpage_from_link(reader->link.next);
 	cpu_buffer->head_page->link.prev = &reader->link;

-- 
2.53.0

