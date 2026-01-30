From: Chen Linxuan <me@black-desk.cn>
Date: Fri, 30 Jan 2026 16:13:54 +0800
Subject: [PATCH] man/man2/mount.2: add ENOSPC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260130-add-enospc-for-mount-v1-1-85b45f0ce3d8@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAEFofGkC/x3MQQqAIBBG4avErBvQgoquEi1Ef2sWaWhFEN09a
 fkt3nsoIwkyjdVDCZdkiaFA1xXZ1YQFLK6YGtV0SreKjXOMEPNu2cfEWzzDwS2MxtAb3wFU0j3
 By/1vp/l9Px602yxmAAAA
X-Change-ID: 20260130-add-enospc-for-mount-3ea1e87af6ee
To: Alejandro Colomar <alx@kernel.org>
Cc: linux-man@vger.kernel.org, Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1292; i=me@black-desk.cn;
 h=from:subject:message-id; bh=gU7ecDZdL4z/t81TZk6YVlIf5YQB18mJInOHzXd6oCo=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpfGhJaR9a2Zdtyxo3XabGCwTBJzaFOROnzgrO7
 roAuB9xtEOJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaXxoSQAKCRB2HuYUOZmu
 i3xUD/0eNVOOxAnydEiSMHqGLvweF+aImUsLO8cUSz8XGI22U53n7gdXlygL6+2qsG9r5UZL3XK
 IzpkLboj6W3POelztTOxTR0HAUaUiCrkPeW3Gc3wbmI27AxnQmgYHRHrq5+q0Cpey5e0u95Dhj7
 ZOBFE+NQ3bTUWifJC+BnAGhSQb8ku3HWOQJb6/CcdG5LWQ5qJJpq/xpeUK3d0x1slF/Z0E0/8j1
 rSQJB4DRIrkaePC/8IQW8DU9LJrduCdwFIJYOKwbqfhMT7l96qpaCnH+Cdt1C4WJ0ieJrYMapPH
 k3x7rbBusQ46JCGUYGkS38CxwAE26g2HLGYLY2R6uY7DCwBNRi8au7Cb0wXyDdBeUSpQ79qoTy0
 OmswfYAsNZmSHqkAN9txLek2nWoEDVAqY5pX6Rd2op/6bHpfiHeL4k4XupfGBlQH/9p3i6q5sxZ
 1o98w4DEgkmuS2U9P2cA3LkBi6jQ7H5vEYddlo0RXHKgAQ9/wlWaym2pABzRR9eu1fPe8DCJaV5
 tpREozdGATgj9+zQdOSvcJs3Tv8t4vcDGF78VJye+Flc8y79Sf2T/zTFVgKNHAvWbSRwgRluYye
 LFM4uCtHbbOJvQOp2uWKlPzVp6U2RQpiutYZ/jA73EaYwPBOKX8JQz+BzwjdWbU58o0P/Lvltn3
 7vsdwtsduR61stw==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After linux commit d29216842a85 ("mnt: Add a per mount namespace limit
on the number of mounts"), mount(2) might return ENOSPC.

---
Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
 man/man2/mount.2 | 13 +++++++++++++
 1 file changed, 13 insertions(+)

diff --git a/man/man2/mount.2 b/man/man2/mount.2
index d5a68cb836b2..bebd3c1792ba 100644
--- a/man/man2/mount.2
+++ b/man/man2/mount.2
@@ -793,6 +793,19 @@ A pathname was empty or had a nonexistent component.
 .B ENOMEM
 The kernel could not allocate a free page to copy filenames or data into.
 .TP
+.B ENOSPC
+Number of mounts will exceed the limit after this syscall in some mount
+namespaces. This limit is controlled by
+.IR /proc/sys/fs/mount-max ,
+see
+.BR proc_sys_fs (5)
+for details of this limit.
+Note that this limit applies both to the mount namespace where the mount
+operation occurs and to any mount namespaces to which the mount will propagate.
+See
+.BR mount_namespaces (7)
+for details for mount namespace and mount propagation.
+.TP
 .B ENOTBLK
 .I source
 is not a block device (and a device was required).

---
base-commit: 6754bd1a126ed1e9b7d9c2bc1d221681f5182bb3
change-id: 20260130-add-enospc-for-mount-3ea1e87af6ee

Best regards,
-- 
Chen Linxuan <me@black-desk.cn>

