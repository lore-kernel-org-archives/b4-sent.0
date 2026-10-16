From: Igor Velkov <iav@iav.lv>
Subject: [PATCH 0/2] arm64: dts: rockchip: Describe more of the power tree
 on Kobol Helios64
Date: Fri, 16 Oct 2026 08:34:32 +0300
Message-Id: <20261016-helios64-power-tree-v1-0-31d6c8dc5092@iav.lv>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAGi30WoC/x3MQQqEMAxG4atI1gZs0SheRVxI5x8NiJVUVBDvP
 mWW3+K9hxJMkagvHjKcmjRuGa4sKCzTNoP1k02+8uIqJ7xg1Zik5j1eMD4M4Kb1ndQhQBqhXO6
 Gr97/6zC+7w9qd1zyZQAAAA==
To: Heiko Stuebner <heiko@sntech.de>
Cc: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, devicetree@vger.kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-rockchip@lists.infradead.org, 
 linux-kernel@vger.kernel.org, Igor Velkov <iav@iav.lv>
X-Mailer: b4 0.13.0
X-Developer-Signature: v=1; a=openpgp-sha256; l=969; i=iav@iav.lv;
 h=from:subject:message-id; bh=H0zSGhB8hGAGhGm1ZMMp2gTyzpy32OW6Q5DZrz3Rqmk=;
 b=owGbwMvMwCVmNH1q96v4SmbG02pJDFkXt2fpHD19VvaiXNvJwOvzopMM3lUdafB5HmCY97ykv
 2nGV75HHaUsDGJcDLJiiiwTDmncylhy9a+/h/kDmDmsTCBDGLg4BWAiNqsZGdbULbULLJ/cfvP+
 C+8DynopafyH9xgu3CHWlFfEnbvbw5/hD5/V7MQ7i5c1qVzavtP2+8ydm2LXRd/4vfdfb9KOlWV
 OegwA
X-Developer-Key: i=iav@iav.lv; a=openpgp;
 fpr=90C228DA68A4D5FD4F4837E03297958BEA5F7903
X-Endpoint-Received: by B4 Relay for iav@iav.lv/default with auth_id=1060
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

The Helios64 device tree leaves out some regulators that the board has.
Patch 1 adds the ones in use. Patch 2 adds the RK808 outputs that the
schematic marks as unused, so that the kernel switches them off.

Schematic:
https://wiki.kobol.io/helios64/files/schematics/Helios64_Schematics_Rev1.2.pdf

Tested on Helios64 with a 7.3-rc7 kernel: the new regulators come up at
the voltages from the schematic, the regulator core switches off the five
unused outputs, and the disks and Ethernet work.

---
Igor Velkov (2):
      arm64: dts: rockchip: Describe more of the power tree on Kobol Helios64
      arm64: dts: rockchip: Describe the unused RK808 outputs on Kobol Helios64

 .../boot/dts/rockchip/rk3399-kobol-helios64.dts    | 83 ++++++++++++++++++++++
 1 file changed, 83 insertions(+)
---
base-commit: d2abcbb905b0e4b2e06b257fa1e5bcf4faa6dbda
change-id: 20261016-helios64-power-tree-572864cce656

Best regards,
-- 
Igor Velkov <iav@iav.lv>

