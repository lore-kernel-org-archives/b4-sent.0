From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Date: Thu, 30 Jul 2026 23:52:01 +0200
Subject: [PATCH 2/4] dt-bindings: arm: qcom: add the Xiaomi Mi Pad 5 Pro 5G
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-sm8250-xiaomi-enuma-v1-2-ed6d8fb99668@dawidwrobel.com>
References: <20260730-sm8250-xiaomi-enuma-v1-0-ed6d8fb99668@dawidwrobel.com>
In-Reply-To: <20260730-sm8250-xiaomi-enuma-v1-0-ed6d8fb99668@dawidwrobel.com>
To: Jianhua Lu <lujianhua000@gmail.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Jessica Zhang <jesszhan0024@gmail.com>, David Airlie <airlied@gmail.com>, 
 Simona Vetter <simona@ffwll.ch>, 
 Maarten Lankhorst <maarten.lankhorst@linux.intel.com>, 
 Maxime Ripard <mripard@kernel.org>, Thomas Zimmermann <tzimmermann@suse.de>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: dri-devel@lists.freedesktop.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=893; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=fLllZL12p66slp7ozlqH9iay8dnPtAgyjBfCTQiWkDo=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlH+8/t1D/yb5m883rz0Qq5rJPaOeUEkpTW/e1QnDLZ
 RGGs3kyHaUsDGJcDLJiiix6aUF7rIJffn/34nc4zBxWJpAhDFycAjCRhC2MDFvWqCSJKHr2TV8q
 fEGcm/lw/pkMNac27f1Vuaa3og5+ucLwz9T51qPiUIHzF2OlNnw+3rB7l6zcawn3RSbzH+glZUX
 e4gMA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mi Pad 5 Pro 5G (enuma) is the modem-equipped variant of the Mi Pad
5 Pro (elish) and shares its board design, so it falls back to the elish
compatible.

Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
 Documentation/devicetree/bindings/arm/qcom.yaml | 5 +++++
 1 file changed, 5 insertions(+)

diff --git a/Documentation/devicetree/bindings/arm/qcom.yaml b/Documentation/devicetree/bindings/arm/qcom.yaml
index f8c37096df46..a19d0146ae4b 100644
--- a/Documentation/devicetree/bindings/arm/qcom.yaml
+++ b/Documentation/devicetree/bindings/arm/qcom.yaml
@@ -1110,6 +1110,11 @@ properties:
               - xiaomi,pipa
           - const: qcom,sm8250
 
+      - items:
+          - const: xiaomi,enuma
+          - const: xiaomi,elish
+          - const: qcom,sm8250
+
       - items:
           - enum:
               - microsoft,surface-duo2

-- 
2.55.0

