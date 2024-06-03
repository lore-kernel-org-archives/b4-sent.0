From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Mon, 03 Jun 2024 19:22:59 +0300
Subject: [PATCH v5 1/9] dt-bindings: iio: adc: Add common-mode-channel
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240603-ad4111-v5-1-9a9c54d9ac78@analog.com>
References: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
In-Reply-To: <20240603-ad4111-v5-0-9a9c54d9ac78@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717431792; l=1609;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=yba6tP7JS+6mHrdlyW824eKSL9BwktJrw/w3K4BKVMQ=;
 b=UMNtbTu2auA50gLwkPnJfIR725zXZRSZvm72Yngt4yYk58WXq+zrgy+iiwOmaQet+V06k34p7
 X5iBXxgrvDrAPcAy+sPjeqDQwHT4CqvEZH+jhRhai4D0/Rk0pYTV4iH
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

There are ADCs that are differential but support to measure single-ended
signals on the same channels by connecting a constant voltage to the
negative input pin.

This property allows to properly define a single-ended channel that
requires two inputs to be specified. Software can use the presence of
this property to mark the channel as not differential.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adc.yaml | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adc.yaml b/Documentation/devicetree/bindings/iio/adc/adc.yaml
index 0a77592f7388..8e7835cf36fd 100644
--- a/Documentation/devicetree/bindings/iio/adc/adc.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adc.yaml
@@ -46,6 +46,17 @@ properties:
       differential channels). If this and diff-channels are not present reg
       shall be used instead.
 
+  common-mode-channel:
+    $ref: /schemas/types.yaml#/definitions/uint32
+    description:
+      Some ADCs have differential input pins that can be used to measure
+      single-ended or pseudo-differential inputs. This property can be used
+      in addition to single-channel to signal software that this channel is
+      not differential but still specify two inputs.
+
+      The input pair is specified by setting single-channel to the positive
+      input pin and common-mode-channel to the negative pin.
+
   settling-time-us:
     description:
       Time between enabling the channel and first stable readings.

-- 
2.43.0

