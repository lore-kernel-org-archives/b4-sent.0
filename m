From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/6] Add support for IPQ5018 Bluetooth
Date: Thu, 25 Jun 2026 18:10:04 +0400
Message-Id: <20260625-ipq5018-bluetooth-v1-0-d999be0e04f7@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWNQQrCMBREr1Ky9kuammiLiPeQLpL0R4NN0+a3R
 RDvbrSbgTcwb96MMHkk1hRvlnD15OOQodwVzD70cEfwXWYmuFBcCQl+nCQvT2D6BecY5wdw5Zx
 Stu6OsmJ5NyZ0/vV33tqNE05LVs9byQIS6b+6Kc6buRTZGO0TNMGwBgywSuBQS+Sm4s65ml8j0
 X5adG9jCPscl9+b0YTwa/zcFIeu1KYSB2fNkbWfzxfm+j9+3wAAAA==
X-Change-ID: 20260625-ipq5018-bluetooth-06ff66c9d753
To: Jens Axboe <axboe@kernel.dk>, Ulf Hansson <ulfh@kernel.org>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Johannes Berg <johannes@sipsolutions.net>, 
 Jeff Johnson <jjohnson@kernel.org>, Bartosz Golaszewski <brgl@kernel.org>, 
 Marcel Holtmann <marcel@holtmann.org>, 
 Luiz Augusto von Dentz <luiz.dentz@gmail.com>, 
 Balakrishna Godavarthi <quic_bgodavar@quicinc.com>, 
 Rocky Liao <quic_rjliao@quicinc.com>, 
 Saravana Kannan <saravanak@kernel.org>, Andrew Lunn <andrew@lunn.ch>, 
 Heiner Kallweit <hkallweit1@gmail.com>, 
 Russell King <linux@armlinux.org.uk>, 
 "David S. Miller" <davem@davemloft.net>, Eric Dumazet <edumazet@google.com>, 
 Jakub Kicinski <kuba@kernel.org>, Paolo Abeni <pabeni@redhat.com>, 
 Simon Horman <horms@kernel.org>, Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>, 
 Mathieu Poirier <mathieu.poirier@linaro.org>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-block@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-mmc@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-wireless@vger.kernel.org, ath10k@lists.infradead.org, 
 linux-arm-msm@vger.kernel.org, linux-bluetooth@vger.kernel.org, 
 netdev@vger.kernel.org, linux-remoteproc@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1782396628; l=3321;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=D6SplHxUa3QnaLv8HkHyckjDvA/Fprxyfd+YMfQx7G8=;
 b=6MKZWbfvyN9Pd5FoUIlXKVCW9PgXMLB8ekM5lOyqEenPO3HzLmd7aZqmcGLCiB4/V1w9BQ4rO
 W7+WbfMcF11AMEj2N5zJ0b/Tu+DnFmNpy3aZ9Tv7SmbNEM6abwmYVk2
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hello,

This patch series introduces Bluetooth support for IPQ5018.

Bluetooth firmware on the IPQ5018 platform runs on the M0 co-processor.
The firmware is loaded by the host into a dedicated reserved memory
carveout and authenticated by TrustZone. A Secure Channel Manager (SCM)
call safely brings the peripheral core out of reset.

A shared memory ring buffer topology handles runtime data frame
transport between the host APSS and the M0 core. An outgoing APCS IPC
bit and an incoming GIC interrupt handle host/guest signaling.

This series has been tested and verified on various IPQ5018 router
boards utilizing firmware extracted from GPL distributions, using both
mdt and mbn file formats.

[   14.781511] Bluetooth: hci0: QCA Product ID   :0x00000016
[   14.781583] Bluetooth: hci0: QCA SOC Version  :0x20180100
[   14.785926] Bluetooth: hci0: QCA ROM Version  :0x00000100
[   14.791546] Bluetooth: hci0: QCA Patch Version:0x00003ded
[   14.796698] Bluetooth: hci0: QCA controller version 0x01000100
[   14.802217] Bluetooth: hci0: QCA Downloading qca/mpnv10.bin
[   16.393850] Bluetooth: hci0: QCA Build Info: BTFW.MAPLE.1.0.0-00102-MPL_ROM_PATCHZ-1

Best regards,
George Moussalem

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (6):
      dt-bindings: remoteproc: document M0 Bluetooth Subsystem secure PIL
      remoteproc: qcom: Add M0 BTSS secure PIL driver
      Bluetooth: btqca: Add IPQ5018 support
      dt-bindings: net: bluetooth: Document Qualcomm IPQ5018 Bluetooth controller
      Bluetooth: Introduce Qualcomm IPQ5018 IPC based HCI driver
      arm64: dts: qcom: ipq5018: add nodes required for Bluetooth support

 .../bindings/net/bluetooth/qcom,ipq5018-bt.yaml    |  63 ++
 .../bindings/remoteproc/qcom,m0-btss-pil.yaml      |  72 ++
 arch/arm64/boot/dts/qcom/ipq5018.dtsi              |  34 +-
 drivers/bluetooth/Kconfig                          |  11 +
 drivers/bluetooth/Makefile                         |   1 +
 drivers/bluetooth/btqca.c                          |  16 +
 drivers/bluetooth/btqca.h                          |   3 +
 drivers/bluetooth/btqcomipc.c                      | 939 +++++++++++++++++++++
 drivers/remoteproc/Kconfig                         |  12 +
 drivers/remoteproc/Makefile                        |   1 +
 drivers/remoteproc/qcom_m0_btss_pil.c              | 261 ++++++
 11 files changed, 1412 insertions(+), 1 deletion(-)
---
base-commit: 4d1ab324fcb7d20df5a071edb0304461846fdc12
change-id: 20260625-ipq5018-bluetooth-06ff66c9d753
prerequisite-message-id: <20260612-block-as-nvmem-v5-0-95e0b30fff90@oss.qualcomm.com>
prerequisite-patch-id: 6ce8686c1683f468d86b4502f5ec9d19c392a382
prerequisite-patch-id: e362f7fcbacff716b7ef720e6780786a7d88c013
prerequisite-patch-id: 9168930e40551e842c8171d5433a6f39ad4b78a4
prerequisite-patch-id: 64fecfbd1e085d7d2ab0ae23295ca34ec8e14c5e
prerequisite-patch-id: 566804aaa690ee9aa285d0fd75fd16d94fbadebf
prerequisite-patch-id: dc18bec338f54b3051f4523f9d1d3c0566a20ccd
prerequisite-patch-id: b6b3eb46429936ab49423d295433daf47981db0f
prerequisite-patch-id: 75caa99e3bbcdf41b6462b9f5f703bea1d4a65fa
prerequisite-patch-id: 35e9968f482f78ca233eb0306d9c5fdbff093175

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

