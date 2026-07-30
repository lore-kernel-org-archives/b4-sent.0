From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Date: Thu, 30 Jul 2026 23:52:00 +0200
Subject: [PATCH 1/4] dt-bindings: display: panel: novatek,nt36523: add the
 Mi Pad 5 Pro 5G panel
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-sm8250-xiaomi-enuma-v1-1-ed6d8fb99668@dawidwrobel.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=1155; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=HLBHIFL7Bhy2H/xHi+CSj5nPkTSnPI1C32w3QZKtKr8=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlH++XM91l8LFvVpKjuqHynx+HStJ/Lny+Z8+7fU6nC
 vL3X2ON6ChlYRDjYpAVU2TRSwvaYxX88vu7F7/DYeawMoEMYeDiFICJqGow/OGfLPUuN9Fijcmd
 b1fNm3xv3vi+2bn7YKj31/yLUf90S94z/NMu43G/+q5zqffCggP3zH+UO1zh+8ARZxR26Pz5fHH
 WgwwA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Xiaomi Mi Pad 5 Pro 5G (enuma) ships the same CSOT panel as the Mi
Pad 5 Pro (elish), so it falls back to the elish compatible. Give it a
device-specific one in front, so a later difference does not need a
device tree change.

Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
 Documentation/devicetree/bindings/display/panel/novatek,nt36523.yaml | 4 ++++
 1 file changed, 4 insertions(+)

diff --git a/Documentation/devicetree/bindings/display/panel/novatek,nt36523.yaml b/Documentation/devicetree/bindings/display/panel/novatek,nt36523.yaml
index b9300a1f2646..2f3f34d08f29 100644
--- a/Documentation/devicetree/bindings/display/panel/novatek,nt36523.yaml
+++ b/Documentation/devicetree/bindings/display/panel/novatek,nt36523.yaml
@@ -22,6 +22,10 @@ properties:
               - xiaomi,elish-boe-nt36523
               - xiaomi,elish-csot-nt36523
           - const: novatek,nt36523
+      - items:
+          - const: xiaomi,enuma-csot-nt36523
+          - const: xiaomi,elish-csot-nt36523
+          - const: novatek,nt36523
       - items:
           - enum:
               - lenovo,j606f-boe-nt36523w

-- 
2.55.0

