From: Joel Selvaraj <joelselvaraj.oss@gmail.com>
Date: Tue, 21 May 2024 09:02:57 -0500
Subject: [PATCH 1/2] dt-bindings: input: touchscreen: edt-ft5x06: Document
 FT5452 and FT8719 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-1-2a648ac7176b@gmail.com>
References: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-0-2a648ac7176b@gmail.com>
In-Reply-To: <20240521-add-support-ft5452-and-ft8719-touchscreen-v1-0-2a648ac7176b@gmail.com>
To: Dmitry Torokhov <dmitry.torokhov@gmail.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-input@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Joel Selvaraj <joelselvaraj.oss@gmail.com>
X-Mailer: b4 0.14-dev
X-Developer-Signature: v=1; a=ed25519-sha256; t=1716300186; l=837;
 i=joelselvaraj.oss@gmail.com; s=20240420; h=from:subject:message-id;
 bh=PmHC2ulzR6NuEbASOPCRVTimkIgpsuWNPVJYpR8+BgY=;
 b=tco50ujfsz4zA97zYnuTnvJ076l7r4lofkiasmm7wUaMZA7TB/KVzUG40KF5mCbDoWcjzmxxw
 90+wBBfzLJ/A748IkXhK8MaflSfd1aU038pudd/s25VW5uK+/gOH3Pz
X-Developer-Key: i=joelselvaraj.oss@gmail.com; a=ed25519;
 pk=qT4gsuVtlPE0Dpr+tQA/Fumm7wzVP6qfeVaY+6pX04s=
X-Endpoint-Received: by B4 Relay for joelselvaraj.oss@gmail.com/20240420 with auth_id=165
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Document FocalTech FT5452 and FT8719 support by adding their compatibles.

Signed-off-by: Joel Selvaraj <joelselvaraj.oss@gmail.com>
---
 Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
index f2808cb4d99df..745e57c05176e 100644
--- a/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
+++ b/Documentation/devicetree/bindings/input/touchscreen/edt-ft5x06.yaml
@@ -39,7 +39,9 @@ properties:
       - edt,edt-ft5406
       - edt,edt-ft5506
       - evervision,ev-ft5726
+      - focaltech,ft5452
       - focaltech,ft6236
+      - focaltech,ft8719
 
   reg:
     maxItems: 1

-- 
2.45.1

