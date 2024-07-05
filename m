From: Yang Li <yang.li@amlogic.com>
Date: Fri, 05 Jul 2024 19:20:47 +0800
Subject: [PATCH 4/4] MAINTAINERS: Add an entry for Amlogic HCI UART
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-btaml-v1-4-7f1538f98cef@amlogic.com>
References: <20240705-btaml-v1-0-7f1538f98cef@amlogic.com>
In-Reply-To: <20240705-btaml-v1-0-7f1538f98cef@amlogic.com>
To: Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Catalin Marinas <catalin.marinas@arm.com>, Will Deacon <will@kernel.org>
Cc: linux-bluetooth@vger.kernel.org, netdev@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, Yang Li <yang.li@amlogic.com>
X-Mailer: b4 0.13-dev-f0463
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178456; l=791;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=6p3yKY36l4948ddX8ZSkIlVHnk6qkn9A/zzKu777K74=;
 b=Ed7f/l9Xlg5GkNfTRh8J13KkPIycQeC2NgSckQjHhjTH/Y3uWKotFhN3wov3NdBahWbrMVZyg
 75upTDaX0koBeQHlSe1OyWlp8GW4djERI79GjmWdXegcqIa0lTlRKjh
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic Bluetooth driver and driver document.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 MAINTAINERS | 8 ++++++++
 1 file changed, 8 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index cd3277a98cfe..b81089290930 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1140,6 +1140,14 @@ S:	Supported
 F:	arch/arm64/boot/dts/amd/amd-seattle-xgbe*.dtsi
 F:	drivers/net/ethernet/amd/xgbe/
 
+AMLOGIC BLUETOOTH DRIVER
+M:	Yang Li <yang.li@amlogic.com>
+L:	linux-bluetooth@vger.kernel.org
+S:	Maintained
+W:	http://www.amlogic.com
+F:	Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
+F:	drivers/bluetooth/hci_aml.c
+
 AMLOGIC DDR PMU DRIVER
 M:	Jiucheng Xu <jiucheng.xu@amlogic.com>
 L:	linux-amlogic@lists.infradead.org

-- 
2.42.0

