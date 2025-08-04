From: Aaron Kling <webgeek1234@gmail.com>
Subject: [PATCH v2 0/2] arm64: tegra: Add reserved-memory node to L4T
 Tegra210 devices
Date: Sun, 03 Aug 2025 22:14:29 -0500
Message-Id: <20250803-p3450-mts-bug-v2-0-6307125408c3@gmail.com>
MIME-Version: 1.0
Content-Type: text/plain; charset="utf-8"
Content-Transfer-Encoding: 7bit
X-B4-Tracking: v=1; b=H4sIAJUlkGgC/3XMQQ6CMBCF4auQWTtm2lJUVt7DsKi1hUmEkhaJh
 vTuVvYu/5e8b4PkIrsEbbVBdCsnDlMJeajADmbqHfKjNEiSmrRscFa1JhyXhPdXjyTVpTZeCU8
 GymeOzvN7925d6YHTEuJn51fxW/9Jq0CBp7MmaoTyJO21Hw0/jzaM0OWcv/HWwteqAAAA
X-Change-ID: 20250526-p3450-mts-bug-02394af31f0a
To: Rob Herring <robh@kernel.org>, Krzysztof Kozlowski <krzk+dt@kernel.org>, 
 Conor Dooley <conor+dt@kernel.org>, 
 Thierry Reding <thierry.reding@gmail.com>, 
 Jonathan Hunter <jonathanh@nvidia.com>
Cc: devicetree@vger.kernel.org, linux-tegra@vger.kernel.org, 
 linux-kernel@vger.kernel.org, Aaron Kling <webgeek1234@gmail.com>
X-Mailer: b4 0.14.2
X-Developer-Signature: v=1; a=ed25519-sha256; t=1754277275; l=658;
 i=webgeek1234@gmail.com; s=20250217; h=from:subject:message-id;
 bh=5qCGnzZe9zvgxj9r6imoUz73U1Eb0b2h8O09bbJ/Y2g=;
 b=pSOcHwoDz3dMPNGO3EBVF8hNPXY0FTEmFRMdwmLLuZK4t52CGSGCYMO5ek9RFNStpLCjWHZnx
 RTHKqJ2rGZcDj4CDggmQLTfHHBSpSfQp0c/rv26FJhxcFVKzHo6wF5j
X-Developer-Key: i=webgeek1234@gmail.com; a=ed25519;
 pk=TQwd6q26txw7bkK7B8qtI/kcAohZc7bHHGSD7domdrU=
X-Endpoint-Received: by B4 Relay for webgeek1234@gmail.com/20250217 with auth_id=342
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Signed-off-by: Aaron Kling <webgeek1234@gmail.com>
---
Changes in v2:
- Add patch for P2180
- Link to v1: https://lore.kernel.org/r/20250526-p3450-mts-bug-v1-1-78500613f02c@gmail.com

---
Aaron Kling (2):
      arm64: tegra: Add reserved-memory node for P3450
      arm64: tegra: Add reserved-memory node for P2180

 arch/arm64/boot/dts/nvidia/tegra210-p2180.dtsi     | 6 ++++++
 arch/arm64/boot/dts/nvidia/tegra210-p3450-0000.dts | 6 ++++++
 2 files changed, 12 insertions(+)
---
base-commit: 0ff41df1cb268fc69e703a08a57ee14ae967d0ca
change-id: 20250526-p3450-mts-bug-02394af31f0a

Best regards,
-- 
Aaron Kling <webgeek1234@gmail.com>

