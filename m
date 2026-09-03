From: Xianwei Zhao <xianwei.zhao@amlogic.com>
Subject: [PATCH v12 0/3] Add Amlogic general DMA
Date: Thu, 03 Sep 2026 07:38:27 +0000
Message-Id: <20260903-amlogic-dma-v12-0-f769bc344056@amlogic.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPQjmWoC/23SzU7DMAwH8FdBPVMUO86HOfEeiEOauFsltqIWV
 aBp7046MbVNd4yj39+OlUs1ytDJWL0+XapBpm7s+nM+AD4/VfEYzgepu5QLFSo0gGDqcPrsD12
 s0ynUjsm5ZGJCS1UWX4O03c8t7v0jn4/d+N0Pv7f0CebqPcduciaoVS3oWYwTtsG9/d++xP5Uz
 UkT3rVVgG6rMWsyaJJGlxylvdaLRlX01lkb2zbcGpaEuNe00mVvyrpFI2SBhJsHk5tFa0VbbbI
 OgYxOQG0ivdd2rXmrbdZWa+KEuknU7LVbaSx6u3ly3zCIAGOEvfaLNghb7bP2NkaMwgT0YGu8a
 IvFznneufHJOowU2Ow1qIU7UMV3UfPsLSUJ4rWTB1sHWPvi6TD/tySOI2om9MX01+v1D1nUWlo
 ZAwAA
X-Change-ID: 20251215-amlogic-dma-79477d5cd264
To: Vinod Koul <vkoul@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Kees Cook <kees@kernel.org>, 
 "Gustavo A. R. Silva" <gustavoars@kernel.org>, 
 Frank Li <Frank.Li@kernel.org>
Cc: linux-amlogic@lists.infradead.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-hardening@vger.kernel.org, Xianwei Zhao <xianwei.zhao@amlogic.com>, 
 Krzysztof Kozlowski <krzysztof.kozlowski@oss.qualcomm.com>, 
 Frank Li <Frank.Li@nxp.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788421111; l=3676;
 i=xianwei.zhao@amlogic.com; s=20251216; h=from:subject:message-id;
 bh=/PsXy4EqiEqfiQEwDz+wINSsCBL8sXDWpm7+CjYgc4k=;
 b=Q00xKoZ6eLMDiuVNVDQsvidBGSTrthNIB7Y5mIi5qorDJUS6tf/12zWXDPUifjk+LnL7dFe1h
 zvcpJQBgl4VCtyEalqH3fo/GDN8tECdaPaRgkWhuOE7EtVo+lHelUoB
X-Developer-Key: i=xianwei.zhao@amlogic.com; a=ed25519;
 pk=dWwxtWCxC6FHRurOmxEtr34SuBYU+WJowV/ZmRJ7H+k=
X-Endpoint-Received: by B4 Relay for xianwei.zhao@amlogic.com/20251216 with auth_id=578
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add DMA driver and bindigns for the Amlogic SoCs.

Signed-off-by: Xianwei Zhao <xianwei.zhao@amlogic.com>
---
Changes in v12:
- Add prefix "AMLOGIG_A9_" for channel type.
- Use workqueue to free,and when remove module,destory queue.
- Consider the little-endian for hardware.
- Modify get dma status return value. 
- Optimize the code according to Vinod's suggestion.
- Link to v11: https://lore.kernel.org/r/20260714-amlogic-dma-v11-0-de79c2394282@amlogic.com

Changes in v11:
- MAX_DMA_LEN 4-byte align, and return real status when get, and lockless error print.
- Link to v10: https://lore.kernel.org/r/20260710-amlogic-dma-v10-0-ff4deae837e7@amlogic.com

Changes in v10:
- Free dma memory in workqueue.
- Deal with zero len sg (not consume sg_link),and reset status to DMA_COMPLETE when terminal channel.
- Add desc for #dma-cells in dt-bindings.
- Link to v9: https://lore.kernel.org/r/20260626-amlogic-dma-v9-0-558d672c4a95@amlogic.com

Changes in v9:
- Use each transmission request sg_link mem instead of the loop mem get.
- Fix some hidden issues which reviewed by ai robot.
- Link to v8: https://lore.kernel.org/r/20260521-amlogic-dma-v8-0-86cc2ce94142@amlogic.com

Changes in v8:
- Use kzalloc instead of kmalloc.
- Initialize the temporary variable and fix a spelling mistake.
- Link to v7: https://lore.kernel.org/r/20260324-amlogic-dma-v7-0-f8b91ee192c1@amlogic.com

Changes in v7:
- Take use vchan to support mltiple txns.
- Link to v6: https://lore.kernel.org/r/20260309-amlogic-dma-v6-0-63349d23bd4b@amlogic.com

Changes in v6:
- Some minor modifications according to Frank's suggestion.
- Link to v5: https://lore.kernel.org/r/20260304-amlogic-dma-v5-0-aa453d14fd43@amlogic.com

Changes in v5:
- Rename head file and rename macro definition.
- Rename the subject in [2/3] from "dma" to "dmaengine".
- Link to v4: https://lore.kernel.org/r/20260227-amlogic-dma-v4-0-f25e4614e9b7@amlogic.com

Changes in v4:
- Support split transfer when data len > MAX_LEN.
- When a module fails or exits, perform de-initialization.
- Some other minor modifications.
- Link to v3: https://lore.kernel.org/r/20260206-amlogic-dma-v3-0-56fb9f59ed22@amlogic.com

Changes in v3:
- Adjust the format of binding according to Frank's suggestion.
- Some code format modified according to Frank's suggestion.
- Support one prep_sg and one submit, drop multi prep_sg and one submit.
- Keep pre state when resume from pause status.
- Link to v2: https://lore.kernel.org/r/20260127-amlogic-dma-v2-0-4525d327d74d@amlogic.com

Changes in v2:
- Introduce what the DMA is used for in the A9 SoC.
- Some minor modifications were made according to Krzysztof's suggestions.
- Some modifications were made according to Neil's suggestions.
- Fix a build error.
- Link to v1: https://lore.kernel.org/r/20251216-amlogic-dma-v1-0-e289e57e96a7@amlogic.com

---
Xianwei Zhao (3):
      dt-bindings: dma: Add Amlogic A9 SoC DMA
      dmaengine: amlogic: Add general DMA driver for A9
      MAINTAINERS: Add an entry for Amlogic DMA driver

 .../devicetree/bindings/dma/amlogic,a9-dma.yaml    |  68 ++
 MAINTAINERS                                        |   7 +
 drivers/dma/Kconfig                                |  10 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/amlogic-dma.c                          | 737 +++++++++++++++++++++
 include/dt-bindings/dma/amlogic,a9-dma.h           |   8 +
 6 files changed, 831 insertions(+)
---
base-commit: bea91d748771879c695b869a6c5a4a172cb0035f
change-id: 20251215-amlogic-dma-79477d5cd264

Best regards,
-- 
Xianwei Zhao <xianwei.zhao@amlogic.com>

