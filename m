From: Sven Peter <sven@kernel.org>
Date: Sat, 06 Sep 2025 15:43:32 +0000
Subject: [PATCH v2 19/22] arm64: dts: apple: t8103: Mark ATC USB AON
 domains as always-on
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250906-atcphy-6-17-v2-19-52c348623ef6@kernel.org>
References: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
In-Reply-To: <20250906-atcphy-6-17-v2-0-52c348623ef6@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>, Frank Li <Frank.Li@nxp.com>, 
 Ran Wang <ran.wang_1@nxp.com>, Peter Chen <peter.chen@nxp.com>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1274; i=sven@kernel.org;
 h=from:subject:message-id; bh=KlPzmlrett6VZZaPvH7/eARfg+MitLPN79oIzdJZz0w=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8aesKVv25TfrFpgvlCt8mzcumJ9y0ztH/ZTDEKmtq9d+
 JrN7fHhjlIWBjEOBlkxRZbt++1Nnzx8I7h006X3MHNYmUCGMHBxCsBEijYzMlzqWq1rX7rFWLbo
 CqNLej/H3vy0+wfTkpMYojP4V6drTGX471lmNdN+57zemxNlS/z67s02e/uXacWdf5lZh0u388t
 V8QIA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Shutting these down breaks dwc3 init done by the firmware. We probably
never want to do this anyway. The initialisation done in the ATC phy
driver is not sufficient to bring dwc3 back up after these power-domains
were shutdown for example after suspend to idle.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 arch/arm64/boot/dts/apple/t8103-pmgr.dtsi | 2 ++
 1 file changed, 2 insertions(+)

diff --git a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
index c41c57d63997a59a9fe3c88de31fddb31781398e..4bfe0d2de30ad6f975b31d443b62ef0e74b14324 100644
--- a/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
+++ b/arch/arm64/boot/dts/apple/t8103-pmgr.dtsi
@@ -1103,6 +1103,7 @@ ps_atc0_usb_aon: power-controller@88 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "atc0_usb_aon";
+		apple,always-on; /* Needs to stay on for dwc3 to work */
 	};
 
 	ps_atc1_usb_aon: power-controller@90 {
@@ -1111,6 +1112,7 @@ ps_atc1_usb_aon: power-controller@90 {
 		#power-domain-cells = <0>;
 		#reset-cells = <0>;
 		label = "atc1_usb_aon";
+		apple,always-on; /* Needs to stay on for dwc3 to work */
 	};
 
 	ps_atc0_usb: power-controller@98 {

-- 
2.34.1

