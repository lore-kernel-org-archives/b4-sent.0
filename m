From: George Chan <gchan9527@gmail.com>
Subject: [PATCH 0/3] u-boot chain-loading LineageOS bootimg
Date: Sun, 27 Apr 2025 19:25:19 +0800
Message-Id: <20250427-android-boot-v1-0-bb6b37c9c9f1@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAB8UDmgC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDI1MDEyNz3cS8lKL8zBTdpPz8Et3U5KQkczOL5JREcyMloJaCotS0zAqwcdG
 xtbUACT5Sf14AAAA=
To: Tom Rini <trini@konsulko.com>, 
 Mattijs Korpershoek <mkorpershoek@kernel.org>, 
 Simon Glass <sjg@chromium.org>, Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Sumit Garg <sumit.garg@kernel.org>
Cc: u-boot@lists.denx.de, u-boot-qcom@groups.io, 
 George Chan <gchan9527@gmail.com>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1745753127; l=2260;
 i=gchan9527@gmail.com; s=20241015; h=from:subject:message-id;
 bh=TpB6jitJMIGVpdwdy7qxgOqOgCBFafe139KZgj6iPf4=;
 b=PKQFLxaHwapPNwtomlArsob6qBCMQHL6B86lp2XxK/EhHNCStBp4W4NCLvPWrZAV1CNYBV/F+
 KfDauO/9OPvDzFBfoihz347uBkPcXmxXIjM6PQCOQ/xDE2XXcGoygmu
X-Developer-Key: i=gchan9527@gmail.com; a=ed25519;
 pk=dscYWhT+BiQOBMpPE19NFQAjBBmcpipc6zdf2MTze/U=
X-Endpoint-Received: by B4 Relay for gchan9527@gmail.com/20241015 with auth_id=248
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This is a series of patches to enable chainloading LineageOS on qcom SOC.

First patch is to workaround kernel/ramdisk invalid addr by identify
its physical memory address out-of-range. Since qcom SOC usually have
0x80000000 as start/base/real memory address but androidboot img
specified to around 0x0. If other vendor bootloader behave similar then
this patch can also workaround it as well.

Second patch is enable bootmeth-android to have chance for extra mem block.
Usually the fastboot mem block, to hold androidboot img, and loadaddr for
unzipped kernel. If other SOC have extra mem block available but
fastboot block, we can add extra logic to take care of it.

Third patch is optional to enable snapdragon board to have extra cmdline
found from original bootloader that is required for LineageOS boot init. 
An alternate method is to put the append string into a dummy device-tree
file, as /chosen/bootarg ofnode porperty, that also contain msm-id. Then
encapsulate as androidboot img and let u-boot as kernel binary. Below is
an example for Xiaomi Miatoll device.

/dts-v1/;

/ {
        qcom,msm-id = <443 0x0>;
        qcom,board-id = <0 0>, 
			<0x10022 1>,
			<0x20022 1>,
			<0x30022 1>,
			<0x40022 1>,
			<0x50022 1>;

        #address-cells = <2>;
        #size-cells = <2>;

        memory {
                ddr_device_type = <0x07>;
                /* We expect the bootloader to fill in the size */
                reg = <0 0 0 0>;
        };

	chosen {
		bootargs = "";
	};
};

Signed-off-by: George Chan <gchan9527@gmail.com>
---
George Chan (3):
      boot/image-android.c: Workaround androidboot kernel/ramdisk addr
      boot/bootmeth-android.c: Reuse fastboot memory block for unzip kernel
      mach-snapdragon: Add support to append string to kernel cmdline

 arch/arm/mach-snapdragon/Kconfig | 11 +++++
 arch/arm/mach-snapdragon/board.c | 97 ++++++++++++++++++++++++++++++++++++++++
 boot/bootmeth_android.c          | 12 +++++
 boot/image-android.c             | 10 +++++
 4 files changed, 130 insertions(+)
---
base-commit: 5a0a93a768487e55ebe50a34cc90d751bf99cc56
change-id: 20250427-android-boot-ecbb768cda72

Best regards,
-- 
George Chan <gchan9527@gmail.com>

