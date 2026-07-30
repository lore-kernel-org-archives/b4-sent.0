From: =?utf-8?q?Dawid_Wr=C3=B3bel?= <me@dawidwrobel.com>
Date: Thu, 30 Jul 2026 23:52:02 +0200
Subject: [PATCH 3/4] arm64: dts: qcom: sm8250-xiaomi-elish: label the WiFi
 node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
Message-Id: <20260730-sm8250-xiaomi-enuma-v1-3-ed6d8fb99668@dawidwrobel.com>
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
X-Developer-Signature: v=1; a=openpgp-sha256; l=793; i=me@dawidwrobel.com;
 h=from:subject:message-id; bh=9PgRYneIZ007uPWyIFA5A8vuFZUckwmPT37f8xhISQU=;
 b=owGbwMvMwCV2qrTGfeXVd28ZT6slMWRlH++/dsorLKNw2Qa7Z4y/HeQ5bl3/+Jv71r1Ta5cXH
 3Nb0OPZ2VHKwiDGxSArpsiilxa0xyr45fd3L36Hw8xhZQIZwsDFKQAT+f+ckWF9ewOLn/J69/6Q
 dGvGj/XXUpek5elkuHc8m7CR8e6XyZkM//12//8+w1bI9taWj1fEo6pz/D/8S+tacsdnYe4chdI
 nBjwA
X-Developer-Key: i=me@dawidwrobel.com; a=openpgp;
 fpr=B64A778E0E64049A70C831C8B7B81FA12B282A92
X-Endpoint-Received: by B4 Relay for me@dawidwrobel.com/default with auth_id=901
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Mi Pad 5 Pro 5G shares this device tree but needs its own board data
variant, so give the node a label to allow overriding the property.

Signed-off-by: Dawid Wróbel <me@dawidwrobel.com>
---
 arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
index 19aff83ecf7b..12a2ba48340f 100644
--- a/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
+++ b/arch/arm64/boot/dts/qcom/sm8250-xiaomi-elish-common.dtsi
@@ -817,7 +817,7 @@ &pcie0_phy {
 };
 
 &pcieport0 {
-	wifi@0 {
+	wifi_0: wifi@0 {
 		compatible = "pci17cb,1101";
 		reg = <0x10000 0x0 0x0 0x0 0x0>;
 

-- 
2.55.0

