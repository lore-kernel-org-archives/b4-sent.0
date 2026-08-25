From: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
Subject: [PATCH 0/2] tracing: Fix remote reader page swap failures
Date: Tue, 25 Aug 2026 01:20:36 -0400
Message-Id: <20260825-kernel-patch-1-v1-0-e9349aa0b165@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MQQqAIBBG4avErBtQI4muEi0k/2ooLDQikO6et
 PwW72VKiIJEfZUp4pYkRyjQdUXT6sICFl9MRhmrOtPyhhiw8+muaWXNvlMWjYfSrqUSnRGzPP9
 wGN/3AxXYl1VgAAAA
X-Change-ID: 20260825-kernel-patch-1-d806e3de01a5
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Vincent Donnefort <vdonnefort@google.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787635292; l=1366;
 i=ivanimmanuel1234@gmail.com; s=20260825; h=from:subject:message-id;
 bh=x74r0oqsaq9tYSELP0l1x9/SUc0crA2uxMOnhcHAnpA=;
 b=ObxVAA6UI2ihrhJIU4/e9qvfLbnlcNFTBkhdrffzuyuU9mZ1EYkMCnplYc4UGI0p/FmqxQ8Rd
 jHQhX13kHVSDZda8WvuCSamRddJzrRXoxqKqSKhZRjixHXrI/RyE5yT
X-Developer-Key: i=ivanimmanuel1234@gmail.com; a=ed25519;
 pk=Wx8O3UUs3XneDkbqbOJJnlNdWSpEf2tWbTAoE7/vnqE=
X-Endpoint-Received: by B4 Relay for ivanimmanuel1234@gmail.com/20260825 with auth_id=975
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The simple ring buffer's reader-page swap retry loop mishandles its last
attempt. A success at that point is reported as an error, while a failure
is allowed to continue into the pointer updates. The remote ring buffer
consumer compounds callback failures by warning and continuing with stale
reader metadata.

Fix the retry result in the provider, then stop the remote consumer before
it mutates its local page list when the swap fails.

These paths are used by remote tracing, including arm64 nVHE EL2 tracing
and CONFIG_TRACE_REMOTE_TEST.

Testing:

  make C=2 W=1 kernel/trace/simple_ring_buffer.o kernel/trace/ring_buffer.o
  scripts/checkpatch.pl --no-tree (each formatted patch)

No runtime reproducer was run. The two final-attempt outcomes follow from
the retry counter's post-decrement semantics. An arm64 cross-compiler was
not available.

---
Ivan Immanuel Shaji (2):
      tracing: Fix retry exhaustion in simple ring buffer reader swap
      ring-buffer: Stop remote reader update when page swap fails

 kernel/trace/ring_buffer.c        | 5 +++--
 kernel/trace/simple_ring_buffer.c | 4 ++--
 2 files changed, 5 insertions(+), 4 deletions(-)
---
base-commit: 66498c75b4f8017f62d720d9b59675bdf3abce91
change-id: 20260825-kernel-patch-1-d806e3de01a5

Best regards,
-- 
Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>

