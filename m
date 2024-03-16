From: Keguang Zhang <keguang.zhang@gmail.com>
Subject: [PATCH v6 0/2] Add support for Loongson1 DMA
Date: Sat, 16 Mar 2024 19:33:52 +0800
Message-Id: <20240316-loongson1-dma-v6-0-90de2c3cc928@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKCD9WUC/z2NQQ6CMBAAv0L27JJukQqc/IfxUGFbGmlrWjVGw
 t+tHjzOYWZWyJwcZxiqFRI/XXYxFFC7CsZZB8vopsIghWyIpMAlxmBzDIST10iq0Ybbg+guPRT
 nlti41693Ohc2KXq8z4n1vyJ62ZGkvm3qVu6V6JDwyvZRZvX7uzxar91Sj9HDtn0AHlUeF6EAA
 AA=
To: Keguang Zhang <keguang.zhang@gmail.com>, Vinod Koul <vkoul@kernel.org>, 
 Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>
Cc: linux-mips@vger.kernel.org, dmaengine@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org
X-Mailer: b4 0.12.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1710588849; l=2457;
 i=keguang.zhang@gmail.com; s=20231129; h=from:subject:message-id;
 bh=4L4tGD1DKV+mZjgPQTvkjdRdWNUjXgMgRTBy+sDZ4xg=;
 b=p93Izz5hHhY6H2wDb31zXn4GqlnZAT04fm48vFU46D5x+W2hAJuZ7arhkDP9w1U14HnAr8S+d
 jxo/7SN/W01D1vWzFQJVw/LAcnoytJr8L3ue7qsMRIWH0kgx1a2WZdx
X-Developer-Key: i=keguang.zhang@gmail.com; a=ed25519;
 pk=FMKGj/JgKll/MgClpNZ3frIIogsh5e5r8CeW2mr+WLs=
X-Endpoint-Received: by B4 Relay for keguang.zhang@gmail.com/20231129 with auth_id=102
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add the driver and dt-binding document for Loongson1 DMA.

Changelog
V5 -> V6:
   Change the compatible to the fallback
   Implement .device_prep_dma_cyclic for Loongson1 sound driver,
   as well as .device_pause and .device_resume.
   Set the limitation LS1X_DMA_MAX_DESC and put all descriptors
   into one page to save memory
   Move dma_pool_zalloc() into ls1x_dma_alloc_desc()
   Drop dma_slave_config structure
   Use .remove_new instead of .remove
   Use KBUILD_MODNAME for the driver name
   Improve the debug information
   Some minor fixes
V4 -> V5:
   Add the dt-binding document
   Add DT support
   Use DT information instead of platform data
   Use chan_id of struct dma_chan instead of own id
   Use of_dma_xlate_by_chan_id() instead of ls1x_dma_filter()
   Update the author information to my official name
V3 -> V4:
   Use dma_slave_map to find the proper channel.
   Explicitly call devm_request_irq() and tasklet_kill().
   Fix namespace issue.
   Some minor fixes and cleanups.
V2 -> V3:
   Rename ls1x_dma_filter_fn to ls1x_dma_filter.
V1 -> V2:
   Change the config from 'DMA_LOONGSON1' to 'LOONGSON1_DMA',
   and rearrange it in alphabetical order in Kconfig and Makefile.
   Fix comment style.

Keguang Zhang (2):
  dt-bindings: dma: Add Loongson-1 DMA
  dmaengine: Loongson1: Add Loongson1 dmaengine driver

 .../bindings/dma/loongson,ls1x-dma.yaml       |  64 +++
 drivers/dma/Kconfig                           |   9 +
 drivers/dma/Makefile                          |   1 +
 drivers/dma/loongson1-dma.c                   | 492 ++++++++++++++++++
 4 files changed, 566 insertions(+)
 create mode 100644 Documentation/devicetree/bindings/dma/loongson,ls1x-dma.yaml
 create mode 100644 drivers/dma/loongson1-dma.c

--
2.39.2

base-commit: 719136e5c24768ebdf80b9daa53facebbdd377c3
---
Keguang Zhang (2):
      dt-bindings: dma: Add Loongson-1 DMA
      dmaengine: Loongson1: Add Loongson1 dmaengine driver

 .../devicetree/bindings/dma/loongson,ls1x-dma.yaml |  66 ++
 drivers/dma/Kconfig                                |   9 +
 drivers/dma/Makefile                               |   1 +
 drivers/dma/loongson1-dma.c                        | 665 +++++++++++++++++++++
 4 files changed, 741 insertions(+)
---
base-commit: a1e7655b77e3391b58ac28256789ea45b1685abb
change-id: 20231120-loongson1-dma-163afe5708b9

Best regards,
-- 
Keguang Zhang <keguang.zhang@gmail.com>

