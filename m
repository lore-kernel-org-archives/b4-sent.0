From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Thu, 06 Jun 2024 19:07:40 +0300
Subject: [PATCH v6 1/9] dt-bindings: iio: adc: Add common-mode-channel
 property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240606-ad4111-v6-1-573981fb3e2e@analog.com>
References: <20240606-ad4111-v6-0-573981fb3e2e@analog.com>
In-Reply-To: <20240606-ad4111-v6-0-573981fb3e2e@analog.com>
To: Ceclan Dumitru <dumitru.ceclan@analog.com>
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Dumitru Ceclan <mitrutzceclan@gmail.com>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1717690059; l=1665;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=7+gdjeLzhs0nsD3z5zCT8lTNIXL7WwI7n9Ywy4A7eJY=;
 b=oZyApd6X1HRxsMW2ljvKhFCgcD7m1xakV5QkuOdiYuZYfC09kzX47w5iLBItPUFBMYChHkRox
 DbE8aTtYIuVAfAA+YtcLuQcJ0RTBZqyFpfdZESWZ1cyAHLTB26Ar9yK
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

Reviewed-by: Conor Dooley <conor.dooley@microchip.com>
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

