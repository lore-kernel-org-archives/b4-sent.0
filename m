From: Congcong Yao <congcong.yao@mediatek.com>
Subject: [PATCH RESEND v3 0/2] memory: mtk-smi: add MT8189 SMI support
Date: Wed, 22 Jul 2026 20:02:42 +0800
Message-Id: <20260722-8189-smi-support-v3-0-ae00e13deeac@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGKxYGoC/3WNPQ+CMBRF/4p5szVt/WhxcpDVQUfDAO1DngZK2
 kI0hP8u4Ox4b849d4CAnjDAcTWAx54CuWYK2/UKTJU3D2RkpwySywNXUjItdMJCTSx0bet8ZCi
 lTRQiV6KAadZ6LOm9KO9wTW/p5QzZrw9d8UQTZ99MVhSi85/luxcL//+mF4yzYi91viutVtqca
 rSUR3xtjKshG8fxC6I+Cx7NAAAA
X-Change-ID: 20260722-8189-smi-support-e22d97ee071b
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Congcong Yao <congcong.yao@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784721998; l=1151;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=7xNjyyJHcIIbAta7PdSl/iTJSUHe53qhyhTm8L5BFTs=;
 b=/yVGxiVm7c2FmPvaazWIztBy3My9KyhM7cYO1UDfHIEDmzDJQ/bPMGCZwfwTJ/S/f9GmXlNv5
 EkECw5hf+gHB1gxrvgkg+gD4cJwU26G0jqenaHLd5OT3V1kGXNkXTb9
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on tag: next-20260629, linux-next/master

This patchset adds MT8189 SMI support.

The series updates the MediaTek SMI bindings for MT8189 and adds the
corresponding SMI common and larb support in the mtk-smi driver.

This is a resend of v3 because the previous submission was sent with the
wrong version number. No code changes.

Changes in v3:
- Change the minimum clock number of smi-sub-common to 3.
- Link to v2:
  https://lore.kernel.org/linux-mediatek/20260427070444.20247-1-zhengnan.chen@mediatek.com/

Signed-off-by: Congcong Yao <congcong.yao@mediatek.com>
---
Congcong Yao (2):
      memory: mtk-smi: Add mt8189 support
      dt-bindings: memory-controllers: mtk-smi: Add support for mt8189

 .../memory-controllers/mediatek,smi-common.yaml    | 18 +++++++++
 .../memory-controllers/mediatek,smi-larb.yaml      |  3 ++
 drivers/memory/mtk-smi.c                           | 44 ++++++++++++++++++++++
 3 files changed, 65 insertions(+)
---
base-commit: 290aaf24a551d5a0dce037e3fab30820f9113a10
change-id: 20260722-8189-smi-support-e22d97ee071b

Best regards,
--  
Congcong Yao <congcong.yao@mediatek.com>

