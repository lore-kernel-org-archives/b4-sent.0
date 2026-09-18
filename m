From: Michael Reeves <michael.reeves077@gmail.com>
Date: Fri, 18 Sep 2026 21:06:44 +1000
Subject: [PATCH v2 01/10] dt-bindings: mailbox: apple: Add M3 ASC mailbox
 compatibles
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260918-apple-mtp-keyboard-final-v2-1-a5c685e50b60@gmail.com>
References: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
In-Reply-To: <20260918-apple-mtp-keyboard-final-v2-0-a5c685e50b60@gmail.com>
To: Sven Peter <sven@kernel.org>, Janne Grunau <j@jannau.net>, 
 Neal Gompa <neal@gompa.dev>, Jassi Brar <jassisinghbrar@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Hector Martin <marcan@marcan.st>, 
 Michael Reeves <michael.reeves077@gmail.com>, 
 "Joerg Roedel (AMD)" <joro@8bytes.org>, Will Deacon <will@kernel.org>, 
 Robin Murphy <robin.murphy@arm.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Jiri Kosina <jikos@kernel.org>, 
 Benjamin Tissoires <bentiss@kernel.org>
Cc: asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 iommu@lists.linux.dev, linux-input@vger.kernel.org, 
 Yureka Lilian <yureka@cyberchaos.dev>, Julian Braha <julianbraha@gmail.com>, 
 Sasha Finkelstein <k@chaosmail.tech>, 
 Conor Dooley <conor.dooley@microchip.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1789729608; l=1133;
 i=michael.reeves077@gmail.com; s=fedora-20260918; h=from:subject:message-id;
 bh=jWZaHgDdQBahv3cP0BkPbF81okNWtgFAdgZ27z/Vurk=;
 b=NgcEIACFNZmoME8QwmiMnJLz74jcA0zAHgOuztZXA/3Iw5uxazVfZiqOhirJuEmNb9Gn9PjB4
 ODfjjfyrivwBzJmK3yAAI4FyYqCypCMEu8J12WYo38Lim4nG6EmaXx0
X-Developer-Key: i=michael.reeves077@gmail.com; a=ed25519;
 pk=VJ0TvyQ9TvfzYZa908YSE9kpkjFLLD5luv0bERu+boc=
X-Endpoint-Received: by B4 Relay for michael.reeves077@gmail.com/fedora-20260918 with auth_id=1035
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the t8122, t6030 and t6031 ASC mailbox compatibles used by the
MTP coprocessor on M3, M3 Pro and M3 Max SoCs. They share the existing
ASC v4 mailbox interface.

Signed-off-by: Michael Reeves <michael.reeves077@gmail.com>
Acked-by: Conor Dooley <conor.dooley@microchip.com>
---
 Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml | 3 +++
 1 file changed, 3 insertions(+)

diff --git a/Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml b/Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
index 28985cc62..9a6dfb0b2 100644
--- a/Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
+++ b/Documentation/devicetree/bindings/mailbox/apple,mailbox.yaml
@@ -30,8 +30,11 @@ properties:
           - enum:
               - apple,t8103-asc-mailbox
               - apple,t8112-asc-mailbox
+              - apple,t8122-asc-mailbox
               - apple,t6000-asc-mailbox
               - apple,t6020-asc-mailbox
+              - apple,t6030-asc-mailbox
+              - apple,t6031-asc-mailbox
           - const: apple,asc-mailbox-v4
 
       - description:

-- 
2.55.0

