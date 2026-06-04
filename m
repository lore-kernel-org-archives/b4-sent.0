From: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
Date: Thu, 04 Jun 2026 14:25:53 +0300
Subject: [PATCH PATCHSET 5/6] ufs: add ufs_tool to Kconfig and Makefile
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
Message-Id: <20260604-ufs_tool-v1-5-741ed00232c0@mobileye.com>
References: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
In-Reply-To: <20260604-ufs_tool-v1-0-741ed00232c0@mobileye.com>
To: u-boot@lists.denx.de
Cc: Tom Rini <trini@konsulko.com>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Simon Glass <sjg@chromium.org>, 
 Peng Fan <peng.fan@nxp.com>, Kory Maincent <kory.maincent@bootlin.com>, 
 Yao Zi <me@ziyao.cc>, Kuan-Wei Chiu <visitorckw@gmail.com>, 
 Raymond Mao <raymond.mao@riscstar.com>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Stefan Roese <stefan.roese@mailbox.org>, 
 Philip Molloy <philip.molloy@analog.com>, 
 Jerome Forissier <jerome.forissier@arm.com>, 
 Bhupesh Sharma <bhupesh.linux@gmail.com>, 
 Neha Malcom Francis <n-francis@ti.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Macpaul Lin <macpaul.lin@mediatek.com>, Michal Simek <michal.simek@amd.com>, 
 Julien Stephan <jstephan@baylibre.com>, 
 Padmarao Begari <padmarao.begari@amd.com>, 
 Kunihiko Hayashi <hayashi.kunihiko@socionext.com>, 
 Venkatesh Yadav Abbarapu <venkatesh.abbarapu@amd.com>, 
 Jared McArthur <j-mcarthur@ti.com>, Shawn Lin <shawn.lin@rock-chips.com>, 
 Igor Belwon <igor.belwon@mentallysanemainliners.org>, 
 Tuyen Dang <tuyen.dang.xa@renesas.com>, Alexey Charkov <alchark@gmail.com>, 
 Raz Ben Yehuda <raz.benyehuda@mobileye.com>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1483;
 i=raz.benyehuda@mobileye.com; h=from:subject:message-id;
 bh=qI4uxjh503s5TdCzG//PE//lMHB1mMeJuZ+wAk23bAE=;
 b=owEBbQKS/ZANAwAKAZ+a6ZSW6I45AcsmYgBqIWDAMvd58rjg4WJsy4T3Ysg4dRbBnd+HsbZ43
 QQymir+NwiJAjMEAAEKAB0WIQSC7lz5E3UmOrJvRDqfmumUluiOOQUCaiFgwAAKCRCfmumUluiO
 OeqhD/9dTHiKhYoxny0Lrwz4Pt5EWZcnOgW0mONlM7hM+zwoA6f8BEoPwD2o6n5qUPV7RlTJHhL
 AFy1YNccj1UzL38mHRMef0rXJ5iO3Ycz+t2WLFjyrQT30HFQUCEhV8c3bLaLc77G1MfSuBwRjl/
 bvOUVlV1b2oh7DQJe7MWpc2yNSM6sLE+p8hNCcs94VaUwfZl5N9YMohKmaoTdZ5IZF8VNM1cRfj
 UambtLzbaCMghxk1MwXsKppCAxV5aXfujRH8Bb8eBKfcrqyQbIYXiD+xmDkNcOiyPC7pyPCueEG
 adiks8myPgRNoOjZPeIIxsgM5341L68Do7gl3QUA0+dRHtSif5mllPlgqSlla8SJrsBMXVFojxE
 zLTnWHIsk/Y8XZuE7UjxSl9v3Umk6OekA8bLSONmTxQje9vu50veMPKNnjn/FT1K4QFUMFy+QwR
 CNzMg4147acY2k5XxpXXm8Nn79WCJowgs1Kw4pwb5X+9lMEy/q5LT2LKVaT4WU6xBYfeKSPubCp
 9hYFTjJOPxHvD2C0y62135GtxXHaGU046bE+fzv4B949Qygt/nCHDtyx7H8kUH1GnQyVBchhvsS
 nhEwFoAT+JpfDPMvarHLz5k9GgXHuojtQA9HS5cG0SC+lGCln3X6nbml5444uui3rsdKfUYxdsq
 CnRUQhizTMbu+QQ==
X-Developer-Key: i=raz.benyehuda@mobileye.com; a=openpgp;
 fpr=82EE5CF91375263AB26F443A9F9AE99496E88E39
X-Endpoint-Received: by B4 Relay for raz.benyehuda@mobileye.com/default with auth_id=808
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Add support for the UFS tool to Kconfig and the Makefile.
The HBA ID defaults to 0 and can be overridden by the user.

Signed-off-by: Raz Ben Yehuda <raz.benyehuda@mobileye.com>
---
 drivers/ufs/Kconfig  | 15 +++++++++++++++
 drivers/ufs/Makefile |  1 +
 2 files changed, 16 insertions(+)

diff --git a/drivers/ufs/Kconfig b/drivers/ufs/Kconfig
index 49472933de3..8f67d916a72 100644
--- a/drivers/ufs/Kconfig
+++ b/drivers/ufs/Kconfig
@@ -8,6 +8,21 @@ config UFS
 	  This selects support for Universal Flash Subsystem (UFS).
 	  Say Y here if you want UFS Support.
 
+config UFS_TOOL
+	bool "ufs tool"
+	depends on UFS
+	help
+	  Add a UFS tool implementation for querying, printing, and updating
+	  UFS descriptors and configuration parameters.
+	  Please see doc/README.ufs for details.
+
+config UFS_HBA_ID
+	int "Id of the ufs hba"
+	depends on UFS_TOOL
+	default 0
+	help
+	  Default UFS HBA ID.
+
 config UFS_AMD_VERSAL2
 	bool "AMD Versal Gen 2 UFS controller platform driver"
 	depends on UFS && ZYNQMP_FIRMWARE
diff --git a/drivers/ufs/Makefile b/drivers/ufs/Makefile
index e7f3c1d30c4..0e472782261 100644
--- a/drivers/ufs/Makefile
+++ b/drivers/ufs/Makefile
@@ -4,6 +4,7 @@
 #
 
 obj-$(CONFIG_UFS) += ufs-uclass.o
+obj-$(CONFIG_UFS_TOOL) += ufs_tool.o
 obj-$(CONFIG_UFS_AMD_VERSAL2) += ufs-amd-versal2.o ufshcd-dwc.o
 obj-$(CONFIG_UFS_CADENCE) += cdns-platform.o
 obj-$(CONFIG_UFS_MEDIATEK) += ufs-mediatek.o

-- 
2.43.0

