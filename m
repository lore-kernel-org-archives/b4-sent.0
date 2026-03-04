From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v4 0/4] Rework BPI-R2-Pro PCIe clock topology
Date: Wed, 04 Mar 2026 12:05:26 +0100
Message-Id: <20260304-rk3568-bri-r2-pro-fix-pcie-v4-0-37abd7ba29d0@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAPcRqGkC/43NwQ6CMAzG8VcxO1vTdRTQk+9hPGxsaGMiZBCCE
 t7dqQf1Qjz+vya/TqoLUUKndqtJxTBIJ801RbZeqepsr6cA4lMrQsqRiCBeDOcluCgQCdrYQC0
 jtJUEMMwOCb1HTyoBbQzp9sIPx9Rn6fom3l6/Bv1c36xBvcQOGjS4bfBGly6zRbGXUfpNdVdPd
 KBvyCxCBAiY5TkHZs+2/IXM/5BJkK3ZMmHh0OoPNM/zA5Rx59tUAQAA
X-Change-ID: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>, 
 Frank Wunderlich <frank-w@public-files.de>
Cc: Martin Filla <freebsd@sysctl.cz>, 
 Charalampos Mitrodimas <charmitro@posteo.net>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=1501; i=david@ixit.cz;
 h=from:subject:message-id; bh=rappOU6haODzrmo9ldSIUDJg7935zH1v7n2L238WwX8=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBpqBH5QVhOP27LnMiKOOFlu0rfrwVolxABEt7dW
 rPVhLK3scuJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaagR+QAKCRBgAj/E00kg
 cujPD/0T4cguv77mntr2cU2BgHwJ0LcMPebStYmJTq6Ik7/c5+GAK/s8VhkqnKNzdzbjUpi7hrg
 O7nxijvj6U5NDJS9uiRTi9570RZFDs8pZDenp/IPKi5WR/GuaslR6Xnbqo8tyt2g2S10rXQaWuJ
 jgWWbr5pc3KZ7aXNNNMBQ8C8GpEj+9VplgNe0WhsDVJhhq6wVZrZsu++DNYpVDEvJ64O5L2vcG/
 Yt30ScMWu6s5mLmYs+CYDFAMsTrrf1P+GqJ7Y/boFpckV5Jg4IW8M68uUbZMqYQxyy1MjES8EH7
 BVviXGVMKG2nPJJYERRIXZTIW1fvMkLTEGk934BsHPGxqOBHKf7FkjH/Jo3jHhBWPckEjWdL0MK
 Of+84WHs6SfTh4JqBwBCzL60pYiOahlVjiyoUq8zb3CGLsriWVz/lSY6af+or2aCmLLuF3cYqOn
 m1DWX8cN7aqwDjGQB7JBShBDGm7Tyk4FRr2WqPOWtNt40VXoQlCcBK7e7u3N5Uc5B0IPmR5X7c3
 bvvPPZa6XSq1W+wWlr1qzPx5gMvkypnN27jWc1mMLPTxkk1y5X8tM1Tbly8lUsm/zVrUtQKZrfU
 rn5M99P8fjNOGhI/PyF9H2VNF8VaHswSAXfkoz5vlyLyGWxjxeQKw+O113kDLClPxY510e4gk3l
 GUKSMAtb06LD/RQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v4:
- Extend rk3568 pipe clock introduction to whole rk356x. (Shawn)
- typos (Charalampos)
- Link to v3: https://lore.kernel.org/r/20260303-rk3568-bri-r2-pro-fix-pcie-v3-0-af5a5207b0a1@ixit.cz

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
      arm64: dts: rockchip: assign pipe clock to rk356x PCIe lanes
      arm64: dts: rockchip: Introduce the reference PCIe clk generator for BPI-R2-Pro
      arm64: dts: rockchip: Use reference PCIe clock generator for BPI-R2-Pro
      arm64: dts: rockchip: Define PCIe clock pinctrl for BPI-R2-Pro

 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 59 +++++++++++++++++-----
 arch/arm64/boot/dts/rockchip/rk3568.dtsi           | 12 +++--
 arch/arm64/boot/dts/rockchip/rk356x-base.dtsi      |  6 ++-
 3 files changed, 57 insertions(+), 20 deletions(-)
---
base-commit: c025f6cf4209e1542ec2afebe49f42bbaf1a5c7b
change-id: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

