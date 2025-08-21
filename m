From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:38:53 +0000
Subject: [PATCH RFC 01/22] dt-bindings: usb: snps,dwc3: Allow multiple
 iommus
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-1-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=707; i=sven@kernel.org;
 h=from:subject:message-id; bh=//lvZcgVxWAuEEA3XDGiToePWRSnH3bkVOU2t/uuiIc=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy2/nG0SnPma7s+1u9jC+KO32S4AWrnn8X92R/kFnUn
 2z0xmB1RykLgxgHg6yYIsv2/famTx6+EVy66dJ7mDmsTCBDGLg4BWAiD7oY/koEWFjGfok9kx3/
 k3v65I0bfsR5Ji8oqNnHKmv2waD6PwvD/+qt78+F3JXaOeHTz5Ji7xnMT1MXKv9Yqbvl3YXZ3vw
 +zzgA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Apple's dwc3 variant requires two iommus.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 Documentation/devicetree/bindings/usb/snps,dwc3.yaml | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/Documentation/devicetree/bindings/usb/snps,dwc3.yaml b/Documentation/devicetree/bindings/usb/snps,dwc3.yaml
index 4380bb6fa2f08a475b557e80467abc2861f622e2..6d35dcc605c01977f4fc6fdb6f12976f1cef2b9e 100644
--- a/Documentation/devicetree/bindings/usb/snps,dwc3.yaml
+++ b/Documentation/devicetree/bindings/usb/snps,dwc3.yaml
@@ -60,7 +60,7 @@ properties:
   dma-coherent: true
 
   iommus:
-    maxItems: 1
+    maxItems: 2
 
   power-domains:
     description:

-- 
2.34.1

