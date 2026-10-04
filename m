From: Petr Hodina <petr.hodina@protonmail.com>
Date: Sun, 04 Oct 2026 21:22:40 +0200
Subject: [PATCH u-boot 8/8] arm: dts: qcom: akatsuki: re-enable the UFS
 controller node
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20261004-b4-ufs-sony-v1-8-54e71c95ba62@protonmail.com>
References: <20261004-b4-ufs-sony-v1-0-54e71c95ba62@protonmail.com>
In-Reply-To: <20261004-b4-ufs-sony-v1-0-54e71c95ba62@protonmail.com>
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
X-Developer-Signature: v=1; a=ed25519-sha256; t=1791141780; l=1485;
 i=petr.hodina@protonmail.com; s=20260107; h=from:subject:message-id;
 bh=QVlhZ7MAT+TeLV7gQeOnoExu28XTr702eo6kVaytxCs=;
 b=0cJS2YcECbh/9q131AEAOs2knpLx8EUVSKgQqR0xf+H0QMBcRigu8G/+Xl1FWPZyWk930YUQG
 3YXk8/2TUEjCT1dTbR+G8OPHhxyxEUO9Ava/S3BGll/M3EYgB2eoej9
X-Developer-Key: i=petr.hodina@protonmail.com; a=ed25519;
 pk=3QaVc6AaAu1IsyyH86+LIOOFhD7kCws8Xhe+wwyE7Bg=
X-Endpoint-Received: by B4 Relay for petr.hodina@protonmail.com/20260107 with auth_id=594
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Upstream Linux explicitly disables ufs_mem_hc/ufs_mem_phy for all Tama
devices (sdm845-sony-xperia-tama.dtsi):

    /* BIG WARNING! DO NOT TOUCH UFS, YOUR DEVICE WILL DIE! */
    &ufs_mem_hc { status = "disabled"; };
    &ufs_mem_phy { status = "disabled"; };

PURGE/UNMAP command issued to these devices' UFS erases the bootloader
and permanently bricks the device.

Signed-off-by: Petr Hodina <petr.hodina@protonmail.com>
---
 MAINTAINERS                                               | 1 +
 arch/arm/dts/sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi | 9 +++++++++
 2 files changed, 10 insertions(+)

diff --git a/MAINTAINERS b/MAINTAINERS
index 45e9076de67..9d6aa8126b7 100644
--- a/MAINTAINERS
+++ b/MAINTAINERS
@@ -687,6 +687,7 @@ R:	Sumit Garg <sumit.garg@kernel.org>
 L:	u-boot-qcom@groups.io
 S:	Maintained
 T:	git https://source.denx.de/u-boot/custodians/u-boot-snapdragon.git
+F:	arch/arm/dts/sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi
 F:	configs/qcm6490_defconfig
 F:	configs/qcs9100_defconfig
 F:	drivers/*/*/pm8???-*
diff --git a/arch/arm/dts/sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi b/arch/arm/dts/sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi
new file mode 100644
index 00000000000..a6e7ba45e92
--- /dev/null
+++ b/arch/arm/dts/sdm845-sony-xperia-tama-akatsuki-u-boot.dtsi
@@ -0,0 +1,9 @@
+// SPDX-License-Identifier: GPL-2.0
+
+&ufs_mem_hc {
+	status = "okay";
+};
+
+&ufs_mem_phy {
+	status = "okay";
+};

-- 
2.55.0

