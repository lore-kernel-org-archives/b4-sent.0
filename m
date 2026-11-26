From: Ilia Snezhkov <iasnezhkov@gmail.com>
To: broonie@kernel.org, lgirdwood@gmail.com
Cc: perex@perex.cz, tiwai@suse.com, matthias.bgg@gmail.com, 
 angelogioacchino.delregno@collabora.com, linux-sound@vger.kernel.org, 
 linux-mediatek@lists.infradead.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org
Subject: [PATCH v2 0/2] ASoC: mediatek: mtk-btcvsd: fix 0xdeadfeed check
 and bt_sram_addr bounds
Date: Thu, 26 Nov 2026 00:53:14 +0000
Message-Id: <20261126005314.71606-1-iasnezhkov@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795654394; l=1430;
 i=iasnezhkov@gmail.com; s=mindone2026; h=from:subject:message-id;
 bh=x5ID1NUyDxYewEijuwziJ4VLj2wpR1LC5OkbG06mBwA=;
 b=In6UhFWhii9n4hlSRerstvYRzmXPkYxqcFJTQLbDdeGZLXxZAE5TcoTib6ZnxCTFYZr29YWaT
 ixKnNQGulV9B7b9LMNc9zyddSLC4gqTkhpp7+iVg9JQkBgQY+/s4snx
X-Developer-Key: i=iasnezhkov@gmail.com; a=ed25519;
 pk=hQgXfiWi4ukk2jh4BHu1vRVhg9BUivo//AFp50AKMag=
X-Endpoint-Received: by B4 Relay for iasnezhkov@gmail.com/mindone2026 with auth_id=1643
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This two-patch v2 series addresses two safety issues in
sound/soc/mediatek/common/mtk-btcvsd.c:

1. Check the live *bt->bt_reg_pkt_w register for 0xdeadfeed under tx_lock
   in btcvsd_tx_clean_buffer() (after skipping the empty num_valid_addr
   case), matching mtk_btcvsd_read_from_bt() and mtk_btcvsd_write_to_bt().
2. Bound bt_sram_addr[] writes in mtk_btcvsd_write_to_bt() against
   ARRAY_SIZE(bt->tx->buffer_info.bt_sram_addr) to prevent an
   out-of-bounds write past the 20-entry array.

Changes in v2:
- Replaced the ineffective check on cached virtual addresses
  bt_sram_addr[i] with a check on the live *bt->bt_reg_pkt_w register
  (returning 0 early when num_valid_addr == 0).
- Dropped the unrelated Fixes: d067b3378a78 tag; kept only
  Fixes: 4bd8597dc36c.
- Added patch 2/2 fixing the unbounded bt_sram_addr[] write spotted
  while auditing mtk_btcvsd_write_to_bt().
- Link to v1: https://lore.kernel.org/r/20261125234830.94895-1-iasnezhkov@gmail.com

Found and drafted with an AI coding assistant while bringing up MT6789.

Ilia Snezhkov (2):
  ASoC: mediatek: mtk-btcvsd: check bt_reg_pkt_w for 0xdeadfeed in
    btcvsd_tx_clean_buffer()
  ASoC: mediatek: mtk-btcvsd: bound bt_sram_addr[] writes in
    mtk_btcvsd_write_to_bt()

 sound/soc/mediatek/common/mtk-btcvsd.c | 28 ++++++++++++++++++++------
 1 file changed, 22 insertions(+), 6 deletions(-)

-- 
2.54.0 (Apple Git-157)


