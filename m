From: Yang Li <yang.li@amlogic.com>
Date: Fri, 02 Aug 2024 17:39:49 +0800
Subject: [PATCH v3 3/3] MAINTAINERS: Add an entry for Amlogic HCI UART (M:
 Yang Li)
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240802-btaml-v3-3-d8110bf9963f@amlogic.com>
References: <20240802-btaml-v3-0-d8110bf9963f@amlogic.com>
In-Reply-To: <20240802-btaml-v3-0-d8110bf9963f@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1722591623; l=782;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=JCpkGkVAbaLnnsN6aT/w92n7ppHeCAU2X3+VbVGUtEo=;
 b=ipIHuZhIM6ngp93qMdEN/VfjA2HdBObHH6HUqRhwg4SUWFYllaWDjnOeLn9MTAx/H80ZxbFBj
 Rz0/egPUCntAjI0rPNIdMIP91Xxt3dEevf97kNawoX1aj3XI4kBdu35
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add Amlogic Bluetooth entry to MAINTAINERS to clarify the maintainers

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 MAINTAINERS | 7 +++++++
 1 file changed, 7 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 0b73a6e2d78c..b106217933b2 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -1149,6 +1149,13 @@ S:	Supported
 F:	arch/arm64/boot/dts/amd/amd-seattle-xgbe*.dtsi
 F:	drivers/net/ethernet/amd/xgbe/
 
+AMLOGIC BLUETOOTH DRIVER
+M:	Yang Li <yang.li@amlogic.com>
+L:	linux-bluetooth@vger.kernel.org
+S:	Maintained
+F:	Documentation/devicetree/bindings/net/bluetooth/amlogic,w155s2-bt.yaml
+F:	drivers/bluetooth/hci_aml.c
+
 AMLOGIC DDR PMU DRIVER
 M:	Jiucheng Xu <jiucheng.xu@amlogic.com>
 L:	linux-amlogic@lists.infradead.org

-- 
2.42.0

