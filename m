From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v3 0/4] Rework BPI-R2-Pro PCIe clock topology
Date: Tue, 03 Mar 2026 20:52:26 +0100
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPo7p2kC/33NQQ6CMBCF4auQrh3TTmlBV97DuKC0ysQEyJQQl
 HB3Cy50xfJ/k3wzixiYQhTnbBYcRorUtSn0IRN1U7WPAORTC5RoJSICP7WxJTgmYISeO7jTBH1
 NAbQxTqL0XnoUCeg5pNuGX2+pG4pDx6/t16jW9ctqqfbYUYECdwpeq9LlVVFcaKLhWL/Fio74D
 +ldCEGCzK01wRhvqvIHLcvyAW/XqfMLAQAA
X-Change-ID: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Frank Wunderlich <frank-w@public-files.de>
Cc: Martin Filla <freebsd@sysctl.cz>, 
 Charalampos Mitrodimas <charmitro@posteo.net>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1229; i=david@ixit.cz;
 h=from:subject:message-id; bh=Tsg7+g5+IzVoAa4NtAmUW9nOtVF1KEhB9DJB2ZeM0Z8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppzv7Syif8BQdEO3VtydBbircS9IZVObETCauE
 8waThZ7wTmJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaac7+wAKCRBgAj/E00kg
 csqXEADHQTI7xNCuksTS/Xb6kCEdA7QqEbj0hAvV3O224oAAKxq/DBwIK4NCg2fkwjMODv08VgE
 jRdEam6+jORT/y+kev2u3+1nVC94l/q/jWgFRUehbU42GeGWWlEqexT/tvCQnLLSObOY+r9tydg
 SZqIR/6r/qE1wF2BucOFbXqKZEC2M6ZAYGjHRhRx+24Wznkl0/Aba6dhN9ffY4HxjDECviRLffw
 HfTM1fmPNtKN56mCKRvivsGHCmuBVDjwPjKpPyV1Uu7ApuBt2lVDJgynQmDPzDpfzvYDQ7MaI16
 A6JIkyPhb+TDxUmb60soVH9yFGlsvWtG0HAdho+B88jffsjCDfZXqiPoRrcMdaBYrwh6y706yyH
 nai572KhAOsU/RRDEuPrHcXo37KoEN3bGnPyUJGRpdvTLhK0zlnDpvPCZkR7BctlkVT+lLsJY5F
 lFiWdXzXkzdMKnJokbBwH8TfLq9qCiURcc3vYpT8u1VgKYlqIh2j1vSGu3ATEM5UQmtW9p/3LNz
 /W+BdciJTIQJarJKeo2miRan2Yx/3PNDgDfithQpo+nmNDBkSqtTUmtDHSnHQlwxnRIRrsRZjhG
 MRXVCic7WW/ATPW1177GmQ9UBX7jutsmI+Q6hOplP7dNuC++coJnH8R/KPv8AOEfMb+rVnyl7gD
 1JypALq0pulpaRw==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v3:
- Added commit extending the clock list with pipe clock for rk3568.
- Updated the clock list in BPI-R2-Pro dts. (Charalampos)
- Link to v2: https://lore.kernel.org/r/20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz

Changes in v2:
- Added patches for solving the topology issues and on top of these
  original patch. (Heiko)
- Link to v1: https://lore.kernel.org/r/20260301-rk3568-bri-r2-pro-fix-pcie-v1-1-b9ed318b4a77@ixit.cz

---
David Heidelberg (4):
      arm64: dts: rockchip: assign pipe clock to rk3568 PCIe lanes
      arm64: dts: rockchip: Introduce the reference PCIe clk generator for BPI-R2-Pro
      arm64: dts: rockchip: Use reference PCIe clock generator for BPI-R2-Pro
      arm64: dts: rockchip: Define PCIe clock pinctrl for BPI-R2-Pro

 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 59 +++++++++++++++++-----
 arch/arm64/boot/dts/rockchip/rk3568.dtsi           | 12 +++--
 2 files changed, 53 insertions(+), 18 deletions(-)
---
base-commit: 3fa5e5702a82d259897bd7e209469bc06368bf31
change-id: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

