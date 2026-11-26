From: Fabricio Akio <fabricioakio@gmail.com>
Date: Wed, 25 Nov 2026 23:20:34 -0300
Subject: [PATCH 1/2] remoteproc: qcom: pas: Vote the SDM660 ADSP's power
 domain while it boots
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261125-sdm660-adsp-proxy-rail-v1-1-b91784c69623@gmail.com>
References: <20261125-sdm660-adsp-proxy-rail-v1-0-b91784c69623@gmail.com>
In-Reply-To: <20261125-sdm660-adsp-proxy-rail-v1-0-b91784c69623@gmail.com>
To: Bjorn Andersson <andersson@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Abel Vesa <abelvesa@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-arm-msm@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dmitry Baryshkov <lumag@kernel.org>, Martin Botka <martin.botka1@gmail.com>, 
 Alexey Minnekhanov <alexeymin@minlexx.ru>, 
 Fabricio Akio <fabricioakio@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795659634; l=1546;
 i=fabricioakio@gmail.com; s=20260928; h=from:subject:message-id;
 bh=zkoyiWmiLPqXph/5+tayJyD7KHTTIW/Ma10fRXwCfwY=;
 b=GG2gnXZ+nJmYpXxqhPCe5aXn2j6T28oYiN5PTPpZJIpYF3Nba4cMfp3BwSNnXAp3p36jotJ8K
 d0cUJBkDqpEBjtpjtoU+NXpO+omUFbymMp3YQ0xCAI/n8KqTyFnEMGv
X-Developer-Key: i=fabricioakio@gmail.com; a=ed25519;
 pk=TlMUT8bPI/ZQzp2q24BIQTb2qSx/jdUTBlGEXIRCm54=
X-Endpoint-Received: by B4 Relay for fabricioakio@gmail.com/20260928 with auth_id=1076
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The SDM660 ADSP uses adsp_resource_init, which names no proxy power
domain, so the driver votes no rail for the DSP while it boots. On an
SDM630 phone the first start after boot succeeds without one; after a
stop, every later start times out waiting for the DSP.

Use msm8996_adsp_resource, which differs only in voting the "cx" power
domain until the DSP signals handover.

Fixes: a0a77028c85a ("remoteproc: q6v5_pas: Add sdm660 ADSP PIL compatible")
Signed-off-by: Fabricio Akio <fabricioakio@gmail.com>
---
 drivers/remoteproc/qcom_q6v5_pas.c | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/drivers/remoteproc/qcom_q6v5_pas.c b/drivers/remoteproc/qcom_q6v5_pas.c
index ff2483529d73..d5b03a433a6d 100644
--- a/drivers/remoteproc/qcom_q6v5_pas.c
+++ b/drivers/remoteproc/qcom_q6v5_pas.c
@@ -2050,7 +2050,7 @@ static const struct of_device_id qcom_pas_of_match[] = {
 	{ .compatible = "qcom,sc8280xp-adsp-pas", .data = &sm8250_adsp_resource },
 	{ .compatible = "qcom,sc8280xp-nsp0-pas", .data = &sc8280xp_nsp0_resource },
 	{ .compatible = "qcom,sc8280xp-nsp1-pas", .data = &sc8280xp_nsp1_resource },
-	{ .compatible = "qcom,sdm660-adsp-pas", .data = &adsp_resource_init },
+	{ .compatible = "qcom,sdm660-adsp-pas", .data = &msm8996_adsp_resource },
 	{ .compatible = "qcom,sdm660-cdsp-pas", .data = &cdsp_resource_init },
 	{ .compatible = "qcom,sdm670-adsp-pas", .data = &sdm670_adsp_resource_init },
 	{ .compatible = "qcom,sdm845-adsp-pas", .data = &sdm845_adsp_resource_init },

-- 
2.56.1

