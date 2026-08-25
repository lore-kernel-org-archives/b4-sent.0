From: Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
Subject: [PATCH v2 0/2] tracing: Fix remote reader page swap failures
Date: Tue, 25 Aug 2026 12:52:48 -0400
Message-Id: <20260825-kernel-patch-1-v2-0-bb3461807a32@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/3XMQQ6CMBCF4auQWTumLbYBV97DsKh0pBOhJS0hG
 sLdrexd/i953waZElOGa7VBopUzx1BCnSrovQ0DIbvSoIQyolEaX5QCjTjbpfco0TXCUO1ISKu
 hnOZET34f4L0r7TkvMX0Of5W/9S+1ShRIbX1prRUPafRtmCyP5z5O0O37/gWRNM8/rAAAAA==
X-Change-ID: 20260825-kernel-patch-1-d806e3de01a5
To: Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>, 
 Vincent Donnefort <vdonnefort@google.com>
Cc: linux-kernel@vger.kernel.org, linux-trace-kernel@vger.kernel.org, 
 stable@vger.kernel.org, Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1787676803; l=1659;
 i=ivanimmanuel1234@gmail.com; s=20260825; h=from:subject:message-id;
 bh=wcF7uM94hR3OYHjUR0deVPFNJXkbu82Yd2mt83M2Wcs=;
 b=XIY564obFbHXJ78STHg+tNDgIkiB60qq73/Njm1V1Lf53UcL3eyb/0jAPKaHOhGhoJH7WRn8t
 J3a3736XDdaC/aXpBWgDgeJvdAXR9ZemwK0qoaBLGUfy8x424EGdLoU
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
Changes in v2:
- Report callback failures with pr_warn_ratelimited() instead of
  WARN_ON_ONCE(), as suggested by Vincent Donnefort.
- Add Vincent Donnefort's Reviewed-by tag to patch 1.
- Link to v1: https://lore.kernel.org/r/20260825-kernel-patch-1-v1-0-e9349aa0b165@gmail.com

---
Ivan Immanuel Shaji (2):
      tracing: Fix retry exhaustion in simple ring buffer reader swap
      ring-buffer: Stop remote reader update when page swap fails

 kernel/trace/ring_buffer.c        | 7 +++++--
 kernel/trace/simple_ring_buffer.c | 4 ++--
 2 files changed, 7 insertions(+), 4 deletions(-)
---
base-commit: 66498c75b4f8017f62d720d9b59675bdf3abce91
change-id: 20260825-kernel-patch-1-d806e3de01a5

Best regards,
-- 
Ivan Immanuel Shaji <ivanimmanuel1234@gmail.com>

