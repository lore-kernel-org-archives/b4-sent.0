From: Mizuno Miotsuki <founder@crepuse.com>
To: heiko@sntech.de
Cc: broonie@kernel.org, conor+dt@kernel.org, devicetree@vger.kernel.org, 
 krzk+dt@kernel.org, linux-arm-kernel@lists.infradead.org, 
 linux-kernel@vger.kernel.org, linux-rockchip@lists.infradead.org, 
 linux-sound@vger.kernel.org, luca.ceresoli@bootlin.com, robh@kernel.org
Subject: [PATCH v2 RESEND 0/1] Enable audio on UNIHIKER M10 V1.2
Date: Wed, 11 Nov 2026 12:14:34 +0000
Message-ID: <179439927463.86676.9537625579963969157.audio-v2-resend-0@crepuse.com>
MIME-Version: 1.0
Content-Transfer-Encoding: 8bit
X-Mailer: b4 0.16.0
Content-Type: text/plain; charset="utf-8"
X-Developer-Signature: v=1; a=openpgp-sha256; l=697; i=founder@crepuse.com;
 s=20261012; h=from:subject:message-id;
 bh=prh6HXem3h6+JFP/qvS34mf59BBbBWZZMrWI0bgKzRM=;
 b=owGbwMvMwCUmds2G2fVJ/hLG02pJDFlfYrSK49on9Uw/vaZo7sM386Vi+vfLfznst+t+XVxut
 JtaRKtlx0QWBjEuBksxRZbZouzlh5pXXJs7ockOZg4rE8gQaZEGBiBgYeDLTcwrNdIx0jPVNtQz
 NNIx0DFm4OIUgKn+vpqR4d32aRd1vFj/RlZ9NmfZLK3JGnjCQ+OqFsuDiTv7rjydMoWR4b19w4K
 K7rXaa+eGaqmdvG99jeuaU1/Ia3fu4nupN1/ZswIA
X-Developer-Key: i=founder@crepuse.com; a=openpgp;
 fpr=9B150777C283A8D69D90823E16D63C0345E46FA4
X-Endpoint-Received: by B4 Relay for founder@crepuse.com/20261012 with auth_id=1166
List-Id: B4 Relay Submissions <b4-sent.feeds.kernel.org>

Enable the internal codec, I2S2 and onboard microphone route. The board
uses codec revision B; that driver support is already accepted in the
ASoC for-7.4 tree as commit 157f7cba77a9. It is a runtime dependency,
not a change to the existing codec binding.

Changes since v1:
- Normalize author/sender identity and preserve it in the patch body.
- Recheck ordinary and strict checkpatch in the actual Git repository.

Mizuno Miotsuki (1):
  arm64: dts: rockchip: Enable audio on DFRobot UNIHIKER M10 V1.2

 .../dts/rockchip/rk3308-unihiker-m10-v1.2.dts | 30 +++++++++++++++++++
 1 file changed, 30 insertions(+)


base-commit: ae965b9856f033145e292b0c29082a26bcc45efd
-- 
2.56.0

