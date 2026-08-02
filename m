From: Junrui Luo <moonafterrain@outlook.com>
Date: Sun, 02 Aug 2026 23:51:41 +0800
Subject: [PATCH 3/6] powerpc/spufs: bound NPC against local store size
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-fixes-v1-3-7368423440f4@outlook.com>
References: <20260802-fixes-v1-0-7368423440f4@outlook.com>
In-Reply-To: <20260802-fixes-v1-0-7368423440f4@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Paul Mackerras <paulus@ozlabs.org>, Arnd Bergmann <arnd@arndb.de>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Junrui Luo <moonafterrain@outlook.com>, Yuhao Jiang <danisjiang@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1325;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=zn0rin21Vmi2aZsnEd8aIQAuyKtzsUFBfqpkfQqnfiw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrPz06QKOEseezU055Jt+YN7t0MAV9xRPVU8XrJ79l
 bnPia2Ft66jlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJiJpxMjwJSQhxPQeT+qa
 PmbB6w9T6zI+rX7FWf/mhWuTqt3DpYa/GBlmNs5n5JmYLSKaY2Iy48Gc5OVfS57f8ZVbUK/Pf/7
 utBR2AOnlSKw=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spu_process_callback() masks the low bits of the NPC register and uses
the result as an offset into the SPU local store: `ls_pointer = in_be32(ls
+ npc)`. The following guard validates ls_pointer against LS_SIZE, but npc
itself is never bounds-checked.

Fix by rejecting npc greater than LS_SIZE - sizeof(ls_pointer) before the
read, mirroring the adjacent ls_pointer guard and returning the same
-EFAULT.

Fixes: 2dd14934c913 ("[PATCH] spufs: allow SPU code to do syscalls")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/run.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/powerpc/platforms/cell/spufs/run.c b/arch/powerpc/platforms/cell/spufs/run.c
index ce52b87496d2..87497316d128 100644
--- a/arch/powerpc/platforms/cell/spufs/run.c
+++ b/arch/powerpc/platforms/cell/spufs/run.c
@@ -317,6 +317,8 @@ static int spu_process_callback(struct spu_context *ctx)
 	/* get syscall block from local store */
 	npc = ctx->ops->npc_read(ctx) & ~3;
 	ls = (void __iomem *)ctx->ops->get_ls(ctx);
+	if (npc > (LS_SIZE - sizeof(ls_pointer)))
+		return -EFAULT;
 	ls_pointer = in_be32(ls + npc);
 	if (ls_pointer > (LS_SIZE - sizeof(s)))
 		return -EFAULT;

-- 
2.51.2

