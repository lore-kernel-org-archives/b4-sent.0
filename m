From: Roman Vivchar <rva333@protonmail.com>
Date: Mon, 07 Sep 2026 21:03:06 +0300
Subject: [PATCH v2 2/3] soc: mediatek: cmdq-helper: add legacy GCE ISA
 support
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260907-6572-gce-v2-2-412a5b037290@protonmail.com>
References: <20260907-6572-gce-v2-0-412a5b037290@protonmail.com>
In-Reply-To: <20260907-6572-gce-v2-0-412a5b037290@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1788804305; l=3889;
 i=rva333@protonmail.com; s=20260510; h=from:subject:message-id;
 bh=Uu3P5wuRY5/ZH17+b4JdmrxQxerJafFFRwJH5TYZehQ=;
 b=op39buDZAmJXgQKhtDaF+BBWSb5/59ftXLIn4uk1/rRHSDVAcd2MP8LZBqLZo5x0gvsWCF3RI
 QYmIsKafIvgAeYjaZyc3uedOWfGMF47v0yrrO2G/mQ82kf/6JSmXgii
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

Also correct comment about PA writes, because it's incorrect for legacy
ISA. Only v2 (mt8167, 8173) and v3 (mt8168, 6768, 6779, 6785, etc) have
GPRs and SPRs for PA writes.

While mt6572 GCE supports 22-bit offsets, the parameter type for offset
remains 16 bit, because all mt6572 GCE mmsys consumers are in the 0xffff
range.

Signed-off-by: Roman Vivchar <rva333@protonmail.com>
---
This change doesn't bring any functional change for mt6572. mt6572 uses
subsystem ID 0 for display, alongside with 16-bit offsets, so layout is
still compatible with v2/v3 GCEs. However, it's better to properly
describe layout.
---
 drivers/soc/mediatek/mtk-cmdq-helper.c   | 57 ++++++++++++++++++++++----------
 include/linux/mailbox/mtk-cmdq-mailbox.h |  1 +
 2 files changed, 40 insertions(+), 18 deletions(-)

diff --git a/drivers/soc/mediatek/mtk-cmdq-helper.c b/drivers/soc/mediatek/mtk-cmdq-helper.c
index f8ee6c9ade89..fb82f2a85a21 100644
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
@@ -86,7 +95,7 @@ int cmdq_dev_get_client_reg(struct device *dev,
 		client_reg->subsys = CMDQ_SUBSYS_INVALID;
 
 		/*
-		 * All GCEs support writing register PA with mask without subsys,
+		 * GCE v2/v3 support writing register PA with mask without subsys,
 		 * but this requires extra GCE instructions to convert the PA into
 		 * a format that GCE can handle, which is less performance than
 		 * directly using subsys. Therefore, when subsys is available,
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
2.55.0

