From: Sven Peter <sven@kernel.org>
Date: Tue, 10 Jun 2025 17:17:34 +0000
Subject: [PATCH 1/2] dt-bindings: nvmem: fixed-layout: Allow optional bit
 positions
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250610-nvmem-bit-pattern-v1-1-55ed5c1b369c@kernel.org>
References: <20250610-nvmem-bit-pattern-v1-0-55ed5c1b369c@kernel.org>
In-Reply-To: <20250610-nvmem-bit-pattern-v1-0-55ed5c1b369c@kernel.org>
To: Srinivas Kandagatla <srini@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Janne Grunau <j@jannau.net>, 
 Alyssa Rosenzweig <alyssa@rosenzweig.io>, Neal Gompa <neal@gompa.dev>, 
 Hector Martin <marcan@marcan.st>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Sasha Finkelstein <fnkl.kernel@gmail.com>, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1501; i=sven@kernel.org;
 h=from:subject:message-id; bh=B8ef7NKPQf8MeJRbWQzc5+78gOTS5XigM7aRKiQ2pMM=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ4ZHxoZ/okfto2eHbj4+w1y7M+nftQ55e03LZo58+ZYOa
 VtWs/yOUhYGMQ4GWTFFlu377U2fPHwjuHTTpfcwc1iZQIYwcHEKwERqZzMyHNZTTllZe/qq9eNF
 V90ZKxaz5WRMCbz97ILp6RIbMYZSUYZ/dtkLODTnn3v1hG0qX/uVlw5W3HfZlqV96O/tOOllu6G
 aEQA=
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

NVMEM nodes can optionally include the bits property to specify the bit
position of the cell within a byte.
Extend patternProperties to allow adding the bit offset to the node
address to be able to distinguish nodes with the same address but
different bit positions, e.g.

   trim@54,4 {
        reg = <0x54 1>;
        bits = <4 2>;
    };
    trim@54,0 {
        reg = <0x54 1>;
        bits = <0 4>;
    };

Before the conversion to NVMEM layouts in commit bd912c991d2e
("dt-bindings: nvmem: layouts: add fixed-layout") this extension was
originally added with commit 4b2545dd19ed ("dt-bindings: nvmem: Extend
patternProperties to optionally indicate bit position") to the now
deprecated layout.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 Documentation/devicetree/bindings/nvmem/layouts/fixed-layout.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/nvmem/layouts/fixed-layout.yaml b/Documentation/devicetree/bindings/nvmem/layouts/fixed-layout.yaml
index 9bd34bd5af30d83ae03d48b10f3b2c5be2ee9586..b01567f9928443fd0f6d4f252cf2632dbec0de9a 100644
--- a/Documentation/devicetree/bindings/nvmem/layouts/fixed-layout.yaml
+++ b/Documentation/devicetree/bindings/nvmem/layouts/fixed-layout.yaml
@@ -27,7 +27,7 @@ properties:
     const: 1
 
 patternProperties:
-  "@[a-f0-9]+$":
+  "@[a-f0-9]+(,[0-7])?$":
     type: object
     $ref: fixed-cell.yaml
     unevaluatedProperties: false

-- 
2.34.1

