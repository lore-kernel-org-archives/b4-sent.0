From: Yang Li <yang.li@amlogic.com>
Date: Fri, 05 Jul 2024 19:20:46 +0800
Subject: [PATCH 3/4] arm64: defconfig: Enable hci_uart for Amlogic
 Bluetooth
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20240705-btaml-v1-3-7f1538f98cef@amlogic.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1720178456; l=589;
 i=yang.li@amlogic.com; s=20240418; h=from:subject:message-id;
 bh=gUtmHVeZTKC9IsfZRX6YKmxxFnXVwUrODq8x21j2HNc=;
 b=ZTHCBJLeGcUBzvp+O9iojkqGknWSEpcghggMhH2YF6OXCj4JHqRHv5lo4cq9mhjUgSKVZ87+u
 3PLPKut2aVvC7NvTKzLnumqV1EmM5m20rJHjawpd8R3nurgt0odwj4U
X-Developer-Key: i=yang.li@amlogic.com; a=ed25519;
 pk=86OaNWMr3XECW9HGNhkJ4HdR2eYA5SEAegQ3td2UCCs=
X-Endpoint-Received: by B4 Relay for yang.li@amlogic.com/20240418 with auth_id=180
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the HCI protocol of Amlogitc Bluetooth.

Signed-off-by: Yang Li <yang.li@amlogic.com>
---
 arch/arm64/configs/defconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/configs/defconfig b/arch/arm64/configs/defconfig
index 57a9abe78ee4..11c4b5c532ca 100644
--- a/arch/arm64/configs/defconfig
+++ b/arch/arm64/configs/defconfig
@@ -192,6 +192,7 @@ CONFIG_BT_HCIUART_LL=y
 CONFIG_BT_HCIUART_BCM=y
 CONFIG_BT_HCIUART_QCA=y
 CONFIG_BT_HCIUART_MRVL=y
+CONFIG_BT_HCIUART_AML=y
 CONFIG_BT_MRVL=m
 CONFIG_BT_MRVL_SDIO=m
 CONFIG_BT_QCOMSMD=m

-- 
2.42.0

