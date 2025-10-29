From: George Moussalem <george.moussalem@outlook.com>
Subject: [PATCH 0/6] wifi: ath11k: Add support for QCN6122
Date: Wed, 29 Oct 2025 18:26:21 +0400
Message-Id: <20251029-ath11k-qcn6122-v1-0-58ed68eba333@outlook.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAA0kAmkC/x3MwQpAQBCA4VfRnG2ZWVa8ihwmBpNa7EpK3t3m+
 B3+/4EoQSVCmz0Q5NKom0/APINhYT+L0TEZqKAKC2oMnwviao7BOyQy9VhZy1yW7BykaA8y6f0
 Pu/59P6+nsdZgAAAA
X-Change-ID: 20251029-ath11k-qcn6122-7d533aa44a66
To: Johannes Berg <johannes@sipsolutions.net>, 
 Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Jeff Johnson <jjohnson@kernel.org>
Cc: linux-wireless@vger.kernel.org, devicetree@vger.kernel.org, 
 ath11k@lists.infradead.org, linux-kernel@vger.kernel.org, 
 George Moussalem <george.moussalem@outlook.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1761747997; l=2267;
 i=george.moussalem@outlook.com; s=20250321; h=from:subject:message-id;
 bh=UnCFoCnku8yVyQzP5inxRUrpnnVudgKfryjNsjn3tsQ=;
 b=khlFtybL94Ksk1micyaAESgIiFeSykKJI1T1PK4DjQeDaaEqLTDeRC3rjlObASVjWDqqhcfxH
 oVwjXKuaOMuCDgLpEjM6jJAquDkPOrU1UXsfcE01gVcWSb/DXn88qda
X-Developer-Key: i=george.moussalem@outlook.com; a=ed25519;
 pk=/PuRTSI9iYiHwcc6Nrde8qF4ZDhJBlUgpHdhsIjnqIk=
X-Endpoint-Received: by B4 Relay for george.moussalem@outlook.com/20250321 with auth_id=364
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

QCN6122 is a PCIe based solution that is attached to and enumerated
by the WPSS (Wireless Processor SubSystem) Q6 processor.

Though it is a PCIe device, since it is not attached to APSS processor
(Application Processor SubSystem), APSS will be unaware of such a decice
so it is registered to the APSS processor as a platform device(AHB).
Because of this hybrid nature, it is called as a hybrid bus device as
introduced by WCN6750.

This chip is similar to WCN6750 and follows the same codepath as for
WCN6750 to bring up the radio and communicate with the firmware.

QCN6122 is an IPQ5018 SoC specific solution and uses shared
IPQ5018/QCN6122 firmware.

This patch series is a much simplified version of below vendor patch:
Download from https://git.codelinaro.org/clo/qsdk/oss/system/feeds/wlan-open/-/blob/NHSS.QSDK.12.4.5.r2/mac80211/patches/232-ath11k-qcn6122-support.patch

Signed-off-by: George Moussalem <george.moussalem@outlook.com>
---
George Moussalem (6):
      dt: bindings: net: add bindings for QCN6122
      wifi: ath11k: add hw params for QCN6122
      wifi: ath11k: add hw ring mask for QCN6122
      wifi: ath11k: update hif and pci ops for QCN6122
      wifi: ath11k: add multipd support for QCN6122
      wifi: ath11k: add QCN6122 device support

 .../bindings/net/wireless/qcom,ath11k.yaml         | 57 +++++++++++++++++-
 drivers/net/wireless/ath/ath11k/ahb.c              | 68 ++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/core.c             | 68 ++++++++++++++++++++++
 drivers/net/wireless/ath/ath11k/core.h             |  5 ++
 drivers/net/wireless/ath/ath11k/hif.h              |  9 +++
 drivers/net/wireless/ath/ath11k/hw.c               | 37 ++++++++++++
 drivers/net/wireless/ath/ath11k/hw.h               |  1 +
 drivers/net/wireless/ath/ath11k/pci.c              |  1 +
 drivers/net/wireless/ath/ath11k/pcic.c             |  9 +++
 drivers/net/wireless/ath/ath11k/qmi.c              |  2 +
 drivers/net/wireless/ath/ath11k/qmi.h              |  3 +-
 11 files changed, 258 insertions(+), 2 deletions(-)
---
base-commit: 88de08348af8ce15dc563e0ebb5553eddd821c06
change-id: 20251029-ath11k-qcn6122-7d533aa44a66

Best regards,
-- 
George Moussalem <george.moussalem@outlook.com>

