From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 12 Aug 2026 13:48:11 +0800
Subject: [PATCH 5/5] powerpc/spufs: fix mmap_lock/state_mutex lock
 inversion
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-spufs-fixes-v1-5-449e201d9f64@outlook.com>
References: <20260812-spufs-fixes-v1-0-449e201d9f64@outlook.com>
In-Reply-To: <20260812-spufs-fixes-v1-0-449e201d9f64@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 David Howells <dhowells@redhat.com>, Al Viro <viro@zeniv.linux.org.uk>, 
 Jeremy Kerr <jk@ozlabs.org>, Arnd Bergmann <arnd@arndb.de>, 
 Paul Mackerras <paulus@ozlabs.org>, 
 Luke Browning <lukebr@linux.vnet.ibm.com>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=2374;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=A766Kj+SIMmBxr8tNi5fB2Rg8hveBn1dANRK8rQSu+Q=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBpO+XRRIc3NC47r6O/m+7zeYs7WdU9Dvn4P3qri+
 LeuWVgrnL2jlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJrLvNSPD33kyX19tsint
 9nylHb89ZypfYZi844bdeh4Za60eWpUzMPwVmLbNn+3dlKPr07u38NVPm3Io7+zN6v5E45incsZ
 Ofq0cAKRLSIU=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spufs_ps_fault() is called by the VM with mmap_lock held for read and
takes ctx->state_mutex via spu_acquire(). When ctx->state is
SPU_STATE_SAVED it drops mmap_lock, waits in spufs_wait() for the
context to become runnable, and then re-takes mmap_lock. spufs_wait()
returns with state_mutex re-acquired, and spu_release() only runs after
the branch, so mmap_read_lock() is called while state_mutex is held.
Every other spufs fault path takes the locks in the opposite order:
spufs_mem_mmap_fault() and spufs_ps_fault() are entered with mmap_lock
already held and only then take state_mutex.

Three threads sharing an mm can close the cycle: one holds state_mutex
and blocks in mmap_read_lock(), another holds mmap_lock for read and
blocks in spu_acquire(), and a queued writer in mmap_write_lock()
prevents the first down_read() from succeeding. This can result in a
deadlock, and since spusched_tick() takes the same state_mutex, one
wedged context also stalls SPU scheduling for every other context on
the node.

Fix by calling spu_release() before re-taking mmap_lock and jumping to
the existing refault path, which drops the reference taken earlier in
the function and returns VM_FAULT_NOPAGE as before.

Fixes: 33bfd7a73861 ("[POWERPC] spufs: block fault handlers in spu_acquire_runnable")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
Found by inspection; I have no Cell/PS3 hardware, so this is
compile-tested only.
---
 arch/powerpc/platforms/cell/spufs/file.c | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/arch/powerpc/platforms/cell/spufs/file.c b/arch/powerpc/platforms/cell/spufs/file.c
index 07b1755ddc3d..d479c956506d 100644
--- a/arch/powerpc/platforms/cell/spufs/file.c
+++ b/arch/powerpc/platforms/cell/spufs/file.c
@@ -349,7 +349,10 @@ static vm_fault_t spufs_ps_fault(struct vm_fault *vmf,
 		spu_context_nospu_trace(spufs_ps_fault__sleep, ctx);
 		err = spufs_wait(ctx->run_wq, ctx->state == SPU_STATE_RUNNABLE);
 		spu_context_trace(spufs_ps_fault__wake, ctx, ctx->spu);
+		if (!err)
+			spu_release(ctx);
 		mmap_read_lock(current->mm);
+		goto refault;
 	} else {
 		area = ctx->spu->problem_phys + ps_offs;
 		ret = vmf_insert_pfn(vmf->vma, vmf->address,

-- 
2.51.2

