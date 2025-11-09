From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Nov 2025 10:39:45 +0100
Subject: [PATCH RFC 2/8] media: qcom: camss: csiphy: Introduce C-PHY
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251109-qcom-cphy-v1-2-165f7e79b0e1@ixit.cz>
References: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
In-Reply-To: <20251109-qcom-cphy-v1-0-165f7e79b0e1@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, 
 Luca Weiss <luca.weiss@fairphone.com>, Petr Hodina <phodina@protonmail.com>, 
 Casey Connolly <casey.connolly@linaro.org>, "Dr. Git" <drgitx@gmail.com>
Cc: Joel Selvaraj <foss@joelselvaraj.com>, linux-media@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1919; i=david@ixit.cz;
 h=from:subject:message-id; bh=DQNIoS5WDVbc+Rdtl7ERIUO61m5Taapf/tMUESkjBiI=;
 b=kA0DAAgBYAI/xNNJIHIByyZiAGkQYXLIQEqxyicaFn15He6QmuX0Uic72wA5dR89dda5iOJO6
 YkCMwQAAQgAHRYhBNd6Cc/u3Cu9U6cEdGACP8TTSSByBQJpEGFyAAoJEGACP8TTSSByjpEQAIrZ
 5rQV5VatFQt+7Mhw14RYr9tDIaB5rP7Eq9GBwsA6r8ERp7zXk0IQpoYrkeLgtAbvIw18/6xbSp3
 uU7kTiriPGQ/hRVTh3nRXI75keiHkIiO7ewXIVwZjSu2gjtfqAZ71bEDZlQ+uNI4NkOVRmplAjw
 t/6CRNqmbqtSZKHFQQZsv+PAC7wTOQD9Qxft196BVhJayc83ON6RlfDT4eAkXjONUKMU7DtYX0P
 WrRXZC+2sZo3GgUpXCPI5mvooJltajt1bPQkM5vO3aZv7f38bA/RE37WE4ZyjtDV7PREGwqe5iD
 D/mgPce0JE4XoEiqhWeju1AuinhAKnTRyObF5l9DGhiXt+tQpR1CUgGBFmwKssgybgjE5wIbO2s
 pMzYqiBC6VBLlGRJz7CUcX/fCvR7IeIhHRasiIz1G858XxWoWXhsQ84RY4rhB0eymlG+RU3zqMo
 ko2BwzC1O/phb1r8xcd0HTwsG7oZ44+PdRQOYb6pAUFRKnjeLWnpbsuN7kANPVV3Uwtk1pqoaTz
 uFCznw79+0CbAbLkspEIgsALVJCPTX25vu3jTGQU6RrE5XJ6apkPT96t2KCP4f49Qy31DQb1vkO
 S27ldwzHOOCVfOq/SNYUN62NLV6IG1K1ZZfQ3ZqeM+1sSv2q9JVi9UojAtIFVlziCxaHYAM3Flc
 PXQgE
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Read C-PHY from the device-tree bus-type and save it into the csiphy
structure for later use.

For C-PHY, skip clock line configuration, as there is none.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy.h | 2 ++
 drivers/media/platform/qcom/camss/camss.c        | 8 ++++++--
 2 files changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy.h b/drivers/media/platform/qcom/camss/camss-csiphy.h
index 895f80003c441..8f7d0e4c73075 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy.h
+++ b/drivers/media/platform/qcom/camss/camss-csiphy.h
@@ -28,11 +28,13 @@ struct csiphy_lane {
 
 /**
  * struct csiphy_lanes_cfg - CSIPHY lanes configuration
+ * @cphy:     true if C-PHY is used, false if D-PHY is used
  * @num_data: number of data lanes
  * @data:     data lanes configuration
  * @clk:      clock lane configuration (only for D-PHY)
  */
 struct csiphy_lanes_cfg {
+	bool cphy;
 	int num_data;
 	struct csiphy_lane *data;
 	struct csiphy_lane clk;
diff --git a/drivers/media/platform/qcom/camss/camss.c b/drivers/media/platform/qcom/camss/camss.c
index fcc2b2c3cba07..549780f3f948b 100644
--- a/drivers/media/platform/qcom/camss/camss.c
+++ b/drivers/media/platform/qcom/camss/camss.c
@@ -4055,9 +4055,13 @@ static int camss_of_parse_endpoint_node(struct device *dev,
 	csd->interface.csiphy_id = vep.base.port;
 
 	mipi_csi2 = &vep.bus.mipi_csi2;
-	lncfg->clk.pos = mipi_csi2->clock_lane;
-	lncfg->clk.pol = mipi_csi2->lane_polarities[0];
 	lncfg->num_data = mipi_csi2->num_data_lanes;
+	lncfg->cphy = vep.bus_type == V4L2_MBUS_CSI2_CPHY;
+
+	if (!lncfg->cphy) {
+		lncfg->clk.pos = mipi_csi2->clock_lane;
+		lncfg->clk.pol = mipi_csi2->lane_polarities[0];
+	}
 
 	lncfg->data = devm_kcalloc(dev,
 				   lncfg->num_data, sizeof(*lncfg->data),

-- 
2.51.0

