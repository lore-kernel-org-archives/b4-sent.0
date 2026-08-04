From: Junrui Luo <moonafterrain@outlook.com>
Date: Tue, 04 Aug 2026 16:50:40 +0800
Subject: [PATCH v2 3/5] powerpc/spufs: check permissions in spufs_setattr()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260804-fixes-v2-3-5bfd827297f9@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1714;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=dffeiU9SuIG2crRu8M1hNRxZHn/iEzt/PMyihiDEjKQ=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrMLlbxTVjPNSXmaeOhL321xIPc/iZOt5vyTxgAsyW
 xgYFVrab3eUsjCIcTHIiimyHC+49M3Cd4vuFp8tyTBzWJlAhjBwcQrARJScGBkeBFrNO/D0QJBQ
 //p0rZh1Xe/62jdz7osUfpo4W4BxVdcmRob9zxY7Pl1XmXm4LKPmtcy9NE23/HCHklOHvq/d6bh
 B8z4fAOdOSp8=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spufs_setattr() applies the caller's attributes with setattr_copy() but
never calls setattr_prepare(). notify_change() leaves that to the
filesystem: it runs only may_setattr(), while inode_owner_or_capable()
and the CAP_CHOWN test live inside setattr_prepare(). setattr_copy()
performs no checking of its own.

The handler is installed for every regular spufs file, so mode and
ownership of another user's context files can be changed without the
usual authorization.

Call setattr_prepare() before setattr_copy(). The existing ATTR_SIZE
test stays ahead of it so that resizing a spufs file keeps returning
-EINVAL. &nop_mnt_idmap matches the adjacent setattr_copy() call.

Fixes: 67207b9664a8 ("[PATCH] spufs: The SPU file system, base")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/inode.c | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/arch/powerpc/platforms/cell/spufs/inode.c b/arch/powerpc/platforms/cell/spufs/inode.c
index 2b54afb31529..c2b15c30f7c0 100644
--- a/arch/powerpc/platforms/cell/spufs/inode.c
+++ b/arch/powerpc/platforms/cell/spufs/inode.c
@@ -96,10 +96,14 @@ spufs_setattr(struct mnt_idmap *idmap, struct dentry *dentry,
 	      struct iattr *attr)
 {
 	struct inode *inode = d_inode(dentry);
+	int ret;
 
 	if ((attr->ia_valid & ATTR_SIZE) &&
 	    (attr->ia_size != inode->i_size))
 		return -EINVAL;
+	ret = setattr_prepare(&nop_mnt_idmap, dentry, attr);
+	if (ret)
+		return ret;
 	setattr_copy(&nop_mnt_idmap, inode, attr);
 	mark_inode_dirty(inode);
 	return 0;

-- 
2.51.2

