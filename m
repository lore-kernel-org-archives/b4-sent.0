From: Bryam Vargas <hexlabsecurity@proton.me>
Date: Mon, 29 Jun 2026 00:01:44 -0500
Subject: [PATCH 2/2] ocfs2: validate lengths in dlm_mig_lockres_handler
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260629-b4-disp-94fb6521-v1-2-6953bcc0421f@proton.me>
References: <20260629-b4-disp-94fb6521-v1-0-6953bcc0421f@proton.me>
In-Reply-To: <20260629-b4-disp-94fb6521-v1-0-6953bcc0421f@proton.me>
To: Joseph Qi <joseph.qi@linux.alibaba.com>, Mark Fasheh <mark@fasheh.com>, 
 Joel Becker <jlbec@evilplan.org>
Cc: linux-kernel@vger.kernel.org, ocfs2-devel@lists.linux.dev, 
 Andrew Morton <akpm@linux-foundation.org>, 
 Kurt Hackel <kurt.hackel@oracle.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782709302; l=2129;
 i=hexlabsecurity@proton.me; s=proton; h=from:subject:message-id;
 bh=n8/U132yn/sKTeFUcvnEZBy26KB8iGkXZR1WnhsgTJk=;
 b=YG+hbSlxbkwERxe49x6W6IxslN971ryVZwQap7HoLlMdGOSvrvWn/L0YM20mAqtzMEZygzPZs
 k0NNPgB865rDXAfllPpZcXBvyw6a3lP6mW9N5a1tlD5ReFqV2zP0j50
X-Developer-Key: i=hexlabsecurity@proton.me; a=ed25519;
 pk=dmppBMZNLLoPzxHi9l8tZDzEZUunPbgsYqIZYXeUrL0=
X-Endpoint-Received: by B4 Relay for hexlabsecurity@proton.me/proton with auth_id=814
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

A node receiving a DLM_MIG_LOCKRES message trusts several fields of the
peer-supplied dlm_migratable_lockres without validation.  num_locks and
lockname_len are bounded only on the sending side, and the message is
never checked to actually carry num_locks migratable_lock entries.  As a
result dlm_process_recovery_data() walks mres->ml[0..num_locks) past the
kmalloc(data_len) copy of the message (an out-of-bounds read that ends in
a BUG_ON panic), and dlm_init_lockres() copies lockname_len bytes into the
fixed 32-byte o2dlm_lockname slab object (a heap out-of-bounds write).
Both are reachable by any node in the domain.

Validate these fields right after dlm_grab(), before anything uses them --
including the not-joined error path, which already prints mres->lockname
with the unbounded lockname_len as a %.*s precision.  Reject the message
unless lockname_len <= DLM_LOCKID_NAME_MAX, num_locks <=
DLM_MAX_MIGRATABLE_LOCKS (the bound the sender already asserts), and the
payload is large enough to hold the claimed locks.  Conforming recovery
and migration messages are unaffected.

Fixes: 6714d8e86bf4 ("[PATCH] OCFS2: The Second Oracle Cluster Filesystem")
Cc: stable@vger.kernel.org
Signed-off-by: Bryam Vargas <hexlabsecurity@proton.me>
---
 fs/ocfs2/dlm/dlmrecovery.c | 9 +++++++++
 1 file changed, 9 insertions(+)

diff --git a/fs/ocfs2/dlm/dlmrecovery.c b/fs/ocfs2/dlm/dlmrecovery.c
index 128872bd945d..14d4c7c3eebd 100644
--- a/fs/ocfs2/dlm/dlmrecovery.c
+++ b/fs/ocfs2/dlm/dlmrecovery.c
@@ -1357,6 +1357,15 @@ int dlm_mig_lockres_handler(struct o2net_msg *msg, u32 len, void *data,
 	if (!dlm_grab(dlm))
 		return -EINVAL;
 
+	if (mres->lockname_len > DLM_LOCKID_NAME_MAX ||
+	    mres->num_locks > DLM_MAX_MIGRATABLE_LOCKS ||
+	    be16_to_cpu(msg->data_len) < struct_size(mres, ml, mres->num_locks)) {
+		mlog(ML_ERROR, "%s: invalid lockres migration message from %u\n",
+		     dlm->name, mres->master);
+		dlm_put(dlm);
+		return -EINVAL;
+	}
+
 	if (!dlm_joined(dlm)) {
 		mlog(ML_ERROR, "Domain %s not joined! "
 			  "lockres %.*s, master %u\n",

-- 
2.43.0

