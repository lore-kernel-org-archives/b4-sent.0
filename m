From: Demeter Barna <me@fromdisposition.org>
Subject: [PATCH 0/9] Qualcomm SM8350 support
Date: Sat, 14 Nov 2026 02:21:54 +0000
Message-Id: <20261114-sm8350-support-v1-0-414271f59474@fromdisposition.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/6tWKk4tykwtVrJSqFYqSi3LLM7MzwNyDHUUlJIzE
 vPSU3UzU4B8JSMDIzNDQ0MT3eJcC2NTA93i0oKC/KISXUujFIvkFGMLMyNjYyWgpoKi1LTMCrC
 B0bEQfnFpUlZqcgnIFKXaWgD88cxYcgAAAA==
X-Change-ID: 20261114-sm8350-support-92d8cd386233
To: Sumit Garg <sumit.garg@kernel.org>, u-boot@lists.u-boot-project.org, 
 u-boot-qcom@groups.io
Cc: Tom Rini <trini@konsulko.com>, Lukasz Majewski <lukma@nabladev.com>, 
 Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Biswapriyo Nath <nathbappai@gmail.com>, 
 Vitalii Skorkin <nikroks@mainlining.org>, 
 Erikas Bitovtas <xerikasxx@gmail.com>, Johan Jonker <jbx6244@gmail.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Michael Srba <Michael.Srba@seznam.cz>, 
 Quentin Schulz <quentin.schulz@cherry.de>, 
 Demeter Barna <me@fromdisposition.org>, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=ed25519-sha256; t=1794622936; l=2755;
 i=me@fromdisposition.org; s=20261012; h=from:subject:message-id;
 bh=V7Z9MNs4lz2ZkPc5+wizpyhZZc3+q5IUGdEJ9guSD3E=;
 b=GUMj3q9aRHN0LvBY/OGUJ61soVOoVBqhfFfFOZ46HzOuxw2yA5oc04nkUHayocuGOpY45bvNj
 laRV3uPH7WmA2DNYEbO59coBu6CxbBNSJvE8XT4Vux9e/4cYdLKKCTv
X-Developer-Key: i=me@fromdisposition.org; a=ed25519;
 pk=S0QFlGq1BQEaAtPPdAH8YKEOXMeRuSkTgctXuvtU+1Y=
X-Endpoint-Received: by B4 Relay for me@fromdisposition.org/20261012 with auth_id=1163
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

This adds the Qualcomm SM8350 (Snapdragon 888) to the generic Qualcomm
target. It is based on v2027.01-rc2 and applies to qcom-next as well.

Patches 1-3 add the GCC, pinctrl and interconnect drivers, limited to
what U-Boot drives: the QUP wrappers, UFS, the primary USB controller
and SDCC2. Patches 4-8 add the SM8350 and PM8350 entries to existing
drivers, and patch 9 enables the new drivers in qcom_defconfig. The data
come from Linux v7.4-rc1.

Tested on the Razer Edge 5G, chainloaded from its ABL: the console on
the splash framebuffer, UFS (HS-G3, two lanes), USB fastboot and the
volume-up key work, the SD host probes (no card tried), and Linux boots
through bootmgr and systemd-boot.

That ABL takes only boot image header v3 and resets on the Image
text_offset of a qcom_defconfig build, so the test builds set
CONFIG_TEXT_BASE=0x80000000 and carry the board DT, much as the patch
"board: qualcomm: add Moto G10 configuration and boot instructions" on
the list describes. The board DT is not in Linux yet; sm8350-hdk builds,
but I have no HDK to run it on.

---
Demeter Barna (9):
      clk: qcom: Add SM8350 GCC driver
      pinctrl: qcom: Add SM8350 pinctrl driver
      interconnect: qcom: Add SM8350 interconnect driver
      clk: qcom: sm8350: enable shared RPMH clock driver
      gpio: qcom_spmi_gpio: add qcom,pm8350-gpio
      iommu: qcom-hyp-smmu: Add SM8350 compatible
      power: regulator: qcom-rpmh: add PM8350 support
      phy: qcom: Add SM8350 to QMP UFS PHY driver
      qcom_defconfig: Enable SM8350 GCC and interconnect

 configs/qcom_defconfig                        |   2 +
 drivers/clk/qcom/Kconfig                      |   9 +
 drivers/clk/qcom/Makefile                     |   1 +
 drivers/clk/qcom/clock-rpmh.c                 |   1 +
 drivers/clk/qcom/clock-sm8350.c               | 281 ++++++++++++++++++++++++++
 drivers/gpio/qcom_spmi_gpio.c                 |   1 +
 drivers/interconnect/qcom/Kconfig             |   7 +
 drivers/interconnect/qcom/Makefile            |   1 +
 drivers/interconnect/qcom/sm8350.c            | 271 +++++++++++++++++++++++++
 drivers/interconnect/qcom/sm8350.h            |  25 +++
 drivers/iommu/qcom-hyp-smmu.c                 |   1 +
 drivers/phy/qcom/phy-qcom-qmp-ufs.c           |   1 +
 drivers/pinctrl/qcom/Kconfig                  |   8 +
 drivers/pinctrl/qcom/Makefile                 |   1 +
 drivers/pinctrl/qcom/pinctrl-sm8350.c         | 101 +++++++++
 drivers/power/regulator/qcom-rpmh-regulator.c |  30 +++
 16 files changed, 741 insertions(+)
---
base-commit: ecdcf9e365df6249a57cd8cc946e7026804ff4ae
change-id: 20261114-sm8350-support-92d8cd386233

Best regards,
--  
Demeter Barna <me@fromdisposition.org>

