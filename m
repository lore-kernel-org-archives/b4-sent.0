From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 12 Aug 2026 13:48:08 +0800
Subject: [PATCH 2/5] powerpc/spufs: fix out-of-bounds read in
 spufs_wbox_info_read()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-spufs-fixes-v1-2-449e201d9f64@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=2501;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=eFoKpMk5QT/Imns3PMC9qhF1gah2+vf/FhZEbtTKzCg=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBpOua8Pz4VM9wsrv2ue81ysOzMqv2rrbC7fOq8ys
 XtFdRtPHO8oZWEQ42KQFVNkOV5w6ZuF7xbdLT5bkmHmsDKBDGHg4hSAiQROY2R4udnCxq4kNyFT
 i6U65FbbrhC2ucmL2c1n6Zam3PsgpyfCyDC/xnbN9dZ8jae2fx4um1wp9ffiP7P9mkGuzzj5rjw
 4uZ8JAMIxSLI=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Reading a context's wbox_info file can copy up to 48 bytes past the end
of an on-stack buffer to userspace.

spufs_wbox_info_cnt() already returns a byte count: it multiplies the
number of queued SPU inbound mailbox entries by sizeof(u32), yielding one
of 0, 4, 8, 12 or 16. spufs_wbox_info_dump() uses it that way and passes
the result to spufs_dump_emit() unscaled.

spufs_wbox_info_read() instead multiplies it by sizeof(u32) a second time
and hands the product to simple_read_from_buffer() as the length of the
available data. The buffer being described is u32
data[ARRAY_SIZE(ctx->csa.spu_mailbox_data)], i.e. 16 bytes, but the value
passed reaches 64. simple_read_from_buffer() clamps the transfer against
that length rather than against the buffer, so once the mailbox holds two
or more entries, a read reaching past offset 16 - either by requesting
more than 16 bytes or by seeking there first - copies adjacent kernel
stack to userspace.

The mailbox occupancy is under unprivileged control. Writing to the
context's wbox file drives spu_backing_wbox_write(), which lowers the
free-slot count in mb_stat_R from four down to zero, and wbox_info is
mode 0444 in spufs_dir_contents[], so the owner of the context can then
read it back.

This dates to the introduction of spufs_wbox_info_cnt(). Before that
commit the local count held an entry count, for which the sizeof(u32)
scaling at the call site was correct.

Pass the byte count through unscaled, as spufs_wbox_info_dump() does.

Fixes: 88413a6bfbbe ("powerpc/spufs: fix copy_to_user while atomic")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/file.c | 3 +--
 1 file changed, 1 insertion(+), 2 deletions(-)

diff --git a/arch/powerpc/platforms/cell/spufs/file.c b/arch/powerpc/platforms/cell/spufs/file.c
index de7494748fec..07b1755ddc3d 100644
--- a/arch/powerpc/platforms/cell/spufs/file.c
+++ b/arch/powerpc/platforms/cell/spufs/file.c
@@ -2028,8 +2028,7 @@ static ssize_t spufs_wbox_info_read(struct file *file, char __user *buf,
 	spin_unlock(&ctx->csa.register_lock);
 	spu_release_saved(ctx);
 
-	return simple_read_from_buffer(buf, len, pos, &data,
-				count * sizeof(u32));
+	return simple_read_from_buffer(buf, len, pos, &data, count);
 }
 
 static const struct file_operations spufs_wbox_info_fops = {

-- 
2.51.2

