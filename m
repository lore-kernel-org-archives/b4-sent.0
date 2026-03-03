From: David Heidelberg <david@ixit.cz>
Subject: [PATCH v2 0/3] Rework BPI-R2-Pro PCIe clock topology
Date: Tue, 03 Mar 2026 16:47:13 +0100
Message-Id: <20260303-rk3568-bri-r2-pro-fix-pcie-v2-0-04665e55d5a8@ixit.cz>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAIECp2kC/33NTQ6CQAyG4auQrq2Z6ciPrryHYcEwVRoTIB1CU
 MLdHXHv8v2aPF0hsgpHuGQrKM8SZehT0CGDtmv6B6OE1ECGCkNEqE+XFxV6FVTCUQe8y4JjK4w
 uz70hE4IJBAkYldNtx2916k7iNOhr/zXb7/pjnbH/2NmiRX/m4GzlT01ZXmWR6di+od627QOeu
 tu1wgAAAA==
X-Change-ID: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, Heiko Stuebner <heiko@sntech.de>
Cc: Martin Filla <freebsd@sysctl.cz>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, David Heidelberg <david@ixit.cz>
X-Mailer: b4 0.14.3
X-Developer-Signature: v=1; a=openpgp-sha256; l=847; i=david@ixit.cz;
 h=from:subject:message-id; bh=OAzOjjkcx2+yhAgDuC5wfxwZXHeEyyP73UH7KaBhzXk=;
 b=owEBbQKS/ZANAwAIAWACP8TTSSByAcsmYgBppwKCyc/A0X35SIdQV+jgSJl8J9tQaDWzoW847
 y05kLjkj9qJAjMEAAEIAB0WIQTXegnP7twrvVOnBHRgAj/E00kgcgUCaacCggAKCRBgAj/E00kg
 cqRtD/9KN/09wBH/zqd36deod2gHhVz2vYzQZc1DQsexbgWgbxHwfosftnde5ze2/6Cbh86EmDA
 /2zUHly1zm6y39IGDmHXowCBWGrOnZwiu5QIfCqH0EMUVSilCaePvhNWa+7oVbHzjy5eiDzkowi
 JkT0HKVM6fW/yTrWKgxkKuOifKcp5ax9swI5C0AmuWJgZKXlyzVxDly1a7ZXzrWw+YVqLFew1lC
 O8Dq739hd+82AmHljHC2IrFPxHmYoaKvOYYkwFPZCv4Zgi7Y8KRJ+Wm6F8ZOp06DJRBvBTAKQoW
 EHxReCvJWIU76pZvKtQalQKDTHlFX+g2J9gAalF+5Z6USQLj+gAPJ+VnaFKE1th4pFAt/R97Yz8
 xZy16v6RD9Xj/DTEMK7k+B7s13WGh+lgY27rFU5Sqtao/fGVU020EiYMFCKfs48VqjIFN6ke0lD
 P1EYVRDp6ZuoDpSZebqGICttZ0knixnWh/Z+1HhIe0eJ3Ac8Gy58NusxmOjD7AwNEt3XwFua+jz
 N6OsyMmHlP10TcpAhU5ppyYowKQ4pw+39suPLv1Bd4rXEX/Mph+mh37dJ1h/u+bUOv/16F8lkdB
 Ng3ZnxDXrkSsEdxko2HhSvrN1lCX6dpMlkkkA0QcI32z5iq97zUphtz6FKr9WKkYEkScPfOcLWR
 QiarM+NWNyD2uKQ==
X-Developer-Key: i=david@ixit.cz; a=openpgp;
 fpr=D77A09CFEEDC2BBD53A7047460023FC4D3492072
X-Endpoint-Received: by B4 Relay for david@ixit.cz/default with auth_id=355
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: David Heidelberg <david@ixit.cz>
---
Changes in v2:
- Added patches for solving the topology issues and on top of these
  original patch. (Heiko)
- Link to v1: https://lore.kernel.org/r/20260301-rk3568-bri-r2-pro-fix-pcie-v1-1-b9ed318b4a77@ixit.cz

---
David Heidelberg (3):
      arm64: dts: rockchip: Introduce the reference PCIe clk generator for BPI-R2-Pro
      arm64: dts: rockchip: Use reference PCIe clock generator for BPI-R2-Pro
      arm64: dts: rockchip: Define PCIe clock pinctrl for BPI-R2-Pro

 arch/arm64/boot/dts/rockchip/rk3568-bpi-r2-pro.dts | 57 ++++++++++++++++------
 1 file changed, 43 insertions(+), 14 deletions(-)
---
base-commit: 3fa5e5702a82d259897bd7e209469bc06368bf31
change-id: 20260222-rk3568-bri-r2-pro-fix-pcie-355b020dd0d2

Best regards,
-- 
David Heidelberg <david@ixit.cz>

