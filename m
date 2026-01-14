From: Yedaya Katsman <yedaya.ka@gmail.com>
Date: Wed, 14 Jan 2026 11:31:06 +0200
Subject: [PATCH v2 1/3] dt-bindings: input: touchscreen: edt-ft5x06: Add
 FocalTech FT3518
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260114-touchscreen-patches-v2-1-4215f94c8aba@gmail.com>
References: <20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com>
In-Reply-To: <20260114-touchscreen-patches-v2-0-4215f94c8aba@gmail.com>
To: SzczurekYT <szczurek@szczurek.yt>, 
 Dmitry Torokhov <dmitry.torokhov@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Yedaya Katsman <yedaya.ka@gmail.com>, 
 =?utf-8?q?Kamil_Go=C5=82da?= <kamil.golda@protonmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1768383069; l=984;
 i=yedaya.ka@gmail.com; s=20260113; h=from:subject:message-id;
 bh=SqsHa1FpeRSC7pDZsCiIt95zVp6duwvdtWnRvd2BIBs=;
 b=NXVOGklMCHzyDE9Vx6PjrhFq4h5CvOMmuoyJo+4WmwIuFMWGygUs/OxB/fYUrvzpiUTuw5ox6
 D7VqO1sVT4FCCXlZ1UrZPc7iBgJrDwhDo0o/be33K4qNSpL4TblsdpQ
X-Developer-Key: i=yedaya.ka@gmail.com; a=ed25519;
 pk=CgNmxD3tYSws5dZfpmJfc6re/bV/f47veVijddHLytk=
X-Endpoint-Received: by B4 Relay for yedaya.ka@gmail.com/20260113 with auth_id=601
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document FocalTech FT3518 support by adding the compatible.

Co-developed-by: Kamil Gołda <kamil.golda@protonmail.com>
Signed-off-by: Kamil Gołda <kamil.golda@protonmail.com>
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

