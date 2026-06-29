From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 29 Jun 2026 00:01:43 -0500
Subject: [PATCH 1/2] ocfs2: bound namelen in dlm_migrate_request_handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-b4-disp-94fb6521-v1-1-6953bcc0421f@proton.me>
References: <20260629-b4-disp-94fb6521-v1-0-6953bcc0421f@proton.me>
In-Reply-To: <20260629-b4-disp-94fb6521-v1-0-6953bcc0421f@proton.me>
To: Joseph Qi <joseph.qi@linux.alibaba.com>, Mark Fasheh <mark@fasheh.com>, 
 Joel Becker <jlbec@evilplan.org>
Cc: linux-kernel@vger.kernel.org, ocfs2-devel@lists.linux.dev, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Kurt Hackel <kurt.hackel@oracle.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782709302; l=1498;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=RtRvTUqLTTNjHItBU2QlVnq+fOoWouPL9E4x4+QRNFc=;
 b=Z4xZ7puaiaDyfsGWJw9bz9DOZTmFFRTsMZEfQi4T4Nnn/MVE/gjpT6YLZQmFBJYrk0+I4GR0p
 cEx5Xhk3FbICudEU7s8iHdC+3JoLm3Upw3K+tRD553SLsfhFdmm6PXX
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A node receiving a DLM_MIGRATE_REQUEST message trusts the peer-supplied
name length (migrate->namelen) without bounding it.  dlm_init_mle() then
copies that many bytes into the fixed DLM_LOCKID_NAME_MAX-byte mname[]
array of an o2dlm_mle slab object, so a malformed message from a cluster
peer overflows the slab object by up to ~215 bytes: a heap out-of-bounds
write of attacker-controlled data, reachable by any node in the domain.

Reject an oversized name, the way dlm_master_request_handler() and the
other o2dlm receive handlers already do; the migration handler omits the
check entirely.  Conforming messages are unaffected.

Fixes: 6714d8e86bf4 ("[PATCH] OCFS2: The Second Oracle Cluster Filesystem")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/ocfs2/dlm/dlmmaster.c | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/fs/ocfs2/dlm/dlmmaster.c b/fs/ocfs2/dlm/dlmmaster.c
index 93eff38fdadd..bd7623cc6e77 100644
--- a/fs/ocfs2/dlm/dlmmaster.c
+++ b/fs/ocfs2/dlm/dlmmaster.c
@@ -3100,6 +3100,12 @@ int dlm_migrate_request_handler(struct o2net_msg *msg, u32 len, void *data,
 
 	name = migrate->name;
 	namelen = migrate->namelen;
+	if (namelen > DLM_LOCKID_NAME_MAX) {
+		mlog(ML_ERROR, "%s: invalid name length %u in migrate request\n",
+		     dlm->name, namelen);
+		ret = -EINVAL;
+		goto leave;
+	}
 	hash = dlm_lockid_hash(name, namelen);
 
 	/* preallocate.. if this fails, abort */

-- 
2.43.0

