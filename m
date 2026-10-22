From: Aiden Isik <aidenisik@member.fsf.org>
Subject: [PATCH 0/2] Add Exynos5515 USB PHY support
Date: Thu, 22 Oct 2026 17:46:35 +0100
Message-Id: <20261022-for-next-lucky7-usb-phy-v1-0-2e47f8484bf4@member.fsf.org>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAOs92moC/yXMQQ6CMBBA0auQWTsJTAhFr2Jc2DKFUVNIhxoI4
 e5WWL7F/xsoR2GFW7FB5K+ojCGjuhTghmfoGaXLBiqpqUoi9GPEwMuMn+Teq8GkFqdhRWOori1
 5d20Zcj1F9rIc5/vjtCb7Yjf/d7DvP+kvrUl7AAAA
X-Change-ID: 20261022-for-next-lucky7-usb-phy-77244b2fc98e
To: Vinod Koul <vkoul@kernel.org>, 
 Neil Armstrong <neil.armstrong@linaro.org>, 
 Manivannan Sadhasivam <mani@kernel.org>, Rob Herring <robh@kernel.org>, 
 Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Marek Szyprowski <m.szyprowski@samsung.com>, 
 Sylwester Nawrocki <s.nawrocki@samsung.com>, 
 Peter Griffin <peter.griffin@linaro.org>, 
 Alim Akhtar <alim.akhtar@samsung.com>
Cc: Krzysztof Kozlowski <krzk@kernel.org>, linux-phy@lists.infradead.org, 
 devicetree@vger.kernel.org, linux-kernel@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-samsung-soc@vger.kernel.org, 
 Aiden Isik <aidenisik@member.fsf.org>
X-Mailer: b4 0.15.2
X-Developer-Signature: v=1; a=openpgp-sha256; l=1831;
 i=aidenisik@member.fsf.org; h=from:subject:message-id;
 bh=me8mjqkDEH3k+r4GPGLnzrCNkQZFbNxiQ3wp8aaLBNU=;
 b=owEBiQJ2/ZANAwAIAUknAbLEetfrAcsmYgBq2j3s5XBlupmzJ4a/zgSIyMg+7QLmOCmMMMq4H
 3sVdzbgdE+JAk8EAAEIADkWIQSDy8UkXGpc3JNbEaVJJwGyxHrX6wUCato97BsUgAAAAAAEAA5t
 YW51MiwyLjUrMS4xMiwyLDIACgkQSScBssR61+sJbBAAytJ84YhHRR+XnuUu8QYoumKEKfprYYg
 Hu7gNBMqyPPPHZOWq0yopgsvDpLJnyL97ZhTkLK4OgNKhcugsq+Di+lbsY1wk9koHodBB+db4oP
 yi7S+wwCkhx7PbKzcjJXPUvmlSdzl0uXnobwKUVPMCXj5oh2OlWNrwC6ropbfeNL+726eRAs9qZ
 9snYCyTj0W40RWvsc52Ye7x8aq3ath/iuJZwJMVk4JV7rnN7z2L4mKEu3sHHhfrymAi9EtxR6S/
 tFk6lmv8gESSH65GXAvTPru8modWt3P5fwD/RpIDITiJe2gIppo9qrDuYTzBNaZtHHkqpMHWLCt
 grFKLjfJ2JV+fENCrKd97EiH8qOZ4//rcUV29mMBnaKr0MvmYuj/ZO+JYFlfPnIWeFMxTIbFIvo
 1GvJveA7UxEwWiiOB8ORN+jndCA7tN317WgX6FotzhLtR4Lw6zS+hcvWmYTQrHR4/iOc/os1vjn
 Q9U5NTQF/78j/MtfGUzJ4l5ZVCrwSmPxhGOHzrcQGed16K2t72oumof33ZaxrGamJSNXk7vpVjJ
 dVFv8/SfR1te3m/6ldQBsaIFt0j1bz3uuQSUbnJo+Nph6bB8UxgdZPHBpB4uqwhG2+yajdXALfN
 pLZjQS9P/GcCAW2U1HxJKsHDiczkCn8MgYw+WB9ZY3zE2traehEY=
X-Developer-Key: i=aidenisik@member.fsf.org; a=openpgp;
 fpr=83CBC5245C6A5CDC935B11A5492701B2C47AD7EB
X-Endpoint-Received: by B4 Relay for aidenisik@member.fsf.org/default with auth_id=956
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Hi there,

This patchset adds support for the Exynos5515 USB PHY.

The PHY supports High-Speed (UTMI+), and also appears to support
Super-Speed (PIPE3) USB according to Samsung's own code to drive this PHY.
However, none of the Exynos5515 hardware which I am aware of actually
supports Super-Speed, therefore I am unable to test that part, hence PIPE3
support being omitted.

This patchset was tested on a Samsung Galaxy Watch FE using the USB serial
gadget.

This patchset also depends on [1], due to using an
exynos5_usbdrd_phy_drvdata member (.n_phy_cfg) which was introduced to fix
an out-of-bounds access bug.

It also depends on [2] and [3] in that they are the clock and pinctrl
drivers for Exynos5515, and without them this driver cannot talk to the
PHY. It does however build without them. [2] should be close to being
merged into Torvalds' tree, and [3] was just submitted by myself a few
days ago.

[1] - https://lore.kernel.org/all/20261020063559.3530901-1-selvarasu.g@samsung.com/
[2] - https://lore.kernel.org/all/20260818-for-next-lucky7-clock-v2-0-cda0cc80f158@member.fsf.org/
[3] - https://lore.kernel.org/all/20261020-for-next-lucky7-pinctrl-v2-0-b6b0e6065452@member.fsf.org/

Kind regards,
- Aiden Isik

Signed-off-by: Aiden Isik <aidenisik@member.fsf.org>
---
Aiden Isik (2):
      dt-bindings: phy: samsung,usb3-drd-phy: Add Exynos5515 compatible
      phy: exynos5-usbdrd: Add support for the Exynos5515 usbdrd phy

 .../bindings/phy/samsung,usb3-drd-phy.yaml         |  2 +
 drivers/phy/samsung/phy-exynos5-usbdrd.c           | 43 ++++++++++++++++++++++
 2 files changed, 45 insertions(+)
---
base-commit: 5260a8a68459dd67262970d38f1b2496f0cad371
change-id: 20261022-for-next-lucky7-usb-phy-77244b2fc98e

Best regards,
--  
Aiden Isik <aidenisik@member.fsf.org>

