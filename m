From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Tue, 11 Nov 2025 17:50:17 +0000
Subject: [PATCH RESEND v2] scsi: pm: Drop unneeded call to
 pm_runtime_mark_last_busy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251111-scsi-pm-improv-v2-1-626b8491f4b4@analog.com>
To: linux-scsi@vger.kernel.org
Cc: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1762883425; l=1113;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=s7cddLv/0itS0gt0AH8XS27Y9mgippHn173s01vX9Rk=;
 b=YrCa9WG+27Szsky0+QmtnLULGxfdcAB9Em4oXhIzHtDcNe4iYJFEKRECfZMjZ86VrtU6HTtHi
 3niS5kvmDgNBFajUOu57pXLMuiYh/Yf1s0c6vhA612RlD9FCl/ln/F9
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There's no need to explicitly call pm_runtime_mark_last_busy() since
pm_runtime_autosuspend() is now doing it since commit 08071e64cb64
("PM: runtime: Mark last busy stamp in pm_runtime_autosuspend()")

Signed-off-by: Nuno Sá <nuno.sa@analog.com>
---
Changes in v2:
- Reference the commit introducing the change affecting this patch
- Link to v1: https://lore.kernel.org/r/20251027-scsi-pm-improv-v1-1-cb9f0bceb4be@analog.com
---
 drivers/scsi/scsi_pm.c | 1 -
 1 file changed, 1 deletion(-)

diff --git a/drivers/scsi/scsi_pm.c b/drivers/scsi/scsi_pm.c
index d581613d87c7..2652fecbfe47 100644
--- a/drivers/scsi/scsi_pm.c
+++ b/drivers/scsi/scsi_pm.c
@@ -205,7 +205,6 @@ static int scsi_runtime_idle(struct device *dev)
 	/* Insert hooks here for targets, hosts, and transport classes */
 
 	if (scsi_is_sdev_device(dev)) {
-		pm_runtime_mark_last_busy(dev);
 		pm_runtime_autosuspend(dev);
 		return -EBUSY;
 	}

---
base-commit: 8fec172c82c2b5f6f8e47ab837c1dc91ee3d1b87
change-id: 20251027-scsi-pm-improv-71477eb109c2
--

Thanks!
- Nuno Sá
-- 
Nuno Sá <nuno.sa@analog.com>

