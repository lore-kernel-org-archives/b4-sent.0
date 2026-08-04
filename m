From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 16:50:42 +0800
Subject: [PATCH v2 5/5] powerpc/spufs: don't hold state_mutex during user
 access
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-fixes-v2-5-5bfd827297f9@outlook.com>
References: <20260804-fixes-v2-0-5bfd827297f9@outlook.com>
In-Reply-To: <20260804-fixes-v2-0-5bfd827297f9@outlook.com>
To: Madhavan Srinivasan <maddy@linux.ibm.com>, 
 Michael Ellerman <mpe@ellerman.id.au>, Nicholas Piggin <npiggin@gmail.com>, 
 "Christophe Leroy (CS GROUP)" <chleroy@kernel.org>, 
 Arnd Bergmann <arnd@arndb.de>, Paul Mackerras <paulus@ozlabs.org>, 
 Al Viro <viro@zeniv.linux.org.uk>
Cc: linuxppc-dev@lists.ozlabs.org, linux-kernel@vger.kernel.org, 
 Yuhao Jiang <danisjiang@gmail.com>, Junrui Luo <moonafterrain@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4105;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=KVNqgEF0+C48K+PWMOxfS0uXgoSuZZMWuvz93e4utzw=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMLlb6bXFGww1mD9ovLjdb0VZ+ON3WvjZ53b3SEpX
 W/vPO166beOUhYGMS4GWTFFluMFl75Z+G7R3eKzJRlmDisTyBAGLk4BmMipRkaGk8dilnY+3yn6
 k3OurXqRd4RVwOqfksvaF2j82SdzU6CqlpFh7beF5s5RSafO/lj8pNOgNu+csZmB0eJv37WtD95
 PO2PGBgB+bE2s
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spufs_mbox_read(), spufs_ibox_read() and spufs_wbox_write() take the
context state_mutex with spu_acquire() and only drop it once their
transfer loop has finished, so every put_user()/get_user() in those
loops runs with the mutex held. The faulting address comes from
userspace, so the fault can be made to take arbitrarily long via
userfaultfd region or a FUSE-backed mapping.

Drop the mutex around the user accesses: acquire it per mailbox element,
just long enough for the ctx->ops mailbox operation, and release it
before touching the user buffer.

spufs_switch_log_read() has the same problem but its loop needs the lock
for more than just the copy.

Fixes: cdcc89bb1c6e ("[POWERPC] spufs: make mailbox functions handle multiple elements")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/file.c | 52 ++++++++++++++++++--------------
 1 file changed, 29 insertions(+), 23 deletions(-)

diff --git a/arch/powerpc/platforms/cell/spufs/file.c b/arch/powerpc/platforms/cell/spufs/file.c
index de7494748fec..c8c3b6e8affb 100644
--- a/arch/powerpc/platforms/cell/spufs/file.c
+++ b/arch/powerpc/platforms/cell/spufs/file.c
@@ -602,13 +602,17 @@ static ssize_t spufs_mbox_read(struct file *file, char __user *buf,
 	if (len < 4)
 		return -EINVAL;
 
-	count = spu_acquire(ctx);
-	if (count)
-		return count;
-
 	for (count = 0; (count + 4) <= len; count += 4, udata++) {
 		int ret;
+
+		ret = spu_acquire(ctx);
+		if (ret) {
+			if (!count)
+				count = ret;
+			break;
+		}
 		ret = ctx->ops->mbox_read(ctx, &mbox_data);
+		spu_release(ctx);
 		if (ret == 0)
 			break;
 
@@ -624,7 +628,6 @@ static ssize_t spufs_mbox_read(struct file *file, char __user *buf,
 			break;
 		}
 	}
-	spu_release(ctx);
 
 	if (!count)
 		count = -EAGAIN;
@@ -705,29 +708,34 @@ static ssize_t spufs_ibox_read(struct file *file, char __user *buf,
 
 	count = spu_acquire(ctx);
 	if (count)
-		goto out;
+		return count;
 
 	/* wait only for the first element */
-	count = 0;
 	if (file->f_flags & O_NONBLOCK) {
 		if (!spu_ibox_read(ctx, &ibox_data)) {
-			count = -EAGAIN;
-			goto out_unlock;
+			spu_release(ctx);
+			return -EAGAIN;
 		}
 	} else {
 		count = spufs_wait(ctx->ibox_wq, spu_ibox_read(ctx, &ibox_data));
 		if (count)
-			goto out;
+			return count;
 	}
+	spu_release(ctx);
 
 	/* if we can't write at all, return -EFAULT */
 	count = put_user(ibox_data, udata);
 	if (count)
-		goto out_unlock;
+		return count;
 
 	for (count = 4, udata++; (count + 4) <= len; count += 4, udata++) {
 		int ret;
+
+		ret = spu_acquire(ctx);
+		if (ret)
+			break;
 		ret = ctx->ops->ibox_read(ctx, &ibox_data);
+		spu_release(ctx);
 		if (ret == 0)
 			break;
 		/*
@@ -740,9 +748,6 @@ static ssize_t spufs_ibox_read(struct file *file, char __user *buf,
 			break;
 	}
 
-out_unlock:
-	spu_release(ctx);
-out:
 	return count;
 }
 
@@ -839,40 +844,41 @@ static ssize_t spufs_wbox_write(struct file *file, const char __user *buf,
 
 	count = spu_acquire(ctx);
 	if (count)
-		goto out;
+		return count;
 
 	/*
 	 * make sure we can at least write one element, by waiting
 	 * in case of !O_NONBLOCK
 	 */
-	count = 0;
 	if (file->f_flags & O_NONBLOCK) {
 		if (!spu_wbox_write(ctx, wbox_data)) {
-			count = -EAGAIN;
-			goto out_unlock;
+			spu_release(ctx);
+			return -EAGAIN;
 		}
 	} else {
 		count = spufs_wait(ctx->wbox_wq, spu_wbox_write(ctx, wbox_data));
 		if (count)
-			goto out;
+			return count;
 	}
-
+	spu_release(ctx);
 
 	/* write as much as possible */
 	for (count = 4, udata++; (count + 4) <= len; count += 4, udata++) {
 		int ret;
+
 		ret = get_user(wbox_data, udata);
 		if (ret)
 			break;
 
+		ret = spu_acquire(ctx);
+		if (ret)
+			break;
 		ret = spu_wbox_write(ctx, wbox_data);
+		spu_release(ctx);
 		if (ret == 0)
 			break;
 	}
 
-out_unlock:
-	spu_release(ctx);
-out:
 	return count;
 }
 

-- 
2.51.2

