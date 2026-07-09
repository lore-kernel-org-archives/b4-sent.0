From: Roman Vivchar <rva333@protonmail.com>
Subject: [PATCH v2 0/2] ARM: dts: mediatek: mt6572 DT cleanup + cache info
Date: Thu, 09 Jul 2026 17:30:26 +0300
Message-Id: <20260709-6572-phase1-v2-0-1fd4a69542ab@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6DIBAFf8XsuTRAFNOe+h/Gg+BSt6lCgJI2x
 n8v2muPk8ybt0LEQBjhWq0QMFMktxSQpwrMNCx3ZDQWBsml4i2vmWpayfw0RBSMi3psGqFtayW
 UhQ9o6X3Uuv7H8aUfaNKe2I2JYnLhc9xlsXv/y7nEmRJGWlQaxcXcfHDJLfNAz7NxM/Tbtn0Bg
 HKFEr0AAAA=
X-Change-ID: 20260704-6572-phase1-014d551bf7f2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1783607435; l=1253;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=3EkOIMI6jj6hJQY/9ED/95LEd8x3WAPGI9Ft97GDTk4=;
 b=LKMabow2Jen0vPcytxu5qSnJxh2GRgF0zsahhxMcquYC1MlSe7Z3JzA7ZLx1jLTcgtg1ESyS8
 3SXZe/GGgQvAPHY2x3S+OY3kqTskhpZl8XTDi67mtn0Lg9wh7OZv4qD
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series replaces legacy clock naming like uart_clk, system_clk and
rtc_clk with clk-*FREQ* equivalents. It also adds L1 and L2 cache info
to properly describe hardware.

Note that patch 1 doesn't break DT ABI. The changed clock node names
and labels are consumed only by phandles, and there are no drivers
relying on the legacy names.

As a brief heads-up, this series is a small part of an ongoing effort
to upstream mt6572 support. In my kernel tree, I have brought up clocks,
pinctrl, eMMC/microSD, cpufreq, thermal, DRM, GPU and more. I plan to
send those series in the near future.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
Changes in v2:
- Fix I-cache line size and sets (oops...).
- Link to v1: https://patch.msgid.link/20260704-6572-phase1-v1-0-61c2fe6be19c@protonmail.com

---
Roman Vivchar (2):
      ARM: dts: mediatek: mt6572: rename fixed clocks
      ARM: dts: mediatek: mt6572: add cache data

 arch/arm/boot/dts/mediatek/mt6572.dtsi | 35 ++++++++++++++++++++++++++++------
 1 file changed, 29 insertions(+), 6 deletions(-)
---
base-commit: 8cd9520d35a6c38db6567e97dd93b1f11f185dc6
change-id: 20260704-6572-phase1-014d551bf7f2

Best regards,
--  
Roman Vivchar <rva333@protonmail.com>

