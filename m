From: Nayeon Kim <nayeoni.kim@samsung.com>
Date: Mon, 02 Nov 2026 11:43:40 +0900
Subject: [PATCH nfstest] NFSUtil: find OPEN when a later operation fails
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261102-b4-fs19-open-partial-success-v1-1-5e0f55385d27@samsung.com>
X-B4-Tracking: v=1; b=H4sIANv452oC/yWM3Q6CMAxGX8X02kZGFhJ8FeNFV4rMyFjaYUwI7
 +7Qy/P9nA1MNIrB9bSByjtaXFIFdz4BT5QegnGoDG3Tds41LQaPo7kelywJM2mJ9EJbmcUM2Te
 Dd71n6RxURVYZ4+env0EarYgVuP8LW8NTuBzyYxrIBINS4umI1mxFhebLTPWlsO9fkuoV5asAA
 AA=
X-Change-ID: 20261102-b4-fs19-open-partial-success-c40d4194ce61
To: Jorge.Mora@netapp.com
Cc: linux-nfs@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1793587419; l=2619;
 i=nayeoni.kim@samsung.com; s=20261102; h=from:subject:message-id;
 bh=kM+8j/vfKTA/FNbh1boUK6kqOiP9hAPClcoKGunMq5Q=;
 b=i4/GZfSnlp4aIqrZl96mMEntMk+JYSePdSBReFgdPJZJY9dvKiNGKS7kZtQ8KiwEzJkWVU/sV
 wvL6DP/w92UCkbOHfME0DGxXthUk+6YXeFxET6k2AC6vvGxEQg6jJvW
X-Developer-Key: i=nayeoni.kim@samsung.com; a=ed25519;
 pk=6rdU/EioX/vzm132vDyAq+TUk6SqpWqob+mz30+/n5E=
X-Endpoint-Received: by B4 Relay for nayeoni.kim@samsung.com/20261102 with auth_id=1381
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

When the client sends LAYOUTGET in the OPEN compound and only the
LAYOUTGET fails, e.g., with NFS4ERR_BAD_STATEID, the OPEN and GETFH
still succeed but the compound status is the LAYOUTGET error.
find_open() looks for the OPEN reply with "NFS.status == 0", which is
the compound status, so it misses this OPEN and either returns
(None, None, None) or picks a later OPEN of the same file.

Fix this by matching on the status of the OPEN operation instead.

After this change, the matched OPEN reply may contain a failed
LAYOUTGET, and find_layoutget() then looks at the same OPEN compound
repeatedly until it hits the recursion limit. In that case, ignore the
failed LAYOUTGET and look for the retried one.

Signed-off-by: Nayeon Kim <nayeoni.kim@samsung.com>
---
This conflicts with the pending "nfstest: DELEG: accept the attribute
delegation" patch, which changes the line right after the open_str
line in find_open(). I can rebase on top of it if that goes in first.

Tested by replaying packet traces with the failed LAYOUTGET through
find_open() and find_layoutget().
---
 nfstest/nfs_util.py | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)

diff --git a/nfstest/nfs_util.py b/nfstest/nfs_util.py
index cf8d6aecc6ae..e6a2dd21ae1a 100644
--- a/nfstest/nfs_util.py
+++ b/nfstest/nfs_util.py
@@ -566,7 +566,7 @@ class NFSUtil(Host):
                 return (None, None, None)
             save_pktcall = pktcall
             xid = pktcall.rpc.xid
-            open_str = "RPC.xid == %d and NFS.status == 0 and NFS.resop == %d" % (xid, OP_OPEN)
+            open_str = "RPC.xid == %d and NFS.opopen.status == 0 and NFS.resop == %d" % (xid, OP_OPEN)
             if deleg_type is not None:
                 open_str += " and NFS.delegation.deleg_type == %d" % deleg_type
 
@@ -625,6 +625,12 @@ class NFSUtil(Host):
                 self.layoutget_on_open = True
                 if self.openreply:
                     layoutget_res = self.getop(self.openreply, OP_LAYOUTGET)
+                    if layoutget_res is not None and status != layoutget_res.status:
+                        # The LAYOUTGET in the OPEN compound did not return
+                        # the expected status, look for another LAYOUTGET
+                        layoutget = None
+                        layoutget_res = None
+                        self.layoutget_on_open = False
 
         if layoutget is None:
             # Find LAYOUTGET request

---
base-commit: 94089545caa18bbe4be1b055125d0721fe8dee80
change-id: 20261102-b4-fs19-open-partial-success-c40d4194ce61

