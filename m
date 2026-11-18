From: Arun Iyengar <aiyengar1990@gmail.com>
Date: Wed, 18 Nov 2026 03:55:58 +0000
Subject: [PATCH] arm64: dts: allwinner: orangepi-zero2: Read the SPI NOR
 over two lines
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261118-zero2-spi-nor-dual-read-v1-1-bcdcbf785be0@gmail.com>
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/0WNUQuCMBRG/4rsuRvbyBUS0f8IH+Z20xvpbHMSi
 f+9pUKPB77vnIkF9ISBFdnEPI4UyHUJxC5jptFdjUA2MZNcKiFEDh/0TkLoCTrnwUb9BI/agjr
 kWlmUOZ4ES+/e453ei/lWrhxi9UAz/HTbwuMrpuSwzliLIeglWWTnraiWVoidImhUwn9ylMABu
 VEKq6NAya91q+m5N669sHKevwbesJbdAAAA
X-Change-ID: 20261115-zero2-spi-nor-dual-read-645a6de25e81
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@kernel.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 Arun Iyengar <aiyengar1990@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794974157; l=1356;
 i=aiyengar1990@gmail.com; s=20261110; h=from:subject:message-id;
 bh=azsGory18NjrLZMbFK+fhx8bhUeiwb0w4jtTyXOp1s0=;
 b=m180m4A6WLT+kJyz23ClvGlYswZxgc9As93hAgp5fKtYXJeB/FchFqqzONmKShqEBxtX3Pvm7
 5EFnJiBr/UxAFBEGtfj77F7geCTkl7SG03XkW5QUEsvFcmgngCX6CKD
X-Developer-Key: i=aiyengar1990@gmail.com; a=ed25519;
 pk=zXpRgUTrhaFe6jLyPqbBy3ccfkj04w0g2690Wv3mg+0=
X-Endpoint-Received: by B4 Relay for aiyengar1990@gmail.com/20261110 with auth_id=1480
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

WP# and HOLD# are tied to VCC (schematic v1.3), so read over two lines.

Signed-off-by: Arun Iyengar <aiyengar1990@gmail.com>
---
Needs the spi-sun6i H616 dual read series v2 (prerequisite below).
Tested on an Orange Pi Zero2 with it: 1-1-2 reads (opcode 0x3b), 2 MiB in
0.28 s instead of 0.52 s, identical data.

Developed with Claude (Anthropic), which wrote the commit message. I
reviewed it.
---
 arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts | 1 +
 1 file changed, 1 insertion(+)

diff --git a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
index 90c25e12e189..fb117116002e 100644
--- a/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
+++ b/arch/arm64/boot/dts/allwinner/sun50i-h616-orangepi-zero2.dts
@@ -150,6 +150,7 @@ &pio {
 
 &spi0 {
 	flash@0 {
+		spi-rx-bus-width = <2>;
 		vcc-supply = <&reg_aldo1>;
 	};
 };

---
base-commit: a203a4bac3316451a3036653657c8b250dea2055
change-id: 20261115-zero2-spi-nor-dual-read-645a6de25e81
prerequisite-message-id: <20261116-spi-sun6i-h616-dual-read-v2-0-e0c66eb71e20@gmail.com>
prerequisite-patch-id: 28b145097d0f859e5bd27bcc5028d0915f3ba4bd
prerequisite-patch-id: fb47570beb53613acb42c518fd1999e05e0c54fb

Best regards,
--  
Arun Iyengar <aiyengar1990@gmail.com>

