From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Tue, 18 Nov 2025 13:59:00 +0800
Subject: [PATCH v2 1/5] dt-bindings: arm: amlogic: meson-gx-ao-secure:
 support more SoCs
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251118-soc-info-s6-s7-s7d-v2-1-38e2b31a88d1@amlogic.com>
References: <20251118-soc-info-s6-s7-s7d-v2-0-38e2b31a88d1@amlogic.com>
In-Reply-To: <20251118-soc-info-s6-s7-s7d-v2-0-38e2b31a88d1@amlogic.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1763445540; l=1074;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=X2YO1s8uBuGAUV6Y26504dBNen26LRGhmjN4aH4eHgQ=;
 b=UvCK7bw2hkzxHmk8SJ/k4HJD2vMK0DPdkXSLdvTsXNyjDV5TxK4go+XkLV4ZsPuH06zv5X5JH
 Gb47s6uNqL+CGjF4M7L3WTMRHo45boBfKjXkhtBOOdkaTgPdJveIm0L
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add new compatible for ao-secure of Amlogic SoCs(S6,S7,S7D).

Acked-by: Conor Dooley <conor.dooley@microchip.com>
Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 .../devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml    | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml b/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
index b4f6695a6015..fa7c403c874a 100644
--- a/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
+++ b/Documentation/devicetree/bindings/arm/amlogic/amlogic,meson-gx-ao-secure.yaml
@@ -34,6 +34,9 @@ properties:
               - amlogic,a4-ao-secure
               - amlogic,c3-ao-secure
               - amlogic,s4-ao-secure
+              - amlogic,s6-ao-secure
+              - amlogic,s7-ao-secure
+              - amlogic,s7d-ao-secure
               - amlogic,t7-ao-secure
           - const: amlogic,meson-gx-ao-secure
           - const: syscon

-- 
2.37.1

