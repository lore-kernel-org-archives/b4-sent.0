From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: matthias.bgg@gmail.com, angelogioacchino.delregno@collabora.com, 
 robh@kernel.org, krzk+dt@kernel.org, conor+dt@kernel.org
Cc: amergnat@baylibre.com, me@adomerle.pw, 
 Roman Vivchar <rva333@protonmail.com>, devicetree@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v4 0/3] soc: mediatek: pwrap: Add MT6789 support
Date: Fri, 27 Nov 2026 03:00:09 +0000
Message-Id: <20261127030009.10572-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795748409; l=1101;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=YvdzdmSvb+O0Tz8QIZiIDOVYHG627P6PfzDQt/Lq8Qg=;
 b=6ol1S4ut2o32IYsWppY97ebccrQQdihnqY7cQQMQ8JdejL4H5wJdiPHLSvNOUN8CCy9Vq1Tk6
 0N4L6GYMyQTDB+Q5Achp3Bh8N9SBikFzrk2bdEvG0gWLoxIIcQ5DUct
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series continues the MediaTek MT6789 (Helio G99) PMIC wrapper
support originally posted by Arseniy Velikanov (on CC):
- pwrap v1: https://lore.kernel.org/linux-mediatek/20250715225746.1321-1-me@adomerle.pw/
- v3: https://lore.kernel.org/r/20261126031001.27288-1-iasnezhkov@gmail.com

Original authorship and Signed-off-by are preserved on patches 1 and 3.

Changes since v3:
- Split the unrelated spi-mt65xx binding patch out into its own
  standalone submission (suggested by Roman Vivchar).
- Add sender Signed-off-by on rebased patches 1 and 3.

The v3/v4 rebase and arbiter fix were prepared with an AI coding assistant.

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


