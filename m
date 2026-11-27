From: Robert Ijtsma <robertijtsma@gmail.com>
Subject: [PATCH 0/5] media: qcom: camss: fix Titan 17x VFE-Lite, buffer
 flushing, and CSID RAW10
Date: Fri, 27 Nov 2026 21:26:23 +0100
Message-Id: <20261127-camss-titan17x-fixes-v1-0-541ab39e5889@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAG/nCWsC/x3LQQqAIBBA0avErBtIwayuEi0sp5pFFk6EEN49a
 fn4/BeEIpPAUL0Q6WHhMxSouoJld2EjZF8MutGtUtri4g4RvPl2QdmEKycSXA313ttuNsZCWa9
 IfyjnOOX8Ae7XOo9mAAAA
X-Change-ID: 20261127-camss-titan17x-fixes-f5e9dd78b557
To: Bryan O'Donoghue <bryan.odonoghue@linaro.org>, 
 Vladimir Zapolskiy <vladimir.zapolskiy@linaro.org>, 
 Loic Poulain <loic.poulain@oss.qualcomm.com>, 
 Mauro Carvalho Chehab <mchehab@kernel.org>, Robert Foss <rfoss@kernel.org>, 
 Hans Verkuil <hverkuil@kernel.org>, 
 Andrey Konovalov <andrey.konovalov@linaro.org>, 
 Atanas Filipov <atanas.filipov@oss.qualcomm.com>, 
 Milen Mitkov <quic_mmitkov@quicinc.com>, 
 Gjorgji Rosikopulos <quic_grosikop@quicinc.com>
Cc: Mauro Carvalho Chehab <mchehab+huawei@kernel.org>, 
 linux-media@vger.kernel.org, linux-arm-msm@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Robert Ijtsma <robertijtsma@gmail.com>, 
 stable@vger.kernel.org
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795811183; l=2151;
 i=robertijtsma@gmail.com; s=20261122; h=from:subject:message-id;
 bh=oZnTJwNV6PntoYX76wzl+jwfwWqVmbMVwDUv61lu1Hg=;
 b=mZw2LvD2yynvac+B7hNbPz+5VkgBnoPZNmpaN3SmrfY9fFtab4K+Tu++9YsDJoG8hy+tTYNbM
 m14aJcLqTO+BAPDTdIwKtkml0DJM7XAvByrSkVUKPeNHTxE31n08Hhw
X-Developer-Key: i=robertijtsma@gmail.com; a=ed25519;
 pk=qiDyKVqFicxFIR5sB5m+p9SWPKL2/+mMoiQnUx0C9P0=
X-Endpoint-Received: by B4 Relay for robertijtsma@gmail.com/20261122 with auth_id=1604
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series addresses five remaining Titan 17x VFE/VFE-Lite, core VFE,
and CSID gen2 issues discovered during SC8180X (Titan 175) camera
bring-up and code inspection, rebased on media-committers/next after
the initial camss fixes series:

1. vfe-17x: Omit CAMIF/bus-bridge/testgen/DSP bits from VFE-Lite global
   reset, guard VFE_BUS_WM_DEBUG_STATUS_CFG behind !vfe_is_lite(), use the
   4-client WM_ADDR_NO_SYNC_LITE_VAL mask, and iterate over the 3 bus IRQ
   registers (0..2) instead of vfe->res->line_num.
2. vfe: Match numbered vfe_liteN core clocks when vfe->id follows full
   VFEs (such as SC8280XP/SC8180X) and reuse vfe_match_core_clock_name().
3. vfe: Move vb2_buffer_done() outside output_lock in vfe_flush_buffers()
   and reset gen2.active_num = 0.
4. vfe-17x: Reuse shared vfe_buf_done() (issuing reg_update() on buffer
   updates), validate wm_output_map[wm] before indexing vfe->line[],
   initialize framedrop/subsample registers, and defer WM_CFG_EN until
   vfe_wm_update().
5. csid-gen2: Add MEDIA_BUS_FMT_{Y10,SBGGR10}_2X8_PADHI_LE to
   formats_gen2[] and configure PLAIN16 LSB unpacking in
   __csid_configure_rdi_stream().

Signed-off-by: Robert Ijtsma <robertijtsma@gmail.com>
---
Robert Ijtsma (5):
      media: qcom: camss: vfe-17x: fix VFE-Lite reset, debug, and bus IRQ handling
      media: qcom: camss: vfe: match numbered vfe_liteN clock names
      media: qcom: camss: vfe: call vb2_buffer_done() outside output_lock
      media: qcom: camss: vfe-17x: use vfe_buf_done() and defer WM enable
      media: qcom: camss: csid-gen2: support plain 16-bit LSB RAW10 formats

 .../media/platform/qcom/camss/camss-csid-gen2.c    |  11 ++-
 drivers/media/platform/qcom/camss/camss-csid.c     |  14 +++
 drivers/media/platform/qcom/camss/camss-vfe-17x.c  |  96 +++++++------------
 drivers/media/platform/qcom/camss/camss-vfe.c      | 105 ++++++++++-----------
 4 files changed, 107 insertions(+), 119 deletions(-)
---
base-commit: 10c156a0a06c0a255cbd13cabad649fd8d604b47
change-id: 20261127-camss-titan17x-fixes-f5e9dd78b557

Best regards,
-- 
Robert Ijtsma <robertijtsma@gmail.com>

