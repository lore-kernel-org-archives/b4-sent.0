From: Rodrigo Alencar <rodrigo.alencar@analog.com>
Date: Thu, 26 Mar 2026 18:32:16 +0000
Subject: [PATCH v2 1/2] dt-bindings: iio: amplifiers: ad8366: add
 adrf5702/3 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260326-adrf570x-iio-support-v2-1-b622a17335d0@analog.com>
References: <20260326-adrf570x-iio-support-v2-0-b622a17335d0@analog.com>
In-Reply-To: <20260326-adrf570x-iio-support-v2-0-b622a17335d0@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Jonathan Cameron <jic23@kernel.org>, David Lechner <dlechner@baylibre.com>, 
 Andy Shevchenko <andy@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Rodrigo Alencar <rodrigo.alencar@analog.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1774549942; l=1370;
 i=rodrigo.alencar@analog.com; s=default; h=from:subject:message-id;
 bh=5LWN54RWSnSJw3FPEr0nBjfRW9uleynujsENa8cqtPU=;
 b=3VVc1SYhLS/yD24Qnbw0v1RFJ2vRPdBckEXmz3AEDc56jlfkQ1rexdFelsP7YxsguVlegMbhl
 PGa5C9Pk8N2BXhNsxsVbeTEKFOx5bv1/PZEIwpn6DvngZxJi74tyJV9
X-Developer-Key: i=rodrigo.alencar@analog.com; a=ed25519;
 pk=ULeHbgU/OYh/PG/4anHDfLgldFItQHAhOktYRVLMFRo=
X-Endpoint-Received: by B4 Relay for rodrigo.alencar@analog.com/default with auth_id=561
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add compatible entries for ADRF5702 and ADRF5703 Digital Attenuators.
ADRF5702 is an 8-bit DSA with a step of 0.125 dB and ADRF5703 is a 7-bit
DSA with a step 0.25 dB. Then, each device ends up with its own gain
range, hence no fallback compatibles are used.

Reviewed-by: Nuno Sá <nuno.sa@analog.com>
Signed-off-by: Rodrigo Alencar <rodrigo.alencar@analog.com>
---
 Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
index 2719de1166a1..065637ce33a5 100644
--- a/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
+++ b/Documentation/devicetree/bindings/iio/amplifiers/adi,ad8366.yaml
@@ -20,6 +20,8 @@ properties:
       - adi,ad8366
       - adi,ada4961
       - adi,adl5240
+      - adi,adrf5702
+      - adi,adrf5703
       - adi,adrf5720
       - adi,adrf5730
       - adi,adrf5731
@@ -66,6 +68,8 @@ allOf:
               anyOf:
                 - const: adi,ad8366
                 - const: adi,ada4961
+                - const: adi,adrf5702
+                - const: adi,adrf5703
                 - const: adi,adrf5720
                 - const: adi,adrf5730
                 - const: adi,adrf5731

-- 
2.43.0

