From: Igor Velkov <iav@iav.lv>
Date: Wed, 30 Sep 2026 16:52:15 +0000
Subject: [PATCH 2/2] arm64: dts: amlogic: meson-sm1-odroid-hc4: run the SPI
 NOR at 40 MHz
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260930-hc4-spi-nor-v1-2-9a3351e2984e@iav.lv>
References: <20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv>
In-Reply-To: <20260930-hc4-spi-nor-v1-0-9a3351e2984e@iav.lv>
To: Neil Armstrong <neil.armstrong@linaro.org>, 
 Kevin Hilman <khilman@baylibre.com>, Jerome Brunet <jbrunet@baylibre.com>, 
 Martin Blumenstingl <martin.blumenstingl@googlemail.com>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Christian Hewitt <christianshewitt@gmail.com>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-amlogic@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1395; i=iav@iav.lv;
 h=from:subject:message-id; bh=EpGmYpLlMviVEwXG8x1TChGxSFfpKyMpVV1+YR4B4L0=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFl77RwN7TTrC1x5sp0jGAySzj6IuL8++L9j51HN4mebL
 dffPMLSUcrCIMbFICumyDLhkMatjCVX//p7mD+AmcPKBDKEgYtTACZSfojhf26vZp+N08/3J6ea
 mM6a5NhaxmwYmqr+Yu+zNctWLzS+U8fwz+7+31+tU4/uPjcne4p3tcAhr8PauWK30/wkUp1V3to
 t5AAA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

At 104 MHz, reads return corrupted data: bit 0 of the first byte of a
transfer flips from 0 to 1 part of the time. The same byte read as the
second byte of a transfer was correct in all 100 reads. One 4 KiB block
read 200 times came back wrong 157 times. Writes are unaffected.

flashcp verifies while it writes, so a bootloader update erases blocks
it should skip and can abort halfway, with the flash half written.

The Hardkernel vendor device tree for this board uses 40 MHz. At 40 MHz
the same tests pass: 200 block reads with no mismatch, and 14 flashcp
runs with no block erased.

Tested on ODROID-HC4 with an XT25F128B.

Fixes: 7178f340e929 ("arm64: dts: meson-sm1-odroid-hc4: add spifc node to ODROID-HC4")
Assisted-by: LLM
Signed-off-by: Igor Velkov <iav@iav.lv>
---
 arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts | 2 +-
 1 file changed, 1 insertion(+), 1 deletion(-)

diff --git a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
index 5ce76a1bfe02..8f09f2b74bdd 100644
--- a/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
+++ b/arch/arm64/boot/dts/amlogic/meson-sm1-odroid-hc4.dts
@@ -144,7 +144,7 @@ flash@0 {
 		#size-cells = <1>;
 		compatible = "jedec,spi-nor";
 		reg = <0>;
-		spi-max-frequency = <104000000>;
+		spi-max-frequency = <40000000>;
 	};
 };
 

-- 
2.43.0

