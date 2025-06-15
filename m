From: =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
Date: Sun, 15 Jun 2025 22:35:04 +0200
Subject: [PATCH v2 2/4] dt-bindings: arm: qcom: Add MSM8976 BQ Aquaris X5
 Plus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20250615-bqx5plus-v2-2-72b45c84237d@apitzsch.eu>
References: <20250615-bqx5plus-v2-0-72b45c84237d@apitzsch.eu>
In-Reply-To: <20250615-bqx5plus-v2-0-72b45c84237d@apitzsch.eu>
To: Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Marijn Suijten <marijn.suijten@somainline.org>
Cc: ~postmarketos/upstreaming@lists.sr.ht, phone-devel@vger.kernel.org, 
 linux-arm-msm@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 =?utf-8?q?Andr=C3=A9_Apitzsch?= <git@apitzsch.eu>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1750019747; l=847;
 i=git@apitzsch.eu; s=20240325; h=from:subject:message-id;
 bh=dI/0IRSIfadPPMn3LJmHpD092PxglhBVPQzVyv8YEEE=;
 b=0VBUKn+9rVlZx6PgT7UUtdMVOT/rdaBSzSdQDw04Ik9164kVYxwT6yl1VceC7Cur6Mh5MzElF
 r+GLLX4dJo4CYxajtuOw0whij7NJaOh0QV9IgPQL+XvWyxnlHhTO8dQ
X-Developer-Key: i=git@apitzsch.eu; a=ed25519;
 pk=wxovcZRfvNYBMcTw4QFFtNEP4qv39gnBfnfyImXZxiU=
X-Endpoint-Received: by B4 Relay for git@apitzsch.eu/20240325 with auth_id=142
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

BQ Aquaris X5 Plus (Longcheer L9360) is a smartphone based on MSM8976
SoC.

Signed-off-by: André Apitzsch <git@apitzsch.eu>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index 56f78f0f3803fedcb6422efd6adec3bbc81c2e03..1ca79192590f9e55de53d7fc7fe51c1b9a4a77bc 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -230,6 +230,11 @@ properties:
           - const: qcom,msm8974pro
           - const: qcom,msm8974
 
+      - items:
+          - enum:
+              - longcheer,l9360
+          - const: qcom,msm8976
+
       - items:
           - enum:
               - acer,a1-724

-- 
2.49.0

