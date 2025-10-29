From: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>
Date: Wed, 29 Oct 2025 16:37:13 +0000
Subject: [PATCH v2] scsi: pm: Drop unneeded call to
 pm_runtime_mark_last_busy()
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20251029-scsi-pm-improv-v2-1-8c276c0eb1b9@analog.com>
X-B4-Tracking: v=1; b=H4sIALhCAmkC/3XMywrCMBCF4Vcps3YkCZVQV76HdJHEaTtgLiQSl
 JJ3N3bv8j9wvh0KZaYC12GHTJULx9BDnQZwmwkrIT96gxLqIoXSWFxhTB7ZpxwrajlqTVaKySn
 op5Rp4fcB3ufeG5dXzJ/Dr/K3/qWqRInOTouwjuxo6WaCecb17KKHubX2BaBWoYitAAAA
X-Change-ID: 20251027-scsi-pm-improv-71477eb109c2
To: linux-scsi@vger.kernel.org
Cc: "James E.J. Bottomley" <James.Bottomley@HansenPartnership.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761755839; l=1077;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=Ou05bUfOa9yU7mLqzgYfaId2pVPwLTtAQ5OCE+EPKUo=;
 b=B2eLKifMO5AX8AcyAqnHC08xxFAgJ7A8rtYR5FIIJRTX+EVjFVknWd5KwTZLgg8hTUihVWk9f
 yABOfzofmRAASnJZ+OAos/AZRocAH2wWfT2DdeoSvFzFlnyXd5L7WXC
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

