From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH v3 0/3] arm64: dts: hi3798cv200: fix GICR size, add cache
 info, maintenance irq and GICH, GICV spaces
Date: Mon, 19 Feb 2024 23:05:25 +0800
Message-Id: <20240219-cache-v3-0-a33c57534ae9@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIADVu02UC/22Myw6CMBBFf8XM2prOgDxc+R/GRRkGaVRqWmw0h
 H+3sNO4PDf3nAmCeCsBDpsJvEQbrBsSZNsNcG+GiyjbJgbSlGvCSrHhXhQiV01X7ouCCdL34aW
 zr7VzOifubRidf6/ZiMv6W4iotCLWpjJ5XpKUR/ccb85dd+zusDQi/fUoedi1NdZCTZvJtzfP8
 wc0A9KW1AAAAA==
To: Wei Xu <xuwei5@hisilicon.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, Alex Elder <elder@linaro.org>, 
 Peter Griffin <peter.griffin@linaro.org>
Cc: linux-arm-kernel@lists.infradead.org, devicetree@vger.kernel.org, 
 linux-kernel@vger.kernel.org, stable@vger.kernel.org, 
 Yang Xiwen <forbidden405@outlook.com>
X-Mailer: b4 0.12.4
X-Developer-Signature: v=1; a=ed25519-sha256; t=1708355220; l=1734;
 i=forbidden405@outlook.com; s=20230724; h=from:subject:message-id;
 bh=utfcqhg+6zII+yQBPRsJUw/zhNmlWQJxo5cBdL99Jgo=;
 b=2PQbYA0iF6C0vZng2DScPn60GvXq/i3yJXMaSQS9RqK0McpsKIIUTJEWHyebhP70eiowmjzyT
 ts1Cd5ksH14D6ALeqqux240ihttaargZG1Jx7lBJ7WdqYcjDbTAX6sQ
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=qOD5jhp891/Xzc+H/PZ8LWVSWE3O/XCQnAg+5vdU2IU=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230724 with auth_id=67
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The patchset fixes some warnings reported by the kernel during boot.

The cache size info is from Processor_Datasheet_v2XX.pdf [1], Section
2.2.1 Master Processor.

The cache line size and the set-associative info are from Cortex-A53
Documentation [2].

From the doc, it can be concluded that L1 i-cache is 4-way assoc, L1
d-cache is 2-way assoc and L2 cache is 16-way assoc. Calculate the dts
props accordingly.

Also, to use KVM's VGIC code, GICH, GICV registers spaces and maintenance
IRQ are added to the dts with verification.

[1]: https://github.com/96boards/documentation/blob/master/enterprise/poplar/hardware-docs/Processor_Datasheet_v2XX.pdf
[2]: https://developer.arm.com/documentation/ddi0500/j/Level-1-Memory-System

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v3:
- send patches to stable (Andrew Lunn)
- rewrite the commit logs more formally (Andrew Lunn)
- rename l2-cache0 to l2-cache (Krzysztof Kozlowski)
- Link to v2: https://lore.kernel.org/r/20240218-cache-v2-0-1fd919e2bd3e@outlook.com

Changes in v2:
- arm64: dts: hi3798cv200: add GICH, GICV register spces and
  maintainance IRQ.
- Link to v1: https://lore.kernel.org/r/20240218-cache-v1-0-2c0a8a4472e7@outlook.com

---
Yang Xiwen (3):
      arm64: dts: hi3798cv200: fix the size of GICR
      arm64: dts: hi3798cv200: add GICH, GICV register space and irq
      arm64: dts: hi3798cv200: add cache info

 arch/arm64/boot/dts/hisilicon/hi3798cv200.dtsi | 43 +++++++++++++++++++++++++-
 1 file changed, 42 insertions(+), 1 deletion(-)
---
base-commit: 8d3dea210042f54b952b481838c1e7dfc4ec751d
change-id: 20240218-cache-11c8bf7566c2

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

