From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v10 0/2] Add support for Loongson1 APB DMA
Date: Fri, 26 Jul 2024 21:06:48 +0800
Message-Id: <20240726-loongson1-dma-v10-0-31bf095a6fa6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGifo2YC/13OTU7DMBAF4KtUXuPIM67/WHEPxCK1J4lFEyO7R
 ECVu+N0AZGXM9L33ruzQjlSYc+nO8u0xhLTUg8QTyfmp34ZicdQHwwFSgAU/JrSMpa0AA9zz0H
 LfiBlhL04Vs1HpiF+PQJf3+o95DTz25Sp/0sRDi0gOCU7hWctLAf+TuNnLet+9sqXce7jtfNp3
 hOnWG4pfz8WrnrP3VPOQoJutqyaC+5EIPTS+9pyCNq3rOag0bXaVC1NuChbNwVSrbb/WgvTalv
 14JzDgMqgEq12Bw2y1a5qDRYG9CaQp6Petu0XRxnnsacBAAA=
To: Keguang Zhang <keguang.zhang@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 Conor Dooley <conor.dooley@microchip.com>, 
 Jiaxun Yang <jiaxun.yang@flygoat.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1721999250; l=3092;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=o2zx3o5hVHzdjVgk8ltvnYkXMU43duXbPFt5gvBbsu0=;
 b=T6wAI6PvcFTCfefJZNNBmUR4tLx2a1DrXnbf/80aDFRgQIvyjh438gbtDn8sSvUFJ37/vpbLh
 YNjMOHuEFnQA+xmq6Vkk0O1gZKsq/oO1u/u1DNwwQhGD0EdoiIHSRjF
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson1 APB DMA.

---
Changes in v10:
- Implement the hwdescs by link list to eliminate the limitation of the desc number.
- Add the prefix 'LS1X_' for all registers and their bits.
- Drop the macros: chan_readl() and chan_writel().
- Use %pad for printing a dma_addr_t type.
- Some minor fixes.
- Link to v9: https://lore.kernel.org/r/20240613-loongson1-dma-v9-0-6181f2c7dece@gmail.com

Changes in v9:
- Fix all the errors and warnings when building with W=1 and C=1
- Link to v8: https://lore.kernel.org/r/20240607-loongson1-dma-v8-0-f9992d257250@gmail.com

Changes in v8:
- Change 'interrupts' property to an items list
- Link to v7: https://lore.kernel.org/r/20240329-loongson1-dma-v7-0-37db58608de5@gmail.com

Changes in v7:
- Change the comptible to 'loongson,ls1*-apbdma' (suggested by Huacai Chen)
- Update the title and description part accordingly
- Rename the file to loongson,ls1b-apbdma.yaml
- Add a compatible string for LS1A
- Delete minItems of 'interrupts'
- Change patterns of 'interrupt-names' to const
- Rename the file to loongson1-apb-dma.c to keep the consistency
- Update Kconfig and Makefile accordingly
- Link to v6: https://lore.kernel.org/r/20240316-loongson1-dma-v6-0-90de2c3cc928@gmail.com

Changes in v6:
- Change the compatible to the fallback
- Implement .device_prep_dma_cyclic for Loongson1 sound driver,
  as well as .device_pause and .device_resume.
- Set the limitation LS1X_DMA_MAX_DESC and put all descriptors
  into one page to save memory
- Move dma_pool_zalloc() into ls1x_dma_alloc_desc()
- Drop dma_slave_config structure
- Use .remove_new instead of .remove
- Use KBUILD_MODNAME for the driver name
- Improve the debug information
- Some minor fixes

Changes in v5:
- Add the dt-binding document
- Add DT support
- Use DT information instead of platform data
- Use chan_id of struct dma_chan instead of own id
- Use of_dma_xlate_by_chan_id() instead of ls1x_dma_filter()
- Update the author information to my official name

Changes in v4:
- Use dma_slave_map to find the proper channel.
- Explicitly call devm_request_irq() and tasklet_kill().
- Fix namespace issue.
- Some minor fixes and cleanups.

Changes in v3:
- Rename ls1x_dma_filter_fn to ls1x_dma_filter.

Changes in v2:
- Change the config from 'DMA_LOONGSON1' to 'LOONGSON1_DMA',
- and rearrange it in alphabetical order in Kconfig and Makefile.
- Fix comment style.

---
Keguang Zhang (2):
      dt-bindings: dma: Add Loongson-1 APB DMA
      dmaengine: Loongson1: Add Loongson-1 APB DMA driver

 .../bindings/dma/loongson,ls1b-apbdma.yaml         |  67 ++
 drivers/dma/Kconfig                                |   9 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/loongson1-apb-dma.c                    | 675 +++++++++++++++++++++
 4 files changed, 752 insertions(+)
---
base-commit: 668d33c9ff922c4590c58754ab064aaf53c387dd
change-id: 20231120-loongson1-dma-163afe5708b9

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

