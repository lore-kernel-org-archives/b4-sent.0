From: David Heidelberg <david@ixit.cz>
Date: Sat, 08 Mar 2025 15:08:37 +0100
Subject: [PATCH v3 1/7] dt-bindings: input: syna,rmi4: document
 syna,pdt-fallback-desc
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250308-synaptics-rmi4-v3-1-215d3e7289a2@ixit.cz>
References: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
In-Reply-To: <20250308-synaptics-rmi4-v3-0-215d3e7289a2@ixit.cz>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, "Jason A. Donenfeld" <Jason@zx2c4.com>, 
 Matthias Schiffer <matthias.schiffer@ew.tq-group.com>, 
 Vincent Huang <vincent.huang@tw.synaptics.com>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, phone-devel@vger.kernel.org, 
 ~postmarketos/upstreaming@lists.sr.ht, 
 Caleb Connolly <caleb.connolly@linaro.org>, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1840; i=david@ixit.cz;
 h=from:subject:message-id; bh=jfmUi6aalLoxYMxgZ9dsU2ijbzSO/6EcRXn0H1q6Lhw=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBnzE9pmemkpBW5RebUKjneZXgHyLcvBe53wAiOD
 /zx7wh9UG+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCZ8xPaQAKCRBgAj/E00kg
 ci7FEADNz7N+u/eG8cZSNAFeLMmu9Y8psA4jZYFiNqxKdCX7tOnd79NgC7Z87+Pw684EMK2AZLR
 IzZQRrtS8R/8ZmbA8VNG7FqFOHcsbQ1tm6NpxiE9+yvhZvJFSOJBtre4/U56V7CP7Cr0feg3ALu
 +UBSpGrGBc6TExUgP3Inh9ybV/RUdsPkWwNQ9DBxmHqOMwECGf1bITBvvmsleB6DDlAw4jzLNLw
 X3gJH2V4xVJiu1tqkAAgW5QMh2Jse+eE2H0RWdk+ageDilyzM8dZVL8iYYizV+rFeWWTRfqr/PV
 wV2nkeKxsLCbfA41O1SA1KEwkSVhh+e2hCgz8xQQIwr31TpQW5tHdO4qAV4G424uq0n/al9rAQn
 o9ClrXLzW2Mg8sY9J6oMkpvmqITYCcQDnLvmJ9KjkHQnSX15RHqztGT6a4P4tTzsTXHFECHhG7y
 sVaCJZXYWDpzCX6HzsilPg67wbWc8qqgwNpXFmOX3YiDaHTi6Joc0R1lKL0P0+id/93pQwkqjdl
 mEhrCDz12ZP9IrXRGjMuwtcILKtawkePnRGf6agrQ0uihH6yLZIX56jgSmWe2lNoH52dM/0FL0n
 a9xkf3wq50swfPgeHg/Z/nkl88uLlyjk5lr0mFk2MR/9egBbCRZCel1bpIB5TZyJF9xRAGhRVNj
 J+wO6yADY/u6QAA==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Caleb Connolly <caleb.connolly@linaro.org>

This new property allows devices to specify some register values which
are missing on units with third party replacement displays. These
displays use unofficial touch ICs which only implement a subset of the
RMI4 specification.

Signed-off-by: Caleb Connolly <caleb.connolly@linaro.org>
Signed-off-by: David Heidelberg <david@ixit.cz>
---
 Documentation/devicetree/bindings/input/syna,rmi4.yaml | 18 ++++++++++++++++++
 1 file changed, 18 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/syna,rmi4.yaml b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
index b522c8d3ce0db719ff379f2fefbdca79e73d027c..a80ec0c052cb1b7278f0832dd18ebd3256bc0874 100644
--- a/Documentation/devicetree/bindings/input/syna,rmi4.yaml
+++ b/Documentation/devicetree/bindings/input/syna,rmi4.yaml
@@ -49,6 +49,24 @@ properties:
     description:
       Delay to wait after powering on the device.
 
+  syna,pdt-fallback-desc:
+    $ref: /schemas/types.yaml#/definitions/uint8-matrix
+    description:
+      This property provides fallback values for certain register fields that
+      are missing on devices using third-party replacement displays.
+      These unofficial displays contain touch controllers that claim RMI4
+      compliance but fail to populate the function_number and function_version
+      registers of their Page Descriptor Table (PDT) entries.
+
+      Since the number of required fallback entries depends on the number of
+      Page Descriptor Tables supported by a given device, this property
+      should be provided on a best-effort basis.
+
+    items:
+      items:
+        - description: The 5th byte of the PDT entry (function number)
+        - description: The 4th byte of the PDT entry (version value)
+
   vdd-supply: true
   vio-supply: true
 

-- 
2.47.2

