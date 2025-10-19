From: Maud Spierings <maud_spierings@hotmail.com>
Date: Sun, 19 Oct 2025 06:43:51 +0200
Subject: [PATCH] ARM: i.MX: Fix the iomux DSE defines for imx8mp
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251019-iomux-v1-1-e049726947ce@hotmail.com>
X-B4-Tracking: v=1; b=H4sIAIZs9GgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1NDA0ML3cz83NIKXYPkpJQk42QTg1RDMyWg2oKi1LTMCrA50bG1tQCeQOD
 0VwAAAA==
X-Change-ID: 20251018-iomux-0cbdb3c40e16
To: Sascha Hauer <s.hauer@pengutronix.de>, 
 BAREBOX <barebox@lists.infradead.org>
Cc: Maud Spierings <maud_spierings@hotmail.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1760849031; l=1098;
 i=maud_spierings@hotmail.com; s=20241110; h=from:subject:message-id;
 bh=wSCw7H++Akrr2OTs+kN7LODotOxe6+O3NmjblvyF9hk=;
 b=+WJ/P9T/YjchV+hPvuQEpvDHhL7G07Bgxfb5oScGqJd2OBBgXE9GQQMPTkK7+UqBZgAtuW5Sf
 uQGoaA9ozTDCAyqdu9W9zYfSk2mUweJdDbhy0Uu2LJVNdGBgfRP3oHW
X-Developer-Key: i=maud_spierings@hotmail.com; a=ed25519;
 pk=CeFKVnZvRfX2QjB1DpdiAe2N+MEjwLEB9Yhx/OAcxRc=
X-Endpoint-Received: by B4 Relay for maud_spierings@hotmail.com/20241110 with auth_id=273
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The DSE field has a deceptive layout, DSE 2 is a higher value than DSE 4

See reference manual 8.2.2.1.3 or the description of any IOMUXC_SW_PAD_X
register in 8.2.4.144+

Fixes: 3c0d42752e9a ("arm: imx: add initial imx8mp support")
Signed-off-by: Maud Spierings <maud_spierings@hotmail.com>
---
 include/mach/imx/iomux-mx8mp.h | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)

diff --git a/include/mach/imx/iomux-mx8mp.h b/include/mach/imx/iomux-mx8mp.h
index 98e340d3dad1..da5cfe3048ca 100644
--- a/include/mach/imx/iomux-mx8mp.h
+++ b/include/mach/imx/iomux-mx8mp.h
@@ -1081,8 +1081,8 @@ enum {
 };
 
 #define MX8MP_PAD_CTL_DSE1	(0 << 1)
-#define MX8MP_PAD_CTL_DSE2	(1 << 1)
-#define MX8MP_PAD_CTL_DSE4	(2 << 1)
+#define MX8MP_PAD_CTL_DSE2	(2 << 1)
+#define MX8MP_PAD_CTL_DSE4	(1 << 1)
 #define MX8MP_PAD_CTL_DSE6	(3 << 1)
 #define MX8MP_PAD_CTL_FSEL	BIT(4)
 #define MX8MP_PAD_CTL_ODE	BIT(5)

---
base-commit: 8defba1d0ab1aef9dd5d57710e18d0d02e2c48e2
change-id: 20251018-iomux-0cbdb3c40e16

Best regards,
-- 
Maud Spierings <maud_spierings@hotmail.com>

