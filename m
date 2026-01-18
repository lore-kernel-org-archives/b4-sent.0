From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Sun, 18 Jan 2026 22:29:40 +0200
Subject: [PATCH v3 1/3] dt-bindings: input: touchscreen: edt-ft5x06: Add
 FocalTech FT3518
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260118-touchscreen-patches-v3-1-1c6a729c5eb4@gmail.com>
References: <20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com>
In-Reply-To: <20260118-touchscreen-patches-v3-0-1c6a729c5eb4@gmail.com>
To: =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768768201; l=1054;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=1Bi52VIjh/c8wtJVop4mGIRRssaUV+3jz69Idk7ZinQ=;
 b=rnO1PoeLK+ZPbI/T1MmzsxTssLrHbpZzYh18ShBRx4/Ly63Miou3WZoGBwBukHCQEeaVJHmID
 RGwEt8D0zbeAbkhRgJzLn3o9nol58A1tA0fvFIvYvePiDUf4IbRmn9w
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document FocalTech FT3518 support by adding the compatible.

Co-developed-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Kamil Gołda <kamil.golda@protonmail.com>
Acked-by: Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>
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

