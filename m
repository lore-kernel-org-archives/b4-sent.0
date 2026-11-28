From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org
Cc: rva333@protonmail.com, amergnat@baylibre.com, me@adomerle.pw, 
 devicetree@vger.kernel.org, linux-mediatek@lists.infradead.org, 
 linux-arm-kernel@lists.infradead.org, phone-devel@vger.kernel.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v5 0/3] soc: mediatek: pwrap: Add MT6789 support
Date: Sat, 28 Nov 2026 04:36:29 +0000
Message-Id: <20261128043629.67417-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795840589; l=1370;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=M3zFXLBGQlmXviuDhtRSayyWoir9sMjZ4AHGCQ5FGYo=;
 b=nTBsL0eBkEhX9Ai6E73QBe9P1mZ2pYlG1y4P6k//RrP+7H9QLh+8I4E2EkzghMdTE4qy+MNJY
 X9h+AhJw2dODbP/PJDnkE2H4g9gL5dfVp3819rrvkGt1guyiTfrvbDH
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the MediaTek MT6789 (Helio G99/G99+/G100/G200,
MT8781) PMIC wrapper support originally posted by Arseniy Velikanov (on CC):
- pwrap v1: https://lore.kernel.org/linux-mediatek/20250715225746.1321-1-me@adomerle.pw/
- v3: https://lore.kernel.org/r/20261126031001.27288-1-iasnezhkov@gmail.com
- v4: https://lore.kernel.org/r/20261127030009.10572-1-iasnezhkov@gmail.com

Original authorship and Signed-off-by are preserved on patches 1 and 3.

Changes since v4:
- Rebased onto linux-next (resolving conflicts with mt6572 support and
  the dev_err_probe() conversion in pwrap_probe(), per Roman Vivchar).
- Collected Reviewed-by from Roman Vivchar on patch 1/3.
- Clarified PMIF bank 3 INT_FLG/INT_CLR (0x458/0x45C) provenance in
  patch 3/3 commit message.
- Added phone-devel@vger.kernel.org to Cc.

The v3-v5 rebases and arbiter fix were prepared with an AI coding assistant.

Arseniy Velikanov (2):
  dt-bindings: soc: mediatek: pwrap: Add compatible for MT6789
  soc: mediatek: mtk-pmic-pwrap: Add MT6789 support

Ilia Snezhkov (1):
  soc: mediatek: mtk-pmic-pwrap: Skip WDT source and init on arbiter
    SoCs

 .../bindings/soc/mediatek/mediatek,pwrap.yaml |  1 +
 drivers/soc/mediatek/mtk-pmic-wrap.c          | 50 +++++++++++++++----
 2 files changed, 42 insertions(+), 9 deletions(-)

-- 
2.54.0 (Apple Git-157)


