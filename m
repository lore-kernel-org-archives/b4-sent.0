From: Ben Grisdale <bengris32@protonmail.ch>
Date: Wed, 11 Nov 2026 12:51:54 +0000
Subject: [PATCH] regulator: tps65132: Fix incorrect bits for VNEG/VPOS
 discharge
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261111-tps65132-discharge-fix-v1-1-c796428a5d43@protonmail.ch>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMwQ5AMBBEf0X2rElbJeFXxAFdrAPSRSSNf7eY2
 5u8mQiMgZChSiIEPIlpXQRMmkA/tcuIirwwWG0LI1H7xkVuMqs8sRhBjIEuhZ1HXWpXZs6BjLe
 AUn/HdfMzH92M/f6+wX0/2TlL1noAAAA=
X-Change-ID: 20261111-tps65132-discharge-fix-ebde09049344
To: Liam Girdwood <lgirdwood@gmail.com>, Mark Brown <broonie@kernel.org>, 
 Venkat Reddy Talla <vreddytalla@nvidia.com>, 
 Laxman Dewangan <ldewangan@nvidia.com>
Cc: linux-kernel@vger.kernel.org, Ben Grisdale <bengris32@protonmail.ch>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794401514; l=1425;
 i=bengris32@protonmail.ch; s=20261018; h=from:subject:message-id;
 bh=PnrNFcAZ5ldwdIhMuy2jJuUkQIJHnuZAIh/FbHRKmRo=;
 b=r7IRW4fYtS8IbbyW3nAx9vl7nERViBONi/sgE13jFnSj/khyFacRQmcxkg/H118+a+3JdteNV
 /llHze4HQABBXJ9SBQmBKtvLDv7uMTP5QeKvtFxiz21vKy20d3K4l0h
X-Developer-Key: i=bengris32@protonmail.ch; a=ed25519;
 pk=4ewFRC2yNph/tXokHVzIDlgOA9Hxecf1AlBuD4eOnaU=
X-Endpoint-Received: by B4 Relay for bengris32@protonmail.ch/20261018 with auth_id=1233
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

According to the TPS65132 datasheet [1], DISN (VNEG active discharge) is
bit 0 of register 0x03, while DISP (VPOS active discharge) is bit 1, as
described in Table 6. The driver currently has them swapped around, so
setting the active discharge of one output changes it on the other.

Swap the bit definitions to be consistent with the datasheet.

Fixes: 77c129bfefc8 ("regulator: tps65132: add regulator driver for TI TPS65132")
Link: https://www.ti.com/lit/ds/symlink/tps65132.pdf [1]
Signed-off-by: Ben Grisdale <bengris32@protonmail.ch>
---
 drivers/regulator/tps65132-regulator.c | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/drivers/regulator/tps65132-regulator.c b/drivers/regulator/tps65132-regulator.c
index 912db82ab51d..42388a170116 100644
--- a/drivers/regulator/tps65132-regulator.c
+++ b/drivers/regulator/tps65132-regulator.c
@@ -37,8 +37,8 @@
 #define TPS65132_VOUT_VMAX		6000000
 #define TPS65132_VOUT_STEP		100000
 
-#define TPS65132_REG_APPS_DIS_VPOS		BIT(0)
-#define TPS65132_REG_APPS_DIS_VNEG		BIT(1)
+#define TPS65132_REG_APPS_DIS_VNEG		BIT(0)
+#define TPS65132_REG_APPS_DIS_VPOS		BIT(1)
 
 #define TPS65132_REGULATOR_ID_VPOS	0
 #define TPS65132_REGULATOR_ID_VNEG	1

---
base-commit: 793807ca13bf3072fc6d16ce6d90e9ab9beff2a5
change-id: 20261111-tps65132-discharge-fix-ebde09049344

Best regards,
--  
Ben Grisdale <bengris32@protonmail.ch>

