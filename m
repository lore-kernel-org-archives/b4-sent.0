From: =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
Subject: [PATCH 0/2] Add port@5 as CPU port on certain MT7622 and MT7986
 boards
Date: Mon, 19 Feb 2024 12:36:12 +0300
Message-Id: <20240219-for-mediatek-v1-0-7078f23eab82@arinc9.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-B4-Tracking: v=1; b=H4sIAAwh02UC/x3MQQqAIBBA0avIrBNUJLCrRAvLsYZIY4wIpLsnL
 d/i/woFmbDAICow3lQopwbdCVg2n1aUFJrBKGOV0U7GzPLAQP7CXfbOea3UjMFZaMnJGOn5d+P
 0vh8YuMC9XgAAAA==
To: Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: erkin.bozoglu@xeront.com, mithat.guner@xeront.com, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 =?utf-8?q?Ar=C4=B1n=C3=A7_=C3=9CNAL?= <arinc.unal@arinc9.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708335384; l=788;
 i=arinc.unal@arinc9.com; s=arinc9-patatt; h=from:subject:message-id;
 bh=uIeslGUrMiIxBs3Hoekn0ZFqBZXLWeLXlSxJlmij2aA=;
 b=9uiTEjuJ0SLjCwgUYlLom+wD/ujYeEnWm/KJsVTE+Bh7pTohkdiTPePxKWgDoJVTjX+EIy7Z0
 bSBrioBNM6ZDlzzUI3u2/EnJYuC7kcnws6qJWI68ukjjY8GKNzaoiDn
X-Developer-Key: i=arinc.unal@arinc9.com; a=ed25519;
 pk=VmvgMWwm73yVIrlyJYvGtnXkQJy9CvbaeEqPQO9Z4kA=
X-Endpoint-Received: by B4 Relay for arinc.unal@arinc9.com/arinc9-patatt with auth_id=115
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi.

This patch series adds port@5 as CPU port on certain MT7622 and MT7986
boards.

Signed-off-by: Arınç ÜNAL <arinc.unal@arinc9.com>
---
Arınç ÜNAL (2):
      arm64: dts: mt7622: add port@5 as CPU port
      arm64: dts: mt7986: add port@5 as CPU port

 .../boot/dts/mediatek/mt7622-bananapi-bpi-r64.dts  | 12 +++++++++++
 arch/arm64/boot/dts/mediatek/mt7622-rfb1.dts       | 24 ++++++++++++++++++++++
 arch/arm64/boot/dts/mediatek/mt7986a-rfb.dts       | 24 ++++++++++++++++++++++
 arch/arm64/boot/dts/mediatek/mt7986b-rfb.dts       | 24 ++++++++++++++++++++++
 4 files changed, 84 insertions(+)
---
base-commit: 5b6df373ec95cf051264f655be0dbe1d6caa173c
change-id: 20240219-for-mediatek-699a100bed94

Best regards,
-- 
Arınç ÜNAL <arinc.unal@arinc9.com>

