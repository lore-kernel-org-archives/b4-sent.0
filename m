From: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
Date: Thu, 15 Oct 2026 03:53:41 +0000
Subject: [PATCH 1/7] libproc: keep the file offset of each mapping
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261015-bug001-uprobe-file-offset-v1-1-bf4c53af8f39@d-matrix.ai>
References: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
In-Reply-To: <20261015-bug001-uprobe-file-offset-v1-0-bf4c53af8f39@d-matrix.ai>
To: dtrace@lists.linux.dev
Cc: dtrace-devel@oss.oracle.com, Kris Van Hees <kris.van.hees@oracle.com>, 
 Alan Maguire <alan.maguire@oracle.com>, 
 Eslam Almorshdy <ealmorshdy@d-matrix.ai>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1792036450; l=1468;
 i=ealmorshdy@d-matrix.ai; s=20261015; h=from:subject:message-id;
 bh=h+L/p2iB1MUcfPH4EbEw1TGI8PX4JVbH/4ZEVmIsTts=;
 b=v0e8GHqyiUCBorL32AJE9zyCm+f7MQdJASjf6xHsAJWItnpyjMamhqyy9P+US5+GikoxLHkGp
 B409ckmpFABCYYHU7zPxfiHPPoxzDNKYiocuu9szqwztTbT0uci80sz
X-Developer-Key: i=ealmorshdy@d-matrix.ai; a=ed25519;
 pk=E4tVAIvp2rvz2CB7Re6YVMP6FiUVSxuq0TUtjGQL5NM=
X-Endpoint-Received: by B4 Relay for ealmorshdy@d-matrix.ai/20261015 with auth_id=1187
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Pupdate_maps() parses the offset field of /proc/<pid>/maps but discards
it.  Store it in a new member, prmap_t.pr_offset: uprobes are placed by
(inode, file offset), so converting a runtime address to a uprobe offset
needs the file offset of the mapping that contains the address.

No functional change.

Assisted-by: Claude Code:claude-opus-5-5
Signed-off-by: Eslam Almorshdy <ealmorshdy@d-matrix.ai>
---
 include/sys/sol_procfs.h | 1 +
 libproc/Psymtab.c        | 1 +
 2 files changed, 2 insertions(+)

diff --git a/include/sys/sol_procfs.h b/include/sys/sol_procfs.h
index 49eb29fb..52360f2d 100644
--- a/include/sys/sol_procfs.h
+++ b/include/sys/sol_procfs.h
@@ -42,6 +42,7 @@ typedef struct prmap {
 	uintptr_t pr_vaddr;	/* virtual address of mapping */
 	char	*pr_mapaddrname; /* address text from /proc/<pid>/maps */
 	size_t	pr_size;	/* size of mapping in bytes */
+	uint64_t pr_offset;	/* offset of the mapping in the backing file */
 	int	pr_mflags;	/* protection and attribute flags (see below) */
 	dev_t	pr_dev;		/* device number */
 	ino_t	pr_inum;	/* inode number */
diff --git a/libproc/Psymtab.c b/libproc/Psymtab.c
index e648c5aa..7876e9a8 100644
--- a/libproc/Psymtab.c
+++ b/libproc/Psymtab.c
@@ -639,6 +639,7 @@ Pupdate_maps(struct ps_prochandle *P)
 
 		pmptr->pr_vaddr = laddr;
 		pmptr->pr_size = haddr - laddr;
+		pmptr->pr_offset = offset;
 		pmptr->pr_mapaddrname = mapaddrname;
 
 		/*

-- 
2.55.0

