From: Mike Bazov <mike.bazov@gmail.com>
Date: Fri, 20 Nov 2026 12:59:12 +0200
Subject: [PATCH bpf-next v3 2/3] bpf: Limit nesting of mmap_read_trylock()
 in BPF helpers
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261120-bpf-raw-tp-regs-preempt-v3-2-ec109009a5d2@gmail.com>
References: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
In-Reply-To: <20261120-bpf-raw-tp-regs-preempt-v3-0-ec109009a5d2@gmail.com>
To: Song Liu <song@kernel.org>, Jiri Olsa <jolsa@kernel.org>, 
 Ihor Solodrai <ihor.solodrai@linux.dev>, 
 Alexei Starovoitov <ast@kernel.org>, Daniel Borkmann <daniel@iogearbox.net>, 
 Andrii Nakryiko <andrii@kernel.org>, Eduard Zingerman <eddyz87@gmail.com>, 
 Kumar Kartikeya Dwivedi <memxor@gmail.com>, 
 Martin KaFai Lau <martin.lau@linux.dev>, 
 Yonghong Song <yonghong.song@linux.dev>, 
 Emil Tsalapatis <emil@etsalapatis.com>, KP Singh <kpsingh@kernel.org>, 
 Matt Bobrowski <matt@bobrowski.net>, Steven Rostedt <rostedt@goodmis.org>, 
 Masami Hiramatsu <mhiramat@kernel.org>, 
 Mathieu Desnoyers <mathieu.desnoyers@efficios.com>
Cc: bpf@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-trace-kernel@vger.kernel.org, Mike Bazov <mike.bazov@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795172363; l=3076;
 i=mike.bazov@gmail.com; s=gmail-20261116; h=from:subject:message-id;
 bh=HKoapPVt+y68Tmqmk8BOQ4lm6ZdE9zNq151YdINJiy8=;
 b=FBHB3WVLGm2+Z5TJ4RNHlFPXH/ljQYiLTyzi0rFT/3iP4qs9oFRUjuDAZoYdstzetwlw4TCcE
 Ih8rA23e/cUAEfK+WqczgpuX+Y13GbFzCYkEF31CIzhf2enWOS3Rv3k
X-Developer-Key: i=mike.bazov@gmail.com; a=ed25519;
 pk=Rr9fagn0pNA+bs8tgc6DXZpRAhl/maU6BeqkttIR7DA=
X-Endpoint-Received: by B4 Relay for mike.bazov@gmail.com/gmail-20261116 with auth_id=1544
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

bpf_get_stack() and bpf_get_stackid() with BPF_F_USER_BUILD_ID, and
bpf_find_vma(), take mmap_read_trylock() on the current mm. That fires
the mmap_lock tracepoints, so a program on one of them that calls these
helpers runs the tracepoint again from inside itself:

  prog 1 on mmap_lock_acquire_returned
    bpf_get_stack(BPF_F_USER_STACK | BPF_F_USER_BUILD_ID)
      mmap_read_trylock()
        prog 2 on mmap_lock_acquire_returned
          bpf_get_stack(...)
            mmap_read_trylock()
              ...

The recursion check of each program only stops it from running inside
itself, so this nests as deep as there are programs attached, and each
level runs all programs that aren't on the stack yet: the work per
tracepoint hit grows with the factorial of the number of programs. With
irqs disabled, the per-CPU irq_work already allows only one level; with
irqs enabled nothing limits it.

Count the levels per CPU with irqs enabled too and fail with -EBUSY past
three, the same depth as the other per-CPU nesting limits of BPF
tracing. The helpers then fall back as they do when the trylock fails:
bpf_get_stack() and bpf_get_stackid() return IPs instead of build IDs,
and bpf_find_vma() returns -EBUSY.

The counter is per CPU, and programs with irqs enabled can be
preempted, so a preempted holder counts against the other tasks on its
CPU. They can hit the limit early and get the fallback; they never get
wrong data.

Suggested-by: Alexei Starovoitov <ast@kernel.org>
Signed-off-by: Mike Bazov <mike.bazov@gmail.com>
---
 kernel/bpf/mmap_unlock_work.h | 16 ++++++++++++++--
 1 file changed, 14 insertions(+), 2 deletions(-)

diff --git a/kernel/bpf/mmap_unlock_work.h b/kernel/bpf/mmap_unlock_work.h
index 1834db20b..02af564e6 100644
--- a/kernel/bpf/mmap_unlock_work.h
+++ b/kernel/bpf/mmap_unlock_work.h
@@ -13,6 +13,7 @@ struct mmap_unlock_irq_work {
 	struct irq_work irq_work;
 	struct mm_struct *mm;
 	atomic_t active;
+	int nest_level;
 };
 
 DECLARE_PER_CPU(struct mmap_unlock_irq_work, mmap_unlock_work);
@@ -28,8 +29,16 @@ static inline struct mmap_unlock_irq_work *bpf_mmap_unlock_guard_get(void)
 {
 	struct mmap_unlock_irq_work *work;
 
-	if (!irqs_disabled())
-		return NULL;
+	if (!irqs_disabled()) {
+		/*
+		 * mmap_read_trylock() fires the mmap_lock tracepoints, and
+		 * programs on them can get here again.
+		 */
+		if (this_cpu_inc_return(mmap_unlock_work.nest_level) <= 3)
+			return NULL;
+		this_cpu_dec(mmap_unlock_work.nest_level);
+		return ERR_PTR(-EBUSY);
+	}
 
 	/*
 	 * PREEMPT_RT does not allow to trylock mmap sem in interrupt
@@ -51,12 +60,15 @@ bpf_mmap_unlock_guard_put(struct mmap_unlock_irq_work *work)
 {
 	if (work)
 		atomic_set_release(&work->active, 0);
+	else
+		this_cpu_dec(mmap_unlock_work.nest_level);
 }
 
 static inline void bpf_mmap_unlock_mm(struct mmap_unlock_irq_work *work, struct mm_struct *mm)
 {
 	if (!work) {
 		mmap_read_unlock(mm);
+		bpf_mmap_unlock_guard_put(NULL);
 	} else {
 		work->mm = mm;
 

-- 
2.43.0

