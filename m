From: David Heidelberg <david@ixit.cz>
Date: Wed, 02 Apr 2025 20:44:52 +0200
Subject: [PATCH v4 1/7] dt-bindings: input: syna,rmi4: Document
 syna,rmi4-s3706b-i2c
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250402-synaptics-rmi4-v4-1-1bb95959e564@ixit.cz>
References: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
In-Reply-To: <20250402-synaptics-rmi4-v4-0-1bb95959e564@ixit.cz>
To: Kaustabh Chakraborty <kauschluss@disroot.org>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Caleb Connolly <caleb.connolly@linaro.org>, 
 phone-devel@vger.kernel.org, ~postmarketos/upstreaming@lists.sr.ht, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1244; i=david@ixit.cz;
 h=from:subject:message-id; bh=gIdWscr+Jqvsk707l9xEQnt4g2c2mNRlbPov8t2ekx4=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBn7YWmm94NXqofT7XHkun4456S/omngFthawuI/
 E08x/7b8OSJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ+2FpgAKCRBgAj/E00kg
 crtTD/46/cU7EY2JWszwm4hLlXx6LZEpm+URrZCQpo2ii6zbwAdzRrWF8yaDWeD9zLsKB/f5XlJ
 G8tSJq1udn+CmVxZXtm/a2qMSAAddvziLcDKSl27NWgokHzdTEGVSCSrb/f6MRLbLVm1kgOraX3
 bgzuBIO8RS4Bp83lx1Q7gbjoKMhALiDuQNfRJt1KOSpjuIq5H84sLmK49mqFbQEeBIWEOnyO09c
 mJKMZsnvyyKqU7A05axvB6jWOaLfdSzlJiY7ckFBrs4e9QcAA2FinXTLIUZWWBcEbgzaWU8sB+h
 NgvCrVxE1PV5GPJYf/XhM19o5kHfTe2ZFs/eaPCACCg3qYvkREYdCrodxPrz1Mr4KUgXPDPjCrY
 SqkgSbaEsZMAlTs+3BMbWVXVk8f2OrHu6vYF5qUMehUcvUFlAXqxC1rX2aXwONOSNE2eaOvdSy+
 Ch3JrjWCazi1iWXcnCItGhvUjfrC4o+SLipmcqEUdBK5PZpyiEX19NB4nrzPviFBHltSCRmF+qK
 CUtd1fXjidYTDaITnezz+ekBLJ1wnVHa4G1p1fVIH+oDVRYWxeQVfIu//qO6qzDcA5qb+8oGWss
 bcwUTJvIj6pMf7m+ggEthsN5Htl6iW8QguRnyBgJxT4gXJOv9YxWmc1f6ztbd6fig+/ji8dGJzk
 +9P1xSsTgHaEelw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Mostly irrelevant for authentic Synaptics touchscreens, but very important
for applying workarounds to cheap TS knockoffs.

These knockoffs work well with the downstream driver, and since the user
has no way to distinguish them, later in this patch set, we introduce
workarounds to ensure they function as well as possible.

Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 11 ++++++++---
 1 file changed, 8 insertions(+), 3 deletions(-)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..855614718bfd1c6c41805d64e713cf5635c20f10 100644
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
+              - syna,rmi4-s3706b-i2c  # OnePlus 6/6T
+          - const: syna,rmi4-i2c
 
   reg:
     maxItems: 1

-- 
2.49.0

