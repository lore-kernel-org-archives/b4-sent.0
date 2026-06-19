From: Chuwei Yu <max_yu2022@163.com>
Date: Fri, 19 Jun 2026 18:24:23 +0800
Subject: [PATCH] jffs2:fix a oops arises from a conflict between inocache
 evict and gc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260619-jffs2-kernel-oops-fix-v1-1-660268541b1b@163.com>
X-B4-Tracking: v=1; b=H4sIANYYNWoC/yXMUQ6CMBCE4auQfXaTtiGAXsX4IGUKi6YlXTQmh
 LtT9fGbZP6NFFmgdKk2yniLSooF9lSRn+5xBMtQTM64xjT2zHMI6viBHPHklBblIB82tW3ROd/
 bGlS+S0aZf93r7W999TP8+o3Rvh/toF+MeQAAAA==
X-Change-ID: 20260619-jffs2-kernel-oops-fix-0417e82cb14e
To: David Woodhouse <dwmw2@infradead.org>, 
 Richard Weinberger <richard@nod.at>
Cc: linux-mtd@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Chuwei Yu <yuchuwei@tp-link.com.hk>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1781864689; l=3390;
 i=max_yu2022@163.com; s=20260617; h=from:subject:message-id;
 bh=ZFODi3N8e2XsMXVkMEc3e9vOzCxZarLxWNIbK21n2p8=;
 b=lqHbxrg3yKDWuRVblgZkKJ+Fdx0hXnqicmPDwWk2Wt/qxHnF8bDn/Com76v3/JLao98HcdGWk
 uTQrNIiLoxfB8roOAA0BvYHfmlBxwU5DpVfC0il70OdyOnHJq/TmccQ
X-Developer-Key: i=max_yu2022@163.com; a=ed25519;
 pk=o5nctjiEWWNk2YWC+lqznx73YyfF0W9rjQS+9VwtGqg=
X-Endpoint-Received: by B4 Relay for max_yu2022@163.com/20260617 with auth_id=832
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Chuwei Yu <yuchuwei@tp-link.com.hk>

[CAUSES]
1 In the garbage collect thread function jffs2_garbage_collect_pass,
it checks the state of all inocaches each loop. If the state is
INO_STATE_GC/INO_STATE_CHECKING/INO_STATE_CLEARING, it will call BUG()
which will cause a kernel oops.

2 If a application executes "echo N > /proc/sys/vm/drop_caches"(N=2/3),
or,  the size of free memory is very low so the kernel wants to clear
the cached memory, both cases will result in Function jffs2_evict_inode
 being called.
Function jffs2_evict_inode calls Function jffs2_do_clear_inode which
sets the state of one inocache to INO_STATE_CLEARING first and does
something and then sets the state of the inocache to
INO_STATE_CHECKEDABSENT.

3 If jffs2_do_clear_inode yields the CPU(Function jffs2_kill_fragtree
 calls cond_resched) after setting the state of one inocache to
INO_STATE_CLEARING, and gc thread happens to get scheduled for execution
at that moment, it will discover the state of one inocache is invalid
and call BUG() to cause a kernel oops.

4 The root cause is that the locks within Function jffs2_evict_inode and
Function jffs2_garbage_collect_pass are not mutually exclusive.

[SOLUTION]
1 Function jffs2_garbage_collect_pass locks c->alloc_sem first by
executing "mutex_lock_interruptible(&c->alloc_sem)" and then lock
c->inocache_lock by executing "spin_lock(&c->inocache_lock)".

2 Function jffs2_do_clear_inode which is called by Function
jffs2_evict_inode executes "mutex_lock(&f->sem)" to lock f->sem first,
then calls Function jffs2_set_inocache_state. In Function
jffs2_set_inocache_state, it locks c->inocache_lock by executing
"spin_lock(&c->inocache_lock)", sets the state of one inocache to
INO_STATE_CLEARING and release the lock c->inocache_lock.
At this moment, because the lock f->sem can not prevent Function
jffs2_garbage_collect_pass from checking the state of all inocaches,
if Function jffs2_garbage_collect_pass gets the CPU to run, the
problem happens.

3 So, we need lock c->alloc_sem before the code line
"jffs2_do_clear_inode(c, f);" in Function jffs2_evict_inode and
unlock c->alloc_sem after the code line "jffs2_do_clear_inode(c, f);"
to make sure that only after jffs2_do_clear_inode is completed can the
jffs2_garbage_collect_pass function checks the state of all inocaches.

[EFFECTIVE]
jffs2 filesystem

[TEST]
1 Compiling with default config works normally.
2 Compiling with allyesconfig works normally.
3 Compiling with allnoconfig works normally.
4 Compiling with O=builddir works normally.
5 Repeat to run drop_caches for 5000 times and jffs2 works normally.

Signed-off-by: Chuwei Yu <yuchuwei@tp-link.com.hk>
---
 fs/jffs2/fs.c | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/fs/jffs2/fs.c b/fs/jffs2/fs.c
index 6ada8369a762..9cf1c480a159 100644
--- a/fs/jffs2/fs.c
+++ b/fs/jffs2/fs.c
@@ -247,7 +247,9 @@ void jffs2_evict_inode (struct inode *inode)
 		  __func__, inode->i_ino, inode->i_mode);
 	truncate_inode_pages_final(&inode->i_data);
 	clear_inode(inode);
+	mutex_lock(&c->alloc_sem);
 	jffs2_do_clear_inode(c, f);
+	mutex_unlock(&c->alloc_sem);
 }
 
 struct inode *jffs2_iget(struct super_block *sb, unsigned long ino)

---
base-commit: 9ecfb2f7287a967b418ba69f10d45ead0d360593
change-id: 20260619-jffs2-kernel-oops-fix-0417e82cb14e

Best regards,
--  
Chuwei Yu <max_yu2022@163.com>

