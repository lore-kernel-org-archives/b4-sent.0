From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH ath-next 00/16] wifi: ath11k: add MultiPD support for AHB
 platforms
Date: Wed, 23 Sep 2026 16:05:06 +0400
Message-Id: <20260923-ipq5018-qcn6122-mpd-v1-0-86729521a75c@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/x3MMQ6DMAxA0asgz1iK3RI1vQpigGDAQ9OQRBUS4
 u5EHd/w/wlZkkqGd3NCkp9m/YYKahvw2xhWQZ2rgQ1b48igxr0z9MLdB0vM+IkzPi131j9ock6
 gljHJosf/2sNYNgxyFBiu6wZ5C1dabwAAAA==
X-Change-ID: 20260910-ipq5018-qcn6122-mpd-46256c31b99e
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>, 
 Bjorn Andersson <andersson@kernel.org>, 
 Konrad Dybcio <konradybcio@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 Vignesh Viswanathan <vignesh.viswanathan@oss.qualcomm.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 linux-arm-msm@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=ed25519-sha256; t=1790165117; l=4766;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=DP7ZakM0RfG18wmgJmMLdmBWCDvPQiNf/lyndgVxw7o=;
 b=6n/qkdAoTe9c56sFXBkMQiIhMPZANlM6ClgA6cmMYrO+R24jrQ8EGwTec/yEhk+Bxot49e/bC
 h7Yu4a8MouHAdM5V5e2nmXjk7/IEiUYt82kbAHCiVCl1gIRvz+JDaly
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add multiPD support for AHB platforms following the approach for ath12k:
link: https://lore.kernel.org/linux-wireless/20250321-ath12k-ahb-v12-0-bb389ed76ae5@quicinc.com/
link: https://lore.kernel.org/linux-wireless/20260721065038.126046-1-aaradhana.sahu@oss.qualcomm.com/

The IPQ5018 platform is a multiPD platform and the current ath11k driver
supports standalone IPQ5018 WiFi only. However, IPQ5018 boards come with
up to two optional SoC-specific QCN6122 WiFi companion chips for 5G/6G
WiFi.

IPQ5018 implements the multi-PD architecture as follows:

                     +-----------------------------+
                     |     Q6 Remote Processor     |
                     |            RootPD           |
                     +--------------+--------------+
                                    |
                                    |
                                    |
              +---------------------+---------------------+
              |                     |                     |
        +-----v-----+         +-----v-----+         +-----v-----+
        |  UserPD1  |         |  UserPD2  |         |  UserPD3  |
        |  IPQ5018  |         | QCN6122 #1|         | QCN6122 #2|
        |  (Radio)  |         |  (Radio)  |         |  (Radio)  |
        +-----------+         +-----------+         +-----------+

The rootPD is responsible for managing the lifecycle of the UserPD and
shared resources and providing SSR notifiers. There are different
firmware blobs that include either the rootPD and userPD binaries for
IPQ5018-only which auto-spawns the userPD for IPQ5018 WiFi, or for
IPQ5018 and QCN6122 for which the userPDs for each radio must be spawned
by the ath11k driver.

It's worth noting that QCN6122 does not have its own Q6 firmware blobs.
Instead, the firmware segments for QCN6122 are included in the MPD
version of the IPQ5018 firmware blob(s). The QCN6122 M3 firmware does
come separately and is loaded into the Q6 memory carveout of IPQ5018.

In high-level, the path series covers:
- Addition of multiPD IPQ5018 binding definition
- Updates to the ath11k driver to register handle standalone vs multiPD
  remoteproc boot sequence with required notifiers.
- Support for loading M3 firmware files during remoteproc boot sequence
- Ability to set required memory carveouts for Q6, BDF, and M3 firmware
  segments.
- Addition of SCM call to manage power state of the internal IPQ5018
  WiFi radio
- Driver support for resource acquisition and power up/down of userPDs
- Binding definition and AHB driver support for QCN6122

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (16):
      dt-bindings: net: wireless: ath11k: Sort compatible names alphabetically
      dt-bindings: net: wireless: ath11k: Add bindings for IPQ5018
      wifi: ath11k: Register root PD rproc notifier
      wifi: ath11k: Add support for loading m3 mbn firmware
      wifi: ath11k: Add ability to set BDF and M3 dump memory addresses
      firmware: qcom: scm: Add support for setting internal WiFi power mode
      wifi: ath11k: Register userPD interrupts and SMEM entries
      wifi: ath11k: Power up userPD
      wifi: ath11k: Power down userPD
      dt-bindings: net: wireless: ath11k: Add bindings for QCN6122
      wifi: ath11k: add hw params for QCN6122
      wifi: ath11k: add hal regs for QCN6122
      wifi: ath11k: add hw ring mask for QCN6122
      wifi: ath11k: update hif and pci ops for QCN6122
      wifi: ath11k: define userPDs for QCN6122
      wifi: ath11k: add QCN6122 device support

 .../bindings/net/wireless/qcom,ath11k.yaml         | 569 ++++++++++++++++++++-
 drivers/firmware/qcom/qcom_scm.c                   |  43 ++
 drivers/firmware/qcom/qcom_scm.h                   |   2 +
 drivers/net/wireless/ath/ath11k/ahb.c              | 555 +++++++++++++++++++-
 drivers/net/wireless/ath/ath11k/ahb.h              |  54 +-
 drivers/net/wireless/ath/ath11k/core.c             |  99 +++-
 drivers/net/wireless/ath/ath11k/core.h             |   1 +
 drivers/net/wireless/ath/ath11k/hif.h              |   9 +
 drivers/net/wireless/ath/ath11k/hw.c               | 112 ++++
 drivers/net/wireless/ath/ath11k/hw.h               |  10 +
 drivers/net/wireless/ath/ath11k/pcic.c             |   9 +
 drivers/net/wireless/ath/ath11k/qmi.c              |  70 ++-
 drivers/net/wireless/ath/ath11k/qmi.h              |   3 +-
 include/linux/firmware/qcom/qcom_scm.h             |   1 +
 14 files changed, 1501 insertions(+), 36 deletions(-)
---
base-commit: 10cfa109c880092df32e396647b4afdca9be8350
change-id: 20260910-ipq5018-qcn6122-mpd-46256c31b99e

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

