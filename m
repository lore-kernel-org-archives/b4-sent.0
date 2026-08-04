From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 16:50:39 +0800
Subject: [PATCH v2 2/5] powerpc/spufs: don't leak kernel stack via spu_run
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-fixes-v2-2-5bfd827297f9@outlook.com>
References: <20260804-fixes-v2-0-5bfd827297f9@outlook.com>
In-Reply-To: <20260804-fixes-v2-0-5bfd827297f9@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Paul Mackerras <paulus@ozlabs.org>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, stable@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1592;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=/mYJIr4Rrbt5tK8GuImhcqAYaBw3DdGgKByxedyucEU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMLlb76tSgqwj18YnOrQtpRllZ+6sNpx9hVr2ztMT
 858m3mM+UhHKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATERHieF/mvPSy7E9malK
 PlmZPR+Wzz/ROOVmBp/wilU6jdlqLCuUGBnmLxSLLDwzZcfSuzcrt6xU2XNXM03EWid2SpTa7Hm
 F8pN5AWe+SRo=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_spu_run() hands the address of an uninitialized local to
spufs_run_spu() and then copies it out unconditionally:

	u32 npc, status;
	...
	ret = spufs_run_spu(i->i_ctx, &npc, &status);
	...
	if (ustatus && put_user(status, ustatus))
		ret = -EFAULT;

spufs_run_spu() writes through that pointer at exactly one place, the
"out:" label, and two of its exits never reach it: the interruptible
acquisition of ctx->run_mutex returns -ERESTARTSYS directly, and a
failed spu_acquire() jumps to "out_unlock", which sits just after the
assignment.

Initialize status to 0, which is what userspace would have observed had
the assignment been reached anyway: spufs_run_spu() resets
ctx->event_return to 0 on entry, and 0 is the "no events pending" value
for this word.

Fixes: 67207b9664a8 ("[PATCH] spufs: The SPU file system, base")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/syscalls.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/powerpc/platforms/cell/spufs/syscalls.c b/arch/powerpc/platforms/cell/spufs/syscalls.c
index ea4ba1b6ce6a..549fcfbbc140 100644
--- a/arch/powerpc/platforms/cell/spufs/syscalls.c
+++ b/arch/powerpc/platforms/cell/spufs/syscalls.c
@@ -37,7 +37,7 @@ static long do_spu_run(struct file *filp,
 {
 	long ret;
 	struct spufs_inode_info *i;
-	u32 npc, status;
+	u32 npc, status = 0;
 
 	ret = -EFAULT;
 	if (get_user(npc, unpc))

-- 
2.51.2

