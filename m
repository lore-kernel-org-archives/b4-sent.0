From: Congcong Yao <congcong.yao@mediatek.com>
Subject: [PATCH v13 0/2] Add SMI reset and clamp for MediaTek MT8188 SoC
Date: Fri, 20 Nov 2026 11:24:54 +0800
Message-Id: <20261120-8188-smi-clamp-reset-v13-0-9a9516e81c1d@mediatek.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIe9/2oC/z2OwQrCMBBEf6Xk7JZsQiX15H+IhzTZ2lVjSxLFU
 vrvpgoe3zDzmEUkikxJHKpFRHpx4vFRAPWuEm6wjwsB+xIIJdUeUWowaAykwODuNkwQKVEG0g4
 7p7RBb0SZTpF6fn+9p/OP07O7ksuba2v0cQyQh0j2r5eILSrZNKputWoAoY/s7VzP5ccxkGeb6
 Va7MYh1/QBTkgXougAAAA==
X-Change-ID: 20261103-8188-smi-clamp-reset-e3c1bc2381d8
To: Yong Wu <yong.wu@mediatek.com>, Krzysztof Kozlowski <krzk@kernel.org>, 
 Rob Herring <robh@kernel.org>, Conor Dooley <conor+dt@kernel.org>, 
 Matthias Brugger <matthias.bgg@gmail.com>, 
 AngeloGioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 Philipp Zabel <p.zabel@pengutronix.de>
Cc: linux-mediatek@lists.infradead.org, linux-kernel@vger.kernel.org, 
 devicetree@vger.kernel.org, linux-arm-kernel@lists.infradead.org, 
 Friday Yang <friday.yang@mediatek.com>, 
 Congcong Yao <congcong.yao@mediatek.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1795145107; l=6753;
 i=congcong.yao@mediatek.com; s=20260722; h=from:subject:message-id;
 bh=XotnFxO8wFe7Ywe6fbOIqLlxO6KyM6lqRZTHezKmJBc=;
 b=H6b+KOcpvuYICqIB91vfYsHUcp/nqHn75HJN+yDppuC/dWFtw1s9vgSjOMxy75OORtHVlkGFB
 4V1b/o1JWBqC97K+7l2jALivps0CeAq/w9aP4xW+iS5TmsfMLBCfKKx
X-Developer-Key: i=congcong.yao@mediatek.com; a=ed25519;
 pk=tIrmGxKQQxnfyb48iCCd19063tppPj89U3nupGYAIxg=
X-Endpoint-Received: by B4 Relay for congcong.yao@mediatek.com/20260722 with auth_id=889
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Based on: linux-next (adcad7f4e633, 2026-11-19)

On the MediaTek MT8188 SoC platform, we encountered power-off failures
and SMI bus hang issues during camera stress tests. The issue arises
because bus glitches are sometimes produced when MTCMOS powers on or
off. While this is fairly normal, the software must handle these
glitches to avoid mistaking them for transaction signals. What's
more, this issue emerged only after the initial upstreaming of SMI
driver.

The software solutions can be summarized as follows:

1. Use CLAMP to disable the SMI sub-common port after turning off the
   LARB CG and before turning off the LARB MTCMOS.
2. Use CLAMP to disable/enable the SMI sub-common port.
3. Implement an AXI reset for SMI LARBs.

Changes in v13:
- Use the linked SMI Common device MMIO base for clamp register writes
  instead of obtaining a syscon regmap. Remove the regmap lookup and its
  error path from mtk_smi_device_link_common().
- Move clamp port setup into mtk_smi_larb_parse_reset(), after the SMI
  Common device link is established and the larb ID is validated.
- Pass the LARB directly to the clamp helper and return immediately on
  reset failure in the genpd callback.
- Drop the v12 driver Reviewed-by tags after changing clamp access.

Changes in v12:
- We used to parse 'mediatek,smi' property in 'mtk_smi_larb_parse_syscon'
  to get smi sub common regmap. The property has already been parsed in
  'mtk_smi_device_link_common'. To remove redundant code, we remove
  'mtk_smi_larb_parse_syscon' function and get the smi sub common regmap
  in 'mtk_smi_device_link_common'.
- We need to get driver data in 'mtk_smi_device_link_common', so move
  'platform_set_drvdata' before 'mtk_smi_device_link_common' in
  'mtk_smi_larb_probe'.
- Link to v12:
  https://lore.kernel.org/lkml/20260119120552.9325-1-friday.yang@mediatek.com/

Changes in v11:
- Add error checking in the 'mtk_smi_genpd_callback' function and use
  'switch-case' statement instead of 'if-else'.
- Use 'larb->larb_gen->clamp_port[larb->larbid]' to determine
  whether smi larb requires clamp and reset operations or not in
  'mtk_smi_larb_probe'. Remove the '_optional' suffix from the
  function name.
- Replace 'devm_reset_control_get_optional_exclusive' with
  'devm_reset_control_get_exclusive' in 'mtk_smi_larb_parse_reset',
  return the error code if it fails to get the reset controller.
