From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Tue, 13 Jan 2026 21:12:35 +0200
Subject: [PATCH 1/3] dt-bindings: input: touchscreen: edt-ft5x06: Add
 FocalTech FT3518
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260113-touchscreen-patches-v1-1-a10957f32dd8@gmail.com>
References: <20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com>
In-Reply-To: <20260113-touchscreen-patches-v1-0-a10957f32dd8@gmail.com>
To: SzczurekYT <szczurek@szczurek.yt>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768331572; l=968;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=VDXUFEuv3upbN0UDPU183YTwX159OGx06IcuT+Bl75c=;
 b=4HaDIpKbTWlZzeQ7JMrY/tTSkxG/wHVoHsaFj5UBJNVl9MRBSwINoOKNa8vAXkMddQ6M+GQk1
 af1tnPBcZnVAR1sg20jGtkpKA3Xbo+theHddb66uWiOazOQ2VTunYPe
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document FocalTech FT3518 support by adding the compatible.

Co-developed-by: SzczurekYT <szczurek@szczurek.yt>
Signed-off-by: SzczurekYT <szczurek@szczurek.yt>
Signed-off-by: Yedaya Katsman <yedaya.ka@gmail.com>
---
 Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index 7d3edb58f72d84ed19fb87fdd136c97f855aba00..6f90522de8c0afbe2d9d1e04578316350f66ec58 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
@@ -39,6 +39,7 @@ properties:
       - edt,edt-ft5406
       - edt,edt-ft5506
       - evervision,ev-ft5726
+      - focaltech,ft3518
       - focaltech,ft5426
       - focaltech,ft5452
       - focaltech,ft6236

-- 
2.52.0

