From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Date: Thu, 27 Nov 2025 15:30:31 +0800
Subject: [PATCH 1/4] dt-bindings: reset: Add compatible for Amlogic
 S6/S7/S7D
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20251127-reset-s6-s7-s7d-v1-1-879099ad90d3@amlogic.com>
References: <20251127-reset-s6-s7-s7d-v1-0-879099ad90d3@amlogic.com>
In-Reply-To: <20251127-reset-s6-s7-s7d-v1-0-879099ad90d3@amlogic.com>
To: Philipp Zabel <p.zabel@pengutronix.de>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-amlogic@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Xianwei Zhao <xianwei.zhao@amlogic.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1764228641; l=907;
 i=xianwei.zhao@amlogic.com; s=20231208; h=from:subject:message-id;
 bh=2OdK+NCY/4qzOMjaRXwivbbB/E5n4gnbT5hQIb0Cm7w=;
 b=Nni4wp2m2zGAhsKqwfP0M8WsDPvUTnG4Clu5t7Ln4JMqDxq9m52wyAoK7g+VEMXQNkb7oIpi0
 YSfvz6dJag5DYsqZrNwv4j5qMKQ9UuadQghQJcJqBVPDfKHjp5KJTwu
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=o4fDH8ZXL6xQg5h17eNzRljf6pwZHWWjqcOSsj3dW24=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20231208 with auth_id=107
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatibles for Amlogic S6/S7/S7D reset controllers,
which fall back to 'amlogic,meson-s4-reset'.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
 Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml b/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
index 150e95c0d9be..ab0239cf16e5 100644
--- a/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
+++ b/Documentation/devicetree/bindings/reset/amlogic,meson-reset.yaml
@@ -25,6 +25,9 @@ properties:
           - enum:
               - amlogic,a4-reset
               - amlogic,a5-reset
+              - amlogic,s6-reset
+              - amlogic,s7-reset
+              - amlogic,s7d-reset
           - const: amlogic,meson-s4-reset
 
   reg:

-- 
2.37.1

