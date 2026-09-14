From: David Heidelberg <david@ixit.cz>
Date: Mon, 14 Sep 2026 20:14:15 +0200
Subject: [PATCH v3 2/4] backlight: qcom-wled: Fix WLED3 brightness register
 stride
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-qcom-wled-backlight-v3-2-d69fe9843841@ixit.cz>
References: <20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz>
In-Reply-To: <20260914-qcom-wled-backlight-v3-0-d69fe9843841@ixit.cz>
To: Lee Jones <lee@kernel.org>, Daniel Thompson <danielt@kernel.org>, 
 Jingoo Han <jingoohan1@gmail.com>, Helge Deller <deller@gmx.de>, 
 Kiran Gunda <quic_kgunda@quicinc.com>, 
 Marco Mattiolo <marco.mattiolo@hotmail.it>, 
 =?utf-8?q?Barnab=C3=A1s_Cz=C3=A9m=C3=A1n?= <barnabas.czeman@mainlining.org>
Cc: linux-arm-msm@vger.kernel.org, dri-devel@lists.freedesktop.org, 
 linux-fbdev@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, Konrad Dybcio <konrad.dybcio@oss.qualcomm.com>, 
 Joel Selvaraj <foss@joelselvaraj.com>, David Heidelberg <david@ixit.cz>, 
 stable@vger.kernel.org
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1777; i=david@ixit.cz;
 h=from:subject:message-id; bh=l2V9M/mtqxNb2sIjHPyjkihrWhmivYuqBuqKZxlIoYM=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqDl4e+EJzY/iCyxKxGF4mhW9oay6H5NgaCsGd
 Ohbw0JWgXWJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqg5eAAKCRBgAj/E00kg
 cmttD/4g8nziAhjgPhmtm3FoI3IvdN4iwbPG/MHGtdHuGY5A/UGENs944vkL0FDaObco14X87RS
 PWvcnas3xWcFqqi8SRIq9W3VjCmY1lYTKC/iMA7voLvBveHndyxNbuAwsEeg/52HbWMhJqzcHSu
 jI+F0WILo1resu1sMN6JWtDEdPGTbVFApxVG5lvDSvpivqMu4qFiC/VCqm7k+jJNd0HJIyixPyB
 9s5tOcOHL7+tlsY7Mi3Y+1fodLRVB537xn7+wOiKErHPPjL5g4/sMH9+go7L7F+yt37vrelpF4W
 JsoawBydmLnDQf387r/558axlGsDKfX3K/eZ5m7ZlqimE5VOqMhAJcoBNWy9w/qhAWvkxDL3y26
 uVatY0mKQEXnhWoAbpGL4TzEV48jGejbg/ynxt/VVCCKKPguiUyxVjDiK1Fgn/joxyyKi204XqR
 s1MXMSYiG/VuB4HpBmKEYiox8Wuk7Y6sFvvi/3cAqCyxAL5SOnhV+PY2g0iMLvjgd8UsvJS8fCJ
 cP6Nl0yvvTBfltTML1LGX/YHPu58+kdXUbD+49NgFG7KcFtU0MsD0UzkkKyBqRQqgkmmb7laDqh
 IXKneKRRpqvmLmSWum0wYBlOogDmy36YxZQdAIcepMkFPJ4rwRDb/HGk8NHSesqLk8pHIbmspMC
 X+UMNFwk1DlrFVQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WLED3 has a 16-bit brightness register pair per string, at 0x40 + 2*n,
which is what the pm8941-wled driver wrote to:

	rc = regmap_bulk_write(wled->regmap,
			wled->addr + WLED3_CTRL_REG_VAL_BASE + 2 * i,
			v, 2);

The restructuring for WLED3 turned that into WLED3_SINK_REG_BRIGHT(n),
defined as 0x40 + n, so the two byte writes for consecutive strings
overlap: string 1 overwrites the MSB of string 0 with its own LSB, and
with the default three strings only string 1 ends up with the requested
value.

Use the 2 byte stride.

Fixes: 775d2ffb4af6 ("backlight: qcom-wled: Restructure the driver for WLED3")
Cc: stable@vger.kernel.org
Assisted-by: LLM
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/video/backlight/qcom-wled.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/video/backlight/qcom-wled.c b/drivers/video/backlight/qcom-wled.c
index a76158a298335..e1962c2d90ed4 100644
--- a/drivers/video/backlight/qcom-wled.c
+++ b/drivers/video/backlight/qcom-wled.c
@@ -54,17 +54,17 @@
 #define WLED3_SINK_REG_SYNC				0x47
 #define  WLED3_SINK_REG_SYNC_CLEAR			0x00
 
 #define WLED3_SINK_REG_CURR_SINK			0x4f
 #define  WLED3_SINK_REG_CURR_SINK_MASK			GENMASK(7, 5)
 #define  WLED3_SINK_REG_CURR_SINK_SHFT			5
 
 /* WLED3 specific per-'string' registers below */
-#define WLED3_SINK_REG_BRIGHT(n)			(0x40 + n)
+#define WLED3_SINK_REG_BRIGHT(n)			(0x40 + (n * 0x10))
 
 #define WLED3_SINK_REG_STR_MOD_EN(n)			(0x60 + (n * 0x10))
 #define  WLED3_SINK_REG_STR_MOD_MASK			BIT(7)
 
 #define WLED3_SINK_REG_STR_FULL_SCALE_CURR(n)		(0x62 + (n * 0x10))
 #define  WLED3_SINK_REG_STR_FULL_SCALE_CURR_MASK	GENMASK(4, 0)
 
 #define WLED3_SINK_REG_STR_MOD_SRC(n)			(0x63 + (n * 0x10))

-- 
2.55.0

