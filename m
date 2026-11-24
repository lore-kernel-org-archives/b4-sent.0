From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/2] soundwire: qcom: fix WCD AHB serialization and
 wr_fifo_depth init order
Date: Tue, 24 Nov 2026 23:46:45 +0100
Message-Id: <20261124-qcom-soundwire-fixes-v1-0-8ca94d60ddd6@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXMQQ6CMBCF4auQWTsJbZWAVzEsdDrKkNBKh6oJ4
 e5WXH55+d8KyklY4VytkPglKjEUmEMFNFzDg1F8MdjaNsbYI84UJ9SYg39LYrzLhxU77wy1nk6
 udlDSZ+J9KOWl/1vzbWRafl+wbV/o6jpEeAAAAA==
X-Change-ID: 20261124-qcom-soundwire-fixes-9d31c8dc5303
To: Srinivas Kandagatla <srini@kernel.org>, Vinod Koul <vkoul@kernel.org>, 
 Bard Liao <yung-chuan.liao@linux.intel.com>, 
 Pierre-Louis Bossart <pierre-louis.bossart@linux.dev>
Cc: linux-arm-msm@vger.kernel.org, linux-sound@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795560406; l=1208;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=nRQ81G0pOHjTe19q0T04n8A6t3fPhnAHDBRobILJgfU=;
 b=Cgl9VQw+aZpzc2uVyo9Pn37RN8cCRaw9l4qgsxkUnFWGZrCsVHjqaYH4a9fuPeSGLUKMQZJJC
 tTwJmyKlJS8BNPqmwSb7fn5+dhMqDk89ZIg5YCKNqW4S/qb9mAaW5wK
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
Robert Ijtsma (2):
      soundwire: qcom: serialize WCD AHB bridge transactions
      soundwire: qcom: populate wr_fifo_depth before enabling interrupts

 drivers/soundwire/qcom.c | 57 ++++++++++++++++++++++++++++++++----------------
 1 file changed, 38 insertions(+), 19 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261124-qcom-soundwire-fixes-9d31c8dc5303

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

