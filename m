From: Yang Xiwen <forbidden405@outlook.com>
Date: Sat, 31 May 2025 21:10:03 +0800
Subject: [PATCH 2/2] arm: qemu: Add imply CONFIG_POSITION_INDEPENDENT
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20250531-pie_blob_fix-v1-2-7b4a37987dbc@outlook.com>
References: <20250531-pie_blob_fix-v1-0-7b4a37987dbc@outlook.com>
In-Reply-To: <20250531-pie_blob_fix-v1-0-7b4a37987dbc@outlook.com>
To: Tom Rini <trini@konsulko.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Raymond Mao <raymond.mao@linaro.org>, 
 Rayagonda Kokatanur <rayagonda.kokatanur@broadcom.com>
Cc: u-boot@lists.denx.de, Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1748697019; l=834;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=tmfpcKi7hSRAY+ZRTdHYSRSCz90BoQaXCuM3tnV10mM=;
 b=bslIUZLubvHfstdqGLkBVv0YZM9ELaZDqmAcUZghxEfADLEKlamBa9K4fzMcjSk9kSZOmuuDY
 VoTrLKGBUX2Aa33klr7f//foJGRqrxr4hSSEq94L46pIkX6REl5FvkI
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add 'imply CONFIG_POSITION_INDEPENTDENT' for QEMU arm arch. This allows
qemu arm boards to load u-boot.bin at any address. It is skipped by
default when u-boot is loaded by either --bios or --kernel.

To load u-boot.bin at a different address, one can use u-boot
chain-loading or qemu loader device[1].

[1] https://www.qemu.org/docs/master/system/generic-loader.html

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
 arch/arm/Kconfig | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm/Kconfig b/arch/arm/Kconfig
index 79f60eb3f349..6ff3f2750ea8 100644
--- a/arch/arm/Kconfig
+++ b/arch/arm/Kconfig
@@ -1091,6 +1091,7 @@ config ARCH_QEMU
 	imply USB_XHCI_PCI
 	imply USB_KEYBOARD
 	imply CMD_USB
+	imply POSITION_INDEPENDENT
 
 config ARCH_RENESAS
 	bool "Renesas ARM SoCs"

-- 
2.43.0

