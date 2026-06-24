From: Ricardo Pardini <ricardo@pardini.net>
Date: Wed, 24 Jun 2026 17:45:53 +0200
Subject: [PATCH v2 1/2] arm64: dts: mediatek: mt8395-radxa-nio-12l: Drop
 redundant i2c2 drive-strength
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260624-nio-12l-add-i2c-40-pin-v2-1-cf3707a6aaf1@pardini.net>
References: <20260624-nio-12l-add-i2c-40-pin-v2-0-cf3707a6aaf1@pardini.net>
In-Reply-To: <20260624-nio-12l-add-i2c-40-pin-v2-0-cf3707a6aaf1@pardini.net>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Ricardo Pardini <ricardo@pardini.net>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1206; i=ricardo@pardini.net;
 h=from:subject:message-id; bh=m5Cx5Z1IWJ++CWhQ3mc1twTHRBYJFzAA/qKlYFYZhuo=;
 b=owGbwMvMwMFoHWf/eN7xty8ZT6slMWRZ/97sedvCKo+7fEqerwwrv/y/74Kpf9LvCH5jtBLrf
 TlRQ1G2k9GfhYGRg8FSTJFljYQyz7f1r07d8eiYDDOIlQlkirRIAwMQsDDw5SbmlRrpGOmZahvq
 GRrpGOgYM3BxCsBUF1Wz/5UT4fJ//z+5RmDX9y9Lxe6xd7jsqgg74CyyLfDv5ylaiVc7cj7l+17
 s5BHST/nfK7Hnr9/Fxls+F5f5V07unKFkGruGbWqS2aHl+9Z4KQg+dmCo2FdWGHZq0qU5rBKfN3
 rlnym4pWBjHrldYaJWiqTr7VWZtwNuZASpTr3RzmZrKuHkrjHdwezHpg67pj3GF/ezRj181i3EJ
 3TnQaLl5oLTVTc7n7A/Tn7lzOn2yWtyyfFzMx/yaAT/sLaevWDxg/VvbS0n9/NOKtxux3pt95XZ
 3+LzD9dG7vQuNam576un5iYWdnG/5v60ekPnhTbnm2TfiQjeeh6qJ/HyQLksz6XWBdOfdCqa2r2
 fXXZNBwA=
X-Developer-Key: i=ricardo@pardini.net; a=openpgp;
 fpr=AC18230CF6AFEACADC4888933B5E3FE39EC7EDE9
X-Endpoint-Received: by B4 Relay for ricardo@pardini.net/default with auth_id=588
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The i2c2_pins node specifies both drive-strength (mA, standard driving)
and drive-strength-microamp (uA, advanced driving). These are mutually
exclusive: the generic pinconf parser logs "cannot have multiple drive
strength properties" at boot, and on MediaTek the advanced driving enable
bit makes the uA value authoritative, leaving the mA value dead.

Drop the redundant drive-strength, keeping only drive-strength-microamp,
matching i2c4_pins.

Signed-off-by: Ricardo Pardini <ricardo@pardini.net>
Assisted-by: Claude:claude-opus-4-8 # vs Sashiko review of upcoming i2c3
---
 arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts | 1 -
 1 file changed, 1 deletion(-)

diff --git a/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts b/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
index bf91305e8e4a5..589a5f07d5dde 100644
--- a/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
+++ b/arch/arm64/boot/dts/mediatek/mt8395-radxa-nio-12l.dts
@@ -784,7 +784,6 @@ pins-bus {
 			pinmux = <PINMUX_GPIO12__FUNC_SDA2>,
 				 <PINMUX_GPIO13__FUNC_SCL2>;
 			bias-pull-up = <1000>;
-			drive-strength = <6>;
 			drive-strength-microamp = <1000>;
 		};
 	};

-- 
2.54.0

