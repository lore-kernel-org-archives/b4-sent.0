From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sat, 08 Mar 2025 22:47:55 +0100
Subject: [PATCH RESEND 1/4] media: i2c: imx214: Calculate link bit rate
 from clock frequency
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250308-imx214_clk_freq-v1-1-467a4c083c35@apitzsch.eu>
References: <20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu>
In-Reply-To: <20250308-imx214_clk_freq-v1-0-467a4c083c35@apitzsch.eu>
To: Ricardo Ribalda <ribalda@kernel.org>, 
 Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1741470489; l=4568;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=CrC/VI4OhUDXF04VluXMQqpjXLZSHaubF6hdre/ipkc=;
 b=ksDPMha74CZMFyaDj4yUSyZBJaSp6hfVgMvVji3dqL0Gj4mol1Tl5l4xGSDPeEiX3uA2G7jYl
 g1BwA3iZzyHAP5OVlKICfa2jVm2qSjaXy/B9Y2M6PuxIr13wmNPw6fr
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Replace the magic link bit rate number (4800) by its calculation based
on the used parameters and the provided external clock frequency.

The link bit rate is output bitrate multiplied by the number lanes. The
output bitrate is the OPPXCK clock frequency multiplied by the number of
bits per pixel. The OPPXCK clock frequency is OPCK multiplied by the
OPPXCK clock division ratio. And OPCK is the external clock frequency
multiplied by the PreDivider setting and the PLL multiple setting.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 drivers/media/i2c/imx214.c | 51 +++++++++++++++++++++++++++++++++-------------
 1 file changed, 37 insertions(+), 14 deletions(-)

diff --git a/drivers/media/i2c/imx214.c b/drivers/media/i2c/imx214.c
index 6c3f6f3c8b1f7724110dc55fead0f8a168edf35b..14a4c5094799014da38ab1beec401f0d923c2152 100644
--- a/drivers/media/i2c/imx214.c
+++ b/drivers/media/i2c/imx214.c
@@ -84,6 +84,7 @@
 #define IMX214_CSI_DATA_FORMAT_RAW10	0x0A0A
 #define IMX214_CSI_DATA_FORMAT_COMP6	0x0A06
 #define IMX214_CSI_DATA_FORMAT_COMP8	0x0A08
+#define IMX214_BITS_PER_PIXEL_MASK	0xFF
 
 #define IMX214_REG_CSI_LANE_MODE	CCI_REG8(0x0114)
 #define IMX214_CSI_2_LANE_MODE		1
@@ -104,11 +105,23 @@
 
 /* PLL settings */
 #define IMX214_REG_VTPXCK_DIV		CCI_REG8(0x0301)
+#define IMX214_DEFAULT_VTPXCK_DIV	5
+
 #define IMX214_REG_VTSYCK_DIV		CCI_REG8(0x0303)
+#define IMX214_DEFAULT_VTSYCK_DIV	2
+
 #define IMX214_REG_PREPLLCK_VT_DIV	CCI_REG8(0x0305)
+#define IMX214_DEFAULT_PREPLLCK_VT_DIV	3
+
 #define IMX214_REG_PLL_VT_MPY		CCI_REG16(0x0306)
+#define IMX214_DEFAULT_PLL_VT_MPY	150
+
 #define IMX214_REG_OPPXCK_DIV		CCI_REG8(0x0309)
+#define IMX214_DEFAULT_OPPXCK_DIV	10
+
 #define IMX214_REG_OPSYCK_DIV		CCI_REG8(0x030b)
+#define IMX214_DEFAULT_OPSYCK_DIV	1
+
 #define IMX214_REG_PLL_MULT_DRIV	CCI_REG8(0x0310)
 #define IMX214_PLL_SINGLE		0
 #define IMX214_PLL_DUAL			1
@@ -204,6 +217,14 @@
 #define IMX214_PIXEL_ARRAY_WIDTH	4208U
 #define IMX214_PIXEL_ARRAY_HEIGHT	3120U
 
