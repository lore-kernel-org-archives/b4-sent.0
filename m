From: Sven Peter <sven@kernel.org>
Date: Thu, 21 Aug 2025 15:39:10 +0000
Subject: [PATCH RFC 18/22] usb: typec: mux: Introduce data_role to mux
 state
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250821-atcphy-6-17-v1-18-172beda182b8@kernel.org>
References: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
In-Reply-To: <20250821-atcphy-6-17-v1-0-172beda182b8@kernel.org>
To: Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Felipe Balbi <balbi@kernel.org>, 
 Janne Grunau <j@jannau.net>, Alyssa Rosenzweig <alyssa@rosenzweig.io>, 
 Neal Gompa <neal@gompa.dev>, Vinod Koul <vkoul@kernel.org>, 
 Kishon Vijay Abraham I <kishon@kernel.org>, 
 Thinh Nguyen <Thinh.Nguyen@synopsys.com>, 
 Heikki Krogerus <heikki.krogerus@linux.intel.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-usb@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, asahi@lists.linux.dev, 
 linux-arm-kernel@lists.infradead.org, linux-phy@lists.infradead.org, 
 Sven Peter <sven@kernel.org>, Hector Martin <marcan@marcan.st>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=832; i=sven@kernel.org;
 h=from:subject:message-id; bh=JRN0Pkcv1Gw9Rq/i5eF+ACOnqAvxuHK0oC9pDd6cKvY=;
 b=owGbwMvMwCHmIlirolUq95LxtFoSQ8Zy233WGZb7kycy/csIv9MoWLJLr6P0mWfg/jSNDxKST
 q8L0z07SlkYxDgYZMUUWbbvtzd98vCN4NJNl97DzGFlAhnCwMUpABPZOpWRYRk3h9t/k1k257m0
 GFvPl7k9vnvu1M5pF6/eV9nQJnT2WCvD/8ItJ1ynXdys4DJ9nmP53TPh5nHccsFrAx2X+30qdlx
 8mREA
X-Developer-Key: i=sven@kernel.org; a=openpgp;
 fpr=A1E3E34A2B3C820DBC4955E5993B08092F131F93
X-Endpoint-Received: by B4 Relay for sven@kernel.org/default with auth_id=407
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

From: Hector Martin <marcan@marcan.st>

Some muxes may need to know the data role that is being switched to,
such as to direct the data pins to separate host/device controllers or
configure a unified PHY correctly.

Signed-off-by: Hector Martin <marcan@marcan.st>
Signed-off-by: Sven Peter <sven@kernel.org>
---
 include/linux/usb/typec_mux.h | 1 +
 1 file changed, 1 insertion(+)

diff --git a/include/linux/usb/typec_mux.h b/include/linux/usb/typec_mux.h
index 2489a7857d8e10a73450a66ee85b5068f401f047..89b64ed081aecaa70529aaa717579c0dc7a5f961 100644
--- a/include/linux/usb/typec_mux.h
+++ b/include/linux/usb/typec_mux.h
@@ -45,6 +45,7 @@ void *typec_switch_get_drvdata(struct typec_switch_dev *sw);
 struct typec_mux_state {
 	struct typec_altmode *alt;
 	unsigned long mode;
+	enum typec_data_role data_role;
 	void *data;
 };
 

-- 
2.34.1