- Remove genpd callback when smi larb probe fails.
- Link to v11:
  https://lore.kernel.org/lkml/20250917120724.8650-1-friday.yang@mediatek.com/

Changes in v10:
- Rename 'smi_comm_inport_id' to 'smi_comm_in_port_id'.
- Return 0 when it fails to get 'larb_id' in
  'mtk_smi_larb_parse_clamp_optional'.
- Link to v10:
  https://lore.kernel.org/lkml/20250806085946.11383-1-friday.yang@mediatek.com/

Changes in v9:
- Add 'dev_pm_genpd_remove_notifier' in 'mtk_smi_larb_remove'.
- Remove unused macros.
- Rename 'sub_comm_syscon' to 'smi_comm_syscon'.
- Rename 'sub_comm_inport_id' to 'smi_comm_inport_id'.
- Add more detailed descriptions in change log.
- Fix incorrect tags.
- Link to v9:
  https://lore.kernel.org/lkml/20250804125215.23076-1-friday.yang@mediatek.com/

Changes in v8:
- Fix incorrect tags.
- Link to v8:
  https://lore.kernel.org/lkml/20250521063347.31578-1-friday.yang@mediatek.com/

Changes in v7:
- We replaced 'pm_runtime_enable' with 'devm_pm_runtime_enable' in the
  v6 patch. This changed the order of cleanup, and reviewers expressed
  concerns that it could introduce unexpected issues. So v7 discard this
  change and continue using 'pm_runtime_enable'. We need to conduct
  further investigation to determine if there are any issues related
  to the cleanup order. This might be resolved in the future, but for
  now, we just maintain the current status.
- Link to v7:
  https://lore.kernel.org/lkml/20250430094545.23932-1-friday.yang@mediatek.com/

Changes in v6:
- Fix coding style.
- Add another patch to replace 'pm_runtime_enable' with
  'devm_pm_runtime_enable'.
- Link to v6:
  https://lore.kernel.org/lkml/20250408033206.12176-1-friday.yang@mediatek.com/

Changes in v5:
- Use 'devm_pm_runtime_enable' instead of 'pm_runtime_enable'.
- Remove 'pm_runtime_disable' in 'mtk_smi_common_remove' and
  'mtk_smi_larb_remove'.
- Link to v5:
  https://lore.kernel.org/lkml/20250311122327.20685-1-friday.yang@mediatek.com/

Changes in v4:
- Use 'devm_reset_control_get_optional_exclusive' instead of
  'devm_reset_control_get'.
- Link to v4:
  https://lore.kernel.org/lkml/20250221074846.14105-1-friday.yang@mediatek.com/

Changes in v3:
- Remove redundant descriptions for 'resets' and 'reset-names'.
- Modify the requirements for 'resets' and 'reset-names'.
- Rename 'mtk_smi_larb_parse_clamp' to 'mtk_smi_larb_parse_clamp_optional'.
- Rename 'mtk_smi_larb_parse_reset' to 'mtk_smi_larb_parse_reset_optional'.
- Merge 'mtk_smi_larb_clamp_protect_enable' and
  'mtk_smi_larb_clamp_protect_disble' into one function.
- Modify the definition for mtk_smi_larb_clamp_port_mt8188,
  use 'larbid' as the index of the array.
- Use 'syscon_regmap_lookup_by_phandle' instead of 'device_node_to_regmap'.
- Do Not parse 'resets', just check the return value of
  'devm_reset_control_get'.
- Add 'has_gals' flag for 'mtk_smi_sub_common_mt8188'.
- Link to v3:
  https://lore.kernel.org/lkml/20250121064934.13482-1-friday.yang@mediatek.com/

Changes in v2:
- According to previous discussions in v1, divided these four
  patches into two topic separately.
- Modify the description for 'resets' in binding.
- Add const value 'larb' for 'reset-names' in binding.
- Modify requirement for 'resets' and 'reset-names' in binding.
- Delete 'mediatek,smi-sub-comm' in binding.
- Delete 'mediatek,smi-sub-comm-in-portid' in binding.
- Modify the example in binding.
- Add 'mtk_smi_larb_clamp_port_mt8188' definition in SMI driver.
- Change the way to parse the 'resets' in driver.
- Change label from 'err_pm_disable' to 'err_link_remove'.
- Link to v2:
  https://lore.kernel.org/lkml/20241120063701.8194-1-friday.yang@mediatek.com/

---
Friday Yang (2):
      dt-bindings: memory: mediatek: Add SMI reset and clamp for MT8188
      memory: mtk-smi: mt8188: Add SMI reset and clamp

 .../memory-controllers/mediatek,smi-common.yaml    |   2 +
 .../memory-controllers/mediatek,smi-larb.yaml      |  19 ++++
 drivers/memory/mtk-smi.c                           | 120 ++++++++++++++++++++-
 3 files changed, 140 insertions(+), 1 deletion(-)
---
base-commit: adcad7f4e6332cff3d6d7165f41584899f598534
change-id: 20261103-8188-smi-clamp-reset-e3c1bc2381d8

Best regards,
--  
Congcong Yao <congcong.yao@mediatek.com>

