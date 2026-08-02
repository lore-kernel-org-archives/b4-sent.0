From: Junrui Luo <moonafterrain@outlook.com>
Date: Sun, 02 Aug 2026 23:51:43 +0800
Subject: [PATCH 5/6] powerpc/spufs: fix deadlock on gang creation failure
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260802-fixes-v1-5-7368423440f4@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=3003;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=sNBdhSvUH4Nc3dR73ItBK/i22i57aFEVzgsW9ggCOvU=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrPz0Gclb/hnZ73M34u+Z98Hd5tv8zilH/im72ka++
 tOTstn0f29HKQuDGBeDrJgiy/GCS98sfLfobvHZkgwzh5UJZAgDF6cATOTdaoZ/Zuu1/l+XiNMx
 UrZ9kXfhSUREkWY3o9Zz6b5TZ59vFrbOYGToDXcT3+ZlMS+zZcIE09yLzc1na74u/ahmVyiW43m
 ibQsvAE8LS9o=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

do_spu_create() enters spufs with the parent directory's i_rwsem held
for write, taken as I_MUTEX_PARENT by start_creating_user_path() and
dropped only by end_creating_path(). When spufs_gang_open() fails inside
that window, spufs_create_gang() cleans up by calling unuse_gang().

The gang was just created, so gang->alive drops to 0 and unuse_gang()
proceeds to simple_recursive_removal(), which takes the parent inode's
i_rwsem as I_MUTEX_CHILD. This leads to the task blocking on an rwsem it
already holds, leaving the spufs directory write-locked. The other two
callers of unuse_gang() do not hold the parent lock: spufs_gang_close()
runs from ->release, and spufs_dir_close() drops the parent lock first.

Tell unuse_gang() which context it is called from, and use
locked_recursive_removal() when the parent is already held. This matches
spufs_rmdir(), which spufs_create_context() already uses for the same
cleanup under the same lock.

Fixes: c134deabf478 ("spufs: fix gang directory lifetimes")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/inode.c | 17 +++++++++++------
 1 file changed, 11 insertions(+), 6 deletions(-)

diff --git a/arch/powerpc/platforms/cell/spufs/inode.c b/arch/powerpc/platforms/cell/spufs/inode.c
index c2b15c30f7c0..998512409552 100644
--- a/arch/powerpc/platforms/cell/spufs/inode.c
+++ b/arch/powerpc/platforms/cell/spufs/inode.c
@@ -175,7 +175,8 @@ static int spufs_fill_dir(struct dentry *dir,
 	return 0;
 }
 
-static void unuse_gang(struct dentry *dir)
+/* @parent_locked: caller holds dir->d_parent's i_rwsem as I_MUTEX_PARENT */
+static void unuse_gang(struct dentry *dir, bool parent_locked)
 {
 	struct inode *inode = dir->d_inode;
 	struct spu_gang *gang = SPUFS_I(inode)->i_gang;
@@ -187,8 +188,12 @@ static void unuse_gang(struct dentry *dir)
 		dead = !--gang->alive;
 		inode_unlock(inode);
 
-		if (dead)
-			simple_recursive_removal(dir, NULL);
+		if (dead) {
+			if (parent_locked)
+				locked_recursive_removal(dir, NULL);
+			else
+				simple_recursive_removal(dir, NULL);
+		}
 	}
 }
 
@@ -204,7 +209,7 @@ static int spufs_dir_close(struct inode *inode, struct file *file)
 	spufs_rmdir(parent, dir);
 	inode_unlock(parent);
 
-	unuse_gang(dir->d_parent);
+	unuse_gang(dir->d_parent, false);
 	return dcache_dir_close(inode, file);
 }
 
@@ -483,7 +488,7 @@ spufs_mkgang(struct inode *dir, struct dentry *dentry, umode_t mode)
 
 static int spufs_gang_close(struct inode *inode, struct file *file)
 {
-	unuse_gang(file->f_path.dentry);
+	unuse_gang(file->f_path.dentry, false);
 	return dcache_dir_close(inode, file);
 }
 
@@ -520,7 +525,7 @@ static int spufs_create_gang(struct inode *inode,
 	if (!ret) {
 		ret = spufs_gang_open(&path);
 		if (ret < 0)
-			unuse_gang(dentry);
+			unuse_gang(dentry, true);
 	}
 	return ret;
 }

-- 
2.51.2

