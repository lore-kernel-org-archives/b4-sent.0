From: David Heidelberg <david@ixit.cz>
Date: Tue, 16 Dec 2025 13:24:50 +0100
Subject: [PATCH v3 1/2] media: dt-bindings: Correct camss VDDA PLL supply
 description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251216-docs-camss-fixes-v3-1-c238b6810771@ixit.cz>
References: <20251216-docs-camss-fixes-v3-0-c238b6810771@ixit.cz>
In-Reply-To: <20251216-docs-camss-fixes-v3-0-c238b6810771@ixit.cz>
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vikram Sharma <quic_vikramsa@quicinc.com>, 
 Kapatrala Syed <akapatra@quicinc.com>, 
 Hariram Purushothaman <hariramp@quicinc.com>, 
 Richard Acayan <mailingradian@gmail.com>, Bryan O'Donoghue <bod@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, Depeng Shao <quic_depengs@quicinc.com>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4182; i=david@ixit.cz;
 h=from:subject:message-id; bh=RboAbdtfza+6rpP6+37BoeslOcwbopgvt6vIQ06lVT8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpQU+TYnM95O1xR3nh3MzuUEdQy0pxVzX4hkbBc
 MXufBHmXbmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaUFPkwAKCRBgAj/E00kg
 cj9/D/9uhriJFw8d8LyuV77Ub4Uc0xwo5OhpsmOuQeeESez20Q1uszOUOtXxomOxze9HV9V+t8g
 7kRvbatumTPXGY+6HmyVHczsZyp4MidTJ581qFs4Nnc+VPY6mS62ADYUS/O3pKi49RhuypC23xc
 sKq8/rms0J3n/jKArls8t1mK0Lrmwd1IryiThiyyD3qUS7LA+QU6y2WolzmpIy51eQrWY7VDdNs
 pvnfgw0N0JQ/l5tSnWjq18SVTotynUXmz8AB3GE6kWFuGzd1NuCLOoxjimAMqYw+spFTS73+G3d
 WW5A+cmFDYv2bl6pel6TgoM8IRBKRi/QQi2rfGEc+pKvFKJCF7mdr3IHXqcavXBIt9U2/TjSt6f
 JeS2BXtZcP4vp46PO8107BHUI+RE/g0EkzbrL2bEcxPRpC1KAxQFtkUn23S0nb/pI7Pjbsn5liK
 v4mBV75aJiDrLgtG9ElvUVOanRlJICaDBNH8mtjt69pxvYxCxJWEvWWEmpOcSvyOI0QXdHnYFJt
 KVeDjZLnmn9bXNWeXDp9BeCAefhv6ive6y/m1yS9dwGAvCneMJ6q6qNEaBcYfSqcxeuAFRNAc/1
 SCOdC9mLoCVSvL9uIqX+m4j+hRZMX4+XfqQRN9CDet5oleg3BX8/aQzhiNDlLjbbuTXN7GQ0iYB
 kbfMN4iHjl/q27Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Usually, the supply is around 1.2 V, not 1.8 V. Rather remove mention of
voltage from the description.

Fixes: 849139d46d09 ("media: dt-bindings: media: camss: Fixup vdda regulator descriptions sdm845")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml  | 2 +-
 Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml | 2 +-
 Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml   | 2 +-
 6 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
index 019caa2b09c32..4986d18d1a2da 100644
--- a/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
@@ -130,7 +130,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
index ee35e3bc97ffd..e4b0b7ffdc336 100644
--- a/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
@@ -129,7 +129,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
index c99fe4106eee9..9cba6e0819fb1 100644
--- a/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
@@ -268,7 +268,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
 required:
   - clock-names
diff --git a/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
index 35c40fe223767..61222839556bd 100644
--- a/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
@@ -95,7 +95,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
index 82bf4689d3300..03b9b34460b0a 100644
--- a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
@@ -211,7 +211,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
 required:
   - clock-names
diff --git a/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
index ebf68ff4ab961..acf9c54682107 100644
--- a/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
@@ -300,7 +300,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      1.2V regulator supply to CSIPHY IP blocks.
 
 required:
   - clock-names

-- 
2.51.0

