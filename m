From: David Heidelberg <david@ixit.cz>
Date: Mon, 14 Sep 2026 19:42:47 +0200
Subject: [PATCH v2 1/3] backlight: qcom-wled: Fix WLED3 brightness register
 stride
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260914-qcom-wled-backlight-v2-1-a908d9233e93@ixit.cz>
References: <20260914-qcom-wled-backlight-v2-0-a908d9233e93@ixit.cz>
In-Reply-To: <20260914-qcom-wled-backlight-v2-0-a908d9233e93@ixit.cz>
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
 h=from:subject:message-id; bh=PsAxMRrlqktvAML3hjPt0kdVxbrGmbj1j8uq3J3KhxU=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqqDIczKVPe0nj8x6gYBinetl5UNl7M9qN/9D+u
 Huri6kL01OJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaqgyHAAKCRBgAj/E00kg
 cpRRD/4uxVlLCDyUgCdbl13H0nFe+KpG/WrmuFvVrcWCoeqUwbyrSKXINFNEGFO2MZguwOaGh1Z
 Qqo0tIv9KFB/iCTMR/oDegM+TaAIeWX0lsI3u/0fse4Mp/iUuolXWm16Vg8VgZIitH5TCpP/4ky
 m038DfnBD0B1efEf1UWHAVjz4npq7R5VSkfmWehv2CHBxooQCtlkPQEYXBtFHFPlJAAvl9a0G8N
 R7EQQQAoJ+33HOKS5Oq4ZWPfIFuaf39ut8Yg1m/rLAU9PMwfr8pBpfoj4q6ZRVPUSPxTUapmf/A
 TeRW9vm8lN5IH+240m+ugggXP8zr6ffLH7yfw7Qcw0gqOF+ZYq+rdj8oPJNm4P7WKDnwVwXboKI
 zeCWyNEGgyQk0Zku/LWwUC14oxfULW5Wp4/W+BcBRF8RQkqI2IJaDcqTe4K4CTMDpTgOwJu6x2S
 xrKTGWmJWvO6aKCd+VQCMHytzQ5kZi22Ii7M80qW8rxdkZU20Pbs7/2zyT40seoq6pd1ZthMVQv
 0e2TT6KgFY3DcEBodKTbKEpxTxGZVD9if7s73YS+p9BVRPcHtrkYE6/Xn2QOVY/5r2OoXYb8O7H
 ZNifwhPBfCA2e4u+JMA0xp+uckgaAie3iGfKpQnIRA7VoMRpCMN5zP4NLpSfsR/a94tPILnWB5f
 XrbZPdxAHtZzCPA==
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
index 650dd95f06ef5..22c35da72dce3 100644
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

