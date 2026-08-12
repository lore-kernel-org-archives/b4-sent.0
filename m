From: Junrui Luo <moonafterrain@outlook.com>
Date: Wed, 12 Aug 2026 13:48:07 +0800
Subject: [PATCH 1/5] powerpc/spufs: fix memory leak of spufs_fs_context in
 spufs_free_fc()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260812-spufs-fixes-v1-1-449e201d9f64@outlook.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1455;
 i=moonafterrain@outlook.com; h=from:subject:message-id;
 bh=7tJ0E00IsnJBei3nS8CdVd0Qh/gBecZOpc59xKiGh0k=;
 b=owJ4nJvAy8zAJVb4wiKgu++DA+NptSSGrBpOWbe6PYdDbk6eKcG3yuT2bsbKWTKZM88uLaw66
 pOXwejldb6jlIVBjItBVkyR5XjBpW8Wvlt0t/hsSYaZw8oEMoSBi1MAJuKrwvDPKIS9wVS0bsm+
 ufOuxTn1rIqYMKnaalX4pb0aDw6LPTHiYPin0BNay8Rec2FX46YA1YZni+1YFi74u+HmNc+Y6Ig
 ey9e8AF6eSFU=
X-Developer-Key: i=moonafterrain@outlook.com; a=openpgp;
 fpr=C770D2F6384DB42DB44CB46371E838508B8EF040
X-Endpoint-Received: by B4 Relay for moonafterrain@outlook.com/default with auth_id=909
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

spufs_init_fs_context() allocates both a struct spufs_fs_context stored
in fc->fs_private and a struct spufs_sb_info stored in fc->s_fs_info.
The ->free callback spufs_free_fc() only releases fc->s_fs_info.
put_fs_context() never touches fc->fs_private, since releasing it is
what ->free() exists for, and vfs_clean_context() calls ->free() and
then clears both pointers itself.

Every spufs fs_context that is constructed and torn down therefore leaks
the struct spufs_fs_context allocation. The leak is reachable without
privileges: fsopen() runs ->init_fs_context() before sget_fc() enforces
spufs's lack of FS_USERNS_MOUNT.

Free fc->fs_private alongside fc->s_fs_info.

Fixes: d2e0981c3b9a ("vfs: Convert spufs to use the new mount API")
Reported-by: Yuhao Jiang <danisjiang@gmail.com>
Assisted-by: Claude:claude-opus-5
Cc: stable@vger.kernel.org
Signed-off-by: Junrui Luo <moonafterrain@outlook.com>
---
 arch/powerpc/platforms/cell/spufs/inode.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/powerpc/platforms/cell/spufs/inode.c b/arch/powerpc/platforms/cell/spufs/inode.c
index 2b54afb31529..51c432864f02 100644
--- a/arch/powerpc/platforms/cell/spufs/inode.c
+++ b/arch/powerpc/platforms/cell/spufs/inode.c
@@ -713,6 +713,7 @@ static int spufs_get_tree(struct fs_context *fc)
 
 static void spufs_free_fc(struct fs_context *fc)
 {
+	kfree(fc->fs_private);
 	kfree(fc->s_fs_info);
 }
 

-- 
2.51.2

