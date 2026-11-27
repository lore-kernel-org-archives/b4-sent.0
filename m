From: Dickson Wu <dickson.wu@certik.com>
Date: Fri, 27 Nov 2026 06:39:32 +0000
Subject: [PATCH 5.15.y] scsi: qla2xxx: Completely fix fcport double free
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261127-so5-qla-515-v1-1-fc31e58ffd78@certik.com>
X-B4-Tracking: v=1; b=H4sIAKMlCWsC/02NSw7CMAxEr1J5jUsSYZC4CmKRj0uDqgTigkBV7
 04CG5bzNPNmAeESWeDYLVD4GSXmVIPedOBHmy6MMdQMRpm91uaAkgnvk0XShE6TUd6rXVAD1MW
 t8BBfX9sJqNfUv+H84/JwV/ZzU7Wms8Loik1+bEg4hTnnCRvf/l3Aun4A8fPAd6MAAAA=
X-Change-ID: 20261127-so5-qla-515-b1520cc04d0f
To: stable@vger.kernel.org
Cc: Vladimir Riabchun <ferr.lambarginio@gmail.com>, 
 "Martin K. Petersen" <martin.petersen@oracle.com>, 
 linux-scsi@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795761571; l=2352;
 i=dickson.wu@certik.com; s=dickson-b4; h=from:subject:message-id;
 bh=5PFq0t+9kyJ3bNqaWKXqN6KsLjWHosGjNZwrSng1BcI=;
 b=t81OAqjPnvuQC/yzrIuJo2vhHiIKCcAVPY/P8neWlpn4bBBH/XV03XQD0SPIHjwY4h1OfO49l
 wJGliHubiwnBDwNHJakqtP5jdaDneDOMwgaGXarIUxokRkShICiB+Ws
X-Developer-Key: i=dickson.wu@certik.com; a=ed25519;
 pk=fxH7FS4FdojeJSGLJzgKdfO51Rvr4EW30yinj2mc1vg=
X-Endpoint-Received: by B4 Relay for dickson.wu@certik.com/dickson-b4 with auth_id=1647
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Vladimir Riabchun <ferr.lambarginio@gmail.com>

commit c0b7da13a04bd70ef6070bfb9ea85f582294560a upstream.

In qla24xx_els_dcmd_iocb() sp->free is set to qla2x00_els_dcmd_sp_free().
When an error happens, this function is called by qla2x00_sp_release(),
when kref_put() releases the first and the last reference.

qla2x00_els_dcmd_sp_free() frees fcport by calling qla2x00_free_fcport().
Doing it one more time after kref_put() is a bad idea.

Fixes: 82f522ae0d97 ("scsi: qla2xxx: Fix double free of fcport")
Fixes: 4895009c4bb7 ("scsi: qla2xxx: Prevent command send on chip reset")
Signed-off-by: Vladimir Riabchun <ferr.lambarginio@gmail.com>
Signed-off-by: Farhat Abbas <fabbas@cloudlinux.com>
Link: https://patch.msgid.link/aYsDln9NFQQsPDgg@vova-pc
Signed-off-by: Martin K. Petersen <martin.petersen@oracle.com>
Signed-off-by: Dickson Wu <dickson.wu@certik.com>
---
6.1.y and newer already have this fix.

Tested on v5.15.226:
- x86_64 allmodconfig W=1 build of the qla2xxx driver and target objects,
  base vs patched, no new warnings
- booted the patched kernel under QEMU/KVM. I don't have QLogic Fibre
  Channel hardware, so the ELS error paths weren't exercised.

The backport and the test runs were prepared with AI coding tools
(OpenAI Codex agents, with review by Claude). I went over the result
before signing off.

drivers/scsi/qla2xxx/qla_iocb.c | 2 --
 1 file changed, 2 deletions(-)
---
 drivers/scsi/qla2xxx/qla_iocb.c | 2 --
 1 file changed, 2 deletions(-)

diff --git a/drivers/scsi/qla2xxx/qla_iocb.c b/drivers/scsi/qla2xxx/qla_iocb.c
index f080e1952927..3984b42fe0dd 100644
--- a/drivers/scsi/qla2xxx/qla_iocb.c
+++ b/drivers/scsi/qla2xxx/qla_iocb.c
@@ -2754,7 +2754,6 @@ qla24xx_els_dcmd_iocb(scsi_qla_host_t *vha, int els_opcode,
 	if (!elsio->u.els_logo.els_logo_pyld) {
 		/* ref: INIT */
 		kref_put(&sp->cmd_kref, qla2x00_sp_release);
-		qla2x00_free_fcport(fcport);
 		return QLA_FUNCTION_FAILED;
 	}
 
@@ -2779,7 +2778,6 @@ qla24xx_els_dcmd_iocb(scsi_qla_host_t *vha, int els_opcode,
 	if (rval != QLA_SUCCESS) {
 		/* ref: INIT */
 		kref_put(&sp->cmd_kref, qla2x00_sp_release);
-		qla2x00_free_fcport(fcport);
 		return QLA_FUNCTION_FAILED;
 	}
 

---
base-commit: 4f2df9a01754521fbba3493e8ad91ef65515e68c
change-id: 20261127-so5-qla-515-b1520cc04d0f

Best regards,
--  
Dickson Wu <dickson.wu@certik.com>

