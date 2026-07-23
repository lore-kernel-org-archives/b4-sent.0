From: Jack Wu <jackbb_wu@compal.com>
Date: Thu, 23 Jul 2026 16:34:32 +0800
Subject: [PATCH v5 7/7] net: wwan: t9xx: Add maintainers entry
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260723-t9xx_driver_v1-v5-7-b27afb99ccbb@compal.com>
References: <20260723-t9xx_driver_v1-v5-0-b27afb99ccbb@compal.com>
In-Reply-To: <20260723-t9xx_driver_v1-v5-0-b27afb99ccbb@compal.com>
To: Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Sergey Ryazanov <ryazanov.s.a@gmail.com>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Andrew Lunn <andrew+netdev@lunn.ch>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Jack Wu <jackbb_wu@compal.com>, Wen-Zhi Huang <wen-zhi.huang@mediatek.com>, 
 Shi-Wei Yeh <shi-wei.yeh@mediatek.com>, 
 Minano Tseng <Minano.tseng@mediatek.com>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Simon Horman <horms@kernel.org>, Jonathan Corbet <corbet@lwn.net>, 
 Shuah Khan <skhan@linuxfoundation.org>, Robert Yu <robert_yu@compal.com>, 
 Jeff Chang <Jeff_Chang@compal.com>
Cc: linux-kernel@vger.kernel.org, netdev@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-doc@vger.kernel.org
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784795677; l=899;
 i=jackbb_wu@compal.com; s=20260526; h=from:subject:message-id;
 bh=6MpjgGzXcGI3PS41xWiOq6mWrN6ZuUsiO+32dtE4ZE0=;
 b=HPw8pOFkwieUGpIkewogampNKF3EYt/SPcEABsAam5beBqmdF83brjUE/xr4SpNKq0qeIvdOQ
 Fr7pL34fTvOCDpP/QSmM35gbjXiczCe2hrKuNKIZFG7kpyR4sBV/rAr
X-Developer-Key: i=jackbb_wu@compal.com; a=ed25519;
 pk=VH1prTWixNl8OEUPPSfII3p46MzJpQN8J3+ecE1tZXg=
X-Endpoint-Received: by B4 Relay for jackbb_wu@compal.com/20260526 with auth_id=793
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MAINTAINERS entry for the MediaTek T9XX 5G WWAN modem device
driver.

Signed-off-by: Jack Wu <jackbb_wu@compal.com>
---
 MAINTAINERS | 11 +++++++++++
 1 file changed, 11 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 461a3eed6129..8f13ef7440ce 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -16494,6 +16494,17 @@ L:	netdev@vger.kernel.org
 S:	Supported
 F:	drivers/net/wwan/t7xx/
 
+MEDIATEK T9XX 5G WWAN MODEM DRIVER
+M:	Jack Wu <jackbb_wu@compal.com>
+M:	Robert Yu <robert_yu@compal.com>
+M:	Jeff Chang <Jeff_Chang@compal.com>
+R:	Wen-Zhi Huang <wen-zhi.huang@mediatek.com>
+R:	Shi-Wei Yeh <shi-wei.yeh@mediatek.com>
+R:	Minano Tseng <Minano.tseng@mediatek.com>
+L:	netdev@vger.kernel.org
+S:	Supported
+F:	drivers/net/wwan/t9xx/
+
 MEDIATEK USB3 DRD IP DRIVER
 M:	Chunfeng Yun <chunfeng.yun@mediatek.com>
 L:	linux-usb@vger.kernel.org

-- 
2.34.1

