From: David Heidelberg <david@ixit.cz>
Date: Thu, 31 Jul 2025 23:06:51 +0200
Subject: [PATCH RESEND v5 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250731-synaptics-rmi4-v5-1-cd0d87d34afa@ixit.cz>
References: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
In-Reply-To: <20250731-synaptics-rmi4-v5-0-cd0d87d34afa@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1304; i=david@ixit.cz;
 h=from:subject:message-id; bh=13S3lrILNzt/3asS2mqAeBe39EneqcPGVQTM//ivAKg=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBoi9r/7nSHwOgYs+0IMyD3zeC4tC01+w3tfVRxM
 NrrDb/HSI6JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaIva/wAKCRBgAj/E00kg
 ciQCD/0eMYcEqyE2cQvCK3PXANlBINqBcth8xK9GhDii1u/H175U8IQLL+ciZXbZY3JDGECKvj+
 KwyJGcNicEV8nMAEyzSHlVOgZsdflfFse/32VFPsq3S3TfWizfj0zWRtBKiWP7HICQypqGMVd4H
 5mHWlFVPrA6GmjTNN5EJl4FtCYkpOPn2XKOJwzoFXrhs9mBMbZP7fkNFOiwbnAT4+6GknB6CnD+
 3K6rl5pCxAOn2LW00FmbmVcaifzAU6yBHubV1zOAS+lQo5aadr23nDyu3Hnp9xM6oaUUvW23Cxs
 VwwP4IM6BNNIttjhTYENOyST399HwcPT9TRtD4sk6SCfRE6d/a2GktXWf4WEL5NJlqcDUXqO2FY
 feqNi4BdFaKwaiuCqraIeI1uom8Dtezxqug0MJn0KS54uaBp6t4dBoGA8OtRdSCjxELEjvGuf/n
 YRJi8XGvphFhH9OQGRUTtoueIf6XHEumz9I2ZvPxQrEd0YjdQC7Ddf7GaUHF+o4FPjNjDwCXowp
 mXiPYfcqiqHSslzUD5psjdMm5Ub61Ppa1CTmG4IJMrLziZd8SeYI2Ox7wGj1lKi2tdepPtsCO3v
 ZidbNAFew6bTX3xSN1QIu0uAWQ9DqnvcHr/yFCf0gVur3Jg3+TauQayflVAbPG/SLICELXnqpvY
 bzN1XHjfzdLoZKg==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly irrelevant for authentic Synaptics touchscreens, but very important
for applying workarounds to cheap TS knockoffs.

These knockoffs work well with the downstream driver, and since the user
has no way to distinguish them, later in this patch set, we introduce
workarounds to ensure they function as well as possible.

Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..d5d0225e3826fa5a0559cbd99115c505ab113aa0 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -18,9 +18,14 @@ description: |
 
 properties:
   compatible:
-    enum:
-      - syna,rmi4-i2c
-      - syna,rmi4-spi
+    oneOf:
+      - enum:
+          - syna,rmi4-i2c
+          - syna,rmi4-spi
+      - items:
+          - enum:
+              - syna,rmi4-s3706b  # OnePlus 6/6T
+          - const: syna,rmi4-i2c
 
   reg:
     maxItems: 1

-- 
2.50.1

