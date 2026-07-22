From: Congcong Yao <congcong.yao@mediatek.com>
Subject: [PATCH RESEND 0/2] memory: mtk-smi: add MT8189 SMI support
Date: Wed, 22 Jul 2026 17:21:56 +0800
Message-Id: <20260722-8189-smi-support-v1-0-b528a4fd878c@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIALSLYGoC/yWMsQ6CQBAFf4W82k3utvDAWloLLI2FwKprIlxuw
 ZgQ/t1Ty5lkZoFJUjHsigVJXmo6Dhn8pkB3vww3Ie0zgx1vXWCm0pcV2VPJ5hjHNJEw91UQccG
 3yFlMctX3b3lCUx/rwx7nv7e5fUg3fX9Y1w89l6RQfAAAAA==
X-Change-ID: 20260722-8189-smi-support-e22d97ee071b
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 Congcong Yao <congcong.yao@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1784712201; l=1079;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=ddUZNX1kLnF7qdIKL+YEYld57GJfWQPqXwNv5z4AkBo=;
 b=NWyWkGdp1PDyU5YCv8inrzIpaJTChYNnYiEmaEbgOWJN+uvpbI6lmPuq4TvJfF7cNJjgK3z4s
 vR3RvBYBMQfDuxwS7/N9XR++02MkwwVpGX633bQ4seBVfUEpvbQkR2h
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on tag: next-20260629, linux-next/master

This patchset adds MT8189 SMI support.

The series updates the MediaTek SMI bindings for MT8189 and adds the
corresponding SMI common and larb support in the mtk-smi driver.

This is a resend of v3. No code changes.

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

