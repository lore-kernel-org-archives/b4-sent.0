From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/4] sdm845: Configure USB3/DP combo properly
Date: Fri, 04 Sep 2026 19:53:43 +0200
Message-Id: <20260904-b4-sdm845-usb-gadget-v2-0-cf1baa65a6d4@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAAAAAAAC/4WNQQ6CMBBFr0K6dkwplRRX3sOwoO0AYyKYTiEo4
 e4WPIDLl7z//ioYAyGLa7aKgDMxjUMCdcqE65uhQyCfWCipSmkKCVYD+6fRF5jYQtf4DiM4XVg
 0zstKe5Gmr4AtLUf2Xv+YJ/tAF/fWbvTEcQzv43fOd+/PxZyDhKpVEo1WvlTmRgvFs/uIetu2L
 8/Epu7IAAAA
X-Change-ID: 20260830-b4-sdm845-usb-gadget-c43be8cd094d
To: Sumit Garg <sumit.garg@kernel.org>, u-boot-qcom@groups.io, 
 u-boot@lists.denx.de
Cc: Casey Connolly <casey.connolly@linaro.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, Tom Rini <trini@konsulko.com>, 
 Petr Hodina <petr.hodina@protonmail.com>, 
 Varadarajan Narayanan <varadarajan.narayanan@oss.qualcomm.com>, 
 Balaji Selvanathan <balaji.selvanathan@oss.qualcomm.com>, 
 Jaehoon Chung <jh80.chung@samsung.com>, Peng Fan <peng.fan@nxp.com>, 
 Luca Weiss <luca.weiss@fairphone.com>, 
 Aswin Murugan <aswin.murugan@oss.qualcomm.com>, 
 Federico Amedeo Izzo <federico@izzo.pro>, 
 Marek Vasut <marek.vasut+renesas@mailbox.org>, 
 Quentin Schulz <quentin.schulz@cherry.de>, phone-devel@vger.kernel.org, 
 David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.16.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=1686; i=david@ixit.cz;
 h=from:subject:message-id; bh=rMx9wV41Nal1tlG88TXQtCY72nCOmxFyrUO8U80xf7c=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBqmwWrq0drcQjy1d6TOsYWX/Q+LAPG6NI/y783/
 L2qkv5GcY+JAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCapsFqwAKCRBgAj/E00kg
 coS0D/9+9F/dvAliXIRzUA5ZkBLDwAEsca+24tp4MsRCtW4WyTelffbokwtl89lAQXG2MX8vJZW
 4E/DubO89XI1/1qgZ8yyg5Bml8FgbSUUxsMiWN9v2fyeu5BrrFIA/i0mVphZA23Zva7RJk6urHF
 FrZ1a4CzEphOP23Fx02OWpiA/OfatEmHsY4T584B4F9Mrpr2xafHRT4ZvmMIRWWJgjHvE5Wj37h
 UBfMLjq8Pe9aKU4gPCvDSDSv61QqpHYwJk07hl18k95GaeJpXipP7EoG2vzQNXVvBq5Jr0w9/8z
 i0OaOrS5/atsUJVHZ/smF4rSstjSc4ztHoDX9A6e1v3sjhsh3mNsw4ex5Cxj+eWMefWznsy7zRV
 AqA0cZLmV/ENIl89l0+IXt4wSpHKLH1JWt46js6SjaN5dMi6jR27tcVnyfPCVn25OikJ/qXk1k6
 6mQUAWRBNCuHndlJRAhfLO5myZoOPtzmkHJndu2vUrQs/FKO9WDnE4DmafMZ1RaBVa6WhNEr0TD
 1ag1KFypB4prm4yinfZErjzQ4fwHSxm3eq502UyQDzTQs5HiInqm8dHIKu1iUP5mgnaYuwqMQdw
 dsX1XL+Xc0vk9T7S9Q3NrNxKKnWlZ1Fv/3SL+h6HsJBosYiabjyPN8EWgvtW7hTyfoSCCozbEm5
 xNuqywyx7gkqdMw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

USB gadget mode nor serial console does not work on some sdm845 boards:

  dwc3-generic-peripheral usb@a600000: failed to enable ep0out

with exception of the first boot.

This series implements "qcom,sdm845-qmp-usb3-dp-phy", so the USB3/DP combo
PHY is never bound, GCC_USB3_PRIM_PHY_PIPE_CLK has no source and stays off,
and the DWC3 endpoint command times out. It can be masked by an earlier
boot stage having left the PHY initialised, which is why this only shows
up on some boots.

Add SDM845 to the combo PHY driver, plus the two things needed to make
it usable: PM8998 regulators, without which the PHY cannot get its
supplies, and the defconfig symbol, without which the driver is left out
of the build entirely.

Tested on Google Pixel 3 (blueline).

---
Changes in v2:
- I cannot find v1 on any mailing list where it was sent to, so
  resending, adding Casey R-b.
- Link to v1: https://patch.msgid.link/20260830-b4-sdm845-usb-gadget-v1-0-9f20e842d628@ixit.cz

---
David Heidelberg (4):
      phy: qcom: qmp-combo: select PCS register offsets per version
      phy: qcom: qmp-combo: add SDM845 support
      power: regulator: qcom-rpmh: add PM8998 support
      configs: qcom: enable QMP USB3-DP combo PHY

 configs/qcom_defconfig                        |   1 +
 drivers/phy/qcom/phy-qcom-qmp-combo.c         | 168 ++++++++++++++++++++++++--
 drivers/power/regulator/qcom-rpmh-regulator.c | 137 +++++++++++++++++++++
 3 files changed, 299 insertions(+), 7 deletions(-)
---
base-commit: ece349ade2973e220f524ce59e59711cc919263f
change-id: 20260830-b4-sdm845-usb-gadget-c43be8cd094d

Best regards,
--  
David Heidelberg <david@ixit.cz>

