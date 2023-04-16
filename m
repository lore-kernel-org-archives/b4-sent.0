From: Yang Xiwen <forbidden405@outlook.com>
Subject: [PATCH RFC v4 0/4] mmc: add support for the dw-mmc controller on
 Hi3798MV200
Date: Sun, 16 Apr 2023 17:19:31 +0800
Message-Id: <20230415-mmc-hi3798mv200-v4-0-44096e187f53@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAKO9O2QC/4XNS6oCMRAF0K1IxkYqSf/iSBBcgFNxkE9ph/fSk
 aQNivTejT0TEYe3invugySMDhNZLx4kYnbJhaGEarkgplfDGamzJRMOXEDFauq9ob0Trex85gD
 UIKtRatl0TUNKS6uEVEc1mP7V8yqNGF+PS8STu81TB7LfbcmxHHuXxhDv83xm8+vrUmYUqNW1l
 sxKIW21CdfxP4S/lQl+1jL/IfAiMMvb6iR1y6z6FMQPQRQBALloOgMtyHdhmqYneDfUdVIBAAA
 =
To: Ulf Hansson <ulf.hansson@linaro.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Rob Herring <robh+dt@kernel.org>, 
 Krzysztof Kozlowski <krzysztof.kozlowski+dt@linaro.org>, 
 Yang Xiwen <forbidden405@outlook.com>
Cc: tianshuliang <tianshuliang@hisilicon.com>, 
 Jiancheng Xue <xuejiancheng@hisilicon.com>, 
 Shawn Guo <shawn.guo@linaro.org>, David Yang <mmyangfl@gmail.com>, 
 linux-mmc@vger.kernel.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org
X-Mailer: b4 0.12.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1681636790; l=1828;
 i=forbidden405@outlook.com; s=20230415; h=from:subject:message-id;
 bh=C3B7e70soFXi8WZxufA7WKhVicEU3OSoxaI6T2fcuAc=;
 b=GmryrH+KwWWU6nkjqwj8a3ukVx0Ec87ykdWjriMTVhsDrDRMtJxEuyCjRBS4WkpmSQFeXKC9o
 j5hrj6xVIjRDVzCxNjUBHNQp58agOcAHp+V78Hg93ESTHGduk1YQplv
X-Developer-Key: i=forbidden405@outlook.com; a=ed25519;
 pk=hfdpPU3AXR+t7fdv58tXCD4UzRNq+fop2TMJezFlAhM=
X-Endpoint-Received: by B4 Relay for forbidden405@outlook.com/20230415 with auth_id=44
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The dw-mmc controller found on Hi3798MV200 is like the one found on
Hi3798CV200, but has some tweaks.
Also refreshed the dt-binding and converted it to YAML.

Signed-off-by: Yang Xiwen <forbidden405@outlook.com>
---
Changes in v4:
- fix license of dt-binding document.
- some other fixes to dt-binding document.
- Link to v3: https://lore.kernel.org/r/20230415-mmc-hi3798mv200-v3-0-00e2368c0709@outlook.com

Changes in v3:
- split dt-binding commit into 2 parts, one for renaming, the other for
  new compatible string.
- some other fixes to dt-binding document.
- Link to v2: https://lore.kernel.org/r/20230415-mmc-hi3798mv200-v2-0-1d274f9b71da@outlook.com

Changes in v2:
- add DDR52 support
- edit dt-binding, substitude all hi3798cv200 with histb
- send email to more people
- Link to v1: https://lore.kernel.org/r/20230415-mmc-hi3798mv200-v1-0-db5b91d939d4@outlook.com

---
Yang Xiwen (4):
      mmc: dw_mmc: hi3798cv200: rename to dw_mmc-histb
      mmc: dw_mmc: histb: add support for hi3798mv200
      dt-binding: mmc: hi3798cv200-dw-mshc: convert to YAML and rename to histb-dw-mshc
      dt-binding: mmc: histb-dw-mshc: Add Hi3798MV200 compatible string

 .../bindings/mmc/hi3798cv200-dw-mshc.txt           |  40 ---
 .../bindings/mmc/hisilicon,histb-dw-mshc.yaml      |  93 ++++++
 drivers/mmc/host/Kconfig                           |   8 +-
 drivers/mmc/host/Makefile                          |   2 +-
 drivers/mmc/host/dw_mmc-hi3798cv200.c              | 206 -------------
 drivers/mmc/host/dw_mmc-histb.c                    | 339 +++++++++++++++++++++
 6 files changed, 437 insertions(+), 251 deletions(-)
---
base-commit: 76f598ba7d8e2bfb4855b5298caedd5af0c374a8
change-id: 20230415-mmc-hi3798mv200-ce15e9b96866

Best regards,
-- 
Yang Xiwen <forbidden405@outlook.com>

