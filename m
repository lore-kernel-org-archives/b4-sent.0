From: Roman Vivchar <rva333@protonmail.com>
Date: Tue, 28 Jul 2026 12:42:47 +0300
Subject: [PATCH 2/3] soc: mediatek: cmdq-helper: add legacy GCE ISA support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260728-6572-gce-v1-2-750bba32689e@protonmail.com>
References: <20260728-6572-gce-v1-0-750bba32689e@protonmail.com>
In-Reply-To: <20260728-6572-gce-v1-0-750bba32689e@protonmail.com>
To: Jassi Brar <jassisinghbrar@gmail.com>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Houlong Wei <houlong.wei@mediatek.com>
Cc: linux-kernel@vger.kernel.org, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-mediatek@lists.infradead.org, 
 Roman Vivchar <rva333@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1785231864; l=3004;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=zZ+T88ouE2HEHrb/+XDv8Cd6G79UZoiQS67bfvvjzg8=;
 b=d+Cfv4lBlSgH8mHhR9Egf7NQmDNkbdPnCidcXHN2SrHTq2hp/DS8z69fXvHB4FeKpiTDq5Jjq
 2o9gl25TkoLAPLvQGia7716wO312VM3cPWmTA/dgRVaX9D1VUMK+Yqv
X-Developer-Key: i=rva333@protonmail.com; a=ed25519;
 pk=zww/nWjBGoQ4POXCG0BV6fx2iuXK6jx77rsKPA5YK5Y=
X-Endpoint-Received: by B4 Relay for rva333@protonmail.com/20260510 with auth_id=777
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Some SoCs, such as mt6572, have different WRITE and POLL instruction
encoding. Instead of 16-bit offset and 8-bit subsystem ID, old GCEs have
22-bit offset and 2-bit subsystem ID.

Extend cmdq_instruction struct with additional union and struct to hold
the legacy format of instruction encoding. Add legacy_isa to select
legacy GCE ISA when writing instruction. Finally, add special handing
for legacy_isa cases.

While mt6572 GCE supports 22-bit offsets, the parameter type for offset
remains 16 bit, because all mt6572 GCE mmsys consumers are in the 0xffff
range.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
 drivers/soc/mediatek/mtk-cmdq-helper.c   | 55 ++++++++++++++++++++++----------
 include/linux/mailbox/mtk-cmdq-mailbox.h |  1 +
 2 files changed, 39 insertions(+), 17 deletions(-)

diff --git a/drivers/soc/mediatek/mtk-cmdq-helper.c b/drivers/soc/mediatek/mtk-cmdq-helper.c
index f8ee6c9ade89..094732405080 100644
--- a/drivers/soc/mediatek/mtk-cmdq-helper.c
+++ b/drivers/soc/mediatek/mtk-cmdq-helper.c
@@ -31,18 +31,27 @@ struct cmdq_instruction {
 		};
 	};
 	union {
-		u16 offset;
-		u16 event;
-		u16 reg_dst;
-	};
-	union {
-		u8 subsys;
 		struct {
-			u8 sop:5;
-			u8 arg_c_t:1;
-			u8 src_t:1;
-			u8 dst_t:1;
-		};
+			union {
+				u16 offset;
+				u16 event;
+				u16 reg_dst;
+			};
+			union {
+				u8 subsys;
+				struct {
+					u8 sop:5;
+					u8 arg_c_t:1;
+					u8 src_t:1;
+					u8 dst_t:1;
+				};
+			};
+		} __packed;
+
+		struct {
+			u32 offset_legacy:22;
+			u32 subsys_legacy:2;
+		} __packed;
 	};
 	u8 op;
 };
@@ -219,10 +228,16 @@ int cmdq_pkt_write(struct cmdq_pkt *pkt, u8 subsys, u16 offset, u32 value)
 {
 	struct cmdq_instruction inst = {
 		.op = CMDQ_CODE_WRITE,
-		.value = value,
-		.offset = offset,
-		.subsys = subsys
+		.value = value
 	};
+
+	if (pkt->priv.legacy_isa) {
+		inst.offset_legacy = offset;
+		inst.subsys_legacy = subsys;
+	} else {
+		inst.offset = offset;
+		inst.subsys = subsys;
+	}
 	return cmdq_pkt_append_command(pkt, inst);
 }
 EXPORT_SYMBOL(cmdq_pkt_write);
@@ -459,10 +474,16 @@ int cmdq_pkt_poll(struct cmdq_pkt *pkt, u8 subsys,
 {
 	struct cmdq_instruction inst = {
 		.op = CMDQ_CODE_POLL,
-		.value = value,
-		.offset = offset,
-		.subsys = subsys
+		.value = value
 	};
+
+	if (pkt->priv.legacy_isa) {
+		inst.offset_legacy = offset;
+		inst.subsys_legacy = subsys;
+	} else {
+		inst.offset = offset;
+		inst.subsys = subsys;
+	}
 	return cmdq_pkt_append_command(pkt, inst);
 }
 EXPORT_SYMBOL(cmdq_pkt_poll);
diff --git a/include/linux/mailbox/mtk-cmdq-mailbox.h b/include/linux/mailbox/mtk-cmdq-mailbox.h
index 07c1bfbdb8c4..9fcebc4ca864 100644
--- a/include/linux/mailbox/mtk-cmdq-mailbox.h
+++ b/include/linux/mailbox/mtk-cmdq-mailbox.h
@@ -72,6 +72,7 @@ struct cmdq_cb_data {
 
 struct cmdq_mbox_priv {
 	u8 shift_pa;
+	bool legacy_isa;
 	dma_addr_t mminfra_offset;
 };
 

-- 
2.54.0

