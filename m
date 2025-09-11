From: =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
Subject: [PATCH v3 0/3] Audio and other peripherals on Orange Pi Zero
Date: Thu, 11 Sep 2025 22:23:54 +0200
Message-Id: <20250911-opz-audio-v3-0-9dfd317a8163@posteo.net>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIANovw2gC/1WMwQ6CMBAFf4X07Jq2tLJ48j+MBwqL9EJJWxuV8
 O8WEiMe5+XNzCyQtxTYuZiZp2SDdWOG8lCwdmjGO4HtMjPJpeZKVOCmNzSPzjrAmqOqWzRGEsv
 /yVNvn1vress82BCdf23pJNb1W8FdJQkQoAhPxmjTVqW6TC5EcseRIlszSf5U5PVelcChV30nt
 NayQfmnLsvyAewWE7DeAAAA
X-Change-ID: 20250417-opz-audio-890849c8bb2e
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Chen-Yu Tsai <wens@csie.org>, 
 Jernej Skrabec <jernej.skrabec@gmail.com>, 
 Samuel Holland <samuel@sholland.org>
Cc: devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-sunxi@lists.linux.dev, linux-kernel@vger.kernel.org, 
 =?utf-8?q?J=2E_Neusch=C3=A4fer?= <j.ne@posteo.net>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1757622235; l=1167;
 i=j.ne@posteo.net; s=20240329; h=from:subject:message-id;
 bh=EbMD20lOlZxBydAK7zCQataQpHJmiIQr5rbqpG7Zzpc=;
 b=wrDUZIaMhF3qOeFIsCo2Hiqq6KZy/a7n1QcgKTmhRJX9sBv2YeeyfbFOsg1KkbXU4p7XXCuuU
 /H5tiRvvRcXB2dd2l6Syk5t8My1EdZRf2a9hUdq3dBNHUuRh8m4r6LV
X-Developer-Key: i=j.ne@posteo.net; a=ed25519;
 pk=NIe0bK42wNaX/C4bi6ezm7NJK0IQE+8MKBm7igFMIS4=
X-Endpoint-Received: by B4 Relay for j.ne@posteo.net/20240329 with auth_id=156
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: J. Neuschäfer <j.ne@posteo.net>
---
Changes in v3:
- Fix name of orangepi-zero-plus2 in patch title
- Link to v2: https://lore.kernel.org/r/20250809-opz-audio-v2-0-f4fd15552a82@posteo.net

Changes in v2:
- Rebase on (almost) 6.17-rc1
- Disable audio pins by default
- Provide separate DT overlay for the Orange Pi Zero Interface Board
- Link to v1: https://lore.kernel.org/r/20250418-opz-audio-v1-1-4e86bb5bc734@posteo.net

---
J. Neuschäfer (3):
      ARM: dts: allwinner: orangepi-zero: Add default audio routing
      ARM: dts: allwinner: orangepi-zero-plus2: Add default audio routing
      ARM: dts: allwinner: Add Orange Pi Zero Interface Board overlay

 arch/arm/boot/dts/allwinner/Makefile               |  7 ++++
 .../dts/allwinner/sun8i-h2-plus-orangepi-zero.dts  | 14 +++++++
 .../dts/allwinner/sun8i-h3-orangepi-zero-plus2.dts | 14 +++++++
 .../sun8i-orangepi-zero-interface-board.dtso       | 46 ++++++++++++++++++++++
 4 files changed, 81 insertions(+)
---
base-commit: 29fdda97f8d5797b160aa8ad1c7248710bb8ffda
change-id: 20250417-opz-audio-890849c8bb2e

Best regards,
-- 
J. Neuschäfer <j.ne@posteo.net>

