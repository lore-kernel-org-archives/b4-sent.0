From: Satish Kharat <satishkh@cisco.com>
Date: Sat, 14 Feb 2026 06:26:02 -0800
Subject: [PATCH] MAINTAINERS: drop enic maintainer entry for benve
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260214-enic-maintainers-update-v1-1-5bec573f90ff@cisco.com>
X-B4-Tracking: v=1; b=H4sIAPmFkGkC/x2MOQ6AIBAAv2K2dhNEPL9iLFAX3UI0gMaE+HeJx
 RRTzETw5Jg89FkERzd7PmySIs9g3rRdCXlJDlLIWshCIVmecddsQ4Kcx+tcdCA0TVe3eiqnShl
 I9enI8POfh/F9P8GmhphpAAAA
To: linux-kernel@vger.kernel.org
Cc: netdev@vger.kernel.org, Satish Kharat <satishkh@cisco.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1771079168; l=707;
 i=satishkh@cisco.com; h=from:subject:message-id;
 bh=hrrYJtxFXPrrNRPRr7m5o4Zl6ZakysaA78D4Co4V8aY=;
 b=SoxCx0+j3d2EBLo+jSVGzdIsR98faUNM3bzZwZFw9cpoxC81/pu3vEwFkePtPg2hywlDoKtvZ
 ZZMuiQrp08SA8RJWq3ZwrJXtUixDrvU9kpXYUjSffZgYBLqFBINCYZP
X-Developer-Key: i=satishkh@cisco.com; a=ed25519;
 pk=4BxbLoCGvHeIMH/PbpiNVx8/2IcTjFvqcr0AD8K6WLY=
X-Endpoint-Received: by B4 Relay for satishkh@cisco.com/default with auth_id=639
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Remove Christian Benvenuti from the enic driver maintainer list.

Signed-off-by: Satish Kharat <satishkh@cisco.com>
---
 MAINTAINERS | 1 -
 1 file changed, 1 deletion(-)

diff --git a/MAINTAINERS b/MAINTAINERS
index 04e5fb80c32c..8b122a39dacf 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -6173,7 +6173,6 @@ S:	Supported
 F:	drivers/scsi/snic/
 
 CISCO VIC ETHERNET NIC DRIVER
-M:	Christian Benvenuti <benve@cisco.com>
 M:	Satish Kharat <satishkh@cisco.com>
 S:	Maintained
 F:	drivers/net/ethernet/cisco/enic/

---
base-commit: 37a93dd5c49b5fda807fd204edf2547c3493319c
change-id: 20260214-enic-maintainers-update-f7968ab3b54f

Best regards,
-- 
Satish Kharat <satishkh@cisco.com>

