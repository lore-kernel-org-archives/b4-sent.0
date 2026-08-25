From: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
Date: Tue, 25 Aug 2026 01:20:38 -0400
Subject: [PATCH 2/2] ring-buffer: Stop remote reader update when page swap
 fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260825-kernel-patch-1-v1-2-e9349aa0b165@gmail.com>
References: <20260825-kernel-patch-1-v1-0-e9349aa0b165@gmail.com>
In-Reply-To: <20260825-kernel-patch-1-v1-0-e9349aa0b165@gmail.com>
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Vincent Donnefort <vdonnefort@google.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787635292; l=1498;
 i=ivanimmanuel1234@gmail.com; s=20260825; h=from:subject:message-id;
 bh=Yt3jJEKjDX8/on3DO9yN+/vqaXIqohP/+YVJCaaE2TA=;
 b=KmTfJ3GvG/u3YrBfBZAyX5nOKK+yVn9H2LRQsIdURBZL6eyXNJKeUDzGR4U1N8WGLf9D7C5OU
 bnWoYbWgI93DAs3LZpK+WUo1uq3qAEUUgZNrxB3zqY9axeBmdR+8JnZ
X-Developer-Key: i=ivanimmanuel1234@gmail.com; a=ed25519;
 pk=Wx8O3UUs3XneDkbqbOJJnlNdWSpEf2tWbTAoE7/vnqE=
X-Endpoint-Received: by B4 Relay for ivanimmanuel1234@gmail.com/20260825 with auth_id=975
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The remote swap_reader_page callback can fail when the writer moves the
head before the remote catches it. __rb_get_reader_page_from_remote()
warns about that failure but continues with the unchanged reader ID and
rearranges the local page list as though the swap succeeded.

Stop immediately after warning. Callers already handle a NULL reader
page as a failed attempt, and this avoids splicing the same page as both
the previous and new reader.

Fixes: 2e67fabd8b77 ("ring-buffer: Introduce ring-buffer remotes")
Cc: stable@vger.kernel.org
Assisted-by: LLM sparse
Signed-off-by: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
---
 kernel/trace/ring_buffer.c | 5 +++--
 1 file changed, 3 insertions(+), 2 deletions(-)

diff --git a/kernel/trace/ring_buffer.c b/kernel/trace/ring_buffer.c
index 3c3ed639923d..d11b2759caac 100644
--- a/kernel/trace/ring_buffer.c
+++ b/kernel/trace/ring_buffer.c
@@ -5805,8 +5805,9 @@ __rb_get_reader_page_from_remote(struct ring_buffer_per_cpu *cpu_buffer)
 
 	prev_reader = cpu_buffer->subbuf_ids[cpu_buffer->meta_page->reader.id];
 
-	WARN_ON_ONCE(cpu_buffer->remote->swap_reader_page(cpu_buffer->cpu,
-							  cpu_buffer->remote->priv));
+	if (WARN_ON_ONCE(cpu_buffer->remote->swap_reader_page(cpu_buffer->cpu,
+							      cpu_buffer->remote->priv)))
+		return NULL;
 	/* nr_pages doesn't include the reader page */
 	if (WARN_ON_ONCE(cpu_buffer->meta_page->reader.id > cpu_buffer->nr_pages))
 		return NULL;

-- 
2.53.0

