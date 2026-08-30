From: Sven Peter <sven@kernel.org>
Date: Sun, 30 Aug 2026 22:19:19 +0200
Subject: [PATCH 01/19] dt-bindings: usb: Add thunderbolt-switch property
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260830-b4-apple-soc-tbt-v1-1-44bc9348683c@kernel.org>
References: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
In-Reply-To: <20260830-b4-apple-soc-tbt-v1-0-44bc9348683c@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Janne Grunau <j@jannau.net>, Neal Gompa <neal@gompa.dev>, 
 Andreas Noever <andreas.noever@gmail.com>, 
 Mika Westerberg <westeri@kernel.org>, 
 Yehezkel Bernat <YehezkelShB@gmail.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: Konrad Dybcio <konradybcio@kernel.org>, linux-usb@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 asahi@lists.linux.dev, linux-arm-kernel@lists.infradead.org, 
 Sven Peter <sven@kernel.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1068; i=sven@kernel.org;
 h=from:subject:message-id; bh=AM+uADRTsie5/REEheLPhgbwiWPLSEIpJ/A32xZhBDE=;
 b=owGbwMvMwCXmIlirolUq95LxtFoSQ9aUCUHRPSviIt489LzkwM0pd0Fr586tWgtyjb2DWzveW
 ChM4gnrKGVhEONikBVTZNm+3970ycM3gks3XXoPM4eVCWQIAxenAExkuh3DX/G2G2avHrYoTJ7C
 +bRsRUKc/SFv/RiWGesK6rhuxTKm9jL89746k2XX7OdTNVyO3+1co37q7uyN4p9cT608FVHpKWX
 7iwcA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The USB4/Thunderbolt host routers on Apple Silicon SoCs require cable
and mode details to be provided out-of-band by the Type-C port controller.
Add a thunderbolt-switch property next to the existing orientation and mode
switches which marks a node as handler of these notifications.

Signed-off-by: Sven Peter <sven@kernel.org>
---
 Documentation/devicetree/bindings/usb/usb-switch.yaml | 6 ++++++
 1 file changed, 6 insertions(+)

diff --git a/Documentation/devicetree/bindings/usb/usb-switch.yaml b/Documentation/devicetree/bindings/usb/usb-switch.yaml
index f77731493dc4..5d125fbb252d 100644
--- a/Documentation/devicetree/bindings/usb/usb-switch.yaml
+++ b/Documentation/devicetree/bindings/usb/usb-switch.yaml
@@ -25,4 +25,10 @@ properties:
     description: Possible handler of SuperSpeed signals retiming
     type: boolean
 
+  thunderbolt-switch:
+    description:
+      Possible handler of USB4/Thunderbolt host router activation and cable
+      information updates
+    type: boolean
+
 additionalProperties: true

-- 
2.55.0

