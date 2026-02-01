From: Chen Linxuan <me@black-desk.cn>
Date: Sun, 01 Feb 2026 11:59:33 +0800
Subject: [PATCH v2] man/man2/mount.2: add ENOSPC
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260201-add-enospc-for-mount-v2-1-43c990199cc6@black-desk.cn>
X-B4-Tracking: v=1; b=H4sIAKTPfmkC/4WNSw7CIBRFt9K8sc/wsbVx5D5MBxQellShgUo0D
 XsXuwGH5yT33A0SRUcJLs0GkbJLLvgK4tCAnpS/EzpTGQQTHeOSoTIGyYe0aLQh4jO8/IqSFKf
 +rGxHBHW6RLLuvWdvQ+XJpTXEz/6S+c/+CWaOHPt2PLWWaZKmv44PpWc0lOaj9jCUUr7DXddYv
 AAAAA==
X-Change-ID: 20260130-add-enospc-for-mount-3ea1e87af6ee
To: Alejandro Colomar <alx@kernel.org>
Cc: linux-man@vger.kernel.org, CAI Qian <caiqian@redhat.com>, 
 "Eric W. Biederman" <ebiederm@xmission.com>, 
 Chen Linxuan <me@black-desk.cn>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1518; i=me@black-desk.cn;
 h=from:subject:message-id; bh=+y9EMiP/IH2Uz/tYjScMx2l0NpB9p+FLiJPVbwBeQPA=;
 b=owEBbQKS/ZANAwAKAXYe5hQ5ma6LAcsmYgBpfs+qAM9+rQU25/ggPGYEUhhG0+GMkgWWKhKGO
 itrryCzqPiJAjMEAAEKAB0WIQTO1VElAk6xdvy0ZVp2HuYUOZmuiwUCaX7PqgAKCRB2HuYUOZmu
 i22bD/0Ywlg0oLZP2athUs3SlIk2x9fXvxfRlqjmHJHN+W2y7JjrwlPoht4Xk89Ke0diUsYypC0
 eCopvR7C07AQup1XYjtaBwV26L7qICk+sdNOc7hon0PWf26JXPIlQickCcX3MPXxv+ruebFtRTj
 Zq5G8q5uitF9u+GTyo1K92VVDEA17ucJd0NFB+RkaVeQFKp8+JvYcZXhzKTXPEXfGoY4nK3Rn+A
 gp9d1gTZquvfk7kCXp43WmFMR44//eAffYOeZJAQkEomC2SCSWtUlOx8y4EUqCMuglONpdTndoW
 0Dhc/MXsWEE148Z5349fJ0cPvUWK9rstfIJv2svqG4SFH/UkD+ksiexLaz76fE+RZh6Mh02Gi7V
 bbc38cqtAMfmruMM8oZfYt2lz9JfzuH0VdGL14bxZoxuomrNZP/ByHswwAYFmuhS2FTH6pkVTYp
 2rynB2Ty8rSXpsplbK/5MmB8iO8zyagx1QQLctaQLk3yTQ29eihQfX/pOvPcNJqmcfBfOIGcvew
 3muIAuFdpZymsL0WIryARSdJIQSH8XFNSTRrnugnCPPaF4WP6sq/oPjjP9a/UVJfetbV981VI25
 UaJaeFKPzDqxkwgM1kIp8vbnVjt813/71kNPCzoLHsM0vFTCvxeLhVRN/g3CdQla13agGHl8fyK
 hQ2ndlFYcV14r/Q==
X-Developer-Key: i=me@black-desk.cn; a=openpgp;
 fpr=D818ACDD385CAE92D4BAC01A6269794D24791D21
X-Endpoint-Received: by B4 Relay for me@black-desk.cn/default with auth_id=573
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

After linux commit d29216842a85 ("mnt: Add a per mount namespace limit
on the number of mounts"), mount(2) might return ENOSPC.

Signed-off-by: Chen Linxuan <me@black-desk.cn>
---
Changes in v2:
- Apply changes suggested by Alejandro:
  - Correct the sign-off line;
  - Use semantic newlines.
- Link to v1: https://lore.kernel.org/r/20260130-add-enospc-for-mount-v1-1-85b45f0ce3d8@black-desk.cn
---
 man/man2/mount.2 | 15 +++++++++++++++
 1 file changed, 15 insertions(+)

diff --git a/man/man2/mount.2 b/man/man2/mount.2
index d5a68cb836b2..35fef946a6d6 100644
--- a/man/man2/mount.2
+++ b/man/man2/mount.2
@@ -793,6 +793,21 @@ A pathname was empty or had a nonexistent component.
 .B ENOMEM
 The kernel could not allocate a free page to copy filenames or data into.
 .TP
+.B ENOSPC
+Number of mounts will exceed the limit after this syscall
+in some mount namespaces.
+This limit is controlled by
+.IR /proc/sys/fs/mount-max ,
+see
+.BR proc_sys_fs (5)
+for details of this limit.
+Note that this limit applies
+both to the mount namespace where the mount operation occurs
+and to any mount namespaces to which the mount will propagate.
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

