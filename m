From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v2 0/2] soundwire: qcom: fix WCD AHB serialization and
 wr_fifo_depth init order
Date: Thu, 26 Nov 2026 09:06:23 +0100
Message-Id: <20261126-qcom-soundwire-fixes-v2-0-07075d571c6c@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAH/oB2sC/4WNQQ6CMBBFr0JmbU1bkIAr72FYYGeEMUK1A6gh3
 N2CB3D58t//fwahwCRwTGYINLGw7yPYXQKurfuGFGNksNrmxthMPZ3vlPixxxcHUld+k6gSU+M
 KdIdUpxCrj0BbEJvn6scyXm7khnVrNVqWwYfP9juZ1ftzMRmlVeHqMsNcI2J+arqa7/voQrUsy
 xdYLGbaygAAAA==
X-Change-ID: 20261124-qcom-soundwire-fixes-9d31c8dc5303
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795680384; l=1637;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=EKuMdzh0CDsAUMsVPBbo4yBwAdPy4sgV4sn7UuhWg2I=;
 b=/igoro4ofmmEDSn6eUL3l/Aq8ZauC88vivGBhSdbnqcTnYnG/rFoJbJNvZQsPCrNcMWGi/RPN
 F+kvXa2CNQ5DuAWTFW50yI7ZWUDSeLRBfGAVGMolqL4PSzjrFrBhREn
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Fix two race conditions observed on WCD934x-hosted Qualcomm SoundWire
controllers (such as on Microsoft Surface Pro X / SC8180X):

1. Serialize each two-step WCD AHB bridge register access (RD_ADDR +
   RD_DATA or WR_DATA + WR_ADDR) with a controller mutex so concurrent
   IRQ and init/bus accesses cannot interleave on the shared bridge
   registers.
2. Read and validate SWRM_COMP_PARAMS write FIFO depth before
   registering the threaded IRQ in probe and before enabling CPU
   interrupts in qcom_swrm_init(), avoiding false write-FIFO overflow
   errors while wr_fifo_depth is still zero.

Tested on Microsoft Surface Pro X SQ2 (SC8180X, WCD934x + WSA881x).

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Drop redundant unchecked SWRM_COMP_PARAMS read from qcom_swrm_init() in
  patch 2/2 since qcom_swrm_probe() already reads and validates
  wr_fifo_depth before requesting the IRQ.
- Point patch 2/2 Fixes: tag to a661308c34de ("soundwire: qcom: wait for
  fifo space to be available before read/write").
- Link to v1: https://patch.msgid.link/20261124-qcom-soundwire-fixes-v1-0-8ca94d60ddd6@gmail.com

---
Robert Ijtsma (2):
      soundwire: qcom: serialize WCD AHB bridge transactions
      soundwire: qcom: populate wr_fifo_depth before enabling interrupts

 drivers/soundwire/qcom.c | 51 ++++++++++++++++++++++++++++++------------------
 1 file changed, 32 insertions(+), 19 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-qcom-soundwire-fixes-9d31c8dc5303

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

