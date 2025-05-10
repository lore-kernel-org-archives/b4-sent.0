From: Sven Peter <sven@svenpeter.dev>
Date: Sat, 10 May 2025 07:44:44 +0000
Subject: [PATCH 4/7] dt-bindings: nvmem: apple: Add T8112 compatible
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250510-nvmem-dt-v1-4-eccfa6e33f6a@svenpeter.dev>
References: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
In-Reply-To: <20250510-nvmem-dt-v1-0-eccfa6e33f6a@svenpeter.dev>
To: Srinivas Kandagatla <srinivas.kandagatla@linaro.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Sven Peter <sven@svenpeter.dev>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=803; i=sven@svenpeter.dev;
 h=from:subject:message-id; bh=1rEv9jNzjWLwB2+MWFArfWPPCr4WKfPng+/WgNvEPzQ=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4Y8C4PvicJlb00+JvVvFvq+NWXph6TEiiNVD74bLXz0/
 OFL3a+TO0pZGMQ4GGTFFFm277c3ffLwjeDSTZfew8xhZQIZwsDFKQATUfNh+B9XbvTq4S8N3oxP
 u1Y/2fD8ygy+/xsl79iarTDmSW55frqakeHa1qveyjbVLVnN7nLvlA8f/5FWMWGL8V+7rQ2sn9R
 j+DkA
X-Developer-Key: i=sven@svenpeter.dev; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@svenpeter.dev/default with auth_id=167
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The eFuse controller found in Apple's M2 is compatible to the one found
in M1 SoCs

Signed-off-by: Sven Peter <sven@svenpeter.dev>
---
 Documentation/devicetree/bindings/nvmem/apple,efuses.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/nvmem/apple,efuses.yaml b/Documentation/devicetree/bindings/nvmem/apple,efuses.yaml
index d3abdafdbca06245cdba000ce2ca757b5ce77d3f..2e8b014e9854a1a25d662bab75fee773c62369cd 100644
--- a/Documentation/devicetree/bindings/nvmem/apple,efuses.yaml
+++ b/Documentation/devicetree/bindings/nvmem/apple,efuses.yaml
@@ -24,6 +24,7 @@ properties:
       - enum:
           - apple,t8103-efuses
           - apple,t6000-efuses
+          - apple,t8112-efuses
       - const: apple,efuses
 
   reg:

-- 
2.34.1

