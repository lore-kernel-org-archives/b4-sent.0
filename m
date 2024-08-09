From: Dumitru Ceclan <dumitru.ceclan@analog.com>
Date: Fri, 09 Aug 2024 13:33:24 +0300
Subject: [PATCH v2 1/2] dt-bindings: adc: ad7173: add support for ad4113
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20240809-ad4113-v2-1-2a70c101a1f4@analog.com>
References: <20240809-ad4113-v2-0-2a70c101a1f4@analog.com>
In-Reply-To: <20240809-ad4113-v2-0-2a70c101a1f4@analog.com>
To: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: mitrutzceclan@gmail.com, linux-iio@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Dumitru Ceclan <dumitru.ceclan@analog.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1723199607; l=1728;
 i=dumitru.ceclan@analog.com; s=20240313; h=from:subject:message-id;
 bh=58eDH7pibCEzmuIPyXvksyLIJ8t1xe4uNHVYeY1xQaM=;
 b=wREnjO6U0jdH6CQWmOFUXSOOFClg70AS/OBAiAJFVOX8Zilnop3z3Pm8nUFjt+sFbDohv/wlR
 z7yayJcy0pWAEVNg1syRl++0YllObPQB72emCn5gn1r6kyAGMGp2HD+
X-Developer-Key: i=dumitru.ceclan@analog.com; a=ed25519;
 pk=HdqMlVyrcazwoiai7oN6ghU+Bj1pusGUFRl30jhS7Bo=
X-Endpoint-Received: by B4 Relay for dumitru.ceclan@analog.com/20240313 with auth_id=140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This commit adds bindings support for AD4113.

The AD4113 is a low power, low noise, 16-bit, Σ-Δ analog-to-digital
converter (ADC) that integrates an analog front end (AFE) for four
fully differential or eight single-ended inputs.

Added ad4113 to the compatible list and the "avdd2-supply: false"
restriction.

Signed-off-by: Dumitru Ceclan <dumitru.ceclan@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml b/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
index 17c5d39cc2c1..ad15cf9bc2ff 100644
--- a/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/adi,ad7173.yaml
@@ -28,6 +28,7 @@ description: |
   Datasheets for supported chips:
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD4111.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD4112.pdf
+    <AD4113: not released yet>
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD4114.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD4115.pdf
     https://www.analog.com/media/en/technical-documentation/data-sheets/AD4116.pdf
@@ -44,6 +45,7 @@ properties:
     enum:
       - adi,ad4111
       - adi,ad4112
+      - adi,ad4113
       - adi,ad4114
       - adi,ad4115
       - adi,ad4116
@@ -331,6 +333,7 @@ allOf:
             enum:
               - adi,ad4111
               - adi,ad4112
+              - adi,ad4113
               - adi,ad4114
               - adi,ad4115
               - adi,ad4116

-- 
2.43.0

