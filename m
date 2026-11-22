From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/5] media: qcom: camss: fix VFE/CSID/video error handling
 and register bugs
Date: Sun, 22 Nov 2026 14:35:48 +0100
Message-Id: <20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yXM3QpAQBCG4VvRHNsy00a5FTlYazDKTztIyb1bH
 D59vd8FykFYoUwuCHyIyjJHYJqAH9zcs5E2GiijHJHIeDepmk5OVmNdXqBnwswSxGIN/A0xqOr
 fujcj++29gPt+AGjUdp5vAAAA
X-Change-ID: 20261122-camss-fixes-4a671ce21042
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795354550; l=1887;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=l9V4qs7Oo4FeqxWex4yYz7xBczsyHC0FN5r4HT7Uh2A=;
 b=/mJTAKlGb/Fwbur7CysGc1PHAGsC5svVFDUaigE45HuIgMu3gFtZqTlFzTWWk0TPfCb7tlmH0
 lWTmshpaSFhDP+yIpz1iVv7RYJp9jDKPupXCeVyrIbZNFqRbERT9y9p
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes five self-contained bugs in the Qualcomm CAMSS driver
found during Titan 175 (SC8180X) camera bring-up and code review:

1. vfe-17x: Check VFE_IRQ_STATUS_1 (status1) rather than
   VFE_IRQ_STATUS_0 (status0) against STATUS_1_RDI_SOF(i) in vfe_isr().
2. csid-gen2: Use BIT(RDI_CFG0_ENABLE) to explicitly set or clear bit 31
   in __csid_configure_rdi_stream(), avoiding signed int shift overflow
   and ensuring the enable bit is cleared when stopping a stream.
3. csid: Release the parent device reference via parent_dev_ops->put()
   on all csid_set_power() power-on failure paths.
4. vfe: Destroy power_lock and stream_lock after unregistering VFE
   subdevices and video nodes in msm_vfe_unregister_entities().
5. video: Roll back already-started upstream subdevices if s_stream(1)
   fails partway through video_start_streaming().

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Robert Ijtsma (5):
      media: qcom: camss: vfe-17x: check status1 for RDI SOF interrupts
      media: qcom: camss: csid-gen2: fix RDI enable bit manipulation
      media: qcom: camss: csid: release parent device on power-on failure
      media: qcom: camss: vfe: destroy mutexes after unregistering entities
      media: qcom: camss: video: stop started subdevs on start_streaming failure

 .../media/platform/qcom/camss/camss-csid-gen2.c    |  5 ++-
 drivers/media/platform/qcom/camss/camss-csid.c     | 48 ++++++++++------------
 drivers/media/platform/qcom/camss/camss-vfe-17x.c  |  2 +-
 drivers/media/platform/qcom/camss/camss-vfe.c      |  6 +--
 drivers/media/platform/qcom/camss/camss-video.c    | 27 ++++++++++--
 5 files changed, 54 insertions(+), 34 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-camss-fixes-4a671ce21042

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

