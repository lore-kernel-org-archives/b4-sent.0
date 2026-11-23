From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH v2 0/5] media: qcom: camss: fix VFE/CSID/video error
 handling and register bugs
Date: Tue, 24 Nov 2026 00:43:52 +0100
Message-Id: <20261124-camss-fixes-v2-0-231a5523cd59@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/22NwQ6CMBBEf4Xs2Zp204B68j8Mh1IWWGOp6SLRE
 P7dglePLzNvZgGhxCRwKRZINLNwHDPgoQA/uLEnxW1mQI2lMYjKuyCiOn6TKOvKynhCoy1CNp6
 J9iALt/rH8mru5KdtYmsMLFNMn/1uNlvv//JslFbntrMtNaeKHF774Phx9DFAva7rF9nXceO4A
 AAA
X-Change-ID: 20261122-camss-fixes-4a671ce21042
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>
Cc: linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 Robert Ijtsma <robertijtsma@gmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795477434; l=2793;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=vYw1nPh4Klj7yHJJhzQwQj3DP4trkjzglC80GQbAh9g=;
 b=f6LOdyOpXQ6PZYXfnrU/+X9zNYMIEEJmIqnb9ruI3YgBRDuFFTxrGwH+szN/WIP4+WOJdRVKg
 sAM+MRsWE1GCZHVajo4+Tc2vcxZnWCJZWam8F5BDhRvfnwcJl37twud
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series fixes five bugs in the Qualcomm CAMSS driver found during
Titan 175 (SC8180X) camera bring-up and code review:

1. vfe-17x: Check VFE_IRQ_STATUS_1 (status1) rather than
   VFE_IRQ_STATUS_0 (status0) against STATUS_1_RDI_SOF(i) in vfe_isr().
2. csid-gen2: Change `enable` to bool and use BIT(RDI_CFG0_ENABLE) to
   explicitly set or clear bit 31 in __csid_configure_rdi_stream().
3. csid: Release the parent device reference via parent_dev_ops->put()
   on all csid_set_power() power-on failure paths.
4. vfe: Destroy power_lock and stream_lock after unregistering VFE
   subdevices and video nodes in msm_vfe_unregister_entities().
5. video: Factor subdevice stream start/stop into a shared helper using
   v4l2_subdev_enable_streams()/v4l2_subdev_disable_streams(), unwinding
   partial start failures and continuing teardown on stop errors.

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Changes in v2:
- Patch 1/5: Drop Fixes tag since vfe_isr_sof() is currently a no-op on
  vfe-17x (Loic); collect Reviewed-by tags from Loic and Bryan.
- Patch 2/5: Change `enable` parameter to `bool` (Loic), drop irrelevant
  sign-bit remark from commit message, and add Bryan's Reviewed-by (Bryan).
- Patch 3/5: Collect Reviewed-by tags from Loic and Bryan.
- Patch 4/5: Collect Reviewed-by tags from Loic and Bryan.
- Patch 5/5: Rework into a shared camss_subdev_pipeline_set_stream() helper
  using v4l2_subdev_enable_streams()/v4l2_subdev_disable_streams() and
  iterating entity sink pads rather than media_entity_remote_source_pad_unique()
  so entities with multiple active sink links (e.g. VFE with CSID + params)
  are handled cleanly (Loic). Dropped Bryan's v1 Reviewed-by due to rework.
- Link to v1: https://patch.msgid.link/20261122-camss-fixes-v1-0-9df4deb87ea2@gmail.com

---
Robert Ijtsma (5):
      media: qcom: camss: vfe-17x: check status1 for RDI SOF interrupts
      media: qcom: camss: csid-gen2: fix RDI enable bit manipulation
      media: qcom: camss: csid: release parent device on power-on failure
      media: qcom: camss: vfe: destroy mutexes after unregistering entities
      media: qcom: camss: video: factor pipeline stream start/stop into helper

 .../media/platform/qcom/camss/camss-csid-gen2.c    |   8 +-
 drivers/media/platform/qcom/camss/camss-csid.c     |  48 ++++-----
 drivers/media/platform/qcom/camss/camss-vfe-17x.c  |   2 +-
 drivers/media/platform/qcom/camss/camss-vfe.c      |   6 +-
 drivers/media/platform/qcom/camss/camss-video.c    | 116 +++++++++++++--------
 5 files changed, 104 insertions(+), 76 deletions(-)
---
base-commit: 4843f6873f7c4835e62f2c73ba0fd538e57a2f22
change-id: 20261122-camss-fixes-4a671ce21042

Best regards,
--  
Robert Ijtsma <robertijtsma@gmail.com>