+/* Link bit rate for a given input clock frequency in single PLL mode */
+#define IMX214_LINK_BIT_RATE(clk_freq) \
+	(((clk_freq) / 1000000) / IMX214_DEFAULT_PREPLLCK_VT_DIV \
+	* IMX214_DEFAULT_PLL_VT_MPY \
+	/ (IMX214_DEFAULT_OPSYCK_DIV * IMX214_DEFAULT_OPPXCK_DIV) \
+	* (IMX214_CSI_DATA_FORMAT_RAW10 & IMX214_BITS_PER_PIXEL_MASK) \
+	* (IMX214_CSI_4_LANE_MODE + 1))
+
 static const char * const imx214_supply_name[] = {
 	"vdda",
 	"vddd",
@@ -299,15 +320,16 @@ static const struct cci_reg_sequence mode_4096x2304[] = {
 	{ IMX214_REG_DIG_CROP_WIDTH, 4096 },
 	{ IMX214_REG_DIG_CROP_HEIGHT, 2304 },
 
-	{ IMX214_REG_VTPXCK_DIV, 5 },
-	{ IMX214_REG_VTSYCK_DIV, 2 },
-	{ IMX214_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX214_REG_PLL_VT_MPY, 150 },
-	{ IMX214_REG_OPPXCK_DIV, 10 },
-	{ IMX214_REG_OPSYCK_DIV, 1 },
+	{ IMX214_REG_VTPXCK_DIV, IMX214_DEFAULT_VTPXCK_DIV },
+	{ IMX214_REG_VTSYCK_DIV, IMX214_DEFAULT_VTSYCK_DIV },
+	{ IMX214_REG_PREPLLCK_VT_DIV, IMX214_DEFAULT_PREPLLCK_VT_DIV },
+	{ IMX214_REG_PLL_VT_MPY, IMX214_DEFAULT_PLL_VT_MPY },
+	{ IMX214_REG_OPPXCK_DIV, IMX214_DEFAULT_OPPXCK_DIV },
+	{ IMX214_REG_OPSYCK_DIV, IMX214_DEFAULT_OPSYCK_DIV },
 	{ IMX214_REG_PLL_MULT_DRIV, IMX214_PLL_SINGLE },
 
-	{ IMX214_REG_REQ_LINK_BIT_RATE, IMX214_LINK_BIT_RATE_MBPS(4800) },
+	{ IMX214_REG_REQ_LINK_BIT_RATE,
+		IMX214_LINK_BIT_RATE_MBPS(IMX214_LINK_BIT_RATE(IMX214_DEFAULT_CLK_FREQ)) },
 
 	{ CCI_REG8(0x3A03), 0x09 },
 	{ CCI_REG8(0x3A04), 0x50 },
@@ -362,15 +384,16 @@ static const struct cci_reg_sequence mode_1920x1080[] = {
 	{ IMX214_REG_DIG_CROP_WIDTH, 1920 },
 	{ IMX214_REG_DIG_CROP_HEIGHT, 1080 },
 
-	{ IMX214_REG_VTPXCK_DIV, 5 },
-	{ IMX214_REG_VTSYCK_DIV, 2 },
-	{ IMX214_REG_PREPLLCK_VT_DIV, 3 },
-	{ IMX214_REG_PLL_VT_MPY, 150 },
-	{ IMX214_REG_OPPXCK_DIV, 10 },
-	{ IMX214_REG_OPSYCK_DIV, 1 },
+	{ IMX214_REG_VTPXCK_DIV, IMX214_DEFAULT_VTPXCK_DIV },
+	{ IMX214_REG_VTSYCK_DIV, IMX214_DEFAULT_VTSYCK_DIV },
+	{ IMX214_REG_PREPLLCK_VT_DIV, IMX214_DEFAULT_PREPLLCK_VT_DIV },
+	{ IMX214_REG_PLL_VT_MPY, IMX214_DEFAULT_PLL_VT_MPY },
+	{ IMX214_REG_OPPXCK_DIV, IMX214_DEFAULT_OPPXCK_DIV },
+	{ IMX214_REG_OPSYCK_DIV, IMX214_DEFAULT_OPSYCK_DIV },
 	{ IMX214_REG_PLL_MULT_DRIV, IMX214_PLL_SINGLE },
 
-	{ IMX214_REG_REQ_LINK_BIT_RATE, IMX214_LINK_BIT_RATE_MBPS(4800) },
+	{ IMX214_REG_REQ_LINK_BIT_RATE,
+		IMX214_LINK_BIT_RATE_MBPS(IMX214_LINK_BIT_RATE(IMX214_DEFAULT_CLK_FREQ)) },
 
 	{ CCI_REG8(0x3A03), 0x04 },
 	{ CCI_REG8(0x3A04), 0xF8 },

-- 
2.48.1

