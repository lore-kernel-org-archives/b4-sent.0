From: Mizuno Miotsuki <founder@crepuse.com>
To: heiko@sntech.de
Cc: conor+dt@kernel.org, devicetree@vger.kernel.org, krzk+dt@kernel.org, 
 linux-arm-kernel@lists.infradead.org, linux-kernel@vger.kernel.org, 
 linux-rockchip@lists.infradead.org, robh@kernel.org
Subject: [PATCH v2 RESEND 0/1] Enable I2C2 on UNIHIKER M10 V1.2
Date: Wed, 11 Nov 2026 12:14:34 +0000
Message-ID: <179439927405.86676.18160135777424812496.i2c2-v2-resend-0@crepuse.com>
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
Content-Type: text/plain; charset="utf-8"
X-Developer-Signature: v=1; a=openpgp-sha256; l=609; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=skhAdHA3RZo/qHb7dMGwTpa8Pr/oRjo6b/TwlaWkzuo=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFlfYrSefT21L5jBPV/5ytZ4lWcFp1qis9ve8fQK/5bZv
 rEzUzmrYwILgxgXg6WYIstsUfbyQ80rrs2d0GQHM4eVCWSItEgDAxCwMPDlJuaVGukY6ZlqG+oZ
 GukY6BgzcHEKwFTv4Gdk+LezzXSiBHd7yoc+3oteeUvlKvMSVLvvRqdZhvw8apv4geHHn9mPMuL
 0lVYd/35aklMtpOZ9lcspzw+60e4SWwIiWbgB
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the onboard I2C2 controller at 400 kHz. The rk3308.dtsi pinmux
provides GPIO2_A2/A3. This common board preparation is independent of
the pending touchscreen device binding and driver.

Changes since v1:
- Normalize author/sender identity and preserve it in the patch body.
- Recheck ordinary and strict checkpatch and the DTS schemas.

Mizuno Miotsuki (1):
  arm64: dts: rockchip: Enable I2C2 on UNIHIKER M10 V1.2

 arch/arm64/boot/dts/rockchip/rk3308-unihiker-m10-v1.2.dts | 5 +++++
 1 file changed, 5 insertions(+)


base-commit: ae965b9856f033145e292b0c29082a26bcc45efd
-- 
2.56.0

