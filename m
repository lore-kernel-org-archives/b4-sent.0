From: David Heidelberg <david@ixit.cz>
Date: Fri, 12 Dec 2025 23:55:57 +0100
Subject: [PATCH] media: dt-bindings: Correct camss VDDA PLL supply
 description
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251212-docs-camss-fixes-v1-1-5c011505ff59@ixit.cz>
X-B4-Tracking: v=1; b=H4sIAHydPGkC/x3LMQqAMAxA0atIZgNNoIheRRxKTTWDrTQggnh3i
 +Pj8x8wqSoGU/dAlUtNS26gvoO4h7wJ6toM7NgTE+NaomEMhxkmvcXQpeDZ80CjJ2jbWeUP7Zq
 X9/0AgZgaumIAAAA=
X-Change-ID: 20251212-docs-camss-fixes-0fa525271951
To: Robert Foss <rfoss@kernel.org>, Todor Tomov <todor.too@gmail.com>, 
 Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Vikram Sharma <quic_vikramsa@quicinc.com>, 
 Kapatrala Syed <akapatra@quicinc.com>, 
 Hariram Purushothaman <hariramp@quicinc.com>, 
 Richard Acayan <mailingradian@gmail.com>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 phone-devel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=4488; i=david@ixit.cz;
 h=from:subject:message-id; bh=qHMgX4yIAZfT5HLJApJFTrMsi2e0Zb8+cULYJUs4ldc=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpPJ19rhf2Bu4oI6wDHizm+ItUDiSmkginGNU4W
 h8yd9I5zFqJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaTydfQAKCRBgAj/E00kg
 corlD/0Xs0msufVJBrB5kVHvPM6tRGweLZPmBRHdC2oJCgJr6zNu3k4CJmEeQTqLZvsEQIozH5J
 0w0Y5IWbujAOXk6HfY16QUQhE8aS1kw/gGfVV1od1FNuKQS5bm6lqZ1wbZf67vlX9En/ZgxfVOe
 Nb8ke6kJ1gVjsbKprAJb4HLr01haX2MCjUKSlfwuJ7ny8C00pmrLi1ZN2y/Yo11zJmRnbWSC3ri
 i0dPwPK70fww0rK+hXVKS7DJ84TJ7bG3ovXjbs+oa0a9sXKeDd3lFvJ7hvLc7ooStsn0Tmec2nf
 iJGYf545z6AZRrqHAhaZ8LYdzmtJ/0XHjEjV1wyBazeUBG8ruU23ruWW03x08Us2/IcjGS7WA+r
 MDEJ5M23rvb7Ye0RFotYLTOcWMyiQyMX0fKVTNl+UtTwbMYKrSUqmHEoKjtcEcw+DHZ3jspMZ78
 eAyiR8aexLiTnzi8ZnEXUGBFb/NwNIumbHg0n+Ze7zvqdXn5/yQ9TeikB4j+f8HDAk1s1UjTuKX
 XexS7mqyKLBinAO3VdJQH6XQoFHi9A8bNchUWaOVBlsyUiK9JCG2JzXighwCqkn8b08/hrnutbv
 UEuj+GsBJAl8bnE0S/RvtIT9BuHLLaz6ONMrjlNSFcQ7kQd9rXpPUrOBrUIyXrfWzHYVDMCM6Sc
 4YD/MIMIf5EZu1Q==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Usually, the supply is around 1.2 V, not 1.8 V. Rather remove mention of
voltage from the description.

Fixes: 849139d46d09 ("media: dt-bindings: media: camss: Fixup vdda regulator descriptions sdm845")
Signed-off-by: David Heidelberg <david@ixit.cz>
---
Added only Fixes tag for the initial commit, not all the copy-paste
propagated ones.
---
 Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml  | 2 +-
 Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml | 2 +-
 Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml   | 2 +-
 Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml   | 2 +-
 6 files changed, 6 insertions(+), 6 deletions(-)

diff --git a/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
index 019caa2b09c32..9009cfe993d75 100644
--- a/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sa8775p-camss.yaml
@@ -130,7 +130,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
index ee35e3bc97ffd..cb922f90fe900 100644
--- a/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sc7280-camss.yaml
@@ -129,7 +129,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
index c99fe4106eee9..2231d7216f62a 100644
--- a/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sc8280xp-camss.yaml
@@ -268,7 +268,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
 required:
   - clock-names
diff --git a/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
index 35c40fe223767..8e6ca94c88695 100644
--- a/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sdm670-camss.yaml
@@ -95,7 +95,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
   ports:
     $ref: /schemas/graph.yaml#/properties/ports
diff --git a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
index 82bf4689d3300..d50e096b900db 100644
--- a/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sdm845-camss.yaml
@@ -211,7 +211,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
 required:
   - clock-names
diff --git a/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml b/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
index ebf68ff4ab961..ccd2d024bfd10 100644
--- a/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
+++ b/Documentation/devicetree/bindings/media/qcom,sm8250-camss.yaml
@@ -300,7 +300,7 @@ properties:
 
   vdda-pll-supply:
     description:
-      Phandle to 1.8V regulator supply to PHY refclk pll block.
+      Phandle to regulator supply to PHY refclk pll block.
 
 required:
   - clock-names

---
base-commit: d9771d0dbe18dd643760431870a6abf9b0866bb0
change-id: 20251212-docs-camss-fixes-0fa525271951

Best regards,
-- 
David Heidelberg <david@ixit.cz>

