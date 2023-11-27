From: Nuno Sa <nuno.sa@analog.com>
Date: Mon, 27 Nov 2023 16:55:34 +0100
Subject: [PATCH 1/2] dt-bindings: adi,ad5791.yaml: Add support for
 controlling RBUF
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20231127-ad5791-michael-stuff-v1-1-04167b3edc56@analog.com>
References: <20231127-ad5791-michael-stuff-v1-0-04167b3edc56@analog.com>
In-Reply-To: <20231127-ad5791-michael-stuff-v1-0-04167b3edc56@analog.com>
To: linux-iio@vger.kernel.org, devicetree@vger.kernel.org
Cc: Lars-Peter Clausen <lars@metafoo.de>, 
 Michael Hennerich <Michael.Hennerich@analog.com>, 
 Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Michael Hennerich <michael.hennerich@analog.com>
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1701100539; l=917;
 i=nuno.sa@analog.com; s=20231116; h=from:subject:message-id;
 bh=0oarBF+t5l1h1kCQzFI2KDQV3L8snvDLRqcv7MsxVLA=;
 b=yOBKk0YqB2bxsTHK2s/2IGCZKAEIOMEAIb3uoyxh1efS7ryT+NoBuWnMKNtXYUCyiKDGk/6cm
 NNL4gGKa5a/A9VaMcG3d0iAiyoglAqFeBZGtLWkOMMH04Qx1RNJR040
X-Developer-Key: i=nuno.sa@analog.com; a=ed25519;
 pk=3NQwYA013OUYZsmDFBf8rmyyr5iQlxV/9H4/Df83o1E=
X-Endpoint-Received: by B4 Relay for nuno.sa@analog.com/20231116 with auth_id=100
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Michael Hennerich <michael.hennerich@analog.com>

This patch adds support for an external amplifier to be connected in a
gain of two configuration.

Signed-off-by: Michael Hennerich <michael.hennerich@analog.com>
Signed-off-by: Nuno Sa <nuno.sa@analog.com>
---
 Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml b/Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml
index 3a84739736f6..c81285d84db7 100644
--- a/Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml
+++ b/Documentation/devicetree/bindings/iio/dac/adi,ad5791.yaml
@@ -26,6 +26,11 @@ properties:
   vdd-supply: true
   vss-supply: true
 
+  adi,rbuf-gain2-en:
+    description: Specify to allow an external amplifier to be connected in a
+      gain of two configuration.
+    type: boolean
+
 required:
   - compatible
   - reg

-- 
2.43.0

