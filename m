From: Congcong Yao <congcong.yao@mediatek.com>
Subject: [PATCH v4 0/2] memory: mtk-smi: add MT8189 SMI support
Date: Mon, 31 Aug 2026 14:52:05 +0800
Message-Id: <20260831-8189-smi-support-v4-0-8ae66dd3eeed@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJUklWoC/4XNQQ7CIBQE0Ks0rMUArZa68h7GBYVf+zUtDVCia
 Xp3oe5c6HKSmTcL8eAQPDkVC3EQ0aMdU6h2BdG9Gm9A0aRMBBNHVgtBJZcN9QNSP0+TdYGCEKa
 pAVjNW5Jmk4MOnxt5uX6yn9s76JCd3OjRB+te22fkufeDj5wy2h6EVFVnZC31eQCDKsBjr+1A8
 kMs/xllMhQwBrw0AOrbWNf1DcHqXSIJAQAA
X-Change-ID: 20260722-8189-smi-support-e22d97ee071b
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Congcong Yao <congcong.yao@mediatek.com>, 
 Zhengnan Chen <zhengnan.chen@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788159129; l=1583;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=M4GaH724wA8/jL/JVMY3JZf+txqUy8LN1XX/SsZ6CeY=;
 b=7Z7F4ncrh+nSJLgO2w4wgXT/3iMtdH4W9EGckso+B7zDd7Mx5m9/fQgkpYqyaHER205awJigg
 g+0LnP0R8QFBRsEWnr/uNTpCuB59giT8SloQtMQdRHAHddKpx35vZ6a
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This patchset adds MT8189 SMI support.

The series updates the MediaTek SMI bindings for MT8189 and adds the
corresponding SMI common and LARB support in the mtk-smi driver.

Based on commit e30626823a40 ("Add linux-next specific files for 20260828")

Changes in v4:
- Rebase onto next-20260828.
- Add MT8189 SMI common, sub-common and LARB binding compatibles.
- Place the DT binding update before the driver update.
- Drop Reviewed-by tags from AngeloGioacchino Del Regno and Yong Wu
  because the patches changed materially.
- Update the MT8189 LARB OSTD settings to avoid zero values terminating
  the existing Gen2 configuration loop.
- Link to v3:
  https://lore.kernel.org/all/20260722-8189-smi-support-v3-0-ae00e13deeac@mediatek.com/

Changes in v3:
- Change the minimum clock number of smi-sub-common to 3.
- Link to v2:
  https://lore.kernel.org/linux-mediatek/20260427070444.20247-1-zhengnan.chen@mediatek.com/

Signed-off-by: Congcong Yao <congcong.yao@mediatek.com>
---
Zhengnan Chen (2):
      dt-bindings: memory-controllers: mtk-smi: Add support for mt8189
      memory: mtk-smi: Add MT8189 support

 .../memory-controllers/mediatek,smi-common.yaml    | 21 +++++++++-
 .../memory-controllers/mediatek,smi-larb.yaml      |  3 ++
 drivers/memory/mtk-smi.c                           | 45 ++++++++++++++++++++++
 3 files changed, 68 insertions(+), 1 deletion(-)
---
base-commit: e30626823a406725ce29bc75cb8ec467d3e1e326
change-id: 20260722-8189-smi-support-e22d97ee071b

Best regards,
--  
Congcong Yao <congcong.yao@mediatek.com>

