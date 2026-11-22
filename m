From: Robert Ijtsma <robertijtsma@gmail.com>
Date: Sun, 22 Nov 2026 14:36:21 +0100
Subject: [PATCH 1/2] remoteproc: qcom: pas: add SC8180X SLPI compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261122-sc8180x-slpi-v1-1-345903fafc96@gmail.com>
References: <20261122-sc8180x-slpi-v1-0-345903fafc96@gmail.com>
In-Reply-To: <20261122-sc8180x-slpi-v1-0-345903fafc96@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354582; l=1360;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=SeluMMGriinjyNsgC4NIGONS30tI/MuFdGdGq+5z5kM=;
 b=5gk+Vr/ojxgoPSgYD9SuROAunRDBbgWCQ3kVW9T5WEBUMuyAcnoyPS+FnEdqXYpnI+FwVJuLm
 O4/KAD779iPChYwlU5TtOrf1Wj2ZI6oHe+ZaO2FQBdC789zXmjH0RZ2
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SC8180X SLPI (Sensors Low-Power Island) shares the same PAS ID (12),
LCX/LMX power domains, and resource layout as SDM845 and SM8150, and
the compatible string "qcom,sc8180x-slpi-pas" is already documented in
Documentation/devicetree/bindings/remoteproc/qcom,sm8150-pas.yaml.

Add the OF match entry for qcom,sc8180x-slpi-pas reusing
sdm845_slpi_resource_init.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
 drivers/remoteproc/qcom_q6v5_pas.c | 1 +
 1 file changed, 1 insertion(+)

diff --git a/drivers/remoteproc/qcom_q6v5_pas.c b/drivers/remoteproc/qcom_q6v5_pas.c
index e7dfad2..21587a9 100644
--- a/drivers/remoteproc/qcom_q6v5_pas.c
+++ b/drivers/remoteproc/qcom_q6v5_pas.c
@@ -2029,6 +2029,7 @@ static const struct of_device_id qcom_pas_of_match[] = {
 	{ .compatible = "qcom,sc8180x-adsp-pas", .data = &sm8150_adsp_resource },
 	{ .compatible = "qcom,sc8180x-cdsp-pas", .data = &sm8150_cdsp_resource },
 	{ .compatible = "qcom,sc8180x-mpss-pas", .data = &sc8180x_mpss_resource },
+	{ .compatible = "qcom,sc8180x-slpi-pas", .data = &sdm845_slpi_resource_init },
 	{ .compatible = "qcom,sc8280xp-adsp-pas", .data = &sm8250_adsp_resource },
 	{ .compatible = "qcom,sc8280xp-nsp0-pas", .data = &sc8280xp_nsp0_resource },
 	{ .compatible = "qcom,sc8280xp-nsp1-pas", .data = &sc8280xp_nsp1_resource },

-- 
2.56.0

