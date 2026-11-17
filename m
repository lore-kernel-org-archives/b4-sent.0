From: Rui Cao <i@udp0.com>
Date: Tue, 17 Nov 2026 17:11:32 +0800
Subject: [PATCH v2 2/5] dt-bindings: watchdog: mediatek,mtk-wdt: Add MT6833
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261117-mt6833-base-v2-2-058a0685c40c@udp0.com>
References: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
In-Reply-To: <20261117-mt6833-base-v2-0-058a0685c40c@udp0.com>
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Sean Wang <sean.wang@mediatek.com>, 
 Wim Van Sebroeck <wim@linux-watchdog.org>, 
 Guenter Roeck <linux@roeck-us.net>, 
 Greg Kroah-Hartman <gregkh@linuxfoundation.org>, 
 Jiri Slaby <jirislaby@kernel.org>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 linux-watchdog@vger.kernel.org, linux-serial@vger.kernel.org, 
 phone-devel@vger.kernel.org, Roman Vivchar <rva333@protonmail.com>, 
 Rui Cao <i@udp0.com>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794906695; l=1098;
 i=i@udp0.com; s=20261107; h=from:subject:message-id;
 bh=jjCiaVOOht+RI3oDkxUaR1YbdSwCNgqgxnVxINfl9q8=;
 b=9g9D2itu8LsARvIWD5fHnn7cKiJ5isx3uDconLIYrEz7YNX9M/UaO365a15DHPzjWzin6dTNu
 DZmZImgXlCpAcN2Vn/scwDnZx8pOnzCjHOIz8kc7gqYD/GgVyArpBpA
X-Developer-Key: i=i@udp0.com; a=ed25519;
 pk=XZJKcKgnUUjjyw8KuKy7u2QeIX0JLY/L1Fxzwwje41w=
X-Endpoint-Received: by B4 Relay for i@udp0.com/20261107 with auth_id=1443
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add MediaTek's MT6833 (Dimensity 700) as a compatible of its own.

It can't fall back to mediatek,mt6589-wdt, which also describes
MT6589's twelve TOPRGU reset lines: MediaTek's kernel for MT6833 resets
the connectivity CPU through bit 12 of WDT_SWSYSRST, past them, and has
no full reset table for the SoC to take one from.

Signed-off-by: Rui Cao <i@udp0.com>
---
 Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml | 1 +
 1 file changed, 1 insertion(+)

diff --git a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
index f9b725592c2..5742cc09a74 100644
--- a/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
+++ b/Documentation/devicetree/bindings/watchdog/mediatek,mtk-wdt.yaml
@@ -24,6 +24,7 @@ properties:
           - mediatek,mt6589-wdt
           - mediatek,mt6735-wdt
           - mediatek,mt6795-wdt
+          - mediatek,mt6833-wdt
           - mediatek,mt7986-wdt
           - mediatek,mt7988-wdt
           - mediatek,mt8167-wdt

-- 
Git-157)

