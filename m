From: Michael Reeves <michael.reeves077@gmail.com>
Date: Mon, 05 Jan 2026 23:56:37 +1100
Subject: [PATCH 2/2] mfd: macsmc: Wire up Apple SMC power driver
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260105-b4-macsmc-power-v1-2-62954c42a555@gmail.com>
References: <20260105-b4-macsmc-power-v1-0-62954c42a555@gmail.com>
In-Reply-To: <20260105-b4-macsmc-power-v1-0-62954c42a555@gmail.com>
To: Sebastian Reichel <sre@kernel.org>, Sven Peter <sven@kernel.org>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Lee Jones <lee@kernel.org>
Cc: linux-kernel@vger.kernel.org, linux-pm@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1767617806; l=759;
 i=michael.reeves077@gmail.com; s=20260105; h=from:subject:message-id;
 bh=vIxVriW7LVSbZfkV9TYc6jdqEm/Rah71gDngXrG5xT8=;
 b=gEO+8YJiCNJnMoPAkVVFkeBS2Bp+zqvI2YBPM8YBi4e8rNuaYViJT9wmJNVsFpR/BWU0KnzkM
 BEHGIxPEbgJAzaHpT36JJsDTt6mzSGCiZNC/Vd81ZOM8uz/gefQvheP
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=QIrgWBGCm3LG0YYc6MLCDkwuVXLTGGooVBdWX/KhSiU=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/20260105 with auth_id=591
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the cell for the macsmc-power driver so it is probed by the
MFD core.

Co-developed-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
---
 drivers/mfd/macsmc.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/mfd/macsmc.c b/drivers/mfd/macsmc.c
index e3893e255ce5..061b43fc842d 100644
--- a/drivers/mfd/macsmc.c
+++ b/drivers/mfd/macsmc.c
@@ -45,6 +45,7 @@
 #define SMC_TIMEOUT_MS		500
 
 static const struct mfd_cell apple_smc_devs[] = {
+	MFD_CELL_NAME("macsmc-power"),
 	MFD_CELL_OF("macsmc-gpio", NULL, NULL, 0, 0, "apple,smc-gpio"),
 	MFD_CELL_OF("macsmc-reboot", NULL, NULL, 0, 0, "apple,smc-reboot"),
 };

-- 
2.51.2

