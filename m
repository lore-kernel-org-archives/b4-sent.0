From: David Heidelberg <david@ixit.cz>
Date: Thu, 08 Jan 2026 00:04:30 +0100
Subject: [PATCH v2] media: ccs: Accommodate C-PHY into the calculation
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260108-ccs-account-for-cphy-v2-1-f2749ecf0733@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAH3mXmkC/4WNQQ6DIBBFr2Jm3WkAE9Sueo/GBR2hzAYMWKM13
 L3UC3T5XvLfPyDbxDbDrTkg2ZUzx1BBXRogb8LLIk+VQQmlhRQaiTIaovgOC7qYkGa/o3FD1/d
 PLdTgoE7nZB1vZ/YxVvacl5j282WVP/snuEqUSK1uh0kLrTp5542XK31gLKV8ASbcgca2AAAA
X-Change-ID: 20260106-ccs-account-for-cphy-af9788b6029f
To: Sakari Ailus <sakari.ailus@linux.intel.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, 
 Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1900; i=david@ixit.cz;
 h=from:subject:message-id; bh=pgifrmWzS93M40AkrvwrqvuNB9Em0PvPuVu5KPWYkkc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpXuZ/tSg/is/AuU7XMxXP5LVAvPoMiwqcI8u+i
 2WpM/Chrf6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaV7mfwAKCRBgAj/E00kg
 cqqkD/9JDlbDiNHaEuQ67d9ZmBvoLyan7X+vdNst4KlVIcrCifjoYS+xTj57D92gdHEjhZctiqP
 WmahRYRK+Kf9Sd/6awLhiYNbp7oCKrrWQgLQVy8cPtBXZmBkz2gIjJLyzvpeoJNCme47Av5ti1+
 Jj5v3X9lvfr6oS8zLZidxo1OCmxOhoU4N37DGJKFl00ZIFr9uVDzoa1EAwHViyVmrcS5o8Gf6C+
 pjq/CoZKhTYGZB9PEmA0t2zk0j/y0EKWX5Q/hZjLZyf0/FWtIZfH692MjX5ft8SgsJe4xMQd1Mx
 uhRK6s8i3dhwb0cIefIp+u07JEKQ2AuaeDmQEtZ6WJqQdNEgIX02mEGilXFt5deDH4lV2V8+3kU
 5K1xd1R/uCF0oSgu0tqUX+GYWUBmUq1NR7gfPIBqsQM1t8bw3qQhSbo9wC+UzS4yHIExnFg93Dm
 OlbGridgx5d+rUZzQ2FYKs4YwKzw0Qm7zosGQ9VfGj7d0DgoLp3hCJC3w8NUe5N+7mhJzmCftTb
 sn6fWGzFcAf8DblgFFIzKdpfkOqqVtvCTUGmNXqWkwP3Ae1S8AOi3K4QzqVtsQPx8BUjUluXBYU
 CaFNArFcp11ZEzKuxxTCUmkRF0PhaW6FqLWkgPtykLgmfHyxgXa9H3IRGS9eJyn/65GAtlaOUIb
 Wo5vjLxrPkFTykw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

We need to set correct mode for PLL to calculate correct frequency.
Signalling mode is known at this point, so use it for that.

Fixes: 47b6eaf36eba ("media: ccs-pll: Differentiate between CSI-2 D-PHY and C-PHY")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Account for CCP2 which PLL calculation handled same way as D-PHY.
- Add default statement for error handling. (Mehdi)
- Link to v1: https://lore.kernel.org/r/20260106-ccs-account-for-cphy-v1-1-c3639d606271@ixit.cz
---
 drivers/media/i2c/ccs/ccs-core.c | 17 ++++++++++++++++-
 1 file changed, 16 insertions(+), 1 deletion(-)

diff --git a/drivers/media/i2c/ccs/ccs-core.c b/drivers/media/i2c/ccs/ccs-core.c
index f8523140784c7..c1fff4029b5bd 100644
--- a/drivers/media/i2c/ccs/ccs-core.c
+++ b/drivers/media/i2c/ccs/ccs-core.c
@@ -3425,7 +3425,22 @@ static int ccs_probe(struct i2c_client *client)
 	sensor->scale_m = CCS_LIM(sensor, SCALER_N_MIN);
 
 	/* prepare PLL configuration input values */
-	sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
+	switch (sensor->hwcfg.csi_signalling_mode) {
+	case CCS_CSI_SIGNALING_MODE_CSI_2_CPHY:
+		sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_CPHY;
+		break;
+	case CCS_CSI_SIGNALING_MODE_CSI_2_DPHY:
+	case SMIAPP_CSI_SIGNALLING_MODE_CCP2_DATA_CLOCK;
+	case SMIAPP_CSI_SIGNALLING_MODE_CCP2_DATA_STROBE:
+		sensor->pll.bus_type = CCS_PLL_BUS_TYPE_CSI2_DPHY;
+		break;
+	default:
+		dev_err(&client->dev, "unsupported signalling mode %u\n",
+			sensor->hwcfg.csi_signalling_mode);
+		rval = -EINVAL;
+		goto out_cleanup;
+
+	}
 	sensor->pll.csi2.lanes = sensor->hwcfg.lanes;
 	if (CCS_LIM(sensor, CLOCK_CALCULATION) &
 	    CCS_CLOCK_CALCULATION_LANE_SPEED) {

---
base-commit: f96074c6d01d8a5e9e2fccd0bba5f2ed654c1f2d
change-id: 20260106-ccs-account-for-cphy-af9788b6029f

Best regards,
-- 
David Heidelberg <david@ixit.cz>

