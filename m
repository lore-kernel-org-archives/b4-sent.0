From: David Heidelberg <david@ixit.cz>
Date: Sun, 09 Nov 2025 10:39:49 +0100
Subject: [PATCH RFC 6/8] media: qcom: camss: csiphy-3ph: Use sdm845 C-PHY
 configuration sequence
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251109-qcom-cphy-v1-6-165f7e79b0e1@ixit.cz>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1280; i=david@ixit.cz;
 h=from:subject:message-id; bh=nfr/qGGID06B5OD83q38f0PZZSjfhMYGec9zEfG35dA=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpEGFyyePuixhaOiyf8A2P/GEclcOykEU12C2eU
 u4BeBtWC2mJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaRBhcgAKCRBgAj/E00kg
 cnYjD/9KCEaAnRuojFAoWEehaCNM56MLeAxGe5I7ssqSeoX4YcvJJ+ehdA5HRpcVSPcnuF5lCMV
 rqcwuDCpuncMXRurj4eDav04LUENS1UReMOU/z/y2GsoMgbmIPh6HOIKJdHOn9W1tCph8KTsCpw
 ZFzH+GMxX5Hdm69cFY2JWwFTj3S1nsiw8GNmM6SQt8rDbTc7r1dCnFn8+pqO6iu27YlpJxtpZjA
 NaASxpO4IEYBONOxgpGL/h1UzTNScS7tEnthar8lA12HAkF/Zi/BVlfzeu314tw8dgAJBlpSm7v
 DkiPT3morRrnpgybbM9YPyrxselJWuCmZ1TOJDfXIUTG+Hmsj3sONHZdX6UZDvXT8qHpKqRv1nT
 QWVbqdh3DFB/kbiqIdIFNTIIFoUWu8CmPdcf4uF6btOODeS9Mopq5vmlrD4lqVb3hQqGJd4oIUw
 0r6KIj+BCziGNMqY3bVTMBuPa9XiF/+GSaTx22czR+sSVDFp+tKd0N4TsgF6PzuHp1NbM867sl+
 J9Pe7dBieez4fLs9t43/NgRPTqfQRAn5yt95+L4LUhUQsgzIEvREzF5Nk9kuZAHv2C6XpGNDDc0
 o0ml18iNg5HybKwQRPLp9o1N9Kv9T6xoi1PXnufADen0RrWpAYC/B0ovj4T1msOlfDGbSOdqjdQ
 UAqux/51YhlDDPA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the 3-phase (3PH) lane configuration introduced earlier when
C-PHY mode is requested on the SDM845 platform. This ensures the proper
initialization sequence is used for C-PHY operation.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c | 10 ++++++++--
 1 file changed, 8 insertions(+), 2 deletions(-)

diff --git a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
index c2adbde6b4e0d..03f5c4676e89a 100644
--- a/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
+++ b/drivers/media/platform/qcom/camss/camss-csiphy-3ph-1-0.c
@@ -1103,8 +1103,14 @@ static void csiphy_lanes_enable(struct csiphy_device *csiphy,
 
 	switch (csiphy->camss->res->version) {
 	case CAMSS_845:
-		regs->lane_regs = &lane_regs_sdm845[0];
-		regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
+		if (c->cphy) {
+			regs->lane_regs = &lane_regs_sdm845_3ph[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845_3ph);
+
+		} else {
+			regs->lane_regs = &lane_regs_sdm845[0];
+			regs->lane_array_size = ARRAY_SIZE(lane_regs_sdm845);
+		}
 		break;
 	case CAMSS_2290:
 		regs->lane_regs = &lane_regs_qcm2290[0];

-- 
2.51.0

