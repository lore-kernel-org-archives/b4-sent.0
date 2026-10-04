From: Petr Hodina <petr.hodina@protonmail.com>
Subject: [PATCH u-boot 0/8] ufs: Sony Yoshino/Tama (MSM8998 / SDM845) UFS
 bring-up
Date: Sun, 04 Oct 2026 21:22:32 +0200
Message-Id: <20261004-b4-ufs-sony-v1-0-54e71c95ba62@protonmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/yWMQQ6CMBAAv0L27Ca0lhr9ivFAcRfWQ2u61EgIf
 6fKcSaZWUEpCyncmhUyfUQlxQrm1MAw9XEklGdlsK31rTcGg8PCiprigperO9uOPbueoRbvTCz
 f/+0OBUNKMzwOryW8aJh/K9i2HTD3Si53AAAA
X-Change-ID: 20260611-b4-ufs-sony-794325f6f4af
To: u-boot@lists.u-boot-project.org, Sumit Garg <sumit.garg@kernel.org>, 
 u-boot-qcom@groups.io
Cc: Neil Armstrong <neil.armstrong@linaro.org>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Casey Connolly <casey.connolly@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Angelo Gioacchino Del Regno <angelogioacchino.delregno@collabora.com>, 
 David Heidelberg <david@ixit.cz>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Shawn Lin <shawn.lin@rock-chips.com>, Jared McArthur <j-mcarthur@ti.com>, 
 Michal Simek <michal.simek@amd.com>, Udit Kumar <u-kumar1@ti.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Tuyen Dang <tuyen.dang.xa@renesas.com>, Alexey Charkov <alchark@gmail.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Simon Glass <sjg@chromium.org>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Bin Meng <bmeng.cn@gmail.com>, Marek Vasut <marek.vasut@mailbox.org>, 
 David Lechner <dlechner@baylibre.com>, 
 Ilias Apalodimas <ilias.apalodimas@linaro.org>, 
 Kory Maincent <kory.maincent@bootlin.com>, Peng Fan <peng.fan@nxp.com>, 
 Kuan-Wei Chiu <visitorckw@gmail.com>, Janne Grunau <j@jannau.net>, 
 Julien Masson <jmasson@baylibre.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Markus Niebel <Markus.Niebel@ew.tq-group.com>, Petr Pavlata <petr@acrux.cz>, 
 Petr Hodina <petr.hodina@protonmail.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141779; l=3712;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=PZPtEbRvlRqs18hXbbpx4eRshX2dFv2BkECdsBwGBVk=;
 b=LyQFKS/S38L27SLZ/ZhevTqJQCn74peIL5+5fGabM1YTVtgk/dq1swnAJ0zvzmgmM8Svfp5NR
 A39VfrHccReD/fPqba/gqfgUwS0zBg48NshmQRKvrPgywbmjhJlC7Ii
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This series brings up UFS on the Sony Xperia "Yoshino" (MSM8998) and
"Tama" (SDM845) families.

The work falls into four layers:

1. A small refactor that extends ufs_dev_desc with the product revision
   string and the UFS spec version (patch 1). No behaviour change.

2. A device-quirk infrastructure (patches 2-4) that lets us match
   per-device link / power-mode workarounds against manufacturer id,
   model and fw revision:

     - patch 2: generic ufs_fixups[] table and ufshcd_fixup_dev_quirks(),
       called from ufs_start() before power-mode negotiation
     - patch 3: UFS_DEVICE_QUIRK_EXTEND_SYNC_LENGTH for SK Hynix devices
       that need PA_TxHsG{1,2,3}SyncLength programmed to 0x48
     - patch 4: CONFIG_UFS_RESTRICT_TX_LANES build-time knob for boards
       with only a single reliable TX lane. Defaults to N so nothing
       else is affected.

3. The NO_PURGE quirk for devices that brick if issued PURGE / UNMAP
   (patches 5-7):

     - patch 5: refuse erase/UNMAP in the SCSI uclass when NO_PURGE
       is set on the underlying UFS device
     - patch 6: print device identification (vendor / model / rev /
       spec version) at probe so quirk matching is observable on the
       console
     - patch 7: a platform gate that auto-enables NO_PURGE on Sony
       Yoshino/Tama compatibles because per-UFS-chip rows can't see
       blank string descriptors on some affected boards.

4. Akatsuki DTS enablement (patch 8): re-enable the UFS controller node.

Background on NO_PURGE: on the affected Sony platforms the SCSI ERASE /
UNMAP / WRITE_BUFFER PURGE operation overwrites the bootloader region
and permanently bricks the device.

Based on the linux patches by Angelo:
https://github.com/kholk/kernel/commit/2e7a9ee1c91a016baa0b826a7752ec45663a0561

Tested on Sony XZ3 (akatsuki, SDM845) where U-Boot enumerates UFS LUN0
and exposes the GPT.

```
UFS Device Information (ufshc@1d84000)
  Manufacturer:    Samsung (0x01ce)
  Model:           (unset)
  Revision:        (unset)
  Spec Version:    0x0210
  Gear  - RX: 3, TX: 3
  Lane  - RX: 2, TX: 2
  Power - RX: 1, TX: 1, HS rate: 2
  Device Quirks:   0x00000001
  NO_PURGE Quirk:  Yes

...

=> scsi erase 0 1

scsi erase: device 0 block # 0, count 1 ... scsi_erase: erase not supported on this device
0 blocks erased: ERROR
=> 
```

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
Petr Hodina (8):
      ufs: read product revision and spec version into ufs_dev_desc
      ufs: add device-quirk infrastructure
      ufs: program extended HS sync length for SK Hynix devices
      ufs: add CONFIG_UFS_RESTRICT_TX_LANES
      scsi: ufs: refuse erase/UNMAP on NO_PURGE devices
      ufs: print device information at probe
      ufs: gate NO_PURGE on Sony Yoshino/Tama platform compatible
      arm: dts: qcom: akatsuki: re-enable the UFS controller node

 MAINTAINERS                                        |   1 +
 .../sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi   |   9 +
 drivers/scsi/scsi.c                                |   5 +
 drivers/ufs/Kconfig                                |  14 ++
 drivers/ufs/ufs-uclass.c                           | 197 +++++++++++++++++++++
 drivers/ufs/ufs.h                                  |   7 +
 drivers/ufs/ufs_quirks.h                           |  94 ++++++++++
 drivers/ufs/unipro.h                               |   3 +
 include/scsi.h                                     |   5 +
 9 files changed, 335 insertions(+)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260611-b4-ufs-sony-794325f6f4af

Best regards,
--  
Petr Hodina <petr.hodina@protonmail.com>

