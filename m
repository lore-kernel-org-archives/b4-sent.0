From: Andrei Stancovici <andrei.stancovici@analog.com>
Date: Fri, 09 Oct 2026 11:43:34 +0300
Subject: [PATCH 1/6] dt-bindings: iio: adc: lltc,ltc2497: add LTC2493
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261009-submission-ltc2493-support-v1-v1-1-3dad1d4b152a@analog.com>
References: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
In-Reply-To: <20261009-submission-ltc2493-support-v1-v1-0-3dad1d4b152a@analog.com>
To: =?utf-8?q?Nuno_S=C3=A1?= <nuno.sa@analog.com>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Liam Beguin <liambeguin@gmail.com>
Cc: linux@analog.com, linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, 
 Andrei Stancovici <andrei.stancovici@analog.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791535413; l=1335;
 i=andrei.stancovici@analog.com; s=20261009; h=from:subject:message-id;
 bh=fP5njPLKeeNkILxLB5TKnpSRBSVEO3zumSVwQ+hdWcE=;
 b=ypbZCODq79zS5UhLlurwo6DsrNFtM7bJKoNiS4n2UZfOHT2BQNMvgCV8nYHwDwlobjruBa6UH
 BEMdWJsdEM0B4CI9ePuwBaSKAHiwKE4jxqBmnxcVsH7URxqtPMwj6wO
X-Developer-Key: i=andrei.stancovici@analog.com; a=ed25519;
 pk=wgT+au+blAhVYxhwNgdx0woNl/1p+OCG484rnTRFrsE=
X-Endpoint-Received: by B4 Relay for andrei.stancovici@analog.com/20261009 with auth_id=1140
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The LTC2493 is a 24-bit delta-sigma ADC with 4 single-ended or 2
differential inputs and an I2C interface. Its channel map matches no
part already listed, so it gets its own compatible rather than a
fallback; no new property is needed.

Signed-off-by: Andrei Stancovici <andrei.stancovici@analog.com>
---
 Documentation/devicetree/bindings/iio/adc/lltc,ltc2497.yaml | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/adc/lltc,ltc2497.yaml b/Documentation/devicetree/bindings/iio/adc/lltc,ltc2497.yaml
index 67445ad2bb3b..4df5aadd1e1d 100644
--- a/Documentation/devicetree/bindings/iio/adc/lltc,ltc2497.yaml
+++ b/Documentation/devicetree/bindings/iio/adc/lltc,ltc2497.yaml
@@ -23,6 +23,12 @@ description: |
 
     https://www.analog.com/media/en/technical-documentation/data-sheets/2309fd.pdf
 
+  LTC2493:
+    24bit ADC supporting up to 4 single ended or 2 differential inputs.
+    I2C interface.
+
+    https://www.analog.com/media/en/technical-documentation/data-sheets/2493fe.pdf
+
   LTC2497:
   LTC2499:
     16bit ADC supporting up to 16 single ended or 8 differential inputs.
@@ -36,6 +42,7 @@ properties:
     enum:
       - lltc,ltc2305
       - lltc,ltc2309
+      - lltc,ltc2493
       - lltc,ltc2497
       - lltc,ltc2499
 

-- 
2.43.0

